local isvoid = game.PlaceId==11879754496
local defaultdata = {mac = false}
local data = ({...})[1]
data = data and type(data)=="table" and data or defaultdata
for i,v in pairs(defaultdata) do
	data[i]=data[i] or v
end
if data.mac then
	setthreadidentity(2)
end
local optimize = false

if game.CoreGui:FindFirstChild("killmenow") then
	game.CoreGui:FindFirstChild("killmenow"):Destroy()
end

local players = game:GetService("Players")
local plr = players.LocalPlayer
local mouse = plr:GetMouse()
local char = plr.Character
local root:Part = if char then char:FindFirstChild("HumanoidRootPart") else nil
local hum:Humanoid = if char then char:FindFirstChild("Humanoid") else nil
plr.CharacterAdded:Connect(function()
	char = plr.Character
	root = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
end)
local rep = game:GetService("ReplicatedStorage")
local rs = game:GetService("RunService")
local input = game:GetService("UserInputService")
local keycodes = Enum.KeyCode:GetEnumItems()
local ts = game:GetService("TeleportService")
local cam = workspace.CurrentCamera

local packets = not isvoid and require(rep.Modules.Packets) or {}
if isvoid then
	for i,v in pairs(rep:WaitForChild("Events"):GetChildren()) do
		if v:IsA("RemoteEvent") then
			packets[v.Name]={send=function(...) v:FireServer(...) end}
		end
	end
end
local bytenet:RemoteEvent = if not isvoid then rep:FindFirstChild("ByteNetReliable") else nil

local offloaded:Instance = not isvoid and game:GetService("ReplicatedFirst").Animals.Offloaded or Instance.new("Folder")
local statsgui = plr.PlayerGui:WaitForChild("MainGui"):WaitForChild("Panels"):WaitForChild("Stats")
local inventorygui = plr.PlayerGui:WaitForChild("MainGui"):WaitForChild("RightPanel"):WaitForChild("Inventory"):WaitForChild("List")

local uilib = loadstring(game:HttpGet("https://github.com/huhthatsnice/pro/raw/main/uilib.lua"))()

local window = uilib:CreateWindow("Pineapple V1")
window.ScreenGui.Name="killmenow"

--functions

local veltoggle = Instance.new("BodyVelocity")
veltoggle.P=math.huge
veltoggle.Velocity=Vector3.new()
veltoggle.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
task.spawn(function()
	while true do rs.PreSimulation:Wait()
		if veltoggle.Parent and veltoggle.Parent:IsA("BasePart") then
			veltoggle.Parent.Velocity=Vector3.new(veltoggle.MaxForce.X==0 and veltoggle.Parent.Velocity.X or 0,veltoggle.MaxForce.Y==0 and veltoggle.Parent.Velocity.Y or 0,veltoggle.MaxForce.Z==0 and veltoggle.Parent.Velocity.Z or 0)
		end
	end
end)

