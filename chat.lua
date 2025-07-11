local send_message_orig = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if not string.begins(message, "/link") and not string.begins(message, "/invite") then
		return send_message_orig(self, channel_id, sender, message)
	end

	local is_steam_mm = not SystemInfo.matchmaking and true or SystemInfo:matchmaking() == Idstring("MM_STEAM")
	if Global.game_settings.permission ~= "public" and is_steam_mm then -- blame discord for removing steam joinlobby link embedding
		self:feed_system_message(self.GAME, managers.localization:text("DB_permission"))
		managers.menu_component:post_event("menu_error")

		return
	end

	local lobby_info = {}

	local stage_info = nil
	local state = (Utils:IsInGameState() and not Utils:IsInHeist()) and "In Briefing" or Utils:IsInHeist() and "In Game" or "In Lobby"
	if managers.job:has_active_job() then
		local job_chain_data = managers.job.current_job_chain_data and managers.job:current_job_chain_data() or managers.job:current_job_data().chain -- current_job_chain_data added later
		local job_name = managers.localization:text(managers.job:current_job_data().name_id)
		local level_name = managers.localization:text(managers.job:current_level_data().name_id)
		local contract_name = #job_chain_data > 1 and string.format("%s: %s", job_name, level_name) or job_name

		if managers.skirmish and managers.skirmish:is_skirmish() then
			local contact_name = managers.localization:text(managers.job:current_contact_data().name_id)

			stage_info = string.format("**%s: %s (%s)**", contact_name, contract_name, state)
		else
			local difficulty = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[Global.game_settings.difficulty])
			local projob = managers.job:is_current_job_professional() and " (PRO JOB)" or Global.game_settings.one_down and " (ONE DOWN)" or ""

			stage_info = string.format("**%s (%s)%s (%s)**", contract_name, difficulty, projob, state)
		end
	elseif managers.crime_spree and managers.crime_spree:is_active() then
		local spree_level = managers.crime_spree:server_spree_level()
		local icon = "<:cum_spree:1393290173999222886>"

		stage_info = string.format("**Crime Spree: %s %s (%s)**", spree_level, icon, state)
	end

	table.insert(lobby_info, stage_info)

	local lobby_message = message:gsub("^/link", ""):gsub("^/invite", ""):trim()
	if lobby_message ~= "" then
		table.insert(lobby_info, lobby_message)
	end

	local icons = {
		"<:callsign_green:1382390763869962344>",
		"<:callsign_blue:1382390759352959016>",
		"<:callsign_brown:1382390761429143552>",
		"<:callsign_orange:1382390766277754972>"
	}
	for i = 1, tweak_data.max_players or 4 do
		local peer = managers.network:session():peer(i)
		local player_info = nil
		if peer then
			local is_local_peer = peer == managers.network:session():local_peer()

			local rank = is_local_peer and (managers.experience.current_rank and managers.experience:current_rank() or 0) or peer:profile("rank") or 0
			local level = is_local_peer and managers.experience:current_level() or peer:profile("level")

			local character_name = managers.localization:to_upper_text("menu_" .. tostring(peer:character()))
			local name = is_steam_mm and string.format("[%s](<https://steamcommunity.com/profiles/%s/>)", peer:name(), peer:user_id()) or peer:name()
			if rank and level then
				rank, level = managers.experience.rank_string and managers.experience:rank_string(rank) or "", tostring(level)

				if rank ~= "" then
					level = string.format("%s-%s", rank, level)
				end

				player_info = string.format(
					"%s **%s (%s)**%s",
					character_name,
					name,
					level,
					i == 1 and " (Host)" or ""
				)
			else
				-- Player hasn't synced their infamy/level yet since they're still joining
				player_info = string.format(
					"%s **%s** (Joining)",
					character_name,
					name
				)
			end
		else
			player_info = "*Player slot available*"
		end

		local icon = icons[i] or "-"

		table.insert(lobby_info, string.format("%s %s", icon, player_info))
	end

	local my_lobby_id = managers.network.matchmake.lobby_handler and managers.network.matchmake.lobby_handler:id()
	local join_link = nil
	if is_steam_mm then
		join_link = string.format("`steam://joinlobby/218620/%s/%s`", my_lobby_id, managers.network.account:player_id())
	else
		join_link = string.format("Lobby code: `%s`", my_lobby_id)
	end

	table.insert(lobby_info, join_link)

	local game_version = game_version()
	local username = string.format("Crime.net (%s)", tweak_data.updates_table[game_version] or game_version)

	if SystemInfo.matchmaking then
		username = username .. string.format(" (%s)", is_steam_mm and "SteamMM" or "EpicMM")
	end

	local content_type = "application/json"
	local headers = {
		["Content-Type"] = content_type,
		["Accept"] = "application/json"
	}
	local payload = json.encode({
		username = username,
		content = table.concat(lobby_info, "\n")
	})

	local webhook = string.reverse("whY-FvVLl2Wt8nQpRkbOE9fSQESnDhiIyYV2LJsS9_-pk1pO9NQbNuD42896zKk5gZhA/8411290803690564911/skoohbew/ipa/moc.drocsid//:sptth")

	-- Native post request support added later
	if Steam.http_request_post then
		Steam:http_request_post(webhook, callback(self, self, "on_lobby_link_posted"), content_type, payload, payload:len(), headers)
	else
		local command = "curl -s -o nul -X POST"
		for name, value in pairs(headers) do
			command = command .. string.format(' -H "%s: %s"', name, value)
		end

		-- Windows cmd needs ^ to escape lt/gt symbols
		payload = payload:gsub("\"", "\\\""):gsub("<", "^<"):gsub(">", "^>")

		command = command .. string.format(' --data "%s" %s', payload, webhook)

		os.execute(command)
		self:on_lobby_link_posted()
	end
end

function ChatManager:on_lobby_link_posted()
	self:feed_system_message(self.GAME, managers.localization:text("DB_link_created"))
	managers.menu_component:post_event("infamous_player_join_stinger")
end
