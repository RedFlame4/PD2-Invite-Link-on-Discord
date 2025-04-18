local send_message_orig = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if not string.begins(message, "/link") and not string.begins(message, "/invite") then
		return send_message_orig(self, channel_id, sender, message)
	end

	if Global.game_settings.permission ~= "public" then
		managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("DBU37_premission"))
		managers.menu_component:post_event("menu_error")

		return
	end

	local lobby_info = {}

	if managers.job:has_active_job() then
		local job_chain_data = managers.job.current_job_chain_data and managers.job:current_job_chain_data() or managers.job:current_job_data().chain -- current_job_chain_data added later
		local job_name = managers.localization:text(managers.job:current_job_data().name_id)
		local level_name = managers.localization:text(managers.job:current_level_data().name_id)
		local contract_name = #job_chain_data > 1 and string.format("%s: %s", job_name, level_name) or job_name

		local difficulty = managers.localization:to_upper_text(tweak_data.difficulty_name_id)
		local projob = managers.job:is_current_job_professional() and " (PRO JOB)" or ""
		local state = (Utils:IsInGameState() and not Utils:IsInHeist()) and "In Briefing" or Utils:IsInHeist() and "In Game" or "In Lobby"

		local stage_info = string.format("**%s (%s)%s (%s)**", contract_name, difficulty, projob, state)

		table.insert(lobby_info, stage_info)
	end

	local lobby_message = message:gsub("^/link", ""):gsub("^/invite", ""):trim()
	if lobby_message ~= "" then
		table.insert(lobby_info, lobby_message)
	end

	local icons = {
		"<:callsign_green:1307738766210891827>",
		"<:callsign_blue:1307738764130648156>",
		"<:callsign_brown:1307738762549137449>",
		"<:callsign_orange:1307738767825571931>"
	}
	for i = 1, tweak_data.max_players or 4 do
		local peer = managers.network:session():peer(i)
		local player_info = nil
		if peer then
			local is_local_peer = peer == managers.network:session():local_peer()

			local rank = is_local_peer and (managers.experience.current_rank and managers.experience:current_rank() or 0) or peer:profile("rank") or 0
			local level = is_local_peer and managers.experience:current_level() or peer:profile("level")

			local character_name = managers.localization:to_upper_text("menu_" .. tostring(peer:character()))
			local name_link = string.format("[%s](<https://steamcommunity.com/profiles/%s/>)", peer:name(), peer:user_id())
			if rank and level then
				rank, level = managers.experience.rank_string and managers.experience:rank_string(rank) or "", tostring(level)

				if rank ~= "" then
					level = string.format("%s-%s", rank, level)
				end

				player_info = string.format(
					"%s **%s (%s)**%s",
					character_name,
					name_link,
					level,
					i == 1 and " (Host)" or ""
				)
			else
				-- Player hasn't synced their infamy/level yet since they're still joining
				player_info = string.format(
					"%s **%s** (Joining)",
					character_name,
					name_link
				)
			end
		else
			player_info = "*Player slot available*"
		end

		local icon = icons[i] or "-"

		table.insert(lobby_info, string.format("%s %s", icon, player_info))
	end

	local my_lobby_id = managers.network.matchmake.lobby_handler and managers.network.matchmake.lobby_handler:id()
	local join_link = string.format("`steam://joinlobby/218620/%s/%s`", my_lobby_id, managers.network.account:player_id())

	table.insert(lobby_info, join_link)

	local game_version = game_version()
	local username = string.format("Crime.net (%s)", tweak_data.updates_table[game_version] or game_version)
	local payload = json.encode({
		username = username,
		content = table.concat(lobby_info, "\n")
	})

	-- Windows cmd needs ^ to escape lt/gt symbols
	payload = payload:gsub("\"", "\\\""):gsub("<", "^<"):gsub(">", "^>")

	local webhook = string.reverse("whY-FvVLl2Wt8nQpRkbOE9fSQESnDhiIyYV2LJsS9_-pk1pO9NQbNuD42896zKk5gZhA/8411290803690564911/skoohbew/ipa/moc.drocsid//:sptth")
	local script = string.format('curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "%s" %s', payload, webhook)

	os.execute(script)

	managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("DBU37_link_created"))
	managers.menu_component:post_event("infamous_player_join_stinger")
end