local function merge(t1,...)
	for i,t2 in pairs({...}) do
		table.move(t2,1,#t2,#t1+1,t1)
	end
	return t1
end
local function remove(t1,find)
	return table.remove(t1,table.find(t1,find))
end
local function getClose(t:{Instance},range,ffunc:(i,v)->BasePart)
	if not root then return end
	ffunc=ffunc or function(i,v) return v end
	local ret = {}
	for i,v in pairs(t) do
		v=ffunc(i,v)
		if (v.Position-root.Position).Magnitude<range then
			ret[v]=i
		end
	end
	return ret
end
local rainparts = {}
for i,v in pairs(workspace:GetChildren()) do
	if v.Name=="RainPart" then
		table.insert(rainparts,v)
	end
end
workspace.ChildAdded:Connect(function(v)
	if v.Name=="RainPart" then
		table.insert(rainparts,v)
	end
end)
local plrchars = {}
for i,v in pairs(game:GetService("Players"):GetPlayers()) do
	plrchars[v]=v.Character
	v.CharacterAdded:Connect(function(c)
		plrchars[v]=v.Character
		local char = v.Character
		char:GetPropertyChangedSignal("Parent"):Connect(function()
			if char.Parent==nil then
				plrchars[v]=nil
			end
		end)
	end)
	if not v.Character then continue end
	local char = v.Character
	char:GetPropertyChangedSignal("Parent"):Connect(function()
		if char.Parent==nil then
			plrchars[v]=nil
		end
	end)
end
local function getMover(part)
	for i,v in pairs(part:GetDescendants()) do
		if not v:IsA("BasePart") then continue end
		local ocf = v.CFrame
		v.CFrame=CFrame.new()
		if v.CFrame==CFrame.new() then
			v.CFrame=ocf
			return v
		end
	end
end
local function getMovePart():BasePart
	if not root then return nil end
	if not (hum and root and hum.SeatPart and hum.SeatPart.Parent) then return root end
	return getMover(hum.SeatPart.Parent) or root
end
local function moveTo(pos:CFrame)
	if not getMovePart() then return end
	if typeof(pos)=="Vector3" then pos = CFrame.new(pos) end
	local move=getMovePart()
	local dif = (move.CFrame.Position-root.CFrame.Position)
	move.CFrame = pos+dif
end
local function getMovementRaycastParams()
	local rp = RaycastParams.new()
	rp.IgnoreWater=true
	rp.FilterType=Enum.RaycastFilterType.Exclude
	local filt=merge({workspace:FindFirstChild("Items"),getMovePart() and getMovePart().Parent},rainparts)
	for i,v in pairs(game:GetService("Players"):GetPlayers()) do
		table.insert(filt,v.Character)
	end
	rp.FilterDescendantsInstances=filt
	return rp
end
local vels = {}
local parts = {}
local function disableBoat()
	if not getMovePart() then return end
	for i,v in pairs(getMovePart().Parent:GetDescendants()) do
		if v~=veltoggle and (v:IsA("BodyVelocity") or v:IsA("BodyPosition")) then
			vels[v]=v.MaxForce
			v.MaxForce=Vector3.new()
		elseif v:IsA("BasePart") then
			table.insert(parts,v)
			v.CanCollide=false
			v.Massless=true
		end
	end
	veltoggle.Parent=getMovePart()
	veltoggle.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
end
local function enableBoat()
	for i,v in pairs(vels) do
		i.MaxForce=v
	end
	for i,v in pairs(parts) do
		v.CanCollide=true
		v.Massless=false
	end
	table.clear(vels)
	table.clear(parts)
	veltoggle.Parent=nil
end
local function teleportStepToward(pos,rate,step,height)
	local posflat=Vector3.new(pos.X,0,pos.Z)
	local cposflat=Vector3.new(root.CFrame.Position.X,0,root.CFrame.Position.Z)
	local dir = (posflat-cposflat).Unit
	local dist = (posflat-cposflat).Magnitude
	if dir.X~=dir.X then
		dir=Vector3.new()
	end
	cposflat+=dir*math.clamp((step or rs.PreSimulation:Wait())*rate,0,dist)
	local ray = workspace:Raycast(cposflat+Vector3.new(0,getMovePart().Position.Y+25,0),Vector3.new(0,-10000,0),getMovementRaycastParams())
	if ray then
		moveTo(ray.Position+Vector3.new(0,height or 3.5,0))
	end
end
local function teleportTo(pos:Vector3,rate:number,reenable:boolean,validator:()->boolean,height)
	local posflat=Vector3.new(pos.X,0,pos.Z)
	local cposflat=Vector3.new(root.CFrame.Position.X,0,root.CFrame.Position.Z)
	local dir = (posflat-cposflat).Unit

	disableBoat()
	while getMovePart() and validator() do
		local step = rate*rs.PreSimulation:Wait()
		if (cposflat-posflat).Magnitude<step then
			moveTo(pos)
			break
		else
			cposflat+=dir*step
			local ray = workspace:Raycast(cposflat+Vector3.new(0,1000,0),Vector3.new(0,-2000,0),getMovementRaycastParams())
			if ray then
				moveTo(ray.Position+Vector3.new(0,height or 5,0))
			end
		end
	end
	if reenable==nil or reenable then
		enableBoat()
	end
end
local function getSlot(name)
	if inventorygui:FindFirstChild(name) and not inventorygui[name]:IsA("UILayout") then
		return inventorygui[name].LayoutOrder
	end
end
local function getCount(name)
	if inventorygui:FindFirstChild(name) and not inventorygui[name]:IsA("UILayout") and inventorygui[name]:FindFirstChild("QuantityText",true) then
		return tonumber(inventorygui[name]:FindFirstChild("QuantityText",true).Text) or 0
	end
	return 0
end
local function trim(str)
	return string.gsub(str, '^%s*(.-)%s*$', '%1')
end
local function getServers(id)
	return game:GetService("HttpService"):JSONDecode(request({Url="https://games.roblox.com/v1/games/"..id.."/servers/0?sortOrder=2&excludeFullGames=true&limit=100"}).Body)
end
--devs fucking implemented buffers so now i gotta fucking make custom functions for the simplest shit --nevermind i figured it out :3

local itemids
local itemdata
for i,v in pairs(getreg()) do
	if type(v)=="table" then
		if not itemids and v[1]=="Wood" then
			itemids=v
		elseif not itemdata and type(v.Wood)=="table" and v.Wood.itemType then
			itemdata=v
		elseif itemids and itemdata then
			break
		end
	end
end
local function getItemId(name)
	if isvoid then return name end
	return table.find(itemids,name)
end
local function hit(parts)
	packets.SwingTool.send(parts)
end
local function useSlot(slot)
	packets.UseBagItem.send(slot)
end
local pickupbuf = buffer.create(2)
buffer.writeu8(pickupbuf,0,58)
buffer.writeu8(pickupbuf,1,1)
local function pickup(part)
	if isvoid or not optimize then
		packets.Pickup.send(part)
	else
		bytenet:FireServer(pickupbuf,{part})
	end
end
local function plant(box,plant)
	if not isvoid then
		packets.InteractStructure.send({structure=box,itemID=plant})
	else
		packets.InteractStructure.send(box,plant)
	end
end
local function grab(item)
	packets.ForceInteract.send(item)
end
local function craft(item)
	packets.CraftItem.send(item)
end
local function touch(p1,p2) --pray this doesn't crash
	pcall(function()
		firetouchinterest(p1,p2,1)
		firetouchinterest(p1,p2,0)
	end)
end
local function place(name,rot,pos)
	if not isvoid then
		packets.PlaceStructure.send({
			buildingName=name,
			yrot=rot,
			vec=pos,
			isMobile=false,
		})
	else
		packets.PlaceStructure.send(
			pos,
			name,
			rot,
			false
		)
	end
end
local pressbuf = buffer.create(4)
buffer.writeu8(pressbuf,0,19)
buffer.writeu8(pressbuf,1,1)
buffer.writeu16(pressbuf,2,if not isvoid then getItemId("Gold") else 0)
local function press(press)
	if isvoid or not optimize then return plant(press,"Gold") end
	bytenet:FireServer(pressbuf,{press})
end


--acctual script begin
local combat = window:AddTab("Combat")
local movement = window:AddTab("Movement")
local resource = window:AddTab("Resource")
local utility = window:AddTab("Utility")
local visuals = window:AddTab("Visuals")

local speed = movement:AddSection("Speed")
speed_enabled=speed:AddSetting("Enabled","Toggle")
speed_keybind=speed:AddSetting("Keybind","String","Y")
speed_speed=speed:AddSetting("Speed","Slider",23.5,0,25,0.1)
speed_boatspeed=speed:AddSetting("Boat Speed","Slider",65,0,75,0.1)
speed_floatheight=speed:AddSetting("Float Height","Slider",3,0,15,0.1)

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if speed_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		speed:UpdateSettingValue("Enabled",not speed_enabled.Value)
	end
end)
local lsp:BasePart
speed:ConnectSettingUpdate("Enabled",function()
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if not speed_enabled.Value and lsp and lsp.Parent then
		enableBoat()
		lsp = nil
	end
end)

task.spawn(function()
	while window.ScreenGui.Parent do
		local t = rs.PreSimulation:Wait()
		if autochasing or autofarm_enabled.Value then continue end
		if speed_enabled.Value and hum and root then
			if hum.SeatPart then
				disableBoat()
				lsp = hum.SeatPart
				local ray = workspace:Raycast(root.Position+(hum.MoveDirection*speed_boatspeed.Value*t)+Vector3.new(0,10,0),Vector3.new(0,-10000,0),getMovementRaycastParams())
				if ray then
					moveTo(getMovePart().CFrame.Rotation+ray.Position+Vector3.new(0,speed_floatheight.Value,0))
				else
					moveTo(getMovePart().CFrame+(hum.MoveDirection*speed_boatspeed.Value*t))
				end
			else
				if lsp and lsp.Parent then
					enableBoat()
				end
				veltoggle.Parent=root
				veltoggle.MaxForce=Vector3.new(math.huge,0,math.huge)
				root.CFrame+=hum.MoveDirection*speed_speed.Value*t
			end
		else
			enableBoat()
			veltoggle.Parent=nil
		end
	end
	enableBoat()
end)

local killaura = combat:AddSection("Killaura")
killaura_enabled = killaura:AddSetting("Enabled","Toggle")
killaura_keybind = killaura:AddSetting("Keybind","String","R")
killaura_range = killaura:AddSetting("Range","Slider",25,0,25,0.1)
killaura_rate = killaura:AddSetting("Rate","Slider",30,0,120,1)

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if killaura_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		killaura:UpdateSettingValue("Enabled",not killaura_enabled.Value)
	end
