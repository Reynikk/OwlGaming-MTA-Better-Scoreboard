--
-- Minimal Modern Scoreboard
-- Client-side script.
-- Created By Reynikk 
--

--[[ Functions to work with dummy players ]]--
local _getPlayerName = getPlayerName
local _getPlayerPing = getPlayerPing
local _getPlayerNametagColor = getPlayerNametagColor

function getPlayerName(player)
	if getElementType(player) == "player" then return _getPlayerName(player) end
	return getElementData(player, "name")
end

function getPlayerPing(player)
	if getElementType(player) == "player" then return _getPlayerPing(player) end
	return getElementData(player, "ping")
end

function getPlayerNametagColor(player)
	if getElementType(player) == "player" then return _getPlayerNametagColor(player)
	else
		local color = getElementData(player, "color")
		if color then
			return unpack(color)
		else
			return 255, 255, 255
		end
	end
end

--[[ Configuration ]]--
local SCOREBOARD_WIDTH				= 500				-- The scoreboard window width
local SCOREBOARD_HEIGHT				= 600				-- The scoreboard window height
local SCOREBOARD_HEADER_HEIGHT		= 60				-- Height for the header
local SCOREBOARD_PLAYER_INFO_HEIGHT	= 80				-- Height for the player info section
local SCOREBOARD_TOGGLE_CONTROL		= "tab"				-- Control/Key to toggle the scoreboard visibility
local SCOREBOARD_PGUP_CONTROL		= "mouse_wheel_up"	-- Control/Key to move one page up
local SCOREBOARD_PGDN_CONTROL		= "mouse_wheel_down"-- Control/Key to move one page down
local SCOREBOARD_DISABLED_CONTROLS	= { "next_weapon",	-- Controls that are disabled when the scoreboard is showing
										"previous_weapon",
										"aim_weapon",
										"radio_next",
										"radio_previous" }
local SCOREBOARD_TOGGLE_TIME		= 0				-- Time in miliseconds to make the scoreboard (dis)appear
local SCOREBOARD_POSTGUI			= true				-- Set to true if it must be drawn over the GUI

-- Minimal color scheme
local COLOR_WHITE = tocolor(255, 255, 255, 255)
local COLOR_BLACK = tocolor(0, 0, 0, 255)
local COLOR_BACKGROUND = tocolor(15, 15, 15, 230)
local COLOR_HEADER = tocolor(25, 25, 25, 250)
local COLOR_ACCENT = tocolor(220, 80, 80, 255)  -- Red accent
local COLOR_ACCENT_DARK = tocolor(180, 60, 60, 255)
local COLOR_TEXT_PRIMARY = tocolor(255, 255, 255, 255)
local COLOR_TEXT_SECONDARY = tocolor(200, 200, 200, 255)
local COLOR_TEXT_TERTIARY = tocolor(150, 150, 150, 255)
local COLOR_ROW_1 = tocolor(20, 20, 20, 180)
local COLOR_ROW_2 = tocolor(30, 30, 30, 180)
local COLOR_MONEY = tocolor(120, 220, 120, 255)
local COLOR_BANK = tocolor(120, 180, 255, 255)
local COLOR_SCROLL_BG = tocolor(40, 40, 40, 180)
local COLOR_SCROLL_FG = tocolor(220, 80, 80, 200)

-- Row settings
local ROW_HEIGHT = 30
local ROW_GAP = 2
local ROW_PADDING = 10

--[[ Global variables to this context ]]--
local g_isShowing = false		-- Marks if the scoreboard is showing
local g_currentWidth = 0		-- Current window width. Used for the fade in/out effect.
local g_currentHeight = 0		-- Current window height. Used for the fade in/out effect.
local g_scoreboardDummy			-- Will contain the scoreboard dummy element to gather info from.
local g_windowSize = { guiGetScreenSize() }	-- The window size
local g_localPlayer = getLocalPlayer()		-- The local player...
local g_currentPage = 0			-- The current scroll page
local g_players					-- We will keep a cache of the conected player list
local g_oldControlStates		-- To save the old control states before disabling them for scrolling

