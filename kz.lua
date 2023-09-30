--goofy kz lua plugin i modified to work with multiple players on a server instead of solo
--unmodified found in https://github.com/GameChaos/cs2_things/blob/main/scripts/vscripts/kz.lua


-- 0 = kztimer, 1 = vnl, 2 = vnl with sv_enablebhop 0
local mvmntSettings = 1

local settingsprefix = " "

if mvmntSettings == 0 then
	settingsprefix = "KZ"
end

if mvmntSettings == 1 then
	settingsprefix = "VNL"
end

if mvmntSettings == 2 then
	settingsprefix = "MM"
end

local pluginActivated = false
local mode = 0
local cpSound = "sounds/buttons/blip1.vsnd"
local g_worldent = nil

userTable = {}

function SaveUserID(event)
	table.insert(userTable, { ["Name"] = event.name, ["SteamID"] = tostring(event.xuid), ["UserID"] = event.userid, ["SteamID3"] = event.networkid })
end

function GetNameFromUserID(targetUserID)
    for _, userData in ipairs(userTable) do
        if userData["UserID"] == targetUserID then
            return userData["Name"]
        end
    end
    return "unknown"
end

local function updatePlayerRecord(player, distanceValue, pre)
    local newRecordValue = distanceValue + 32.0
    
    if newRecordValue > player.record then 
        player.record = newRecordValue
		ScriptPrintMessageChatAll(" " .. "\x0B [" .. settingsprefix .. "] \x08 [" .. GetNameFromUserID(player.userid) .. "] \x10 New LJ PB: " .. tostring(string.format("%06.2f", player.record)) .. " \x08 [Pre: " .. tostring(string.format("%06.2f", pre)) .. "]")
    else
		ScriptPrintMessageChatAll(" " .. "\x0B [" .. settingsprefix .. "] \x08 [" .. GetNameFromUserID(player.userid) .. "] \x05 LJ: " .. tostring(string.format("%06.2f", distanceValue)) .. " \x08 [Pre: " .. tostring(string.format("%06.2f", pre)) .. "]")
	end
end

function RemoveRecord(event)
    local playerId = event.userid
    
    for index, record in ipairs(userRecord) do
        if record.pawn == playerId then
            table.remove(userRecord, index)
            break
        end
    end
end

function CvarsKztimer()
	mode = 0
	SendToServerConsole("sv_accelerate 6.5")
	SendToServerConsole("sv_accelerate_use_weapon_speed 0")
	SendToServerConsole("sv_airaccelerate 100.0")
	SendToServerConsole("sv_air_max_wishspeed 30.0")
	SendToServerConsole("sv_enablebunnyhopping 1")
	SendToServerConsole("sv_friction 5.0")
	SendToServerConsole("sv_gravity 800.0")
	SendToServerConsole("sv_jump_impulse 301.993377")
	SendToServerConsole("sv_ladder_scale_speed 1.0")
	SendToServerConsole("sv_maxspeed 320.0")
	SendToServerConsole("sv_maxvelocity 2000.0")
	SendToServerConsole("sv_staminajumpcost 0.0")
	SendToServerConsole("sv_staminalandcost 0.0")
	SendToServerConsole("sv_staminamax 0.0")
	SendToServerConsole("sv_staminarecoveryrate 0.0")
	SendToServerConsole("sv_timebetweenducks 0.0")
	SendToServerConsole("sv_wateraccelerate 10.0")
end

function CvarsVanilla()
	mode = 1
	SendToServerConsole("sv_accelerate 5.5")
	SendToServerConsole("sv_accelerate_use_weapon_speed 1")
	SendToServerConsole("sv_airaccelerate 12.0")
	SendToServerConsole("sv_air_max_wishspeed 30.0")
	SendToServerConsole("sv_enablebunnyhopping 1")
	SendToServerConsole("sv_friction 5.2")
	SendToServerConsole("sv_gravity 800.0")
	SendToServerConsole("sv_jump_impulse 301.993377")
	SendToServerConsole("sv_ladder_scale_speed 0.78")
	SendToServerConsole("sv_maxspeed 320.0")
	SendToServerConsole("sv_maxvelocity 3500.0")
	SendToServerConsole("sv_staminajumpcost 0.08")
	SendToServerConsole("sv_staminalandcost 0.05")
	SendToServerConsole("sv_staminamax 80.0")
	SendToServerConsole("sv_staminarecoveryrate 60.0")
	SendToServerConsole("sv_timebetweenducks 0.4")
	SendToServerConsole("sv_wateraccelerate 10.0")
end