end)

local lasthit=0
task.spawn(function()
	while window.ScreenGui.Parent do
		local t = rs.PostSimulation:Wait()
		if killaura_enabled.Value and char and root and tick()-lasthit>(1/killaura_rate.Value) then
			local plrs = game:GetService("Players"):GetPlayers()
			local hits = {}
			for i,v in pairs(plrs) do
				if v and v ~= plr and (plr.Team.Name=="NoTribe" or plr.Neutral or plr.Team~=v.Team) and v.Character then
					local vroot:Part=v.Character:FindFirstChild("HumanoidRootPart")
					local vhum:Humanoid=v.Character:FindFirstChild("Humanoid")
					if vroot and vhum and (vroot.Position-root.Position).Magnitude<killaura_range.Value and vhum.Health>0 then
						for i,v in pairs(v.Character:GetChildren()) do
							if v:IsA("Part") then
								table.insert(hits,v)
							end
						end
					end
				end
			end
			for i,v in pairs(workspace.Critters:GetChildren()) do
				local vroot:Part=v:FindFirstChild("HumanoidRootPart")
				if vroot and (vroot.Position-root.Position).Magnitude<killaura_range.Value then
					for i,v in pairs(v:GetChildren()) do
						if v:IsA("Part") then
							table.insert(hits,v)
						end
					end
				end
			end
			if isvoid then
				for i,v in pairs(workspace:GetChildren()) do
					if v.Name=="Void Ant" then
						local vroot:Part=v:FindFirstChild("HumanoidRootPart")
						if vroot and (vroot.Position-root.Position).Magnitude<killaura_range.Value then
							for i,v in pairs(v:GetChildren()) do
								if v:IsA("Part") then
									table.insert(hits,v)
								end
							end
						end
					end
				end
			end
			if not isvoid then
				for i,v in pairs(workspace.HumanoidCritters:GetChildren()) do
					local vroot:Part=v:FindFirstChild("HumanoidRootPart")
					local vhum:Humanoid=v:FindFirstChild("Humanoid")
					if vroot and vhum and vhum.Health>0 and (vroot.Position-root.Position).Magnitude<killaura_range.Value then
						for i,v in pairs(v:GetChildren()) do
							if v:IsA("Part") then
								table.insert(hits,v)
							end
						end
					end
				end
			end
			if #hits>0 then
				hit(hits)
				lasthit=tick()
			end
		end
	end
end)

local clipup = movement:AddSection("ClipUp")
clipup_enabled=clipup:AddSetting("Activate","Button")
clipup_keybind=clipup:AddSetting("Keybind","String","E")

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if clipup_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		clipup:UpdateSettingValue("Activate")
	end
end)

clipup:ConnectSettingUpdate("Activate",function()
	if root and hum then
		local ray = workspace:Raycast(root.Position+Vector3.new(0,5000,0),Vector3.new(0,-10000),getMovementRaycastParams())
		if ray then
			moveTo(getMovePart().CFrame.Rotation+ray.Position+Vector3.new(0,2,0))
		end
	end
end)

local autograb = resource:AddSection("AutoGrab")
autograb_enabled=autograb:AddSetting("Enabled","Toggle")
autograb_keybind=autograb:AddSetting("Keybind","String","")
autograb_range=autograb:AddSetting("Range","Slider",25,0,25,0.1)
autograb_whitelistenabled=autograb:AddSetting("WhitelistEnabled","Toggle",true)
autograb_whitelist=autograb:AddSetting("Whitelist","String","Gold, Crystal Chunk, Void Shard, Essence, Emerald, Pink Diamond, Coin2, Coin, Magnetite, Spirit Key")

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if autograb_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		autograb:UpdateSettingValue("Enabled")
	end
end)

local grabbed = {}
local chests = {}
for i,v in pairs(workspace.Deployables:GetChildren()) do
	if v.Name:lower():find("chest") then
		table.insert(chests,v:FindFirstChild("Contents"))
	end
end
workspace.Deployables.ChildAdded:Connect(function(v)
	if v.Name:lower():find("chest") then
		table.insert(chests,v:FindFirstChild("Contents"))
	end
end)

task.spawn(function()
	while window.ScreenGui.Parent do rs.RenderStepped:Wait()
		if autograb_enabled.Value and root and hum and hum.Health>0 then
			local children = workspace.Items:GetChildren()
			for i,v in pairs(chests) do
				for i,v in pairs(v:GetChildren()) do
					table.insert(children,v)
				end
			end
			local whitelist = {}
			if autograb_whitelistenabled.Value then
				for i,v in pairs(autograb_whitelist.Value:split(",")) do
					whitelist[trim(v)]=true
				end
			end
			for i,v:Instance in pairs(children) do
				if grabbed[v] then continue end
				if autograb_whitelistenabled.Value and not whitelist[v.Name] then continue end
				if v:IsA("Model") then
					if #v:GetChildren()>2 and (v:GetPivot().Position-root.Position).Magnitude<autograb_range.Value then
						print("grab")
						pickup(v)
						grabbed[v]=true
						task.spawn(function()
							task.wait(1)
							grabbed[v]=nil
						end)
					end
				elseif v:IsA("BasePart") then
					if (v.Position-root.Position).Magnitude<autograb_range.Value then
						print("grab")
						pickup(v)
						grabbed[v]=true
						task.spawn(function()
							task.wait(1)
							grabbed[v]=nil
						end)
					end
				end
			end
		end
	end
end)

local autochest = resource:AddSection("Auto Chest")
autochest_enabled=autochest:AddSetting("Enabled","Toggle")
autochest_keybind=autochest:AddSetting("Keybind","String","")
autochest_range=autochest:AddSetting("Range","Slider",25,0,25,0.1)
autochest_whitelistenabled=autochest:AddSetting("WhitelistEnabled","Toggle",false)
autochest_whitelist=autochest:AddSetting("Whitelist","String","Gold, Crystal Chunk, Void Shard, Essence, Emerald, Pink Diamond")
autochest_addeddelay=autochest:AddSetting("Added Delay","Slider",0.15,0.1,0.5)
autochest_bind=autochest:AddSetting("Bind","Button")

local chest 

autochest:ConnectSettingUpdate("Bind",function()
	mouse.Button1Down:Wait()
	chest = mouse.Target and mouse.Target.Parent and mouse.Target.Parent:FindFirstChild("Base")
end)

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if autochest_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		autochest:UpdateSettingValue("Enabled")
	end
end)

