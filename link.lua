Hooks:Add("LocalizationManagerPostInit", "DiscordBotU37_loc", function(...)				
	LocalizationManager:add_localized_strings({
		DBU37_link_created = "Join link created.",
		DBU37_premission = "Lobby permission isn't public.",
		DBU37_play_together = "Wanna play together? Write /link or /invite followed by an optional message for the lobby.\nIt will create a join link into #u37-looking-to-play channel on Original Pack Discord server, you'll get attention from other players wanted to play.",
		
	})
		
	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			DBU37_link_created = "Ссылка для присоединения создана.",
			DBU37_premission = "Ваше лобби не публично.",
			DBU37_play_together = "Хочешь играть в компании? Напиши /link или /invite.\nЭто создаст ссылку для присоединения в канале #u37-looking-to-play на Discord сервере Original Pack, вы привлекёте внимание других игроков, которые хотят поиграть.",
		})
	end
end)

local data = MenuManager.created_lobby
function MenuManager:created_lobby()
	data(self)

	DelayedCalls:Add("DiscordBotU37_message_delay", 1, function()
		if managers.chat then
		
			managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("DBU37_play_together"))
		end
	end)
end