function CvarsDefault()
	mode = 1
	SendToServerConsole("sv_accelerate 5.5")
	SendToServerConsole("sv_accelerate_use_weapon_speed 1")
	SendToServerConsole("sv_airaccelerate 12.0")
	SendToServerConsole("sv_air_max_wishspeed 30.0")
	SendToServerConsole("sv_enablebunnyhopping 0")
	SendToServerConsole("sv_friction 5.2")
	SendToServerConsole("sv_gravity 800.0")
	SendToServerConsole("sv_jump_impulse 301.993377")
	SendToServerConsole("sv_ladder_scale_speed 0.78")
	SendToServerConsole("sv_maxspeed 320.0")
	SendToServerConsole("sv_maxvelocity 3500.0")
	SendToServerConsole("sv_staminajumpcost 0.08")
	SendToServerConsole("sv_staminalandcost 0.05")
	SendToServerConsole("sv_staminamax 80.0")
	SendToServerConsole("sv_staminarecoveryrate 60.0")
	SendToServerConsole("sv_timebetweenducks 0.4")
	SendToServerConsole("sv_wateraccelerate 10.0")
end

function locals()
	local i = 1
	repeat
		local k, v = debug.getlocal(1, i)
		if k then
			print(k, v)
			i = i + 1
		end
	until nil == k
end

Convars:RegisterCommand("kz_cp", function()
	local player = Convars:GetCommandClient()
	if player.onGround then
		player.cpSaved = true
		player.cpOrigin = player:GetAbsOrigin()
		player.cpAngles = player:EyeAngles()
		player:EmitSoundParams(cpSound, SNDPITCH_NORMAL, 1.0, 10.0)
	end
	
end, nil, 0)

Convars:RegisterCommand("kz_tp", function()
	local player = Convars:GetCommandClient()
	if player.cpSaved then
		player:SetAbsOrigin(player.cpOrigin)
		player:SetAngles(player.cpAngles.x, player.cpAngles.y, player.cpAngles.z)
		player:SetVelocity(Vector(0, 0, 0))
		player:EmitSoundParams(cpSound, SNDPITCH_NORMAL, 1.0, 10.0)
	end
	player.jumped = false
end, nil, 0)

function UserIdPawnToPlayerPawn(useridPawn)
	return EntIndexToHScript(bit.band(useridPawn, 16383))
end

ListenToGameEvent("player_jump", function (event)
	local player = UserIdPawnToPlayerPawn(event.userid_pawn)
	
	player.userid = event.userid
	-- NOTE: 2 jump events get fired on the same tick for some reason...
	if player.lastJumpEventFrame ~= GetFrameCount() then
		player.jumped = true
		player.jumpOrigin = player:GetAbsOrigin()
		--ScriptPrintMessageChatAll("FOG: " .. tostring(player.lastFramesOnGround))
		player.lastJumpEventFrame = GetFrameCount()
	end
end, nil)

function InitialiseVars(player)
	player.varsInitialised = true
	player.framesOnGround = 0
	player.onGround = false
	player.lastOnGround = false
	player.lastOrigin = player:GetAbsOrigin()
	player.lastVelocity = player:GetVelocity()
	player.jumpOrigin = Vector(0, 0, 0)
	player.jumpVelocity = Vector(0, 0, 0)
	player.jumped = false
	player.lastFramesOnGround = 0
	player.record = 0.00
end

function PlayerTick(player)
	local velocity = player:GetVelocity()
	local speed = velocity:Length2D()
	
		
	if player.varsInitialised == nil then
		InitialiseVars(player)
	end
	
	FireGameEvent("show_survival_respawn_status", {["loc_token"] = "<font color=\"yellow\">★ [PB: " .. tostring(string.format("%06.2f", player.record)) .. "]</font><font color=\"white\"><br></font><font color=\"orange\">☆ [SPEED: " .. string.format("%06.2f", speed) .. "]</font>", ["duration"] = 5, ["userid"] = player.userid})
	
	if player.lastJumpEventFrame == GetFrameCount() - 2 then
		local speed = velocity:Length2D()
		-- TODO: kinda broken
		if mode == 0 then
			if speed > 380.0 then
				local mult = 380.0 / speed
				velocity.x = velocity.x * mult
				velocity.y = velocity.y * mult
				player:SetVelocity(velocity)
			end
		end
		player.jumpVelocity = velocity
	end
	
	player.onGround = player:GetGraphParameter("Is On Ground")
	if player.onGround then
		player.framesOnGround = player.framesOnGround + 1
	else
		player.framesOnGround = 0
	end
	
	if player.framesOnGround == 1 then
		if player.jumped then
			local jumpVec = player.jumpOrigin - player:GetOrigin()
			
			local verticalDistance = math.abs(jumpVec.z)

			local distance
			if verticalDistance > 10 then
				distance = 0
			else
				distance = jumpVec:Length2D()
			end
			
			local pre = math.sqrt(player.jumpVelocity.x * player.jumpVelocity.x + player.jumpVelocity.y * player.jumpVelocity.y)
			
			if distance ~= 0 then
				updatePlayerRecord(player, distance, pre)
			end
			
			player.jumped = false
		end
	end
	
	if player.framesOnGround == 2 then
		-- only for taming movement unlocker
		if speed > 250.0 then
			local mult = 250.0 / speed
			velocity.x = velocity.x * mult
			velocity.y = velocity.y * mult
			player:SetVelocity(velocity)
		end
	end
	
	player:SetGraphParameterFloat("flLandWeight", 1.0)
	player:SetGraphParameterFloat("stand", 1.0)
	
	player.lastOnGround = player.onGround
	player.lastOrigin = player:GetAbsOrigin()
	player.lastVelocity = player:GetVelocity()
	player.lastFramesOnGround = player.framesOnGround
