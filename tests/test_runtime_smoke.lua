-- Full-file startup/control-flow tests with an isolated Roblox service model.
-- This does not render Roblox UI or validate live networking/game physics.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('Games/StealAnEgg_Diagnostics.lua')
local loader=read('Loader.lua')
local registry=read('GameRegistry.lua')
local tests=0
local function fixture(options)
    options=options or {}
    local signals,objects,tasks={},{},{}
    local function signal()
        local s={handlers={}};signals[#signals+1]=s
        function s:Connect(fn)
            local c={Connected=true,fn=fn};function c:Disconnect() self.Connected=false end
            self.handlers[#self.handlers+1]=c;return c
        end
        function s:Fire(...) for _,c in ipairs(self.handlers) do if c.Connected then c.fn(...) end end end
        return s
    end
    local function object(class,name)
        local props={ClassName=class,Name=name or class,Visible=true,Enabled=true,Active=true,Text='',children={},signals={},attrs={}}
        local obj={}
        local methods={}
        function methods:IsA(kind) return kind==props.ClassName or kind=='GuiObject' and (class=='Frame' or class=='TextLabel' or class=='TextButton' or class=='TextBox') or kind=='LayerCollector' and class=='ScreenGui' end
        function methods:GetChildren() local r={};for _,c in ipairs(props.children) do r[#r+1]=c end;return r end
        function methods:GetDescendants() local r={};local function visit(n) for _,c in ipairs(n:GetChildren()) do r[#r+1]=c;visit(c) end end;visit(self);return r end
        function methods:FindFirstChild(n) for _,c in ipairs(props.children) do if c.Name==n then return c end end end
        function methods:WaitForChild(n) return self:FindFirstChild(n) end
        function methods:FindFirstChildOfClass(n) if props.failClassLookup then error('mock character lookup fault') end;for _,c in ipairs(props.children) do if c:IsA(n) then return c end end end
        function methods:GetAttributes() return props.attrs end
        function methods:GetAttribute(n) return props.attrs[n] end
        function methods:GetFullName() return props.Parent and props.Parent:GetFullName()..'.'..props.Name or props.Name end
        function methods:IsDescendantOf(n) local p=props.Parent;while p do if p==n then return true end;p=p.Parent end;return false end
        function methods:GetPropertyChangedSignal(n) props.signals[n]=props.signals[n] or signal();return props.signals[n] end
        function methods:CaptureFocus() end
        function methods:Destroy()
            for _,c in ipairs(self:GetChildren()) do c:Destroy() end
            self.Parent=nil;props.destroyed=true
            for _,s in pairs(props.signals) do for _,c in ipairs(s.handlers) do c:Disconnect() end end
        end
        setmetatable(obj,{__index=function(_,k)
            if methods[k] then return methods[k] end
            if k=='Activated' or k=='InputBegan' or k=='InputChanged' or k=='InputEnded' or k=='AncestryChanged' or k=='CharacterAdded' or k=='DescendantAdded' or k=='DescendantRemoving' or k=='PromptShown' then props.signals[k]=props.signals[k] or signal();return props.signals[k] end
            return props[k]
        end,__newindex=function(_,k,v)
            if k=='Text' and props.failWrite then error('mock UI write fault') end
            if k=='Scale' then assert(v>0,'UIScale must stay positive') end
            if k=='Parent' then
                if props.Parent then for i,c in ipairs(props.Parent.children) do if c==obj then table.remove(props.Parent.children,i);break end end end
                props.Parent=v;if v then v.children[#v.children+1]=obj end
                if props.signals.AncestryChanged then props.signals.AncestryChanged:Fire(obj,v) end
            else props[k]=v end
        end})
        objects[#objects+1]=obj;return obj
    end
    local pg=object('PlayerGui','PlayerGui');local player=object('Player','TestPlayer');pg.Parent=player
    player.Name='TestPlayer';player.UserId=42
    local backpack=object('Backpack','Backpack');backpack.Parent=player
    player.Character=object('Model','TestPlayer')
    local workspace=object('Workspace','Workspace')
    workspace.CurrentCamera=object('Camera','Camera');workspace.CurrentCamera.ViewportSize={X=options.width or 1920,Y=options.height or 1080}
    local ui=object('UserInputService');function ui:GetFocusedTextBox() return nil end
    local storage=object('ReplicatedStorage','ReplicatedStorage')
    local http={GenerateGUID=function() return 'test-nonce' end,JSONDecode=function() return options.malformed and {object=123} or {object={sha=string.rep('a',40)}} end}
    function http:JSONEncode(value) self.lastPayload=value;return 'mock json' end
    local services={Players={LocalPlayer=player},HttpService=http,UserInputService=ui,TweenService={},PathfindingService={},ProximityPromptService=object('ProximityPromptService'),ReplicatedStorage=storage}
    local game={PlaceId=options.placeId or 107778070777162,IsLoaded=function() return true end,GetService=function(_,n) return assert(services[n],n) end}
    function game:HttpGet(url)
        if url:find('api.github.com',1,true) then if options.apiError then error('lookup unavailable') end;return 'head' end
        if url:find('GameRegistry.lua',1,true) then return registry end
        if url:find('Games/StealAnEgg_Diagnostics.lua',1,true) then return options.badSource and 'local =' or source end
        error('unexpected download '..url)
    end
    local env=setmetatable({workspace=workspace,game=game,typeof=type,Instance={new=function(c) return object(c) end},
        task={spawn=function(fn,...) tasks[#tasks+1]={fn=fn,args={...}} end,delay=function(_,fn) tasks[#tasks+1]={fn=fn,args={}} end,defer=function(fn) tasks[#tasks+1]={fn=fn,args={}} end,wait=function() error('Background workers are not run by this startup test') end},
        Color3={fromRGB=function(...) return {...} end,new=function(...) return {...} end},ColorSequence={new=function(...) return {...} end},
        UDim={new=function(...) return {...} end},UDim2={fromOffset=function(x,y) return {X=x,Y=y} end,fromScale=function(x,y) return {X=x,Y=y} end,new=function() return {} end},
        Vector2={new=function(x,y) return {X=x,Y=y} end},Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,n) return k..'.'..n end});rawset(t,k,v);return v end}),
        print=function() end,warn=function() end},{__index=_G})
    env._G=env;env.getgenv=function() return env end;env.loadstring=function(s,n) return load(s,n,'t',env) end
    local f={env=env,pg=pg,ui=ui,tasks=tasks,objects=objects,player=player,http=http}
    function f:run(s) assert(load(s or source,'@Games/StealAnEgg_Diagnostics.lua','t',env))() end
    function f:button(text) for _,obj in ipairs(pg:GetDescendants()) do if obj.ClassName=='TextButton' and obj.Text==text then return obj end end;error('Button missing: '..text) end
    function f:liveConnections() local n=0;for _,s in ipairs(signals) do for _,c in ipairs(s.handlers) do if c.Connected then n=n+1 end end end;return n end
    function f:loaderStatus() local g=assert(pg:FindFirstChild('MyRobloxHub_LoaderStatus'));return g:FindFirstChildOfClass('TextLabel').Text end
    return f
end
local function check(name,fn) fn();tests=tests+1;print('PASS '..name) end
check('full egg script constructs every tab and starts all automation OFF',function()
    local f=fixture();f:run();local gui=assert(f.pg:FindFirstChild('EggDiagnostics'))
    assert(gui.Enabled and gui.DisplayOrder==1000)
    for _,name in ipairs({'Automation','Eggs','Placement','Diagnostics','Settings','Auto Hatch: OFF','Collect: OFF','Upgrade: OFF','Train: OFF','Auto Place: DISABLED','Scan eggs','Copy eggs'}) do f:button(name) end
end)
check('UI stays positively scaled while camera viewport is not ready',function()
    local f=fixture({width=1,height=1});f:run()
    for _,obj in ipairs(f.objects) do if obj.ClassName=='UIScale' then assert(obj.Scale>0 and obj.Scale<=1) end end
end)
check('all tabs and egg scan work before a character humanoid is available',function()
    local f=fixture();f:run()
    for _,name in ipairs({'Eggs','Placement','Diagnostics','Settings','Automation'}) do f:button(name).Activated:Fire() end
    f:button('Scan eggs').Activated:Fire();f:button('Mode: NEAREST').Activated:Fire();f:button('Mode: INCOME')
end)
check('Alt hides and restores the window and leaves restore control accessible',function()
    local f=fixture();f:run();local frames={};for _,obj in ipairs(f.objects) do if obj.ClassName=='Frame' and obj.Parent==f.pg:FindFirstChild('EggDiagnostics') then frames[#frames+1]=obj end end
    local input={KeyCode=f.env.Enum.KeyCode.LeftAlt};f.ui.InputBegan:Fire(input,false);f.ui.InputEnded:Fire(input)
    assert(not frames[1].Visible and f:button('YUU HUB').Visible)
    f:button('YUU HUB').Activated:Fire();assert(frames[1].Visible)
end)
check('Auto Place control remains disabled when clicked',function()
    local f=fixture();f:run();local b=f:button('Auto Place: DISABLED');b.Activated:Fire();assert(b.Text=='Auto Place: DISABLED')
end)
check('rerunning egg UI cleans old connections and close stops all tracked listeners',function()
    local f=fixture();f:run();local first=f.pg:FindFirstChild('EggDiagnostics');local connections=f:liveConnections()
    f:run();assert(first.destroyed and first~=f.pg:FindFirstChild('EggDiagnostics') and f:liveConnections()==connections)
    f:button('X').Activated:Fire();assert(not f.pg:FindFirstChild('EggDiagnostics') and f:liveConnections()==0)
end)
check('universal Loader boots the full egg UI and verifies it',function()
    local f=fixture();f:run(loader);assert(f.pg:FindFirstChild('EggDiagnostics') and f:loaderStatus():find('Started ',1,true))
end)
check('malformed commit lookup falls back instead of killing UI startup',function()
    local f=fixture({malformed=true});f:run(loader);assert(f.pg:FindFirstChild('EggDiagnostics') and f:loaderStatus():find('Started ',1,true))
end)
check('unavailable commit lookup falls back to branch',function()
    local f=fixture({apiError=true});f:run(loader);assert(f.pg:FindFirstChild('EggDiagnostics') and f:loaderStatus():find('Started ',1,true))
end)
check('Loader surfaces compile errors with stack context',function()
    local f=fixture({badSource=true});f:run(loader);assert(f:loaderStatus():find('FAILED:',1,true) and f:loaderStatus():find('stack traceback',1,true))
end)
check('unsupported place never starts egg UI',function()
    local f=fixture({placeId=1});f:run(loader);assert(not f.pg:FindFirstChild('EggDiagnostics') and f:loaderStatus():find('Unsupported game',1,true))
end)
check('Egg list render faults are isolated and exported for diagnosis',function()
    local f=fixture();f:run();local counter
    for _,obj in ipairs(f.objects) do if obj.ClassName=='TextLabel' and obj.Text=='Not scanned' then counter=obj end end
    assert(counter);counter.failWrite=true
    f:button('Scan eggs').Activated:Fire()
    f:button('Copy eggs').Activated:Fire()
    assert(f.http.lastPayload.eggSelection.runtimeErrors.ui:find('mock UI write fault',1,true))
    counter.failWrite=false;f:button('Scan eggs').Activated:Fire();assert(counter.Text:find('0 eggs',1,true))
end)
check('unexpected Hatch faults disable automation instead of retrying',function()
    local f=fixture();f:run();f:button('Auto Hatch: OFF').Activated:Fire()
    f.player.Character.failClassLookup=true;f:button('Test Hatch once').Activated:Fire()
    local queued=f.tasks[#f.tasks];queued.fn(table.unpack(queued.args))
    f:button('Auto Hatch: OFF')
    local found=false
    for _,obj in ipairs(f.objects) do if obj.ClassName=='TextLabel' and obj.Text:find('mock character lookup fault',1,true) then found=true end end
    assert(found)
end)
check('game data modules load only after the explicit button is clicked',function()
    local f=fixture();local calls=0
    f.env.require=function(module) calls=calls+1;return {name=module.Name,perSecond=12} end
    local storage=f.env.game:GetService('ReplicatedStorage')
    local function make(class,name,parent) local obj=f.env.Instance.new(class);obj.Name=name;obj.Parent=parent;return obj end
    local data=make('Folder','Data',storage);make('ModuleScript','Assets',data);make('ModuleScript','Rarity',data)
    make('ModuleScript','AssetEarnings',make('Folder','Util',make('Folder','Shared',storage)))
    f:run();assert(calls==0)
    f.env.task.spawn=function(fn,...) fn(...) end
    f:button('Read game data').Activated:Fire();assert(calls==3)
    f:button('Copy eggs').Activated:Fire()
    assert(f.http.lastPayload.eggSelection.definitionDiscovery.loaded==3)
end)
check('game data button blocks loading while automation is enabled',function()
    local f=fixture();local calls=0;f.env.require=function() calls=calls+1;return {} end
    f:run();f.env.task.spawn=function(fn,...) fn(...) end
    f:button('Auto Hatch: OFF').Activated:Fire();f:button('Read game data').Activated:Fire()
    assert(calls==0)
end)
check('game data UI shows Directory coverage and exports compact records',function()
    local f=fixture()
    f.env.require=function(module)
        if module.Name=='Assets' then
            return {Directory={Raccoon={_id='Raccoon',DisplayName='Raccoon',EarningRate=45,
                Egg={DisplayName='Raccoon Egg'},Rarity={_id='Rare',Rank=3},Icon='omit'}}}
        end
        return {}
    end
    local storage=f.env.game:GetService('ReplicatedStorage')
    local function make(class,name,parent) local obj=f.env.Instance.new(class);obj.Name=name;obj.Parent=parent;return obj end
    local data=make('Folder','Data',storage);make('ModuleScript','Assets',data);make('ModuleScript','Rarity',data)
    make('ModuleScript','AssetEarnings',make('Folder','Util',make('Folder','Shared',storage)))
    f:run();f.env.task.spawn=function(fn,...) fn(...) end
    f:button('Read game data').Activated:Fire()
    local found=false
    for _,obj in ipairs(f.objects) do if obj.ClassName=='TextLabel' and obj.Text:find('Directory: 1/1',1,true) then found=true end end
    assert(found)
    f:button('Copy eggs').Activated:Fire()
    local directory=f.http.lastPayload.eggSelection.definitionDiscovery.modules[1].directory
    assert(directory.complete and directory.entries[1].EarningRate==45 and not directory.entries[1].Icon)
end)
print(string.format('%d runtime startup tests passed',tests))
