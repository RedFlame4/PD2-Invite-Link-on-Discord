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

	local diffs = {
		normal = "Normal",
		hard = "Hard",
		overkill = "Very Hard",
		overkill_145 = "OVERKILL",
		easy_wish = "Mayhem",
		overkill_290 = "Death Wish",
		sm_wish = "Death Sentence",
	}

	local levels = {
		airport = "Airport",
		alex_1 = "Cook Off",
		alex_2 = "Code for Meth",
		alex_3 = "Bus Stop",
		arm_cro = "Transport: Crossroads",
		arm_fac = "Transport: Harbor",
		arm_for = "Transport: Train Heist",
		arm_hcm = "Transport: Downtown",
		arm_par = "Transport: Park",
		arm_und = "Transport: Underpass",
		big = "The Big Bank",
		branchbank = "Bank Heist",
		election_day_1 = "Right Track",
		election_day_2 = "Swing Vote",
		election_day_3 = "Breaking Ballot",
		escape_cafe = "Cafe Escape",
		escape_garage = "Garage Escape",
		escape_overpass = "Overpass Escape",
		escape_park = "Park Escape",
		escape_street = "Street Escape",
		family = "Diamond Store",
		firestarter_1 = "Firestarter: Airport",
		firestarter_2 = "Firestarter: FBI Server",
		firestarter_3 = "Firestarter: Trustee Bank",
		four_stores = "Four Stores",
		framing_frame_1 = "Art Gallery",
		framing_frame_2 = "Train Trade",
		framing_frame_3 = "Framing",
		haunted = "Safe House Nightmare",
		jewelry_store = "Jewelry Store",
		kosugi = "Shadow Raid",
		mallcrasher = "Mallcrasher",
		mia_1 = "Hotline Miami",
		mia_2 = "Four Floors",
		nightclub = "Nightclub",
		roberts = "GO Bank",
		ukrainian_job = "Ukrainian Job",
		watchdogs_1 = "Truck Load",
		watchdogs_2 = "Boat Load",
		welcome_to_the_jungle_1 = "Club House",
		welcome_to_the_jungle_2 = "Engine Problem",
	}

	local lobby_info = {}

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

			local rank = is_local_peer and managers.experience:current_rank() or peer:profile("rank")
			local level = is_local_peer and managers.experience:current_level() or peer:profile("level")

			local name_link = string.format("[%s](<https://steamcommunity.com/profiles/%s/>)", peer:name(), peer:user_id())
			if rank and level then
				rank = managers.experience:rank_string(rank)
				rank = rank ~= "" and rank .. "-" or rank

				player_info = string.format(
					"%s **%s (%s%s)**%s",
					CriminalsManager.convert_old_to_new_character_workname(peer:character()):upper(),
					name_link,
					rank,
					tostring(level),
					i == 1 and " (Host)" or ""
				)
			else
				-- Player hasn't synced their infamy/level yet since they're still joining
				player_info = string.format(
					"%s **%s** (Joining)",
					CriminalsManager.convert_old_to_new_character_workname(peer:character()):upper(),
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

	local level_id = Global.game_settings.level_id
	local level_name = levels[level_id] or tweak_data.levels:get_localized_level_name_from_level_id(level_id) -- fallback to localisationmanager, works as long as the game is in English
	local difficulty = diffs[Global.game_settings.difficulty]:upper()
	local projob = managers.job:is_current_job_professional() and " (PRO JOB)" or ""
	local state = (Utils:IsInGameState() and not Utils:IsInHeist()) and "In Briefing" or Utils:IsInHeist() and "In Game" or "In Lobby"
	local stage_info = string.format("%s (%s)%s (%s)", level_name, difficulty, projob, state)

	local payload = json.encode({
		username = stage_info,
		content = table.concat(lobby_info, "\n")
	})

	-- Windows cmd needs ^ to escape lt/gt symbols
	payload = payload:gsub("\"", "\\\""):gsub("<", "^<"):gsub(">", "^>")

	local webhook = "https://discord.com/api/webhooks/1192094378114695229/8X-KGXZ38SbybXdHLuyFQy8qiOPlCww6XHscif6Yh-rUs7htV6zP7SupY865fTHvwbd_"
	local script = string.format('curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "%s" discord-webhook-link %s', payload, webhook)

	os.execute(script)

	managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("DBU37_link_created"))
	managers.menu_component:post_event("infamous_player_join_stinger")
end