local loops = {}
local utils = setmetatable({}, {
  __newindex = function(self, key, value)
    getgenv()[key] = value
  end
})

utils.getfunctionfromgc = function(funcName, targetScript) --> Returns table of functions
  local functions = {}
  local gc = getgc()
  for i=1, #gc do
    local v = gc[i]
    if (targetScript and getfenv(v).script == targetScript or true) getinfo(v).name == funcName then
      table.insert(functions, v)
    end
  end
  return functions
end

utils.services = setmetatable({}, {
  __index = function(self, index)
    return game:GetService(index)
  end
})

utils.players = services.Players
utils.replicatedStorage = services.ReplicatedStorage
utils.client = players.LocalPlayer

utils.getpos = function(part)
  part = part or client.Character.Humanoid.RootPart
  return part.Position
end

utils.call = function(remote, ...) --> remote, args
  return remote[(remote:IsA("RemoteEvent") and "FireServer") or (remote:IsA("RemoteFunction") and "InvokeServer")](remote, ...)
end

utils.disablesignal = function(scriptSignal)
  for _, v in next, getconnections(scriptSignal) do
    v:Disable()
  end
end

utils.addloop = function(loopName, waitLength, loopFunc)
  loops[loopName] = true
  task.spawn(function()
    while task.wait(waitLength) do
      if loops[loopName] then loopFunc() end
    end
  end)
end

utils.toggleLoop = function(loopName)
  loops[loopName] = not loops[loopName]
end