local waitingforchest=false
task.spawn(function()
	while window.ScreenGui.Parent do rs.RenderStepped:Wait()
		if autochest_enabled.Value and root and hum and hum.Health>0 and chest then
			local closest
			local closestmag = autochest_range.Value
			local whitelist = autochest_whitelist.Value:split(",")
			for i,v in pairs(whitelist) do
				whitelist[i]=trim(v)
			end
			for i,v:Instance in pairs(workspace.Items:GetChildren()) do
				if grabbed[v] then continue end
				if autochest_whitelistenabled.Value then
					if not table.find(whitelist,v.Name) then
						continue
					end
				end
				local pos = if v:IsA("BasePart") then v.Position elseif v:IsA("Model") then v:GetPivot().Position else nil
				if pos and (pos-root.Position).Magnitude<closestmag then
					closest = v
					closestmag = (pos-root.Position).Magnitude
				end
			end
			if not closest then continue end
			if closest:IsA("Model") then
				local mover = getMover(closest)
				if mover then
					task.spawn(function()
						waitingforchest=true
						grab(closest)
						task.wait(plr:GetNetworkPing()+autochest_addeddelay.Value)
						touch(mover,chest)
						grab()
						grabbed[mover]=true
						task.spawn(function()
							task.wait(1)
							grabbed[mover]=nil
						end)
						waitingforchest=false
					end)
				end
			elseif closest:IsA("BasePart") then
				task.spawn(function()
					waitingforchest=true
					grab(closest)
					task.wait(plr:GetNetworkPing()+autochest_addeddelay.Value)
					touch(closest,chest)
					grab()
					grabbed[closest]=true
					task.spawn(function()
						task.wait(1)
						grabbed[closest]=nil
					end)
					waitingforchest=false
				end)
			end
		end
	end
end)


local autofarm = resource:AddSection("Auto Farm")
autofarm_enabled=autofarm:AddSetting("Enabled","Toggle")
autofarm_antrange=autofarm:AddSetting("Avoid Ant Range","Slider",100,0,100)
autofarm_resources=autofarm:AddSetting("Resources","String","Gold Node")
autofarm_usechest=autofarm:AddSetting("Use Chest","Toggle")
autofarm_speed=autofarm:AddSetting("Speed","Slider",50,0,250)

local tppos
local itemcon:RBXScriptConnection
local function getAntsDistance(pos)
	if isvoid then return math.huge end
	local closestmag = math.huge
	for i,v in pairs(workspace.Mounds:GetChildren()) do
		local dist = (v:GetPivot().Position-pos).Magnitude
		if dist<closestmag then
			closestmag=dist
		end
	end
	return closestmag
end
local function validgold()
	local search = autofarm_resources.Value:split(",")
	for i,v in pairs(search) do
		search[i]=trim(v)
	end
	local closest
	local closestmag = math.huge
	local frp = root.Position-Vector3.new(0,root.Position.Y,0)
	for i,v:Instance in pairs(workspace.Resources:GetChildren()) do
		if v:IsA("Model") and table.find(search,v.Name) and v:GetPivot().Position~=Vector3.new() then
			local fpos = v:GetPivot().Position-Vector3.new(0,v:GetPivot().Position.Y,0)
			local dist =(fpos-frp).Magnitude
			if dist<closestmag then
				local cdist = getAntsDistance(v:GetPivot().Position)
				if cdist>autofarm_antrange.Value then
					closest=v
					closestmag=dist
				end
			end
		end
	end
	return closest==nil
end

local waiting = false
local defaulttppos
task.spawn(function()
	while not defaulttppos do rs.PostSimulation:Wait()
		tppos = workspace:Raycast(Vector3.new(-217,1000,-678),Vector3.new(0,-10000,0),getMovementRaycastParams())
		if tppos then
			defaulttppos=tppos.Position
		end
	end
end)
autofarm:ConnectSettingUpdate("Enabled",function()
	if not autofarm_enabled.Value then return end
	tppos=root.Position
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
	while window.ScreenGui.Parent and autofarm_enabled.Value do rs.PostSimulation:Wait()
		disableBoat()
		local search = autofarm_resources.Value:split(",")
		for i,v in pairs(search) do
			search[i]=trim(v)
		end
		local closest
		local closestmag = math.huge
		local frp = root.Position-Vector3.new(0,root.Position.Y,0)
		for i,v:Instance in pairs(workspace.Resources:GetChildren()) do
			if v:IsA("Model") and table.find(search,v.Name) and v:GetPivot().Position~=Vector3.new() then
				local fpos = v:GetPivot().Position-Vector3.new(0,v:GetPivot().Position.Y,0)
				local dist =(fpos-frp).Magnitude
				if dist<closestmag then
					local cdist = getAntsDistance(v:GetPivot().Position)
					if cdist>autofarm_antrange.Value then
						closest=v
						closestmag=dist
					end
				end
			end
		end
		if closest then
			waiting=false
			teleportTo(closest:GetPivot().Position,autofarm_speed.Value,false,function()
				return getAntsDistance(closest:GetPivot().Position)>autofarm_antrange.Value and autofarm_enabled.Value
			end)
			disableBoat()
			itemcon = workspace.Items.ChildAdded:Connect(function(v:Instance)
				if not autofarm_usechest.Value then
					if v:IsA("Model") then
						if #v:GetChildren()>2 and (v:GetPivot().Position-root.Position).Magnitude<autograb_range.Value then
							pickup(v)
							grabbed[v]=true
							task.spawn(function()
								task.wait(1)
								grabbed[v]=nil
							end)
						end
					elseif v:IsA("BasePart") then
						if (v.Position-root.Position).Magnitude<autograb_range.Value then
							pickup(v)
							grabbed[v]=true
							task.spawn(function()
								task.wait(1)
								grabbed[v]=nil
							end)
						end
					end
				end
			end)
			local rp = RaycastParams.new()
			rp.FilterType=Enum.RaycastFilterType.Include
			rp.FilterDescendantsInstances={closest}
			tppos = workspace:Raycast(closest:GetPivot().Position+Vector3.new(0,50,0),Vector3.new(0,-100,0),rp) or closest:GetPivot()
			tppos=tppos.Position
			local closeparts={}
			for i,v in pairs(closest:GetDescendants()) do
				if v:IsA("BasePart") then
					table.insert(closeparts,v)
				end
			end
			while tppos and autofarm_enabled.Value and closest.Parent and getAntsDistance(closest:GetPivot().Position)>autofarm_antrange.Value do rs.RenderStepped:Wait()
				disableBoat()
				moveTo(tppos+Vector3.new(0,1.5,0))
				hit(closeparts)
			end
			tppos = workspace:Raycast(tppos,Vector3.new(0,-100,0),getMovementRaycastParams()) or root.CFrame
			tppos=tppos.Position
			local t = tick()
			local lgrabbed = {}
			local waittime = plr:GetNetworkPing()+0.25
			while tppos and autofarm_enabled.Value and (tick()-t<waittime or autofarm_usechest.Value) and getAntsDistance(closest:GetPivot().Position)>autofarm_antrange.Value do rs.PostSimulation:Wait()
				if not autofarm_usechest.Value  then
					for i,v:Instance in pairs(workspace.Items:GetChildren()) do
						if lgrabbed[v] then continue end
						if v:IsA("Model") then
							if #v:GetChildren()>2 and (v:GetPivot().Position-root.Position).Magnitude<autograb_range.Value then
								pickup(v)
								lgrabbed[v]=true
								task.spawn(function()
									task.wait(1)
									lgrabbed[v]=nil
								end)
							end
						elseif v:IsA("BasePart") then
							if (v.Position-root.Position).Magnitude<autograb_range.Value then
								pickup(v)
								lgrabbed[v]=true
								task.spawn(function()
									task.wait(1)
									lgrabbed[v]=nil
								end)
							end
						end
					end
				else
					local closest
					local closestmag = autochest_range.Value
					for i,v:Instance in pairs(workspace.Items:GetChildren()) do
						if grabbed[v] then continue end
						local pos = if v:IsA("BasePart") then v.Position elseif v:IsA("Model") then v:GetPivot().Position else nil
						if pos and (pos-root.Position).Magnitude<closestmag then
							closest = v
							closestmag = (pos-root.Position).Magnitude
						end
					end
					if not closest then
						if tick()-t<0.5 then continue end
						break
					end
					if closest:IsA("Model") then
						local mover = getMover(closest)
						if mover then
							grab(closest)
							task.wait(plr:GetNetworkPing()+autochest_addeddelay.Value)
							touch(closest,chest)
							grab()
							grabbed[closest]=true
							task.spawn(function()
								task.wait(1)
								grabbed[closest]=nil
							end)
						end
					elseif closest:IsA("BasePart") then
						grab(closest)
						task.wait(plr:GetNetworkPing()+autochest_addeddelay.Value)
						touch(closest,chest)
						grab()
						grabbed[closest]=true
						task.spawn(function()
							task.wait(1)
							grabbed[closest]=nil
						end)
					end
				end
				disableBoat()
				moveTo(tppos+Vector3.new(0,3,0))
			end
			itemcon:Disconnect()
			itemcon=nil
		else
			if defaulttppos then
				if not waiting then
					waiting=true
					teleportTo(defaulttppos+Vector3.new(0,3,0),autofarm_speed.Value,false,function()
						return autofarm_enabled.Value and validgold()
					end)
				else
					moveTo(defaulttppos+Vector3.new(0,3,0))
				end
			end
		end
	end
	waiting=false
	if itemcon then	
		itemcon:Disconnect()
		itemcon=nil
	end
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
	enableBoat()
	tppos=nil
end)

