repeat task.wait() until game:IsLoaded();

local startTime = os.time();

local JuiceHub;

--// ANCHOR Localization \\--
local CFrame = CFrame;
local Vector3 = Vector3;
local Vector2 = Vector2;
local game = game;

--// ANCHOR GetService \\--
local _getservice = game.GetService;
local Services = {};
local GetService = function(service)
    Services[service] = Services[service] or _getservice(game, service);
    return Services[service];
end;

--// ANCHOR util \\--
local util = {
    ["startsWith"] = function(input, check)
        local sub = string.sub(input, 1, #check);
        return sub == check, sub;
    end,
    ["endsWith"] = function(input, check)
        local sub = string.sub(input, #input - #check + 1, #input);
        return sub == check, sub;
    end
};

JuiceHub = {
    ["Config"] = {
        ["WalkSpeed"] = tonumber(16),
        ["JumpPower"] = tonumber(50),
        ["DupeInventory"] = false,
        ["DupePickup"] = false,
        ["DupeMode"] = false,
        ["DupeMoney"] = false,
        ["DupeSlot"] = tonumber(1)
    },
    ["Variables"] = {
        ["RenderStepped"] = JuiceHub.Services.RunService.RenderStepped,
        ["Injector"] = identifyexecutor(),
        ["Player"] = JuiceHub.Services.Players.LocalPlayer,
        ["Character"] = JuiceHub.Services.Player.LocalPlayer.Character,
        ["Humanoid"] = JuiceHub.Services.Player.LocalPlayer.Character.Humanoid,
        ["HumanoidRootPart"] = JuiceHub.Services.Player.LocalPlayer.Character.HumanoidRootPart,
        ["Mouse"] = JuiceHub.Variables.Player:GetMouse()
    },
    ["Services"] = {
        ["RunService"] = GetService("RunService"),
        ["Players"] = GetService("Players")
    },
    ["Functions"] = {
        ["wait"] = function(time)
            if not (time) or (typeof(time) ~= "number") then
                return JuiceHub.Variables.RenderStepped:Wait()
            end;
            local startAt = os.clock();
            local endsAt = (startAt + time) - 0.05;
            
            if (endsAt < 0) then
                return wait()
            end;
            repeat JuiceHub.Variables.RenderStepped:Wait() until os.clock() >= endsAt;
            return os.clock() - startAt;
        end,
        ["ExploitCheck"] = function()
            if (JuiceHub.Variables.Injector:match("Synapse")) or (JuiceHub.Variables.Injector:match("ScriptWare")) or (JuiceHub.Variables.Injector:match("Krnl")) then -- Because I Can L
                return true;
            end;
            if (getsenv) and (checkcaller) and (hookmetamethod) and (debug) and (debug.setupvalue) and (debug.getupvalue) and (oldHooks) then
                return true;
            end;
            return false;
        end,
        ["Table_ForEach"] = function(table, callback)
            --// Using numerical loops is quicker than regular table.foreach & iterating over pairs apparently, source: Ancestor \\--
            for i = 1, #table do
                callback(i, table[i])
            end;
        end,
        ["GetCFrame"] = function(part)
            local part = part or (JuiceHub.Variables.Character) and (JuiceHub.Variables.HumanoidRootPart);
            if not (part) then return end;
            return part.CFrame;
        end,
        ["GetPosition"] = function(part)
            return JuiceHub.Functions.GetCFrame(part).Position;
        end,
        ["TP"] = function(pos)
            local pos = pos or JuiceHub.Variables.Mouse.Hit + Vector3.new(tonumber(0), JuiceHub.Variables.HumanoidRootPart.Size.Y, tonumber(0));
            if (typeof(pos) == "CFrame") then
                JuiceHub.Variables.Character:SetPrimaryPartCFrame(pos);
            elseif
                JuiceHub.Variables.Character:MoveTo(pos);
            end;
        end
    }
};

if not (JuiceHub.Functions.ExploitCheck()) then JuiceHub.Variables.Player:Kick(string.format("Your executor %s is not supported.", JuiceHub.Variables.Injector)) end; -- Dont you just love adding more work its so fun :D

