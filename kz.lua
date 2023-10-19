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
end

function CvarsVanilla()
	mode = 1
end

function CvarsDefault()
	mode = 1
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

local knifeCommands = {
    bayonet = "500",
    butterfly = "515",
    karambit = "507",
    m9 = "508",
    skeleton = "525",
    talon = "523",
    classic = "503",
    stiletto = "522",
    flip = "505",
    ursus = "519",
    paracord = "517",
    survival = "518",
    huntsman = "509",
    falchion = "512",
    bowie = "514",
    daggers = "516",
    gut = "506",
    navaja = "520"
}

Convars:RegisterCommand("knife", function(_, knife)
    local command = knifeCommands[knife]
    if command then
        SendToServerConsole("sv_cheats true")
        SendToServerConsole("subclass_change " .. command .. " weapon_knife")
    end
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