local resourceaura = resource:AddSection("ResourceAura")
resourceaura_enabled = resourceaura:AddSetting("Enabled","Toggle")
resourceaura_keybind = resourceaura:AddSetting("Keybind","String","")
resourceaura_range = resourceaura:AddSetting("Range","Slider",25,0,25)
resourceaura_rate = resourceaura:AddSetting("Rate","Slider",30,0,120)

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if resourceaura_keybind.Value==inp.KeyCode.Name then
		resourceaura_enabled:UpdateSettingValue("Enabled",not resourceaura_enabled.Value)
	end
end)

local lasthit=0
task.spawn(function()
	while window.ScreenGui.Parent do
		local t = rs.PostSimulation:Wait()
		if resourceaura_enabled.Value and char and root and tick()-lasthit>(1/resourceaura_rate.Value) then
			local resources:{Instance}=workspace.Resources:GetChildren()
			local hits = {}
			for i,v in pairs(resources) do
				if v:IsA("Model") then
					local dist = (v:GetPivot().Position-root.Position).Magnitude
					if dist<resourceaura_range.Value then
						for i,v in pairs(v:GetDescendants()) do
							if v:IsA("BasePart") then
								table.insert(hits,v)
							end
						end
					end
				end
			end
			if #hits>0 then
				hit(hits)
				lasthit=tick()
			end
		end
	end
end)

local autoeat = utility:AddSection("Auto Eat")
autoeat_enabled = autoeat:AddSetting("Enabled","Toggle")
autoeat_threshold = autoeat:AddSetting("Threshold","Slider",75,0,100,0.1)
autoeat_foods=autoeat:AddSetting("Foods","String","Lemon, Cooked Meat")

local lastate = 0
task.spawn(function()
	while window.ScreenGui.Parent do
		rs.RenderStepped:Wait()
		if autoeat_enabled.Value and tick()-lastate>0.2 then
			local hunger = (statsgui.Food.Slider.AbsoluteSize.X/statsgui.Food.AbsoluteSize.X)*100
			if hunger<autoeat_threshold.Value then
				for i,v in pairs(autoeat_foods.Value:split(",")) do
					if getSlot(trim(v)) then
						useSlot(getSlot(trim(v)))
						lastate=tick()
						break
					end
				end
			end
		end
	end
end)

local noslide = movement:AddSection("NoSlide")
noslide_enabled=noslide:AddSetting("Enabled","Toggle")
local pang = hum.MaxSlopeAngle
task.spawn(function()
	while window.ScreenGui.Parent do rs.PreSimulation:Wait()
		if not hum then return end
		if noslide_enabled.Value then
			pang=hum.MaxSlopeAngle
			hum.MaxSlopeAngle=90
		else
			hum.MaxSlopeAngle=pang
		end
	end
end)

local autoheal = combat:AddSection("Auto Heal")
autoheal_enabled = autoheal:AddSetting("Enabled","Toggle")
autoheal_tosave = autoheal:AddSetting("To Save","Number",500)
autoheal_rate = autoheal:AddSetting("Rate","Number",50)
autoheal_perhp = autoheal:AddSetting("Blood Per HP","Number",0.5)

local lhp = hum and hum.Health or 100
local healcon
local tohealow=0
local function hpchanged()
	local chp = hum.Health
	if chp>lhp then lhp = chp return end
	if isvoid and autoheal_enabled.Value then
		if getCount("Bloodfruit") <= autoheal_tosave.Value then return end
		if lhp>chp then
			--local toheal = math.clamp((lhp-chp)/3,0,10)
			--toheal += ((lhp-chp)-toheal*3)/1.5
			--toheal=math.ceil(toheal)+1
			local toheal = math.ceil((lhp-chp)/itemdata.Bloodfruit.nourishment.health)
			for i=1,toheal do
				useSlot(getSlot("Bloodfruit"))
			end
			lhp=chp
		end
	end
	tohealow+=lhp-chp
	lhp = chp
end
if hum then
	if healcon then
		healcon:Disconnect()
	end
	healcon = hum:GetPropertyChangedSignal("Health"):Connect(hpchanged)
