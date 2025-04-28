Hooks:Add("LocalizationManagerPostInit", "DiscordBot_loc", function(...)				
	LocalizationManager:add_localized_strings({
		DB_link_created = "Join link created.",
		DB_permission = "Lobby permission isn't public.",
		DB_play_together = "Wanna play together? Write /link or /invite followed by an optional message for the lobby.\nIt will create a join link into #old-looking-to-play channel on the Original Pack Discord server, you'll get attention from other players wanting to play.",
	})

	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			DB_link_created = "Ссылка для присоединения создана.",
			DB_permission = "Ваше лобби не публично.",
			DB_play_together = "Хочешь играть в компании? Напиши /link или /invite.\nЭто создаст ссылку для присоединения в канале #u37-looking-to-play на Discord сервере Original Pack, вы привлекёте внимание других игроков, которые хотят поиграть.",
		})
	end
end)

Hooks:PostHook(MenuManager, "created_lobby", "DiscordBot_created_lobby", function()
	DelayedCalls:Add("DiscordBot_message_delay", 1, function()
		if managers.chat then
			managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("DB_play_together"))
		end
	end)
end)