--[[ Pre-calculate some stuff ]]--
-- Scoreboard position
local SCOREBOARD_X = math.floor((g_windowSize[1] - SCOREBOARD_WIDTH) / 2)
local SCOREBOARD_Y = math.floor((g_windowSize[2] - SCOREBOARD_HEIGHT) / 2)

-- Column widths (percentage of total width)
local COLUMN_ID_WIDTH = 0.08
local COLUMN_NAME_WIDTH = 0.59
local COLUMN_HOURS_WIDTH = 0.15
local COLUMN_PING_WIDTH = 0.14
local COLUMN_SCROLL_WIDTH = 0.04

-- Column positions function - calculates positions dynamically
local function getColumnPositions()
    local positions = {}
    positions[1] = {SCOREBOARD_X, SCOREBOARD_X + COLUMN_ID_WIDTH * g_currentWidth}
    positions[2] = {positions[1][2], positions[1][2] + COLUMN_NAME_WIDTH * g_currentWidth}
    positions[3] = {positions[2][2], positions[2][2] + COLUMN_HOURS_WIDTH * g_currentWidth}
    positions[4] = {positions[3][2], positions[3][2] + COLUMN_PING_WIDTH * g_currentWidth}
    positions[5] = {positions[4][2], SCOREBOARD_X + g_currentWidth}
    return positions
end

--[[ Pre-declare some functions ]]--
local onRender
local fadeScoreboard
local drawScoreboard

--[[
* clamp
Clamps a value into a range.
--]]
local function clamp(valueMin, current, valueMax)
	if current < valueMin then
		return valueMin
	elseif current > valueMax then
		return valueMax
	else
		return current
	end
end

--[[
* createPlayerCache
Generates a new player cache.
--]]
function createPlayerCache(ignorePlayer)
	-- Optimize the function in case of not having to ignore a player
	if ignorePlayer then
		-- Clear the gloal table
		g_players = {}

		-- Get the list of connected players
		local players = getElementsByType("player")

		-- Dump them to the global table
		for k, player in ipairs(players) do
			if ignorePlayer ~= player then
				table.insert(g_players, player)
			end
		end
	else
		g_players = getElementsByType("player")
	end

	-- Add dummy players for testing
	for k,v in ipairs(getElementsByType("playerDummy")) do
		table.insert(g_players, v)
	end

	-- Sort the player list by their ID, giving priority to the local player
	table.sort(g_players, function(a, b)
		local idA = getElementData(a, "playerid") or 0
		local idB = getElementData(b, "playerid") or 0

		-- Perform the checks to always set the local player at the beggining
		if a == g_localPlayer then
			idA = -1
		elseif b == g_localPlayer then
			idB = -1
		end

		return tonumber(idA) < tonumber(idB)
	end)
end

--[[
* onClientResourceStart
Handles the resource start event to create the initial player cache
--]]
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), function()
	createPlayerCache()
end, false)

--[[
* onClientElementDataChange
Handles the element data changes event to update the player cache
if the playerid was changed.
--]]
addEventHandler("onClientElementDataChange", root, function(dataName, dataValue)
	if dataName == "playerid" then
		createPlayerCache()
	end
end)

--[[
* onClientPlayerQuit
Handles the player quit event to update the player cache.
--]]
addEventHandler("onClientPlayerQuit", root, function()
	createPlayerCache(source)
end)

--[[
* toggleScoreboard
Toggles the visibility of the scoreboard.
--]]
local function toggleScoreboard(show)
	if not getPedControlState(localPlayer, 'aim_weapon') then
		-- Force the parameter to be a boolean
		local show = show == true

		-- Check if the status has changed
		if show ~= g_isShowing then
			g_isShowing = show

			if g_isShowing and g_currentWidth == 0 and g_currentHeight == 0 then
				-- Handle the onClientRender event to start drawing the scoreboard.
				addEventHandler("onClientPreRender", root, onRender, false)
			end

			-- Little hack to avoid switching weapons while moving through the scoreboard pages.
			if g_isShowing then
				g_oldControlStates = {}
				for k, control in ipairs(SCOREBOARD_DISABLED_CONTROLS) do
					g_oldControlStates[k] = isControlEnabled(control)
					toggleControl(control, false)
				end
			else
				for k, control in ipairs(SCOREBOARD_DISABLED_CONTROLS) do
					toggleControl(control, g_oldControlStates[k])
				end
				g_oldControlStates = nil
			end
		end
	end
