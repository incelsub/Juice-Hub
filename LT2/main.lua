--[[
Copyright 2022 - Juice Hub developers (incelsub / 0x37, One Shot, 0x12)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- // Exploit Check
if not getsenv or not checkcaller or not hookmetamethod or not debug or not debug.setupvalue or not debug.getupvalue then
  return game:GetService("Players").LocalPlayer:Kick("Exploit not supported.")
end

if oldHooks then
  local nc, ni = clonefunction(oldHooks.namecall), clonefunction(oldHooks.newindex)
  hookmetamethod(game, "__namecall", function(...) return nc(...) end)
  hookmetamethod(game, "__newindex", function(...) return ni(...) end)
  getgenv().oldHooks = nil
end

-- // Variables
local flags = {
  ws = 16,
  jp = 50,
  dupeInventory = false,
  dupePickup = false,
  dupeMode = false,
  dupeMoney = false,
  dupeSlot = 1
}

local UI, dupeModeToggle
local gs = function(service) return game:GetService(service) end
local players = gs("Players")
local client = players.LocalPlayer
local connections = {}

connections[1] = client.CharacterAdded:Connect(function(character)
  character:WaitForChild("HumanoidRootPart")
  character.Humanoid.JumpPower = flags.jp
  character.Humanoid.WalkSpeed = flags.ws
end)

-- // Remote Grabber
local remotes = {
  events = {},
  functions = {}
}

local gameDescendants = game:GetDescendants()
for i=1, #gameDescendants do
  local v = gameDescendants[i]
  local dir = (v.ClassName == "RemoteEvent" and "events" or v.ClassName == "RemoteFunction" and "functions")
  if dir then 
    remotes[dir][v.Name] = v 
  end
end

-- // Functions

-- [[ Using numerical loops is quicker than regular table.foreach & iterating over pairs apparently, source: Ancestor ]] --
local table_foreach = function(table, callback)
  for i=1,#table do
    callback(i, table[i])
  end
end

-- [[ Utilities ]] --
local getCFrame = function(part)
  local part = part or (client.Character and client.Character.HumanoidRootPart)
  if not part then return end
  return part.CFrame
end

local getPosition = function(part)
  return getCFrame(part).Position
end

local tp = function(pos)
  local pos = pos or client:GetMouse().Hit + Vector3.new(0, client.Character.HumanoidRootPart.Size.Y, 0)
  if typeof(pos) == "CFrame" then
    client.Character:SetPrimaryPartCFrame(pos)
  elseif typeof(pos) == "Vector3" then
    client.Character:MoveTo(pos)
  end
end

-- [[ Land Functions ]] --
local propertyPurchasingEnv = getsenv(client.PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
local oldPurchaseMode = propertyPurchasingEnv.enterPurchaseMode

local getProperty = function(firstPlot)
  local properties = {}
  table_foreach(gs("Workspace").Properties:GetChildren(), function(i, v)
    if v:FindFirstChild("Owner") and v.Owner.Value == nil then
      properties[#properties + 1] = v
    end
  end)
  return properties[(firstPlot == true and 1) or (firstPlot == "donate" and #properties) or math.random(2, #properties)]
end

local getPlrProperty = function(plr)
  local plr = plr or client
  local plot
  table_foreach(gs("Workspace").Properties:GetChildren(), function(i, v)
    if v:FindFirstChild("Owner") and v.Owner.Value == plr then
      plot = v
    end
  end)
  return plot
end

local saveSlot = function()
  if client.CurrentSaveSlot.Value == -1 then return end
  return remotes.functions.RequestSave:InvokeServer(client.CurrentSaveSlot.Value, client)
end

local canLoad = function() 
  return remotes.functions.ClientMayLoad:InvokeServer() 
end


-- [[ Fast Load ]] --
local loadSlot = function(slot, plot)
  repeat wait() until canLoad()
  propertyPurchasingEnv.enterPurchaseMode = function(...)
    debug.setupvalue(propertyPurchasingEnv.rotate, 3, 69)
    debug.setupvalue(oldPurchaseMode, 10, plot)
    return
  end
  remotes.functions.RequestLoad:InvokeServer(slot, client)
  propertyPurchasingEnv.enterPurchaseMode = oldPurchaseMode
end

-- [[ Free Land ]] --
local freeLand = function(donatingPlot)
  if getPlrProperty() then
    UI.Banner({
      Text = "You already have a piece of land!"
    })
    return false
  end

  local property = getProperty(donatingPlot)
  remotes.functions.SetPropertyPurchasingValue:InvokeServer(true)
  remotes.events.ClientPurchasedProperty:FireServer(property, property.OriginSquare.Position)
  remotes.functions.SetPropertyPurchasingValue:InvokeServer(false)
  tp(property.OriginSquare.Position)
  return true
end

-- [[ Dupe Funcs ]] --
local interact = function(...)
  remotes.events.ClientInteracted:FireServer(...)
end

-- [[ Dupe Inventory ]] --
local getTools = function()
  client.Character.Humanoid:UnequipTools()
  local tools = {}
  table_foreach(client.Backpack:GetChildren(), function(_, v)
    if v.Name ~= "BlueprintTool" then 
      tools[#tools + 1] = v 
    end
  end)
  return tools
end

local dropTool = function(tool, pos)
  local pos = pos or getCFrame()
  if tool.Name == "BlueprintTool" then return end
  interact(tool, "Drop tool", pos)
end

local dropAllTools = function(pos)
  table_foreach(client.Backpack:GetChildren(), function(i, v)
    dropTool(v, pos)
  end)
end

local pickupTool = function(tool)
  if #getTools() >= 9 then return end
  tp(tool.Main.CFrame)
  task.wait(0.35)
  interact(tool, "Pick up tool")
  task.wait(0.35)
end

dupeInventory = function(pos)
  local pos = pos or getCFrame()
  client.Character.Head:Destroy()
  local tools = {}
  toolFilter = gs("Workspace").PlayerModels.ChildAdded:Connect(function(child)
    local owner = child:WaitForChild("Owner", 5)
    if not owner then return end
    if owner.Value == client and child:FindFirstChild("ToolName") then
      tools[#tools + 1] = child
    end
  end)
  dropAllTools(pos)
  task.delay(5, function() toolFilter:Disconnect() end)
  client.CharacterAdded:Wait()
  client.Character:WaitForChild("HumanoidRootPart")
  if flags.dupePickup and #getTools() <= 9 then
    task.wait(1)
    table_foreach(tools, function(_, v)
      pickupTool(v)
    end)
    client.Character.Humanoid:UnequipTools()
  end
  if flags.dupeInventory then
    dupeInventory(pos)
  else
    task.wait(1) 
    tp(pos)
  end
end

-- [[ Dupe Money ]] --
local donateEnv = getsenv(client.PlayerGui.DonateGUI.DonateClient)
local donateFunc = donateEnv.sendDonation

-- [[ Send Money, I believe ancestor discovered this method, apparently its faster (in my testing, its the same cooldown as the donate remote: 120 seconds) ]] --
local sendMoney = function(plr, amt)
  debug.setupvalue(donateFunc, 1, plr)
  debug.setupvalue(donateFunc, 3, amt)
  donateFunc()
end

dupeMoney = function()
  local currentSlot = client.CurrentSaveSlot.Value
  local currentMoney = client.leaderstats.Money.Value

  -- [[ Retarded? ]] --
  if currentSlot == -1 then
    return UI.Banner({
      Text = "Please load a slot & try again."
    })
  end

  -- [[ No Bitches? ]] --
  if currentMoney == 0 then
    return UI.Banner({
      Text = "You have no money to dupe."
    })
  end

  -- [[ Set dupe mode to true ]] --
  dupeModeToggle:SetState(true)

  -- [[ Wait until we can reload ]] --
  if not canLoad() then
    UI.Banner({
      Text = "Waiting for load cooldown, this may take up to 60 seconds."
    })
    repeat wait() until canLoad()
  end

  -- [[ Send ourselves the money ]] --
  repeat 
    task.spawn(sendMoney, client, currentMoney)
    wait(2.5) 
  until client.leaderstats.Money.Value == 0
  
  UI.Banner({
    Text = "Reloading."
  })
  
  -- [[ Reload the slot ]] --
  loadSlot(currentSlot, getProperty())
  
  -- [[ Wait until we've reloaded ]] --
  repeat wait() until client.leaderstats.Money.Value == math.clamp(currentMoney, 0, 20000000)
  
  -- [[ Get the money back instantly ]] --
  task.spawn(function()
    client.leaderstats.Money:GetPropertyChangedSignal("Value"):Wait()
    saveSlot()
    UI.Banner({
      Text = "Successfully duped money!"
    })
    if flags.dupeMoney then
      dupeMoney()    
    end
  end)
  saveSlot()
end

-- [[ Donate Plot ]] --
local donatePlot = function(slotNum)
  local slotNum = math.clamp(slotNum, 1, 6)
  if getPlrProperty() then 
    return UI.Banner({
      Text = "Please unload your slot & try again."
    })
  end
  task.delay(0.1, function()
    freeLand(true)
  end)
  loadSlot(slotNum, getProperty("donate"))
  UI.Banner({
    Text = "Slot loaded, waiting for reload cooldown."
  })
  repeat wait(1) until canLoad()
  UI.Banner({
    Text = "Unloading slot, please wait."
  })
  remotes.functions.ClientSetListPlayer:InvokeServer(client.WhitelistFolder, client, true)
  remotes.functions.RequestLoad:InvokeServer(-1)
  UI.Banner({
    Text = "Success! Whitelist your friend & tell them to load over top of your base."
  })
  remotes.functions.ClientSetListPlayer:InvokeServer(client.WhitelistFolder, client, false)
end

-- [[ Autobuy ]] --

local moveItem = function(item, cframe)
  remotes.events.ClientIsDragging:FireServer(item)
  item.Main.CFrame = cframe
end

local distanceBetween = function(pos1, pos2)
  return (pos1 - pos2).Magnitude
end

-- // Grab NPCs
local npcList = {}
local requiredNpcs = {"WoodRUs", "CarStore", "FurnitureStore", "ShackShop", "LogicStore", "FineArt"}

local count = 0
local npcGrab = remotes.events.PromptChat.OnClientEvent:Connect(function(_, npc)
	if table.find(requiredNpcs, npc.Character.Parent.Name) and not npcList[npc.Character.Parent.Name] then
		count = count + 1
		npcList[npc.Character.Parent.Name] = npc
	end
end)

remotes.functions.SetChattingValue:InvokeServer(1)
repeat wait() until count == #requiredNpcs
npcGrab:Disconnect()
remotes.functions.SetChattingValue:InvokeServer(0)

-- [[ Items ]] --
local stores = {
	WoodRUs = {Items = workspace.Stores:FindFirstChild("WorkLight", true).Parent, NPC = npcList.WoodRUs},
	CarStore = {Items = workspace.Stores:FindFirstChild("Trailer2", true).Parent, NPC = npcList.CarStore},
	FurnitureStore = {Items = workspace.Stores:FindFirstChild("Bed1", true).Parent, NPC = npcList.FurnitureStore},
	ShackShop = {Items = workspace.Stores:FindFirstChild("Dynamite", true).Parent, NPC = npcList.ShackShop},
	LogicStore = {Items = workspace.Stores:FindFirstChild("SignalDelay", true).Parent, NPC = npcList.LogicStore},
	FineArt = {Items = workspace.Stores:FindFirstChild("Painting1", true).Parent, NPC = npcList.FineArt}
}

local itemInfo, visualItems = {}, {}

local getItemModel = function(item)
	return gs("ReplicatedStorage").Purchasables:FindFirstChild(item.Name, true)
end

for _, v in pairs(stores) do
  table_foreach(v.Items:GetChildren(), function(i, v)
    local itemModel = getItemModel(v)
    if not itemModel:FindFirstChild("WoodCost") and not table.find(visualItems, itemModel.ItemName.Value) then
      itemInfo[itemModel.ItemName.Value] = { Name = v.Name, Price = itemModel.Price.Value }
      visualItems[#visualItems + 1] = itemModel.ItemName.Value
    end
  end)
end

local findStoreByItem = function(itemName)
  local storesWithItem = {}
  for i,v in next, stores do
    local stock = 0
    for _, item in next, v.Items:GetChildren() do
      if item.Name == itemName then
        stock = stock + 1
      end
    end
    storesWithItem[#storesWithItem + 1] = {store = i, stock = stock} 
  end

  table.sort(storesWithItem, function(a, b)
    return a.stock > b.stock
  end)

  return storesWithItem[1]
end

local buyItem = function(item, quantity)
  local itemInfo = itemInfo[item]
  local store = findStoreByItem(itemInfo.Name).store

  if not store then return false, "Failed to find item." end

  local totalPrice = itemInfo.Price * quantity

  if totalPrice > client.leaderstats.Money.Value then
		return false, "You can't afford this, you need $" .. totalPrice .. " in total."
  end

  local oldPosition = client.Character.Humanoid.RootPart.Position
	local items = stores[store].Items
	local counter = workspace.Stores[store].Counter

  for i=1, quantity do
    local item = items:WaitForChild(itemInfo.Name)
    item:WaitForChild("Main")
    if distanceBetween(client.Character.HumanoidRootPart.Position, item.Main.Position) > 50 then
			tp(item.Main.Position + Vector3.new(5, 5, 0))
			task.wait()
		end

    repeat
      moveItem(item, (counter.CFrame * CFrame.new(0, 0.3, 0)) * CFrame.Angles(0, 90, 0))
			remotes.functions.PlayerChatted:InvokeServer({ID = stores[store].NPC.ID, Name = stores[store].NPC.Name}, "ConfirmPurchase")
			task.wait()
		until item.Parent ~= items
    repeat 
      moveItem(item, CFrame.new(oldPosition + Vector3.new(5, 0, 0)))
      task.wait()
    until task.wait(0.4)
  end

  tp(oldPosition)
  return true, "Finished Autobuy!"
end

-- [[ Ctrl + Click TP ]] --
gs("UserInputService").InputBegan:Connect(function(input, gpe)
  if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 or not gs("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then return end
  tp()
end)

-- [[ AC Bypass ]] --
local acEnv = getsenv(client.PlayerGui.LoadSaveGUI.LoadSaveClient.LocalScript)
debug.setupvalue(acEnv.ban, 1, true)

-- [[ CALL FUNCTION AT RISK, IT WILL FLOOD BAN SYSTEM, PREVENTING ANYONE FROM BEING BANNED IN LT2! ]] --
local fuckBanSystem = function()
  remotes.events.Ban:FireServer(("a"):rep(1048576 * 3.99))
end

-- // Tree Stuff

local getToolStats = function(toolName)
  if typeof(toolName) ~= "string" then
    print(toolName)
	toolName = toolName.ToolName.Value
  end
  return require(gs("ReplicatedStorage").Purchasables.Tools.AllTools[toolName].AxeClass).new()
end

local getBestAxe = function(treeClass)
  local tools = getTools()
  if #tools == 0 then
	return false, "Error!\nYou don't have any tools."
  end
  local toolStats = {}
  local tool
  for _, v in next, tools do
	if treeClass == "LoneCave" and v.ToolName.Value == "EndTimesAxe" then
	  tool = v
	  break
	end
    local axeStats = getToolStats(v)
	if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
	  for i, v in next, axeStats.SpecialTrees[treeClass] do
	    axeStats[i] = v
	  end
    end
	table.insert(toolStats, { tool = v, damage = axeStats.Damage })
  end
  if not tool and treeClass == "LoneCave" then
	return false, "Error!\nYou must have an end times axe to cut this."
  end
  table.sort(toolStats, function(a, b)
	return a.damage > b.damage
  end)
  return true, tool or toolStats[1].tool
end

local cutPart = function(event, section, height, tool, treeClass)
  local axeStats = getToolStats(tool)
  if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
	for i, v in next, axeStats.SpecialTrees[treeClass] do
	  axeStats[i] = v
	end
  end
  
  remotes.events.RemoteProxy:FireServer(event, {
	tool = tool,
	faceVector = Vector3.new(-1, 0, 0),
	height = height or 0.3,
	sectionId = section or 1,
	hitPoints = axeStats.Damage,
	cooldown = axeStats.SwingCooldown,
	cuttingClass = "Axe"
  })
end

local treeListener = function(treeClass, callback)
  local childAdded
  childAdded = workspace.LogModels.ChildAdded:Connect(function(child)
	local owner = child:WaitForChild("Owner")
	if owner.Value == client and child.TreeClass.Value == treeClass then
	  childAdded:Disconnect()
	  callback(child)
	end
  end)
end

local treeClasses = {}
local treeRegions = {}

for _, v in next, workspace:GetChildren() do
  if v.Name == "TreeRegion" then
    treeRegions[v] = {}
    for _, v2 in next, v:GetChildren() do
	  if v2:FindFirstChild("TreeClass") and not table.find(treeClasses, v2.TreeClass.Value) then
	    table.insert(treeClasses, v2.TreeClass.Value)
	  end
	  if v2:FindFirstChild("TreeClass") and not table.find(treeRegions[v], v2.TreeClass.Value) then
		table.insert(treeRegions[v], v2.TreeClass.Value)
	  end
	end
  end
end

local getBiggestTree = function(treeClass)
  local trees = {}
  for i, v in next, treeRegions do
	if table.find(v, treeClass) then
	  for _, v2 in next, i:GetChildren() do
		if v2:IsA("Model") and v2:FindFirstChild("Owner") then
		  if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == treeClass and v2.Owner.Value == nil or v2.Owner.Value == client then
			local totalMass = 0
			local treeTrunk
			for _, v3 in next, v2:GetChildren() do
			  if v3:IsA("BasePart") then
			    if v3:FindFirstChild("ID") and v3.ID.Value == 1 then
			      treeTrunk = v3
			    end
			    totalMass = totalMass + v3:GetMass()
			  end
			end
			table.insert(trees, { tree = v2, trunk = treeTrunk, mass = totalMass })
		  end
		end
	  end
	end
  end
  table.sort(trees, function(a, b)
    return a.mass > b.mass
  end)
  return trees[1] or nil
end

local bringTree = function(treeClass)
  local success, data = getBestAxe(treeClass)
  if not success then
	return UI.Banner({
	  Text = data
	})
  end
  
  local axeStats = getToolStats(data)

  local tree = getBiggestTree(treeClass)
  
  if not tree then
	return UI.Banner({
	  Text = "Error!\nFailed to find tree."
	 })
  end
  
  local oldPosition = getPosition()
  
  local treeCut = false
  treeListener(treeClass, function(tree)
	tree.PrimaryPart = tree:FindFirstChild("WoodSection")
	treeCut = true
	for i=1, 14 do
	  remotes.events.ClientIsDragging:FireServer(tree.WoodSection)
	  remotes.events.ClientRequestOwnership:FireServer(tree.WoodSection)
	  tree:MoveTo(oldPosition)
	  wait()
	end
	task.wait(0.15)
	if treeClass == "LoneCave" then
	  client.Character.Head:Destroy()
	  client.CharacterAdded:Wait()
	  wait(2)
	end
	tp(oldPosition)	
  end)
  
  if treeClass == "LoneCave" then
    local rj = client.Character.HumanoidRootPart.RootJoint
    local rjClone = rj:Clone()
    rj:Destroy()
    wait(0.05)
    rjClone.Parent = client.Character.HumanoidRootPart    
  end
  
  wait()
  
  task.spawn(function()
    repeat
      tp(tree.trunk.CFrame * CFrame.new(4, 3, 4))
      task.wait()
    until treeCut
  end)
  
  task.wait(0.3)
  
  task.spawn(function()
    repeat 
      cutPart(tree.tree.CutEvent, 1, 0.3, data, treeClass)
      task.wait(axeStats.SwingCooldown + 0.05)
    until treeCut
  end)
end

-- // MT Hooks
-- [[ __namecall ]] --
getgenv().oldHooks = {} 
getgenv().oldHooks.namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
  -- [[ Anti Kick ]] --
  if getnamecallmethod() == "Kick" then
    return wait(9e9)
  end

  -- [[ Anti Ban ]] --
  if tostring(self) == "Ban" or tostring(self) == "AddLog" then
    return true
  end

  -- [[ Prevent Saving ]] --
  if not checkcaller() and self.Name == "RequestSave" and flags.dupeMode then
    return true
  end

  return oldHooks.namecall(self, ...)
end))

-- [[ __newindex ]] -- 
getgenv().oldHooks.newindex = hookmetamethod(game, "__newindex", newcclosure(function(self, index, value)
  -- [[ Walkspeed ]] --
  if not checkcaller() and self == client.Character.Humanoid and index == "WalkSpeed" and value ~= 0 then
    value = flags.ws
  end
  return oldHooks.newindex(self, index, value)
end))

-- // UI
local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/incelsub/Juice-Hub/main/ui.lua"))()
UI = Material.Load({
  Title = "Juice Hub (Beta)",
  Style = 1,
  SizeX = 500,
  SizeY = 350,
  Theme = "Dark"
})

-- [[ Tabs ]] --
local LocalTab = UI.New({ Title = "Local" })
local DupeTab = UI.New({ Title = "Dupe" })
local DonateTab = UI.New({ Title = "Donate" })
local LandTab = UI.New({ Title = "Land" })
local AutobuyTab = UI.New({ Title = "Autobuy" })
local TreeTab = UI.New({ Title = "Tree" })
local SettingsTab = UI.New({ Title = "Settings" })

-- [[ Local Tab ]] --
LocalTab.Slider({
  Text = "Walk Speed",
  Callback = function(value)
    flags.ws = value
    client.Character.Humanoid.WalkSpeed = value
  end,
  Min = 0,
  Max = 500,
  Def = flags.ws
})

LocalTab.Slider({
  Text = "Jump Power",
  Callback = function(value)
    flags.jp = value
    client.Character.Humanoid.JumpPower = value
  end,
  Min = 0,
  Max = 500,
  Def = flags.jp
})

-- [[ Dupe Tab ]] --
dupeModeToggle = DupeTab.Toggle({
  Text = "Dupe Mode",
  Callback = function(bool)
    print(bool)
    flags.dupeMode = bool    
  end,
  Enabled = false
})

DupeTab.Button({
  Text = "Dupe Inventory",
  Callback = dupeInventory
})

DupeTab.ChipSet({
  Text = "InvDupe",
  Callback = function(options)
    flags.dupeInventory = options.Loop
    flags.dupePickup = options.Pickup
  end,
  Options = {
    Loop = false,
    Pickup = false
  }
})

DupeTab.Button({
  Text = "Drop Inventory",
  Callback = dropAllTools
})

DupeTab.Button({
  Text = "Dupe Money",
  Callback = dupeMoney
})

DupeTab.ChipSet({
  Text = "MoneyDupe",
  Callback = function(options)
    flags.dupeMoney = options.Loop
  end,
  Options = {
    Loop = false
  }
})

-- [[ Donate Tab ]] --
DonateTab.Slider({
  Text = "Slot",
  Callback = function(value)
    flags.dupeSlot = value
  end,
  Min = 1,
  Max = 6,
  Def = flags.dupeSlot
})

DonateTab.Button({
  Text = "Donate Base",
  Callback = function()
    donatePlot(flags.dupeSlot)    
  end
})

-- [[ Land Tab ]] --
LandTab.Button({
  Text = "Free Land",
  Callback = freeLand
})

-- [[ Autobuy Tab ]] --

flags.buyItem = visualItems[1]
AutobuyTab.Dropdown({
  Text = "Item",
  Callback = function(value)
    flags.buyItem = value
  end,
  Options = visualItems
})

flags.buyQuantity = 1
AutobuyTab.Slider({
  Text = "Quantity",
  Min = 1,
  Max = 100,
  Def = 1,
  Callback = function(value)
    flags.buyQuantity = value
  end
})

AutobuyTab.Button({
  Text = "Purchase",
  Callback = function()
    local success, msg = buyItem(flags.buyItem, flags.buyQuantity)
    if not success then
      return UI.Banner({
        Text = "Error! " .. msg
      })
    end
    UI.Banner({
      Text = "Successfully bought items."
    })
  end
})

-- [[ Tree Tab ]] --
flags.treeSelected = treeClasses[1]
TreeTab.Dropdown({
  Text = "Tree",
  Callback = function(value)
    flags.treeSelected = value
  end,
  Options = treeClasses
})

TreeTab.Button({
  Text = "Bring Tree",
  Callback = function()
	bringTree(flags.treeSelected)
  end
})

-- [[ Settings Tab ]] --
SettingsTab.Button({
  Text = "Unload Script",
  Callback = function()
    hookmetamethod(game, "__namecall", newcclosure(function(...) return oldHooks.namecall(...) end))
    hookmetamethod(game, "__newindex", newcclosure(function(...) return oldHooks.newindex(...) end))
    getgenv().oldHooks = nil
    table_foreach(connections, function(_, v) v:Disconnect() end)
    pcall(function() OldInstance:Destroy() end)
  end
})

UI.Banner({
  Text = "Welcome, " .. client.DisplayName .. "!\nJuice Hub (LT2) was developed by 0x37."
})
