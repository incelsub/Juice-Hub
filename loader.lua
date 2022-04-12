--> Base URL of Juice Hub
local baseUrl = "https://raw.githubusercontent.com/incelsub/Juice-Hub/main"

--> Load init script
loadstring(game:HttpGet(baseUrl .. "/init.lua"))()

--> Handler
local games = {
  [4581966615] = {
    name = "Anomic",
    url = "/Anomic/main.lua"
  }
}

local game = games[game.PlaceId]

--> Invalid game check
if (not game) then
  return client:Kick("This is not a game supported by Juice Hub.")
end

--> Load game script
loadstring(game:HttpGet(baseUrl .. game.url))()