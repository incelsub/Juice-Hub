-- coded like a ape to make people question why they live.
return function(game)
  local games = require("./games");
  local gameId = game.PlaceId;
  
  local gameInfo;
  
  for i,v in next, games do
      for a,b in next, v do
        if (a == tostring("GameId")) then 
          if (tonumber(b) == gameId) then
              gameInfo = b;
              break;
            end;
         end;
      end;
    end;
 end;
