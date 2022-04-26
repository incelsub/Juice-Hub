--> Games
local games = {
  [13822889] = "/LT2/main.lua"
}

local game = games[game.PlaceId]

--> Invalid game check
if (not game) then
  return game:GetService("Players").LocalPlayer:Kick("This is not a game supported by Juice Hub.")
end

--> Load script
loadstring(game:HttpGet("https://raw.githubusercontent.com/incelsub/Juice-Hub/main" .. game))()