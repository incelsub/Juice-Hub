--> Base URL of Juice Hub
local baseUrl = "https://raw.githubusercontent.com/incelsub/Juice-Hub/main"

--> Load init script
loadstring(game:HttpGet(baseUrl .. "/init.lua"))()

--> Handler
local games = {
  [placeIdHere] = {
    name = "Game Name Here",
    url = "/GameNameHere/url-to-script.lua"
  }
}

local game = games[game.PlaceId]

--> Invalid game check
if (not game) then
  return client:Kick("This is not a game supported by Juice Hub.")
end

--> Load game script
loadstring(game:HttpGet(baseUrl .. game.url))()