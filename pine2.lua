workspace.StreamingEnabled=false
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

local packets = require(rep.Modules.Packets)

local uilib = loadstring(game:HttpGet("https://github.com/hmmmmmmmmmmmmmmmmmmmmmm/pro/raw/main/uilib.lua"))()

local window = uilib:CreateWindow("Booga Booga")
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

local function getMover(part)
	for i,v in pairs(part:GetChildren()) do
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
	if not (hum and hum.SeatPart) then return root end
	return getMover(hum.SeatPart.Parent)
end
local function moveTo(pos: CFrame | Vector3)
    if typeof(pos) == "Vector3" then
        pos = CFrame.new(pos)
    end

    local move = getMovePart()
    if not move then
        warn("Move part not found.")
        return
    end

    local dif = (move.CFrame.Position - root.CFrame.Position)
    move.CFrame = pos + dif
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
	end
	table.clear(vels)
	table.clear(parts)
	veltoggle.Parent=nil
end
local function getMovementRaycastParams()
	local rp = RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	local filter = {char,hum and hum.SeatPart and hum.SeatPart.Parent}
	for i,v in pairs(game:GetService("Players"):GetPlayers()) do
		table.insert(filter,v.Character)
	end
	for i,v in pairs(workspace:GetChildren()) do
		if v:IsA("Part") and v.Name=="RainPart" then
			table.insert(filter,v)
		end
	end
	rp.FilterDescendantsInstances=filter
	rp.IgnoreWater=true
	return rp
end
local function teleportTo(pos:Vector3,rate:number,reenable:boolean,validator)
	validator=validator or function() return true end
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
				moveTo(ray.Position+Vector3.new(0,3.5,0))
			end
		end
	end
	if reenable==nil or reenable then
		enableBoat()
	end
end
local function trim(str)
	return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

--devs fucking implemented buffers so now i gotta fucking make custom functions for the simplest shit --nevermind i figured it out :3

local function hit(parts)
	packets.SwingTool.send(parts)
end
local function pickup(part)
	packets.Pickup.send(part)
end
local function grab(item)
	packets.ForceInteract.send(item)
end
local function touch(p1,p2)
	firetouchinterest(p1,p2,1)
	firetouchinterest(p1,p2,0)
end

local resource = window:AddTab("Resource")


local grabbed = {}

local autoeat = resource:AddSection("Auto Eat")
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


local antiafk = resource:AddSection("Anti AFK")
antiafk_enabled = autoeat:AddSetting("Enabled","Toggle")
local lastafkstate
task.spawn(function()
	while window.ScreenGui.Parent do
		rs.RenderStepped:Wait()
		if antiafk_enabled.Value and tick()-lastafkstate>0.2 then
			hum.Jump()
			lastate = tick()
		end
	end
end)

local autofarm = resource:AddSection("Auto Farm")
autofarm_enabled=autofarm:AddSetting("Enabled","Toggle")
autofarm_antrange=autofarm:AddSetting("Avoid Ant Range","Slider",100,0,100,0.1)
autofarm_resources=autofarm:AddSetting("Resources","String","Gold Node")
autofarm_usechest=autofarm:AddSetting("Use Chest","Toggle")
autofarm_speed=autofarm:AddSetting("Speed","Slider",50,0,250,0.1)
autofarm_bind=autofarm:AddSetting("Bind","Button")

local chest
local waitingforchest=false
autofarm:ConnectSettingUpdate("Bind",function()
	mouse.Button1Down:Wait()
	chest= mouse.Target and mouse.Target.Parent and mouse.Target.Parent:FindFirstChild("Base")
end)

local tppos
local itemcon:RBXScriptConnection

local function getDistanceToAnts(pos)
    local cdist = math.huge
    for _, ant in ipairs(workspace.Critters:GetChildren()) do
        if ant.Name:lower():find(" ant") and ant.Name:lower() ~= "scavenger ant" and ant:IsA("Model") then
            local antPosition = ant:GetPivot().Position
            local dist = (pos - antPosition).Magnitude
            if dist < cdist then
                cdist = dist
            end
        end
    end
    return cdist
