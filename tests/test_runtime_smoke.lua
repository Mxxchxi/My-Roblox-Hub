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
            if k=='Focused' or k=='FocusLost' or k=='Activated' or k=='InputBegan' or k=='InputChanged' or k=='InputEnded' or k=='AncestryChanged' or k=='CharacterAdded' or k=='DescendantAdded' or k=='DescendantRemoving' or k=='PromptShown' then props.signals[k]=props.signals[k] or signal();return props.signals[k] end
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
    function f:run(s)
        if s then assert(load(s,'@Loader.lua','t',env))()
        else self.probe=assert(load(source..'\nreturn {snapshot=collectSnapshot,logReport=eggLogic.logReport,log=eggLogic.log,bootstrap=eggLogic.bootstrapField}', '@Games/StealAnEgg_Diagnostics.lua','t',env))() end
    end
    function f:button(text) for _,obj in ipairs(pg:GetDescendants()) do if obj.ClassName=='TextButton' and obj.Text==text then return obj end end;error('Button missing: '..text) end
    function f:liveConnections() local n=0;for _,s in ipairs(signals) do for _,c in ipairs(s.handlers) do if c.Connected then n=n+1 end end end;return n end
    function f:loaderStatus() local g=assert(pg:FindFirstChild('MyRobloxHub_LoaderStatus'));return g:FindFirstChildOfClass('TextLabel').Text end
    function f:tick()
        local start=assert(source:find('task.spawn(function()\n    while active do\n        task.wait(1)',1,true))
        local _,count=source:sub(1,start):gsub('\n','');local scheduler
        for _,job in ipairs(tasks) do if debug.getinfo(job.fn,'S').linedefined==count+1 then scheduler=job.fn end end
        assert(scheduler)
        local oldWait,oldSpawn=env.task.wait,env.task.spawn;local ticks=0
        env.task.spawn=function(fn,...) fn(...) end
        env.task.wait=function(seconds)
            if seconds==1 then ticks=ticks+1;if ticks>1 then error('end simulated tick') end end
        end
        local ok,err=pcall(scheduler)
        env.task.wait,env.task.spawn=oldWait,oldSpawn
        assert(not ok and tostring(err):find('end simulated tick',1,true),tostring(err))
    end
    function f:logBox()
        for _,obj in ipairs(objects) do if obj.Name=='LogText' then return obj end end;error('Log TextBox missing')
    end
    function f:logHint()
        for _,obj in ipairs(objects) do if obj.Name=='LogHint' then return obj.Text end end;error('Log hint missing')
    end
    function f:copyLog()
        local oldSpawn,oldWait,oldDefer=env.task.spawn,env.task.wait,env.task.defer
        env.task.spawn=function(fn,...) fn(...) end;env.task.defer=env.task.spawn;env.task.wait=function() end
        self:button('Copy log').Activated:Fire()
        env.task.spawn,env.task.wait,env.task.defer=oldSpawn,oldWait,oldDefer
    end
    function f:state()
        return {autoCollect=self.probe.snapshot(true)}
    end
    return f
