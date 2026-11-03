-- Roll-A-Stickman Neon V2: UI framework only (no automation or network calls)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local parent = (type(gethui) == "function" and gethui()) or player:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("RollAStickmanNeonV2")
if old then old:Destroy() end

local C = {
 bg=Color3.fromRGB(12,10,27), panel=Color3.fromRGB(25,17,44),
 card=Color3.fromRGB(35,23,60), accent=Color3.fromRGB(151,76,255),
 text=Color3.fromRGB(245,235,255), muted=Color3.fromRGB(175,153,207)
}
local state = {running=false,toggles={},selections={},values={MoonInterval=5},page="Status"}
local function create(class,props,parentObject)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parentObject
 return o
end
local function round(o,r) create("UICorner",{CornerRadius=UDim.new(0,r or 9)},o) end
local function label(s,h,parentObject,size,color)
 return create("TextLabel",{
  Size=UDim2.new(1,0,0,h),BackgroundTransparency=1,
  Text=s,TextColor3=color or C.text,Font=Enum.Font.Gotham,TextSize=size or 13,
  TextXAlignment=Enum.TextXAlignment.Left
 },parentObject)
end
local function button(s,parentObject,h,callback)
 local b=create("TextButton",{
  Size=UDim2.new(1,0,0,h or 34),BackgroundColor3=C.card,
  TextColor3=C.text,Text=s,Font=Enum.Font.GothamMedium,TextSize=13
 },parentObject)
 round(b,7)
 if callback then b.MouseButton1Click:Connect(callback) end
 return b
end

local gui=create("ScreenGui",{Name="RollAStickmanNeonV2",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
local window=create("Frame",{
 Name="Window",Size=UDim2.fromOffset(670,460),
 Position=UDim2.new(0.5,-335,0.5,-230),BackgroundColor3=C.bg,Active=true
},gui)
round(window,12)
create("UIStroke",{Color=C.accent,Thickness=1,Transparency=0.45},window)
local header=create("Frame",{
 Size=UDim2.new(1,-20,0,46),Position=UDim2.fromOffset(10,8),
 BackgroundTransparency=1,Active=true
},window)
label("ROLL A STICKMAN  /  NEON V2",42,header,17)
local close=create("TextButton",{
 Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-32,0,6),
 BackgroundColor3=C.card,Text="X",TextColor3=C.text,TextSize=18
},header)
round(close,6)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local mini=create("TextButton",{
 Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-65,0,6),
 BackgroundColor3=C.card,Text="-",TextColor3=C.text,TextSize=20
},header)
round(mini,6)

-- Left sidebar navigation
local nav=create("ScrollingFrame",{
 Size=UDim2.fromOffset(145,344),Position=UDim2.fromOffset(12,62),
 BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=3,
 CanvasSize=UDim2.new()
},window)
round(nav,9)
local navLayout=create("UIListLayout",{Padding=UDim.new(0,5)},nav)
create("UIPadding",{
 PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,7),
 PaddingRight=UDim.new(0,7)
},nav)
navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
 nav.CanvasSize=UDim2.fromOffset(0,navLayout.AbsoluteContentSize.Y+18)
end)

-- Main content at the right
local content=create("ScrollingFrame",{
 Size=UDim2.new(1,-182,1,-127),Position=UDim2.fromOffset(169,62),
 BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,
 CanvasSize=UDim2.new()
},window)
round(content,9)
local layout=create("UIListLayout",{Padding=UDim.new(0,8)},content)
create("UIPadding",{
 PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,12),
 PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,10)
},content)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
 content.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+24)
end)

local footer=create("Frame",{
 Size=UDim2.new(1,-24,0,40),Position=UDim2.new(0,12,1,-48),
 BackgroundTransparency=1
},window)
local start=create("TextButton",{
 Size=UDim2.new(0.49,0,1,0),BackgroundColor3=C.accent,
 Text="START ALL",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=13
},footer)
round(start,8)
local stop=create("TextButton",{
 Size=UDim2.new(0.49,0,1,0),Position=UDim2.new(0.51,0,0,0),
 BackgroundColor3=C.card,Text="STOP ALL",TextColor3=C.text,
 Font=Enum.Font.GothamBold,TextSize=13
},footer)
round(stop,8)

local pages={"Status","Team","Fight","Potion","Pet","Open Card","Moon","Settings"}
local auroras={"Normal x1","Aurora A (placeholder)","Aurora B (placeholder)","Aurora C (placeholder)"}
local navButtons={}
local render
local function section(s) label(s,28,content,16,C.accent) end
local function toggle(s,initial)
 if state.toggles[s]==nil then state.toggles[s]=initial or false end
 local b=button("",content,35)
 local function refresh()
  b.Text=(state.toggles[s] and "[ON] " or "[OFF] ")..s
 end
 refresh()
 b.MouseButton1Click:Connect(function()
  state.toggles[s]=not state.toggles[s]
  refresh()
 end)