end

--[[
* onToggleKey
Function to bind to the appropiate key the function to toggle the scoreboard visibility.
--]]
local function onToggleKey(key, keyState)
	-- Check if the scoreboard element has been created
	if not g_scoreboardDummy then
		local elementTable = getElementsByType("scoreboard")
		if #elementTable > 0 then
			g_scoreboardDummy = elementTable[1]
		else
			return
		end
	end

	-- Toggle the scoreboard, and check that it's allowed.
	toggleScoreboard(keyState == "down" and getElementData(g_scoreboardDummy, "allow"))
end
bindKey(SCOREBOARD_TOGGLE_CONTROL, "both", onToggleKey)

--[[
* onScrollKey
Function to bind to the appropiate key the function to change the current page.
--]]
local function onScrollKey(direction)
	if g_isShowing then
		-- Calculate how many players can fit in the list
		local listHeight = g_currentHeight - SCOREBOARD_HEADER_HEIGHT - SCOREBOARD_PLAYER_INFO_HEIGHT
		local headerSpace = ROW_HEIGHT + ROW_GAP * 2 -- Space taken by the header row
		local availableHeight = listHeight - headerSpace
		local rowUnitHeight = ROW_HEIGHT + ROW_GAP
		local maxVisiblePlayers = math.floor(availableHeight / rowUnitHeight)

		-- Only allow scrolling if we have more players than fit on one page
		if #g_players <= maxVisiblePlayers then
			g_currentPage = 0
			return
		end

		-- Calculate max pages
		local maxPages = math.floor((#g_players - 1) / maxVisiblePlayers)

		if direction then
			-- Scroll down, but don't exceed max pages
			g_currentPage = math.min(g_currentPage + 1, maxPages)
		else
			-- Scroll up, but don't go below 0
			g_currentPage = math.max(g_currentPage - 1, 0)
		end
	end
end
bindKey(SCOREBOARD_PGUP_CONTROL, "down", function() onScrollKey(false) end)
bindKey(SCOREBOARD_PGDN_CONTROL, "down", function() onScrollKey(true) end)

--[[
* onRender
Event handler for onClientPreRender. It will forward the flow to the most appropiate
function: fading-in, fading-out or drawScoreboard.
--]]
onRender = function(timeshift)
	-- Boolean to check if we must draw the scoreboard.
	local drawIt = false

	if g_isShowing then
		-- Check if the scoreboard has been disallowed
		if not getElementData(g_scoreboardDummy, "allow") then
			toggleScoreboard(false)
		-- If it's showing, check if it got fully faded in. Else, draw it normally.
		elseif g_currentWidth < SCOREBOARD_WIDTH or g_currentHeight < SCOREBOARD_HEIGHT then
			drawIt = fadeScoreboard(timeshift, 1)
		else
			-- Allow drawing the full scoreboard
			drawIt = true
		end
	else
		-- If it shouldn't be showing, make another step to fade it out.
		drawIt = fadeScoreboard(timeshift, -1)
	end

	-- Draw the scoreboard if allowed.
	if drawIt then
		drawScoreboard()
	end
end

--[[
* fadeScoreboard
Makes a step of the fade effect. Gets a multiplier to make it either fading in or out.
--]]
fadeScoreboard = function(timeshift, multiplier)
	-- Get the percentage of the final size that it should grow for this step.
	local growth = (timeshift / SCOREBOARD_TOGGLE_TIME) * multiplier

	-- Apply the growth to the scoreboard size with smoother animation
	local targetWidth = multiplier > 0 and SCOREBOARD_WIDTH or 0
	local targetHeight = multiplier > 0 and SCOREBOARD_HEIGHT or 0

	-- Use easing for smoother animation
	if multiplier > 0 then
		-- Fade in - accelerate at the beginning
		g_currentWidth = clamp(0, g_currentWidth + (SCOREBOARD_WIDTH * growth * (1 + (1 - g_currentWidth / SCOREBOARD_WIDTH) * 0.5)), SCOREBOARD_WIDTH)
		g_currentHeight = clamp(0, g_currentHeight + (SCOREBOARD_HEIGHT * growth * (1 + (1 - g_currentHeight / SCOREBOARD_HEIGHT) * 0.5)), SCOREBOARD_HEIGHT)
	else
		-- Fade out - decelerate at the end
		g_currentWidth = clamp(0, g_currentWidth + (SCOREBOARD_WIDTH * growth * (1 + (g_currentWidth / SCOREBOARD_WIDTH) * 0.5)), SCOREBOARD_WIDTH)
		g_currentHeight = clamp(0, g_currentHeight + (SCOREBOARD_HEIGHT * growth * (1 + (g_currentHeight / SCOREBOARD_HEIGHT) * 0.5)), SCOREBOARD_HEIGHT)
	end

	-- Check if the scoreboard has collapsed. If so, unregister the onClientRender event.
	if g_currentWidth <= 1 or g_currentHeight <= 1 then
		g_currentWidth = 0
		g_currentHeight = 0
		removeEventHandler("onClientPreRender", root, onRender)
		return false
	else
		return true
	end
end

--[[
* drawPlayerInfo
Draws the player's personal information (name, money, bank balance)
--]]
local function drawPlayerInfo()
	-- Check if player is logged in
	local loggedIn = getElementData(g_localPlayer, "loggedin") == 1

	-- Get player data
	local characterName = "Not logged in"
	local money = 0
	local bankMoney = 0

	if loggedIn then
		characterName = getPlayerName(g_localPlayer):gsub("_", " ")
		money = getElementData(g_localPlayer, "money") or 0
		bankMoney = getElementData(g_localPlayer, "bankmoney") or 0
	end

	-- Format money with commas manually
	local function formatMoney(amount)
		local formatted = tostring(amount)
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
			if (k == 0) then
				break
			end
		end
		return formatted
	end

	local formattedMoney = formatMoney(money)
	local formattedBankMoney = formatMoney(bankMoney)

	-- Calculate positions
	local infoY = SCOREBOARD_Y + SCOREBOARD_HEADER_HEIGHT
	local infoHeight = clamp(0, SCOREBOARD_PLAYER_INFO_HEIGHT, g_currentHeight - SCOREBOARD_HEADER_HEIGHT)

	-- Draw background for player info
	dxDrawRectangle(SCOREBOARD_X, infoY, g_currentWidth, infoHeight, COLOR_HEADER)

	-- Draw accent line at top
	dxDrawRectangle(SCOREBOARD_X, infoY, g_currentWidth, 3, COLOR_ACCENT)

	-- Draw vertical divider between character/cash and bank
	dxDrawRectangle(SCOREBOARD_X + g_currentWidth/2, infoY + 10, 1, infoHeight - 20, COLOR_ACCENT_DARK)

	-- Reorganize layout to be more compact and aligned
	-- Left side: Character name and location
	-- Right side: Bank balance and cash

	-- Draw character name
	dxDrawText("CHARACTER",
		SCOREBOARD_X + 15,
		infoY + 10,
		SCOREBOARD_X + g_currentWidth/2 - 15,
		infoY + 25,
		COLOR_TEXT_TERTIARY,
		1.0, "default-bold",
		"left", "top")

	dxDrawText(characterName,
		SCOREBOARD_X + 15,
		infoY + 25,
		SCOREBOARD_X + g_currentWidth/2 - 15,
		infoY + 45,
		COLOR_TEXT_PRIMARY,
		1.2, "default-bold",
		"left", "top")

	-- Get player location using getZoneName
	local locationText = "Unknown"
	if loggedIn then
		-- Get player position
		local x, y, z = getElementPosition(g_localPlayer)

		-- Get zone and city
		local zone = getZoneName(x, y, z)
		local city = getZoneName(x, y, z, true)

		-- Format location text
		if zone and city and zone ~= city then
			locationText = zone .. ", " .. city
		elseif zone then
			locationText = zone
		elseif city then
			locationText = city
		end
	end

	-- Draw location (directly below character name)
	dxDrawText("LOCATION",
		SCOREBOARD_X + 15,
		infoY + 45,
		SCOREBOARD_X + g_currentWidth/2 - 15,
		infoY + 60,
		COLOR_TEXT_TERTIARY,
		1.0, "default-bold",
		"left", "top")

	dxDrawText(locationText,
		SCOREBOARD_X + 15,
		infoY + 60,
		SCOREBOARD_X + g_currentWidth/2 - 15,
		infoY + 75,
		COLOR_TEXT_PRIMARY,
		1.0, "default-bold",
		"left", "top")

	-- Draw bank balance (right side, aligned with character name)
	dxDrawText("BANK",
		SCOREBOARD_X + g_currentWidth/2 + 15,
		infoY + 10,
		SCOREBOARD_X + g_currentWidth - 15,
		infoY + 25,
		COLOR_TEXT_TERTIARY,
		1.0, "default-bold",
		"left", "top")

	dxDrawText("$" .. formattedBankMoney,
		SCOREBOARD_X + g_currentWidth/2 + 15,
		infoY + 25,
		SCOREBOARD_X + g_currentWidth - 15,
		infoY + 45,
		COLOR_BANK,
		1.0, "default-bold",
		"left", "top")

	-- Draw money (right side, below bank balance)
	dxDrawText("CASH",
		SCOREBOARD_X + g_currentWidth/2 + 15,
		infoY + 45,
		SCOREBOARD_X + g_currentWidth - 15,
		infoY + 60,
		COLOR_TEXT_TERTIARY,
		1.0, "default-bold",
		"left", "top")

	dxDrawText("$" .. formattedMoney,
		SCOREBOARD_X + g_currentWidth/2 + 15,
		infoY + 60,
		SCOREBOARD_X + g_currentWidth - 15,
		infoY + 75,
		COLOR_MONEY,
		1.0, "default-bold",
		"left", "top")
end

--[[
* drawRow
Draws a row in the scoreboard
--]]
local function drawRow(id, name, hours, ping, colors, isHeader, top, rowIndex)
	local bottom = top + ROW_HEIGHT
	local columnPositions = getColumnPositions()

	-- Draw row background if not header
	if not isHeader then
		local rowColor = (rowIndex % 2 == 0) and COLOR_ROW_1 or COLOR_ROW_2
		dxDrawRectangle(SCOREBOARD_X, top, g_currentWidth, ROW_HEIGHT, rowColor)

		-- Highlight for local player
		if name == getPlayerName(g_localPlayer):gsub("_", " ") then
			dxDrawRectangle(SCOREBOARD_X, top, 3, ROW_HEIGHT, COLOR_ACCENT)
		end
	else
		-- Draw header background
		dxDrawRectangle(SCOREBOARD_X, top, g_currentWidth, ROW_HEIGHT, COLOR_HEADER)

		-- Draw accent line under header
		dxDrawRectangle(SCOREBOARD_X, bottom - 1, g_currentWidth, 1, COLOR_ACCENT)
	end

	-- Make sure we have valid positions
	if not columnPositions or not columnPositions[1] then return end

	-- Draw ID
	dxDrawText(id,
		columnPositions[1][1] + ROW_PADDING,
		top,
		columnPositions[1][2] - ROW_PADDING,
		bottom,
		isHeader and COLOR_TEXT_TERTIARY or colors[1],
		1.0, "default-bold",
		"center", "center")

	-- Draw Name
	dxDrawText(name,
		columnPositions[2][1] + ROW_PADDING,
		top,
		columnPositions[2][2] - ROW_PADDING,
		bottom,
		isHeader and COLOR_TEXT_TERTIARY or colors[2],
		1.0, "default-bold",
		"left", "center")

	-- Draw Hours
	dxDrawText(hours,
		columnPositions[3][1] + ROW_PADDING,
		top,
		columnPositions[3][2] - ROW_PADDING,
		bottom,
		isHeader and COLOR_TEXT_TERTIARY or colors[3],
		1.0, "default-bold",
		"center", "center")

	-- Draw Ping
	dxDrawText(ping,
		columnPositions[4][1] + ROW_PADDING,
		top,
		columnPositions[4][2] - ROW_PADDING,
		bottom,
		isHeader and COLOR_TEXT_TERTIARY or colors[3],
		1.0, "default-bold",
		"center", "center")
end

--[[
* drawScrollBar
Draws the scroll bar. Position ranges from 0 to 1.
--]]
local function drawScrollBar(top, position, height)
	-- Only draw scrollbar if we're fully visible
	if g_currentWidth < SCOREBOARD_WIDTH or g_currentHeight < SCOREBOARD_HEIGHT then
		return
	end

	-- Get the bounding box
	local columnPositions = getColumnPositions()

	-- Make sure we have valid positions
	if not columnPositions or not columnPositions[5] then return end

	local left = columnPositions[5][1]
	local right = columnPositions[5][2]
	local bottom = top + height

	-- Draw the background
	dxDrawRectangle(left, top, right - left, height, COLOR_SCROLL_BG)

	-- Calculate scroll marker position
	local scrollHeight = 40
	local scrollTop = top + position * (height - scrollHeight)
	local scrollBottom = scrollTop + scrollHeight

	-- Draw scroll marker
	if scrollTop < scrollBottom then
		dxDrawRectangle(left, scrollTop, right - left, scrollBottom - scrollTop, COLOR_SCROLL_FG)
	end
end

--[[
* drawScoreboard
Draws the scoreboard contents.
--]]
drawScoreboard = function()
	-- Check that we got the list of players
	if not g_players then return end

	-- Draw main background
	dxDrawRectangle(SCOREBOARD_X, SCOREBOARD_Y, g_currentWidth, g_currentHeight, COLOR_BACKGROUND)

	-- Get the server information
	local serverName = getElementData(g_scoreboardDummy, "serverName") or "MTA server"
	local maxPlayers = getElementData(root, "server:Slots") or 1024
	serverName = tostring(serverName)
	maxPlayers = tonumber(maxPlayers)

	-- Draw header
	dxDrawRectangle(SCOREBOARD_X, SCOREBOARD_Y, g_currentWidth, SCOREBOARD_HEADER_HEIGHT, COLOR_HEADER)

	-- Draw accent line
	dxDrawRectangle(SCOREBOARD_X, SCOREBOARD_Y, g_currentWidth, 3, COLOR_ACCENT)

	-- Draw server name
	dxDrawText(serverName,
		SCOREBOARD_X + 15,
		SCOREBOARD_Y + 15,
		SCOREBOARD_X + g_currentWidth - 15,
		SCOREBOARD_Y + 40,
		COLOR_TEXT_PRIMARY,
		1.4, "default-bold",
		"left", "top")

	-- Draw player count
	local usagePercent = (#g_players / maxPlayers) * 100
	local playerCountText = #g_players .. "/" .. maxPlayers .. " players (" .. math.floor(usagePercent + 0.5) .. "%)"

	dxDrawText(playerCountText,
		SCOREBOARD_X + 15,
		SCOREBOARD_Y + 40,
		SCOREBOARD_X + g_currentWidth - 15,
		SCOREBOARD_Y + SCOREBOARD_HEADER_HEIGHT,
		COLOR_TEXT_SECONDARY,
		1.0, "default-bold",
		"left", "top")

	-- Draw player info section
	drawPlayerInfo()

	-- Calculate positions for player list
	local listTop = SCOREBOARD_Y + SCOREBOARD_HEADER_HEIGHT + SCOREBOARD_PLAYER_INFO_HEIGHT
	local listHeight = g_currentHeight - SCOREBOARD_HEADER_HEIGHT - SCOREBOARD_PLAYER_INFO_HEIGHT

	-- Draw player list header
	local headerTop = listTop + ROW_GAP
	drawRow("ID", "PLAYER NAME", "HOURS", "PING", {}, true, headerTop)

	-- Calculate how many players can fit in the list
	local headerSpace = ROW_HEIGHT + ROW_GAP * 2 -- Space taken by the header row
	local availableHeight = listHeight - headerSpace
	local rowUnitHeight = ROW_HEIGHT + ROW_GAP
	local maxVisiblePlayers = math.floor(availableHeight / rowUnitHeight)

	-- Calculate players to skip for pagination
	local playersToSkip = 0

	-- If we're on the last page, calculate exactly how many to skip to show a full page
	if g_currentPage == math.ceil(#g_players / maxVisiblePlayers) - 1 and #g_players > maxVisiblePlayers then
		-- For the last page, calculate to show exactly maxVisiblePlayers
		playersToSkip = #g_players - maxVisiblePlayers
	else
		-- For other pages, use normal calculation
		playersToSkip = g_currentPage * maxVisiblePlayers
	end

	-- Make sure we don't skip too many players
	local maxSkip = math.max(0, #g_players - maxVisiblePlayers)
	playersToSkip = math.min(playersToSkip, maxSkip)

	-- Safety check
	if playersToSkip < 0 then
		playersToSkip = 0
	end

	-- Draw player rows
	local rowTop = headerTop + ROW_HEIGHT + ROW_GAP
	local isStaffOnDuty = exports.global:isStaffOnDuty(localPlayer)

	-- Calculate exact bottom position for the last row
	local bottomPosition = SCOREBOARD_Y + g_currentHeight

	-- Count visible players
	local visibleCount = 0
	local rowsToShow = math.min(maxVisiblePlayers, #g_players - playersToSkip)

	-- Draw rows
	for i = 1, rowsToShow do
		local k = playersToSkip + i
		if k > #g_players then break end

		local player = g_players[k]
		local hasPerk, perkValue = exports.donators:hasPlayerPerk(player, 12)

		if not (hasPerk and tonumber(perkValue) == 1) or isStaffOnDuty then
			-- Get player data
			local playerID = getElementData(player, "playerid") or 0
			local playerUsername = ""
			if isStaffOnDuty then
				local uname = getElementData(player, 'account:username')
				playerUsername = uname and (" ("..uname..")") or ""
			end
			local playerName = getPlayerName(player):gsub("_", " ")..playerUsername
			local playerHours = getElementData(player, 'hoursplayed') or 0
			local playerPing = getPlayerPing(player)

			-- Get player color
			local r, g, b = 255, 255, 255
			if getElementData(player, "loggedin") ~= 1 then -- Not logged in
				r, g, b = 150, 150, 150
			elseif getElementData(player, "donation:nametag") and getElementData(player, "nametag_on") then
				r, g, b = 167, 133, 63
			elseif tonumber(getElementData(player, "admin_level")) == 10 then
				r, g, b = 255, 255, 255
			end

			-- Draw the row
			local colors = {tocolor(r, g, b, 255), tocolor(r, g, b, 255), tocolor(r, g, b, 255)}
			drawRow(playerID, playerName, playerHours, playerPing, colors, false, rowTop, visibleCount + 1)

			-- Update position for next row
			rowTop = rowTop + ROW_HEIGHT + ROW_GAP
			visibleCount = visibleCount + 1
		end
	end

	-- Add credit text at the bottom
	if #g_players > 0 then
		-- Calculate position for credit text
		local creditY = SCOREBOARD_Y + g_currentHeight - 20

		-- Draw credit text
		dxDrawText("Created By Reynikk",
			SCOREBOARD_X + 15,
			creditY,
			SCOREBOARD_X + g_currentWidth - 15,
			creditY + 30,
			COLOR_TEXT_TERTIARY,
			0.8, "default-bold",
			"right", "center")
	end

	-- Draw scrollbar if needed
	if #g_players > maxVisiblePlayers then
		local maxPlayersToSkip = math.max(0, #g_players - maxVisiblePlayers)
		local scrollPosition = maxPlayersToSkip > 0 and (playersToSkip / maxPlayersToSkip) or 0

		-- Calculate exact scrollbar position to match rows
		local scrollbarTop = headerTop + ROW_HEIGHT + ROW_GAP

		-- Calculate exact scrollbar height to match rows
		-- This ensures the scrollbar ends exactly where the last row ends
		local scrollbarHeight = (ROW_HEIGHT + ROW_GAP) * maxVisiblePlayers - ROW_GAP

		drawScrollBar(scrollbarTop, scrollPosition, scrollbarHeight)
	end
end

--[[
* isVisible
Returns wherever or not the scoreboard is visible
--]]
function isVisible()
	return g_isShowing
end