end
plr.CharacterAdded:Connect(function(c)
	task.wait(0.5)
	healcon = hum:GetPropertyChangedSignal("Health"):Connect(hpchanged)
end)
local lastate = 0
task.spawn(function()
	while window.ScreenGui.Parent do
		rs.RenderStepped:Wait()
		if autoheal_enabled.Value and hum then
			if getCount("Bloodfruit") <= autoheal_tosave.Value then continue end
			if not isvoid then
				if tohealow>0 and tick()-lastate>1/autoheal_rate.Value then
					useSlot(getSlot("Bloodfruit"))
					tohealow=math.clamp(tohealow-autoheal_perhp.Value,0,1000)
					lastate=tick()
				end
			else
				--local chp = hum.Health
				--if chp<lhp then
				--	for i=1,math.ceil((chp-chp)/4)+5 do
				--		useSlot(getSlot("Bloodfruit"))
				--	end
				--end
				--lhp=chp
			end
		end
	end
	healcon:Disconnect()
end)

local clipdown = movement:AddSection("ClipDown")
clipdown_enabled=clipdown:AddSetting("Activate","Button")
clipdown_keybind=clipdown:AddSetting("Keybind","String","Q")

input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if clipdown_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		clipdown:UpdateSettingValue("Activate")
	end
end)

clipdown:ConnectSettingUpdate("Activate",function()
	if root and hum then
		local ray = workspace:Raycast(root.Position-Vector3.new(0,5,0),Vector3.new(0,-10000),getMovementRaycastParams())
		if ray then
			moveTo(getMovePart().CFrame.Rotation+ray.Position+Vector3.new(0,2,0))
		end
	end
end)

local nodoor = utility:AddSection("No Door")
nodoor_enabled=nodoor:AddSetting("Enabled","Toggle")

local doors = {}
for i,v in pairs(workspace.Deployables:GetDescendants()) do
	if v.Name=="Door" and v:IsA("BasePart") then
		doors[v]=v.Parent
	end
end
workspace.Deployables.DescendantAdded:Connect(function(v)
	if v.Name=="Door" and v:IsA("BasePart") then
		task.wait()
		doors[v]=v.Parent
		if not pcall(function() v.Parent = if nodoor_enabled.Value then nil else v.Parent end) then doors[v]=nil end
	end
end)

nodoor:ConnectSettingUpdate("Enabled",function()
	for i,v in pairs(doors) do
		if not pcall(function() i.Parent = if nodoor_enabled.Value then nil else v end) then doors[v]=nil end
	end
end)
task.spawn(function()
	while window.ScreenGui.Parent do task.wait() end
	for i,v in pairs(doors) do
		pcall(function() i.Parent = v end)
	end
end)

