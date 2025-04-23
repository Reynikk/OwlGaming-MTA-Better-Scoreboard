-- --
-- -- Test Dummy Players for Scoreboard
-- -- This file adds dummy players for testing the scoreboard 
-- --

-- local dummyPlayers = {}
-- local isTestActive = false

-- -- Function to create a dummy player element
-- local function createDummyPlayer(id, name, hours, ping, money, bank)
--     local dummy = createElement("playerDummy")

--     -- Set basic properties
--     setElementData(dummy, "playerid", id)
--     setElementData(dummy, "name", name)
--     setElementData(dummy, "hoursplayed", hours)
--     setElementData(dummy, "ping", ping)
--     setElementData(dummy, "loggedin", 1)
--     setElementData(dummy, "money", money)
--     setElementData(dummy, "bankmoney", bank)

--     -- Set random zone and city
--     local zones = {"Ganton", "Idlewood", "Jefferson", "Las Colinas", "Los Flores", "East Beach", "Willowfield", "Verona Beach", "Santa Maria Beach", "Marina"}
--     local cities = {"Los Santos", "San Fierro", "Las Venturas"}

--     setElementData(dummy, "zone", zones[math.random(1, #zones)])

--     -- Set color (random)
--     local r, g, b = math.random(100, 255), math.random(100, 255), math.random(100, 255)
--     setElementData(dummy, "color", {r, g, b})

--     return dummy
-- end

-- -- List of names for test players
-- local firstNames = {
--     "John", "Jane", "Mike", "Sarah", "David", "Emma", "James", "Olivia", "Daniel", "Sophia",
--     "William", "Emily", "Michael", "Ava", "Robert", "Mia", "Thomas", "Isabella", "Charles", "Charlotte",
--     "Joseph", "Amelia", "Christopher", "Harper", "Andrew", "Evelyn", "Matthew", "Abigail", "Joshua", "Elizabeth",
--     "Jack", "Sofia", "Ryan", "Ella", "Nicholas", "Grace", "Anthony", "Chloe", "Eric", "Victoria",
--     "Adam", "Lily", "Brian", "Hannah", "Kevin", "Zoe", "Jason", "Natalie", "Justin", "Addison"
-- }

-- local lastNames = {
--     "Doe", "Smith", "Johnson", "Williams", "Brown", "Davis", "Miller", "Wilson", "Taylor", "Anderson",
--     "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson", "Clark",
--     "Rodriguez", "Lewis", "Lee", "Walker", "Hall", "Allen", "Young", "Hernandez", "King", "Wright",
--     "Lopez", "Hill", "Scott", "Green", "Adams", "Baker", "Gonzalez", "Nelson", "Carter", "Mitchell",
--     "Perez", "Roberts", "Turner", "Phillips", "Campbell", "Parker", "Evans", "Edwards", "Collins", "Stewart"
-- }

-- -- Function to add test players
-- function addTestPlayers(commandName, count)
--     -- If already active, remove existing players first
--     if isTestActive then
--         removeTestPlayers()
--     end

--     -- Parse count parameter
--     local numPlayers = tonumber(count) or 10

--     -- Ensure at least 1 player
--     if numPlayers < 1 then numPlayers = 1 end

--     -- Warn if very large number requested
--     if numPlayers > 500 then
--         outputChatBox("Warning: Adding " .. numPlayers .. " players may affect performance")
--     end

--     -- For very large numbers, show progress
--     local showProgress = numPlayers > 100
--     local progressInterval = math.floor(numPlayers / 10)

--     -- Create dummy players with different properties
--     for i = 1, numPlayers do
--         -- Show progress for large numbers
--         if showProgress and i % progressInterval == 0 then
--             outputChatBox("Creating test players: " .. math.floor((i / numPlayers) * 100) .. "% complete")
--         end

--         -- Generate random properties
--         local id = i + 1

--         -- Generate unique name with number suffix if needed
--         local firstName = firstNames[math.random(1, #firstNames)]
--         local lastName = lastNames[math.random(1, #lastNames)]
--         local name = firstName .. "_" .. lastName

--         -- Add number suffix for large numbers of players to ensure uniqueness
--         if numPlayers > #firstNames * #lastNames / 2 then
--             name = name .. "_" .. i
--         end
--         local hours = math.random(10, 500)
--         local ping = math.random(30, 150)
--         local money = math.random(1000, 100000)
--         local bank = math.random(10000, 2000000)

--         -- Create and add the dummy player
--         table.insert(dummyPlayers, createDummyPlayer(id, name, hours, ping, money, bank))
--     end

--     -- Set flag to prevent adding duplicates
--     isTestActive = true

--     outputChatBox("Added " .. numPlayers .. " test players to the scoreboard")
-- end

-- -- Function to remove test players
-- function removeTestPlayers()
--     if not isTestActive then return end

--     -- Destroy all dummy elements
--     for _, player in ipairs(dummyPlayers) do
--         destroyElement(player)
--     end

--     -- Clear the table
--     dummyPlayers = {}

--     -- Reset flag
--     isTestActive = false

--     outputChatBox("Removed all test players from the scoreboard")
-- end

-- -- Add command handlers
-- addCommandHandler("addtestplayers", addTestPlayers)
-- addCommandHandler("removetestplayers", removeTestPlayers)
