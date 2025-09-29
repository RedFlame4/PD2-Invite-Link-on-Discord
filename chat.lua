local send_message_orig = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if not string.begins(message, "/link") and not string.begins(message, "/invite") then
		return send_message_orig(self, channel_id, sender, message)
	end

	local attributes = DiscordLink.attributes
	if not next(attributes) then
		return
	end

	if Global.game_settings.permission == "private" then
		self:feed_system_message(self.GAME, managers.localization:text("DB_permission"))
		managers.menu_component:post_event("menu_error")

		return
	end

	local matchmaking = nil
	if SystemInfo.matchmaking then
		matchmaking = SystemInfo:matchmaking() == Idstring("MM_STEAM") and "steam" or "epic"
	end

	local lobby_info = {
		game_version = attributes.send_version and Application:version() or nil,
		version_identifier = attributes.version_identifier or nil,
		matchmaking = matchmaking,
		channel_id = attributes.channel_id,
		lobby_id = managers.network.matchmake.lobby_handler:id(),
		lobby_message = message:gsub("^/link", ""):gsub("^/invite", ""):trim(),
		max_players = BigLobbyGlobals and BigLobbyGlobals.num_player_slots and BigLobbyGlobals:num_player_slots() or tweak_data.max_players or 4,
		players = {},
	}

	local heist_data = {}
	local is_crime_spree = managers.crime_spree and managers.crime_spree:is_active()
	if is_crime_spree then
		heist_data.spree_level = managers.crime_spree:server_spree_level()
	end

	if managers.job:has_active_job() then
		heist_data.job_name = managers.localization:text(managers.job:current_job_data().name_id)
		heist_data.level_name = managers.localization:text(managers.job:current_level_data().name_id)

		if is_crime_spree then
		elseif managers.skirmish and managers.skirmish:is_skirmish() then
			heist_data.is_holdout = true
		else
			local job_chain_data = managers.job.current_job_chain_data and managers.job:current_job_chain_data() or managers.job:current_job_data().chain -- current_job_chain_data added later

			heist_data.days = #job_chain_data
			heist_data.difficulty = managers.localization:text(tweak_data.difficulty_name_ids[Global.game_settings.difficulty])
			heist_data.pro_job = managers.job:is_current_job_professional()
			heist_data.one_down = Global.game_settings.one_down
			heist_data.is_escape = managers.job:interupt_stage() and true
		end
	end

	if next(heist_data) then
		heist_data.state = Utils:IsInHeist() and "in_game" or Utils:IsInGameState() and "briefing" or "in_lobby"
		lobby_info.heist_data = heist_data
	end

	-- managers.network:session():all_peers() added in SBLT-CUS
	local local_peer = managers.network:session():local_peer()
	for peer_id, peer in pairs(managers.network:session():all_peers()) do
		local player_data = {
			character_name = managers.localization:text("menu_" .. tostring(peer:character())),
			steam_id = matchmaking ~= "epic" and peer:user_id() or nil,
			username = peer:name(),
		}

		if peer == local_peer then
			player_data.rank = managers.experience.current_rank and managers.experience:current_rank()
			player_data.level = managers.experience:current_level()
		else
			player_data.rank = peer:profile("rank")
			player_data.level = peer:profile("level")

			if not player_data.level then -- not synced yet
				player_data.is_joining = true
			end
		end

		lobby_info.players[peer_id] = player_data
	end

	local content_type = "application/json"
	local headers = {
		["Content-Type"] = content_type,
		["Accept"] = "application/json"
	}
	local payload = json.encode(lobby_info)

	local api_link = "https://paydayretro.com/api/lobby-link"

	-- Native post request support added later, TODO: support HttpRequest
	if Steam.http_request_post then
		Steam:http_request_post(api_link, callback(self, self, "on_lobby_link_posted"), content_type, payload, payload:len(), headers)
	else
		local command = "curl -s -o nul -X POST"
		for name, value in pairs(headers) do
			command = command .. string.format(' -H "%s: %s"', name, value)
		end

		-- Windows cmd needs ^ to escape lt/gt symbols
		payload = payload:gsub("\"", "\\\""):gsub("<", "^<"):gsub(">", "^>")

		command = command .. string.format(' --data "%s" %s', payload, api_link)

		os.execute(command)
		self:on_lobby_link_posted()
	end
end

function ChatManager:on_lobby_link_posted()
	self:feed_system_message(self.GAME, managers.localization:text("DB_link_created"))
	managers.menu_component:post_event("infamous_player_join_stinger")
end
