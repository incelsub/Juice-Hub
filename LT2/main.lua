-- // Exploit Check
if not getsenv or not checkcaller or not hookmetamethod or not debug or not debug.setupvalue or not debug.getupvalue then
  return game:GetService("Players").LocalPlayer:Kick("Exploit not supported.")
end

-- // Variables
local flags = {
  ws = 16,
  jp = 50,
  dupeInventory = false,
  dupePickup = false,
  dupeMode = false,
  dupeMoney = false
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
  if firstPlot then return properties[1] end
  return properties[math.random(2, #properties)]
end

local saveSlot = function()
  if client.CurrentSaveSlot.Value == -1 then return end
  return gs("ReplicatedStorage").LoadSaveRequests.RequestSave:InvokeServer(client.CurrentSaveSlot.Value, client)
end

local canLoad = function() 
  return gs("ReplicatedStorage").LoadSaveRequests.ClientMayLoad:InvokeServer() 
end

local loadSlot = function(slot, plot)
  repeat wait() until canLoad()
  propertyPurchasingEnv.enterPurchaseMode = function(...)
    debug.setupvalue(propertyPurchasingEnv.rotate, 3, 69)
    debug.setupvalue(oldPurchaseMode, 10, plot)
    return
  end
  gs("ReplicatedStorage").LoadSaveRequests.RequestLoad:InvokeServer(slot, client)
  propertyPurchasingEnv.enterPurchaseMode = oldPurchaseMode
end

-- [[ Dupe Funcs ]] --
local interact = function(...)
  gs("ReplicatedStorage").Interaction.ClientInteracted:FireServer(...)
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
  gs("ReplicatedStorage").Interaction.Ban:FireServer(("a"):rep(1048576 * 3.99))
end

-- // MT Hooks
-- [[ __namecall ]] -- 
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
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

  return __namecall(self, ...)
end))

-- [[ __newindex ]] -- 
__newindex = hookmetamethod(game, "__newindex", newcclosure(function(self, index, value)
  -- [[ Walkspeed ]] --
  if not checkcaller() and self == client.Character.Humanoid and index == "WalkSpeed" and value ~= 0 then
    value = flags.ws
  end
  return __newindex(self, index, value)
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

-- [[ Settings Tab ]] --
SettingsTab.Button({
  Text = "Unload Script",
  Callback = function()
    hookmetamethod(game, "__namecall", newcclosure(function(...) return __namecall(...) end))
    hookmetamethod(game, "__newindex", newcclosure(function(...) return __newindex(...) end))
    table_foreach(connections, function(_, v) v:Disconnect() end)
    pcall(function() OldInstance:Destroy() end)
  end
})