end
local function choice(title,options)
 label(title,23,content,13,C.muted)
 state.selections[title]=state.selections[title] or {}
 for _,option in ipairs(options) do
  local b=button("",content,30)
  local function refresh()
   b.Text=(state.selections[title][option] and "[x] " or "[ ] ")..option
  end
  refresh()
  b.MouseButton1Click:Connect(function()
   state.selections[title][option]=not state.selections[title][option]
   refresh()
  end)
 end
end
local function numberSetting(title,key,minimum,maximum,step)
 label(title,22,content,13,C.muted)
 local row=create("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},content)
 local minus=create("TextButton",{
  Size=UDim2.fromOffset(45,34),BackgroundColor3=C.card,
  Text="-",TextColor3=C.text,TextSize=18
 },row)
 round(minus,7)
 local value=create("TextLabel",{
  Size=UDim2.new(1,-100,1,0),Position=UDim2.fromOffset(50,0),
  BackgroundTransparency=1,TextColor3=C.text,TextSize=14
 },row)
 local plus=create("TextButton",{
  Size=UDim2.fromOffset(45,34),Position=UDim2.new(1,-45,0,0),
  BackgroundColor3=C.card,Text="+",TextColor3=C.text,TextSize=18
 },row)
 round(plus,7)
 local function refresh() value.Text=tostring(state.values[key]) end
 refresh()
 minus.MouseButton1Click:Connect(function()
  state.values[key]=math.max(minimum,state.values[key]-step)
  refresh()
 end)
 plus.MouseButton1Click:Connect(function()
  state.values[key]=math.min(maximum,state.values[key]+step)
  refresh()
 end)
end
local function clearContent()
 for _,child in ipairs(content:GetChildren()) do
  if child:IsA("GuiObject") then child:Destroy() end
 end
end
render=function(page)
 state.page=page
 for name,b in pairs(navButtons) do
  b.BackgroundColor3=(name==page) and C.accent or C.card
 end
 clearContent()
 section(page)
 if page=="Status" then
  label("Automation: "..(state.running and "RUNNING" or "STOPPED"),30,content,14)
  for _,p in ipairs(pages) do
   if p~="Status" and p~="Settings" then
    label(p..": "..(state.toggles["Enable "..p] and "ON" or "OFF"),25,content,13)
   end
  end
 elseif page=="Team" then
  toggle("Enable Team")
  choice("Team Mode",{"Automatic","Manual"})
 elseif page=="Fight" then
  toggle("Enable Fight")
  choice("Fight Target",{"Automatic","Selected target"})
 elseif page=="Potion" then
  toggle("Enable Potion")
  choice("Potion Types",{"Luck Potion","Pet Luck Potion","Other Potion"})
  choice("Use Potion When - Aurora",auroras)
 elseif page=="Pet" then
  toggle("Enable Pet")
  choice("Boost Luck Pet When",auroras)
  choice("Boost Card from Play (if not Aurora)",auroras)
 elseif page=="Open Card" then
  toggle("Enable Open Card")
  toggle("Open on Normal x1")
  toggle("Require Luck Potion + Pet Luck")
  choice("Card Aurora Filter",auroras)
 elseif page=="Moon" then
  toggle("Enable Moon")
  numberSetting("Moon refresh interval (minutes)","MoonInterval",1,15,1)
 elseif page=="Settings" then
  toggle("Notifications",true)
  toggle("Auto Save Config")
  label("UI only: settings are session-local.",30,content,12,C.muted)
 end
end
local icons={Status="*",Team="T",Fight="F",Potion="P",Pet="Pt",["Open Card"]="C",Moon="M",Settings="S"}
for _,p in ipairs(pages) do
 local b=button("  "..icons[p].."   "..p,nav,36,function() render(p) end)
 b.TextXAlignment=Enum.TextXAlignment.Left
 navButtons[p]=b
end
start.MouseButton1Click:Connect(function()
 state.running=true
 render(state.page)
end)
stop.MouseButton1Click:Connect(function()
 state.running=false
 render(state.page)
end)
local minimized=false
mini.MouseButton1Click:Connect(function()
 minimized=not minimized
 nav.Visible=not minimized
 content.Visible=not minimized
 footer.Visible=not minimized
 window.Size=minimized and UDim2.fromOffset(670,58) or UDim2.fromOffset(670,460)
end)

local dragging=false
local dragStart,startPos
header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1
 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true
  dragStart=input.Position
  startPos=window.Position
 end
end)
UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
 or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=input.Position-dragStart
  window.Position=UDim2.new(
   startPos.X.Scale,startPos.X.Offset+delta.X,
   startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1
 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
render("Status")
print("Roll-A-Stickman Neon V2 UI loaded (UI only)")