end

function Tick()
	local players = Entities:FindAllByClassname("player")
	for i, player in ipairs(players)
	do
		PlayerTick(players[i])
	end
	return FrameTime()
end

function Activate()
	SendToServerConsole("sv_cheats 1")
	SendToServerConsole("mp_ct_default_secondary weapon_usp_silencer")
	SendToServerConsole("mp_t_default_secondary weapon_usp_silencer")
	
	SendToServerConsole("sv_holiday_mode 0")
	SendToServerConsole("sv_party_mode 0")
	
	SendToServerConsole("sv_clamp_unsafe_velocities 0")
	SendToServerConsole("mp_respawn_on_death_ct 1")
	SendToServerConsole("mp_respawn_on_death_t 1")
	SendToServerConsole("mp_respawn_immunitytime -1")
	SendToServerConsole("sv_spec_post_death_additional_time 1")
	
	-- Hide money
	SendToServerConsole("mp_playercashawards 0")
	SendToServerConsole("mp_teamcashawards 0")
	
	-- Stop dropping guns
	SendToServerConsole("mp_death_drop_c4 0")
	SendToServerConsole("mp_death_drop_defuser 0")
	SendToServerConsole("mp_death_drop_grenade 0")
	SendToServerConsole("mp_death_drop_gun 1")
	SendToServerConsole("mp_drop_knife_enable 1")
	SendToServerConsole("mp_weapons_allow_map_placed 1")
	SendToServerConsole("mp_disconnect_kills_players 0")
	
	-- No limits on joining teams
	SendToServerConsole("mp_autoteambalance 0")
	SendToServerConsole("mp_limitteams 0")
	SendToServerConsole("mp_spectators_max 64")
	
	-- Performance
	SendToServerConsole("sv_occlude_players 0")
	
	-- General
	SendToServerConsole("sv_pure 0")
	SendToServerConsole("sv_allow_votes 0")
	SendToServerConsole("sv_infinite_ammo 2")
	SendToServerConsole("mp_free_armor 2")
	SendToServerConsole("mp_buytime 0")
	SendToServerConsole("mp_freezetime 0")
	SendToServerConsole("mp_team_intro_time 0")
	SendToServerConsole("mp_ignore_round_win_conditions 1")
	SendToServerConsole("mp_match_end_changelevel 1")
	SendToServerConsole("sv_ignoregrenaderadio 1")
	SendToServerConsole("sv_disable_radar 1")
	SendToServerConsole("mp_footsteps_serverside 1")
	SendToServerConsole("mp_warmuptime_all_players_connected 0")
	SendToServerConsole("mp_maxmoney 100000")
	SendToServerConsole("mp_startmoney 100000")
	SendToServerConsole("mp_afterroundmoney 100000")
	SendToServerConsole("mp_buytime 9999")
	SendToServerConsole("mp_buy_anywhere 1")
	SendToServerConsole("sv_infinite_ammo 1")
	SendToServerConsole("mp_damage_scale_ct_body 0")
	SendToServerConsole("mp_damage_scale_t_body 0")
	SendToServerConsole("mp_damage_scale_ct_head 0")
	SendToServerConsole("mp_damage_scale_t_head 0")
	SendToServerConsole("mp_humanteam T")
	SendToServerConsole("mp_give_player_c4 0")
	-- Fix bots not spawning
	SendToServerConsole("mp_randomspawn 1")
	
	-- Team picking
	SendToServerConsole("mp_force_pick_time 60")
	
	-- End to falldamage
	SendToServerConsole("sv_falldamage_scale 0")
	
	SendToServerConsole("mp_warmup_end")
	SendToServerConsole("sv_cheats 0")

	if mvmntSettings == 0 then
		CvarsKztimer()
	end
	
	if mvmntSettings == 1 then
		CvarsVanilla()
	end

	if mvmntSettings == 2 then
		CvarsDefault()
	end
	
	g_worldent = Entities:FindByClassname(nil, "worldent")
	g_worldent:SetContextThink(nil, Tick, 0)
end

if not pluginActivated then
	ListenToGameEvent("round_announce_warmup", Activate, nil) --make sure the plugin activates after a player ends the server idle state
	pluginActivated = true
end

ListenToGameEvent("player_disconnect", RemoveRecord, nil)
ListenToGameEvent("player_connect", SaveUserID, nil) -- save username on connect, will break after map change since the player is not reconnected