end
autofarm:ConnectSettingUpdate("Enabled",function()
	if not autofarm_enabled.Value then return end
	tppos=root.Position
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
	while autofarm_enabled.Value do rs.PostSimulation:Wait()
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
					if getDistanceToAnts(v:GetPivot().Position)>autofarm_antrange.Value then
						closest=v
						closestmag=dist
					end
				end
			end
		end
		if closest then
			print("Found",closest.Name)
			teleportTo(closest:GetPivot().Position,autofarm_speed.Value,false,function()
				return getDistanceToAnts(closest:GetPivot().Position)>autofarm_antrange.Value and autofarm_enabled.Value
			end)
			disableBoat()
			if getDistanceToAnts(closest:GetPivot().Position)<autofarm_antrange.Value then
				continue
			end
			itemcon = workspace.Items.ChildAdded:Connect(function(v:Instance)
				if not autofarm_usechest.Value then
					if v:IsA("Model") then
						if #v:GetChildren()>2 and (v:GetPivot().Position-root.Position).Magnitude<25 then
							pickup(v)
							table.insert(grabbed,v)
						end
					elseif v:IsA("BasePart") then
						if (v.Position-root.Position).Magnitude<25 then
							pickup(v)
							table.insert(grabbed,v)
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
			while tppos and autofarm_enabled.Value and closest.Parent and closest:FindFirstChild("Health") and closest.Health.Value>0 and getDistanceToAnts(closest:GetPivot().Position)>autofarm_antrange.Value do rs.PostSimulation:Wait()
				disableBoat()
				moveTo(tppos+Vector3.new(0,1,0))
				hit(closeparts)
			end
			local rp = getMovementRaycastParams()
			tppos = workspace:Raycast(tppos,Vector3.new(0,-100,0),rp) or root.CFrame
			tppos=tppos.Position
			local t = tick()
			local lgrabbed = {}
			while tppos and autofarm_enabled.Value and (tick()-t<0.5 or autofarm_usechest.Value) and getDistanceToAnts(closest:GetPivot().Position)>autofarm_antrange.Value do rs.PostSimulation:Wait()
				if not autofarm_usechest.Value  then
					for i,v:Instance in pairs(workspace.Items:GetChildren()) do
						if table.find(lgrabbed,v) then continue end
						if v:IsA("Model") then
							if #v:GetChildren()>2 and (v:GetPivot().Position-root.Position).Magnitude<25 then
								pickup(v)
								table.insert(lgrabbed,v)
								task.spawn(function()
									task.wait(1)
									table.remove(lgrabbed,table.find(lgrabbed,v))
								end)
							end
						elseif v:IsA("BasePart") then
							if (v.Position-root.Position).Magnitude<25 then
								pickup(v)
								table.insert(lgrabbed,v)
								task.spawn(function()
									task.wait(1)
									table.remove(lgrabbed,table.find(lgrabbed,v))
								end)
							end
						end
					end
				elseif not waitingforchest then
					local closest
					local closestmag = 25
					for i,v:Instance in pairs(workspace.Items:GetChildren()) do
						if table.find(grabbed,v) then continue end
						local pos = if v:IsA("BasePart") then v.Position elseif v:IsA("Model") then v:GetPivot().Position else nil
						if pos and (pos-root.Position).Magnitude<closestmag then
							closest = v
							closestmag = (pos-root.Position).Magnitude
						end
					end
					print(closest)
					if not closest then
						if tick()-t<0.5 then continue  end
						break
					end
					if closest:IsA("Model") then
						local mover = getMover(closest)
						if mover then
							grab(closest)
							task.wait(plr:GetNetworkPing()+0.1)
							touch(closest,chest)
							grab()
							table.insert(grabbed,closest)
							task.spawn(function()
								task.wait(1)
								table.remove(grabbed,table.find(grabbed,closest))
							end)
						end
					elseif closest:IsA("BasePart") then
						grab(closest)
						task.wait(plr:GetNetworkPing()+0.1)
						touch(closest,chest)
						grab()
						task.spawn(function()
							task.wait(1)
							table.remove(grabbed,table.find(grabbed,closest))
						end)
					end
				end
				disableBoat()
				moveTo(tppos+Vector3.new(0,1,0))
			end
			print("done")
			itemcon:Disconnect()
			itemcon=nil
		elseif tppos then
			moveTo(tppos+Vector3.new(0,1,0))
		end
	end
	if itemcon then	
		itemcon:Disconnect()
		itemcon=nil
	end
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
	enableBoat()
	tppos=nil
end)