local teleports = utility:AddSection("Teleports")
teleports_bigvoid=teleports:AddSetting("Big Void","Button")
teleports:ConnectSettingUpdate("Big Void",function()
	local servers = getServers(11879754496).data
	local touse = {}
	for i,v in pairs(servers) do
		if v.playing>25 then
			table.insert(touse,v.id)
		end
	end
	local bestid = #touse>0 and touse[math.random(1,#touse)] or servers[1].id
	ts:TeleportToPlaceInstance(11879754496,bestid,plr)
end)
teleports_smallvoid=teleports:AddSetting("Small Void","Button")
teleports:ConnectSettingUpdate("Small Void",function()
	local servers = getServers(11879754496).data
	local bestid = servers[#servers].id
	ts:TeleportToPlaceInstance(11879754496,bestid,plr)
end)
teleports_lowpingvoid=teleports:AddSetting("Low Ping Void","Button")
teleports:ConnectSettingUpdate("Low Ping Void",function()
	local servers = getServers(11879754496).data
	local bestid
	local bestval=math.huge
	for i,v in pairs(servers) do
		if v.ping<bestval then
			bestid=v.id
		end
	end
	ts:TeleportToPlaceInstance(11879754496,bestid,plr)
end)
teleports_randomvoid=teleports:AddSetting("Random Void","Button")
teleports:ConnectSettingUpdate("Random Void",function()
	local servers = getServers(11879754496).data
	local bestid = servers[math.random(1,#servers)].id
	while bestid==game.JobId do
		bestid = servers[math.random(1,#servers)].id
	end
	ts:TeleportToPlaceInstance(11879754496,bestid,plr)
end)

teleports_bigoverworld=teleports:AddSetting("Big Overworld","Button")
teleports:ConnectSettingUpdate("Big Overworld",function()
	local servers = getServers(11729688377).data
	local touse = {}
	for i,v in pairs(servers) do
		if v.playing>25 then
			table.insert(touse,v.id)
		end
	end
	local bestid = #touse>0 and touse[math.random(1,#touse)] or servers[1].id
	ts:TeleportToPlaceInstance(11729688377,bestid,plr)
end)
teleports_smalloverworld=teleports:AddSetting("Small Overworld","Button")
teleports:ConnectSettingUpdate("Small Overworld",function()
	local servers = getServers(11729688377).data
	local bestid = servers[#servers].id
	ts:TeleportToPlaceInstance(11729688377,bestid,plr)
end)
teleports_lowpingoverworld=teleports:AddSetting("Low Ping Overworld","Button")
teleports:ConnectSettingUpdate("Low Ping Overworld",function()
	local servers = getServers(11729688377).data
	local bestid
	local bestval=math.huge
	for i,v in pairs(servers) do
		if v.ping<bestval then
			bestid=v.id
		end
	end
	ts:TeleportToPlaceInstance(11729688377,bestid,plr)
end)
teleports_randomoverworld=teleports:AddSetting("Random Overworld","Button")
teleports:ConnectSettingUpdate("Random Overworld",function()
	local servers = getServers(11729688377).data
	local bestid = servers[math.random(1,#servers)].id
	while bestid==game.JobId do
		bestid = servers[math.random(1,#servers)].id
	end
	ts:TeleportToPlaceInstance(11729688377,bestid,plr)
end)

local autoplant = resource:AddSection("Auto Plant")
autoplant_enabled=autoplant:AddSetting("Enabled","Toggle")
autoplant_item=autoplant:AddSetting("Item","String","Bloodfruit")

local planterboxes = {}
for i,v in pairs(workspace.Deployables:GetChildren()) do
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end
workspace.Deployables.ChildAdded:Connect(function(v)
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end)

task.spawn(function()
	while window.ScreenGui.Parent do rs.RenderStepped:Wait()
		if autoplant_enabled.Value then
			local closest
			local closestmag = 25
			for i,v in pairs(planterboxes) do
				if #v:GetChildren()==8 and v:FindFirstChild("Reference") then
					local dist = (v:FindFirstChild("Reference").Position-root.Position).Magnitude
					if dist<closestmag then
						closest=v
						closestmag=dist
					end
				end
			end
			if closest then
				plant(closest,getItemId(autoplant_item.Value))
			end
		end
	end
end)

local autoharvest = resource:AddSection("Auto Harvest")
autoharvest_enabled=autoharvest:AddSetting("Enabled","Toggle")
autoharvest_range=autoharvest:AddSetting("Range","Slider",25,0,25)

local planterboxes = {}
for i,v in pairs(workspace.Deployables:GetChildren()) do
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end
workspace.Deployables.ChildAdded:Connect(function(v)
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end)

task.spawn(function()
	while window.ScreenGui.Parent do local step = rs.RenderStepped:Wait()
		if autoharvest_enabled.Value and root and hum and hum.Health>0 then
			for i,v:Instance in pairs(workspace:GetChildren()) do
				if grabbed[v] then continue end
				if v:IsA("Model") then
					local dist = (v:GetPivot().Position-root.Position).Magnitude
					if v:FindFirstChild("Pickup") and #v:GetChildren()>1 and dist<autoharvest_range.Value then
						pickup(v)
						grabbed[v]=true
						task.spawn(function()
							task.wait(1)
							grabbed[v]=nil
						end)
					end
				end
			end
		end
	end
end)

local placeplantboxes=utility:AddSection("Place Plantboxes")
placeplantboxes_enabled=placeplantboxes:AddSetting("Enabled","Toggle")

task.spawn(function()
	while window.ScreenGui.Parent do rs.PostSimulation:Wait()
		if placeplantboxes_enabled.Value then
			local pos = root.Position
			pos = Vector3.new(math.round(pos.X/6.05)*6.05,pos.Y,math.round(pos.Z/6.05)*6.05)
			local ray = workspace:Raycast(pos+Vector3.new(0,100,0),Vector3.new(0,-200,0),getMovementRaycastParams())
			if ray then
				place("Plant Box",0,ray.Position)
			end
		end
	end
end)

local void = movement:AddSection("Void")
void_activate=void:AddSetting("Activate","Button")
void:ConnectSettingUpdate("Activate",function()
	getMovePart().CFrame-=Vector3.new(0,100,0)
end)

local antiaim = visuals:AddSection("Anti Aim")
antiaim_enabled=antiaim:AddSetting("Enabled","Toggle")
task.spawn(function()
	while window.ScreenGui.Parent do rs.PostSimulation:Wait()
		if antiaim_enabled.Value then
			root.CFrame=CFrame.lookAt(root.Position,Vector3.new(math.random(-10000,10000),0,math.random(-10000,10000)))
		end
	end
end)

local plrstatguis:{{Frame}} = {}
local esp = visuals:AddSection("ESP")
esp_enabled=esp:AddSetting("Enabled","Toggle")
esp_name=esp:AddSetting("Name","Toggle",true)
esp:ConnectSettingUpdate("Name",function()
	for i,v in pairs(plrstatguis) do
		if v.Name then
			v.Name.Parent=if esp_name.Value then v.Main else nil
		end
	end
end)
esp_health=esp:AddSetting("Health","Toggle",true)
esp:ConnectSettingUpdate("Health",function()
	for i,v in pairs(plrstatguis) do
		if v.Health then
			v.Health.Parent=if esp_health.Value then v.Main else nil
		end
	end
end)



local trackedplrstats = {}
local offs = {}
for x=-0.5,0.5 do
	for y=-0.5,0.5 do
		for z=-0.5,0.5 do
			table.insert(offs,Vector3.new(x,y,z))
		end
	end
end

esp:ConnectSettingUpdate("Enabled",function()
	if not esp_enabled.Value then
		for i,v in pairs(plrstatguis) do
			v.Main.Parent=nil
		end
	end
end)
game.Players.PlayerRemoving:Connect(function(v)
	if plrstatguis[v] then
		for i,v in pairs(plrstatguis[v]) do
			v.Parent=nil
		end
	end
	plrstatguis[v]=nil
end)
task.spawn(function()
	while window.ScreenGui.Parent do rs.RenderStepped:Wait()
		if esp_enabled.Value then
			for i,v in pairs(game:GetService("Players"):GetPlayers()) do
				local vchar = v.Character
				if v ~= plr and vchar then
					local vroot = vchar:FindFirstChild("HumanoidRootPart")
					local vhum = vchar:FindFirstChildOfClass("Humanoid")
					if vroot then
						if not plrstatguis[v] then
							plrstatguis[v]={}
							local frame = Instance.new("Frame")
							frame.BackgroundTransparency=1
							frame.AutomaticSize=Enum.AutomaticSize.XY
							frame.AnchorPoint=Vector2.new(0.5,0.5)
							local uilayout = Instance.new("UIListLayout")
							uilayout.Parent=frame
							local name = Instance.new("TextLabel")
							name.TextSize=10
							name.Size=UDim2.new(0,0,0,10)
							name.LayoutOrder=1
							name.BackgroundTransparency=1
							name.TextColor3=v.TeamColor.Color
							name.Text=v.Name.."("..v.DisplayName..")"
							name.Parent=if esp_name.Value then frame else nil
							plrstatguis[v].Name=name
							local hp = Instance.new("TextLabel")
							hp.TextSize=10
							hp.Size=UDim2.new(0,0,0,10)
							hp.LayoutOrder=2
							hp.BackgroundTransparency=1
							hp.TextColor3=Color3.new(1,0,0)
							hp.Text=tostring(vhum and math.round(vhum.Health*10)/10 or "???")
							hp.Parent=if esp_name.Value then frame else nil
							plrstatguis[v].Health=hp
							plrstatguis[v].Main=frame
						end
						local frame = plrstatguis[v].Main
						local cpos = cam:WorldToViewportPoint(vroot.Position)
						if cpos.Z<0 then
							frame.Parent=nil
						else
							plrstatguis[v].Name.TextColor3=v.TeamColor.Color
							plrstatguis[v].Health.Text=tostring(vhum and math.round(vhum.Health*10)/10 or "???")
							frame.Parent=window.ScreenGui
							frame.Position=UDim2.new(0,cpos.X,0,cpos.Y)
						end
					elseif plrstatguis[v] then
						plrstatguis[v].Main.Parent=nil
					end
				end
			end
		end
	end
end)


local autofarmplant = resource:AddSection("Autofarm Plants")
autofarmplant_enabled=autofarmplant:AddSetting("Enabled","Toggle")
autofarmplant_seekrange=autofarmplant:AddSetting("Seek Range","Number",10000)
autofarmplant_range=autofarmplant:AddSetting("Range","Slider",25,0,25)
autofarmplant_plant=autofarmplant:AddSetting("Plant","String","Bloodfruit")
autofarmplant_movetospeed=autofarmplant:AddSetting("Speed","Slider",50,0,75)

autofarmplant:ConnectSettingUpdate("Enabled",function()
	if autofarmplant_enabled.Value then
		disableBoat()
	else
		enableBoat()
	end
end)
local planterboxes = {}
for i,v in pairs(workspace.Deployables:GetChildren()) do
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end
workspace.Deployables.ChildAdded:Connect(function(v)
	if v.Name=="Plant Box" then
		table.insert(planterboxes,v)
	end
end)

task.spawn(function()
	while window.ScreenGui.Parent do local step = rs.PostSimulation:Wait()
		if autofarmplant_enabled.Value and root and hum and hum.Health>0 then
			local closestplant
			local closestmag=autofarmplant_seekrange.Value
			for i,v:Instance in pairs(workspace:GetChildren()) do
				if grabbed[v] then continue end
				if v:IsA("Model") then
					local dist = (v:GetPivot().Position-root.Position).Magnitude
					if v:FindFirstChild("Pickup") and #v:GetChildren()>1 then
						if dist<closestmag then
							closestplant=v
							closestmag=dist
						end
						if dist<autofarmplant_range.Value then
							pickup(v)
							grabbed[v]=true
							task.spawn(function()
								task.wait(1)
								grabbed[v]=nil
							end)
						end
					end
				end
			end

			local closestbox
			local closestmag=autofarmplant_seekrange.Value
			for i,v in pairs(planterboxes) do
				if #v:GetChildren()==8 and v:FindFirstChild("Reference") then
					local dist = (v:FindFirstChild("Reference").Position-root.Position).Magnitude
					if dist<closestmag then
						closestbox=v
						closestmag=dist
					end
				end
			end
			if closestplant then
				teleportStepToward(closestplant:GetPivot().Position,autofarmplant_movetospeed.Value,step,4)
			end
			if closestbox then
				plant(closestbox,getItemId(autofarmplant_plant.Value))
				if not closestplant then
					teleportStepToward(closestbox:GetPivot().Position,autofarmplant_movetospeed.Value,step,4)
				end
			end
		end
	end
end)

local autochase = combat:AddSection("Auto Chase")
autochase_enabled=autochase:AddSetting("Enabled","Toggle")
autochase_keybind=autochase:AddSetting("Keybind","String","G")
autochase_speed=autochase:AddSetting("Speed","Slider",23.5,0,25,0.1)


autochase:ConnectSettingUpdate("Enabled",function()
	if not autochase_enabled.Value then
		autochasing=false
	else
		autochasing=true
	end
end)
input.InputBegan:Connect(function(inp)
	if not window.ScreenGui.Parent or input:GetFocusedTextBox() then return end
	if autochase_keybind.Value:lower()==inp.KeyCode.Name:lower() then
		autochase:UpdateSettingValue("Enabled",not autochase_enabled.Value)
	end
end)
autochasing=false
task.spawn(function()
	while window.ScreenGui.Parent do
		local step = rs.PreSimulation:Wait()
		if autochase_enabled.Value and root then

			local closest
			local closestdist=math.huge
			for i,v:Player in pairs(game:GetService("Players"):GetPlayers()) do
				i=v
				v=i.Character
				if v and i~=plr and (i.Team~=plr.Team or plr.Team.Name=="NoTribe") and v:FindFirstChild("HumanoidRootPart") then
					local dist = (v.HumanoidRootPart.Position-root.Position).Magnitude
					if dist<closestdist then
						closest=v
						closestdist=dist
					end
				end
			end
			if closest and closest:FindFirstChild("HumanoidRootPart") then
				local dif = (closest.HumanoidRootPart.Position-getMovePart().Position)
				getMovePart().CFrame+=dif.Unit*math.clamp(step*autochase_speed.Value,0,dif.Magnitude)
				if dif.Unit.X==dif.Unit.X and (closest.HumanoidRootPart.Position-getMovePart().Position).Magnitude<25 then
					veltoggle.Parent=getMovePart()
					veltoggle.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
					autochasing=true
					getMovePart().CFrame+=dif.Unit*math.clamp(step*autochase_speed.Value,0,dif.Magnitude)
				else
					if autochasing then
						veltoggle.Parent=nil
					end
					autochasing=false
				end
			else
				if autochasing then
					veltoggle.Parent=nil
				end
				autochasing=false
			end
		else
			if autochasing then
				veltoggle.Parent=nil
			end
			autochasing=false
		end
	end
end)

local autopress = utility:AddSection("Auto Press")
autopress_activate=autopress:AddSetting("Press","Button")
autopress_autograb=autopress:AddSetting("Auto Grab","Toggle",true)
autopress_count=autopress:AddSetting("Count","Number",100)

autopress:ConnectSettingUpdate("Press",function()
	for i,v:Instance in pairs(workspace.Deployables:GetChildren()) do
		if v.Name=="Coin Press" and (v:GetPivot().Position-root.Position).Magnitude<10 then
			for i=1,autopress_count.Value do
				press(v)
			end
			if not autopress_autograb.Value then return end
			local con:RBXScriptConnection = workspace.Items.ChildAdded:Connect(function(v)
				if v.Name=="Coin2" then
					pickup(v)
				end
			end)
			task.wait(10)
			con:Disconnect()
			break
		end
	end
end)

local chestheight = utility:AddSection("Chest Height")
chestheight_enabled=chestheight:AddSetting("Enabled","Toggle")
chestheight:ConnectSettingUpdate("Enabled",function()
	if not hum then return end
	if chestheight_enabled.Value then
		hum.HipHeight=0.5
	else
		hum.HipHeight=2
	end
end)
plr.CharacterAdded:Connect(function()
	if chestheight_enabled.Value then
		while not hum do task.wait() end
		hum.HipHeight=0.5
	end
end)

local autocraft = utility:AddSection("Auto Craft")
autocraft_activate=autocraft:AddSetting("Craft","Button")
autocraft_item=autocraft:AddSetting("Item","String","Leaf Bag")
autocraft_count=autocraft:AddSetting("Count","Number",100)

autocraft:ConnectSettingUpdate("Craft",function()
	for i=1,autocraft_count.Value do
		craft(getItemId(autocraft_item.Value))
	end
end)

local birdfarm = resource:AddSection("Bird Farm")
birdfarm_enabled=birdfarm:AddSetting("Enabled","Toggle")

task.spawn(function()
	while window.ScreenGui.Parent do 
		local step = rs.PostSimulation:Wait()
		if birdfarm_enabled.Value and hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent:FindFirstChild("DangerZone") then
			local dz =  hum.SeatPart.Parent.DangerZone
			local closest
			local closestmag = math.huge
			local v = offloaded:FindFirstChild("Bird")
			if not v then continue end
			while hum.SeatPart and hum.SeatPart.Parent and birdfarm_enabled.Value and v.Parent and v:FindFirstChild("HumanoidRootPart") do 
				touch(dz,v:FindFirstChild("HumanoidRootPart"))
				rs.PostSimulation:Wait() 
			end
		end
	end
end)