end
local function check(name,fn) fn();tests=tests+1;print('PASS '..name) end
check('full egg script constructs every tab and starts all automation OFF',function()
    local f=fixture();f:run();local gui=assert(f.pg:FindFirstChild('EggDiagnostics'))
    assert(gui.Enabled and gui.DisplayOrder==1000)
    for _,name in ipairs({'Automation','Settings','Log','Copy log','Select all','Clear log','Auto Hatch: OFF','Collect: OFF','Upgrade: OFF','Train: OFF','Priority: RARITY'}) do f:button(name) end
end)
check('UI stays positively scaled while camera viewport is not ready',function()
    local f=fixture({width=1,height=1});f:run()
    for _,obj in ipairs(f.objects) do if obj.ClassName=='UIScale' then assert(obj.Scale>0 and obj.Scale<=1) end end
end)
check('remaining tabs and priority work before a character humanoid is available',function()
    local f=fixture();f:run()
    for _,name in ipairs({'Settings','Log','Automation'}) do f:button(name).Activated:Fire() end
    f:button('Priority: RARITY').Activated:Fire();f:button('Priority: NEAREST')
end)
check('Alt hides and restores the window and leaves restore control accessible',function()
    local f=fixture();f:run();local frames={};for _,obj in ipairs(f.objects) do if obj.ClassName=='Frame' and obj.Parent==f.pg:FindFirstChild('EggDiagnostics') then frames[#frames+1]=obj end end
    local input={KeyCode=f.env.Enum.KeyCode.LeftAlt};f.ui.InputBegan:Fire(input,false);f.ui.InputEnded:Fire(input)
    assert(not frames[1].Visible and f:button('YUU HUB').Visible)
    f:button('YUU HUB').Activated:Fire();assert(frames[1].Visible)
end)
check('removed pages and placement diagnostic actions have no controls',function()
    local f=fixture();f:run()
    for _,name in ipairs({'Placement','Diagnostics','Auto Place: DISABLED','Mark empty slot','Clear slots',
        'Auto mark empty slots','Manual placement','Record placement: OFF','Scan / Refresh','Copy all','Copy short',
        'Save file','Select ALL','< Page','Page >'}) do assert(not pcall(function() f:button(name) end)) end
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
check('unexpected Hatch faults disable automation instead of retrying',function()
    local f=fixture();f:run();f:button('Auto Hatch: OFF').Activated:Fire()
    f.player.Character.failClassLookup=true;f:button('Test Hatch once').Activated:Fire()
    local queued=f.tasks[#f.tasks];queued.fn(table.unpack(queued.args))
    f:button('Auto Hatch: OFF')
    local found=false
    for _,obj in ipairs(f.objects) do if obj.ClassName=='TextLabel' and obj.Text:find('mock character lookup fault',1,true) then found=true end end
    assert(found)
end)
local function autoModules(f)
    local storage=f.env.game:GetService('ReplicatedStorage')
    local function make(class,name,parent) local obj=f.env.Instance.new(class);obj.Name=name;obj.Parent=parent;return obj end
    local data=make('Folder','Data',storage);make('ModuleScript','Assets',data);make('ModuleScript','Rarity',data)
    make('ModuleScript','AssetEarnings',make('Folder','Util',make('Folder','Shared',storage)))
    local calls=0
    f.env.require=function(module)
        calls=calls+1
        if module.Name=='Assets' then return {Directory={Raccoon={_id='Raccoon',DisplayName='Raccoon',EarningRate=45,
            Egg={DisplayName='Raccoon Egg'},Rarity={_id='Rare',DisplayName='Rare',Rank=3}}}} end
        if module.Name=='Rarity' then return {Rarities={Rare={_id='Rare',DisplayName='Rare',Rank=3}}} end
        return {LiveRatePerSecond=function() error('must not call exported earnings') end}
    end
    return function() return calls end
end
check('Eggs tab and all manual egg controls are removed',function()
    local f=fixture();f:run()
    for _,name in ipairs({'Eggs','Scan eggs','Read game data','Scan sources','Copy eggs','Apply names','Mode: NEAREST'}) do
        assert(not pcall(function() f:button(name) end))
    end
end)
check('two-tab startup remains OFF without automatic module or report work',function()
    local f=fixture();local calls=autoModules(f)
    f.http.JSONEncode=function() error('removed report encoder must not run') end
    f:run();local r=f:state()
    assert(not r.autoCollect.enabled and calls()==0)
    assert(r.autoCollect.eggSelection.mode=='Rarity' and r.autoCollect.eggSelection.automaticDiscovery.status=='idle')
end)
check('Collect ON automatically loads rank modules with only Automation and Settings',function()
    local f=fixture();local calls=autoModules(f);f:run();assert(calls()==0)
    f:button('Collect: OFF').Activated:Fire();f:tick();f:button('Collect: ON')
    local r=f:state();local e=r.autoCollect.eggSelection
    assert(calls()==3 and e.automaticDiscovery.status=='ready' and e.definitionDiscovery.trigger=='collect_on')
    assert(e.catalog.rarityRanking.ready and e.definitionDiscovery.modules[1].directory.exported==1)
end)
check('automatic discovery reuses cached definitions after OFF ON',function()
    local f=fixture();local calls=autoModules(f);f:run()
    f:button('Collect: OFF').Activated:Fire();f:tick()
    f:button('Collect: ON').Activated:Fire();f:button('Collect: OFF').Activated:Fire();f:tick()
    assert(calls()==3 and f:state().autoCollect.enabled)
end)
check('priority toggle switches Rarity Nearest without loading modules and is locked while Collect runs',function()
    local f=fixture();local calls=autoModules(f);f:run()
    f:button('Priority: RARITY').Activated:Fire();f:button('Priority: NEAREST')
    f:button('Collect: OFF').Activated:Fire();f:button('Priority: NEAREST').Activated:Fire();f:button('Priority: NEAREST')
    f:tick();assert(calls()==0)
    f:button('Collect: ON').Activated:Fire();f:button('Priority: NEAREST').Activated:Fire();f:button('Priority: RARITY')
end)
check('automatic read failure leaves Collect ON and avoids repeated immediate loading',function()
    local f=fixture();autoModules(f);local calls=0;f.env.require=function() calls=calls+1;error('temporary load failure') end
    f:run();f:button('Collect: OFF').Activated:Fire();f:tick();assert(calls==3)
    f:tick();f:button('Collect: ON');assert(calls==3)
    local e=f:state().autoCollect.eggSelection
    assert(e.automaticDiscovery.status=='waiting_retry' and e.automaticDiscovery.retryInSeconds>0)
end)
check('OFF during module initialization cancels discovery and prevents later collection',function()
    local f=fixture();autoModules(f);local calls=0
    f.env.require=function() calls=calls+1;f:button('Collect: ON').Activated:Fire();return {} end
    f:run();f:button('Collect: OFF').Activated:Fire();f:tick();f:button('Collect: OFF')
    local r=f:state();assert(calls==1 and not r.autoCollect.enabled and r.autoCollect.eggSelection.automaticDiscovery.status=='cancelled')
end)
check('scheduler keeps Collect ON and displays retry reason when home is unavailable',function()
    local f=fixture();f:run();f:button('Priority: RARITY').Activated:Fire()
    f:button('Collect: OFF').Activated:Fire();f:tick();f:button('Collect: ON')
    local r=f:state();assert(r.autoCollect.enabled and r.autoCollect.phase=='WAITING_RETRY')
    local visible=false
    for _,obj in ipairs(f.objects) do if obj.ClassName=='TextLabel' and obj.Text:find('Auto home not ready',1,true) then visible=true end end
    assert(visible)
    assert(r.autoCollect.retry.reason:find('Auto home not ready',1,true))
    f:button('Collect: ON').Activated:Fire();local stopped=f:state();assert(not stopped.autoCollect.enabled and not stopped.autoCollect.retry)
end)
check('Log tab renders compact current state and history',function()
    local f=fixture();f:run();f:button('Log').Activated:Fire()
    local text=f:logBox().Text
    assert(text:find('v1.59',1,true) and text:find('hub.ready',1,true) and text:find('Collect: OFF',1,true))
    assert(#text<=18000 and f:logBox().TextEditable and f:logBox().ClearTextOnFocus==false)
end)
check('Copy log verifies clipboard readback against the exact displayed snapshot',function()
    local f=fixture();local copied;f.env.setclipboard=function(text) copied=text end;f.env.getclipboard=function() return copied end
    f:run();f:copyLog()
    assert(copied==f:logBox().Text and f:logHint():find('Copied and verified',1,true))
end)
check('missing clipboard APIs leave the fixed log selected for native copy',function()
    local f=fixture();f:run();f:copyLog();local box=f:logBox()
    assert(box.Text:find('MY ROBLOX HUB',1,true) and box.SelectionStart==1 and box.CursorPosition==#box.Text+1)
    assert(f:logHint():find('Copy not verified',1,true) and f:logHint():find('Ctrl+A / Ctrl+C',1,true))
end)
check('throwing clipboard writer falls back to native selection and can be retried',function()
    local f=fixture();local attempts=0;f.env.setclipboard=function() attempts=attempts+1;error('unavailable clipboard') end
    f:run();f:copyLog();f:copyLog()
    assert(attempts==2 and f:logBox().SelectionStart==1 and f:logHint():find('not verified',1,true))
end)
check('a writer with no reader is never claimed verified',function()
    local f=fixture();local copied;f.env.setclipboard=function(text) copied=text end
    f:run();f:copyLog();assert(copied==f:logBox().Text and f:logHint():find('not verified',1,true))
end)
check('a no-op writer with stale readback leaves the current log selected',function()
    local f=fixture();f.env.setclipboard=function() end;f.env.getclipboard=function() return 'stale clipboard' end
    f:run();f:copyLog();assert(f:logHint():find('not verified',1,true) and f:logBox().Text~='stale clipboard')
end)
check('new events cannot overwrite the snapshot during manual copying',function()
    local f=fixture();f:run();f:copyLog();local captured=f:logBox().Text
    f.probe.log('after.copy','new event after snapshot');f:tick()
    assert(f:logBox().Text==captured)
    f:button('Automation').Activated:Fire();f:button('Log').Activated:Fire()
    assert(f:logBox().Text:find('new event after snapshot',1,true))
end)
check('clicking the log text freezes live updates for Ctrl A Ctrl C',function()
    local f=fixture();f:run();f:button('Log').Activated:Fire();local captured=f:logBox().Text
    f:logBox().Focused:Fire();f.probe.log('after.focus','new event');f:tick()
    assert(f:logBox().Text==captured)
end)
check('Clear log removes history without stopping active collection',function()
    local f=fixture();f:run();f:button('Priority: RARITY').Activated:Fire();f:button('Collect: OFF').Activated:Fire();f:tick()
    f.probe.log('old-history','remove this history');f:copyLog();f:button('Clear log').Activated:Fire()
    assert(f:state().autoCollect.enabled and not f:logBox().Text:find('remove this history',1,true))
    assert(f:logBox().Text:find('buffer 0 / 60',1,true))
end)
check('closing the hub cancels a queued clipboard attempt',function()
    local f=fixture();local writes=0;f.env.setclipboard=function() writes=writes+1 end
    f:run();f:button('Copy log').Activated:Fire();local queued=f.tasks[#f.tasks]
    f:button('X').Activated:Fire();queued.fn(table.unpack(queued.args));assert(writes==0 and f:liveConnections()==0)
end)
check('Clear log invalidates an older queued clipboard snapshot',function()
    local f=fixture();local writes=0;f.env.setclipboard=function() writes=writes+1 end
    f:run();f:button('Copy log').Activated:Fire();local queued=f.tasks[#f.tasks]
    f:button('Clear log').Activated:Fire();queued.fn(table.unpack(queued.args));assert(writes==0)
    f:copyLog();assert(writes==1)
end)
local function snapshotModule(f,response)
    local storage=f.env.game:GetService('ReplicatedStorage')
    local packages=f.env.Instance.new('Folder');packages.Name='Packages';packages.Parent=storage
    local networking=f.env.Instance.new('Folder');networking.Name='Networking';networking.Parent=packages
    local remote=f.env.Instance.new('RemoteFunction');remote.Name='RF/EggWorld/AskFieldEggSnapshot';remote.Parent=networking
    local calls=0
    function remote:InvokeServer(...)
        assert(select('#',...)==0);calls=calls+1
        return type(response)=='function' and response() or response
    end
    return function() return calls end
end
local function bootstrapNow(f)
    local old=f.env.task.spawn;f.env.task.spawn=function(fn) fn() end
    local ok,result=pcall(f.probe.bootstrap);f.env.task.spawn=old
    assert(ok,tostring(result));return result
end
check('full script snapshot bootstrap fills an initially empty cache and exposes the result in Copy log',function()
    local f=fixture();autoModules(f)
    local calls=snapshotModule(f,{Records={{Uid='snapshot-a',AssetCategory='Raccoon',Position={X=3,Y=0,Z=0}}}})
    f:run();f:button('Collect: OFF').Activated:Fire();f:tick()
    assert(bootstrapNow(f) and calls()==1 and f:state().autoCollect.eggSelection.catalog.fieldData.stored==1)
    f:copyLog();assert(f:logBox().Text:find('Field snapshot: received',1,true) and f:logBox().Text:find('imported 1',1,true))
end)
check('OFF during snapshot invocation discards the reply and keeps the button OFF',function()
    local f=fixture();autoModules(f)
    snapshotModule(f,function()
        f:button('Collect: ON').Activated:Fire()
        return {Records={{Uid='snapshot-a',AssetCategory='Raccoon',Position={X=3,Y=0,Z=0}}}}
    end)
    f:run();f:button('Collect: OFF').Activated:Fire();f:tick()
    assert(not bootstrapNow(f));f:button('Collect: OFF')
    assert(f:state().autoCollect.eggSelection.catalog.fieldData.stored==0)
end)
check('snapshot invocation failure remains ON and produces a useful compact log',function()
    local f=fixture();autoModules(f);snapshotModule(f,function() error('missing snapshot parameter') end)
    f:run();f:button('Collect: OFF').Activated:Fire();f:tick();assert(not bootstrapNow(f));f:button('Collect: ON')
    f:copyLog();assert(f:logBox().Text:find('missing snapshot parameter',1,true))
end)
check('copying the log does not invoke snapshot RPCs',function()
    local f=fixture();autoModules(f);local calls=snapshotModule(f,{Records={}})
    f:run();f:copyLog();f:copyLog();assert(calls()==0)
end)
check('pickup input cycles only while Collect is stopped',function()
    local f=fixture();f:run()
    f:button('Pickup input: AUTO').Activated:Fire();f:button('Pickup input: PROMPT').Activated:Fire()
    f:button('Pickup input: KEYBOARD').Activated:Fire();f:button('Pickup input: AUTO')
    f:button('Collect: OFF').Activated:Fire();f:button('Pickup input: AUTO').Activated:Fire()
    f:button('Pickup input: AUTO');f:copyLog()
    assert(f:logBox().Text:find('Pickup input: Auto',1,true))
end)
print(string.format('%d runtime startup tests passed',tests))

