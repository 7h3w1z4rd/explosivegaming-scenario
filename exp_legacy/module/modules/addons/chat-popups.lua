--- Creates flying text entities when a player sends a message in chat;
-- also displays a ping above users who are named in the message
-- @addon Chat-Popups

local FlyingText = require("modules/exp_util/flying_text")
local Event = require("modules/exp_legacy/utils/event") --- @dep utils.event
local config = require("modules.exp_legacy.config.popup_messages") --- @dep config.popup_messages

Event.add(defines.events.on_console_chat, function(event)
    if not event.player_index or event.player_index < 1 then return end
    local player = game.players[event.player_index]

    -- Some basic sanity checks
    if not player then return end
    if not event.message then return end

    -- Sends the message as text above them
    if config.show_player_messages then
        FlyingText.create_as_player{
            target_player = player,
            text = { "chat-popup.message", player.name, event.message },
        }
    end

    if not config.show_player_mentions then return end

    -- Makes lower and removes white space from the message
    local search_string = event.message:lower():gsub("%s+", "")

    -- Loops over online players to see if they name is included
    for _, mentioned_player in pairs(game.connected_players) do
        if mentioned_player.index ~= player.index then
            if search_string:find(mentioned_player.name:lower(), 1, true) then
                FlyingText.create_as_player{
                    target_player = mentioned_player,
                    text = { "chat-popup.ping", player.name },
                }
            end
        end
    end
end)
