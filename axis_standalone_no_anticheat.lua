if not game:IsLoaded() then
    game.Loaded:Wait()
end
if game.GameId ~= 6035872082 then
    error("Invalid Game Context")
end

pcall(function()
    loadstring([[ function LPH_NO_VIRTUALIZE(f) return f end; ]])()
end)

-- decrypted from locker

        -- [[ Caching & High Performance Engine Architecture ]]
        local task = task
        local playersService = game:GetService("Players")
        
        local lp = playersService.LocalPlayer
        while not lp do
            task.wait()
            lp = playersService.LocalPlayer
        end

        -- [[ Mobile Executor Compatibility Shield ]]
        local cloneref = cloneref or function(obj) return obj end
        local newcclosure = newcclosure or function(f) return f end

        if _G.axis_VoidHide_Loaded then 
            pcall(function() if _G.axis_Unload then _G.axis_Unload() end end)
        end
        _G.axis_VoidHide_Loaded = true

        local scriptActive = true
        local earlyConnections = {}
        local playerConnections = {}
        local origWalkspeedRestore = nil


        
        local function cleanPlayerConnections(plr)
            if playerConnections[plr] then
                for _, conn in ipairs(playerConnections[plr]) do
                    if conn.Connected then
                        conn:Disconnect()
                    end
                end
                playerConnections[plr] = nil
            end
        end

        local function cleanAllEarlyConnections()
            scriptActive = false
            for _, conn in ipairs(earlyConnections) do
                if conn.Connected then conn:Disconnect() end
            end
            for plr, conns in pairs(playerConnections) do
                for _, conn in ipairs(conns) do
                    if conn.Connected then conn:Disconnect() end
                end
            end
            table.clear(earlyConnections)
            table.clear(playerConnections)
            if origWalkspeedRestore then
                pcall(origWalkspeedRestore)
            end
        end
        
        -- [[ Cached Targeting & Character System ]]
        local SilentAim = {
            Target = nil,
            Circle = nil
        }
        local GetClosestTarget
        local Teammates = {}
        
        local CachedSilentAimTarget = nil
        local CachedNearestEnemyRoot = nil
        local CachedOrbitTarget = nil
        local CharacterCache = {}
        local PlayerDefenseStates = {}
        local SnowParticles = {}
        
        local currentVM = nil
        local cachedItemVisual = nil
        
        local function checkVM(child)
            if child:IsA("Model") and string.find(child.Name, lp.Name, 1, true) == 1 then
                currentVM = child
                cachedItemVisual = child:FindFirstChild("ItemVisual")
            end
        end
        
        task.spawn(function()
            local vp = workspace:WaitForChild("ViewModels", 10)
            local fp = vp and vp:WaitForChild("FirstPerson", 10)
            if fp then
                table.insert(earlyConnections, fp.ChildAdded:Connect(checkVM))
                table.insert(earlyConnections, fp.ChildRemoved:Connect(function(child)
                    if currentVM == child then
                        currentVM = nil
                        cachedItemVisual = nil
                    end
                end))
                for _, child in ipairs(fp:GetChildren()) do
                    checkVM(child)
                end
            end
        end)
        local function cleanSnow()
            if #SnowParticles > 0 then
                for i = 1, #SnowParticles do
                    pcall(function() SnowParticles[i]:Remove() end)
                end
                table.clear(SnowParticles)
            end
        end

        
        local function cacheCharacter(char)
            if not char then return end
            local cache = {
                HumanoidRootPart = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5),
                Humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5),
                Head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5),
                HitboxParts = {},
                Parts = {},
                Sounds = {}
            }
            local function checkPart(p)
                if p:IsA("BasePart") then
                    cache.Parts[p.Name] = p
                    if p.Name:find("Hitbox") or p.Name == "Head" then
                        table.insert(cache.HitboxParts, p)
                    end
                elseif p:IsA("Sound") then
                    table.insert(cache.Sounds, p)
                end
            end
            for _, p in ipairs(char:GetDescendants()) do
                checkPart(p)
            end
            local c1 = char.DescendantAdded:Connect(function(p)
                pcall(checkPart, p)
            end)
            local c2 = char.DescendantRemoving:Connect(function(p)
                if p:IsA("BasePart") then
                    if cache.Parts[p.Name] == p then
                        cache.Parts[p.Name] = nil
                    end
                    for i = #cache.HitboxParts, 1, -1 do
                        if cache.HitboxParts[i] == p then
                            table.remove(cache.HitboxParts, i)
                        end
                    end
                elseif p:IsA("Sound") then
                    for i = #cache.Sounds, 1, -1 do
                        if cache.Sounds[i] == p then
                            table.remove(cache.Sounds, i)
                        end
                    end
                end
            end)
            
            local plr = playersService:GetPlayerFromCharacter(char)
            if plr then
                playerConnections[plr] = playerConnections[plr] or {}
                table.insert(playerConnections[plr], c1)
                table.insert(playerConnections[plr], c2)
            else
                table.insert(earlyConnections, c1)
                table.insert(earlyConnections, c2)
            end

            CharacterCache[char] = cache
        end
        
        -- Hook existing and future players for hitbox caching
        playersService = game:GetService("Players")
        local function setupPlayerCaching(plr)
            playerConnections[plr] = playerConnections[plr] or {}
            local c1 = plr.CharacterAdded:Connect(function(char)
                pcall(cacheCharacter, char)
            end)
            table.insert(playerConnections[plr], c1)
            
            local c2 = plr.CharacterRemoving:Connect(function(char)
                CharacterCache[char] = nil
            end)
            table.insert(playerConnections[plr], c2)
            
            if plr.Character then
                pcall(cacheCharacter, plr.Character)
            end
        end
        for _, plr in ipairs(playersService:GetPlayers()) do
            setupPlayerCaching(plr)
        end
        table.insert(earlyConnections, playersService.PlayerAdded:Connect(setupPlayerCaching))
        table.insert(earlyConnections, playersService.PlayerRemoving:Connect(function(plr)
            cleanPlayerConnections(plr)
            PlayerDefenseStates[plr] = nil
        end))


        -- Background loop for Team Check (optimized lookup cache updated every 0.5 seconds)
        task.spawn(function()
            local playersService = game:GetService("Players")
            local localPlayer = playersService.LocalPlayer
            while scriptActive and task.wait(0.5) do
                local myTeam = localPlayer.Team
                local localChar = localPlayer.Character
                local myHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
                
                local newTeammates = {}
                for _, v in pairs(playersService:GetPlayers()) do
                    if v == localPlayer then continue end
                    local char = v.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hasLabel = hrp and (hrp:FindFirstChild("TeammateLabel") ~= nil)
                    local sameTeam = (myTeam ~= nil and v.Team ~= nil and v.Team == myTeam)
                    
                    if sameTeam or hasLabel then
                        newTeammates[v] = true
                    end
                end
                Teammates = newTeammates
            end
        end)

        local players = cloneref(game:GetService("Players"))
        local localPlayer = players.LocalPlayer

        local originalKick = nil
        pcall(function() originalKick = localPlayer.Kick end)


        local function setupUnlockAll()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local players = game:GetService("Players")
            local lp = players.LocalPlayer
            local playerScripts = lp:WaitForChild("PlayerScripts")
            local controllers = playerScripts and playerScripts:WaitForChild("Controllers")
            local HttpService = game:GetService("HttpService")
            
            --// [[ ReplicatedClass sliding speed detour (Commented out as requested) ]]
            --[[
            task.spawn(function()
                local modules = ReplicatedStorage:WaitForChild("Modules", 20)
                local ReplicatedClassModule = modules and modules:WaitForChild("ReplicatedClass", 20)
                if ReplicatedClassModule then
                    local success, ReplicatedClass = pcall(function() return require(ReplicatedClassModule) end)
                    if success and ReplicatedClass and ReplicatedClass.Get then
                        local oldGet = ReplicatedClass.Get
                        ReplicatedClass.Get = function(self, key, ...)
                            if key == "SlidingSpeedMax" and _G.Toggles and _G.Toggles.SlideBoostEnabled and _G.Toggles.SlideBoostEnabled.Value then
                                return _G.Options and _G.Options.SlideBoost and _G.Options.SlideBoost.Value or 3
                            end
                            return oldGet(self, key, ...)
                        end
                    end
                end
            end)
            ]]
            
            --// [[ Item Library & Cooldown Patching ]]
            local originalCooldowns = {}
            local originalDefaults = {}
            local originalItems = {}

            local function applyCooldownPatch(enabled)
                pcall(function()
                    local itemLibrary = nil
                    for _, module in pairs(ReplicatedStorage:GetDescendants()) do
                        if module:IsA("ModuleScript") and module.Name == "ItemLibrary" then
                            itemLibrary = module
                            break
                        end
                    end
                    if itemLibrary then
                        local success, lib = pcall(function() return require(itemLibrary) end)
                        if success and lib then
                            if enabled then
                                -- Save originals
                                if originalCooldowns.QUICK_ATTACK_COOLDOWN == nil then
                                    originalCooldowns.QUICK_ATTACK_COOLDOWN = lib.QUICK_ATTACK_COOLDOWN
                                end
                                if lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS and originalDefaults.Melee == nil then
                                    originalDefaults.Melee = lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Melee
                                    originalDefaults.Utility = lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Utility
                                end

                                -- Apply patch
                                lib.QUICK_ATTACK_COOLDOWN = 0
                                if lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS then
                                    lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Melee = 3
                                    lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Utility = 4
                                end
                                if lib.Items then
                                    for _, item in pairs(lib.Items) do
                                        if not originalItems[item] then
                                            originalItems[item] = {
                                                UseTime = item.UseTime,
                                                ReloadTime = item.ReloadTime,
                                                ShootRecoil = item.ShootRecoil,
                                                ShootSpread = item.ShootSpread,
                                                ShootSpreadConsistent = item.ShootSpreadConsistent,
                                                AimSpreadMultiplier = item.AimSpreadMultiplier
                                            }
                                        end
                                        if item.UseTime then item.UseTime = 0.1 end
                                        if item.ReloadTime then item.ReloadTime = 0.1 end
                                        if item.ShootRecoil then item.ShootRecoil = 0 end
                                        if item.ShootSpread then item.ShootSpread = 0 end
                                        if item.ShootSpreadConsistent ~= nil then item.ShootSpreadConsistent = true end
                                        if item.AimSpreadMultiplier then item.AimSpreadMultiplier = 0 end
                                    end
                                end
                            else
                                -- Restore originals
                                if originalCooldowns.QUICK_ATTACK_COOLDOWN ~= nil then
                                    lib.QUICK_ATTACK_COOLDOWN = originalCooldowns.QUICK_ATTACK_COOLDOWN
                                end
                                if lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS and originalDefaults.Melee ~= nil then
                                    lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Melee = originalDefaults.Melee
                                    lib.QUICK_ATTACK_ITEM_INDEX_DEFAULTS.Utility = originalDefaults.Utility
                                end
                                if lib.Items then
                                    for _, item in pairs(lib.Items) do
                                        local orig = originalItems[item]
                                        if orig then
                                            item.UseTime = orig.UseTime
                                            item.ReloadTime = orig.ReloadTime
                                            item.ShootRecoil = orig.ShootRecoil
                                            item.ShootSpread = orig.ShootSpread
                                            item.ShootSpreadConsistent = orig.ShootSpreadConsistent
                                            item.AimSpreadMultiplier = orig.AimSpreadMultiplier
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            _G.applyCooldownPatch = applyCooldownPatch

            task.spawn(function()
                repeat task.wait() until _G.Toggles and _G.Toggles.GlobalCooldownPatch
                applyCooldownPatch(_G.Toggles.GlobalCooldownPatch.Value)
            end)

            if not controllers then return end

            --// [[ Advanced Unlock All Module ]]
            local equipped, favorites = {}, {}
            local lastUsedWeapon = nil
            local currentEquippedWeapon = nil
            local constructingWeapon = nil
            local saveFile = "Symbol.gg/config.json"

            local EnumLibrary, CosmeticLibrary, ItemLibrary, DataController, CONSTANTS
            pcall(function()
                EnumLibrary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EnumLibrary"))
                if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
            end)
            pcall(function()
                CosmeticLibrary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CosmeticLibrary"))
            end)
            pcall(function()
                ItemLibrary = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemLibrary"))
            end)
            pcall(function()
                DataController = require(controllers:WaitForChild("PlayerDataController"))
            end)
            pcall(function()
                CONSTANTS = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CONSTANTS"))
            end)

            local originalBaseWalkspeed = CONSTANTS and CONSTANTS.BASE_WALKSPEED or 16
            origWalkspeedRestore = function()
                if CONSTANTS then
                    CONSTANTS.BASE_WALKSPEED = originalBaseWalkspeed
                end
            end
            task.spawn(function()
                while scriptActive and task.wait(0.1) do
                    pcall(function()
                        if CONSTANTS then
                            if _G.Toggles and _G.Toggles.CFrameSpeed and _G.Toggles.CFrameSpeed.Value then
                                CONSTANTS.BASE_WALKSPEED = originalBaseWalkspeed * (_G.Options and _G.Options.SpeedMult and _G.Options.SpeedMult.Value or 1.5)
                            else
                                CONSTANTS.BASE_WALKSPEED = originalBaseWalkspeed
                            end
                        end
                    end)
                end
            end)

            local function cloneCosmetic(name, cosmeticType, options)
                local base = CosmeticLibrary and CosmeticLibrary.Cosmetics and CosmeticLibrary.Cosmetics[name]
                if not base then return nil end
                local data = {}
                for key, value in pairs(base) do data[key] = value end
                data.Name = name
                data.Type = data.Type or cosmeticType
                data.Seed = data.Seed or math.random(1, 1000000)
                if EnumLibrary then
                    local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                    if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
                end
                if options then
                    if options.inverted ~= nil then data.Inverted = options.inverted end
                    if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
                end
                return data
            end

            local function saveConfig()
                if not writefile then return end
                pcall(function()
                    local config = {equipped = {}, favorites = favorites}
                    for weapon, cosmetics in pairs(equipped) do
                        config.equipped[weapon] = {}
                        for cosmeticType, cosmeticData in pairs(cosmetics) do
                            if cosmeticData and cosmeticData.Name then
                                config.equipped[weapon][cosmeticType] = {
                                    name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                                }
                            end
                        end
                    end
                    if not isfolder("Symbol.gg") then makefolder("Symbol.gg") end
                    writefile(saveFile, HttpService:JSONEncode(config))
                end)
            end

            local function loadConfig()
                if not readfile or not isfile or not isfile(saveFile) then return end
                pcall(function()
                    local config = HttpService:JSONDecode(readfile(saveFile))
                    if config.equipped then
                        for weapon, cosmetics in pairs(config.equipped) do
                            equipped[weapon] = {}
                            for cosmeticType, cosmeticData in pairs(cosmetics) do
                                local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                                if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                            end
                        end
                    end
                    favorites = config.favorites or {}
                end)
            end

            local function isCosmeticUnlockable(name)
                if not name or type(name) ~= "string" then return false end
                if name:find("MISSING_") then return false end
                return true
            end

            local viewingProfile = nil

            if CosmeticLibrary then
                local originalOwnsNormally = CosmeticLibrary.OwnsCosmeticNormally
                CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                        return true
                    end
                    return originalOwnsNormally and originalOwnsNormally(self, inventory, name, weapon, ...) or false
                end

                local originalOwnsUniversally = CosmeticLibrary.OwnsCosmeticUniversally
                CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                        return true
                    end
                    return originalOwnsUniversally and originalOwnsUniversally(self, inventory, name, weapon, ...) or false
                end

                local originalOwnsForWeapon = CosmeticLibrary.OwnsCosmeticForWeapon
                CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                        return true
                    end
                    return originalOwnsForWeapon and originalOwnsForWeapon(self, inventory, name, weapon, ...) or false
                end
                
                local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
                CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                        if name and tostring(name):find("MISSING_") then
                            return originalOwnsCosmetic and originalOwnsCosmetic(self, inventory, name, weapon, ...) or false
                        end
                        return true
                    end
                    return originalOwnsCosmetic and originalOwnsCosmetic(self, inventory, name, weapon, ...) or false
                end
            end

            if DataController then
                local originalGet = DataController.Get
                DataController.Get = function(self, key, ...)
                    local data = originalGet(self, key, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                        if key == "CosmeticInventory" then
                            local proxy = {}
                            if data then for k, v in pairs(data) do proxy[k] = v end end
                            return setmetatable(proxy, {__index = function(t, k)
                                if type(k) == "string" and k ~= "" and not k:find("MISSING_") then
                                    if CosmeticLibrary and CosmeticLibrary.Cosmetics and CosmeticLibrary.Cosmetics[k] then
                                        return true
                                    end
                                end
                            end})
                        end
                        if key == "FavoritedCosmetics" then
                            local result = data and table.clone(data) or {}
                            for weapon, favs in pairs(favorites) do
                                result[weapon] = result[weapon] or {}
                                for name, isFav in pairs(favs) do result[weapon][name] = isFav end
                            end
                            return result
                        end
                    end
                    return data
                end

                local originalGetWeaponData = DataController.GetWeaponData
                DataController.GetWeaponData = function(self, weaponName, ...)
                    local data = originalGetWeaponData(self, weaponName, ...)
                    if not data then return nil end
                    if not (Toggles.UnlockAll and Toggles.UnlockAll.Value) then return data end

                    local merged = {}
                    for key, value in pairs(data) do merged[key] = value end
                    merged.Name = weaponName
                    if equipped[weaponName] then
                        for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                            merged[cosmeticType] = cosmeticData
                        end
                    end
                    return merged
                end
            end

            --// Hooking Remotes for Custom Equipping
            local FighterController
            local classHooked = false
            local hookedFighters = setmetatable({}, {__mode = "k"})
            pcall(function() 
                FighterController = require(controllers:WaitForChild("FighterController", 10)) 
                _G.FighterController = FighterController
                
                if FighterController then
                    local function hookFighterClass(fighter)
                        if not fighter or hookedFighters[fighter] then return end
                        hookedFighters[fighter] = true
                        local getmt = getrawmetatable or getmetatable
                        local fmt = getmt(fighter)
                        
                        -- Fallback: Hook table directly if writeable (wrapped in pcall)
                        pcall(function()
                            local oldGet = fighter.Get
                            if oldGet then
                                fighter.Get = function(sf, key, ...)
                                    --[[ Commented out:
                                    if key == "SlidingSpeedMax" and _G.Toggles and _G.Toggles.SlideBoostEnabled and _G.Toggles.SlideBoostEnabled.Value then
                                        return _G.Options and _G.Options.SlideBoost and _G.Options.SlideBoost.Value or 3
                                    end
                                    ]]
                                    return oldGet(sf, key, ...)
                                end
                            end
                        end)
                        pcall(function()
                            local oldGetCameraSway = fighter.GetCameraSway
                            if oldGetCameraSway then
                                fighter.GetCameraSway = function(sf, ...)
                                    if _G.Toggles and _G.Toggles.WeaponModsAll and _G.Toggles.WeaponModsAll.Value then
                                        local orig = oldGetCameraSway(sf, ...)
                                        if typeof(orig) == "Vector3" then
                                            return Vector3.zero
                                        elseif typeof(orig) == "Vector2" then
                                            return Vector2.zero
                                        elseif typeof(orig) == "number" then
                                            return 0
                                        end
                                        return orig
                                    end
                                    return oldGetCameraSway(sf, ...)
                                end
                            end
                        end)

                        if fmt and typeof(fmt) == "table" then
                            local index = fmt.__index
                            if typeof(index) == "table" then
                                classHooked = true
                                -- Hook Get method on metatable index table
                                local oldGet = index.Get
                                if oldGet then
                                    index.Get = function(sf, key, ...)
                                        --[[ Commented out:
                                        if key == "SlidingSpeedMax" and _G.Toggles and _G.Toggles.SlideBoostEnabled and _G.Toggles.SlideBoostEnabled.Value then
                                            return _G.Options and _G.Options.SlideBoost and _G.Options.SlideBoost.Value or 3
                                        end
                                        ]]
                                        return oldGet(sf, key, ...)
                                    end
                                end

                                -- Hook GetCameraSway method on metatable index table
                                local oldGetCameraSway = index.GetCameraSway
                                if oldGetCameraSway then
                                    index.GetCameraSway = function(sf, ...)
                                        if _G.Toggles and _G.Toggles.WeaponModsAll and _G.Toggles.WeaponModsAll.Value then
                                            local orig = oldGetCameraSway(sf, ...)
                                            if typeof(orig) == "Vector3" then
                                                return Vector3.zero
                                            elseif typeof(orig) == "Vector2" then
                                                return Vector2.zero
                                            elseif typeof(orig) == "number" then
                                                return 0
                                            end
                                            return orig
                                        end
                                        return oldGetCameraSway(sf, ...)
                                    end
                                end
                            elseif typeof(index) == "function" then
                                classHooked = true
                                fmt.__index = function(sf, key, ...)
                                    if key == "Get" then
                                        return function(self_f, key_name, ...)
                                            --[[ Commented out:
                                            if key_name == "SlidingSpeedMax" and _G.Toggles and _G.Toggles.SlideBoostEnabled and _G.Toggles.SlideBoostEnabled.Value then
                                                return _G.Options and _G.Options.SlideBoost and _G.Options.SlideBoost.Value or 3
                                            end
                                            ]]
                                            local oldGet = index(self_f, "Get")
                                            if oldGet then
                                                return oldGet(self_f, key_name, ...)
                                            end
                                        end
                                    elseif key == "GetCameraSway" then
                                        return function(self_f, ...)
                                            if _G.Toggles and _G.Toggles.WeaponModsAll and _G.Toggles.WeaponModsAll.Value then
                                                local oldGetCameraSway = index(self_f, "GetCameraSway")
                                                if oldGetCameraSway then
                                                    local orig = oldGetCameraSway(self_f, ...)
                                                    if typeof(orig) == "Vector3" then
                                                        return Vector3.zero
                                                    elseif typeof(orig) == "Vector2" then
                                                        return Vector2.zero
                                                    elseif typeof(orig) == "number" then
                                                        return 0
                                                    end
                                                    return orig
                                                end
                                            end
                                            local oldGetCameraSway = index(self_f, "GetCameraSway")
                                            if oldGetCameraSway then
                                                return oldGetCameraSway(self_f, ...)
                                            end
                                        end
                                    end
                                    return index(sf, key, ...)
                                end
                            end
                        end
                    end

                    -- Hook existing local fighter immediately if it already exists
                    local localFighter = FighterController.LocalFighter or (FighterController.GetFighter and FighterController:GetFighter(lp))
                    if localFighter then
                        pcall(hookFighterClass, localFighter)
                    end

                    -- Periodically ensure the local fighter is hooked (e.g. after respawning!)
                    task.spawn(function()
                        while task.wait(0.5) do
                            pcall(function()
                                local lf = FighterController.LocalFighter or (FighterController.GetFighter and FighterController:GetFighter(lp))
                                if lf then
                                    pcall(hookFighterClass, lf)
                                end
                            end)
                        end
                    end)

                    local oldGetFighter = FighterController.GetFighter
                    if oldGetFighter then
                        FighterController.GetFighter = function(self, player, ...)
                            local fighter = oldGetFighter(self, player, ...)
                            if fighter then
                                pcall(hookFighterClass, fighter)
                            end
                            return fighter
                        end
                    end

                    local oldWaitForLocalFighter = FighterController.WaitForLocalFighter
                    if oldWaitForLocalFighter then
                        FighterController.WaitForLocalFighter = function(self, ...)
                            local fighter = oldWaitForLocalFighter(self, ...)
                            if fighter then
                                pcall(hookFighterClass, fighter)
                            end
                            return fighter
                        end
                    end
                end
            end)
            
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            local dataRemotes = remotes and remotes:WaitForChild("Data", 10)
            local equipRemote = dataRemotes and dataRemotes:WaitForChild("EquipCosmetic", 10)
            local favoriteRemote = dataRemotes and dataRemotes:WaitForChild("FavoriteCosmetic", 10)
            local replicationRemotes = remotes and remotes:WaitForChild("Replication", 10)
            local fighterRemotes = replicationRemotes and replicationRemotes:WaitForChild("Fighter", 10)
            local hitscanRequest = fighterRemotes and fighterRemotes:WaitForChild("HitscanRequest", 10)
            local projectileRequest = fighterRemotes and fighterRemotes:WaitForChild("ProjectileRequest", 10)
            local useItemRemote = fighterRemotes and fighterRemotes:WaitForChild("UseItem", 10)
            local outOfBoundsRemote = fighterRemotes and fighterRemotes:WaitForChild("OutOfBounds", 10)

            local oldFireServer
            pcall(function()
                if typeof(hookfunction) == "function" then
                    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
                        local args = table.pack(...)
                        
                        end

                        pcall(function()
                            local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                            
                            -- [[ Silent Aim: Hitscan ]]
                            if self == hitscanRequest and dynToggles and dynToggles.SilentAim and dynToggles.SilentAim.Value then
                                local target = SilentAim.Target or (typeof(GetClosestTarget) == "function" and GetClosestTarget())
                                if target and target.Character then
                                    local targetPart = target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("Head")
                                    if targetPart then
                                        local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[target]
                                        local targetPos = realCF and (realCF.Position + Vector3.new(0, 1.5, 0)) or targetPart.Position
                                        if typeof(args[1]) == "table" then
                                            args[1].Target = targetPart
                                            args[1].Position = targetPos
                                            if args[1].Origin then
                                                args[1].Direction = (targetPos - args[1].Origin).Unit
                                                if getgenv().CreateBulletTracer then
                                                    getgenv().CreateBulletTracer(args[1].Origin, targetPos)
                                                end
                                            end
                                            if getgenv().TriggerHitmarker then
                                                task.spawn(getgenv().TriggerHitmarker)
                                            end
                                        end
                                    end
                                end
                            elseif self == hitscanRequest and typeof(args[1]) == "table" and args[1].Origin then
                                local dest = args[1].Position
                                if not dest and args[1].Direction then
                                    dest = args[1].Origin + args[1].Direction * 1000
                                end
                                if dest and getgenv().CreateBulletTracer then
                                    getgenv().CreateBulletTracer(args[1].Origin, dest)
                                end
                                if args[1].Target then
                                    local targetChar = args[1].Target:FindFirstAncestorOfClass("Model")
                                    if targetChar and targetChar:FindFirstChildWhichIsA("Humanoid") and (lp and targetChar.Name ~= lp.Name) then
                                        if getgenv().TriggerHitmarker then
                                            task.spawn(getgenv().TriggerHitmarker)
                                        end
                                    end
                                end
                            end

                            -- [[ Silent Aim: Projectile ]]
                            if self == projectileRequest and dynToggles and dynToggles.SilentAim and dynToggles.SilentAim.Value then
                                local target = SilentAim.Target or (typeof(GetClosestTarget) == "function" and GetClosestTarget())
                                if target and target.Character then
                                    local targetPart = target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("Head")
                                    if targetPart then
                                        local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[target]
                                        local targetPos = realCF and (realCF.Position + Vector3.new(0, 1.5, 0)) or targetPart.Position
                                        if typeof(args[1]) == "table" and args[1].Origin then
                                            args[1].Direction = (targetPos - args[1].Origin).Unit
                                            if getgenv().CreateBulletTracer then
                                                getgenv().CreateBulletTracer(args[1].Origin, targetPos)
                                            end
                                            if getgenv().TriggerHitmarker then
                                                task.spawn(getgenv().TriggerHitmarker)
                                            end
                                        end
                                    end
                                end
                            elseif self == projectileRequest and typeof(args[1]) == "table" and args[1].Origin then
                                local dest = args[1].Origin + (args[1].Direction or Vector3.new(0, -1, 0)) * 500
                                if getgenv().CreateBulletTracer then
                                    getgenv().CreateBulletTracer(args[1].Origin, dest)
                                end
                            end
                        end)
                        
                        return oldFireServer(self, table.unpack(args, 1, args.n))
                    end))
                end
            end)

            if equipRemote or favoriteRemote then
                local oldNamecall
                local namecallHookFn = function(self, ...)
                    local method = getnamecallmethod()

                    if method == "FireServer" then
                        local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                        if dynToggles and dynToggles.UnlockAll and dynToggles.UnlockAll.Value then
                            local args = {...}

                            if useItemRemote and self == useItemRemote then
                                pcall(function()
                                    local objectID = args[1]
                                    if FighterController then
                                        local fighter = FighterController:GetFighter(lp)
                                        if fighter and fighter.Items then
                                            for _, item in pairs(fighter.Items) do
                                                if item:Get("ObjectID") == objectID then
                                                    lastUsedWeapon = item.Name
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end)
                            end

                            if self == equipRemote then
                                local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}

                                equipped[weaponName] = equipped[weaponName] or {}
                                if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                    equipped[weaponName][cosmeticType] = nil
                                    if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                                else
                                    local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                    if not cloned then
                                        -- Fallback: build minimal cosmetic data if not in CosmeticLibrary.Cosmetics
                                        cloned = {Name = cosmeticName, Type = cosmeticType, Seed = math.random(1, 1000000)}
                                        if options.IsInverted ~= nil then cloned.Inverted = options.IsInverted end
                                        if EnumLibrary then
                                            local ok, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, cosmeticName)
                                            if ok and enumId then cloned.Enum = enumId cloned.ObjectID = enumId end
                                        end
                                    end
                                    equipped[weaponName][cosmeticType] = cloned
                                end
                                task.defer(function()
                                    pcall(function() if DataController then DataController.CurrentData:Replicate("WeaponInventory") end end)
                                    task.wait(0.2)
                                    saveConfig()
                                end)
                                return
                            end

                            if self == favoriteRemote then
                                favorites[args[1]] = favorites[args[1]] or {}
                                favorites[args[1]][args[2]] = args[3] or nil
                                saveConfig()
                                task.spawn(function() pcall(function() if DataController then DataController.CurrentData:Replicate("FavoritedCosmetics") end end) end)
                                return
                            end
                        end
                    end
                    return oldNamecall(self, ...)
                end

                local hookOk, hookErr = pcall(function()
                    oldNamecall = hookmetamethod(game, "__namecall", namecallHookFn)
                end)
                if not hookOk then
                    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(namecallHookFn))
                end
            end

            -- Zero-overhead Active Weapon Mod Cache
            getgenv().localWeaponInstances = getgenv().localWeaponInstances or setmetatable({}, { __mode = "k" })
            getgenv().originalWeaponAttributes = getgenv().originalWeaponAttributes or setmetatable({}, { __mode = "k" })
            
            local function toggleTableAttribute(attribute, value)
                pcall(function()
                    for _, gcVal in pairs(getgc(true)) do
                        if type(gcVal) == "table" and rawget(gcVal, attribute) ~= nil then
                            if not originalWeaponAttributes[gcVal] then
                                originalWeaponAttributes[gcVal] = {}
                            end
                            if originalWeaponAttributes[gcVal][attribute] == nil then
                                originalWeaponAttributes[gcVal][attribute] = rawget(gcVal, attribute)
                            end
                            gcVal[attribute] = value
                        end
                    end
                end)
            end
            getgenv().toggleTableAttribute = toggleTableAttribute

            local function restoreTableAttribute(attribute)
                pcall(function()
                    for gcVal, orig in pairs(originalWeaponAttributes) do
                        if type(gcVal) == "table" and orig[attribute] ~= nil then
                            gcVal[attribute] = orig[attribute]
                        end
                    end
                end)
            end
            getgenv().restoreTableAttribute = restoreTableAttribute

            getgenv().applyWeaponInstanceMods = function(item, enabled) end

            -- ViewModel & Finishers Hooks
            local ClientItem
            pcall(function() 
                local modules = playerScripts:WaitForChild("Modules")
                local crc = modules:WaitForChild("ClientReplicatedClasses")
                local cf = crc:WaitForChild("ClientFighter")
                local ci = cf:WaitForChild("ClientItem")
                ClientItem = require(ci)
            end)
            if ClientItem then
                if ClientItem._CreateViewModel then
                    local originalCreateViewModel = ClientItem._CreateViewModel
                    ClientItem._CreateViewModel = function(self, viewmodelRef)
                        local weaponName = self.Name
                        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                        constructingWeapon = (weaponPlayer == lp) and weaponName or nil    
                        if weaponPlayer == lp then
                            localWeaponInstances[self] = true
                            lastUsedWeapon = weaponName
                            currentEquippedWeapon = weaponName
                            _G.ActiveWeaponName = weaponName
                            if Toggles.WeaponModsAll and Toggles.WeaponModsAll.Value then
                                applyWeaponInstanceMods(self, true)
                            end
                        end
                        if (Toggles.UnlockAll and Toggles.UnlockAll.Value) and weaponPlayer == lp and equipped[weaponName] and viewmodelRef then
                            local cosmetics = equipped[weaponName]
                            local dataKey = self:ToEnum("Data")
                            local dataTable = viewmodelRef[dataKey] or viewmodelRef.Data
                            
                            if dataTable then
                                if cosmetics.Skin then
                                    local skinKey = self:ToEnum("Skin")
                                    local nameKey = self:ToEnum("Name")
                                    dataTable[skinKey] = cosmetics.Skin
                                    dataTable[nameKey] = cosmetics.Skin.Name
                                end
                                if cosmetics.Wrap then
                                    local wrapKey = self:ToEnum("Wrap")
                                    dataTable[wrapKey] = cosmetics.Wrap
                                end
                            end
                        end
                        local result = originalCreateViewModel(self, viewmodelRef)
                        constructingWeapon = nil
                        return result
                    end
                end
                
                if ClientItem.Equip then
                    local originalEquip = ClientItem.Equip
                    ClientItem.Equip = function(self, ...)
                        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                        if weaponPlayer == lp then
                            localWeaponInstances[self] = true
                            lastUsedWeapon = self.Name
                            currentEquippedWeapon = self.Name
                            _G.ActiveWeaponName = self.Name
                            if Toggles.WeaponModsAll and Toggles.WeaponModsAll.Value then
                                applyWeaponInstanceMods(self, true)
                            end
                        end
                        return originalEquip(self, ...)
                    end
                end
                
            end

            -- ClientViewModel Hooks for Charms and Wraps
            pcall(function()
                local modules = playerScripts:WaitForChild("Modules")
                local crc = modules:WaitForChild("ClientReplicatedClasses")
                local cf = crc:WaitForChild("ClientFighter")
                local ci = cf:WaitForChild("ClientItem")
                local viewModelModule = ci:WaitForChild("ClientViewModel")
                local ClientViewModel = require(viewModelModule)
                
                if ClientViewModel.GetCharm then
                    local originalGetCharmFunc = ClientViewModel.GetCharm
                    ClientViewModel.GetCharm = function(self, ...)
                        if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                            local weaponName = self.ClientItem and self.ClientItem.Name
                            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                            if weaponName and weaponPlayer == lp and equipped[weaponName] and equipped[weaponName].Charm then
                                return equipped[weaponName].Charm
                            end
                        end
                        return originalGetCharmFunc(self, ...)
                    end
                end
                
                if ClientViewModel.GetWrap then
                    local originalGetWrapFunc = ClientViewModel.GetWrap
                    ClientViewModel.GetWrap = function(self, ...)
                        if Toggles.UnlockAll and Toggles.UnlockAll.Value then
                            local weaponName = self.ClientItem and self.ClientItem.Name
                            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                            if weaponName and weaponPlayer == lp and equipped[weaponName] and equipped[weaponName].Wrap then
                                return equipped[weaponName].Wrap
                            end
                        end
                        return originalGetWrapFunc(self, ...)
                    end
                end
                
                local originalNew = ClientViewModel.new
                ClientViewModel.new = function(replicatedData, clientItem, ...)
                    local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                    local weaponName = constructingWeapon or clientItem.Name
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value and weaponPlayer == lp and equipped[weaponName] then
                        pcall(function()
                            local ReplicatedClass = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ReplicatedClass"))
                            local dataKey = ReplicatedClass:ToEnum("Data")
                            replicatedData[dataKey] = replicatedData[dataKey] or {}
                            local cosmetics = equipped[weaponName]
                            if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
                            if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
                            if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
                        end)
                    end
                    local result = originalNew(replicatedData, clientItem, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value and weaponPlayer == lp and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
                        pcall(function()
                            result:_UpdateWrap()
                            task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
                        end)
                    end
                    return result
                end
            end)

            -- EmoteController Hook for Unlocking Dances/Emotes
            pcall(function()
                local EmoteController = require(controllers:WaitForChild("EmoteController"))
                if EmoteController and EmoteController.GetEmotes then
                    local originalGetEmotes = EmoteController.GetEmotes
                    EmoteController.GetEmotes = function(self, ...)
                        local emotes = originalGetEmotes(self, ...)
                        if Toggles.UnlockAll and Toggles.UnlockAll.Value and CosmeticLibrary and CosmeticLibrary.Cosmetics then
                            for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
                                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then
                                    if not emotes[name] then
                                        emotes[name] = {
                                            Name = name,
                                            Type = cosmetic.Type,
                                            ObjectID = cosmetic.ObjectID,
                                            Enum = cosmetic.Enum
                                        }
                                    end
                                end
                            end
                        end
                        return emotes
                    end
                end
            end)

            -- ItemLibrary Viewmodel Image Override Hook
            if ItemLibrary then
                local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
                ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes, ...)
                    if Toggles.UnlockAll and Toggles.UnlockAll.Value and weaponData then
                        local weaponName = weaponData.Name
                        local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == lp and equipped[weaponName] and equipped[weaponName].Skin)
                        if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
                            local skinInfo = self.ViewModels and self.ViewModels[equipped[weaponName].Skin.Name]
                            if skinInfo then
                                return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image
                            end
                        end
                    end
                    return originalGetViewModelImage(self, weaponData, highRes, ...)
                end
            end

            -- Profile Fetch Tracker Hook (For correct skin render in profile menu)
            pcall(function()
                local ViewProfile = require(playerScripts:WaitForChild("Modules"):WaitForChild("Pages"):WaitForChild("ViewProfile"))
                if ViewProfile and ViewProfile.Fetch then
                    local originalFetch = ViewProfile.Fetch
                    ViewProfile.Fetch = function(self, targetPlayer, ...)
                        viewingProfile = targetPlayer
                        return originalFetch(self, targetPlayer, ...)
                    end
                end
            end)

            local ClientEntity
            pcall(function() 
                local modules = playerScripts:WaitForChild("Modules")
                local crc = modules:WaitForChild("ClientReplicatedClasses")
                local ce = crc:WaitForChild("ClientEntity")
                ClientEntity = require(ce)
            end)
            if ClientEntity and ClientEntity.ReplicateFromServer then
                local originalReplicateFromServer = ClientEntity.ReplicateFromServer
                ClientEntity.ReplicateFromServer = function(self, action, ...)
                    if action == "FinisherEffect" then
                        local args = table.pack(...)
                        local killerName = args[3]            
                        local decodedKiller = killerName
                        if type(killerName) == "userdata" and EnumLibrary and EnumLibrary.FromEnum then
                            local ok, decoded = pcall(EnumLibrary.FromEnum, EnumLibrary, killerName)
                            if ok and decoded then decodedKiller = decoded end
                        end            
                        local isOurKill = tostring(decodedKiller) == lp.Name or tostring(decodedKiller):lower() == lp.Name:lower()            
                        if (Toggles.UnlockAll and Toggles.UnlockAll.Value) and isOurKill then
                            local finisherData = nil
                            if lastUsedWeapon and equipped[lastUsedWeapon] and equipped[lastUsedWeapon].Finisher then
                                finisherData = equipped[lastUsedWeapon].Finisher
                            elseif currentEquippedWeapon and equipped[currentEquippedWeapon] and equipped[currentEquippedWeapon].Finisher then
                                finisherData = equipped[currentEquippedWeapon].Finisher
                            else
                                for weaponName, cosmetics in pairs(equipped) do
                                    if cosmetics.Finisher then
                                        finisherData = cosmetics.Finisher
                                        break
                                    end
                                end
                            end
                            if finisherData then
                                local finisherEnum = finisherData.Enum                
                                if not finisherEnum and EnumLibrary then
                                    local ok, result = pcall(EnumLibrary.ToEnum, EnumLibrary, finisherData.Name)
                                    if ok and result then finisherEnum = result end
                                end                
                                if finisherEnum then
                                    args[1] = finisherEnum
                                    return originalReplicateFromServer(self, action, table.unpack(args, 1, args.n))
                                end
                            end
                        end
                        return originalReplicateFromServer(self, action, table.unpack(args, 1, args.n))
                    end        
                    return originalReplicateFromServer(self, action, ...)
                end
            end

            loadConfig()

        end
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            pcall(setupUnlockAll)
        end)

        -- Isolated Dynamic Weapon Mods Handler (Replication-Safe)
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            lp = playersService.LocalPlayer
            local playerScripts = lp:WaitForChild("PlayerScripts", 60)
            if not playerScripts then return end
            
            local modules = playerScripts:WaitForChild("Modules", 60)
            local crc = modules and modules:WaitForChild("ClientReplicatedClasses", 60)
            local cf = crc and crc:WaitForChild("ClientFighter", 60)
            local ci = cf and cf:WaitForChild("ClientItem", 60)
            
            if ci then
                local success, ClientItem = pcall(require, ci)
                if success and ClientItem and ClientItem.Input then
                    local oldInput
                    oldInput = hookfunction(ClientItem.Input, function(...)
                        local args = {...}
                        local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                        if dynToggles and dynToggles.WeaponModsAll and dynToggles.WeaponModsAll.Value then
                            pcall(function()
                                if type(args[1]) == "table" and args[1].Info then
                                    args[1].Info.ShootRecoil = 0
                                    args[1].Info.ShootSpread = 0
                                    args[1].Info.ProjectileSpeed = 99999999
                                    args[1].Info.ShootCooldown = 0
                                    args[1].Info.QuickShotCooldown = 0
                                end
                            end)
                        end
                        return oldInput(...)
                    end)
                end
            end
        end)


        -- mobile compatibility layer
        local function getHttpGet()
            local get = game.HttpGet
            if get then
                return function(url) return get(game, url) end
            end
            if request then
                return function(url) return request({Url = url, Method = "GET"}).Body end
            end
            return function() return "" end
        end
        local httpGet = getHttpGet()

        local function safeDrawingNew(type)
            local ok, res = pcall(Drawing.new, type)
            if ok then return res end
            return { Remove = function() end, Destroy = function() end, Visible = false }
        end

        local drawFont = (Drawing and Drawing.Fonts and (Drawing.Fonts.UI or Drawing.Fonts.System)) or 0

        -- Save script source for Auto-Execute
        pcall(function()
            if not getgenv().axis_src then
                local possible = {"abc (2).lua", "abc.lua", "if _G.lua"}
                for _, f in ipairs(possible) do
                    if isfile and isfile(f) then
                        getgenv().axis_src = readfile(f)
                        break
                    end
                end
            end
        end)

        -- Load Guard
        if not game:IsLoaded() then game.Loaded:Wait() end
        lp = playersService.LocalPlayer

        -- Handicap Mode Initializer (Moved to top for UI access)
        local function ApplyHandicap(enabled)
            pcall(function()
                local controllers = lp.PlayerScripts:FindFirstChild("Controllers")
                if controllers then
                    local debugCtrl = require(controllers:WaitForChild("DebugController", 2))
                    if debugCtrl and debugCtrl.SetHandicapsEnabled then
                        debugCtrl:SetHandicapsEnabled(enabled)
                    end
                end
            end)
        end

        local rs = game:GetService("RunService")
        local uis = game:GetService("UserInputService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Target Prioritization API
        getgenv().PrioritizedPlayers = getgenv().PrioritizedPlayers or {}
        getgenv().IsPrioritized = function(player)
            if not player then return false end
            return getgenv().PrioritizedPlayers[player.UserId] ~= nil
        end

        -- Global Bullet Tracer Drawer
        getgenv().CreateBulletTracer = function(from, to)
            -- Always stamp shot time so Full Auto can detect auto weapons
            getgenv().lastShotTick = tick()
            if not Toggles.BulletTracers or not Toggles.BulletTracers.Value then return end
            
            pcall(function()
                local tracerFolder = workspace:FindFirstChild("AxisTracers")
                if not tracerFolder then
                    tracerFolder = Instance.new("Folder", workspace)
                    tracerFolder.Name = "AxisTracers"
                end

                local dist = (to - from).Magnitude
                if dist > 2000 then return end -- Avoid super long tracers from lag

                local part = Instance.new("Part")
                part.Name = "Tracer"
                part.Anchored = true
                part.CanCollide = false
                part.CastShadow = false
                part.Material = Enum.Material.Neon
                part.Color = Options.BulletTracerCol.Value
                part.Size = Vector3.new(0.08, 0.08, dist)
                part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
                part.Parent = tracerFolder

                -- Smoothly fade out the tracer
                task.spawn(function()
                    local duration = 1.0
                    local steps = 20
                    local delayTime = duration / steps
                    for i = 1, steps do
                        task.wait(delayTime)
                        if part and part.Parent then
                            part.Transparency = i / steps
                        else
                            break
                        end
                    end
                    if part and part.Parent then
                        part:Destroy()
                    end
                end)
            end)
        end

        -- 3D Weather System State
        local Weather = { Part = nil, Rain = nil, Snow = nil }

        -- ============================================================
        -- CUSTOM UI LIBRARY (Self-Contained, No Network Dependencies)
        -- Compatible with LinoriaLib API: Toggles/Options/OnChanged
        -- ============================================================

        getgenv().Toggles = setmetatable({}, {
            __index = function(t, k)
                return { Value = false, OnChanged = function() end, SetValue = function() end }
            end
        })
        getgenv().Options = setmetatable({}, {
            __index = function(t, k)
                return { Value = 0, OnChanged = function() end, SetValue = function() end, SetValues = function() end }
            end
        })
        _G.Toggles = getgenv().Toggles
        _G.Options = getgenv().Options
        -- local Toggles
        -- local Options
        local Library

        -- ── Services ──────────────────────────────────────────────
        -- local playersService
        local RunService   = game:GetService("RunService")
        local UserInput    = game:GetService("UserInputService")
        local TweenService = game:GetService("TweenService")
        -- local lp

        -- ── Theme ─────────────────────────────────────────────────
        local Theme = {
            BG         = Color3.fromRGB(15,  15,  15),
            Header     = Color3.fromRGB(15,  15,  15),
            Accent     = Color3.fromRGB(180, 55, 255), -- Slider Purple
            AccentDark = Color3.fromRGB(180, 55, 255), -- FLAT PURPLE (ZERO PINK)
            Tab        = Color3.fromRGB(15,  15,  15),
            TabSel     = Color3.fromRGB(15,  15,  20),
            TabHover   = Color3.fromRGB(20,  20,  25),
            Section    = Color3.fromRGB(12,  12,  12),
            Border     = Color3.fromRGB(24,  24,  24),
            BorderAccent = Color3.fromRGB(35, 35, 35),
            Text       = Color3.fromRGB(220, 220, 220),
            TextDim    = Color3.fromRGB(120, 120, 120),
            Toggle_On  = Color3.fromRGB(180, 55, 255),
            Toggle_Off = Color3.fromRGB(30,  30,  30),
            Input      = Color3.fromRGB(12,  12,  12),
            Slider     = Color3.fromRGB(180, 55, 255),
            SliderBG   = Color3.fromRGB(25,  25,  25),
        }

        -- ── Helpers ────────────────────────────────────────────────
        local function new(cls, props, parent)
            local obj = Instance.new(cls)
            for k, v in pairs(props or {}) do obj[k] = v end
            if parent then obj.Parent = parent end
            return obj
        end

        local function corner(r, parent)
            return new("UICorner", {CornerRadius = UDim.new(0, r)}, parent)
        end

        local function stroke(color, thickness, parent)
            return new("UIStroke", {Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
        end

        local function tween(obj, t, props)
            TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
        end

        local function makeDraggable(frame, handle)
            handle = handle or frame
            local dragToggle = nil
            local dragStart = nil
            local startPos = nil

            handle.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and input.UserInputState == Enum.UserInputState.Begin then
                    dragToggle = true
                    dragStart = input.Position
                    startPos = frame.Position
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragToggle = false
                        end
                    end)
                end
            end)

            Library:Track(UserInput.InputChanged:Connect(function(input)
                if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end))
        end

        local function makeResizable(frame, handle, minWidth, minHeight, onResize)
            handle = handle or frame
            minWidth = minWidth or 300
            minHeight = minHeight or 250
            
            local dragToggle = nil
            local dragStart = nil
            local startSize = nil

            handle.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and input.UserInputState == Enum.UserInputState.Begin then
                    dragToggle = true
                    dragStart = input.Position
                    startSize = frame.Size
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragToggle = false
                        end
                    end)
                end
            end)

            Library:Track(UserInput.InputChanged:Connect(function(input)
                if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    local newWidth = math.max(minWidth, startSize.X.Offset + delta.X)
                    local newHeight = math.max(minHeight, startSize.Y.Offset + delta.Y)
                    frame.Size = UDim2.new(0, newWidth, 0, newHeight)
                    if onResize then
                        pcall(onResize, newWidth, newHeight)
                    end
                end
            end))
        end

        -- ── Root ScreenGui ─────────────────────────────────────────
        local uiParent
        pcall(function()
            if gethui then uiParent = gethui() end
        end)
        if not uiParent then
            pcall(function()
                uiParent = game:GetService("CoreGui")
            end)
        end
        if not uiParent then
            pcall(function()
                uiParent = lp:WaitForChild("PlayerGui", 10)
            end)
        end
        
        local ScreenRoot = new("ScreenGui", {
            Name = "AxisCustomUI",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999
        }, uiParent)

        -- ── File System Helpers ────────────────────────────────────
        local Paths = {}
        Paths.Root = "axislol\\"
        Paths.Config = Paths.Root .. "configs\\"
        Paths.Theme = Paths.Root .. "themes\\"
        Paths.Script = Paths.Root .. "scripts\\"
        Paths.Asset = Paths.Root .. "assets\\"

        local function ensureFolders()
            if not isfolder then return end
            for _, path in ipairs({Paths.Root, Paths.Config, Paths.Theme, Paths.Script, Paths.Asset}) do
                if not isfolder(path) then makefolder(path) end
            end
        end
        ensureFolders()

        local function write(path, content) if writefile then writefile(path, content) end end
        local function read(path) if isfile and isfile(path) then return readfile(path) end return nil end
        local function list(path) if listfiles then return listfiles(path) end return {} end
        local list_dir = list

        -- ── Library object ─────────────────────────────────────────
        Library = {
            Toggles = Toggles,
            Options  = Options,
            ToggleKeybind = nil,
            _unloadFns = {},
            _connections = {},
            Running = true,
        }
        function Library:Track(conn) table.insert(self._connections, conn); return conn end
        function Library:OnUnload(fn) table.insert(self._unloadFns, fn) end
        Library:OnUnload(cleanSnow)
        Library:OnUnload(cleanAllEarlyConnections)
        function Library:Toggle()
            local Win = Library.Window
            if not Win then return end
            Win.Visible = not Win.Visible
            if CustomCursor then CustomCursor.Visible = Win.Visible end
            if not Win.Visible then
                uis.MouseIconEnabled = true
                uis.MouseBehavior = Enum.MouseBehavior.Default
            else
                uis.MouseIconEnabled = false
            end
        end

        function Library:Unload()
            self.Running = false
            uis.MouseIconEnabled = true
            uis.MouseBehavior = Enum.MouseBehavior.Default
            for _, fn in ipairs(self._unloadFns) do pcall(fn) end
            for _, conn in ipairs(self._connections) do pcall(function() conn:Disconnect() end) end
            rs:UnbindFromRenderStep("tp_snapback")
            rs:UnbindFromRenderStep("orbit_v4_pos")
            rs:UnbindFromRenderStep("axis_crosshair")
            rs:UnbindFromRenderStep("ResolutionOverride")
            _G.axis_VoidHide_Loaded = nil
            ScreenRoot:Destroy()
        end
        _G.axis_Unload = function() Library:Unload() end

        -- ── Watermark Bar ──────────────────────────────────────────
        local WatermarkBar = new("Frame", {
            Name = "Watermark",
            BackgroundColor3 = Theme.BG,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 200, 0, 22),
            ZIndex = 10,
        }, ScreenRoot)
        stroke(Theme.Border, 1, WatermarkBar)

        local WatermarkAccent = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 11,
        }, WatermarkBar)
        new("UIGradient", {
            Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
            Rotation = 90
        }, WatermarkAccent)

        local WatermarkLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Text = "axis.lol | discord.gg/at9m",
            TextColor3 = Theme.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        }, WatermarkBar)

        WatermarkLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
            WatermarkBar.Size = UDim2.new(0, WatermarkLabel.TextBounds.X + 16, 0, 22)
        end)

        -- ── Target HUD (Orbit) ──────────────────────────────────
        -- ── Target HUD (Orbit) ──────────────────────────────────
        local TargetHUD = new("Frame", {
            Name = "TargetHUD",
            BackgroundColor3 = Theme.BG,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 50, 0.5, 50),
            Size = UDim2.new(0, 180, 0, 75),
            ZIndex = 10,
            Visible = false,
        }, ScreenRoot)
        stroke(Theme.Border, 1, TargetHUD)

        local TargetHeader = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
        }, TargetHUD)

        local TargetLineContainer = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 9),
            Size = UDim2.new(1, -16, 0, 1),
            ZIndex = 11,
        }, TargetHeader)

        local TargetLeftLine = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 10, 1, 0),
        }, TargetLineContainer)
        new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 90}, TargetLeftLine)

        local TargetTitleLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, -8),
            Size = UDim2.new(0, 0, 0, 16),
            Text = "TARGET HUD",
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 12,
        }, TargetLineContainer)

        local TargetRightLine = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
        }, TargetLineContainer)
        new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 90}, TargetRightLine)
        
        TargetTitleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            TargetRightLine.Position = UDim2.new(0, TargetTitleLabel.AbsoluteSize.X + 18, 0, 0)
            TargetRightLine.Size = UDim2.new(1, -(TargetTitleLabel.AbsoluteSize.X + 18), 1, 0)
        end)

        local TargetName = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 24),
            Size = UDim2.new(1, -16, 0, 16),
            Text = "Name: None",
            TextColor3 = Theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        }, TargetHUD)

        local TargetWeapon = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 40),
            Size = UDim2.new(1, -16, 0, 16),
            Text = "Weapon: None",
            TextColor3 = Theme.TextDim,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        }, TargetHUD)

        local TargetHPBackground = new("Frame", {
            BackgroundColor3 = Theme.SliderBG,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 60),
            Size = UDim2.new(1, -16, 0, 4), -- Minimalist thin bar
            ZIndex = 11,
        }, TargetHUD)

        local HPFill = new("Frame", {
            BackgroundColor3 = Color3.fromRGB(0, 255, 100),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 12,
        }, TargetHPBackground)
        new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 90}, HPFill)

        local HPText = new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "100%",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            ZIndex = 13,
        }, HPBackground)

        -- ── Keybind HUD ──────────────────────────────────────────
        local KeybindHUD = new("Frame", {
            Name = "KeybindHUD",
            BackgroundColor3 = Theme.BG,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0.4, 0),
            Size = UDim2.new(0, 160, 0, 20),
            ZIndex = 11,
            Visible = true,
            AutomaticSize = Enum.AutomaticSize.Y,
        }, ScreenRoot)
        stroke(Theme.Border, 1, KeybindHUD)
        makeDraggable(KeybindHUD, KeybindHUD)

        local KeyHeader = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
        }, KeybindHUD)

        local KeyLineContainer = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 9),
            Size = UDim2.new(1, -16, 0, 1),
            ZIndex = 12,
        }, KeyHeader)

        local KeyLeftLine = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 10, 1, 0),
        }, KeyLineContainer)
        new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 90}, KeyLeftLine)

        local KeyTitleLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, -8),
            Size = UDim2.new(0, 0, 0, 16),
            Text = "KEYBINDS",
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 13,
        }, KeyLineContainer)

        local KeyRightLine = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
        }, KeyLineContainer)
        new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 90}, KeyRightLine)
        
        KeyTitleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            KeyRightLine.Position = UDim2.new(0, KeyTitleLabel.AbsoluteSize.X + 18, 0, 0)
            KeyRightLine.Size = UDim2.new(1, -(KeyTitleLabel.AbsoluteSize.X + 18), 1, 0)
        end)

        local KeyListContent = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, KeybindHUD)
        new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, KeyListContent)
        new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4)}, KeyListContent)

        Library.KeybindHUD = KeybindHUD -- export
        local CustomCursor = new("ImageLabel", {
            Name = "CustomCursor",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 24, 0, 24),
            Image = "rbxassetid://11419713342", -- Sleek sharp arrow
            ZIndex = 1000,
            Visible = false,
        }, ScreenRoot)

        Library:Track(rs.RenderStepped:Connect(function()
            if not Library.Running then return end
            if CustomCursor and pcall(function() return CustomCursor.Visible end) and CustomCursor.Visible then
                -- Force unlock behavior while menu is open
                uis.MouseBehavior = Enum.MouseBehavior.Default
                local mPos = uis:GetMouseLocation()
                -- Adjust for GUI Inset (Top bar is ~36px)
                CustomCursor.Position = UDim2.new(0, mPos.X, 0, mPos.Y - 36)
            end
        end))

        -- ── Notification ───────────────────────────────────────────
        local function DoNotify(msg, dur)
            local content = tostring(msg or "")
            local nf = new("Frame", {
                BackgroundColor3 = Theme.BG,
                BorderSizePixel = 0,
                Position = UDim2.new(1, 20, 0.1, 0), -- Start off-screen
                Size = UDim2.new(0, 240, 0, 36),
                ZIndex = 50,
            }, ScreenRoot)
            stroke(Theme.Border, 1, nf)

            local accent = new("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 51,
            }, nf)
            new("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.AccentDark), Rotation = 0}, accent)

            new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                Text = content,
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 52,
            }, nf)

            tween(nf, 0.3, {Position = UDim2.new(1, -250, 0.1, 0)})
            task.delay(dur or 3, function()
                tween(nf, 0.3, {Position = UDim2.new(1, 20, 0.1, 0)})
                task.wait(0.4)
                nf:Destroy()
            end)
        end

        function Library:Notify(msg, dur) DoNotify(tostring(msg or ""), dur) end
        function Library:SetWatermark(text) WatermarkLabel.Text = tostring(text or "") end
        function Library:SetWatermarkVisibility(v) WatermarkBar.Visible = v end

        -- ── Toggle/Option constructors ─────────────────────────────
        local function makeToggle(idx, default)
            local cbs = {}
            local t = {
                Value = default or false,
                _callbacks = cbs,
            }
            function t:OnChanged(fn) table.insert(self._callbacks, fn) end
            function t:SetValue(v)
                self.Value = v
                for _, cb in ipairs(self._callbacks) do task.spawn(cb, v) end
            end
            -- AddKeyPicker stub (key pickers added in-place)
            function t:AddKeyPicker(kidx, cfg)
                local kcbs = {}
                Options[kidx] = {Value = cfg.Default or "None", _callbacks = kcbs}
                Options[kidx].OnChanged = function(self, fn) table.insert(kcbs, fn) end
                return self
            end
            Toggles[idx] = t
            return t
        end

        local function makeOption(idx, default)
            local cbs = {}
            local o = {Value = default, _callbacks = cbs}
            function o:OnChanged(fn) table.insert(self._callbacks, fn) end
            function o:SetValue(v)
                self.Value = v
                for _, cb in ipairs(self._callbacks) do task.spawn(cb, v) end
            end
            Options[idx] = o
            return o
        end

        -- ══════════════════════════════════════════════════════════
        -- CreateWindow → Window → AddTab → AddLeftGroupbox / AddRightGroupbox
        -- ══════════════════════════════════════════════════════════
        function Library:CreateWindow(cfg)
            local isMobile = UserInput.TouchEnabled
            local winWidth = isMobile and 400 or 600
            local winHeight = isMobile and 380 or 650

            -- ── Main window frame ──────────────────────────────────
            local Win = new("Frame", {
                Name = "AxisWindow",
                BackgroundColor3 = Theme.BG,
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, -winWidth/2, 0.5, -winHeight/2),
                Size = UDim2.new(0, winWidth, 0, winHeight),
                ClipsDescendants = true,
            }, ScreenRoot)
            -- corner(8, Win) -- Removed for sharp HvH look
            stroke(Theme.Border, 1, Win)

            -- ── Header ────────────────────────────────────────────
            local Header = new("Frame", {
                BackgroundTransparency = 1, -- Fully flat
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
            }, Win)

            local Title = new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                Text = cfg.Title or "axis.lol",
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)

            -- Divider 1: Header - TabBar
            new("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
            }, Header)


            -- Close / minimise buttons
            local function headerBtn(text, xOff, fn)
                local b = new("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, xOff, 0, 0),
                    Size = UDim2.new(0, 22, 1, 0),
                    Text = text,
                    TextColor3 = Theme.TextDim,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                }, Header)
                b.MouseButton1Click:Connect(fn)
                b.MouseEnter:Connect(function() tween(b, 0.1, {TextColor3 = Theme.Text}) end)
                b.MouseLeave:Connect(function() tween(b, 0.1, {TextColor3 = Theme.TextDim}) end)
            end
            local minimized = false
            local contentFrame -- forward declare
            headerBtn("_", -44, function()
                minimized = not minimized
                if contentFrame then
                    tween(Win, 0.2, {Size = minimized and UDim2.new(0, winWidth, 0, 32) or UDim2.new(0, winWidth, 0, winHeight)})
                end
            end)
            headerBtn("x", -22, function() 
                Library:Toggle()
            end)

            Library.Window = Win

            makeDraggable(Win, Header)

            -- Premium resizable menu handle (Mouse & Touch supported)
            local minW = UserInput.TouchEnabled and 300 or 450
            local minH = UserInput.TouchEnabled and 250 or 350

            local ResizeHandle = new("TextLabel", {
                Name = "ResizeHandle",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -12, 1, -12),
                Size = UDim2.new(0, 12, 0, 12),
                Text = "◢",
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                Active = true,
                ZIndex = 1200,
            }, Win)
            
            ResizeHandle.MouseEnter:Connect(function() tween(ResizeHandle, 0.1, {TextColor3 = Theme.Accent}) end)
            ResizeHandle.MouseLeave:Connect(function() tween(ResizeHandle, 0.1, {TextColor3 = Theme.TextDim}) end)

            makeResizable(Win, ResizeHandle, minW, minH, function(w, h)
                if not minimized then
                    winWidth = w
                    winHeight = h
                end
            end)

            -- Draggable Mobile Toggle Button (only on touch devices)
            if UserInput.TouchEnabled then
                local mobileBtn = new("TextButton", {
                    Name = "MobileToggle",
                    BackgroundColor3 = Theme.BG,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 38, 0, 143),
                    Size = UDim2.new(0, 46, 0, 46),
                    Text = "",
                    ZIndex = 5000,
                }, ScreenRoot)
                corner(23, mobileBtn)
                stroke(Theme.Border, 1.5, mobileBtn)
                
                local gradient = new("UIGradient", {
                    Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                    Rotation = 45
                }, mobileBtn)

                local glow = new("UIStroke", {
                    Color = Theme.Accent,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }, mobileBtn)

                local logo = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "A",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 22,
                    Font = Enum.Font.GothamBold,
                }, mobileBtn)

                makeDraggable(mobileBtn)

                mobileBtn.MouseButton1Click:Connect(function()
                    Library:Toggle()
                end)
                
                mobileBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        tween(mobileBtn, 0.1, {Size = UDim2.new(0, 42, 0, 42)})
                    end
                end)
                mobileBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        tween(mobileBtn, 0.1, {Size = UDim2.new(0, 46, 0, 46)})
                    end
                end)
            end

            -- ── Tab bar (Seamless) ──────────────────────────────────
            local TabBar = new("ScrollingFrame", {
                Name = "AxisNav",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, winWidth - 20, 0, 30),
                ZIndex = 1100, -- OVER EVERYTHING
                Visible = true,
                ScrollBarThickness = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.X,
                ScrollingDirection = Enum.ScrollingDirection.X,
            }, ScreenRoot) -- Parented to ScreenRoot for absolute visibility
            
            -- Keep tabs tracking the window
            local track = rs.RenderStepped:Connect(function()
                if Win and TabBar and ScreenRoot then
                    TabBar.Visible = Win.Visible and Win.Parent ~= nil
                    if Win.Visible then
                        local ap = Win.AbsolutePosition
                        local as = Win.AbsoluteSize
                        TabBar.Position = UDim2.new(0, ap.X + 10, 0, ap.Y + 24)
                        TabBar.Size = UDim2.new(0, as.X - 20, 0, 30)
                    end
                end
            end)
            Library:OnUnload(function() track:Disconnect() end)
            
            -- Divider 2: TabBar - Content
            new("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
            }, TabBar)

            -- Removed UIListLayout for manual control
            new("UIPadding", {PaddingLeft = UDim.new(0, 5)}, TabBar)

            -- ── Content area ───────────────────────────────────────
            contentFrame = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 58), -- Shifted down to prevent clipping
                Size = UDim2.new(1, 0, 1, -58),
                ClipsDescendants = true,
            }, Win)

            local activeTabFrame = nil
            local activeTabBtn   = nil
            local tabBtns = {}

            local WindowObj = { Tabs = {} }

            function WindowObj:AddTab(name)
                local tabObj = { Name = name }
                table.insert(self.Tabs, tabObj)
                
                local btn = new("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, #tabBtns * 75, 0, 0), -- Manual anchor
                    Size = UDim2.new(0, 70, 1, 0),
                    Text = name,
                    TextColor3 = Theme.TextDim,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    ZIndex = 51,
                    AutoButtonColor = false,
                    Visible = true,
                }, TabBar)

                local indicator = new("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 52,
                }, btn)
                new("UIGradient", {
                    Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                    Rotation = 90
                }, indicator)

                btn.MouseEnter:Connect(function()
                    if activeTabBtn ~= btn then
                        tween(btn, 0.1, {TextColor3 = Theme.Text})
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if activeTabBtn ~= btn then
                        tween(btn, 0.1, {TextColor3 = Theme.TextDim})
                    end
                end)

                -- Tab content pane
                local pane = new("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    Visible = false,
                }, contentFrame)

                -- Two-column layout inside pane
                local leftCol  = new("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,6,0,6), Size=UDim2.new(0.5,-9,1,0)}, pane)
                local rightCol = new("Frame", {BackgroundTransparency=1, Position=UDim2.new(0.5,3,0,6), Size=UDim2.new(0.5,-9,1,0)}, pane)
                local leftLayout  = new("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5)}, leftCol)
                local rightLayout = new("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5)}, rightCol)

                -- select if first tab
                if not activeTabFrame then
                    activeTabFrame = pane
                    activeTabBtn   = btn
                    pane.Visible = true
                    indicator.Visible = true
                    btn.TextColor3 = Theme.Text
                end
                table.insert(tabBtns, btn)

                btn.MouseButton1Click:Connect(function()
                    if activeTabFrame == pane then return end
                    if activeTabFrame then activeTabFrame.Visible = false end
                    if activeTabBtn then 
                        activeTabBtn.TextColor3 = Theme.TextDim
                        activeTabBtn:FindFirstChildOfClass("Frame").Visible = false
                    end
                    pane.Visible = true
                    indicator.Visible = true
                    btn.TextColor3 = Theme.Text
                    activeTabFrame = pane
                    activeTabBtn   = btn
                end)

                -- ── Groupbox factory ──────────────────────────────
                local function makeGroupbox(col, label, layout)
                    local order = layout.AbsoluteContentSize.Y + 1

                    local frame = new("Frame", {
                        BackgroundColor3 = Theme.Section,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 20),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        LayoutOrder = order,
                        ClipsDescendants = false,
                    }, col)
                    stroke(Theme.Border, 1, frame)

                    -- Integrated Line Header
                    local lineContainer = new("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 8, 0, -8),
                        Size = UDim2.new(1, -16, 0, 16),
                        ZIndex = 10,
                    }, frame)

                    local leftLine = new("Frame", {
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.new(0, 10, 0, 1),
                    }, lineContainer)
                    new("UIGradient", {
                        Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                        Rotation = 90
                    }, leftLine)

                    local titleLabel = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 14, 0, 0),
                        Size = UDim2.new(0, 0, 1, 0),
                        Text = label:upper(),
                        TextColor3 = Theme.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutomaticSize = Enum.AutomaticSize.X,
                    }, lineContainer)

                    local rightLine = new("Frame", {
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.new(1, 0, 0, 1),
                    }, lineContainer)
                    new("UIGradient", {
                        Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                        Rotation = 90
                    }, rightLine)
                    -- Wait for title size to position right line
                    titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        rightLine.Position = UDim2.new(0, titleLabel.AbsoluteSize.X + 18, 0.5, 0)
                        rightLine.Size = UDim2.new(1, -(titleLabel.AbsoluteSize.X + 18), 0, 1)
                    end)

                    local content = new("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 8),
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                    }, frame)
                    local cLayout = new("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)}, content)
                    new("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,10)}, content)

                    -- ── Element helpers ───────────────────────────
                    local G = {}
                    local elemOrder = 0
                    local function nextOrder() elemOrder = elemOrder + 1 return elemOrder end

                    local function rowFrame(h)
                        h = h or 22
                        return new("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,0,0,h),
                            LayoutOrder = nextOrder(),
                        }, content)
                    end

                    local function labelText(parent, txt, xalign)
                        return new("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,0,1,0),
                            Text = txt,
                            TextColor3 = Theme.Text,
                            TextSize = 12,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = xalign or Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                        }, parent)
                    end

                    -- AddLabel
                    function G:AddLabel(text)
                        local row = rowFrame(20)
                        local lbl = labelText(row, text)
                        local obj = {}
                        function obj:SetText(t) lbl.Text = t end
                        function obj:AddColorPicker(idx, cfg) return G:AddColorPicker(idx, cfg) end
                        function obj:AddKeyPicker(idx, cfg)  return G:AddKeyPicker(idx, cfg) end
                        return obj
                    end

                    -- AddButton
                    function G:AddButton(text_or_cfg, fn)
                        local text = type(text_or_cfg)=="string" and text_or_cfg or text_or_cfg.Text
                        fn = type(text_or_cfg)=="table" and text_or_cfg.Func or fn
                        local row = rowFrame(20)
                        local btn = new("TextButton", {
                            BackgroundColor3 = Theme.Section,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1,0,1,0),
                            Text = text,
                            TextColor3 = Theme.Text,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                        }, row)
                        stroke(Theme.Border, 1, btn)
                        btn.MouseButton1Click:Connect(function() if fn then task.spawn(fn) end end)
                        btn.MouseEnter:Connect(function() tween(btn,0.1,{BackgroundColor3=Theme.TabHover}) end)
                        btn.MouseLeave:Connect(function() tween(btn,0.1,{BackgroundColor3=Theme.Section}) end)
                        local obj = {}
                        function obj:AddColorPicker(kidx, kcfg) G:AddColorPicker(kidx, kcfg); return self end
                        function obj:AddKeyPicker(kidx, kcfg) G:AddKeyPicker(kidx, kcfg); return self end
                        return obj
                    end

                    -- AddToggle
                    function G:AddToggle(idx, cfg)
                        local tog = makeToggle(idx, cfg.Default)
                        local row = rowFrame(18)

                        local box = new("Frame", {
                            BackgroundColor3 = Theme.Toggle_Off,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0.5, -5), -- Center better
                            Size = UDim2.new(0, 10, 0, 10), -- Sized to ref
                        }, row)
                        stroke(Theme.Border, 1, box)

                        local inner = new("Frame", {
                            BackgroundColor3 = Theme.Accent,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 0),
                            Size = UDim2.new(1, 0, 1, 0), -- Solid fill
                            Visible = tog.Value,
                        }, box)
                        new("UIGradient", {
                            Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                            Rotation = 90
                        }, inner)

                        local label = labelText(row, cfg.Text or idx)
                        label.Position = UDim2.new(0, 18, 0, 0)
                        label.TextSize = 12
                        label.Font = Enum.Font.Gotham

                        local btn = new("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,0,1,0),
                            Text = "",
                        }, row)

                        local function refresh(v)
                            inner.Visible = v
                            tween(inner, 0.1, {BackgroundTransparency = v and 0 or 1})
                        end

                        btn.MouseButton1Click:Connect(function()
                            tog.Value = not tog.Value
                            refresh(tog.Value)
                            for _, cb in ipairs(tog._callbacks) do task.spawn(cb, tog.Value) end
                        end)

                        -- expose SetValue to update visuals
                        local orig = tog.SetValue
                        function tog:SetValue(v)
                            local val = not not v
                            self.Value = val
                            refresh(val)
                            for _, cb in ipairs(self._callbacks) do task.spawn(cb, val) end
                        end

                        -- AddKeyPicker on toggle
                        function tog:AddKeyPicker(kidx, kcfg)
                            G:AddKeyPicker(kidx, kcfg, idx)
                            return self
                        end

                        function tog:AddColorPicker(kidx, kcfg)
                            G:AddColorPicker(kidx, kcfg)
                            return self
                        end

                        if cfg.Callback then tog:OnChanged(cfg.Callback) end
                        return tog
                    end

                    -- AddSlider
                    function G:AddSlider(idx, cfg)
                        local opt = makeOption(idx, cfg.Default or cfg.Min)
                        local row = rowFrame(26)

                        local nameRow = new("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,14)}, row)
                        local valLbl = new("TextLabel", {
                            BackgroundTransparency=1,
                            AnchorPoint=Vector2.new(1,0),
                            Position=UDim2.new(1,0,0,0),
                            Size=UDim2.new(0,60,0,14),
                            Text=tostring(opt.Value),
                            TextColor3 = Theme.Text,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Right,
                        }, nameRow)
                        new("TextLabel", {
                            BackgroundTransparency=1,
                            Size=UDim2.new(1,-64,0,14),
                            Text=cfg.Text or idx,
                            TextColor3=Theme.Text,
                            TextSize=12,
                            Font=Enum.Font.Gotham,
                            TextXAlignment=Enum.TextXAlignment.Left,
                        }, nameRow)

                        local track = new("Frame", {
                            BackgroundColor3=Theme.SliderBG,
                            BorderSizePixel=0,
                            Position=UDim2.new(0,0,0,18),
                            Size=UDim2.new(1,0,0,4), -- Ultra thin
                        }, row)
                        stroke(Theme.Border, 1, track)

                        local fill = new("Frame", {
                            BackgroundColor3=Theme.Slider,
                            BorderSizePixel=0,
                            Size=UDim2.new(0,0,1,0),
                        }, track)
                        new("UIGradient", {
                            Color = ColorSequence.new(Theme.Accent, Theme.AccentDark),
                            Rotation = 90
                        }, fill)

                        local rounding = cfg.Rounding or 0
                        local function toFrac(v)
                            return math.clamp((v - cfg.Min)/(cfg.Max - cfg.Min), 0, 1)
                        end
                        local function fromFrac(f)
                            local v = cfg.Min + f*(cfg.Max - cfg.Min)
                            local mul = 10^rounding
                            return math.floor(v*mul+0.5)/mul
                        end
                        local function setVal(v)
                            local val = tonumber(v) or cfg.Default or cfg.Min or 0
                            opt.Value = val
                            local f = toFrac(val)
                            fill.Size = UDim2.new(f, 0, 1, 0)
                            pcall(function() valLbl.Text = tostring(val) end)
                            for _, cb in ipairs(opt._callbacks) do task.spawn(cb, val) end
                        end
                        setVal(opt.Value)

                        local drag = false
                        local btn = new("TextButton", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text="", ZIndex=3}, track)
                        
                        local function updateSlider(input)
                            local f = math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
                            setVal(fromFrac(f))
                        end
                        
                        btn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                drag = true
                                updateSlider(input)
                            end
                        end)
                        
                        Library:Track(UserInput.InputChanged:Connect(function(input)
                            if not Library.Running then return end
                            if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                updateSlider(input)
                            end
                        end))
                        
                        Library:Track(UserInput.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                drag = false
                            end
                        end))

                        function opt:SetValue(v)
                            setVal(v)
                        end

                        function opt:AddColorPicker(kidx, kcfg)
                            G:AddColorPicker(kidx, kcfg)
                            return self
                        end
                        if cfg.Callback then opt:OnChanged(cfg.Callback) end
                        return opt
                    end

                    -- AddDropdown
                    function G:AddDropdown(idx, cfg)
                        local items = cfg.Values or {}
                        local multi = cfg.Multi or false
                        local selected = {}
                        local opt = makeOption(idx, multi and {} or (cfg.Default or items[1]))
                        local row = rowFrame(36)
                        local open = false

                        if multi and cfg.Default then for _, v in ipairs(cfg.Default) do selected[v] = true end end

                        local title = cfg.Title or cfg.Name or idx
                        new("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,14), Text=title, TextColor3=Theme.Text, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, row)

                        local btn = new("TextButton", {BackgroundColor3=Theme.Input, BorderSizePixel=0, Position=UDim2.new(0,0,0,16), Size=UDim2.new(1,0,0,18), Text=multi and "  ..." or "  "..tostring(opt.Value), TextColor3=Theme.Text, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, row)
                        stroke(Theme.Border, 1, btn)

                        local popup = nil
                        local function close() if popup then popup:Destroy(); popup = nil end; open = false end
                        
                        function opt:CloseDropdown() close() end
                        function opt:OpenDropdown()
                            if open then return end
                            open = true
                            popup = new("Frame", {BackgroundColor3=Theme.BG, Position=UDim2.new(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y+20), Size=UDim2.new(0, btn.AbsoluteSize.X, 0, math.min(#items,8)*22), ZIndex=3000}, ScreenRoot)
                            stroke(Theme.Accent, 1, popup)
                            local scroll = new("ScrollingFrame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), CanvasSize=UDim2.new(0,0,0,#items*22), ScrollBarThickness=2, ZIndex=3001}, popup)
                            new("UIListLayout", {}, scroll)
                            for _, itm_val in ipairs(items) do
                                local itm = new("TextButton", {
                                    BackgroundColor3 = Theme.BG,
                                    BorderSizePixel = 0,
                                    Size = UDim2.new(1, 0, 0, 22),
                                    Text = "   " .. tostring(itm_val), -- extra space for padding
                                    TextColor3 = (multi and selected[itm_val] or opt.Value == itm_val) and Theme.Accent or Theme.Text,
                                    TextSize = 11,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 3002,
                                }, scroll)
                                stroke(Theme.Input, 1, itm) -- subtle inner border
                                itm.MouseEnter:Connect(function() tween(itm, 0.1, {BackgroundColor3 = Theme.Input}) end)
                                itm.MouseLeave:Connect(function() tween(itm, 0.1, {BackgroundColor3 = Theme.BG}) end)
                                
                                itm.MouseButton1Click:Connect(function()
                                    if multi then
                                        selected[itm_val] = not selected[itm_val]
                                        local vls = {}; for k,v in pairs(selected) do if v then table.insert(vls, k) end end
                                        opt:SetValue(vls)
                                    else opt:SetValue(itm_val); close() end
                                end)
                            end
                        end

                        btn.MouseButton1Click:Connect(function()
                            if open then close() else opt:OpenDropdown() end
                        end)

                        function opt:SetValue(v)
                            if multi and type(v)=="table" then
                                selected = {}; for _, k in ipairs(v) do selected[k]=true end
                                self.Value = v; 
                                pcall(function() btn.Text = "  "..(#v > 0 and table.concat(v, ", ") or "...") end)
                                if #btn.Text > 12 then btn.Text = btn.Text:sub(1,10)..".." end
                            else 
                                local val = v or items[1] or ""
                                self.Value = val; 
                                pcall(function() btn.Text = "  "..tostring(val) end)
                            end
                            for _, cb in ipairs(self._callbacks) do task.spawn(cb, self.Value) end
                        end

                        function opt:Refresh(newItems) items = newItems; if open then close() end end
                        function opt:AddColorPicker(kidx, kcfg)
                            G:AddColorPicker(kidx, kcfg)
                            return self
                        end
                        if cfg.Callback then opt:OnChanged(cfg.Callback) end
                        opt.Type = "Dropdown"
                        return opt
                    end


                    -- AddInput
                    function G:AddInput(idx, cfg)
                        local opt = makeOption(idx, cfg.Default or "")
                        local row = rowFrame(44)

                        new("TextLabel", {
                            BackgroundTransparency=1,
                            Size=UDim2.new(1,0,0,18),
                            Text=cfg.Text or idx,
                            TextColor3=Theme.Text,
                            TextSize=12,
                            Font=Enum.Font.Gotham,
                            TextXAlignment=Enum.TextXAlignment.Left,
                        }, row)

                        local box = new("TextBox", {
                            BackgroundColor3=Theme.Input,
                            BorderSizePixel=0,
                            Position=UDim2.new(0,0,0,20),
                            Size=UDim2.new(1,0,0,22),
                            Text=cfg.Default or "",
                            PlaceholderText=cfg.Placeholder or "",
                            TextColor3=Theme.Text,
                            PlaceholderColor3=Theme.TextDim,
                            TextSize=11,
                            Font=Enum.Font.Gotham,
                            TextXAlignment=Enum.TextXAlignment.Left,
                            ClearTextOnFocus=false,
                        }, row)
                        -- corner(4, box) -- Removed
                        stroke(Theme.Border, 1, box)
                        new("UIPadding", {PaddingLeft=UDim.new(0,6)}, box)

                        box.FocusLost:Connect(function()
                            opt.Value = box.Text
                            for _, cb in ipairs(opt._callbacks) do task.spawn(cb, box.Text) end
                            if cfg.Callback then cfg.Callback(box.Text) end
                        end)

                        function opt:SetValue(v)
                            local val = tostring(v or "")
                            pcall(function() box.Text = val end)
                            self.Value = val
                            for _, cb in ipairs(self._callbacks) do task.spawn(cb, val) end
                            if cfg.Callback then pcall(cfg.Callback, val) end
                        end
                        function opt:AddColorPicker(kidx, kcfg)
                            G:AddColorPicker(kidx, kcfg)
                            return self
                        end
                        return opt
                    end

                    -- AddColorPicker (sleek, high-quality, floating color picker with 100% mobile touch support)
                    function G:AddColorPicker(idx, cfg)
                        local opt = makeOption(idx, cfg.Default or Color3.new(1,1,1))
                        local row = rowFrame(24)

                        local title = cfg.Title or cfg.Name or idx
                        new("TextLabel", {
                            BackgroundTransparency=1,
                            Size=UDim2.new(1,-30,1,0),
                            Text=title,
                            TextColor3=Theme.Text,
                            TextSize=12,
                            Font=Enum.Font.Gotham,
                            TextXAlignment=Enum.TextXAlignment.Left,
                        }, row)

                        local swatch = new("TextButton", {
                            BackgroundColor3=opt.Value,
                            BorderSizePixel=0,
                            AnchorPoint=Vector2.new(1,0.5),
                            Position=UDim2.new(1,0,0.5,0),
                            Size=UDim2.new(0,22,0,16),
                            Text="",
                            ZIndex=5,
                        }, row)
                        stroke(Theme.Border, 1, swatch)

                        function opt:SetValue(c)
                            self.Value = c
                            swatch.BackgroundColor3 = c
                            for _, cb in ipairs(self._callbacks) do task.spawn(cb, c) end
                        end

                        -- Clicking swatch opens a gorgeous absolute floating popup
                        local activePopup = nil
                        swatch.MouseButton1Click:Connect(function()
                            if activePopup then
                                activePopup:Destroy()
                                activePopup = nil
                                return
                            end

                            local popup = new("Frame", {
                                BackgroundColor3=Theme.BG,
                                BorderSizePixel=0,
                                Position=UDim2.new(0, swatch.AbsolutePosition.X - 165, 0, swatch.AbsolutePosition.Y),
                                Size=UDim2.new(0, 160, 0, 160),
                                ZIndex=4000,
                            }, ScreenRoot)
                            activePopup = popup
                            corner(6, popup)
                            stroke(Theme.Accent, 1, popup)

                            -- Padding
                            new("UIPadding", {
                                PaddingLeft=UDim.new(0,8),
                                PaddingRight=UDim.new(0,8),
                                PaddingTop=UDim.new(0,8),
                                PaddingBottom=UDim.new(0,8),
                            }, popup)

                            -- UIListLayout
                            new("UIListLayout", {
                                Padding=UDim.new(0,6),
                                SortOrder=Enum.SortOrder.LayoutOrder,
                            }, popup)

                            -- Header Row
                            local header = new("Frame", {
                                BackgroundTransparency=1,
                                Size=UDim2.new(1,0,0,14),
                                LayoutOrder=1,
                            }, popup)
                            new("TextLabel", {
                                BackgroundTransparency=1,
                                Size=UDim2.new(1,-14,1,0),
                                Text=title:upper(),
                                TextColor3=Theme.Text,
                                TextSize=10,
                                Font=Enum.Font.GothamBold,
                                TextXAlignment=Enum.TextXAlignment.Left,
                            }, header)
                            local closeBtn = new("TextButton", {
                                BackgroundTransparency=1,
                                Position=UDim2.new(1,-12,0,0),
                                Size=UDim2.new(0,12,0,12),
                                Text="×",
                                TextColor3=Theme.TextDark,
                                TextSize=14,
                                Font=Enum.Font.GothamBold,
                            }, header)
                            closeBtn.MouseButton1Click:Connect(function()
                                popup:Destroy()
                                activePopup = nil
                            end)

                            -- Preview & Info
                            local preview = new("Frame", {
                                BackgroundColor3=opt.Value,
                                Size=UDim2.new(1,0,0,26),
                                LayoutOrder=2,
                            }, popup)
                            corner(4, preview)
                            stroke(Theme.Border, 1, preview)
                            
                            local hexLabel = new("TextLabel", {
                                BackgroundTransparency=1,
                                Size=UDim2.new(1,0,1,0),
                                Text="",
                                TextColor3=Color3.new(1,1,1),
                                TextSize=10,
                                Font=Enum.Font.GothamBold,
                                TextStrokeTransparency=0.5,
                            }, preview)

                            local vals = {opt.Value.R*255, opt.Value.G*255, opt.Value.B*255}

                            local function toHex(r, g, b)
                                return string.format("#%02X%02X%02X", math.floor(r), math.floor(g), math.floor(b))
                            end

                            local function update()
                                local c = Color3.fromRGB(vals[1], vals[2], vals[3])
                                preview.BackgroundColor3 = c
                                swatch.BackgroundColor3 = c
                                opt.Value = c
                                hexLabel.Text = toHex(vals[1], vals[2], vals[3]) .. " (" .. math.floor(vals[1]) .. "," .. math.floor(vals[2]) .. "," .. math.floor(vals[3]) .. ")"
                                for _, cb in ipairs(opt._callbacks) do task.spawn(cb, c) end
                            end
                            update()

                            local channels = {
                                {"R", vals[1], Color3.fromRGB(220,60,60)},
                                {"G", vals[2], Color3.fromRGB(60,200,60)},
                                {"B", vals[3], Color3.fromRGB(60,120,220)}
                            }

                            for i, ch in ipairs(channels) do
                                local sRow = new("Frame", {
                                    BackgroundTransparency=1,
                                    Size=UDim2.new(1,0,0,28),
                                    LayoutOrder=2+i,
                                }, popup)
                                
                                new("TextLabel", {
                                    BackgroundTransparency=1,
                                    Size=UDim2.new(1,0,0,12),
                                    Text=ch[1] .. ": " .. math.floor(vals[i]),
                                    TextColor3=Theme.TextDark,
                                    TextSize=10,
                                    Font=Enum.Font.Gotham,
                                    TextXAlignment=Enum.TextXAlignment.Left,
                                }, sRow)

                                local track = new("Frame", {
                                    BackgroundColor3=Theme.SliderBG,
                                    BorderSizePixel=0,
                                    Position=UDim2.new(0,0,0,16),
                                    Size=UDim2.new(1,0,0,6),
                                }, sRow)
                                stroke(Theme.Border, 1, track)
                                corner(3, track)

                                local fill = new("Frame", {
                                    BackgroundColor3=ch[3],
                                    BorderSizePixel=0,
                                    Size=UDim2.new(vals[i]/255, 0, 1, 0),
                                }, track)
                                corner(3, fill)

                                local drag = false
                                local function updateVal(input)
                                    local f = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                                    vals[i] = math.floor(f * 255 + 0.5)
                                    fill.Size = UDim2.new(f, 0, 1, 0)
                                    sRow.TextLabel.Text = ch[1] .. ": " .. vals[i]
                                    update()
                                end

                                track.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        drag = true
                                        updateVal(input)
                                    end
                                end)

                                Library:Track(UserInput.InputChanged:Connect(function(input)
                                    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                        updateVal(input)
                                    end
                                end))

                                Library:Track(UserInput.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        drag = false
                                    end
                                end))
                            end

                            -- Auto close on clicking outside popup and swatch
                            local function isPointInFrame(pos, frame)
                                if not frame or not frame.Parent then return false end
                                local fPos = frame.AbsolutePosition
                                local fSize = frame.AbsoluteSize
                                return pos.X >= fPos.X and pos.X <= fPos.X + fSize.X and pos.Y >= fPos.Y and pos.Y <= fPos.Y + fSize.Y
                            end

                            local clickOutsideConnection
                            clickOutsideConnection = Library:Track(UserInput.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                    task.wait(0.01) -- minor delay to avoid instant destroy on swatch click
                                    if popup and popup.Parent then
                                        if not isPointInFrame(input.Position, popup) and not isPointInFrame(input.Position, swatch) then
                                            popup:Destroy()
                                            activePopup = nil
                                            clickOutsideConnection:Disconnect()
                                        end
                                    else
                                        clickOutsideConnection:Disconnect()
                                    end
                                end
                            end))
                        end)

                        if cfg.Callback then opt:OnChanged(cfg.Callback) end
                        return opt
                    end

                    -- AddKeyPicker
                    -- AddKeyPicker
                    function G:AddKeyPicker(idx, cfg, linkedToggleIdx)
                        local opt = makeOption(idx, cfg.Default or "None")
                        local row = rowFrame(22)
                        local listening = false

                        local KeyMaps = {
                            ["RButton"] = Enum.UserInputType.MouseButton2,
                            ["LButton"] = Enum.UserInputType.MouseButton1,
                            ["MButton"] = Enum.UserInputType.MouseButton3,
                        }

                        local DisplayMaps = {
                            ["MouseButton1"] = "LButton",
                            ["MouseButton2"] = "RButton",
                            ["MouseButton3"] = "MButton",
                        }

                        local function updateHUD()
                            for _, child in ipairs(KeyListContent:GetChildren()) do
                                if child:IsA("Frame") then child:Destroy() end
                            end
                            for kid, kopt in pairs(Options) do
                                if kopt.IsKeybind and kopt.Value ~= "None" and kopt.Name ~= "Menu keybind" then
                                    local isActive = true
                                    if kopt.AssociatedToggle and Toggles[kopt.AssociatedToggle] then
                                        isActive = Toggles[kopt.AssociatedToggle].Value
                                    end
                                    local disp = DisplayMaps[kopt.Value] or kopt.Value
                                    local kr = new("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,16)}, KeyListContent)
                                    new("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0.6,0,1,0), Text=tostring(kopt.Name or "Unknown"), TextColor3=isActive and Theme.Text or Theme.TextDim, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ZIndex = 11}, kr)
                                    new("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0.6,0,0,0), Size=UDim2.new(0.4,0,1,0), Text="["..tostring(disp or "None").."]", TextColor3=isActive and Theme.Accent or Theme.TextDim, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right, ZIndex = 11}, kr)
                                end
                            end
                        end

                        local function matchesInput(i)
                            if opt.Value == "None" then return false end
                            local mapped = KeyMaps[opt.Value]
                            if mapped then return i.UserInputType == mapped end
                            if i.UserInputType.Name == opt.Value then return true end
                            if i.KeyCode.Name == opt.Value then return true end
                            return false
                        end

                        opt.IsKeybind = true
                        opt.Name = cfg.Text or idx
                        opt.AssociatedToggle = linkedToggleIdx
                        opt.Active = false
                        opt.Mode = cfg.Mode or "Toggle"

                        function opt:GetState()
                            if self.Value == "None" then return false end
                            if self.Mode == "Toggle" then
                                return self.Active
                            else
                                local val = self.Value
                                local mapped = KeyMaps[val]
                                if mapped then
                                    return UserInput:IsMouseButtonPressed(mapped)
                                elseif val:find("MouseButton") then
                                    local success, enumVal = pcall(function() return Enum.UserInputType[val] end)
                                    if success and enumVal then return UserInput:IsMouseButtonPressed(enumVal) end
                                else
                                    local success, enumVal = pcall(function() return Enum.KeyCode[val] end)
                                    if success and enumVal then return UserInput:IsKeyDown(enumVal) end
                                end
                                return self.Active
                            end
                        end

                        if linkedToggleIdx and Toggles[linkedToggleIdx] then
                            Toggles[linkedToggleIdx]:OnChanged(function()
                                updateHUD()
                            end)
                        end

                        local lbl = new("TextLabel", {
                            BackgroundTransparency=1,
                            Size=UDim2.new(1,-70,1,0),
                            Text=cfg.Text or idx,
                            TextColor3=Theme.Text,
                            TextSize=12,
                            Font=Enum.Font.Gotham,
                            TextXAlignment=Enum.TextXAlignment.Left,
                        }, row)

                        local keybtn = new("TextButton", {
                            BackgroundTransparency=1,
                            BorderSizePixel=0,
                            AnchorPoint=Vector2.new(1,0.5),
                            Position=UDim2.new(1,0,0.5,0),
                            Size=UDim2.new(0,0,0,16),
                            AutomaticSize=Enum.AutomaticSize.X,
                            Text="["..tostring(DisplayMaps[opt.Value] or opt.Value).."]",
                            TextColor3=Theme.Accent,
                            TextSize=11,
                            Font=Enum.Font.GothamBold,
                        }, row)

                        function opt:SetValue(v)
                            local val = tostring(v or "None")
                            self.Value = val
                            local disp = DisplayMaps[val] or val
                            pcall(function() keybtn.Text = "["..disp.."]" end)
                            for _, cb in ipairs(self._callbacks) do task.spawn(cb, val) end
                        end

                        keybtn.MouseButton1Click:Connect(function()
                            if listening then
                                listening = false
                                keybtn.Text = "["..tostring(DisplayMaps[opt.Value] or opt.Value).."]"
                                keybtn.TextColor3 = Theme.Accent
                            else
                                listening = true
                                keybtn.Text = "..."
                                keybtn.TextColor3 = Theme.TextDim
                            end
                        end)

                        Library:Track(UserInput.InputBegan:Connect(function(i, gp)
                            if not listening then
                                if gp then return end
                                if matchesInput(i) then
                                    if opt.Mode == "Toggle" then
                                        opt.Active = not opt.Active
                                        if linkedToggleIdx and Toggles[linkedToggleIdx] then
                                            Toggles[linkedToggleIdx]:SetValue(opt.Active)
                                        end
                                    else
                                        opt.Active = true
                                    end
                                    for _, cb in ipairs(opt._callbacks) do task.spawn(cb, i.KeyCode or i.UserInputType, false) end
                                end
                            else
                                if gp then return end
                                local newValue = nil
                                local displayValue = nil
                                
                                if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode ~= Enum.KeyCode.Escape then
                                    newValue = i.KeyCode.Name
                                    displayValue = i.KeyCode.Name
                                  elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
                                    newValue = "MouseButton1"
                                    displayValue = "LButton"
                                  elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
                                    newValue = "MouseButton2"
                                    displayValue = "RButton"
                                  elseif i.UserInputType == Enum.UserInputType.MouseButton3 then
                                    newValue = "MouseButton3"
                                    displayValue = "MButton"
                                end
                                
                                if newValue then
                                    opt.Value = newValue
                                    keybtn.Text = "["..displayValue.."]"
                                    keybtn.TextColor3 = Theme.Accent
                                    updateHUD()
                                    task.spawn(function()
                                        for _, cb in ipairs(opt._callbacks) do task.spawn(cb, i.KeyCode or i.UserInputType, true) end
                                        task.wait(0.2)
                                        listening = false
                                    end)
                                end
                            end
                        end))

                        Library:Track(UserInput.InputEnded:Connect(function(i, gp)
                            if not listening then
                                if matchesInput(i) then
                                    if opt.Mode == "Hold" then
                                        opt.Active = false
                                    end
                                end
                            end
                        end))

                        if cfg.Callback then opt:OnChanged(cfg.Callback) end
                        return opt
                    end

                    function G:AddRow(h)
                        return rowFrame(h or 24)
                    end

                    G.Container = content
                    return G
                end -- makeGroupbox

                function tabObj:AddLeftGroupbox(label)  return makeGroupbox(leftCol,  label, leftLayout)  end
                function tabObj:AddRightGroupbox(label) return makeGroupbox(rightCol, label, rightLayout) end

                function tabObj:Remove()
                    local wasActive = (activeTabBtn == btn)
                    pcall(function() pane:Destroy() end)
                    pcall(function() btn:Destroy() end)
                    for i, t in ipairs(tabBtns) do if t == btn then table.remove(tabBtns, i) break end end
                    for i, k in ipairs(self.Tabs) do if k == tabObj then table.remove(self.Tabs, i) break end end
                    
                    -- Re-align remaining tab buttons
                    local curX = 0
                    for _, b in ipairs(tabBtns) do
                        b.Position = UDim2.new(0, curX, 0, 0)
                        curX = curX + 75
                    end

                    -- If we removed the active tab, switch to the first available one
                    if wasActive and #tabBtns > 0 then
                        -- Find the first button and click it
                        local first = tabBtns[1]
                        if first then
                            -- We can't easily fire click, but we can call the same logic
                            -- Better: just find the first TabObj in self.Tabs and make it active
                            for _, t in ipairs(self.Tabs) do
                                -- To avoid complex logic, just tell user to switch tabs
                                Library:Notify("Active tab removed. Please switch tabs.", 2)
                                break
                            end
                        end
                    end
                end

                return tabObj
            end -- AddTab

            return WindowObj
        end -- CreateWindow

        -- Theme Manager (Decommissioned)
        local ThemeManager = {Folder = Paths.Theme}
        function ThemeManager:SetLibrary(lib) end
        function ThemeManager:SetFolder(f) end
        function ThemeManager:SaveTheme(name) end
        function ThemeManager:LoadTheme(name) end
        function ThemeManager:SetAutoload(name) end
        function ThemeManager:RemoveAutoload() end
        function ThemeManager:LoadAutoloadTheme() end
        function ThemeManager:ApplyToTab(tab) end

        -- ── Save Manager ──────────────────────────────────────────
        local SaveManager = {Folder = Paths.Config, Ignore = {}}
        function SaveManager:SetLibrary(lib) self.Library = lib end
        function SaveManager:SetFolder(f) self.Folder = f .. "\\" end
        function SaveManager:IgnoreThemeSettings() end
        function SaveManager:SetIgnoreIndexes(t) self.Ignore = t end
        
        function SaveManager:Save(name)
            if not name or name == "" then return end
            local data = {Toggles = {}, Options = {}}
            for k, v in pairs(Toggles) do data.Toggles[k] = v.Value end
            for k, v in pairs(Options) do
                local skip = false
                for _, idx in ipairs(self.Ignore) do if k == idx then skip = true end end
                if not skip then 
                    local val = v.Value
                    if typeof(val) == "Color3" then
                        data.Options[k] = {Type = "Color3", R = val.R, G = val.G, B = val.B}
                    else
                        data.Options[k] = val 
                    end
                end
            end
            write(self.Folder .. name .. ".json", game:GetService("HttpService"):JSONEncode(data))
        end
        
        function SaveManager:Load(name)
            if not name or name == "" then return end
            local content = read(self.Folder .. name .. ".json")
            if not content then return end
            local data = game:GetService("HttpService"):JSONDecode(content)
            for k, v in pairs(data.Toggles or {}) do if Toggles[k] then Toggles[k]:SetValue(v) end end
            for k, v in pairs(data.Options or {}) do 
                local opt = Options[k]
                if opt and type(opt) == "table" and opt.SetValue then 
                    if type(v) == "table" and v.Type == "Color3" then
                        pcall(function() opt:SetValue(Color3.new(v.R, v.G, v.B)) end)
                    else
                        pcall(function() opt:SetValue(v) end)
                    end
                end 
            end
        end

        function SaveManager:SetAutoload(name)
            write(self.Folder .. "autoload.txt", name)
        end
        function SaveManager:RemoveAutoload()
            pcall(function() delfile(self.Folder .. "autoload.txt") end)
        end
        function SaveManager:LoadAutoloadConfig()
            local name = read(self.Folder .. "autoload.txt")
            if name and name ~= "" then self:Load(name) end
        end

        function SaveManager:BuildConfigSection(tab)
            local group = tab:AddRightGroupbox("Configuration")
            local autolbl = group:AddLabel("Current autoload config: "..(read(self.Folder .. "autoload.txt") or "none"))
            local cname = group:AddInput("ConfigName", {Text = "Config name", Default = ""})
            local conf_list = {}
            local function refresh()
                conf_list = {}
                for _, f in ipairs(list_dir(self.Folder)) do
                    local n = f:match("([^\\]+)%.json$")
                    if n then table.insert(conf_list, n) end
                end
            end
            refresh()
            local drop = group:AddDropdown("ConfigList", {Text = "Config list", Values = conf_list})
            
            local function btn(txt, cb, parent, full)
                local b = new("TextButton", {BackgroundColor3=Theme.Tab, Size=full and UDim2.new(1,0,1,0) or UDim2.new(0.5,-3,1,0), Text=txt, TextColor3=Theme.Text, TextSize=11, Font=Enum.Font.GothamBold}, parent)
                stroke(Theme.Border, 1, b); b.MouseButton1Click:Connect(cb)
                return b
            end

            local row1 = group:AddRow(24)
            new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)}, row1)
            btn("Create config", function() self:Save(Options.ConfigName.Value); refresh(); drop:Refresh(conf_list) end, row1)
            btn("Load config", function() self:Load(Options.ConfigList.Value) end, row1)

            local row2 = group:AddRow(24)
            new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)}, row2)
            btn("Overwrite config", function() self:Save(Options.ConfigList.Value) end, row2)
            btn("Delete config", function() pcall(function() delfile(self.Folder..Options.ConfigList.Value..".json") end); refresh(); drop:Refresh(conf_list) end, row2)

            local row3 = group:AddRow(24)
            btn("Refresh list", function() refresh(); drop:Refresh(conf_list) end, row3, true)

            local row4 = group:AddRow(24)
            new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)}, row4)
            btn("Set autoload", function() self:SetAutoload(Options.ConfigList.Value); refresh(); drop:Refresh(conf_list) end, row4)
            btn("Remove autoload", function() self:RemoveAutoload(); refresh(); drop:Refresh(conf_list) end, row4)
            
            local oldRefresh = refresh
            refresh = function()
                oldRefresh()
                local cur = read(self.Folder .. "autoload.txt") or "none"
                autolbl:SetText("Current autoload config: " .. cur)
            end
        end

        function Library:LoadPlugins()
            -- logic remains but not auto-called
            local files = list(Paths.Script)
            for _, file in ipairs(files) do
                if file:sub(-4) == ".lua" then
                    local success, err = pcall(function()
                        local code = read(file)
                        if code then loadstring(code)() end
                    end)
                    if not success then warn("[axis] Plugin Error ("..file.."): "..err) end
                end
            end
        end

        Library.SaveManager = SaveManager
        Library.ThemeManager = ThemeManager
        getgenv().SaveManager = SaveManager
        getgenv().ThemeManager = ThemeManager
        _G.AxisAPI = Library -- Export for plugins

        function Library:AddTab(...) return self.MainWindow:AddTab(...) end
        
        -- Consolidated Notification logic moved to top
        -- Notification Wrapper (Silent Load aware)
        local function Notify(msg, duration)
            if Toggles.SilentLoad and Toggles.SilentLoad.Value then return end
            Library:Notify(msg, duration or 3)
        end
        _G.Notify = function(...) Notify(...) end

        -- ThemeManager:SetLibrary(Library) -- Decommissioned

        -- ── UI Creation Checkpoints ──


        local Window = Library:CreateWindow({
            Title = "axis.lol | discord.gg/at9m",
            Center = true,
            AutoShow = true,
            TabPadding = 8,
            MenuFadeTime = 0.2
        })
        Library.MainWindow = Window

        local Tabs = {
            Rage     = Window:AddTab('Rage'),
            AntiAim  = Window:AddTab('Orbit'),
            Movement = Window:AddTab('Movement'),
            Visuals  = Window:AddTab('Visuals'),
            Misc     = Window:AddTab('Main'),
            Settings = Window:AddTab('Settings'),
            Skins    = Window:AddTab('Skins'),
        }
        Tabs.World = Tabs.Movement -- Compatibility for legacy World references

        -- ============================================================
        -- ADVANCED ESP — UI
        -- ============================================================
        ;(function()
            local ESPMain   = Tabs.Visuals:AddLeftGroupbox("Player ESP")
            local ESPColors = Tabs.Visuals:AddRightGroupbox("ESP Colors")
            local ESPExtras = Tabs.Visuals:AddLeftGroupbox("ESP Extras")

            -- Master toggles
            ESPMain:AddToggle("ESPEnabled",   { Text = "Enable ESP",      Default = false })
            ESPMain:AddToggle("ESPBoxes",     { Text = "Corner Boxes",    Default = true  })
            ESPMain:AddToggle("ESPBoxFull",   { Text = "Full Boxes",      Default = false })
            ESPMain:AddToggle("ESPFill",      { Text = "Box Fill",        Default = false, Tooltip = "Semi-transparent inner fill." })
            ESPMain:AddToggle("ESPNames",     { Text = "Names",           Default = true  })
            ESPMain:AddToggle("ESPHealth",    { Text = "Health Bar",      Default = true  })
            ESPMain:AddToggle("ESPHealthNum", { Text = "Health Number",   Default = false })
            ESPMain:AddToggle("ESPSkeleton",  { Text = "Skeleton",        Default = false })
            ESPMain:AddToggle("ESPTracers",   { Text = "Tracers",         Default = false })
            ESPMain:AddDropdown("ESPTracerOrigin", { Text = "Tracer From", Values = {"Bottom", "Center", "Top"}, Default = 1 })
            ESPMain:AddToggle("ESPDistance",  { Text = "Distance",        Default = true })
            -- ESPMain:AddToggle("ESPWeapon",    { Text = "Weapon",          Default = false })
            ESPMain:AddToggle("ESPTeamCheck", { Text = "Team Check",      Default = false, Tooltip = "Skip players on the same team." })
            ESPMain:AddToggle("ESPHideDead",  { Text = "Hide Dead",       Default = true  })
            ESPMain:AddSlider("ESPMaxDist",   { Text = "Max Distance",    Default = 500, Min = 50, Max = 5000, Rounding = 0, Suffix = " studs" })
            ESPMain:AddSlider("ESPTextSize",  { Text = "Text Size",       Default = 13,  Min = 8,  Max = 24,  Rounding = 0 })

            -- Color pickers (must be chained off a Label in LinoriaLib)
            ESPColors:AddColorPicker("ESPColorEnemy", { Default = Color3.fromRGB(255, 60, 60), Title = "Enemy Color" })
            ESPColors:AddColorPicker("ESPColorTeam", { Default = Color3.fromRGB(60, 200, 255), Title = "Team Color" })
            ESPColors:AddColorPicker("ESPBoxCol", { Default = Color3.fromRGB(255, 255, 255), Title = "Box Color" })
            ESPColors:AddColorPicker("ESPColorFill", { Default = Color3.fromRGB(20, 20, 20), Title = "Fill Color" })
            ESPColors:AddColorPicker("ESPColorSkel", { Default = Color3.fromRGB(255, 255, 255), Title = "Skeleton Color" })
            ESPColors:AddColorPicker("ESPTracerCol", { Default = Color3.fromRGB(255, 255, 0), Title = "Tracer Color" })
            ESPColors:AddColorPicker("ESPColorHP", { Default = Color3.fromRGB(50, 220, 80), Title = "HP Bar Color" })
            ESPColors:AddColorPicker("ESPColorName", { Default = Color3.fromRGB(255, 255, 255), Title = "Name Color" })
            ESPColors:AddColorPicker("ESPPrioCol", { Default = Color3.fromRGB(255, 215, 0), Title = "Priority Color" })
            ESPColors:AddSlider("ESPBoxThick",    { Text = "Box Thickness",     Default = 1, Min = 1, Max = 4, Rounding = 0 })
            ESPColors:AddSlider("ESPSkelThick",   { Text = "Skel Thickness",    Default = 1, Min = 1, Max = 3, Rounding = 0 })
            ESPColors:AddSlider("ESPTracerThick", { Text = "Tracer Thickness",  Default = 1, Min = 1, Max = 4, Rounding = 0 })
            ESPColors:AddSlider("ESPHealthThick", { Text = "Health Bar Thickness", Default = 2, Min = 1, Max = 6, Rounding = 0 })

            -- Extra rendering (chain color pickers off their toggle)
            ESPExtras:AddToggle("ChamsEnabled", { Text = "Chams (Highlight)", Default = false, Tooltip = "Forces a flat colour override on enemy models." }):AddColorPicker("ChamsCol", { Default = Color3.fromRGB(255, 60, 60), Title = "Chams Color" })
            ESPExtras:AddToggle("OSIndicators", { Text = "Off-Screen Indicators", Default = false })
            ESPExtras:AddToggle("ESPGlow", { Text = "Glow Effect", Default = false }):AddColorPicker("ESPGlowColor", { Default = Color3.fromRGB(255, 80, 80), Title = "Glow Color" })
            ESPExtras:AddSlider("ESPGlowDepth", { Text = "Glow Depth", Default = 3, Min = 1, Max = 10, Rounding = 0 })
            ESPExtras:AddToggle("ESPSnaplines", { Text = "Snaplines", Default = false })
            ESPExtras:AddToggle("ESPHeadDot", { Text = "Head Dot", Default = false }):AddColorPicker("ESPHeadDotColor", { Default = Color3.new(1,1,1), Title = "Head Dot Color" })
        end)()

        -- ============================================================
        -- WORLD TAB — Movement & Lighting additions
        -- ============================================================
        local MovGroup = Tabs.Movement:AddLeftGroupbox("Movement")
        local LightGroup = Tabs.Visuals:AddLeftGroupbox("Lighting")

        MovGroup:AddToggle("CFrameSpeed", {
            Text = "WalkSpeed Hack",
            Default = false,
            Tooltip = "Smoothly scales your native movement speed using the game's internal physics constants."
        }):AddKeyPicker("SpeedKey", { Default = "V", SyncToggleState = true, Mode = "Toggle", Title = "Speed Hack" })
        
        MovGroup:AddSlider("SpeedMult", {
            Text = "Speed Multiplier",
            Default = 2,
            Min = 1,
            Max = 10,
            Rounding = 1,
        })

        MovGroup:AddToggle("FlyEnabled", {
            Text = "Fly / Noclip",
            Default = false,
        }):AddKeyPicker("FlyKey", { Default = "X", SyncToggleState = true, Mode = "Toggle", Title = "Fly" })

        MovGroup:AddSlider("FlySpeed", {
            Text = "Fly Speed",
            Default = 50,
            Min = 10,
            Max = 250,
            Rounding = 0,
        })

        MovGroup:AddToggle("BhopEnabled", {
            Text = "Bunny Hop",
            Default = false,
        })

        MovGroup:AddToggle("InfiniteDoubleJump", {
            Text = "Infinite Jump",
            Default = false,
        })

        MovGroup:AddSlider("DoubleJumpHeight", {
            Text = "Jump Multiplier",
            Default = 1,
            Min = 1,
            Max = 5,
            Rounding = 1,
        })

        MovGroup:AddToggle("SlideBoostEnabled", {
            Text = "Slide Boost",
            Default = false,
        })

        MovGroup:AddSlider("SlideBoost", {
            Text = "Boost Power",
            Default = 10,
            Min = 1,
            Max = 50,
            Rounding = 1,
        })

        MovGroup:AddToggle("NoclipEnabled", {
            Text = "Noclip Only",
            Default = false,
        })

        MovGroup:AddToggle("AntiRagdoll", {
            Text = "Anti-Ragdoll",
            Default = false,
        })

        LightGroup:AddToggle("FullbrightEnabled", {
            Text    = "Fullbright",
            Default = false,
            Tooltip = "Maximises all ambient lighting for complete map visibility.",
        })
        LightGroup:AddSlider("FullbrightBrightness", {
            Text     = "Brightness",
            Default  = 2,
            Min      = 1,
            Max      = 10,
            Rounding = 1,
        })

        local SkyboxList = {
            ["Aurora"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Aurora/Aurora/sky512_%s.tex" },
            ["Beautfil [From tutorial]"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Beautfil%20%5BFrom%20tutorial%5D/Beautfil%20%5BFrom%20tutorial%5D/sky512_%s.tex" },
            ["Blue"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Blue/Blue/sky512_%s.tex" },
            ["Caseoh"] = { single = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/sky512_dn.png" },
            ["Chill gray"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Chill%20gray/Chill%20gray/sky512_%s.tex" },
            ["Chill pink"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Chill%20pink/Chill%20pink/sky512_%s.tex" },
            ["Clear Skies Skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Clear%20Skies%20Skybox/Clear%20Skies%20Skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Cyan"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Cyan/Cyan/sky512_%s.tex" },
            ["DeadStarForestbyLiquidicy"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/DeadStarForestbyLiquidicy/DeadStarForestbyLiquidicy/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["ElegentMorningSky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/ElegentMorningSky/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Emo"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Emo/Emo/sky512_%s.tex" },
            ["FadeBlueSky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/FadeBlueSky/FadeBlueSky/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Goodnight"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Goodnight/Goodnight/sky512_%s.tex" },
            ["Hades"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Hades/Hades/sky512_%s.tex" },
            ["Hazy"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Hazy/Hazy/sky512_%s.tex" },
            ["Light Blue"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Light%20Blue/Light%20Blue/sky512_%s.tex" },
            ["Light pink"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Light%20pink/Light%20pink/sky512_%s.tex" },
            ["MCEndSkybytoby109tt"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/MCEndSkybytoby109tt/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["MCSkybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/MCSkybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Moonlight"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Moonlight/Moonlight/sky512_%s.tex" },
            ["NeonSky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/NeonSky/NeonSky/sky512_%s.tex" },
            ["NeonSky2"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/NeonSky2/NeonSky2/sky512_%s.tex" },
            ["Night"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Night/Night/sky512_%s.tex" },
            ["NightSkyWMoon"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/NightSkyWMoon/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Northern Lights Skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Northern%20Lights%20Skybox/Northern%20Lights%20Skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Oblivion"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Oblivion/Oblivion/sky512_%s.tex" },
            ["Orange"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Orange/Orange/sky512_%s.tex" },
            ["Overcast"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Overcast/Overcast/sky512_%s.tex" },
            ["Pandora [From tutorial]"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Pandora%20%5BFrom%20tutorial%5D/Pandora%20%5BFrom%20tutorial%5D/sky512_%s.tex" },
            ["PeacefullMorningSky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/PeacefullMorningSky/PeacefullMorningSky/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Pink Sunrise"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Pink%20Sunrise/Pink%20Sunrise/sky512_%s.tex" },
            ["Pumpkin Hill Skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Pumpkin%20Hill%20Skybox/Pumpkin%20Hill%20Skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Purple Nebula Skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Purple%20Nebula%20Skybox/Purple%20Nebula%20Skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Red"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Red/Red/sky512_%s.tex" },
            ["SFOTH"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/SFOTH/SFOTH/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["SettingSunSky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/SettingSunSky/SettingSunSky/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Shiverfrost"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Shiverfrost/Shiverfrost/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Space Blue"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Space%20Blue/Space%20Blue/sky512_%s.tex" },
            ["Spooky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Spooky/Spooky/sky512_%s.tex" },
            ["Sunny Sky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Sunny%20Sky/Sunny%20Sky/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Universe"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Universe/Universe/sky512_%s.tex" },
            ["Utter East"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Utter%20East/Utter%20East/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Vibrant Blue Skies Skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Vibrant%20Blue%20Skies%20Skybox/Vibrant%20Blue%20Skies%20Skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["Winterness"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/Winterness/Winterness/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["XenSkybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/XenSkybox/sky512_%s.tex" },
            ["ZenEnd"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/ZenEnd/sky512_%s.tex" },
            ["blackhole_skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/blackhole_skybox/blackhole_skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["broken sky skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/broken%20sky%20skybox/broken%20sky%20skybox/PlatformContent/pc/textures/sky/indoor512_%s.tex" },
            ["castle grounds skybox"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/castle%20grounds%20skybox/castle%20grounds%20skybox/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["forest"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/forest/forest/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["grimnight"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/grimnight/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["jungle_csgo"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/jungle_csgo/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["pink sky"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/pink%20sky/sky512_%s.tex" },
            ["rbx_sky Hydro"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/rbx_sky%20Hydro/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["rbx_sky Trainyard"] = { single = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/rbx_sky%20Trainyard/PlatformContent/pc/textures/sky/sky512_bk2.tex" },
            ["sky"] = { single = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky/moon.jpg" },
            ["sky2006"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky2006/sky2006/sky512_%s.tex" },
            ["sky_05"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_05/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_13"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_13/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_22"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_22/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_31"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_31/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_38"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_38/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_47"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_47/grimnight/Modifications/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_Disaster"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_Disaster/sky_Disaster/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_nibiru_bl"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_nibiru_bl/sky_nibiru_bl/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_purple"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_purple/sky_purple/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["sky_sunset"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_sunset/sky_sunset/sky512_%s.tex" },
            ["sky_universe"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/sky_universe/sky_universe/PlatformContent/pc/textures/sky/sky512_%s.tex" },
            ["whomp fortress"] = { url = "https://raw.githubusercontent.com/cloudsense-pub/assets/main/whomp%20fortress/whomp%20fortress/PlatformContent/pc/textures/sky/sky512_%s.tex" },
        }

        local skyboxKeys = {}
        for k, _ in pairs(SkyboxList) do table.insert(skyboxKeys, k) end
        table.sort(skyboxKeys)

        local AtmosGroup = Tabs.Visuals:AddRightGroupbox("Atmosphere")
        AtmosGroup:AddToggle("AtmosCustom", { Text = "Custom Atmosphere", Default = false })
        AtmosGroup:AddSlider("AtmosTime", { Text = "Time of Day", Default = 12, Min = 0, Max = 24, Rounding = 1 })
        AtmosGroup:AddColorPicker("AtmosAmbient", { Default = Color3.new(1,1,1), Title = "Ambient Color" })
        AtmosGroup:AddToggle("AtmosSkybox", { Text = "Custom Skybox", Default = false })
        AtmosGroup:AddDropdown("AtmosSkyboxSelect", { Text = "Skybox Style", Default = 1, Values = skyboxKeys })
        
        AtmosGroup:AddToggle("AtmosSunMoon", { Text = "Custom Sun & Moon", Default = false })
        AtmosGroup:AddDropdown("AtmosSunMoonSelect", { Text = "Sun/Moon Style", Default = 1, Values = { "idk", "terraria", "youareanidiot" } })

        AtmosGroup:AddToggle("AtmosCustom", { Text = "Custom Atmosphere", Default = false })
        AtmosGroup:AddSlider("AtmosTime", { Text = "Time of Day", Default = 12, Min = 0, Max = 24, Rounding = 1 })
        AtmosGroup:AddColorPicker("AtmosAmbient", { Default = Color3.new(1,1,1), Title = "Ambient Color" })
        AtmosGroup:AddToggle("AtmosFog", { Text = "Custom Fog", Default = false })
        AtmosGroup:AddSlider("AtmosFogStart", { Text = "Fog Start", Default = 0, Min = 0, Max = 1000, Rounding = 0 })
        AtmosGroup:AddSlider("AtmosFogEnd", { Text = "Fog End", Default = 1000, Min = 50, Max = 5000, Rounding = 0 })
        AtmosGroup:AddColorPicker("AtmosFogColor", { Default = Color3.fromRGB(150, 150, 150), Title = "Fog Color" })
        AtmosGroup:AddToggle("TexturePackEnabled", { Text = "Texture Pack (cloudsense)", Default = false, Tooltip = "Replaces Roblox material textures with the cloudsense texture pack via MaterialService. Downloads on first enable." })

        -- Weather Effects Commented Out
        --[[
        local WeatherGroup = Tabs.Visuals:AddLeftGroupbox("Weather & World")
        WeatherGroup:AddToggle("WeatherRain", { Text = "Enable Rain", Default = false })
        WeatherGroup:AddToggle("WeatherSnow", { Text = "Enable Snow", Default = false })
        WeatherGroup:AddToggle("GUISnow", { Text = "GUI Snow Effect", Default = false })
        --]]

        local CameraModGroup = Tabs.Visuals:AddRightGroupbox("Camera & Viewmodel")
        CameraModGroup:AddToggle("FOVEnabled", { Text = "Override FOV", Default = false })
        CameraModGroup:AddSlider("FOVValue", { Text = "Field of View", Default = 90, Min = 20, Max = 120, Rounding = 0 })
        
        CameraModGroup:AddToggle("NoSway", { Text = "No Weapon Sway/Bob", Default = false })

        -- Weapon Aesthetics
        CameraModGroup:AddToggle("VMWeaponOverride", { Text = "Weapon Material/Color", Default = false }):AddColorPicker("VMWeaponColor", { Default = Color3.fromRGB(180, 55, 255), Title = "Weapon Color" })
        CameraModGroup:AddDropdown("VMWeaponMaterial", { Values = {"Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Glass", "ForceField", "Foil", "DiamondPlate"}, Default = 1, Text = "Weapon Material" })
        CameraModGroup:AddSlider("VMWeaponTransparency", { Text = "Weapon Transparency %", Default = 0, Min = 0, Max = 100, Rounding = 0 })

        -- Arms Aesthetics
        CameraModGroup:AddToggle("VMArmsOverride", { Text = "Arms Material/Color", Default = false }):AddColorPicker("VMArmsColor", { Default = Color3.fromRGB(180, 55, 255), Title = "Arms Color" })
        CameraModGroup:AddDropdown("VMArmsMaterial", { Values = {"Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Glass", "ForceField", "Foil", "DiamondPlate"}, Default = 1, Text = "Arms Material" })
        CameraModGroup:AddSlider("VMArmsTransparency", { Text = "Arms Transparency %", Default = 0, Min = 0, Max = 100, Rounding = 0 })

        -- Arms & Weapon Positioning
        CameraModGroup:AddToggle("VMArmsPosEnabled", { Text = "Override Arms & Weapon Position", Default = false })
        CameraModGroup:AddSlider("VMArmsX", { Text = "Offset X", Default = 0, Min = -5, Max = 5, Rounding = 1 })
        CameraModGroup:AddSlider("VMArmsY", { Text = "Offset Y", Default = 0, Min = -5, Max = 5, Rounding = 1 })
        CameraModGroup:AddSlider("VMArmsZ", { Text = "Offset Z", Default = 0, Min = -5, Max = 5, Rounding = 1 })

        -- Hitmarkers Commented Out
        --[[
        local HitFXGroup = Tabs.Visuals:AddLeftGroupbox("Hit & Kill FX")
        HitFXGroup:AddToggle("HitmarkerEnabled", { Text = "Draw Hitmarkers", Default = false }):AddColorPicker("HitmarkerColor", { Default = Color3.new(1,1,1), Title = "Hitmarker Color" })
        HitFXGroup:AddSlider("HitmarkerFade", { Text = "Fade Time", Default = 0.5, Min = 0.1, Max = 2, Rounding = 1 })
        --]]

        -- ============================================================
        -- RAGEBOT & ANTI-AIM (New Features Only)
        -- ============================================================
        ;(function()
            local RageGroup = Tabs.Rage:AddLeftGroupbox("Ragebot")
            RageGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
            RageGroup:AddToggle("Wallbang", { Text = "Wallbang", Default = false, Tooltip = "Shoot through walls via Raycast manipulation." })
            RageGroup:AddToggle("AutoFire", { Text = "Auto Fire", Default = false })
            RageGroup:AddToggle("RapidFire", { Text = "Rapid Fire (UE-Killer)", Default = false })
            RageGroup:AddSlider("RapidFireSpam", { Text = "Spam Intensity", Default = 3, Min = 1, Max = 10, Rounding = 0 })
            
            -- Custom Triggerbot UI Options
            RageGroup:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false, Tooltip = "Automatically fires/swings when your mouse is over an enemy." })
            RageGroup:AddToggle("TriggerbotKatanaCheck", { Text = "Katana Parry Bypass", Default = true, Tooltip = "Will not fire/swing if the enemy is parrying or deflecting with a Katana." })
            RageGroup:AddToggle("TriggerbotForcefieldCheck", { Text = "Forcefield/Invincibility Check", Default = true, Tooltip = "Will not fire/swing if the target is invincible, has a active shield, or has SpawnProtection/Forcefield." })
            RageGroup:AddSlider("TriggerbotRange", { Text = "Triggerbot Range Limit", Default = 1000, Min = 5, Max = 1000, Rounding = 0, Suffix = " studs" })

            RageGroup:AddToggle("ShowFOV", { Text = "Show FOV Circle", Default = false }):AddColorPicker("SilentAimFOVColor", { Default = Color3.new(1, 1, 1), Title = "FOV Color" })
            RageGroup:AddToggle("RageFOVCheck", { Text = "Use FOV Check", Default = true })
            RageGroup:AddToggle("FOVFill", { Text = "Fill FOV", Default = false })
            RageGroup:AddToggle("FOVOutline", { Text = "FOV Outline", Default = false })
            RageGroup:AddSlider("SilentAimFOV", { Text = "FOV Limit", Default = 150, Min = 1, Max = 800, Rounding = 0 })
            RageGroup:AddDropdown("SilentAimPart", { Values = {"Head"}, Default = 1, Text = "Target Part (Forced Headshot)" })

            do
                RageGroup:AddToggle("CamLock", { Text = "Camera Aimbot (Cam Lock)", Default = false, Tooltip = "Smoothly locks your camera onto the target's head." })
                    :AddKeyPicker("CamLockKeybind", { Default = "RButton", SyncToggleState = false, Mode = "Hold", Title = "Cam Lock Keybind" })
                RageGroup:AddSlider("CamLockSmoothing", { Text = "Cam Lock Smoothing", Default = 20, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
            end

            local VoidGroup = Tabs.Rage:AddLeftGroupbox("Void Exploits")
            VoidGroup:AddToggle("SlingBypass", { Text = "Sling Bypass", Default = false })
            VoidGroup:AddToggle("VoidHide", { Text = "Void Hide (Bypass)", Default = false }):AddKeyPicker("VoidHideKeybind", { Default = "None", SyncToggleState = true, Mode = "Toggle", Title = "Void Hide" })
            VoidGroup:AddToggle("VoidSpam", { Text = "Void Spam (Cycle)", Default = false, Tooltip = "Cycles between the void and your original position." })
            VoidGroup:AddSlider("VoidHideTime", { Text = "Hide Time", Default = 0.5, Min = 0.1, Max = 5, Rounding = 1, Suffix = "s" })
            VoidGroup:AddSlider("VoidAttackTime", { Text = "Attack Time", Default = 0.2, Min = 0.1, Max = 5, Rounding = 1, Suffix = "s" })
            VoidGroup:AddToggle("VoidSpamRandom", { Text = "Void Spam (Aggressive)", Default = false, Tooltip = "Teleports you rapidly all over the void." })
            VoidGroup:AddSlider("VoidSpamSpeed", { Text = "Spam Speed", Default = 10, Min = 1, Max = 50, Rounding = 1 })

            local AntiDefenseGroup = Tabs.Rage:AddRightGroupbox("Anti-Defense Checks")
            AntiDefenseGroup:AddToggle("AntiKatana", { Text = "Anti Katana Parry", Default = true, Tooltip = "Will not target players actively deflecting or parrying with a Katana." })
            AntiDefenseGroup:AddToggle("AntiShield", { Text = "Anti Riot Shield", Default = true, Tooltip = "Will not target players holding or blocking with a Riot Shield." })

            local TeleportGroup = Tabs.Rage:AddRightGroupbox("Teleport Rage")
            TeleportGroup:AddToggle("TeleportRage", { Text = "Enable Teleport", Default = false })
            TeleportGroup:AddDropdown("TeleportMode", { Values = {"Above", "Behind", "Back", "Orbit"}, Default = "Above", Text = "Teleport Mode" })
            TeleportGroup:AddSlider("TeleportDist", { Text = "Back / Orbit Radius", Default = 10, Min = 5, Max = 30, Rounding = 1 })
            TeleportGroup:AddToggle("RandomTP", {
                Text = "Random TP",
                Default = false,
                Tooltip = "Rapidly teleports you to random positions nearby, making you extremely hard to hit.",
            })
            TeleportGroup:AddSlider("RandomTPSpeed", { Text = "TP Speed (per sec)", Default = 12, Min = 1, Max = 30, Rounding = 1 })
            TeleportGroup:AddSlider("RandomTPRadius", { Text = "Z Spread", Default = 30, Min = 5, Max = 120, Rounding = 1 })

            local HitboxGroup = Tabs.Rage:AddRightGroupbox("Hitbox Expander")
            HitboxGroup:AddToggle("HitboxExpand", { Text = "Expand Hitboxes", Default = false })
            HitboxGroup:AddToggle("HitboxVisible", { Text = "Show Hitboxes", Default = false })
            HitboxGroup:AddSlider("HitboxSize", { Text = "Enemy Hitbox Size", Default = 5, Min = 1, Max = 50, Rounding = 1 })
            HitboxGroup:AddSlider("KnifeHitboxSize", { Text = "Knife / Melee Range", Default = 8, Min = 1, Max = 50, Rounding = 1, Tooltip = "Expands the local player's equipped tool parts so melee touch-detection range increases." })

            local WeaponModsGroup = Tabs.Rage:AddRightGroupbox("Weapon Modifiers")
            WeaponModsGroup:AddToggle("WeaponModsAll", { Text = "No Cooldown, Spread, Recoil", Default = false })
        end)()
        -- WeaponModsGroup:AddToggle("FullAuto", { Text = "Full Auto (Semi → Auto)", Default = false, Tooltip = "Forces all semi-automatic weapons to fire fully automatically while held." })

        -- Anti-Aim UI defined below in the AntiAim tab (canonical block)

        -- Redundant Movement Group Commented Out (Unified under MovGroup on Movement Tab)
        --[[
        local MovementGroup = Tabs.Movement:AddLeftGroupbox("Movement Modifiers")
        MovementGroup:AddToggle("BhopEnabled", { Text = "Bunny Hop", Default = false })
        MovementGroup:AddToggle("CFrameSpeed", { Text = "CFrame Speed", Default = false })
        MovementGroup:AddSlider("SpeedMult", { Text = "Speed Multiplier", Default = 2, Min = 1, Max = 10, Rounding = 1 })
        MovementGroup:AddToggle("AntiRagdoll", { Text = "Anti-Ragdoll", Default = false })
        MovementGroup:AddToggle("InfiniteDoubleJump", { Text = "Infinite Jump", Default = false })
        MovementGroup:AddSlider("DoubleJumpHeight", { Text = "Jump Multiplier", Default = 1, Min = 1, Max = 5, Rounding = 1 })
        MovementGroup:AddToggle("SlideBoostEnabled", { Text = "Slide Boost", Default = false })
        MovementGroup:AddSlider("SlideBoost", { Text = "Boost Power", Default = 10, Min = 1, Max = 50, Rounding = 1 })
        --]]

        -- Panic Key addition to Misc
        local MiscGroup = Tabs.Misc:AddLeftGroupbox("Security & Utilities")
        MiscGroup:AddToggle("AntiScreenshot", { Text = "Anti-Screenshot / Panic", Default = false, Tooltip = "Instantly clears all ESP and hides the menu on detection." })
        MiscGroup:AddToggle("ReloadBypass", { Text = "Instant Reload / No Recoil", Default = false, Tooltip = "Sets reload time to zero for Bow, Daggers, and Slingshot." })
        MiscGroup:AddToggle("GlobalCooldownPatch", { Text = "Global Cooldown Patch", Default = false, Tooltip = "Removes delays between attacks/item use." })
        MiscGroup:AddToggle("AutoJumpShard", { Text = "Auto Collect Shards", Default = false, Tooltip = "Automatically collects JumpShard pickups on Heartbeat." })
        MiscGroup:AddToggle("SubspaceTripmine", { Text = "Auto Detonate Tripmines", Default = false, Tooltip = "Automatically detonates SubspaceTripmineHitbox objects on Heartbeat." })
        MiscGroup:AddToggle("HandicapMode", { Text = "Handicap Mode", Default = false, Tooltip = "Enables internal DebugController handicaps." })
        MiscGroup:AddLabel("Panic Key: End (Hardcoded)")

        Toggles.HandicapMode:OnChanged(function()
            ApplyHandicap(Toggles.HandicapMode.Value)
        end)


        -- Animation Player Groupbox
        local AnimGroup = Tabs.Visuals:AddRightGroupbox("Animation Player")
        AnimGroup:AddToggle("AnimEnabled", { Text = "Enable Animation Player", Default = false })
        AnimGroup:AddDropdown("AnimPreset", { Values = {"Normal", "Long Legs", "Spin", "Floppy", "Zesty"}, Default = 1, Text = "Animation Preset" })
        AnimGroup:AddInput("CustomAnimID", { Text = "Custom Animation ID", Placeholder = "id... (ex: 4049646104)" })
        AnimGroup:AddSlider("AnimSpeed", { Text = "Animation Speed", Default = 1, Min = 0.1, Max = 10, Rounding = 1 })
        AnimGroup:AddSlider("AnimStart", { Text = "Loop Start %", Default = 0, Min = 0, Max = 100, Rounding = 0 })
        AnimGroup:AddSlider("AnimEnd", { Text = "Loop End %", Default = 100, Min = 0, Max = 100, Rounding = 0 })

        -- Third Person Commented Out
        --[[
        local TPersonGroup = Tabs.Visuals:AddRightGroupbox("Third Person")
        TPersonGroup:AddToggle("ThirdPersonEnabled", { Text = "Enable Third Person", Default = false })
        TPersonGroup:AddSlider("ThirdPersonDist", { Text = "Camera Distance", Default = 10, Min = 1, Max = 50, Rounding = 1 })
        --]]

        local ExploitsGroup = Tabs.AntiAim:AddRightGroupbox("UE v2 Desync & Speed")
        -- ExploitsGroup:AddToggle("CFrameSpeed", { Text = "CFrame Speed", Default = false })
        -- ExploitsGroup:AddSlider("CFrameSpeedMult", { Text = "Speed Multiplier", Default = 1, Min = 0.1, Max = 5, Rounding = 1 })
        ExploitsGroup:AddToggle("FakeDpiEnabled", { Text = "Fake DPI", Default = false })
        ExploitsGroup:AddSlider("FakeDpiValue", { Text = "DPI Intensity", Default = 5, Min = 1, Max = 20, Rounding = 1 })

        -- Bullet Tracers and Look Tracers Commented Out
        --[[
        local TracerGroup = Tabs.Visuals:AddRightGroupbox("UE v2 ESP Features")
        TracerGroup:AddToggle("LookTracers", { Text = "Look Tracers", Default = false }):AddColorPicker("LookTracerCol", { Default = Color3.new(1, 0, 0), Title = "Tracer Color" })
        TracerGroup:AddToggle("BulletTracers", { Text = "Bullet Tracers (Beams)", Default = false }):AddColorPicker("BulletTracerCol", { Default = Color3.new(0, 1, 1), Title = "Bullet Color" })
        --]]

        local SkinGroup = Tabs.Skins:AddLeftGroupbox("Unlock All")
        SkinGroup:AddToggle("UnlockAll", {
            Text = "Client-Side Unlock All",
            Default = false,
            Tooltip = "Unlocks all cosmetics and weapons client-side. Re-equip items to apply.",
        })

        -- Replacements UI
        local ReplGroup  = Tabs.Skins:AddRightGroupbox("Replacements")

        ReplGroup:AddToggle("NoVignette", {
            Text    = "No Vignette",
            Default = false,
            Tooltip = "Removes the aiming vignette overlay (asset 14824249410).",
        })

        ReplGroup:AddToggle("SoundSwapperEnabled", {
            Text    = "Enable Audio Swapper",
            Default = false,
            Tooltip = "Enables custom replacement audio for game hits, kills, and eliminations.",
        })

        local audioOptions = { "Default", "Water", "Sweep", "Coin", "Agoui", "Crystal", "Water Drop", "Apakill", "Fatality", "Primordial", "Bameware", "Gamesense", "Neverlose", "Rifk7", "Bameware Mouse Click" }

        ReplGroup:AddDropdown("SoundHitBody", {
            Text    = "Body Hit Sound",
            Values  = audioOptions,
            Default = "Default",
        })

        ReplGroup:AddDropdown("SoundHitHead", {
            Text    = "Head Hit Sound",
            Values  = audioOptions,
            Default = "Default",
        })

        ReplGroup:AddDropdown("SoundKill", {
            Text    = "Kill Sound",
            Values  = audioOptions,
            Default = "Default",
        })

        ReplGroup:AddDropdown("SoundEliminated", {
            Text    = "Eliminated Sound",
            Values  = audioOptions,
            Default = "Default",
        })


        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)

        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({ 'ConfigList', 'ConfigName', 'PluginList' })

        pcall(function()
            if not isfolder('axislol') then makefolder('axislol') end
            if not isfolder('axislol/themes') then makefolder('axislol/themes') end
            if not isfolder('axislol/configs') then makefolder('axislol/configs') end
            if not isfolder('axislol/scripts') then makefolder('axislol/scripts') end
            if not isfolder('axislol/assets') then makefolder('axislol/assets') end
        end)

        -- ThemeManager:SetFolder('axislol/themes')
        SaveManager:SetFolder('axislol/configs')
        SaveManager:BuildConfigSection(Tabs.Settings)
        -- ThemeManager:ApplyToTab(Tabs.Settings)

        local PluginGroup = Tabs.Settings:AddRightGroupbox("Plugins")
        local plugin_list = {}
        local function refreshPlugins()
            plugin_list = {}
            for _, f in ipairs(list_dir(Paths.Script)) do
                local n = f:match("([^\\]+)%.lua$")
                if n then table.insert(plugin_list, n) end
            end
        end
        refreshPlugins()

        local drop = PluginGroup:AddDropdown("PluginList", {Text = "Script List", Values = plugin_list})
        
        local function btn(txt, cb, parent, full)
            local b = new("TextButton", {BackgroundColor3=Theme.Tab, Size=full and UDim2.new(1,0,1,0) or UDim2.new(0.5,-3,1,0), Text=txt, TextColor3=Theme.Text, TextSize=11, Font=Enum.Font.GothamBold}, parent)
            stroke(Theme.Border, 1, b); b.MouseButton1Click:Connect(cb)
        end

        local row1 = PluginGroup:AddRow(24)
        new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)}, row1)
        
        Library.PluginTabs = Library.PluginTabs or {}
        Library.PluginFeatures = Library.PluginFeatures or {}

        btn("Load Plugin", function()
            local file = Options.PluginList.Value
            if not file or file == "" then return end
            
            -- Track state before loading
            local beforeTabs = {}
            for _, t in ipairs(Window.Tabs) do beforeTabs[t] = true end
            local beforeToggles = {}
            for k, _ in pairs(Toggles) do beforeToggles[k] = true end
            local beforeOptions = {}
            for k, _ in pairs(Options) do beforeOptions[k] = true end
            
            local path = Paths.Script .. file .. ".lua"
            local code = read(path)
            if code then
                local success, err = pcall(function() loadstring(code)() end)
                if success then 
                    Library:Notify("Loaded: " .. file, 3) 
                    
                    -- Identify and store new objects
                    Library.PluginTabs[file] = Library.PluginTabs[file] or {}
                    for _, t in ipairs(Window.Tabs) do
                        if not beforeTabs[t] then table.insert(Library.PluginTabs[file], t) end
                    end
                    
                    Library.PluginFeatures[file] = Library.PluginFeatures[file] or { Toggles = {}, Options = {} }
                    for k, _ in pairs(Toggles) do
                        if not beforeToggles[k] then table.insert(Library.PluginFeatures[file].Toggles, k) end
                    end
                    for k, _ in pairs(Options) do
                        if not beforeOptions[k] then table.insert(Library.PluginFeatures[file].Options, k) end
                    end
                else 
                    Library:Notify("Error: " .. err, 5) 
                end
            end
        end, row1)

        btn("Unload Plugin", function()
            local file = Options.PluginList.Value
            if not file or file == "" then return end
            
            -- Cleanup Features
            local feats = Library.PluginFeatures[file]
            if feats then
                for _, k in ipairs(feats.Toggles) do
                    if Toggles[k] then
                        pcall(function() Toggles[k]:SetValue(false) end)
                        Toggles[k] = nil
                    end
                end
                for _, k in ipairs(feats.Options) do
                    Options[k] = nil
                end
                Library.PluginFeatures[file] = nil
            end

            -- Cleanup Tabs
            local tabs = Library.PluginTabs[file]
            if tabs and #tabs > 0 then
                local count = #tabs
                for _, t in ipairs(tabs) do
                    local success, err = pcall(function() t:Remove() end)
                    if not success then warn("Failed to remove tab: " .. tostring(err)) end
                end
                Library.PluginTabs[file] = nil
                Library:Notify("Unloaded " .. count .. " tabs & features for: " .. file, 3)
            else
                Library:Notify("Unloaded features for: " .. file, 3)
            end
        end, row1)

        local row2 = PluginGroup:AddRow(24)
        btn("Refresh script list", function() refreshPlugins(); drop:Refresh(plugin_list) end, row2, true)

        local UISettingsGroup = Tabs.Settings:AddLeftGroupbox("Menu Settings")

        UISettingsGroup:AddToggle("WatermarkEnabled", {
            Text = "Show Watermark",
            Default = true,
        })

        UISettingsGroup:AddLabel("Menu bind"):AddKeyPicker("AxisMenuBind", {
            Default = "RightShift",
            NoUI = true,
            Text = "Menu keybind",
        })

        UISettingsGroup:AddButton("Unload", function() Library:Unload() end)

        Options.AxisMenuBind:OnChanged(function(key, isSetting)
            if not isSetting then
                Library:Toggle()
            end
        end)

        UISettingsGroup:AddToggle("SilentLoad", {
            Text = "Silent Load",
            Default = false,
            Tooltip = "Mutes all notifications during script execution.",
        })

        --[[
        UISettingsGroup:AddToggle("AutoExecute", {
            Text = "Auto-Execute (Teleport)",
            Default = false,
            Tooltip = "Automatically re-runs the script when you teleport between servers.",
        })
        --]]

        UISettingsGroup:AddToggle("AutoRejoin", {
            Text = "Auto Rejoin",
            Default = false,
            Tooltip = "Automatically rejoins the game if you get kicked or disconnected.",
        })

        --[[
        UISettingsGroup:AddInput("AutoExecSource", {
            Text = "Auto-Execute Script",
            Default = "",
            Placeholder = "Paste loader here for teleports...",
            Tooltip = "If provided, this script will be used for Auto-Execute instead of detected files. Required for Luarmor.",
        })
        --]]

        Toggles.WatermarkEnabled:OnChanged(function()
            Library:SetWatermarkVisibility(Toggles.WatermarkEnabled.Value)
        end)

        -- Library:LoadPlugins() -- Disabled autoloading as requested
        
        --[[
        -- Default config auto-load
        if Toggles.AutoExecute and Toggles.AutoExecute.Value then
            pcall(function() SaveManager:Load("default") end)
        end
        --]]

        -- Centralized Menu Keybind Callback removed, logic moved to definition

        -- Auto Rejoin Logic
        Library:Track(game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            if Toggles.AutoRejoin and Toggles.AutoRejoin.Value then
                task.wait(5)
                game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
            end
        end))

        -- Auto Execute (Teleport) Logic (Disabled)
        --[[
        lp.OnTeleport:Connect(function(State)
            if State == Enum.TeleportState.Started and Toggles.AutoExecute and Toggles.AutoExecute.Value then
                local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
                if qot then
                    local manualSrc = Options.AutoExecSource and Options.AutoExecSource.Value or ""
                    local src = (manualSrc ~= "") and manualSrc or (getgenv().axis_src or "")
                    if src ~= "" then
                        qot(src)
                    end
                end
            end
        end)
        --]]

        -- UI Consolidation complete. Combat logic moved to line 4600+.

        local MoveExploits = Tabs.Movement:AddRightGroupbox("Teleports & World")
        MoveExploits:AddToggle("KillTP", {
            Text = "Kill-TP (Aimbot Snap)",
            Default = false,
            Tooltip = "Automatically teleports you behind your Silent Aim target.",
        })
        MoveExploits:AddToggle("AntiVoid", {
            Text = "Anti-Void",
            Default = false,
            Tooltip = "Prevents you from falling into the void.",
        })

        local rivalsCodes = {"FREE174", "COMMUNITY23", "BONUS", "BOOST", "ROBLOX_RTC"}

        local MainGroup = Tabs.Misc:AddRightGroupbox("Misc")

        MainGroup:AddButton("Redeem All Codes", function()
            local remote = nil
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and (v.Name:find("Redeem") or v.Name:find("ClaimCode")) then
                    remote = v
                    break
                end
            end
            
            if remote then
                Notify("Redeeming " .. #rivalsCodes .. " codes...", 2)
                for _, code in ipairs(rivalsCodes) do
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer(code)
                        else
                            remote:InvokeServer(code)
                        end
                    end)
                    task.wait(0.5)
                end
                Notify("Redemption process finished!", 3)
            else
                Notify("Could not find redemption remote. Please enter the Shop first.", 3)
            end
        end)

        local OrbitGroup = Tabs.AntiAim:AddLeftGroupbox("Orbit")
        local OrbitAdvanced = Tabs.AntiAim:AddRightGroupbox("Desync Settings")
        local AntiAimGroup = Tabs.AntiAim:AddLeftGroupbox("Anti-Aim")

        AntiAimGroup:AddToggle("AntiAimEnabled", {
            Text = "Enable Anti-Aim",
            Default = false,
            Tooltip = "Desynchs your hitbox to make it extremely hard to hit.",
        }):AddKeyPicker("AntiAimKey", {
            Default = "None",
            SyncToggleState = true,
            Mode = "Toggle",
            Text = "Anti-Aim",
        })

        AntiAimGroup:AddDropdown("AntiAimMode", {
            Text = "Anti-Aim Type",
            Values = {"Jitter", "Sway", "Inverter", "None"},
            Default = "Jitter",
        })

        AntiAimGroup:AddDropdown("AntiAimPitch", {
            Text = "Pitch (Head Desync)",
            Values = {"Flip", "Up", "Down", "None"},
            Default = "Down",
        })

        AntiAimGroup:AddSlider("AntiAimSpeed", {
            Text = "Speed",
            Default = 15,
            Min = 1,
            Max = 50,
            Rounding = 1,
        })

        AntiAimGroup:AddSlider("AntiAimJitterRange", {
            Text = "Rotate Amount",
            Default = 45,
            Min = 0,
            Max = 360,
            Rounding = 1,
            Suffix = "°",
        })

        AntiAimGroup:AddToggle("BackFaceEnemy", {
            Text = "Back-Face Nearest Enemy",
            Default = false,
            Tooltip = "Permanently rotates your character's back toward the nearest enemy. Makes riot shields and hitbox detection face away from them.",
        })

        OrbitGroup:AddToggle("OrbitEnabled", {
            Text = "Enable Orbit",
            Default = false,
            Tooltip = "Orbits around the nearest enemy to desync your hitbox.",
        })

        OrbitGroup:AddToggle("OrbitTargetHUD", {
            Text = "Target HUD",
            Default = false,
            Tooltip = "Shows a small HUD with target name, HP, and weapon.",
        })

        OrbitGroup:AddDropdown("OrbitTargetMode", {
            Values = {"Nearest", "Lowest HP"},
            Default = "Nearest",
            Text = "Target Mode",
        })

        OrbitGroup:AddSlider("OrbitRadius", {
            Text = "Base Radius",
            Default = 12,
            Min = 2,
            Max = 60,
            Rounding = 1,
        })

        OrbitGroup:AddSlider("OrbitSpeed", {
            Text = "Orbit Speed",
            Default = 20,
            Min = 1,
            Max = 120,
            Rounding = 1,
        })

        OrbitGroup:AddSlider("OrbitMaxDist", {
            Text = "Max Engage Distance",
            Default = 9999,
            Min = 20,
            Max = 9999,
            Rounding = 0,
            Tooltip = "Max distance to orbit enemy. Set to 9999 for infinite.",
        })

        OrbitGroup:AddToggle("OrbitKillNotif", {
            Text = "Kill Notifier",
            Default = false,
            Tooltip = "Shows a notification when you eliminate a player.",
        })

        OrbitAdvanced:AddToggle("OrbitJitterEnabled", {
            Text = "Jitter Radius",
            Default = false,
            Tooltip = "Rapidly switches between two radii to break aimbot interp.",
        })

        OrbitAdvanced:AddSlider("OrbitJitterAmt", {
            Text = "Jitter Intensity",
            Default = 6,
            Min = 1,
            Max = 50,
            Rounding = 1,
        })

        OrbitAdvanced:AddToggle("OrbitPhaseEnabled", {
            Text = "Phase Displacement",
            Default = false,
            Tooltip = "Randomly snaps to opposite side of orbit to break angular prediction.",
        })

        OrbitAdvanced:AddToggle("OrbitVerticalJitter", {
            Text = "Vertical Jitter",
            Default = false,
            Tooltip = "Varies Y height every orbit to break head-level aim.",
        })

        OrbitAdvanced:AddToggle("OrbitSpeedVariation", {
            Text = "Speed Variation",
            Default = false,
            Tooltip = "Randomly speeds up/slows orbit to break velocity-based prediction.",
        })

        OrbitAdvanced:AddToggle("OrbitLocalView", {
            Text = "Local View (Follow Orbit)",
            Default = false,
            Tooltip = "Your camera follows the orbit position so you can aim at your target.",
        })

        -- ── Player Prioritizer Groupbox ──
        local PrioritizeGroup = Tabs.AntiAim:AddRightGroupbox("Player Prioritizer")

        local function getPrioritizedListString()
            local list = {}
            for id, name in pairs(getgenv().PrioritizedPlayers) do
                table.insert(list, name)
            end
            table.sort(list)
            if #list == 0 then
                return "None"
            end
            return table.concat(list, ", ")
        end

        local prioLabel = PrioritizeGroup:AddLabel("Prioritized: None")

        local function refreshPrioLabel()
            prioLabel:SetText("Prioritized: " .. getPrioritizedListString())
        end

        local function getPlayerNames()
            local names = {}
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                if p ~= lp then
                    table.insert(names, p.Name)
                end
            end
            table.sort(names)
            if #names == 0 then
                return {"None"}
            end
            return names
        end

        local prioDropdown = PrioritizeGroup:AddDropdown("PrioPlayerSelect", {
            Values = getPlayerNames(),
            Default = 1,
            Text = "Select Player",
        })

        PrioritizeGroup:AddButton("Prioritize Player", function()
            local targetName = Options.PrioPlayerSelect.Value
            if not targetName or targetName == "" or targetName == "None" then return end
            local targetPlr = game:GetService("Players"):FindFirstChild(targetName)
            if targetPlr then
                getgenv().PrioritizedPlayers[targetPlr.UserId] = targetPlr.Name
                refreshPrioLabel()
                Notify("Prioritized " .. targetPlr.Name, 2)
            else
                Notify("Player not found", 2)
            end
        end)

        PrioritizeGroup:AddButton("Remove Priority", function()
            local targetName = Options.PrioPlayerSelect.Value
            if not targetName or targetName == "" or targetName == "None" then return end
            local targetPlr = game:GetService("Players"):FindFirstChild(targetName)
            if targetPlr then
                getgenv().PrioritizedPlayers[targetPlr.UserId] = nil
                refreshPrioLabel()
                Notify("Unprioritized " .. targetPlr.Name, 2)
            else
                -- Try to search by name in case player left
                for id, name in pairs(getgenv().PrioritizedPlayers) do
                    if name == targetName then
                        getgenv().PrioritizedPlayers[id] = nil
                        refreshPrioLabel()
                        Notify("Removed " .. name .. " from priority", 2)
                        return
                    end
                end
                Notify("Player not in list", 2)
            end
        end)

        PrioritizeGroup:AddButton("Clear All Priority", function()
            getgenv().PrioritizedPlayers = {}
            refreshPrioLabel()
            Notify("Cleared all prioritized players", 2)
        end)

        PrioritizeGroup:AddButton("Refresh Player List", function()
            prioDropdown:Refresh(getPlayerNames())
        end)

        -- Automatically refresh player dropdown on player join/leave
        Library:Track(game:GetService("Players").PlayerAdded:Connect(function()
            prioDropdown:Refresh(getPlayerNames())
        end))
        Library:Track(game:GetService("Players").PlayerRemoving:Connect(function(plr)
            if getgenv().PrioritizedPlayers[plr.UserId] then
                getgenv().PrioritizedPlayers[plr.UserId] = nil
                refreshPrioLabel()
            end
            prioDropdown:Refresh(getPlayerNames())
        end))

        local NetworkGroup = Tabs.AntiAim:AddLeftGroupbox("Packet Desync")
        NetworkGroup:AddToggle("PacketDesync", {
            Text = "Enable Packet Desync",
            Default = false,
            Tooltip = "Experimental RakNet hook to desync network packets.",
        })

        local AntiAimExtras = Tabs.AntiAim:AddRightGroupbox("Anti-Aim Extras")
        AntiAimExtras:AddToggle("AntiAimBodyCompress", {
            Text = "Body Compression",
            Default = false,
            Tooltip = "Squashes your hitbox to near-flat for maximum desync. Pairs with underground.",
        })
        AntiAimExtras:AddToggle("AntiAimUnderground", {
            Text = "Underground (Bury HRP)",
            Default = false,
            Tooltip = "Sinks hitbox below map floor height to prevent body-shot hits.",
        })
        AntiAimExtras:AddSlider("AntiAimUndergroundDepth", {
            Text = "Underground Depth",
            Default = 4,
            Min = 1,
            Max = 20,
            Rounding = 1,
            Suffix = " studs",
            Tooltip = "How far underground to sink your HumanoidRootPart.",
        })
        AntiAimExtras:AddToggle("AntiAimAntiOOB", {
            Text = "Anti Out-of-Bounds",
            Default = false,
            Tooltip = "Snaps you back to the map center if your position exceeds the boundary.",
        })
        AntiAimExtras:AddSlider("AntiAimOOBBound", {
            Text = "OOB Boundary",
            Default = 4000,
            Min = 500,
            Max = 10000,
            Rounding = 0,
            Suffix = " studs",
            Tooltip = "Distance from 0,0 to be considered Out of Bounds.",
        })

        -- Sling Bypass & Handicap UI in Main Tab (formerly Misc) consolidated to Security & Utilities
        --[[
        local EliteTools = Tabs.Misc:AddLeftGroupbox("Main")

        -- Movement logic removed as requested

        EliteTools:AddToggle("HandicapMode", {
            Text = "Handicap Mode",
            Default = false,
            Tooltip = "Enables internal DebugController handicaps.",
        })

        -- Performance logic remains but UI moved

        Toggles.HandicapMode:OnChanged(function()
            ApplyHandicap(Toggles.HandicapMode.Value)
        end)

        EliteTools:AddToggle("AutoJumpShard", {
            Text = "Auto Jump Shard",
            Default = false,
            Tooltip = "Automatically collects JumpShard pickups on Heartbeat.",
        })

        EliteTools:AddToggle("SubspaceTripmine", {
            Text = "Subspace Tripmine",
            Default = false,
            Tooltip = "Automatically detonates SubspaceTripmineHitbox objects for you on Heartbeat.",
        })

        EliteTools:AddToggle("ReloadBypass", {
            Text = "Instant Reload",
            Default = false,
            Tooltip = "Sets reload time to zero for Bow, Daggers, and Slingshot.",
        })
        ]]

        local MatchmakingGroup = Tabs.Misc:AddLeftGroupbox("Matchmaking")

        MatchmakingGroup:AddInput("PartyLeader", {
            Default = "",
            Text = "Party Leader Username",
            Placeholder = "Enter username...",

        })

        MatchmakingGroup:AddInput("AltUsernames", {
            Default = "",
            Text = "Alt Usernames (Comma Split)",
            Placeholder = "User1, User2, User3",

        })

        local SecurityGroup = Tabs.Misc:AddRightGroupbox("Staff")

        SecurityGroup:AddToggle("StaffDetector", {
            Text = "Enable Staff Detector",
            Default = false,
            Tooltip = "Alerts or kicks if a moderator/contributor is detected."
        })

        SecurityGroup:AddToggle("StaffDetectorAlert", {
            Text = "Staff Alert (Notifier)",
            Default = false,
            Tooltip = "Triggers sound and on-screen notification if staff is detected."
        })

        SecurityGroup:AddToggle("AutoLeaveStaff", {
            Text = "Auto Leave on Staff",
            Default = false,
            Tooltip = "Automatically leaves the server if a staff member joins."
        })

        -- Remove MovementGroup entirely as requested
        --[[
        local MovementGroup = Tabs.Misc:AddLeftGroupbox("Movement")
        ...
        ]]

        --[[
        local WorldGroup = Tabs.World:AddRightGroupbox("World Protection")

        WorldGroup:AddToggle("RemoveKillers", {
            Text = "Remove Killers",
            Default = false,
            Tooltip = "Attempts to disable kill bricks and void floors.",
        })

        local OptimGroup = Tabs.World:AddLeftGroupbox("Performance")
        OptimGroup:AddToggle("FPSBoostEnabled", {
            Text = "FPS Boost (No Textures)",
            Default = false,
            Tooltip = "Removes materials and decals to significantly increase FPS.",
        })

        OptimGroup:AddSlider("CameraResolution", {
            Text = "Camera Resolution",
            Default = 1,
            Min = 0.1,
            Max = 1,
            Rounding = 2,
            Tooltip = "Stretches resolution (Lower = Wider/More FPS).",
        })
        --]]

        -- Duplicate VoidHide and NoArmsEnabled commented out (Canonical exist in Rage & Visuals)
        --[[
        MainGroup:AddToggle("VoidHide", {
            Text = "VoidHide",
            Default = false,
            Tooltip = "Teleports you away and snaps you back to desync hitboxes.",
        }):AddKeyPicker("VoidHideKeybind", {
            Default = "None",
            SyncToggleState = true,
            Mode = "Toggle",
            Text = "VoidHide",
            NoUI = false,
        })

        -- Main Group cleanup

        MainGroup:AddToggle("NoArmsEnabled", {
            Text = "No Arms",
            Default = false,
            Tooltip = "Removes your own arms and cleans any left behind in the workspace.",
        })
        --]]

        -- Image Crosshair Logic
        local currentCrosshair = nil

        local function UpdateImageCrosshair()
            if Toggles.ImageCrosshair.Value then
                if not currentCrosshair then
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "CustomImageCrosshair"
                    gui.ResetOnSpawn = false
                    gui.IgnoreGuiInset = true
                    gui.Parent = lp:WaitForChild("PlayerGui")

                    local crosshair = Instance.new("ImageLabel")
                    crosshair.Parent = gui
                    crosshair.BackgroundTransparency = 1
                    crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
                    crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
                    crosshair.Size = UDim2.new(0, 24, 0, 24)
                    crosshair.Image = "rbxassetid://97119437608195"
                    crosshair.ImageTransparency = 0
                    
                    currentCrosshair = gui
                end
                uis.MouseIconEnabled = false
            else
                if currentCrosshair then
                    currentCrosshair:Destroy()
                    currentCrosshair = nil
                end
                uis.MouseIconEnabled = true
            end
        end

        local SpooferIdentity = Tabs.Misc:AddLeftGroupbox("Identity (Avatar)")
        local trackedVictimID = "1"
        SpooferIdentity:AddInput("SpoofVictimID", {
            Default = "1",
            Text = "Target UserID",
            Numeric = true,
            Finished = false,
        })

        Options.SpoofVictimID:OnChanged(function()
            trackedVictimID = Options.SpoofVictimID.Value
        end)

        SpooferIdentity:AddButton("Apply Identity", function()
            pcall(_G.axis_ApplySpoofIdentity)
        end)

        SpooferIdentity:AddToggle("AutoRefreshIdentity", {
            Text = "Auto-Refresh Identity",
            Default = false,
            Tooltip = "Periodically reapplies your chosen identity even after deaths.",
        })

        local SpooferName = Tabs.Misc:AddRightGroupbox("Name Changer")

        SpooferName:AddToggle("CustomNameEnabled", {
            Text = "Enable Name Changer",
            Default = false,
        })

        SpooferName:AddInput("CustomNameValue", {
            Default = "axis user",
            Text = "Custom Name",
        })

        -- ── Device Spoofer logic and UI setup ───────────────────────────
        do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local deviceControlMap = {
                ["VR"] = "VR",
                ["Mobile"] = "Touch",
                ["Controller"] = "Gamepad",
                ["PC"] = "MouseKeyboard"
            }

            local function applyDeviceSpoof()
                if not Toggles.DeviceSpoofEnabled or not Toggles.DeviceSpoofEnabled.Value then return end
                local selectedType = Options.DeviceSpoofType and Options.DeviceSpoofType.Value or "Mobile"
                local mappedValue = deviceControlMap[selectedType]
                if mappedValue then
                    pcall(function()
                        local remote = ReplicatedStorage:FindFirstChild("Remotes")
                            and ReplicatedStorage.Remotes:FindFirstChild("Replication")
                            and ReplicatedStorage.Remotes.Replication:FindFirstChild("Fighter")
                            and ReplicatedStorage.Remotes.Replication.Fighter:FindFirstChild("SetControls")
                        if remote then
                            remote:FireServer(mappedValue)
                        end
                    end)
                end
            end

            local DeviceSpoofer = Tabs.Misc:AddRightGroupbox("Device Spoofer")

            DeviceSpoofer:AddToggle("DeviceSpoofEnabled", {
                Text = "Enable Device Spoofer",
                Default = false,
                Tooltip = "Spoofs your controller/input device type to the server.",
                Callback = function(v)
                    if v then
                        applyDeviceSpoof()
                    end
                end
            })

            DeviceSpoofer:AddDropdown("DeviceSpoofType", {
                Values = { "PC", "Mobile", "Controller", "VR" },
                Default = "Mobile",
                Multi = false,
                Text = "Spoofed Device",
                Tooltip = "Choose the device type you want to broadcast to the game.",
                Callback = function()
                    applyDeviceSpoof()
                end
            })

            Library:Track(lp.CharacterAdded:Connect(function()
                task.wait(1.5)
                applyDeviceSpoof()
            end))
        end

        -- Visuals Tab is already well-organized at the top (lines 1619-1717)
        -- Removing redundant blocks from bottom of script to prevent 'doubled settings'
        
        local VisualsMisc = Tabs.Visuals:AddRightGroupbox("Direct & World Extras")
        VisualsMisc:AddToggle("NoArmsEnabled", {
            Text = "No Arms",
            Default = false,
            Tooltip = "Removes your own arms and cleans any left behind in the workspace.",
        })
        VisualsMisc:AddToggle("ImageCrosshair", {
            Text = "Image Crosshair",
            Default = false,
            Tooltip = "Enables a custom image-based crosshair at the center of the screen.",
        })
        Toggles.ImageCrosshair:OnChanged(UpdateImageCrosshair)

        local CrosshairGroup = Tabs.Visuals:AddLeftGroupbox("Crosshair")

        CrosshairGroup:AddToggle("CrosshairEnabled", {
            Text = "Enabled",
            Default = false,
        })

        CrosshairGroup:AddToggle("CrosshairOutline", {
            Text = "Outline",
            Default = false,
        })

        CrosshairGroup:AddToggle("CrosshairRainbow", {
            Text = "Rainbow Cycle",
            Default = false,
        })

        CrosshairGroup:AddLabel("Right Color"):AddColorPicker("CrosshairColRight", { Default = Color3.fromRGB(255, 255, 255) })
        CrosshairGroup:AddLabel("Up Color"):AddColorPicker("CrosshairColUp",       { Default = Color3.fromRGB(255, 255, 255) })
        CrosshairGroup:AddLabel("Left Color"):AddColorPicker("CrosshairColLeft",   { Default = Color3.fromRGB(255, 255, 255) })
        CrosshairGroup:AddLabel("Down Color"):AddColorPicker("CrosshairColDown",   { Default = Color3.fromRGB(255, 255, 255) })

        CrosshairGroup:AddLabel("Outline Color"):AddColorPicker("CrosshairOutlineColor", {
            Default = Color3.fromRGB(0, 0, 0),
            Title = "Outline Color",
        })

        CrosshairGroup:AddSlider("CrosshairRotation", {
            Text = "Rotation",
            Default = 0,
            Min = 0,
            Max = 360,
            Rounding = 1,
            Tooltip = "Static rotation offset in degrees.",
        })

        CrosshairGroup:AddSlider("CrosshairRotationSpeed", {
            Text = "Spin Speed",
            Default = 0,
            Min = 0,
            Max = 5,
            Rounding = 1,
            Tooltip = "Rotations per second. 0 = static.",
        })

        CrosshairGroup:AddSlider("CrosshairBounce", {
            Text = "Bounce (px)",
            Default = 0,
            Min = 0,
            Max = 300,
            Rounding = 0,
        })

        CrosshairGroup:AddSlider("CrosshairBounceSpeed", {
            Text = "Bounce Speed",
            Default = 5,
            Min = 1,
            Max = 5,
            Rounding = 1,
        })

        CrosshairGroup:AddSlider("CrosshairOffset", {
            Text = "Offset (px)",
            Default = 4,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Tooltip = "Gap between center and crosshair arms.",
        })

        CrosshairGroup:AddSlider("CrosshairLength", {
            Text = "Length (px)",
            Default = 8,
            Min = 1,
            Max = 500,
            Rounding = 0,
        })

        CrosshairGroup:AddSlider("CrosshairThickness", {
            Text = "Thickness (px)",
            Default = 1,
            Min = 1,
            Max = 10,
            Rounding = 0,
        })

        CrosshairGroup:AddSlider("CrosshairLerp", {
            Text = "LERP",
            Default = 1,
            Min = 0.01,
            Max = 1,
            Rounding = 2,
            Tooltip = "Smoothing factor. 1 = instant.",
        })

        CrosshairGroup:AddToggle("CrosshairBranding", {
            Text = "Show 'axis.lol' Text",
            Default = false,
            Tooltip = "Renders 'axis.lol' in small text just below the crosshair.",
        })

        -- Duplicate Performance tools commented out (Unified under primary Lighting/Movement components)
        --[[
        local PerformanceTools = Tabs.Visuals:AddRightGroupbox("Performance")
        PerformanceTools:AddToggle("FPSBoostEnabled", { 
            Text = "No Textures (FPS Boost)", 
            Default = false,
            Tooltip = "Removes materials and textures to maximize performance."
        })

        PerformanceTools:AddSlider("CameraResolution", { 
            Text = "Resolution Scale", 
            Default = 1, 
            Min = 0.1, 
            Max = 1, 
            Rounding = 2,
            Tooltip = "Stretches resolution for wider view/more FPS."
        })

        PerformanceTools:AddToggle("FullbrightEnabled", { Text = "Fullbright", Default = false })
        PerformanceTools:AddSlider("FullbrightBrightness", { Text = "Brightness", Default = 3, Min = 1, Max = 10, Rounding = 1 })
        --]]


        local function handleArm(obj)
            if not (Toggles.NoArmsEnabled and Toggles.NoArmsEnabled.Value) then return end
            if not (obj:IsA("BasePart") or obj:IsA("MeshPart")) then return end
            if obj:FindFirstAncestorOfClass("Accessory") then return end

            local name = obj.Name:lower()
            
            if name:find("arm") or name:find("hand") then
                local character = obj:FindFirstAncestorOfClass("Model")
                
                if character then
                    -- 1. Protect OTHER players
                    local player = playersService:GetPlayerFromCharacter(character)
                    if player and player ~= lp then
                        return
                    end
                    
                    -- 2. Protect Dummies/NPCs (Models with Humanoids that aren't you)
                    if character:FindFirstChildOfClass("Humanoid") then
                        if not (player == lp or character == lp.Character or character.Name == lp.Name) then
                            return
                        end
                    end
                end
                
                -- 3. If it's yours, a viewmodel, or an orphan (doesn't hit returns), destroy it
                obj:Destroy()
            end
        end

        Toggles.NoArmsEnabled:OnChanged(function()
            if Toggles.NoArmsEnabled.Value then

                -- Clean everything currently in workspace (with yields to prevent freeze)
                local count = 0
                for _, obj in pairs(workspace:GetDescendants()) do
                    count = count + 1
                    if count % 500 == 0 then task.wait() end
                    pcall(handleArm, obj)
                end
                -- Double check local character
                if lp.Character then
                    for _, obj in pairs(lp.Character:GetDescendants()) do
                        pcall(handleArm, obj)
                    end
                end

            end
        end)

        table.insert(earlyConnections, workspace.DescendantAdded:Connect(function(obj)
            pcall(handleArm, obj)
        end))

        -- Dedicated No Arms Throttled Loop
        task.spawn(function()
            while scriptActive do
                task.wait(0.2)
                if not Library.Running then break end
                if Toggles.NoArmsEnabled and Toggles.NoArmsEnabled.Value then
                    pcall(function()
                        local char = lp.Character
                        if char then
                            for _, v in ipairs(char:GetChildren()) do
                                if v.Name:find("Arm") or v.Name:find("Hand") then
                                    for _, p in ipairs(v:GetDescendants()) do
                                        if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = 1 end
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end)

        -- UI Settings logic
        Library.ToggleKeybind = Options.AxisMenuBind

        -- Status Features
        local function UpdateStatus()
            local state = Toggles.VoidHide.Value and "Active" or "Inactive"
            Library:SetWatermark("axis.lol | discord.gg/at9m | Status: " .. state)
        end

        UpdateStatus()

        Toggles.VoidHide:OnChanged(function()
            UpdateStatus()
        end)



        -- Kill Notifier Logic
        local function showKillNotif(name)
            if not Toggles.OrbitKillNotif.Value then return end
            Notify("Eliminated " .. name, 3)
        end

        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= lp then
                Library:Track(p.CharacterAdded:Connect(function(char)
                    local hum = char:WaitForChild("Humanoid", 5)
                    if hum then
                        hum.Died:Connect(function()
                            -- Simple distance check to see if we were likely the killer
                            local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            local targetHRP = char:FindFirstChild("HumanoidRootPart")
                            if myHRP and targetHRP and (myHRP.Position - targetHRP.Position).Magnitude < 100 then
                                showKillNotif(p.Name)
                            end
                        end)
                    end
                end))
            end
        end

        --[[
        -- World Protection Logic (Disabled)
        --]]

        -- Logic
        local character = lp.Character or lp.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

        -- Snap Back Data
        local clientc
        local clientv
        local clientva

        -- Character Handling
        Library:Track(lp.CharacterAdded:Connect(function(newCharacter)
            character = newCharacter
            humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
        end))

        -- Core Heartbeat (Teleport Away)
        -- Core Heartbeat (Teleport Away)
        local voidHideTog = Toggles.VoidHide
        Library:Track(rs.Heartbeat:Connect(function()
            if not Library.Running or not voidHideTog or not voidHideTog.Value then return end
            pcall(function()
                if humanoidRootPart then
                    -- Save real position (Always update for fluid movement)
                    clientc = humanoidRootPart.CFrame
                    clientv = humanoidRootPart.AssemblyLinearVelocity
                    clientva = humanoidRootPart.AssemblyAngularVelocity
                    -- Teleport to random extreme coordinate for desync (engine-safe range to prevent anti-cheat kicks)
                    local tpPos = Vector3.new(
                        math.random(-99999, 99999),
                        math.random(99999, 150000),
                        math.random(-99999, 99999)
                    )
                    humanoidRootPart.CFrame = CFrame.new(tpPos)
                end
            end)
        end))

        -- Core RenderStep (Snap back) - uses pre-declared function, no per-frame closure allocation
        local function _snapback()
            if humanoidRootPart and clientc then
                humanoidRootPart.CFrame = clientc
                if clientv  then humanoidRootPart.AssemblyLinearVelocity  = clientv  end
                if clientva then humanoidRootPart.AssemblyAngularVelocity = clientva end
            end
        end

        rs:BindToRenderStep("tp_snapback", Enum.RenderPriority.First.Value, function()
            local voidActive  = Toggles.VoidHide and Toggles.VoidHide.Value
            local orbitActive = Toggles.OrbitEnabled and Toggles.OrbitEnabled.Value
            local localView   = Toggles.OrbitLocalView and Toggles.OrbitLocalView.Value

            if (voidActive or orbitActive) and not localView then
                pcall(_snapback)
            end
        end)

        -- ── Enemy Orbit System (v2 - Anti-Resolver) ─────────────────
        do
            local orbit_angle      = 0
            local orbit_phaseFlip  = 1  -- +1 or -1 for phase displacement
            local orbit_speedVar   = 1  -- multiplier for speed variation
            local orbit_lastPhase  = 0  -- throttle phase flips
            local orbit_lastSpeed  = 0  -- throttle speed variation
            local orbit_currentTarget = nil

            local function getOrbitTarget()
                return CachedNearestEnemyRoot
            end

            rs:BindToRenderStep("orbit_v4_pos", Enum.RenderPriority.First.Value + 1, function()
                if not (Toggles.OrbitEnabled and Toggles.OrbitEnabled.Value) then
                    orbit_currentTarget = nil
                    if TargetHUD then TargetHUD.Visible = false end
                    return
                end
                pcall(function()
                    local myChar = lp.Character
                    local hrp    = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    -- Find target
                    local targetHRP = getOrbitTarget()
                    orbit_currentTarget = targetHRP
                    if not targetHRP then return end -- No enemy in range, stay put

                    local t      = tick()
                    local radius = Options.OrbitRadius.Value
                    local speed  = Options.OrbitSpeed.Value

                    -- ── Anti-Resolver: Speed Variation ─────────────────────
                    if Toggles.OrbitSpeedVariation and Toggles.OrbitSpeedVariation.Value then
                        if t - orbit_lastSpeed > 0.3 then
                            orbit_speedVar   = 0.5 + math.random() * 1.5 -- 0.5x to 2x speed
                            orbit_lastSpeed  = t
                        end
                        speed = speed * orbit_speedVar
                    end

                    -- ── Anti-Resolver: Phase Displacement ──────────────────
                    if Toggles.OrbitPhaseEnabled and Toggles.OrbitPhaseEnabled.Value then
                        if t - orbit_lastPhase > 0.15 + math.random() * 0.25 then
                            if math.random() < 0.35 then -- 35% chance per window
                                orbit_phaseFlip  = -orbit_phaseFlip
                            end
                            orbit_lastPhase = t
                        end
                    else
                        orbit_phaseFlip = 1
                    end

                    -- ── Anti-Resolver: Jitter Radius ───────────────────────
                    if Toggles.OrbitJitterEnabled and Toggles.OrbitJitterEnabled.Value then
                        local jAmt = Options.OrbitJitterAmt.Value
                        -- Fast alternation between tight and wide radius
                        local jitterPhase = math.floor(t * 30) % 2 -- 15Hz switch
                        radius = radius + (jitterPhase == 0 and jAmt or -jAmt * 0.5)
                        radius = math.max(2, radius)
                    end

                    -- ── Advance angle ──────────────────────────────────────
                    orbit_angle = orbit_angle + (speed * orbit_phaseFlip * 0.016)

                    local cosA = math.cos(orbit_angle)
                    local sinA = math.sin(orbit_angle)

                    -- ── Anti-Resolver: Vertical Jitter ─────────────────────
                    local yOffset = 3 -- default slight elevation above ground
                    if Toggles.OrbitVerticalJitter and Toggles.OrbitVerticalJitter.Value then
                        -- Combine two sine waves at different frequencies for chaotic vertical motion
                        yOffset = 3 + math.sin(t * 7.3) * 3 + math.sin(t * 13.1) * 1.5
                    end

                    local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(targetHRP.Parent)
                    local targetRealCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[targetPlayer]
                    local targetPos = targetRealCF and targetRealCF.Position or targetHRP.Position

                    local orbitPos = targetPos + Vector3.new(cosA * radius, yOffset, sinA * radius)
                    local orbitCF  = CFrame.new(orbitPos, targetPos) -- Face target

                    hrp.CFrame = orbitCF

                    -- ── Local View: update clientc so snapback follows orbit ─
                    if Toggles.OrbitLocalView and Toggles.OrbitLocalView.Value then
                        clientc  = orbitCF
                        clientv  = Vector3.zero
                        clientva = Vector3.zero
                    end
                end)

                -- ── Target HUD Update ──────────────────────────
                local showHUD = Toggles.OrbitTargetHUD and Toggles.OrbitTargetHUD.Value
                if showHUD and orbit_currentTarget then
                    pcall(function()
                        local targetHRP = orbit_currentTarget
                        local targetChar = targetHRP.Parent
                        local hum = targetChar and targetChar:FindFirstChildWhichIsA("Humanoid")
                        local p = game:GetService("Players"):GetPlayerFromCharacter(targetChar)
                        
                        TargetHUD.Visible = true
                        TargetName.Text = "Name: " .. (p and (p.DisplayName or p.Name) or (targetChar and targetChar.Name or "Unknown"))
                        
                        if hum then
                            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            HPFill.Size = UDim2.new(hp, 0, 1, 0)
                            HPText.Text = math.floor(hp * 100) .. "%"
                            HPFill.BackgroundColor3 = Color3.fromHSV(hp * 0.35, 0.8, 1)
                        end

                        local tool = targetChar and targetChar:FindFirstChildOfClass("Tool")
                        TargetWeapon.Text = "Weapon: " .. (tool and tool.Name or "None")
                    end)
                else
                    if TargetHUD then TargetHUD.Visible = false end
                end
            end)
        end

        -- Network Desync Logic
        do
            local function rakhook(packet)
                if packet.PacketId == 0x1B then
                    local data = packet.AsBuffer
                    pcall(function()
                        buffer.writeu32(data, 1, 0xFFFFFFFF)
                        packet:SetData(data)
                    end)
                end
            end

            Toggles.PacketDesync:OnChanged(function()
                local has_raknet = false
                pcall(function() has_raknet = (type(getgenv().raknet) == "table" or type(raknet) == "table") end)

                if not has_raknet then 
                    if Toggles.PacketDesync.Value then
                        Notify("Your executor does not support RakNet hooks!", 3)
                        Toggles.PacketDesync:SetValue(false)
                    end
                    return 
                end
                
                if Toggles.PacketDesync.Value then
                    pcall(function() raknet.add_send_hook(rakhook) end)
                    Notify("Packet Desync Enabled", 2)
                else
                    pcall(function() raknet.remove_send_hook(rakhook) end)
                    Notify("Packet Desync Disabled", 2)
                end
            end)
        end

        -- Animation Player Logic
        do
            local currentAnimTrack = nil
            local animConnection = nil

            local function stopCurrentAnim()
                if currentAnimTrack then
                    pcall(function() currentAnimTrack:Stop() end)
                    currentAnimTrack = nil
                end
                if animConnection then
                    animConnection:Disconnect()
                    animConnection = nil
                end
            end

            local function anim2track(asset_id)
                local success, objs = pcall(function() return game:GetObjects(asset_id) end)
                if success and objs and objs[1] then
                    for i = 1, #objs do
                        if objs[i]:IsA("Animation") then
                            return objs[i].AnimationId
                        end
                    end
                end
                return asset_id
            end

            -- Presets mapped to aesthetic animation asset IDs
            local AnimationPresets = {
                ["Long Legs"] = "rbxassetid://507768375",   -- Zombie walk
                ["Spin"]      = "rbxassetid://188632007",   -- Spin loop
                ["Floppy"]    = "rbxassetid://182435965",   -- Ninja run
                ["Zesty"]     = "rbxassetid://3337994105"   -- Aesthetic run
            }

            local function playCustomAnim()
                stopCurrentAnim()
                if not (Toggles.AnimEnabled and Toggles.AnimEnabled.Value) then return end
                
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                
                local animId
                local preset = Options.AnimPreset.Value
                if preset ~= "Normal" and AnimationPresets[preset] then
                    animId = AnimationPresets[preset]
                else
                    local custom = Options.CustomAnimID.Value
                    if not custom or custom == "" then return end
                    if not custom:find("rbxassetid://") then
                        custom = "rbxassetid://" .. custom
                    end
                    animId = custom
                end

                local trackId = anim2track(animId)
                local animation = Instance.new("Animation")
                animation.AnimationId = trackId
                
                pcall(function()
                    for _, track in next, hum:GetPlayingAnimationTracks() do
                        track:Stop()
                    end
                    
                    currentAnimTrack = hum:LoadAnimation(animation)
                    currentAnimTrack.Priority = Enum.AnimationPriority.Action4
                    currentAnimTrack:Play()
                    
                    local speed = Options.AnimSpeed.Value or 1
                    currentAnimTrack:AdjustSpeed(speed)

                    -- Dynamic loop frame range
                    local startPercent = (Options.AnimStart.Value or 0) / 100
                    local endPercent = (Options.AnimEnd.Value or 100) / 100
                    
                    if currentAnimTrack.Length > 0 then
                        currentAnimTrack.TimePosition = currentAnimTrack.Length * startPercent
                    end

                    animConnection = currentAnimTrack.Stopped:Connect(function()
                        if Toggles.AnimEnabled.Value and lp.Character == char then
                            playCustomAnim()
                        end
                    end)
                    
                    task.spawn(function()
                        while Toggles.AnimEnabled.Value and currentAnimTrack and currentAnimTrack.IsPlaying do
                            if currentAnimTrack.Length > 0 then
                                local curr = currentAnimTrack.TimePosition / currentAnimTrack.Length
                                if curr >= endPercent then
                                    currentAnimTrack.TimePosition = currentAnimTrack.Length * startPercent
                                end
                            end
                            task.wait(0.05)
                        end
                    end)
                end)
            end

            Toggles.AnimEnabled:OnChanged(playCustomAnim)
            Options.AnimPreset:OnChanged(playCustomAnim)
            Options.CustomAnimID:OnChanged(playCustomAnim)
            Options.AnimSpeed:OnChanged(function()
                if currentAnimTrack then
                    pcall(function() currentAnimTrack:AdjustSpeed(Options.AnimSpeed.Value) end)
                end
            end)
            Options.AnimStart:OnChanged(playCustomAnim)
            Options.AnimEnd:OnChanged(playCustomAnim)

            Library:Track(lp.CharacterAdded:Connect(function(char)
                char:WaitForChild("Humanoid")
                task.wait(0.5)
                if Toggles.AnimEnabled and Toggles.AnimEnabled.Value then
                    playCustomAnim()
                end
            end))
        end

        -- Spoofer Logic
        do
            local imagetable = {
                ["DESKTOP"] = "rbxassetid://17136633356",
                ["MOBILE"] = "rbxassetid://17136633510",
                ["CONSOLE"] = "rbxassetid://17136633629",
                ["VR"] = "rbxassetid://17136765745"
            }

            local spoofedData = nil
            local lastSpoofedData = nil

            local function applyIdentityToCharacter(char, data)
                if not char or not data then return end
                pcall(function()
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local appearance = playersService:GetCharacterAppearanceAsync(data.id or data.Id)
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                            v:Destroy()
                        end
                    end
                    for _, v in pairs(appearance:GetChildren()) do
                        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                            v.Parent = char
                        elseif v:IsA("Accessory") then
                            hum:AddAccessory(v)
                        end
                    end
                end)
            end

            _G.axis_ApplySpoofIdentity = function()
                local victim = Options.SpoofVictimID and Options.SpoofVictimID.Value
                if not victim or victim == "" or victim == "1" then return end

                task.spawn(function()
                    Notify("Fetching data for ID: " .. tostring(victim) .. "...", 3)

                    local success, data = pcall(function()
                        return game:GetService("HttpService"):JSONDecode(
                            game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(victim))
                        )
                    end)

                    if not (success and data and (data.id or data.Id)) then
                        Notify("Failed to fetch UserID. The game might be blocking the request.", 3)
                        lastSpoofedData = nil
                        return
                    end

                    spoofedData = data
                    local me = lp

                    pcall(function()
                        me.Name = data.name
                        me.UserId = data.id
                        me.CharacterAppearanceId = data.id
                        me.DisplayName = data.displayName
                    end)

                    -- Appearance fetch in its own nested spawn so it never hitches
                    task.spawn(function()
                        pcall(function()
                            if not me.Character then return end
                            local hum = me.Character:FindFirstChildOfClass("Humanoid")
                            if not hum then return end

                            local appearance = playersService:GetCharacterAppearanceAsync(data.id)
                            for _, v in pairs(me.Character:GetChildren()) do
                                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                                    v:Destroy()
                                end
                            end
                            for _, v in pairs(appearance:GetChildren()) do
                                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                                    v.Parent = me.Character
                                elseif v:IsA("Accessory") then
                                    hum:AddAccessory(v)
                                end
                            end

                            local oldParent = me.Character.Parent
                            me.Character.Parent = nil
                            me.Character.Parent = oldParent
                        end)
                    end)

                    lastSpoofedData = data
                    Notify("Identity Applied: " .. (data.displayName or data.name or "Unknown"), 3)
                end)
            end

            -- Auto-Refresh Identity Loop
            task.spawn(function()
                while Library.Running do
                    task.wait(5)
                    if not Library.Running then break end
                    if Toggles.AutoRefreshIdentity and Toggles.AutoRefreshIdentity.Value then
                        if lastSpoofedData then
                            task.spawn(function()
                                if not Library.Running then return end
                                pcall(function()
                                    applyIdentityToCharacter(lp.Character, lastSpoofedData)
                                end)
                            end)
                        end
                    end
                end
            end)

            -- UI icons cleaning might still be useful but most was tied to stats loop. 
            -- For now removing the loop entirely as requested.

            -- Performance / Optimization Logic
            local function boostFPS(v)
                local enabled = Toggles.FPSBoostEnabled.Value
                
                -- Compatibility Filter: Ignore other cheats/drawings
                local name = v.Name:lower()
                if name:find("fov") or name:find("circle") or name:find("esp") or name:find("drawing") or name:find("crosshair") or name:find("aim") or name:find("target") then
                    return
                end

                if enabled then
                    -- 3D World Optimization
                    if v:IsA("Texture") or v:IsA("Decal") then
                        if not v:GetAttribute("Axis_OrigTex") then v:SetAttribute("Axis_OrigTex", v.Texture) end
                        v.Texture = ""
                        v.Transparency = 1
                    elseif v:IsA("MeshPart") then
                        if not v:GetAttribute("Axis_OrigMat") then v:SetAttribute("Axis_OrigMat", v.Material.Name) end
                        if not v:GetAttribute("Axis_OrigTex") then v:SetAttribute("Axis_OrigTex", v.TextureID) end
                        v.Material = Enum.Material.SmoothPlastic
                        v.Reflectance = 0
                        v.TextureID = ""
                    elseif v:IsA("Part") or v:IsA("WedgePart") or v:IsA("CornerWedgePart") then
                        if not v:GetAttribute("Axis_OrigMat") then v:SetAttribute("Axis_OrigMat", v.Material.Name) end
                        v.Material = Enum.Material.SmoothPlastic
                        v.Reflectance = 0
                    -- HUD (UI) Optimization
                    elseif v:IsA("ImageLabel") or v:IsA("ImageButton") or v:IsA("UIGradient") or v:IsA("UIStroke") then
                        local isGameHUD = v:FindFirstAncestor("MainGui") or v:FindFirstAncestor("HUD") or v:FindFirstAncestor("MainFrame")
                        local isCoreGui = v:FindFirstAncestorWhichIsA("CoreGui")
                        
                        if isGameHUD and not isCoreGui then
                            if v:IsA("ImageLabel") or v:IsA("ImageButton") then
                                if not v:GetAttribute("Axis_OrigImage") then v:SetAttribute("Axis_OrigImage", v.Image) end
                                v.Image = ""
                            else
                                if not v:GetAttribute("Axis_OrigEnabled") then v:SetAttribute("Axis_OrigEnabled", tostring(v.Enabled)) end
                                v.Enabled = false
                            end
                        end
                    elseif v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                        if not v:GetAttribute("Axis_OrigEnabled") then v:SetAttribute("Axis_OrigEnabled", tostring(v.Enabled)) end
                        v.Enabled = false
                    end
                else
                    -- Restoration Logic
                    pcall(function()
                        if v:GetAttribute("Axis_OrigTex") then
                            if v:IsA("MeshPart") then v.TextureID = v:GetAttribute("Axis_OrigTex") 
                            else v.Texture = v:GetAttribute("Axis_OrigTex") end
                            v:SetAttribute("Axis_OrigTex", nil)
                        end
                        if v:GetAttribute("Axis_OrigMat") then
                            v.Material = Enum.Material[v:GetAttribute("Axis_OrigMat")]
                            v:SetAttribute("Axis_OrigMat", nil)
                        end
                        if v:GetAttribute("Axis_OrigImage") then
                            v.Image = v:GetAttribute("Axis_OrigImage")
                            v:SetAttribute("Axis_OrigImage", nil)
                        end
                        if v:GetAttribute("Axis_OrigEnabled") then
                            v.Enabled = (v:GetAttribute("Axis_OrigEnabled") == "true")
                            v:SetAttribute("Axis_OrigEnabled", nil)
                        end
                    end)
                end
            end

            Toggles.FPSBoostEnabled:OnChanged(function()
                task.spawn(function()
                    pcall(function()
                        local descendants = game:GetDescendants()
                        for i, v in ipairs(descendants) do
                            pcall(boostFPS, v)
                            if i % 1000 == 0 then task.wait() end -- Yield to prevent freeze
                        end
                    end)
                end)
            end)

            -- Only hook newly added descendants when FPS Boost is actually ON
            -- (previously this fired for every object in the entire game all the time)
            table.insert(earlyConnections, game.DescendantAdded:Connect(function(v)
                if Toggles.FPSBoostEnabled.Value then
                    pcall(boostFPS, v)
                end
            end))

            -- Capture real identity for cleaner brute-forcing
            local realDisplayName = lp.DisplayName
            local realName = lp.Name

            -- Safe Identity Hooks (Ultra-Targeted)
            local function updateIdentityProperties()
                if not Toggles.CustomNameEnabled.Value then return end
                local customName = Options.CustomNameValue.Value
                
                pcall(function()
                    lp.DisplayName = customName
                    lp.Name = customName
                    lp:SetAttribute("DisplayName", customName)
                    lp:SetAttribute("Display Name", customName)
                    lp:SetAttribute("Nickname", customName)
                end)

                -- Brute force CoreGui (Roblox ESC Menu)
                pcall(function()
                    local CoreGui = game:GetService("CoreGui")
                    -- Names of common labels in the ESC menu
                    for _, v in ipairs(CoreGui:GetDescendants()) do
                        if v:IsA("TextLabel") then
                            if v.Text == realDisplayName or v.Text == realName or v.Text:find(realDisplayName) then
                                v.Text = customName
                            end
                        end
                    end
                end)
            end

            --[[
            Toggles.CustomNameEnabled:OnChanged(updateIdentityProperties)
            Options.CustomNameValue:OnChanged(updateIdentityProperties)

            -- Continuous Enlightenment Loop (Ensures CoreGui reflects changes)
            task.spawn(function()
                while true do
                    if Toggles.CustomNameEnabled and Toggles.CustomNameEnabled.Value then
                        pcall(updateIdentityProperties)
                    end
                    task.wait(1) -- High speed sync
                end
            end)
            --]]
        end

        pcall(function()
            local oldIndex
            oldIndex = hookmetamethod(lp, "__index", newcclosure(LPH_NO_VIRTUALIZE(function(self, key)
                local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                if not checkcaller() and rawequal(self, lp) then
                    if dynToggles and dynToggles.CustomNameEnabled and dynToggles.CustomNameEnabled.Value then
                        if key == "DisplayName" or key == "Name" then
                            local dynOptions = getgenv().Options or _G.Options or Options
                            return dynOptions and dynOptions.CustomNameValue and dynOptions.CustomNameValue.Value or "Axis User"
                        end
                    end
                end
                return oldIndex(self, key)
            end)))
            
            local oldAttr
            oldAttr = hookmetamethod(lp, "GetAttribute", newcclosure(LPH_NO_VIRTUALIZE(function(self, key)
                local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                if not checkcaller() and rawequal(self, lp) then
                    if dynToggles and dynToggles.CustomNameEnabled and dynToggles.CustomNameEnabled.Value then
                        local k = tostring(key)
                        if k == "DisplayName" or k == "Display Name" or k == "Nickname" then
                            local dynOptions = getgenv().Options or _G.Options or Options
                            return dynOptions and dynOptions.CustomNameValue and dynOptions.CustomNameValue.Value or "Axis User"
                        end
                    end
                end
                return oldAttr(self, key)
            end)))

            -- Add Namecall support for :GetAttribute and :GetName
            local oldNamecall
            oldNamecall = hookmetamethod(lp, "__namecall", newcclosure(LPH_NO_VIRTUALIZE(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if not checkcaller() and rawequal(self, lp) then
                    local dynToggles = getgenv().Toggles or _G.Toggles or Toggles
                    if dynToggles and dynToggles.CustomNameEnabled and dynToggles.CustomNameEnabled.Value then
                        if method == "GetAttribute" and (args[1] == "DisplayName" or args[1] == "Display Name") then
                            local dynOptions = getgenv().Options or _G.Options or Options
                            return dynOptions and dynOptions.CustomNameValue and dynOptions.CustomNameValue.Value or "Axis User"
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)))
        end)

        -- ============================================================
        -- No Vignette & Sound Swapper Logic
        -- ============================================================
        do
            local VIGNETTE_ASSET = "14824249410"

            local function removeVignette(obj)
                pcall(function()
                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        if obj.Image:find(VIGNETTE_ASSET) then
                            obj.Image = ""
                            obj.Visible = false
                        end
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        if obj.Texture:find(VIGNETTE_ASSET) then
                            obj.Texture = ""
                        end
                    end
                end)
            end

            local function scanAndRemoveVignette()
                local descendants = game:GetDescendants()
                for i, obj in ipairs(descendants) do
                    removeVignette(obj)
                    if i % 1000 == 0 then task.wait() end -- Yield to prevent freeze
                end
            end

            Toggles.NoVignette:OnChanged(function()
                if Toggles.NoVignette.Value then
                    task.spawn(scanAndRemoveVignette)
                end
            end)

            table.insert(earlyConnections, game.DescendantAdded:Connect(function(child)
                if Toggles.NoVignette and Toggles.NoVignette.Value then
                    removeVignette(child)
                end
            end))

            -- Sound Swapper Logic
            local customAudioMap = {
                ["Water"] = "97441656169056",
                ["Sweep"] = "108650930455865",
                ["Coin"] = "104984663188968",
                ["Agoui"] = "132466801508072",
                ["Crystal"] = "102678667660412",
                ["Water Drop"] = "110808739139073",
                ["Apakill"] = "133688008696899",
                ["Fatality"] = "106586644436584",
                ["Primordial"] = "85340682645435",
                ["Bameware"] = "92614567965693",
                ["Gamesense"] = "81045011794709",
                ["Neverlose"] = "97643101798871",
                ["Rifk7"] = "76064874887167",
                ["Bameware Mouse Click"] = "89535599673191"
            }

            local function handleSound(obj)
                if not Toggles.SoundSwapperEnabled or not Toggles.SoundSwapperEnabled.Value then return end
                if not obj:IsA("Sound") then return end

                local bodySelect = Options.SoundHitBody and Options.SoundHitBody.Value or "Default"
                local headSelect = Options.SoundHitHead and Options.SoundHitHead.Value or "Default"
                local killSelect = Options.SoundKill and Options.SoundKill.Value or "Default"
                local elimSelect = Options.SoundEliminated and Options.SoundEliminated.Value or "Default"

                local s1 = customAudioMap[killSelect]
                local s2 = customAudioMap[headSelect]
                local s3 = customAudioMap[elimSelect]
                local s4 = customAudioMap[bodySelect]

                local soundMapping = {
                    ["16530229616"] = s1, ["16530229541"] = s1, ["16530229695"] = s1,
                    ["16537337310"] = s2, ["16537449730"] = s2,
                    ["16810041280"] = s3,
                    ["13110130082"] = s4
                }

                for target, replacement in pairs(soundMapping) do
                    if replacement and obj.SoundId:find(target) then
                        obj.SoundId = "rbxassetid://" .. tostring(replacement)
                        break
                    end
                end
            end

            local function scanAndSwapAllSounds()
                local descendants = game:GetDescendants()
                for i, obj in ipairs(descendants) do
                    pcall(handleSound, obj)
                    if i % 1000 == 0 then task.wait() end -- Yield to prevent freeze
                end
            end

            Toggles.SoundSwapperEnabled:OnChanged(function()
                if Toggles.SoundSwapperEnabled.Value then
                    task.spawn(scanAndSwapAllSounds)
                end
            end)

            table.insert(earlyConnections, game.DescendantAdded:Connect(function(child)
                if Toggles.SoundSwapperEnabled and Toggles.SoundSwapperEnabled.Value then
                    pcall(handleSound, child)
                end
            end))

            -- Listen for real-time changes to the dropdowns
            task.spawn(function()
                local function onSoundChange()
                    if Toggles.SoundSwapperEnabled and Toggles.SoundSwapperEnabled.Value then
                        task.spawn(scanAndSwapAllSounds)
                    end
                end
                task.wait(1) -- wait for options to initialize fully
                if Options.SoundHitBody then Options.SoundHitBody:OnChanged(onSoundChange) end
                if Options.SoundHitHead then Options.SoundHitHead:OnChanged(onSoundChange) end
                if Options.SoundKill then Options.SoundKill:OnChanged(onSoundChange) end
                if Options.SoundEliminated then Options.SoundEliminated:OnChanged(onSoundChange) end
            end)
        end

        Library:OnUnload(function()
            _G.axis_VoidHide_Loaded = nil
            stopCurrentAnim()
            pcall(function()
                if raknet then raknet.remove_send_hook(rakhook) end
            end)
            rs:UnbindFromRenderStep("tp_snapback")
            rs:UnbindFromRenderStep("ResolutionOverride")
            pcall(function() if Weather.Part then Weather.Part:Destroy() end end)
            -- Cleanup UI scales
            pcall(function()
                for _, gui in ipairs(lp.PlayerGui:GetChildren()) do
                    if gui:FindFirstChild("AxisResScale") then
                        gui.AxisResScale:Destroy()
                    end
                end
            end)

        end)

        -- ── Matchmaking / Party Social Logic ─────────────────────
        local partyLeaderOpt = Options.PartyLeader
        local altUsernamesOpt = Options.AltUsernames
        task.defer(function()
            while Library.Running do
                task.wait(5)
                pcall(function()
                    if not Library.Running then return end
                    local leader = partyLeaderOpt and partyLeaderOpt.Value
                    local altsRaw = altUsernamesOpt and altUsernamesOpt.Value
                    if not leader or leader == "" then return end
                    
                    local alts = {}
                    if altsRaw then
                        for s in string.gmatch(altsRaw, '([^,]+)') do
                            table.insert(alts, string.gsub(s, "^%s*(.-)%s*$", "%1"))
                        end
                    end

                    local mmRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Matchmaking")
                    if not mmRemote then return end

                    -- Leader Logic: Invite Alts
                    if lp.Name == leader then
                        for _, username in ipairs(alts) do
                            local target = game:GetService("Players"):FindFirstChild(username)
                            if target then
                                local sendInvite = mmRemote:FindFirstChild("SendPartyInvite")
                                if sendInvite then sendInvite:FireServer(target) end
                            end
                        end
                    end

                    -- Alt Logic: Accept Leader Invite
                    if table.find(alts, lp.Name) then
                        local mainPlayer = game:GetService("Players"):FindFirstChild(leader)
                        if mainPlayer then
                            local acceptInvite = mmRemote:FindFirstChild("AcceptPartyInvite")
                            if acceptInvite then acceptInvite:FireServer(mainPlayer) end
                        end
                    end
                end)
            end
        end)

        -- ── Rivals Staff Detector ──────────────────────────────────
        xpcall(function()
            if (game.GameId ~= 6035872082) then return end
            
            local players = game:GetService("Players")
            local coregui = (gethui and gethui()) or game:GetService("CoreGui")
            local http = game:GetService("HttpService")
            local groupId = game.CreatorId
            local notify_sound = nil
            local CACHE_FILE = "axis/assets/staffcache_" .. groupId .. ".json"

            if game.CreatorType ~= Enum.CreatorType.Group then return end

            task.spawn(function()
                pcall(function()
                    if not isfile("axis/assets/staffdetect.mp3") then 
                        writefile("axis/assets/staffdetect.mp3", tostring(game:HttpGetAsync("https://github.com/Ukrubojvo/api/raw/main/alert.mp3"))) 
                    end
                    notify_sound = Instance.new("Sound", workspace)
                    notify_sound.SoundId = (getcustomasset and getcustomasset("axis/assets/staffdetect.mp3")) or "rbxassetid://4590662766"
                    notify_sound.Volume = 5
                    notify_sound.Looped = true
                end)
            end)

            local function fetchUsersInRole(gId, rId)
                local collected = {}
                pcall(function()
                    local url = string.format("https://groups.roproxy.com/v1/groups/%d/roles/%d/users?limit=100", gId, rId)
                    local res = game:HttpGet(url)
                    local json = http:JSONDecode(res)
                    if json.data then
                        for _, user in ipairs(json.data) do collected[user.userId] = true end
                    end
                end)
                return collected
            end

            local function isStaffRoleName(role)
                if not role then return false end
                local r = string.lower(role)
                return string.find(r, "mod") or string.find(r, "staff") or string.find(r, "contributor") or string.find(r, "script") or string.find(r, "build")
            end

            local detectionRunning = false
            local function runDetection()
                if detectionRunning then return end
                if not Toggles.StaffDetector.Value then return end
                detectionRunning = true
                task.spawn(function()
                    local staffFound = false
                    local detectedNames = {}
                    local pending = 0
                    for _, plr in ipairs(players:GetPlayers()) do
                        pending += 1
                        task.spawn(function()
                            pcall(function()
                                local role = plr:GetRoleInGroup(groupId)
                                if isStaffRoleName(role) then
                                    staffFound = true
                                    table.insert(detectedNames, plr.Name)
                                end
                            end)
                            pending -= 1
                        end)
                    end
                    -- Wait for all GetRoleInGroup calls to complete
                    while pending > 0 do task.wait(0.1) end
                    if staffFound then
                        if Toggles.AutoLeaveStaff.Value then
                            lp:Kick("[axis] Moderator Detected: " .. table.concat(detectedNames, ", "))
                        elseif Toggles.StaffDetectorAlert and Toggles.StaffDetectorAlert.Value then
                            Notify("MODERATOR DETECTED: " .. table.concat(detectedNames, ", "), 10)
                            if notify_sound then notify_sound:Play() end
                        end
                    end
                    detectionRunning = false
                end)
            end

            Library:Track(players.PlayerAdded:Connect(function(plr)
                task.wait(2) -- Increased wait to let player fully load
                if Toggles.StaffDetector.Value then runDetection() end
            end))
            
            local staffTog = Toggles.StaffDetector
            task.spawn(function()
                while scriptActive do
                    task.wait(30)
                    if not Library.Running then break end
                    if staffTog and staffTog.Value then runDetection() end
                end
            end)
        end, function(err) warn("Staff Detector Error: " .. tostring(err)) end)

        -- Resolution & UI Scaling Logic
        local function updateResolutionEffect()
            local res = Options.CameraResolution.Value
            local Camera = workspace.CurrentCamera
            
            -- 1. Camera Bind (High Priority)
            pcall(function()
                rs:UnbindFromRenderStep("ResolutionOverride")
                if res < 1 then
                    rs:BindToRenderStep("ResolutionOverride", Enum.RenderPriority.Camera.Value + 1, function()
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, res, 0, 0, 0, 1)
                    end)
                end
            end)
            
            -- 2. UI Scaling
            pcall(function()
                for _, gui in ipairs(lp.PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        local scale = gui:FindFirstChild("AxisResScale") or Instance.new("UIScale")
                        scale.Name = "AxisResScale"
                        -- Reverse the stretch effect for UI so it stays readable but fits the wider look
                        scale.Scale = res
                        scale.Parent = gui
                    end
                end
            end)
        end

        Options.CameraResolution:OnChanged(updateResolutionEffect)

        -- Spotify Widget Logic
        local spotifyWidget = nil
        local function createSpotifyWidget()
            if spotifyWidget then spotifyWidget:Destroy() end
            
            local gui = Instance.new("ScreenGui")
            gui.Name = "AxisSpotify"
            gui.ResetOnSpawn = false
            gui.Parent = lp:WaitForChild("PlayerGui")
            
            local main = Instance.new("Frame")
            main.Name = "Main"
            main.Size = UDim2.new(0, 240, 0, 70)
            main.Position = UDim2.new(0.8, 0, 0.8, 0)
            main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            main.BorderSizePixel = 0
            main.BackgroundTransparency = 0.2
            main.Parent = gui
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = main
            
            -- Draggable logic
            local dragging, dragStart, startPos
            main.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = main.Position
                end
            end)
            main.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            Library:Track(uis.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Position - dragStart
                    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end))
            
            local art = Instance.new("ImageLabel")
            art.Name = "Art"
            art.Size = UDim2.new(0, 50, 0, 50)
            art.Position = UDim2.new(0, 10, 0, 10)
            art.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            art.BorderSizePixel = 0
            art.Parent = main
            Instance.new("UICorner", art).CornerRadius = UDim.new(0, 4)
            
            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(1, -75, 0, 20)
            title.Position = UDim2.new(0, 65, 0, 12)
            title.Text = "Not Playing"
            title.TextColor3 = Color3.new(1, 1, 1)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 14
            title.BackgroundTransparency = 1
            title.Parent = main
            
            local artist = Instance.new("TextLabel")
            artist.Name = "Artist"
            artist.Size = UDim2.new(1, -75, 0, 15)
            artist.Position = UDim2.new(0, 65, 0, 28)
            artist.Text = "Spotify"
            artist.TextColor3 = Color3.fromRGB(180, 180, 180)
            artist.TextXAlignment = Enum.TextXAlignment.Left
            artist.Font = Enum.Font.Gotham
            artist.TextSize = 12
            artist.BackgroundTransparency = 1
            artist.Parent = main
            
            local progBg = Instance.new("Frame")
            progBg.Name = "ProgBg"
            progBg.Size = UDim2.new(1, -75, 0, 4)
            progBg.Position = UDim2.new(0, 65, 0, 48)
            progBg.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            progBg.BackgroundTransparency = 0.5
            progBg.BorderSizePixel = 0
            progBg.Parent = main
            Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 2)
            
            local prog = Instance.new("Frame")
            prog.Name = "Prog"
            prog.Size = UDim2.new(0, 0, 1, 0)
            prog.BackgroundColor3 = Color3.fromRGB(30, 215, 96) -- Spotify Green
            prog.BorderSizePixel = 0
            prog.Parent = progBg
            Instance.new("UICorner", prog).CornerRadius = UDim.new(0, 2)
            
            spotifyWidget = gui
        end

        task.spawn(function()
            while Library.Running do
                task.wait(5) -- Poll every 5s instead of 1s to reduce executor load
                if not Library.Running or not (Toggles.SpotifyWidgetEnabled and Toggles.SpotifyWidgetEnabled.Value) then
                    if spotifyWidget then 
                        spotifyWidget:Destroy()
                        spotifyWidget = nil
                    end
                    continue
                end

                if not spotifyWidget then createSpotifyWidget() end

                local discordID = Options.SpotifyDiscordID.Value
                if discordID == "" then continue end

                -- Fire HTTP in isolated thread so it can NEVER block the game
                task.spawn(function()
                    pcall(function()
                        local response = game:HttpGet("https://api.lanyard.rest/v1/users/" .. discordID)
                        local data = game:GetService("HttpService"):JSONDecode(response).data
                        if not data then return end

                        if data.discord_user then
                            spotifyWidget.Main.Title.Text = data.discord_user.username:upper()
                        end

                        local sf = data.spotify

                        if data.activities then
                            for _, v in ipairs(data.activities) do
                                if v.name == "Spotify" or v.type == 2 or (v.details and v.details:gsub("%s", ""):find("Spotify")) then
                                    sf = sf or {}
                                    sf.song = sf.song or v.details
                                    sf.artist = sf.artist or v.state
                                    sf.timestamps = sf.timestamps or v.timestamps
                                    if not sf.album_art_url and v.assets and v.assets.large_image then
                                        local artId = v.assets.large_image
                                        if artId:find("spotify:") then
                                            sf.album_art_url = "https://i.scdn.co/image/" .. artId:gsub("spotify:", "")
                                        else
                                            local appId = v.application_id or "306915641241763840"
                                            sf.album_art_url = "https://cdn.discordapp.com/app-assets/" .. appId .. "/" .. artId .. ".png"
                                        end
                                    end
                                    if sf.song then break end
                                end
                            end
                        end

                        if not spotifyWidget then return end -- widget may have been destroyed
                        if sf and sf.song then
                            spotifyWidget.Main.Visible = true
                            spotifyWidget.Main.Title.Text = sf.song
                            spotifyWidget.Main.Artist.Text = sf.artist or "Spotify"
                            spotifyWidget.Main.Art.Image = sf.album_art_url or ""
                            if sf.timestamps then
                                local endTime = sf.timestamps["end"] or sf.timestamps.stop or sf.timestamps.finish
                                if endTime then
                                    local total = endTime - sf.timestamps.start
                                    local current = (tick() * 1000) - sf.timestamps.start
                                    local percent = math.clamp(current / total, 0, 1)
                                    spotifyWidget.Main.ProgBg.Prog.Visible = true
                                    spotifyWidget.Main.ProgBg.Prog.Size = UDim2.new(percent, 0, 1, 0)
                                else
                                    spotifyWidget.Main.ProgBg.Prog.Visible = false
                                end
                            else
                                spotifyWidget.Main.ProgBg.Prog.Visible = false
                            end
                        else
                            spotifyWidget.Main.Artist.Text = "Not Listening"
                            spotifyWidget.Main.Art.Image = ""
                            spotifyWidget.Main.ProgBg.Prog.Visible = false
                        end
                    end)
                end)
            end
        end)


        -- ── Event-Driven Jump Shard & Tripmine Detonator ──────────────────
        local activeShardsAndTripmines = {}
        
        local function checkShardOrTripmine(obj)
            local name = obj.Name
            local lowerName = name:lower()
            if lowerName == "jumpshard" or name == "subspacetripminehitbox" then
                task.defer(function()
                    if not obj.Parent then return end
                    local hitbox = obj:FindFirstChild("Hitbox") or obj:FindFirstChildWhichIsA("BasePart") or obj
                    if hitbox then
                        activeShardsAndTripmines[obj] = {
                            Hitbox = hitbox,
                            IsShard = (lowerName == "jumpshard")
                        }
                    end
                end)
            end
        end

        Library:Track(workspace.ChildAdded:Connect(function(child)
            pcall(checkShardOrTripmine, child)
        end))
        
        Library:Track(workspace.ChildRemoved:Connect(function(child)
            activeShardsAndTripmines[child] = nil
        end))

        for _, child in ipairs(workspace:GetChildren()) do
            pcall(checkShardOrTripmine, child)
        end

        Library:Track(rs.Heartbeat:Connect(function()
            if not Library.Running then return end
            local shardEnabled = Toggles.AutoJumpShard and Toggles.AutoJumpShard.Value
            local tripmineEnabled = Toggles.SubspaceTripmine and Toggles.SubspaceTripmine.Value
            if not (shardEnabled or tripmineEnabled) then return end

            pcall(function()
                local myChar = lp.Character
                local hrp    = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for obj, info in pairs(activeShardsAndTripmines) do
                    if obj and obj.Parent then
                        if (info.IsShard and shardEnabled) or (not info.IsShard and tripmineEnabled) then
                            local hitbox = info.Hitbox
                            if hitbox then
                                firetouchinterest(hrp, hitbox, 1)
                                firetouchinterest(hrp, hitbox, 0)
                            end
                        end
                    else
                        activeShardsAndTripmines[obj] = nil
                    end
                end
            end)
        end))


        -- ── Auto Jump Shard ────────────────────────────────────────
        Library:Track(workspace.DescendantAdded:Connect(function(s)
            if not Toggles.AutoJumpShard or not Toggles.AutoJumpShard.Value then return end
            if s.Name:lower() == "jumpshard" then
                pcall(function()
                    local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not r then return end
                    local hitbox = s:FindFirstChild("Hitbox") or s
                    firetouchinterest(r, hitbox, 1)
                    firetouchinterest(r, hitbox, 0)
                end)
            end
        end))

        -- ── Instant Reload Bypass ─────────────────────────────────
        local function applyReloadBypass()
            pcall(function()
                local ItemLibrary = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
                local Items = rawget(ItemLibrary, "Items")
                if not Items then return end
                local WhitelistedItems = {"Bow", "Daggers", "Slingshot"}
                for _, Item in Items do
                    local Name = Item.Name
                    if not table.find(WhitelistedItems, Name) then continue end
                    if not Item["ReloadLength"] then continue end
                    rawset(Item, "ReloadLength", (Name == "Daggers" and 0.09 or 0))
                end
            end)
        end

        Toggles.ReloadBypass:OnChanged(function()
            if Toggles.ReloadBypass.Value then
                applyReloadBypass()
                Notify("Instant Reload: ON", 2)
            else
                Notify("Instant Reload: OFF (rejoin to restore)", 3)
            end
        end)

        Toggles.GlobalCooldownPatch:OnChanged(function(v)
            if _G.applyCooldownPatch then
                _G.applyCooldownPatch(v)
                if v then
                    Notify("Global Cooldown Patch: ON", 2)
                else
                    Notify("Global Cooldown Patch: OFF", 2)
                end
            end
        end)

        -- ── Custom Table Attribute Toggle Feature (Lag-Free Active Weapons Engine) ──
        Toggles.WeaponModsAll:OnChanged(function(v)
            pcall(function()
                if localWeaponInstances then
                    for inst in pairs(localWeaponInstances) do
                        applyWeaponInstanceMods(inst, v)
                    end
                end
                if v then
                    toggleTableAttribute("ShootCooldown", 0)
                    toggleTableAttribute("ShootSpread", 0)
                    toggleTableAttribute("ShootRecoil", 0)
                else
                    restoreTableAttribute("ShootCooldown")
                    restoreTableAttribute("ShootSpread")
                    restoreTableAttribute("ShootRecoil")
                end
            end)
            if v then
                Notify("Weapon Modifications: ON", 2)
            else
                Notify("Weapon Modifications: OFF", 2)
            end
        end)



        --[[
        -- ============================================================
        -- SKIN CHANGER (adapted from Aybrix / 1pw3gu)
        -- ============================================================
        do
            local ef = table.insert

            -- Services (local to this scope to avoid collisions)
            local HttpService      = game:GetService("HttpService")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Lighting          = game:GetService("Lighting")

            -- Aliases matching the original variable names
            local k  = lp
            local m  = k.Name
            local al = k.PlayerScripts.Assets.ViewModels

            -- ── Config ──────────────────────────────────────────────
            local f  = "axis/rivals/settings/SkinConfig"
            local e  = f .. "/default.json"
            local ai = {
                ActiveSkins      = {},
                CurrentMaterial  = "SmoothPlastic",
                MaterialEnabled  = false,
                Transparency     = 0,
            }

            local function da()
                if not isfolder('axis/rivals/settings') then return end
                if not isfolder(f) then makefolder(f) end
            end
            local function go()
                da()
                local cr = {
                    ActiveSkins     = ai.ActiveSkins,
                    CurrentMaterial = ai.CurrentMaterial,
                    MaterialEnabled = ai.MaterialEnabled,
                    Transparency    = ai.Transparency,
                }
                local fd, cz = pcall(HttpService.JSONEncode, HttpService, cr)
                if fd then writefile(e, cz) end
            end
            local function eo()
                da()
                if not isfile(e) then return end
                local fd, fu = pcall(readfile, e)
                if not fd or not fu or fu == "" then return end
                local fe, cr = pcall(HttpService.JSONDecode, HttpService, fu)
                if not fe or type(cr) ~= "table" then return end
                if type(cr.ActiveSkins)     == "table"   then ai.ActiveSkins     = cr.ActiveSkins     end
                if type(cr.CurrentMaterial) == "string"  then ai.CurrentMaterial = cr.CurrentMaterial end
                if type(cr.MaterialEnabled) == "boolean" then ai.MaterialEnabled = cr.MaterialEnabled end
                if type(cr.Transparency)    == "number"  then ai.Transparency    = cr.Transparency    end
            end
            eo()

            -- ── Weapon / Skin data ───────────────────────────────────
            local ao = {
                ["Assault Rifle"] = {"AK-47","AUG","Tommy Gun","Phoenix Rifle","Boneclaw Rifle","10B Visits","AKEY-47","Gingerbread AUG","Glorious Assault Rifle"},
                ["Bow"] = {"Compound Bow","Raven Bow","Dream Bow","Bat Bow","Frostbite Bow","Key Bow","Balloon Bow","Beloved Bow","Glorious Bow"},
                ["Burst Rifle"] = {"Aqua Burst","Electro Rifle","FAMAS","Pine Burst","Spectral Burst","Pixel Burst","Keyst Rifle","Glorious Burst Rifle"},
                ["Chainsaw"] = {"Blobsaw","Handsaws","Mega Drill","Buzzsaw","Festive Buzzsaw","Glorious Chainsaw"},
                ["RPG"] = {"Nuke Launcher","RPKEY","Spaceship Launcher","Pencil Launcher","Squid Launcher","Pumpkin Launcher","Firework Launcher","Rocket Launcher","Glorious RPG"},
                ["Exogun"] = {"Singularity","Wondergun","Exogourd","Ray Gun","Repulsor","Midnight Festive Exogun","Glorious Exogun"},
                ["Fists"] = {"Boxing Gloves","Brass Knuckles","Fists of Hurt","Festive Fists","Pumpkin Claws","Glorious Fists","Fist"},
                ["Flamethrower"] = {"Lamethrower","Pixel Flamethrower","Glitterthrower","Jack O' Thrower","Snowblower","Keythrower","Glorious Flamethrower","Rainbowthrower","Jack O'Thrower"},
                ["Flare Gun"] = {"Dynamite Gun","Firework Gun","Banana Flare","Wrapped Flare Gun","Vexed Flare Gun","Glorious Flare Gun"},
                ["Freeze Ray"] = {"Bubble Ray","Temporal Ray","Gum Ray","Wrapped Freeze Ray","Glorious Freeze Ray","Spider Ray"},
                ["Grenade"] = {"Water Balloon","Whoopee Cushion","Dynamite","Frozen Grenade","Spooky Grenade","Soul Grenade","Keynade","Cuddle Bomb","Jingle Grenade","Glorious Grenade"},
                ["Grenade Launcher"] = {"Swashbuckler","Uranium Launcher","Gearnade Launcher","Skull Launcher","Snowball Launcher","Balloon Launcher","Glorious Grenade Launcher"},
                ["Handgun"] = {"Blaster","Gumball Handgun","Pumpkin Handgun","Towerstone Handgun","Warp Handgun","Gingerbread Handgun","Pixel Handgun","Stealth Handgun","Glorious Handgun","Hand Gun"},
                ["Katana"] = {"Lightning Bolt","Saber","Stellar Katana","Ice Katana","Pixel Katana","New Years Katana","Arch Katana","Keytana","Crystal Katana","Linked Sword","Glorious Katana","New Year Katana","Evil Trident"},
                ["Minigun"] = {"Lasergun 3000","Pixel Minigun","Fighter Jet","Pumpkin Minigun","Wrapped Minigun","Glorious Minigun"},
                ["Paintball Gun"] = {"Boba Gun","Slime Gun","Ketchup Gun","Paintballoon Gun","Snowball Gun","Glorious Paintball Gun","Brain Gun"},
                ["Revolver"] = {"Sheriff","Desert Eagle","Peppergun","Boneclaw Revolver","Keyvolver","Peppermint Sheriff","Glorious Revolver"},
                ["Slingshot"] = {"Goalpost","Stick","Harp","Boneshot","Reindeer Slingshot","Glorious Slingshot","Lucky Horseshoe"},
                ["Subspace Tripmine"] = {"Don't Press","Spring","DIY Tripmine","Trick or Treat","Glorious Subspace Tripmine","Dev-in-the-Box","Pot o' Keys"},
                ["Uzi"] = {"Electro Uzi","Water Uzi","Money Gun","Pine Uzi","Keyzi","Demon Uzi","Glorious Uzi"},
                ["Sniper"] = {"Pixel Sniper","Hyper Sniper","Event Horizon","Eyething Sniper","Gingerbread Sniper","Keyper","Glorious Sniper"},
                ["Knife"] = {"Karambit","Chancla","Balisong","Machete","Keyrambit","Keylisong","Glorious Knife","Candy Cane","Armature.001","Caladbolg"},
                ["Shotgun"] = {"Balloon Shotgun","Cactus Shotgun","Wrapped Shotgun","Broomstick Shotgun","Hyper Shotgun","Shotkey","Glorious Shotgun","Broomstick"},
                ["Crossbow"] = {"Pixel Crossbow","Violin Crossbow","Crossbone","Harpoon Crossbow","Frostbite Crossbow","Arch Crossbow","Glorious Crossbow"},
                ["Daggers"] = {"Aces","Paper Planes","Shurikens","Bat Daggers","Cookies","Keynais","Crystal Daggers","Broken Hearts","Glorious Daggers"},
                ["Distortion"] = {"Plasma Distortion","Cyber Distortion","Magma Distortion","Electropunk Distortion","Sleighstortion","Glorious Distortion"},
                ["Energy Rifle"] = {"Hacker Rifle","Void Rifle","New Year Energy Rifle","Apex Rifle","Hydro Rifle","Soul Rifle","Glorious Energy Rifle"},
                ["Energy Pistols"] = {"Void Pistols","Hydro Pistols","New Years Energy Pistols","Soul Pistols","Hacker Pistols","Apex Pistols","Glorious Energy Pistols","New Year Energy Pistols","Hyperlaser Guns"},
                ["Gunblade"] = {"Hyper Gunblade","Gunsaw","Boneblade","Crude Gunblade","Elf's Gunblade","Glorious Gunblade"},
                ["Battle Axe"] = {"The Shred","Ban Axe","Cerulean Axe","Nordic Axe","Keytle Axe","Balloon Axe","Mimic Axe","Glorious Battleaxe","Glorious Battle Axe","Keyttle Axe"},
                ["Riot Shield"] = {"Door","Masterpiece","Sled","Tombstone Shield","Glorious Riot Shield","Energy Shield"},
                ["Scythe"] = {"Scythe of Death","Sakura Scythe","Bat Scythe","Keythe","Cryo Scythe","Crystal Scythe","Glorious Scythe","Anchor","Bug Net"},
                ["Trowel"] = {"Plastic Shovel","Paintbrush","Snow Shovel","Garden Shovel","Glorious Trowel","Pumpkin Carver"},
                ["Medkit"] = {"Sandwich","Medkitty","Shady Chicken Sandwich","Milk & Cookies","Glorious Medkit","Box of Chocolates","Briefcase","Bucket of Candy","Laptop"},
                ["Molotov"] = {"Coffee","Torch","Lava Lamp","Vexed Candle","Glorious Molotov","Arch Molotov","Hot Coals"},
                ["Satchel"] = {"Bag O' Money","Notebook Satchel","Suspicious Gift","Advanced Satchel","Potion Satchel","Glorious Satchel","Bag o' Money"},
                ["Smoke Grenade"] = {"Emoji Cloud","Balance","Hourglass","Glorious Smoke Grenade","Snowglobe","Eyeball"},
                ["War Horn"] = {"Trumpet","Air Horn","Megaphone","Mammoth Horn","Boneclaw Horn","Glorious War Horn"},
                ["Warpstone"] = {"Cyber Warpstone","Bonestone","Electropunk Warpstone","Warpbone","Unstable Warpstone","Glorious Warpstone","Experiment W4","Warpstar","Teleport Disc","Warpeye"},
                ["Flashbang"] = {"Pixel Flashbang","Skullbang","Glorious Flashbang","Lightbulb","Disco Ball","Shining Star","Camera"},
                ["Jump Pad"] = {"Glorious Jump Pad","Bounce House","Jolly Man","Spider Web","Trampoline"},
                ["Warper"] = {"Arcane Warper","Electropunk Warper","Frost Warper","Glitter Warper","Glorious Warper","Hotel Bell"},
                ["Shorty"] = {"Balloon Shorty","Demon Shorty","Lovely Shorty","Not So Shorty","Too Shorty","Wrapped Shorty","Glorious Shorty","Experiment D15"},
                ["Maul"] = {"Ice Maul","Sleigh Maul","Glorious Maul","Ban Hammer"},
                ["Spray"] = {"Boneclaw Spray","Key Spray","Lovely Spray","Pine Spray","Glorious Spray","Spray Bottle","Nail Gun"},
                ["Permafrost"] = {"Ice Permafrost","Snowman Permafrost","Glorious Permafrost"},
            }

            local l = {"Plastic","SmoothPlastic","Neon","Metal","Wood","WoodPlanks","Marble","Slate","Concrete","Granite","Brick","Pebble","Cobblestone","CorrodedMetal","DiamondPlate","Foil","Glass","Grass","Ice","Sand","Fabric","ForceField"}

            local af = {
                ["MISSING_WEAPON"]="rbxassetid://124519084257039",["MISSING_SKIN"]="rbxassetid://124519084257039",
                ["Medkit"]="rbxassetid://17160800734",["Sandwich"]="rbxassetid://17838232333",["Milk & Cookies"]="rbxassetid://99156135330432",["Medkitty"]="rbxassetid://125732280509514",["Glorious Medkit"]="rbxassetid://73358160718523",["Shady Chicken Sandwich"]="rbxassetid://86361684164972",
                ["Subspace Tripmine"]="rbxassetid://17160799418",["Don't Press"]="rbxassetid://17821233203",["Spring"]="rbxassetid://18766860615",["Trick or Treat"]="rbxassetid://101693036028491",["DIY Tripmine"]="rbxassetid://85747991601740",["Glorious Subspace Tripmine"]="rbxassetid://112555928142930",
                ["Flamethrower"]="rbxassetid://89455038280473",["Pixel Flamethrower"]="rbxassetid://17771752104",["Lamethrower"]="rbxassetid://18766862822",["Jack O' Thrower"]="rbxassetid://140280020818514",["Snowblower"]="rbxassetid://128743586418880",["Glitterthrower"]="rbxassetid://88920581735649",["Glorious Flamethrower"]="rbxassetid://71676635953177",["Keythrower"]="rbxassetid://130308634220965",
                ["Grenade"]="rbxassetid://17160801411",["Whoopee Cushion"]="rbxassetid://17672062933",["Water Balloon"]="rbxassetid://18766859819",["Soul Grenade"]="rbxassetid://85903097459179",["Jingle Grenade"]="rbxassetid://97646859596860",["Dynamite"]="rbxassetid://119066463640901",["Keynade"]="rbxassetid://102785971311114",["Glorious Grenade"]="rbxassetid://103034870490455",["Frozen Grenade"]="rbxassetid://96120996159611",["Cuddle Bomb"]="rbxassetid://116801887274189",["Spooky Grenade"]="rbxassetid://85903097459179",
                ["Molotov"]="rbxassetid://109264750627289",["Coffee"]="rbxassetid://17672061538",["Torch"]="rbxassetid://115586189235552",["Vexed Candle"]="rbxassetid://78128648928195",["Lava Lamp"]="rbxassetid://79616583726432",["Glorious Molotov"]="rbxassetid://108930340066987",
                ["Flashbang"]="rbxassetid://17160801529",["Pixel Flashbang"]="rbxassetid://132815625474597",["Skullbang"]="rbxassetid://73796957224972",["Glorious Flashbang"]="rbxassetid://96760506528185",
                ["Smoke Grenade"]="rbxassetid://17160799767",["Emoji Cloud"]="rbxassetid://17821234077",["Balance"]="rbxassetid://18766866168",["Hourglass"]="rbxassetid://108311418974073",["Glorious Smoke Grenade"]="rbxassetid://139714146508398",
                ["Fists"]="rbxassetid://17160801745",["Boxing Gloves"]="rbxassetid://17672060486",["Brass Knuckles"]="rbxassetid://18766866012",["Pumpkin Claws"]="rbxassetid://90996407819750",["Festive Fists"]="rbxassetid://102757458529795",["Fists of Hurt"]="rbxassetid://140103672289959",["Glorious Fists"]="rbxassetid://82492165200104",
                ["Knife"]="rbxassetid://17160800983",["Chancla"]="rbxassetid://17672060795",["Karambit"]="rbxassetid://18766863586",["Machete"]="rbxassetid://84364955819899",["Balisong"]="rbxassetid://93303458333011",["Glorious Knife"]="rbxassetid://77448895595314",["Keyrambit"]="rbxassetid://108512337101248",["Keylisong"]="rbxassetid://100084654831857",
                ["Chainsaw"]="rbxassetid://17160801873",["Blobsaw"]="rbxassetid://17825963589",["Handsaws"]="rbxassetid://18766864583",["Buzzsaw"]="rbxassetid://74057448201836",["Festive Buzzsaw"]="rbxassetid://80811854818775",["Mega Drill"]="rbxassetid://76663867023998",["Glorious Chainsaw"]="rbxassetid://122622447397834",
                ["Katana"]="rbxassetid://17160801158",["Saber"]="rbxassetid://17672062341",["Lightning Bolt"]="rbxassetid://18768968241",["Pixel Katana"]="rbxassetid://127922483074145",["New Years Katana"]="rbxassetid://102866488046710",["Keytana"]="rbxassetid://118899310989170",["Stellar Katana"]="rbxassetid://72617738655198",["Glorious Katana"]="rbxassetid://75588958786035",["Arch Katana"]="rbxassetid://94679283541658",["Crystal Katana"]="rbxassetid://88872493010693",["Linked Sword"]="rbxassetid://83575725004177",["Ice Katana"]="rbxassetid://72617738655198",
                ["Scythe"]="rbxassetid://17160800186",["Scythe of Death"]="rbxassetid://17825996537",["Keythe"]="rbxassetid://114560926055433",["Bat Scythe"]="rbxassetid://131711174838548",["Cryo Scythe"]="rbxassetid://119930754357379",["Sakura Scythe"]="rbxassetid://133811689655966",["Glorious Scythe"]="rbxassetid://115811939422419",["Crystal Scythe"]="rbxassetid://73971549402646",
                ["Trowel"]="rbxassetid://17160799172",["Plastic Shovel"]="rbxassetid://17672062201",["Garden Shovel"]="rbxassetid://18766864873",["Snow Shovel"]="rbxassetid://78271338778848",["Paintbrush"]="rbxassetid://84687920829755",["Glorious Trowel"]="rbxassetid://100888500368219",
                ["Flare Gun"]="rbxassetid://17160801627",["Firework Gun"]="rbxassetid://17691132917",["Dynamite Gun"]="rbxassetid://18766865384",["Vexed Flare Gun"]="rbxassetid://116287930550049",["Wrapped Flare Gun"]="rbxassetid://135638020129378",["Banana Flare"]="rbxassetid://123589213761955",["Glorious Flare Gun"]="rbxassetid://115324763672074",
                ["Assault Rifle"]="rbxassetid://17160682738",["AK-47"]="rbxassetid://17691132793",["AUG"]="rbxassetid://18770192853",["Boneclaw Rifle"]="rbxassetid://100015754284323",["AKEY-47"]="rbxassetid://80017496220683",["Gingerbread AUG"]="rbxassetid://85584922619813",["Phoenix Rifle"]="rbxassetid://140228738718621",["Tommy Gun"]="rbxassetid://111251887761435",["10B Visits"]="rbxassetid://122165086598560",["Soul Rifle"]="rbxassetid://129351366788323",["Glorious Assault Rifle"]="rbxassetid://130669996688265",
                ["Handgun"]="rbxassetid://17160801282",["Blaster"]="rbxassetid://17821234554",["Pixel Handgun"]="rbxassetid://82199841278177",["Pumpkin Handgun"]="rbxassetid://88495685924653",["Gingerbread Handgun"]="rbxassetid://95881238590412",["Gumball Handgun"]="rbxassetid://106890990556815",["Stealth Handgun"]="rbxassetid://124919185835138",["Glorious Handgun"]="rbxassetid://85129427786041",["Warp Handgun"]="rbxassetid://102974911528828",["Towerstone Handgun"]="rbxassetid://88654252790032",["Snowball Gun"]="rbxassetid://113685354916533",
                ["Burst Rifle"]="rbxassetid://17160801983",["Electro Rifle"]="rbxassetid://132227459821018",["Aqua Burst"]="rbxassetid://18837670807",["Pixel Burst"]="rbxassetid://102648809593259",["Spectral Burst"]="rbxassetid://135012309412679",["Pine Burst"]="rbxassetid://132753732294083",["FAMAS"]="rbxassetid://74974560606812",["Glorious Burst Rifle"]="rbxassetid://78517330608597",["Keyst Rifle"]="rbxassetid://78377522426003",
                ["Sniper"]="rbxassetid://17160799574",["Pixel Sniper"]="rbxassetid://17676081196",["Hyper Sniper"]="rbxassetid://18766864081",["Keyper"]="rbxassetid://85472935605264",["Eyething Sniper"]="rbxassetid://103915302076013",["Gingerbread Sniper"]="rbxassetid://99943841952995",["Event Horizon"]="rbxassetid://80749667426815",["Glorious Sniper"]="rbxassetid://118012090175286",
                ["RPG"]="rbxassetid://17160802243",["Nuke Launcher"]="rbxassetid://17672061995",["RPKEY"]="rbxassetid://108438721125410",["Spaceship Launcher"]="rbxassetid://18766860860",["Pumpkin Launcher"]="rbxassetid://94648176067808",["Firework Launcher"]="rbxassetid://75233372670156",["Squid Launcher"]="rbxassetid://130764310743404",["Pencil Launcher"]="rbxassetid://106934516693548",["Glorious RPG"]="rbxassetid://130506879885802",["Rocket Launcher"]="rbxassetid://116931956715309",
                ["Shorty"]="rbxassetid://17160800091",["Not So Shorty"]="rbxassetid://17672062572",["Too Shorty"]="rbxassetid://18129531276",["Lovely Shorty"]="rbxassetid://18766862000",["Demon Shorty"]="rbxassetid://116443498278384",["Wrapped Shorty"]="rbxassetid://136522183669611",["Balloon Shorty"]="rbxassetid://75590262133322",["Glorious Shorty"]="rbxassetid://105834197552222",
                ["Shotgun"]="rbxassetid://17160800007",["Balloon Shotgun"]="rbxassetid://17821234823",["Hyper Shotgun"]="rbxassetid://18768968419",["Broomstick Shotgun"]="rbxassetid://118061559757082",["Wrapped Shotgun"]="rbxassetid://74894345245237",["Cactus Shotgun"]="rbxassetid://131606483507460",["Shotkey"]="rbxassetid://93004214983981",["Glorious Shotgun"]="rbxassetid://71704618059601",
                ["Bow"]="rbxassetid://17160802080",["Compound Bow"]="rbxassetid://17672234242",["Raven Bow"]="rbxassetid://18766861627",["Bat Bow"]="rbxassetid://108984987378619",["Frostbite Bow"]="rbxassetid://121895626623160",["Dream Bow"]="rbxassetid://101089313144218",["Key Bow"]="rbxassetid://122525140091212",["Glorious Bow"]="rbxassetid://84201415206621",["Balloon Bow"]="rbxassetid://128957010941029",["Beloved Bow"]="rbxassetid://110219131386799",
                ["Uzi"]="rbxassetid://17160798908",["Water Uzi"]="rbxassetid://17821233590",["Electro Uzi"]="rbxassetid://96806694653207",["Demon Uzi"]="rbxassetid://132973040482576",["Pine Uzi"]="rbxassetid://82545206964916",["Money Gun"]="rbxassetid://100705725115757",["Keyzi"]="rbxassetid://100392703246534",["Glorious Uzi"]="rbxassetid://120045334159124",
                ["Revolver"]="rbxassetid://17160800299",["Desert Eagle"]="rbxassetid://17821234372",["Sheriff"]="rbxassetid://18770192507",["Boneclaw Revolver"]="rbxassetid://119174697609264",["Peppermint Sheriff"]="rbxassetid://95859403750768",["Keyvolver"]="rbxassetid://87974031410344",["Peppergun"]="rbxassetid://124178691056979",["Glorious Revolver"]="rbxassetid://118135542031794",
                ["Paintball Gun"]="rbxassetid://17160853798",["Slime Gun"]="rbxassetid://17672062472",["Boba Gun"]="rbxassetid://18768830660",["Ketchup Gun"]="rbxassetid://76083615050939",["Glorious Paintball Gun"]="rbxassetid://86297318955856",["Paintballoon Gun"]="rbxassetid://100129918948246",
                ["Slingshot"]="rbxassetid://17160799888",["Goalpost"]="rbxassetid://17672063165",["Stick"]="rbxassetid://17672063048",["Boneshot"]="rbxassetid://86606957688341",["Reindeer Slingshot"]="rbxassetid://121612921203624",["Harp"]="rbxassetid://80850043664453",["Glorious Slingshot"]="rbxassetid://101195664167288",
                ["Grenade Launcher"]="rbxassetid://17250453814",["Swashbuckler"]="rbxassetid://17821233828",["Uranium Launcher"]="rbxassetid://18766860114",["Gearnade Launcher"]="rbxassetid://133756750612042",["Skull Launcher"]="rbxassetid://103257281022910",["Snowball Launcher"]="rbxassetid://112349955391111",["Balloon Launcher"]="rbxassetid://137862701599991",["Glorious Grenade Launcher"]="rbxassetid://134130354519919",
                ["Minigun"]="rbxassetid://17250458611",["Lasergun 3000"]="rbxassetid://103437974285778",["Pixel Minigun"]="rbxassetid://18766861798",["Pumpkin Minigun"]="rbxassetid://77388785880854",["Wrapped Minigun"]="rbxassetid://127077702465909",["Fighter Jet"]="rbxassetid://70780739230558",["Glorious Minigun"]="rbxassetid://84246894288637",
                ["Exogun"]="rbxassetid://17344796376",["Wondergun"]="rbxassetid://17672060360",["Singularity"]="rbxassetid://17676876756",["Ray Gun"]="rbxassetid://18766861454",["Exogourd"]="rbxassetid://137140750597688",["Midnight Festive Exogun"]="rbxassetid://127612442529810",["Repulsor"]="rbxassetid://109263387714628",["Glorious Exogun"]="rbxassetid://129125201034206",
                ["Freeze Ray"]="rbxassetid://18429552328",["Temporal Ray"]="rbxassetid://18429552503",["Bubble Ray"]="rbxassetid://18766865819",["Wrapped Freeze Ray"]="rbxassetid://76183738050112",["Gum Ray"]="rbxassetid://121504417727123",["Glorious Freeze Ray"]="rbxassetid://120211873831101",
                ["War Horn"]="rbxassetid://104600246515190",["Trumpet"]="rbxassetid://88975601634708",["Mammoth Horn"]="rbxassetid://93076834584542",["Megaphone"]="rbxassetid://107074211847347",["Air Horn"]="rbxassetid://111168146142976",["Glorious War Horn"]="rbxassetid://96293355496772",["Boneclaw Horn"]="rbxassetid://138360812591331",
                ["Satchel"]="rbxassetid://82237471151891",["Advanced Satchel"]="rbxassetid://113860326910548",["Suspicious Gift"]="rbxassetid://76209303162814",["Notebook Satchel"]="rbxassetid://124817464748150",["Bag O' Money"]="rbxassetid://129192426700659",["Glorious Satchel"]="rbxassetid://100521994805910",["Potion Satchel"]="rbxassetid://76787046046890",
                ["Battle Axe"]="rbxassetid://93390542043222",["The Shred"]="rbxassetid://71234381808727",["Nordic Axe"]="rbxassetid://80052264197135",["Ban Axe"]="rbxassetid://111046431576859",["Cerulean Axe"]="rbxassetid://76353832683350",["Glorious Battleaxe"]="rbxassetid://87227212476138",["Mimic Axe"]="rbxassetid://111717370450373",["Keytle Axe"]="rbxassetid://122117068984402",["Balloon Axe"]="rbxassetid://102429983628211",
                ["Riot Shield"]="rbxassetid://121172272442833",["Door"]="rbxassetid://79242603995428",["Sled"]="rbxassetid://73881731607231",["Masterpiece"]="rbxassetid://79914271483818",["Glorious Riot Shield"]="rbxassetid://132866851386509",["Tombstone Shield"]="rbxassetid://125895528641243",
                ["Daggers"]="rbxassetid://91885384580845",["Aces"]="rbxassetid://139089881483398",["Cookies"]="rbxassetid://114482325531769",["Crystal Daggers"]="rbxassetid://126221748659600",["Paper Planes"]="rbxassetid://84003122595879",["Shurikens"]="rbxassetid://135574097643275",["Glorious Daggers"]="rbxassetid://76023189104485",["Bat Daggers"]="rbxassetid://92001964015225",["Keynais"]="rbxassetid://84562761142610",["Broken Hearts"]="rbxassetid://74156924296351",
                ["Energy Pistols"]="rbxassetid://79471670126710",["Hacker Pistols"]="rbxassetid://140621407555872",["Apex Pistols"]="rbxassetid://136156057859453",["New Years Energy Pistols"]="rbxassetid://126589959779039",["Void Pistols"]="rbxassetid://111278471262300",["Hydro Pistols"]="rbxassetid://115281889984097",["Glorious Energy Pistols"]="rbxassetid://114418789647547",["Soul Pistols"]="rbxassetid://72213738067158",
                ["Energy Rifle"]="rbxassetid://110259279810005",["Hacker Rifle"]="rbxassetid://122816271917525",["Apex Rifle"]="rbxassetid://88144772234151",["New Year Energy Rifle"]="rbxassetid://111446782522703",["Hydro Rifle"]="rbxassetid://73690448730060",["Void Rifle"]="rbxassetid://95985016411441",["Glorious Energy Rifle"]="rbxassetid://72632815443247",
                ["Spray"]="rbxassetid://92882887485248",["Lovely Spray"]="rbxassetid://131203015026683",["Pine Spray"]="rbxassetid://128285758736343",["Glorious Spray"]="rbxassetid://138246745001490",["Boneclaw Spray"]="rbxassetid://114078818081911",["Key Spray"]="rbxassetid://94061940442700",
                ["Crossbow"]="rbxassetid://140211832612284",["Pixel Crossbow"]="rbxassetid://115931961841903",["Frostbite Crossbow"]="rbxassetid://101536997945363",["Harpoon Crossbow"]="rbxassetid://107460405492001",["Violin Crossbow"]="rbxassetid://74401302514014",["Glorious Crossbow"]="rbxassetid://70875146419725",["Crossbone"]="rbxassetid://103469183638638",["Arch Crossbow"]="rbxassetid://94981733362451",
                ["Gunblade"]="rbxassetid://131231034374465",["Hyper Gunblade"]="rbxassetid://134415898983004",["Elf's Gunblade"]="rbxassetid://114103306647123",["Crude Gunblade"]="rbxassetid://126996645502136",["Gunsaw"]="rbxassetid://102700915422689",["Glorious Gunblade"]="rbxassetid://88003799126136",["Boneblade"]="rbxassetid://126327381608481",
                ["Jump Pad"]="rbxassetid://79459600453621",["Glorious Jump Pad"]="rbxassetid://71803398862947",
                ["Distortion"]="rbxassetid://115712150398379",["Glorious Distortion"]="rbxassetid://134722661973710",["Electropunk Distortion"]="rbxassetid://109544539643046",["Plasma Distortion"]="rbxassetid://126813935337091",["Magma Distortion"]="rbxassetid://81103807698156",["Cyber Distortion"]="rbxassetid://88995062151276",["Sleighstortion"]="rbxassetid://111242141481650",
                ["Warper"]="rbxassetid://88033795039891",["Glorious Warper"]="rbxassetid://95823647035211",["Electropunk Warper"]="rbxassetid://75386728379756",["Glitter Warper"]="rbxassetid://94607497565715",["Arcane Warper"]="rbxassetid://83632373572638",["Frost Warper"]="rbxassetid://70539216094396",
                ["Warpstone"]="rbxassetid://94035693279005",["Glorious Warpstone"]="rbxassetid://137583560042806",["Unstable Warpstone"]="rbxassetid://110083777654388",["Warpbone"]="rbxassetid://96452209607150",["Cyber Warpstone"]="rbxassetid://133002984228937",["Electropunk Warpstone"]="rbxassetid://75299042976369",["Bonestone"]="rbxassetid://96452209607150",
                ["Maul"]="rbxassetid://81478141693597",["Sleigh Maul"]="rbxassetid://114892026951995",["Ice Maul"]="rbxassetid://100001888078290",["Glorious Maul"]="rbxassetid://125917253783002",
                ["Permafrost"]="rbxassetid://74353733133888",["Snowman Permafrost"]="rbxassetid://100890626643184",["Ice Permafrost"]="rbxassetid://83722160119335",["Glorious Permafrost"]="rbxassetid://119977291442329",
                ["Briefcase"]="rbxassetid://18142172067",["Laptop"]="rbxassetid://18770164868",["Bucket of Candy"]="rbxassetid://93791981490691",["Box of Chocolates"]="rbxassetid://132421415091712",
                ["Dev-in-the-Box"]="rbxassetid://125056115146240",["Pot o' Keys"]="rbxassetid://125355191847719",
                ["Jack O'Thrower"]="rbxassetid://140280020818514",["Rainbowthrower"]="rbxassetid://102070206928252",
                ["Hot Coals"]="rbxassetid://110423024723304",["Arch Molotov"]="rbxassetid://96589300342777",
                ["Disco Ball"]="rbxassetid://17672061796",["Camera"]="rbxassetid://18766865640",["Shining Star"]="rbxassetid://108392227354212",["Lightbulb"]="rbxassetid://125489177573287",["Eyeball"]="rbxassetid://135911399763146",["Snowglobe"]="rbxassetid://119390465944051",
                ["Fist"]="rbxassetid://109585706680035",["Candy Cane"]="rbxassetid://124021545052910",["Armature.001"]="rbxassetid://104026327618871",["Caladbolg"]="rbxassetid://101180142582964",["Evil Trident"]="rbxassetid://101234805269080",
                ["New Year Katana"]="rbxassetid://102866488046710",["Anchor"]="rbxassetid://18766866743",["Bug Net"]="rbxassetid://115620701626004",["Pumpkin Carver"]="rbxassetid://78827307308671",
                ["Hand Gun"]="rbxassetid://18837670624",["Broomstick"]="rbxassetid://118061559757082",["Brain Gun"]="rbxassetid://85970592668118",["Lucky Horseshoe"]="rbxassetid://131242126669282",["Spider Ray"]="rbxassetid://136838810668332",
                ["Bag o' Money"]="rbxassetid://129192426700659",["Glorious Battle Axe"]="rbxassetid://87227212476138",["Keyttle Axe"]="rbxassetid://122117068984402",
                ["Energy Shield"]="rbxassetid://90215439337413",["New Year Energy Pistols"]="rbxassetid://126589959779039",["Hyperlaser Guns"]="rbxassetid://106947526362970",
                ["Nail Gun"]="rbxassetid://110577809934251",["Spray Bottle"]="rbxassetid://137955019285700",
                ["Trampoline"]="rbxassetid://103567857194140",["Bounce House"]="rbxassetid://71226436012588",["Spider Web"]="rbxassetid://84204578032332",["Jolly Man"]="rbxassetid://97375473537804",
                ["Experiment D15"]="rbxassetid://103446773933340",["Experiment W4"]="rbxassetid://126884960764998",
                ["Hotel Bell"]="rbxassetid://117742703173821",["Warpeye"]="rbxassetid://127023603234857",["Teleport Disc"]="rbxassetid://104608154111107",["Warpstar"]="rbxassetid://102652397897598",
                ["Ban Hammer"]="rbxassetid://126491383967029",
            }

            -- Build image→weaponClass reverse map
            local d = {}
            do
                for iv, _ in pairs(ao) do
                    local bn = af[iv]
                    if bn then d[bn] = iv end
                end
            end

            -- Build skinName→weaponClass reverse map
            local ah = {}
            for ix, he in pairs(ao) do
                for _, hb in ipairs(he) do ah[hb] = ix end
            end

            -- ── Game-GUI finders (Rivals-specific) ───────────────────
            local function dm()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local dd = er and er:FindFirstChild("Equipment")
                local cp = dd and dd:FindFirstChild("Customize") local bt = cp and cp:FindFirstChild("Bottom")
                local cm = bt and bt:FindFirstChild("Container") local en = cm and cm:FindFirstChild("List")
                return en and en:FindFirstChild("Container")
            end
            local function dn()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local dd = er and er:FindFirstChild("Equipment")
                local em = dd and dd:FindFirstChild("Left") local en = em and em:FindFirstChild("List")
                return en and en:FindFirstChild("Container")
            end
            local function dk()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local fi = er and er:FindFirstChild("Pages")
                local fm = fi and fi:FindFirstChild("PickWeapons")
                return fm and fm:FindFirstChild("ChosenWeapons")
            end
            local function dp()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local dg = er and er:FindFirstChild("FighterInterfaces")
                local fq = dg and dg:FindFirstChild(m) local ea = fq and fq:FindFirstChild("Hotbar")
                return ea and ea:FindFirstChild("Container")
            end
            local function dq()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local fi = er and er:FindFirstChild("Pages")
                local ie = fi and fi:FindFirstChild("ViewProfile") local ay = ie and ie:FindFirstChild("Active")
                local fo = ay and ay:FindFirstChild("Player")
                return fo and fo:FindFirstChild("MostPlayedWeapons")
            end
            local function dr()
                local fr = k:FindFirstChild("PlayerGui") local es = fr and fr:FindFirstChild("MainGui")
                local er = es and es:FindFirstChild("MainFrame") local fi = er and er:FindFirstChild("Pages")
                local fm = fi and fi:FindFirstChild("PickWeapons") local en = fm and fm:FindFirstChild("List")
                return en and en:FindFirstChild("Container")
            end

            -- ── Skin-icon helpers ─────────────────────────────────────
            local function bg(ce, it, ec)
                for _, bz in ipairs(ce:GetDescendants()) do
                    if bz.Name == "EquipmentButtonSlot" then
                        local bw = bz:FindFirstChild("Button") if not bw then continue end
                        local hp = bw:FindFirstChild("Title") if hp and hp.Text == it then
                            local eb = bw:FindFirstChild("Icon") if eb then eb.Image = ec end
                        end
                    end
                end
            end
            local function hw(it, gx)
                local ck = dm() if not ck then return end
                local ec = af[gx] or af[it] if not ec then return end
                for _, hf in ipairs(ck:GetChildren()) do
                    local bw = hf:FindFirstChild("Button") if not bw then continue end
                    local hq = bw:FindFirstChild("Title") if not hq then continue end
                    local hg = hq.Text
                    local ep = bw:FindFirstChild("Locked") local eb = bw:FindFirstChild("Icon")
                    local de = bw:FindFirstChild("Equipped")
                    if hg == "None" then
                        if de then de.Visible = (gx == nil) end
                    else
                        if hg ~= it then continue end
                        if ep then ep.Visible = false end
                        if eb then eb.ImageColor3 = Color3.fromRGB(255,255,255); eb.ImageTransparency = 0 end
                        if de then de.Visible = true end
                    end
                end
            end
            local function hx(it, gx)
                local ck = dn() if not ck then return end
                local ec = af[gx] or af[it] if not ec then return end
                for _, ce in ipairs(ck:GetChildren()) do
                    if ce.Name == "EquipmentClassSlot" then bg(ce, it, ec) end
                end
            end
            local function hy(it, gx)
                local ec = af[gx] or af[it] if not ec then return end
                local ck = dp() if not ck then return end
                local iw = ck:FindFirstChild(it) if not iw then return end
                local eb = iw:FindFirstChild("Icon") if not eb then return end
                eb.Image = ec
            end
            local function hz(it, gx)
                local ec = af[gx] or af[it] if not ec then return end
                local function ht(hf)
                    local bw = hf:FindFirstChild("Button") if not bw then return false end
                    local hp = bw:FindFirstChild("Title") if not hp or hp.Text ~= it then return false end
                    local eb = bw:FindFirstChild("Icon") if not eb then return false end
                    local fn = eb:FindFirstChild("Picture") if fn then fn.Image = ec end
                    return true
                end
                task.spawn(function()
                    local ck while not ck do ck = dr() if not ck then task.wait(0.5) end end
                    local eu = false
                    for _, hf in ipairs(ck:GetChildren()) do if ht(hf) then eu = true end end
                    if not eu then
                        local cj
                        cj = Library:Track(ck.ChildAdded:Connect(function(hf) task.wait() if ht(hf) then cj:Disconnect() end end))
                    end
                end)
            end

            -- ── ViewModel skin swap core ──────────────────────────────
            local q = Lighting:FindFirstChild("SC_DefaultBackups") or Instance.new("Folder", Lighting)
            q.Name = "SC_DefaultBackups"
            local function bp(ey, ew)
                if not ew then return end if q:FindFirstChild(ey) then return end
                local bo = Instance.new("Folder") bo.Name = ey
                for _, item in ipairs(ew:GetChildren()) do local cf = item:Clone() if cf then cf.Parent = bo end end
                bo.Parent = q
            end
            local function bl(hn, hc)
                -- Preserve animations and effects while swapping visual geometry
                local preserved = {}
                for _, v in ipairs(hn:GetChildren()) do
                    -- Broadened filter for animations/effects/scripts/folders
                    if v:IsA("Folder") or v:IsA("Configuration") or v:IsA("Animation") or v:IsA("ModuleScript") or v:IsA("LocalScript") or v.Name:find("Effect") or v.Name:find("Client") or v.Name:find("Shared") then
                        table.insert(preserved, v)
                        v.Parent = nil -- Temporary detach
                    elseif v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") or v:IsA("MeshPart") then
                        v:Destroy()
                    end
                end
                -- Apply new skin geometry
                for _, item in ipairs(hc:GetChildren()) do
                    if item:IsA("BasePart") or item:IsA("Decal") or item:IsA("Texture") or item:IsA("MeshPart") then
                        local cf = item:Clone()
                        cf.Parent = hn
                    end
                end
                -- Restore preserved folders
                for _, v in ipairs(preserved) do
                    v.Parent = hn
                end
            end
            local function gb(hn, bq, gp)
                local bo = q:FindFirstChild(bq) if not bo then return end
                hn:ClearAllChildren()
                for _, item in ipairs(bo:GetChildren()) do item:Clone().Parent = hn end
                if gp then hn:PivotTo(gp) end
            end

            -- Sound remapping
            local az = {}
            local ge = {}
            local function dl_inner()
                local fd, gc = pcall(function()
                    return k:WaitForChild("PlayerScripts",3):WaitForChild("Modules",3)
                        :WaitForChild("ClientReplicatedClasses",3):WaitForChild("ClientFighter",3):WaitForChild("ClientItem",3)
                end)
                return fd and gc or nil
            end
            local cachedCC = nil
            local function dl() if cachedCC then return cachedCC end cachedCC = dl_inner() return cachedCC end
            local function fv(ix)
                for kk in next,az do az[kk]=nil end
                if not ix then return end
                local gx = ai.ActiveSkins[ix] if not gx then return end
                local ag_entry = {}  -- placeholder; ag table defined below
                -- populated after ag is defined
            end
            local function fk(et)
                local cc = dl() if not cc then return end
                for _, fc in next, cc:GetChildren() do
                    if fc:IsA("Sound") then local fw = et[fc.SoundId] if fw then fc.SoundId = fw end end
                end
            end
            local function bv(it, fx)
                local gd = {} for base, sk in next, fx do gd[sk] = base end ge[it] = gd return gd
            end
            local aw = nil
            local function db()
                if aw then return end local cc = dl() if not cc then return end
                aw = Library:Track(cc.ChildAdded:Connect(function(fc)
                    if fc:IsA("Sound") then local fw = az[fc.SoundId] if fw then fc.SoundId = fw end end
                end))
            end

            -- forward declarations for bk (set after ag is defined)
            local bk

            -- Main skin apply function
            local function bj(it, gx, cy)
                if not it then return end
                local iu
                for _, v in ipairs(al:GetDescendants()) do if v.Name == it then iu = v break end end
                if not iu then return end
                if cy and gx then
                    local hc for _, v in ipairs(al:GetDescendants()) do if v.Name == gx then hc = v break end end
                    if not hc then return end
                    bp(it, iu); bl(iu, hc)
                    local iy = workspace:FindFirstChild(it)
                    if iy then bp(it.."_ws", iy); local gp = iy:GetPivot(); bl(iy, hc); iy:PivotTo(gp) end
                    -- Also swap in ReplicatedStorage Temp ViewModels (live rendered models + effects)
                    pcall(function()
                        local tempVMs = ReplicatedStorage.Assets.Temp.ViewModels
                        local prefix = m .. " - "
                        for _, ih in ipairs(tempVMs:GetChildren()) do
                            if string.sub(ih.Name, 1, #prefix) == prefix then
                                local weaponPart = string.sub(ih.Name, #prefix + 1)
                                if weaponPart == it then
                                    local ig = ih:FindFirstChild("ItemVisual")
                                    if ig then bl(ig, hc) elseif ih then bl(ih, hc) end
                                end
                            end
                        end
                    end)
                    ai.ActiveSkins[it] = gx
                    hy(it, gx); hz(it, gx); hw(it, gx); hx(it, gx)
                    local cb = dk() if cb then for _, hf in ipairs(cb:GetChildren()) do -- bf called after definition
                    end end
                else
                    gb(iu, it, nil)
                    local iy = workspace:FindFirstChild(it)
                    if iy then gb(iy, it.."_ws", iy:GetPivot()) end
                    -- Also restore in ReplicatedStorage Temp ViewModels
                    pcall(function()
                        local tempVMs = ReplicatedStorage.Assets.Temp.ViewModels
                        local prefix = m .. " - "
                        for _, ih in ipairs(tempVMs:GetChildren()) do
                            if string.sub(ih.Name, 1, #prefix) == prefix then
                                local weaponPart = string.sub(ih.Name, #prefix + 1)
                                if weaponPart == it then
                                    local ig = ih:FindFirstChild("ItemVisual")
                                    local target = ig or ih
                                    local backupKey = "SC_Backup_" .. it
                                    local bo = q:FindFirstChild(backupKey)
                                    if bo then
                                        target:ClearAllChildren()
                                        for _, item in ipairs(bo:GetChildren()) do item:Clone().Parent = target end
                                    end
                                end
                            end
                        end
                    end)
                    ai.ActiveSkins[it] = nil
                    hy(it, it); hz(it, it); hw(it, nil); hx(it, it)
                    local cb = dk() if cb then for _, hf in ipairs(cb:GetChildren()) do -- bf called after definition
                    end end
                end
                go()
                if bk then bk(it, gx, cy) end
            end

            -- ChosenWeapons slot icon sync
            local ir = {}
            local hh = {}
            local bf  -- forward declare
            bf = function(hf)
                local bw = hf:FindFirstChild("Button") if not bw then return end
                local fn = bw:FindFirstChild("Picture") if not fn then return end
                local function bh(iv)
                    hh[hf] = iv
                    local gx = ai.ActiveSkins[iv]
                    local cu = (gx and af[gx]) or af[iv]
                    if cu and fn.Image ~= cu then fn.Image = cu end
                end
                local function cv()
                    local iv = d[fn.Image] or hh[hf] if not iv then return end
                    bh(iv)
                    if not ir[hf] then
                        ir[hf] = true
                        Library:Track(fn:GetPropertyChangedSignal("Image"):Connect(function()
                            if fn.Image == "" then return end
                            local bs = d[fn.Image] if bs then bh(bs) end
                        end))
                    end
                end
                if fn.Image ~= "" then cv()
                else
                    local cj cj = fn:GetPropertyChangedSignal("Image"):Connect(function()
                        if fn.Image ~= "" then cj:Disconnect(); cv() end
                    end)
                end
            end

            -- Now patch bj to call bf on chosen weapons
            local _bj_orig = bj
            bj = function(it, gx, cy)
                _bj_orig(it, gx, cy)
                local cb = dk()
                if cb then for _, hf in ipairs(cb:GetChildren()) do pcall(bf, hf) end end
            end

            local function du(ck)
                for _, hf in ipairs(ck:GetChildren()) do bf(hf) end
                Library:Track(ck.ChildAdded:Connect(function(hf) task.wait(); bf(hf) end))
            end

            local is = {}
            local function ip(iv, eb)
                local ei = iv.."_"..tostring(eb)
                if is[ei] then return end is[ei] = true
                if eb.GetPropertyChangedSignal then
                    Library:Track(eb:GetPropertyChangedSignal("Image"):Connect(function()
                        local gx = ai.ActiveSkins[iv] if not gx then return end
                        local ct = af[gx] or af[iv]
                        if ct and eb.Image ~= ct then eb.Image = ct end
                    end))
                end
            end
            local function dw(ck)
                for _, hf in ipairs(ck:GetChildren()) do
                    local eb = hf:FindFirstChild("Icon") if eb then ip(hf.Name, eb) end
                end
                Library:Track(ck.ChildAdded:Connect(function(hf)
                    task.wait() local eb = hf:FindFirstChild("Icon")
                    if eb then ip(hf.Name, eb); local gx = ai.ActiveSkins[hf.Name] if gx then hy(hf.Name, gx) end end
                end))
            end
            local function dy(ck)
                local function bm(hf)
                    local bw = hf:FindFirstChild("Button") if not bw then return end
                    local hp = bw:FindFirstChild("Title") if not hp then return end
                    local iv = hp.Text local gx = ai.ActiveSkins[iv]
                    local ec = af[gx or iv] or af[iv] if not ec then return end
                    local eb = bw:FindFirstChild("Icon") if not eb then return end
                    local fn = eb:FindFirstChild("Picture")
                    if fn then fn.Image = ec else eb.Image = ec end
                end
                for _, hf in ipairs(ck:GetChildren()) do bm(hf) end
                Library:Track(ck.ChildAdded:Connect(function(hf) task.wait(); bm(hf) end))
            end
            local function bi(hf)
                local bw = hf:FindFirstChild("Button") if not bw then return end
                local hq = bw:FindFirstChild("Title") if not hq then return end
                local iv = hq.Text if not iv or iv == "" then return end
                local gx = ai.ActiveSkins[iv] local ec = af[gx] or af[iv] if not ec then return end
                local eb = bw:FindFirstChild("Icon") if not eb then return end
                local fn = eb:FindFirstChild("Picture") if not fn then return end
                fn.Image = ec
            end
            local function dx(ck)
                for _, hf in ipairs(ck:GetChildren()) do bi(hf) end
                Library:Track(ck.ChildAdded:Connect(function(hf) task.wait(); bi(hf) end))
            end

            -- Start all syncing loops
            local function hl()
                task.spawn(function() local ck while not ck do ck=dp() if not ck then task.wait(0.5) end end dw(ck) end)
                task.spawn(function() local ck while not ck do ck=dr() if not ck then task.wait(0.5) end end dy(ck) end)
                task.spawn(function() local ck while not ck do ck=dq() if not ck then task.wait(0.5) end end dx(ck) end)
                task.spawn(function() local ck while not ck do ck=dk() if not ck then task.wait(0.5) end end du(ck) end)
                task.spawn(function()
                    local ck while not ck do ck=dn() if not ck then task.wait(0.5) end end
                    local function dv(ce)
                        for it, gx in pairs(ai.ActiveSkins) do bg(ce, it, af[gx] or af[it]) end
                        Library:Track(ce.ChildAdded:Connect(function() task.wait() for it, gx in pairs(ai.ActiveSkins) do bg(ce, it, af[gx] or af[it]) end end))
                    end
                    for _, ce in ipairs(ck:GetChildren()) do if ce.Name == "EquipmentClassSlot" then dv(ce) end end
                    Library:Track(ck.ChildAdded:Connect(function(ce) if ce.Name == "EquipmentClassSlot" then task.wait(); dv(ce) end end))
                end)
                task.spawn(function()
                    local ck while not ck do ck=dm() if not ck then task.wait(0.5) end end
                    for it, gx in pairs(ai.ActiveSkins) do hw(it, gx) end
                    Library:Track(ck.ChildAdded:Connect(function() for it, gx in pairs(ai.ActiveSkins) do hw(it, gx) end end))
                end)
            end

            -- ── Material / Transparency helpers ───────────────────────
            local function gu(ew, ev)
                for _, v in ipairs(ew:GetDescendants()) do
                    if (v:IsA("MeshPart") or v:IsA("BasePart") or v:IsA("Part")) and not string.find(string.lower(v.Name),"primary") then
                        v.Material = Enum.Material[ev]
                    end
                end
            end
            local function gw(ew, ic)
                for _, v in ipairs(ew:GetDescendants()) do
                    if (v:IsA("MeshPart") or v:IsA("BasePart") or v:IsA("Part")) and not string.find(string.lower(v.Name),"primary") then
                        v.Transparency = ic / 100
                    end
                end
            end
            local function ia()
                if not ai.MaterialEnabled then return end
                local id = ReplicatedStorage.Assets.Temp.ViewModels
                for _, ih in ipairs(id:GetChildren()) do
                    if string.find(ih.Name, m.." -", 1, true) == 1 then
                        local ig = ih:FindFirstChild("ItemVisual")
                        if ig then gu(ig, ai.CurrentMaterial); gw(ig, ai.Transparency) end
                    end
                end
            end
            do
                local cs = false
                Library:Track(ReplicatedStorage.Assets.Temp.ViewModels.ChildAdded:Connect(function()
                    if cs then return end cs = true
                    task.delay(0.1, function() ia(); cs = false end)
                end))
            end

            -- ── Sound remapping (bk) ─────────────────────────────────
            local ag = {
                ["AK-47"]={["rbxassetid://13087362838"]="rbxassetid://17662574783"},
                ["AUG"]={["rbxassetid://13087362838"]="rbxassetid://17662574783",["rbxassetid://13158735106"]="rbxassetid://13455395017",["rbxassetid://13236549962"]="rbxassetid://13236549929",["rbxassetid://13455395017"]="rbxassetid://13236549929"},
                ["Blaster"]={["rbxassetid://13110197220"]="rbxassetid://17803104424",["rbxassetid://13110197302"]="rbxassetid://17803104424",["rbxassetid://13158330479"]="rbxassetid://17803104424"},
            }

            local au = m .. " - "
            local av = #au
            local as_weapon = nil

            local function fb(gx) return gx:lower():gsub("[^%a%d]","") end

            local ap = {
                ["Assault Rifle"]="assaultrifle",["Bow"]="bow",["Burst Rifle"]="burstrifle",["Chainsaw"]="chainsaw",
                ["RPG"]="rpg",["Exogun"]="exogun",["Fists"]="fists",["Flamethrower"]="flamethrower",
                ["Flare Gun"]="flaregun",["Freeze Ray"]="freezeray",["Grenade"]="grenade",["Grenade Launcher"]="grenadelauncher",
                ["Handgun"]="handgun",["Katana"]="katana",["Minigun"]="minigun",["Paintball Gun"]="paintballgun",
                ["Revolver"]="revolver",["Slingshot"]="slingshot",["Subspace Tripmine"]="subspacetripmine",["Uzi"]="uzi",
                ["Sniper"]="sniper",["Knife"]="knife",["Shotgun"]="shotgun",["Crossbow"]="crossbow",
                ["Daggers"]="daggers",["Distortion"]="distortion",["Energy Rifle"]="energyrifle",["Energy Pistols"]="energypistols",
                ["Gunblade"]="gunblade",["Battle Axe"]="battleaxe",["Riot Shield"]="riotshield",["Scythe"]="scythe",
                ["Trowel"]="trowel",["Medkit"]="medkit",["Molotov"]="molotov",["Satchel"]="satchel",
                ["Smoke Grenade"]="smokegrenade",["War Horn"]="warhorn",["Warpstone"]="warpstone",["Flashbang"]="flashbang",
                ["Jump Pad"]="jumppad",["Warper"]="warper",["Shorty"]="shorty",["Maul"]="maul",
                ["Spray"]="spray",["Permafrost"]="permafrost",
            }

            bk = function(it, gx, cy)
                if cy and gx then
                    local fx = ag[gx] if not fx then return end
                    bv(it, fx)
                    if as_weapon == it then
                        for k2 in next,az do az[k2]=nil end
                        for base, fw in next, fx do az[base] = fw end
                        fk(az)
                    end
                else
                    local fx = gx and ag[gx]
                    if fx then
                        if as_weapon == it then
                            local gd = ge[it] or bv(it, fx) fk(gd)
                            for k2 in next, az do az[k2]=nil end
                        end
                        ge[it] = nil
                    end
                end
            end

            -- ── UI State (Skins tab) ───────────────────────────────
            local SC_weaponNames = {}
            for wname in pairs(ao) do ef(SC_weaponNames, wname) end
            table.sort(SC_weaponNames)

            local SC_selectedWeapon = SC_weaponNames[1]
            local SC_selectedSkin   = "Default"

            local function SC_getSkins(weaponName)
                local skins = {"Default"}
                if ao[weaponName] then
                    for _, sk in ipairs(ao[weaponName]) do ef(skins, sk) end
                end
                return skins
            end

            -- ── Obsidian tab controls ─────────────────────────
            local SkinsGroupL = Tabs.Skins:AddLeftGroupbox("Weapon")
            local SkinsGroupR = Tabs.Skins:AddRightGroupbox("Skin")

            -- skin dropdown forward-declared so weapon callback can update it
            local SC_skinDropdown

            SkinsGroupL:AddDropdown("SC_WeaponSelect", {
                Values   = SC_weaponNames,
                Default  = SC_weaponNames[1],
                Text     = "Weapon",
                Callback = function(weaponName)
                    SC_selectedWeapon = weaponName
                    SC_selectedSkin   = "Default"
                    if SC_skinDropdown then
                        SC_skinDropdown:SetValues(SC_getSkins(weaponName))
                        SC_skinDropdown:SetValue("Default")
                    end
                end,
            })

            SkinsGroupL:AddButton("Reset This Weapon", function()
                if SC_selectedWeapon then
                    bj(SC_selectedWeapon, nil, false)
                end
            end)

            SkinsGroupL:AddButton("Reset All Skins", function()
                for it in pairs(ai.ActiveSkins) do
                    bj(it, nil, false)
                end
            end)

            SC_skinDropdown = SkinsGroupR:AddDropdown("SC_SkinSelect", {
                Values   = SC_getSkins(SC_weaponNames[1]),
                Default  = "Default",
                Text     = "Skin",
                Callback = function(skinName)
                    SC_selectedSkin = skinName
                end,
            })

            SkinsGroupR:AddButton("Apply Skin", function()
                if not SC_selectedWeapon then return end
                if SC_selectedSkin == "Default" or SC_selectedSkin == nil then
                    bj(SC_selectedWeapon, nil, false)
                else
                    bj(SC_selectedWeapon, SC_selectedSkin, true)
                end
            end)

            local WeaponAppGroup = Tabs.Skins:AddRightGroupbox("Weapon Appearance")

            WeaponAppGroup:AddToggle("SC_MaterialEnabled", {
                Text     = "Material Override",
                Default  = ai.MaterialEnabled,
                Callback = function(v2)
                    ai.MaterialEnabled = v2
                    go(); ia()
                end,
            })

            WeaponAppGroup:AddDropdown("SC_MaterialSelect", {
                Values   = l,
                Default  = ai.CurrentMaterial,
                Text     = "Select Material",
                Callback = function(v2)
                    ai.CurrentMaterial = v2
                    go(); ia()
                end,
            })

            WeaponAppGroup:AddSlider("SC_Transparency", {
                Text     = "Transparency %",
                Default  = ai.Transparency,
                Min      = 0,
                Max      = 100,
                Rounding = 0,
                Callback = function(v2)
                    ai.Transparency = v2
                    go(); ia()
                end,
            })

            -- ── Initialization ────────────────────────────────────────
            task.defer(function()
                task.wait(1)
                for it, gx in pairs(ai.ActiveSkins) do
                    bj(it, gx, true)
                end
                if ai.MaterialEnabled then ia() end
                hl()
                task.spawn(function()
                    while true do
                        task.wait(0.5) -- was 0.1 (10x/sec) - 0.5 is plenty for icon sync
                        for it, gx in pairs(ai.ActiveSkins) do
                            hy(it, gx); hx(it, gx); hw(it, gx)
                        end
                        if ai.MaterialEnabled then pcall(ia) end
                    end
                end)
            end)

            -- Start sound remapping listener
            task.spawn(function() dl(); db() end)

        end -- end skin changer scope
        --]]




        -- [[ UI Relocated to Top for Initialization Stability ]]

        --[[
        -- PREMIUM COMBAT LOGIC HOOKS
        -- Refactored/Disabled in v4.4.1
        --]]

        --[[
        -- UE V2 ESP LOGIC
        -- Refactored/Disabled in v4.4.1
        --]]

        --[[
        -- SILENT AIM & CAMLOCK LOGIC
        -- Refactored/Disabled in v4.4.1
        --]]

        --[[
        -- ANTI-AIM LOGIC
        -- Refactored/Disabled in v4.4.1
        --]]

        --[[
        -- CFRAME SPEED / HITBOX / PARRY
        -- Refactored/Disabled in v4.4.1
        --]]

        --[[
        -- DRAWINGLIB ESP LOGIC
        -- Refactored/Disabled in v4.4.1 for stability
        --]]

        -- MOVEMENT LOGIC DISABLED AS REQUESTED
        --[[
        local function getHum()
            local char = lp.Character
            return char and char:FindFirstChildOfClass("Humanoid")
        end
        ...
        Toggles.BhopEnabled:OnChanged(function()
            ...
        end)
        ]]

        -- ============================================================
        -- FULLBRIGHT LOGIC
        -- ============================================================
        local FB_saved = {}

        local function applyFullbright(on)
            local Lighting = game:GetService("Lighting")
            pcall(function()
                if on then
                    if not FB_saved.done then
                        FB_saved.Brightness     = Lighting.Brightness
                        FB_saved.ClockTime      = Lighting.ClockTime
                        FB_saved.FogEnd         = Lighting.FogEnd
                        FB_saved.GlobalShadows  = Lighting.GlobalShadows
                        FB_saved.Ambient        = Lighting.Ambient
                        FB_saved.OutdoorAmbient = Lighting.OutdoorAmbient
                        FB_saved.done           = true
                    end
                    local br = Options.FullbrightBrightness.Value
                    Lighting.Brightness     = br
                    Lighting.ClockTime      = 14
                    Lighting.FogEnd         = 9e9
                    Lighting.GlobalShadows  = false
                    Lighting.Ambient        = Color3.new(1, 1, 1)
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                    for _, v in ipairs(Lighting:GetChildren()) do
                        if v:IsA("BloomEffect") or v:IsA("BlurEffect")
                        or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
                            if not v:GetAttribute("FB_was") then v:SetAttribute("FB_was", v.Enabled) end
                            v.Enabled = false
                        end
                    end
                else
                    if FB_saved.done then
                        Lighting.Brightness     = FB_saved.Brightness
                        Lighting.ClockTime      = FB_saved.ClockTime
                        Lighting.FogEnd         = FB_saved.FogEnd
                        Lighting.GlobalShadows  = FB_saved.GlobalShadows
                        Lighting.Ambient        = FB_saved.Ambient
                        Lighting.OutdoorAmbient = FB_saved.OutdoorAmbient
                        FB_saved.done           = false
                    end
                    for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
                        local was = v:GetAttribute("FB_was")
                        if was ~= nil then
                            pcall(function() v.Enabled = was end)
                            v:SetAttribute("FB_was", nil)
                        end
                    end
                end
            end)
        end

        Toggles.FullbrightEnabled:OnChanged(function()
            applyFullbright(Toggles.FullbrightEnabled.Value)
        end)
        Options.FullbrightBrightness:OnChanged(function()
            if Toggles.FullbrightEnabled.Value then applyFullbright(true) end
        end)

        -- ============================================================
        -- ELITE VISUALS ENGINE (Weather, FOV, Viewmodel, Hitmarkers)
        -- ============================================================
        -- ============================================================
        -- ELITE VISUALS ENGINE (Weather, FOV, Viewmodel, Hitmarkers)
        -- ============================================================
        do
            local Lighting = game:GetService("Lighting")
            local origAtmosphere = {
                ClockTime = Lighting.ClockTime,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogStart = Lighting.FogStart,
                FogEnd = Lighting.FogEnd,
                FogColor = Lighting.FogColor
            }
            local origSky = Lighting:FindFirstChildOfClass("Sky")
            local origSkyData = nil
            if origSky then
                pcall(function()
                    origSkyData = {
                        SkyboxBk = origSky.SkyboxBk,
                        SkyboxDn = origSky.SkyboxDn,
                        SkyboxFt = origSky.SkyboxFt,
                        SkyboxLf = origSky.SkyboxLf,
                        SkyboxRt = origSky.SkyboxRt,
                        SkyboxUp = origSky.SkyboxUp,
                        SunTextureId = origSky.SunTextureId,
                        MoonTextureId = origSky.MoonTextureId,
                        CelestialBodiesShown = origSky.CelestialBodiesShown,
                    }
                end)
            end

            local lastAtmosCustom = false
            local lastAtmosFog = false
            local lastAtmosSkybox = false
            local lastAtmosSunMoon = false

            local downloadedSkyboxes = {}
            local downloadedSunMoons = {}

            local function getExternalAsset(url, filename)
                if not (typeof(writefile) == "function" and typeof(getcustomasset) == "function") then
                    return nil
                end
                
                -- If already cached, return immediately
                if typeof(isfile) == "function" and isfile(filename) then
                    local assetId = nil
                    local ok = pcall(function() assetId = getcustomasset(filename) end)
                    if ok and assetId then
                        return assetId
                    end
                end
                
                local success, data = pcall(function()
                    return game:HttpGet(url)
                end)
                if success and data and #data > 0 then
                    pcall(function()
                        writefile(filename, data)
                    end)
                    local assetId = nil
                    pcall(function() assetId = getcustomasset(filename) end)
                    return assetId
                end
                return nil
            end

            local function applyCustomSkybox()
                pcall(function()
                    local sky = Lighting:FindFirstChildOfClass("Sky")
                    if not sky then
                        sky = Instance.new("Sky")
                        sky.Name = "AxisCustomSky"
                        sky.Parent = Lighting
                    end
                    
                    local currentSkyboxActive = Toggles.AtmosSkybox and Toggles.AtmosSkybox.Value
                    local currentSunMoonActive = Toggles.AtmosSunMoon and Toggles.AtmosSunMoon.Value
                    
                    if currentSkyboxActive then
                        local sel = Options.AtmosSkyboxSelect.Value
                        local data = downloadedSkyboxes[sel]
                        if data then
                            sky.SkyboxBk = data.SkyboxBk
                            sky.SkyboxDn = data.SkyboxDn
                            sky.SkyboxFt = data.SkyboxFt
                            sky.SkyboxLf = data.SkyboxLf
                            sky.SkyboxRt = data.SkyboxRt
                            sky.SkyboxUp = data.SkyboxUp
                        end
                    else
                        if origSkyData then
                            sky.SkyboxBk = origSkyData.SkyboxBk
                            sky.SkyboxDn = origSkyData.SkyboxDn
                            sky.SkyboxFt = origSkyData.SkyboxFt
                            sky.SkyboxLf = origSkyData.SkyboxLf
                            sky.SkyboxRt = origSkyData.SkyboxRt
                            sky.SkyboxUp = origSkyData.SkyboxUp
                        end
                    end
                    
                    if currentSunMoonActive then
                        local sel = Options.AtmosSunMoonSelect.Value
                        local data = downloadedSunMoons[sel]
                        if data then
                            sky.SunTextureId = data.SunTextureId
                            sky.MoonTextureId = data.MoonTextureId
                            sky.CelestialBodiesShown = true
                        end
                    else
                        if origSkyData then
                            sky.SunTextureId = origSkyData.SunTextureId
                            sky.MoonTextureId = origSkyData.MoonTextureId
                            sky.CelestialBodiesShown = origSkyData.CelestialBodiesShown
                        end
                    end
                end)
            end

            local function downloadSkyboxAssets(sel)
                local entry = SkyboxList[sel]
                if not entry or downloadedSkyboxes[sel] then return end
                
                if entry.single then
                    local tex = getExternalAsset(entry.single, "axis_sky_"..sel) or ""
                    downloadedSkyboxes[sel] = { SkyboxBk = tex, SkyboxDn = tex, SkyboxFt = tex, SkyboxLf = tex, SkyboxRt = tex, SkyboxUp = tex }
                else
                    local bk = getExternalAsset(string.gsub(entry.url, "%%s", "bk"), "axis_sky_"..sel.."_bk") or ""
                    local dn = getExternalAsset(string.gsub(entry.url, "%%s", "dn"), "axis_sky_"..sel.."_dn") or ""
                    local ft = getExternalAsset(string.gsub(entry.url, "%%s", "ft"), "axis_sky_"..sel.."_ft") or ""
                    local lf = getExternalAsset(string.gsub(entry.url, "%%s", "lf"), "axis_sky_"..sel.."_lf") or ""
                    local rt = getExternalAsset(string.gsub(entry.url, "%%s", "rt"), "axis_sky_"..sel.."_rt") or ""
                    local up = getExternalAsset(string.gsub(entry.url, "%%s", "up"), "axis_sky_"..sel.."_up") or ""
                    
                    downloadedSkyboxes[sel] = { SkyboxBk = bk, SkyboxDn = dn, SkyboxFt = ft, SkyboxLf = lf, SkyboxRt = rt, SkyboxUp = up }
                end
                applyCustomSkybox()
            end

            local function downloadSunMoonAssets(sel)
                if downloadedSunMoons[sel] then return end
                
                local sunUrl, moonUrl
                if sel == "terraria" then
                    sunUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/terraia/terraia/sun.png"
                    moonUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/terraia/terraia/moon.png"
                elseif sel == "youareanidiot" then
                    sunUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/youareanidiot/youareanidiot/sun.png"
                    moonUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/youareanidiot/youareanidiot/moon.png"
                else -- default "idk" (sun.jpg/moon.jpg)
                    sunUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/sun.jpg"
                    moonUrl = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/moon.jpg"
                end
                
                local sun = getExternalAsset(sunUrl, "axis_sun_"..sel) or ""
                local moon = getExternalAsset(moonUrl, "axis_moon_"..sel) or ""
                
                downloadedSunMoons[sel] = { SunTextureId = sun, MoonTextureId = moon }
                applyCustomSkybox()
            end

            local function restoreOriginalSkybox()
                pcall(function()
                    local sky = Lighting:FindFirstChildOfClass("Sky")
                    if sky then
                        if origSkyData then
                            sky.SkyboxBk = origSkyData.SkyboxBk
                            sky.SkyboxDn = origSkyData.SkyboxDn
                            sky.SkyboxFt = origSkyData.SkyboxFt
                            sky.SkyboxLf = origSkyData.SkyboxLf
                            sky.SkyboxRt = origSkyData.SkyboxRt
                            sky.SkyboxUp = origSkyData.SkyboxUp
                            sky.SunTextureId = origSkyData.SunTextureId
                            sky.MoonTextureId = origSkyData.MoonTextureId
                            sky.CelestialBodiesShown = origSkyData.CelestialBodiesShown
                        else
                            if sky.Name == "AxisCustomSky" then
                                sky:Destroy()
                            end
                        end
                    end
                end)
            end

            task.spawn(function()
                while scriptActive do
                    task.wait(2)
                    local currentSkyboxActive = Toggles.AtmosSkybox and Toggles.AtmosSkybox.Value
                    local currentSunMoonActive = Toggles.AtmosSunMoon and Toggles.AtmosSunMoon.Value
                    
                    if currentSkyboxActive or currentSunMoonActive then
                        pcall(function()
                            local sky = Lighting:FindFirstChildOfClass("Sky")
                            if not sky then
                                sky = Instance.new("Sky")
                                sky.Name = "AxisCustomSky"
                                sky.Parent = Lighting
                            end
                            
                            if currentSkyboxActive then
                                local sel = Options.AtmosSkyboxSelect.Value
                                local data = downloadedSkyboxes[sel]
                                if data and sky.SkyboxBk ~= data.SkyboxBk then
                                    sky.SkyboxBk = data.SkyboxBk
                                    sky.SkyboxDn = data.SkyboxDn
                                    sky.SkyboxFt = data.SkyboxFt
                                    sky.SkyboxLf = data.SkyboxLf
                                    sky.SkyboxRt = data.SkyboxRt
                                    sky.SkyboxUp = data.SkyboxUp
                                end
                            end
                            
                            if currentSunMoonActive then
                                local sel = Options.AtmosSunMoonSelect.Value
                                local data = downloadedSunMoons[sel]
                                if data and sky.SunTextureId ~= data.SunTextureId then
                                    sky.SunTextureId = data.SunTextureId
                                    sky.MoonTextureId = data.MoonTextureId
                                end
                            end
                        end)
                    end
                end
            end)

            Library:Track(rs.RenderStepped:Connect(function(dt)
                -- Hitmarker Rendering
                -- Hitmarker system removed
     
                -- Skybox & Celestial Body Restore/Enforce Loop
                local currentSkyboxActive = Toggles.AtmosSkybox and Toggles.AtmosSkybox.Value
                local currentSunMoonActive = Toggles.AtmosSunMoon and Toggles.AtmosSunMoon.Value
                
                if currentSkyboxActive or currentSunMoonActive then
                    local sky = Lighting:FindFirstChildOfClass("Sky")
                    if not sky then
                        sky = Instance.new("Sky")
                        sky.Name = "AxisCustomSky"
                        sky.Parent = Lighting
                    end
                    
                    if currentSkyboxActive then
                        local sel = Options.AtmosSkyboxSelect.Value
                        local data = downloadedSkyboxes[sel]
                        if data and sky.SkyboxBk ~= data.SkyboxBk then
                            sky.SkyboxBk = data.SkyboxBk
                            sky.SkyboxDn = data.SkyboxDn
                            sky.SkyboxFt = data.SkyboxFt
                            sky.SkyboxLf = data.SkyboxLf
                            sky.SkyboxRt = data.SkyboxRt
                            sky.SkyboxUp = data.SkyboxUp
                        end
                    end
                    
                    if currentSunMoonActive then
                        local sel = Options.AtmosSunMoonSelect.Value
                        local data = downloadedSunMoons[sel]
                        if data and sky.SunTextureId ~= data.SunTextureId then
                            sky.SunTextureId = data.SunTextureId
                            sky.MoonTextureId = data.MoonTextureId
                        end
                    end
                end

                local anyWasActive = (lastAtmosSkybox ~= false) or (lastAtmosSunMoon ~= false)

                if currentSkyboxActive then
                    local sel = Options.AtmosSkyboxSelect.Value
                    if lastAtmosSkybox ~= sel then
                        lastAtmosSkybox = sel
                        task.spawn(function()
                            downloadSkyboxAssets(sel)
                        end)
                    end
                elseif lastAtmosSkybox then
                    lastAtmosSkybox = false
                    task.spawn(applyCustomSkybox)
                end

                if currentSunMoonActive then
                    local sel = Options.AtmosSunMoonSelect.Value
                    if lastAtmosSunMoon ~= sel then
                        lastAtmosSunMoon = sel
                        task.spawn(function()
                            downloadSunMoonAssets(sel)
                        end)
                    end
                elseif lastAtmosSunMoon then
                    lastAtmosSunMoon = false
                    task.spawn(applyCustomSkybox)
                end

                if not currentSkyboxActive and not currentSunMoonActive and anyWasActive then
                    task.spawn(restoreOriginalSkybox)
                end
                
                            -- Atmosphere Restore Transition
                if Toggles.AtmosCustom and Toggles.AtmosCustom.Value then
                    lastAtmosCustom = true
                    pcall(function()
                        Lighting.ClockTime = Options.AtmosTime.Value
                        Lighting.Ambient = Options.AtmosAmbient.Value
                        Lighting.OutdoorAmbient = Options.AtmosAmbient.Value
                    end)
                elseif lastAtmosCustom then
                    lastAtmosCustom = false
                    pcall(function()
                        Lighting.ClockTime = origAtmosphere.ClockTime
                        Lighting.Ambient = origAtmosphere.Ambient
                        Lighting.OutdoorAmbient = origAtmosphere.OutdoorAmbient
                    end)
                end
                
                -- Fog Restore Transition
                if Toggles.AtmosFog and Toggles.AtmosFog.Value then
                    lastAtmosFog = true
                    pcall(function()
                        Lighting.FogStart = Options.AtmosFogStart.Value
                        Lighting.FogEnd = Options.AtmosFogEnd.Value
                        Lighting.FogColor = Options.AtmosFogColor.Value
                    end)
                elseif lastAtmosFog then
                    lastAtmosFog = false
                    pcall(function()
                        Lighting.FogStart = origAtmosphere.FogStart
                        Lighting.FogEnd = origAtmosphere.FogEnd
                        Lighting.FogColor = origAtmosphere.FogColor
                    end)
                end
                -- Camera FOV
                if Toggles.FOVEnabled and Toggles.FOVEnabled.Value then
                    pcall(function()
                        camera.FieldOfView = Options.FOVValue.Value
                    end)
                end
                
                -- Viewmodel Manipulation & No Sway are handled in the consolidated RenderStepped loop below to avoid conflicts.
            end))
        end


        --[[
        -- Master Logic Loop (Combat & Camera)
        rs.RenderStepped:Connect(function()
            ...
        end)
        --]]

        -- Unified visuals and movement loop verified.
        -- Unified execution loop confirmed.

        -- Hardcoded Panic Key (End)
        Library:Track(game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
            if not Library.Running then return end
            if not gpe and input.KeyCode == Enum.KeyCode.End then
                -- 1. Unload Library (Hides Menu/Overlays)
                Library:Unload()
                -- 2. Fallback: destroy any world-space assets
                local tracerFolder = workspace:FindFirstChild("AxisTracers")
                if tracerFolder then tracerFolder:Destroy() end
                local weatherPart = workspace:FindFirstChild("AxisWeather")
                if weatherPart then weatherPart:Destroy() end
                -- 3. Notify
            end
        end))

        -- ── Hitmarker System (Drawing API & Audio) ───────────────────
        do
            getgenv().hitmarkerSound = Instance.new("Sound")
            getgenv().hitmarkerSound.SoundId = "rbxassetid://160432334"
            getgenv().hitmarkerSound.Volume = 2
            getgenv().hitmarkerSound.Parent = game:GetService("SoundService")

            getgenv().TriggerHitmarker = function()
                -- Hitmarkers Commented Out
            end
        end
        --[[
        local old_TriggerHitmarker = function()
            if not Toggles.HitmarkerEnabled or not Toggles.HitmarkerEnabled.Value then return end
            pcall(function() hitmarkerSound:Play() end)
            
            local lines = {}
            local size = 6
            local gap = 3
            local offsets = {
                {dx = 1, dy = 1},
                {dx = -1, dy = 1},
                {dx = 1, dy = -1},
                {dx = -1, dy = -1}
            }
            
            for i=1, 4 do
                local line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Color = Options.HitmarkerColor.Value or Color3.new(1,1,1)
                line.Visible = true
                line.ZIndex = 11
                lines[i] = line
            end
            
            task.spawn(function()
                local duration = Options.HitmarkerFade.Value or 0.5
                local elapsed = 0
                while elapsed < duration do
                    if not Library.Running then break end
                    local percent = 1 - (elapsed / duration)
                    local curCenter = camera.ViewportSize / 2
                    
                    for i, offset in ipairs(offsets) do
                        local line = lines[i]
                        line.From = curCenter + Vector2.new(offset.dx * gap, offset.dy * gap)
                        line.To = curCenter + Vector2.new(offset.dx * (gap + size), offset.dy * (gap + size))
                        line.Transparency = percent
                    end
                    task.wait(0.01)
                    elapsed = elapsed + 0.01
                end
                for _, line in ipairs(lines) do line:Remove() end
            end)
        end
        --]]

        -- ── Crosshair Renderer (Drawing API) ─────────────────────────
        (function()
            local function newLine()
                local l = Drawing.new("Line")
                l.Visible = false
                l.ZIndex = 10
                return l
            end
            local function newText()
                local t = Drawing.new("Text")
                t.Visible = false
                t.Size = 13
                t.Font = drawFont
                t.Center = true
                t.Outline = true
                t.ZIndex = 10
                return t
            end

            -- 4 arms × (main + outline) = 8 lines
            local outlines = {newLine(), newLine(), newLine(), newLine()}
            local lines   = {newLine(), newLine(), newLine(), newLine()}
            local brandTextAxis = newText()
            local brandTextLol  = newText()

            local chPos = Vector2.new(0, 0)  -- lerp target
            local chAngle = 0               -- running rotation angle

            -- Cleanup on library unload (safe pcall wrapper since OnUnload varies by Linoria version)
            Library:OnUnload(function()
                for _, l in ipairs(lines)    do pcall(function() if l.Remove then l:Remove() else l:Destroy() end end) end
                for _, l in ipairs(outlines) do pcall(function() if l.Remove then l:Remove() else l:Destroy() end end) end
                pcall(function() if brandTextAxis.Remove then brandTextAxis:Remove() else brandTextAxis:Destroy() end end)
                pcall(function() if brandTextLol.Remove then brandTextLol:Remove() else brandTextLol:Destroy() end end)
            end)

            rs:BindToRenderStep("axis_crosshair", Enum.RenderPriority.Last.Value, function(dt)
                if not Library.Running then return end
                local enabled = Toggles.CrosshairEnabled and Toggles.CrosshairEnabled.Value
                if not enabled then
                    for _, l in ipairs(lines)    do l.Visible = false end
                    for _, l in ipairs(outlines) do l.Visible = false end
                    brandTextAxis.Visible = false
                    brandTextLol.Visible  = false
                    return
                end

                local rainbow   = Toggles.CrosshairRainbow and Toggles.CrosshairRainbow.Value
                local cols      = {
                    Options.CrosshairColRight and Options.CrosshairColRight.Value or Color3.new(1,1,1),
                    Options.CrosshairColUp and Options.CrosshairColUp.Value or Color3.new(1,1,1),
                    Options.CrosshairColLeft and Options.CrosshairColLeft.Value or Color3.new(1,1,1),
                    Options.CrosshairColDown and Options.CrosshairColDown.Value or Color3.new(1,1,1)
                }
                if rainbow then
                    local hue = (tick() % 3) / 3
                    local rc  = Color3.fromHSV(hue, 1, 1)
                    cols = {rc, rc, rc, rc}
                end

                local outCol    = Options.CrosshairOutlineColor and Options.CrosshairOutlineColor.Value or Color3.new(0,0,0)
                local outline   = Toggles.CrosshairOutline and Toggles.CrosshairOutline.Value
                local offset    = Options.CrosshairOffset and Options.CrosshairOffset.Value or 4
                local length    = Options.CrosshairLength and Options.CrosshairLength.Value or 8
                local thickness = Options.CrosshairThickness and Options.CrosshairThickness.Value or 1
                local lerp      = Options.CrosshairLerp and Options.CrosshairLerp.Value or 1
                local rotBase   = math.rad(Options.CrosshairRotation and Options.CrosshairRotation.Value or 0)
                local spinSpeed = Options.CrosshairRotationSpeed and Options.CrosshairRotationSpeed.Value or 0
                local bounce    = Options.CrosshairBounce and Options.CrosshairBounce.Value or 0
                local bounceSpd = Options.CrosshairBounceSpeed and Options.CrosshairBounceSpeed.Value or 5
                local branding  = Toggles.CrosshairBranding and Toggles.CrosshairBranding.Value

                chAngle = chAngle + spinSpeed * dt * math.pi * 2
                local bounceOff = bounce > 0 and (math.abs(math.sin(tick() * bounceSpd)) * bounce) or 0
                local finalOffset = offset + bounceOff

                local target = workspace.CurrentCamera.ViewportSize / 2
                pcall(function() chPos = chPos:Lerp(target, math.min(1, lerp)) end)

                local cx, cy = math.floor(chPos.X), math.floor(chPos.Y)
                local totalAngle = rotBase + chAngle
                local dirs = {
                    Vector2.new( math.cos(totalAngle),               math.sin(totalAngle)),
                    Vector2.new(-math.sin(totalAngle),               math.cos(totalAngle)),
                    Vector2.new(-math.cos(totalAngle),              -math.sin(totalAngle)),
                    Vector2.new( math.sin(totalAngle),              -math.cos(totalAngle)),
                }

                -- Draw outlines first so they don't clip main lines
                for i, dir in ipairs(dirs) do
                    local from = Vector2.new(cx, cy) + (dir * finalOffset)
                    local to   = Vector2.new(cx, cy) + (dir * (finalOffset + length))
                    local ol = outlines[i]
                    ol.Visible = outline
                    -- extend outline by 1px mathematically to cap the ends
                    ol.From = Vector2.new(math.floor(from.X - dir.X), math.floor(from.Y - dir.Y))
                    ol.To   = Vector2.new(math.floor(to.X + dir.X),   math.floor(to.Y + dir.Y))
                    ol.Color = outCol
                    ol.Thickness = thickness + 2
                    ol.ZIndex = 1
                end

                -- Draw main lines
                for i, dir in ipairs(dirs) do
                    local from = Vector2.new(cx, cy) + (dir * finalOffset)
                    local to   = Vector2.new(cx, cy) + (dir * (finalOffset + length))
                    local ml = lines[i]
                    ml.Visible = true
                    ml.From = Vector2.new(math.floor(from.X), math.floor(from.Y))
                    ml.To   = Vector2.new(math.floor(to.X),   math.floor(to.Y))
                    ml.Color = cols[i]
                    ml.Thickness = thickness
                    ml.ZIndex = 3
                end

                -- Split Branding Text ("axis" in white, ".lol" in accent)
                brandTextAxis.Visible = branding
                brandTextLol.Visible  = branding
                if branding then
                    brandTextAxis.Text = "axis"
                    brandTextAxis.Color = Color3.new(1,1,1)
                    brandTextAxis.OutlineColor = outCol
                    brandTextAxis.Center = false
                    
                    brandTextLol.Text = ".lol"
                    brandTextLol.Color = Color3.fromRGB(74, 124, 155)
                    brandTextLol.OutlineColor = outCol
                    brandTextLol.Center = false
                    
                    local tw1 = brandTextAxis.TextBounds.X
                    local tw2 = brandTextLol.TextBounds.X
                    local tot = tw1 + tw2
                    local startX = math.floor(cx - (tot / 2))
                    local txtY = math.floor(cy + finalOffset + length + 6)
                    
                    brandTextAxis.Position = Vector2.new(startX, txtY)
                    brandTextLol.Position = Vector2.new(startX + tw1, txtY)
                end
            end)
        end)()

        -- Load final config after all UI elements are created
        SaveManager:SetFolder("axislol/configs")
        ThemeManager:SetFolder("axislol/themes")
        pcall(function() SaveManager:LoadAutoloadConfig() end)
        ThemeManager:LoadAutoloadTheme()

        -- Silent Load: Hide menu on launch if enabled
        if Toggles.SilentLoad and Toggles.SilentLoad.Value then
            Window.Visible = false
        end

        -- Sync initial cursor state based on final visibility
        if Window.Visible then
            if CustomCursor then CustomCursor.Visible = true end
            uis.MouseIconEnabled = false
        else
            if CustomCursor then CustomCursor.Visible = false end
            uis.MouseIconEnabled = true
        end

        Notify("axis.lol fully loaded [v2.0.0]", 3)

        -- Final Cleanup & Identity Trigger
        _G.axis_TriggerIdentity = function()
            task.spawn(function()
                pcall(function()
                    local id = Options.SpoofVictimID and Options.SpoofVictimID.Value
                    if id and id ~= "" and id ~= "1" then
                        _G.axis_ApplySpoofIdentity()
                    end
                end)
            end)
        end

        task.spawn(function()
            task.wait(1.5)
            if _G.axis_TriggerIdentity then _G.axis_TriggerIdentity() end
        end)

        -- ============================================================
        -- TEXTURE PACK (MaterialService / MaterialVariant)
        -- Source: https://github.com/cloudsense-pub/assets/tree/main/textures
        -- Each material folder contains diffuse.dds + normal.dds.
        -- We download with getExternalAsset (writefile+getcustomasset),
        -- then create MaterialVariant instances in MaterialService.
        -- Files are cached by name so re-enabling won't re-download.
        -- ============================================================
        task.spawn(function()
            local texPackVariants = {}
            local texPackDownloaded = false
            local TEX_BASE = "https://raw.githubusercontent.com/cloudsense-pub/assets/refs/heads/main/textures/"
            local TEX_MATERIALS = {
                { folder = "brick",        mat = Enum.Material.Brick        },
                { folder = "cobblestone",  mat = Enum.Material.Cobblestone  },
                { folder = "concrete",     mat = Enum.Material.Concrete     },
                { folder = "diamondplate", mat = Enum.Material.DiamondPlate },
                { folder = "fabric",       mat = Enum.Material.Fabric       },
                { folder = "granite",      mat = Enum.Material.Granite      },
                { folder = "grass",        mat = Enum.Material.Grass        },
                { folder = "ice",          mat = Enum.Material.Ice          },
                { folder = "marble",       mat = Enum.Material.Marble       },
                { folder = "metal",        mat = Enum.Material.Metal        },
                { folder = "pebble",       mat = Enum.Material.Pebble       },
                { folder = "plastic",      mat = Enum.Material.Plastic      },
                { folder = "sand",         mat = Enum.Material.Sand         },
                { folder = "slate",        mat = Enum.Material.Slate        },
                { folder = "wood",         mat = Enum.Material.Wood         },
                { folder = "woodplanks",   mat = Enum.Material.WoodPlanks   },
                { folder = "glass",        mat = Enum.Material.Glass        },
            }
            local function removeTexturePack()
                local MS = game:GetService("MaterialService")
                for _, entry in ipairs(TEX_MATERIALS) do
                    pcall(function()
                        MS[entry.mat.Name .. "Name"] = ""
                    end)
                end
                for _, v in pairs(texPackVariants) do
                    pcall(function() v:Destroy() end)
                end
                texPackVariants = {}
            end
            local function downloadAndApplyTexturePack()
                local MS = game:GetService("MaterialService")
                local applied = 0
                local failed  = 0
                local function fetchTex(folder, file)
                    local fname = "axis_tex_" .. folder .. "_" .. file:gsub("%.", "_") .. ".png"
                    return getExternalAsset(
                        "https://media.githubusercontent.com/media/cloudsense-pub/assets/main/textures/" .. folder .. "/" .. file,
                        fname
                    ) or getExternalAsset(
                        TEX_BASE .. folder .. "/" .. file,
                        fname
                    )
                end
                for _, entry in ipairs(TEX_MATERIALS) do
                    task.wait()
                    pcall(function()
                        local folder  = entry.folder
                        local diffuse = fetchTex(folder, "diffuse.dds")
                        local normal  = fetchTex(folder, "normal.dds")
                        if diffuse or normal then
                            local v = Instance.new("MaterialVariant")
                            v.Name         = "AxisTex_" .. folder
                            v.BaseMaterial = entry.mat
                            if diffuse then v.ColorMap  = diffuse end
                            if normal  then v.NormalMap = normal  end
                            v.Parent = MS
                            
                            -- Globally set material variant override on MaterialService
                            MS[entry.mat.Name .. "Name"] = v.Name
                            
                            table.insert(texPackVariants, v)
                            applied = applied + 1
                        else
                            failed = failed + 1
                        end
                    end)
                end
                texPackDownloaded = true
                if applied > 0 then
                    Library:Notify("Texture Pack: " .. applied .. "/" .. (applied + failed) .. " materials applied!", 5)
                else
                    Library:Notify("Texture Pack: All downloads failed. Check executor writefile/getcustomasset support.", 8)
                end
            end
            Toggles.TexturePackEnabled:OnChanged(function()
                if Toggles.TexturePackEnabled.Value then
                    task.spawn(downloadAndApplyTexturePack)
                else
                    removeTexturePack()
                end
            end)
        end)

        task.spawn(function()
            task.wait(2.5)
            if _G.axis_TriggerIdentity then _G.axis_TriggerIdentity() end
        end)


        --// [[ Feature Modules Scope ]]
        task.spawn(function()
            local lp = playersService.LocalPlayer
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local camera = workspace.CurrentCamera
            local chAngle = 0
            
        local DynamicWhitelist = {}
        local KATANA_SOUNDS = {
            "rbxassetid://14798337918", -- Default
            "rbxassetid://17640978498", -- Saber
            "rbxassetid://17641044986", -- Saber
            "rbxassetid://101419032712753", -- Lightning Bolt
            "rbxassetid://130523978733899", -- Lightning Bolt
            "rbxassetid://114054077914317", -- Pixel
            "rbxassetid://90757583550672", -- Keytana
            "rbxassetid://116868301514983", -- Arch Katana
            "rbxassetid://118748685078128", -- Crystal Katana
            "rbxassetid://125777995479531", -- Crystal Katana
            "rbxassetid://12222208", -- Linked Sword
            "rbxassetid://16828414433", -- Deflect Cooldown ID
            "14798337918",
            "17640978498",
            "17641044986",
            "101419032712753",
            "130523978733899",
            "114054077914317",
            "90757583550672",
            "116868301514983",
            "118748685078128",
            "125777995479531",
            "12222208",
            "16828414433"
        }
        
        -- Active Weapon Detector (Startup Init)
        local initWeapon = nil
        pcall(function()
            lp = playersService.LocalPlayer
            local char = lp.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then initWeapon = tool.Name end
            end
            if not initWeapon then
                local ViewModels = workspace:FindFirstChild("ViewModels")
                local fp = ViewModels and ViewModels:FindFirstChild("FirstPerson")
                if fp then
                    for _, vm in pairs(fp:GetChildren()) do
                        local user, weapon = vm.Name:match("^([^-]+) %- ([^-]+)")
                        if user and user:gsub("%s+$", "") == lp.Name then
                            initWeapon = weapon:gsub("^%s+", ""):gsub("%s+$", "")
                            break
                        end
                    end
                end
            end
        end)
        _G.ActiveWeaponName = initWeapon or _G.ActiveWeaponName
        
        task.spawn(function()
            lp = playersService.LocalPlayer
            while scriptActive and task.wait(0.1) do
                local newWhitelist = {}
                
                -- 1. Viewmodel Shield Check
                local ViewModels = workspace:FindFirstChild("ViewModels")
                if ViewModels then
                    local fp = ViewModels:FindFirstChild("FirstPerson")
                    if fp then
                        for _, vm in pairs(fp:GetChildren()) do
                            if vm.Name:find("Riot Shield") then
                                local username = vm.Name:match("^(.+) %- Riot Shield %-.+$")
                                if username then
                                    newWhitelist[username] = true
                                end
                            end
                        end
                    end
                end
                
                -- 2. Multi-layered Katana Deflect / Shield / Invincibility check
                for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= lp and p.Character then
                        pcall(function()
                            local char = p.Character
                            
                            -- A. Invincibility check
                            local invincible = false
                            if char:FindFirstChild("ForceField") or char:GetAttribute("Protected") or char:GetAttribute("SpawnProtection") or p:GetAttribute("Protected") or p:GetAttribute("SpawnProtection") then
                                invincible = true
                            end
                            if not invincible and _G.FighterController then
                                pcall(function()
                                    local fighter = _G.FighterController:GetFighter(p)
                                    if fighter and fighter.Entity and fighter.Entity:Get("IsInvincible") then
                                        invincible = true
                                    end
                                end)
                            end

                            -- B. Katana parry check
                            local isParrying = false
                            if char:FindFirstChild("_katana_deflect_active_not_local", true) or char:FindFirstChild("_katana_deflect_active", true) then
                                isParrying = true
                            end
                            if not isParrying then
                                for _, child in ipairs(char:GetChildren()) do
                                    if child:IsA("Tool") then
                                        local name = child.Name:lower()
                                        if name:find("katana") or name:find("blade") then
                                            if child:GetAttribute("Deflecting") or child:GetAttribute("Parrying") then
                                                isParrying = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            if not isParrying then
                                local cacheData = CharacterCache[char]
                                if cacheData and cacheData.Sounds then
                                    for _, obj in ipairs(cacheData.Sounds) do
                                        if obj.Playing then
                                            local soundId = obj.SoundId
                                            for _, checkId in ipairs(KATANA_SOUNDS) do
                                                if soundId:find(checkId) then
                                                    isParrying = true
                                                    break
                                                end
                                            end
                                            if isParrying then break end
                                        end
                                    end
                                else
                                    for _, obj in ipairs(char:GetDescendants()) do
                                        if obj:IsA("Sound") and obj.Playing then
                                            local soundId = obj.SoundId
                                            for _, checkId in ipairs(KATANA_SOUNDS) do
                                                if soundId:find(checkId) then
                                                    isParrying = true
                                                    break
                                                end
                                            end
                                            if isParrying then break end
                                        end
                                    end
                                end
                            end
                            if not isParrying then
                                local humanoid = char:FindFirstChildOfClass("Humanoid")
                                local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid)
                                if animator then
                                    local tracks = animator:GetPlayingAnimationTracks()
                                    for _, track in ipairs(tracks) do
                                        local animName = string.lower(track.Name or "")
                                        if animName:find("deflect") or animName:find("parry") or animName:find("shield") then
                                            isParrying = true
                                            break
                                        end
                                    end
                                end
                            end
                            
                            -- C. Shield check
                            local hasShield = false
                            local shield = char:FindFirstChild("RiotShield") or char:FindFirstChild("Riot Shield")
                            if shield and (shield:GetAttribute("Active") or shield:FindFirstChild("Handle") or shield:FindFirstChild("Handle", true)) then
                                hasShield = true
                            end
                            if not hasShield then
                                for _, child in ipairs(char:GetChildren()) do
                                    if child:IsA("Tool") or child:IsA("Model") then
                                        local name = string.lower(child.Name)
                                        if name:find("shield") then
                                            hasShield = true
                                            break
                                        end
                                    end
                                end
                            end
                            if newWhitelist[p.Name] then
                                hasShield = true
                            end
                            
                            if isParrying or hasShield then
                                newWhitelist[p.Name] = true
                            end
                            
                            -- Active weapon detection
                            local activeWeapon = nil
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                activeWeapon = tool.Name
                            end
                            if not activeWeapon then
                                local _bodyParts = {
                                    HumanoidRootPart=true,Head=true,UpperTorso=true,LowerTorso=true,
                                    LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
                                    RightUpperArm=true,RightLowerArm=true,RightHand=true,
                                    LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,
                                    RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
                                    Humanoid=true,Animate=true,HitboxBody=true,
                                }
                                for _, child in ipairs(char:GetChildren()) do
                                    if (child:IsA("Model") or child:IsA("Tool")) and not _bodyParts[child.Name] then
                                        activeWeapon = child.Name
                                        break
                                    end
                                end
                            end
                            if not activeWeapon then
                                local vmCtrl = char:FindFirstChild("ViewmodelController")
                                if vmCtrl and vmCtrl:GetAttribute("Equipped") then
                                    for _, child in ipairs(char:GetChildren()) do
                                        if not child:IsA("BasePart") and not child:IsA("Humanoid")
                                            and not child:IsA("Script") and not child:IsA("LocalScript")
                                            and not child:IsA("StringValue") and not child:IsA("Animation")
                                            and child.Name ~= "Animate" and child.Name ~= "HitboxBody" then
                                            activeWeapon = child.Name
                                            break
                                        end
                                    end
                                end
                            end

                            PlayerDefenseStates[p] = {
                                Invincible = invincible,
                                IsParrying = isParrying,
                                HasShield = hasShield,
                                ActiveWeapon = activeWeapon
                            }
                        end)
                    end
                end
                
                DynamicWhitelist = newWhitelist
            end
        end)

        --// Custom Rage: Silent Aim Module
        SilentAim = {
            Target = nil,
            Circle = nil
        }

        -- Initialize FOV Circle
        pcall(function()
            local circle = Drawing.new("Circle")
            circle.Thickness = 1
            circle.NumSides = 60
            circle.Radius = 150
            circle.Filled = false
            circle.Transparency = 1
            circle.Color = Color3.fromRGB(200, 200, 200)
            circle.Visible = false
            SilentAim.Circle = circle
        end)

        local SharedRaycastParams = RaycastParams.new()
        SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local LocalFilterTable = { nil, nil }
        local function updateRaycastFilter()
            LocalFilterTable[1] = workspace.CurrentCamera
            LocalFilterTable[2] = lp.Character
            SharedRaycastParams.FilterDescendantsInstances = LocalFilterTable
        end
        Library:Track(lp.CharacterAdded:Connect(updateRaycastFilter))
        Library:Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateRaycastFilter))
        updateRaycastFilter()

        local function updateTargets()
            CachedSilentAimTarget = nil
            CachedNearestEnemyRoot = nil
            CachedOrbitTarget = nil

            local myChar = lp.Character
            local cachedMyChar = myChar and CharacterCache[myChar]
            local myHrp = cachedMyChar and (cachedMyChar.HumanoidRootPart or cachedMyChar.Parts["HitboxBody"])
            if not myHrp then return end

            local cam = workspace.CurrentCamera
            local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            local fovRadius = (Options.SilentAimFOV and Options.SilentAimFOV.Value) or 1000
            
            local bestAimDist = fovRadius
            local bestOrbitDist = math.huge
            local bestNearestDist = math.huge

            local activePlayers = playersService:GetPlayers()
            for i = 1, #activePlayers do
                local v = activePlayers[i]
                if v == lp or (lp and (v.UserId == lp.UserId or v.Name == lp.Name)) then continue end
                
                if Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value and Teammates[v] then continue end
                if getgenv().WhitelistedPlayers and getgenv().WhitelistedPlayers[v.UserId] then continue end

                local char = v.Character
                if not char then continue end
                
                local cached = CharacterCache[char]
                if not cached then
                    pcall(cacheCharacter, char)
                    cached = CharacterCache[char]
                end
                if not cached then continue end

                local hum = cached.Humanoid
                if not hum or hum.Health <= 0 then continue end

                local hrp = cached.HumanoidRootPart
                if not hrp then continue end

                local defense = PlayerDefenseStates[v]
                local invincible = defense and defense.Invincible
                if invincible == nil then
                    invincible = false
                    if char:FindFirstChild("ForceField") or char:GetAttribute("Protected") or char:GetAttribute("SpawnProtection") or v:GetAttribute("Protected") or v:GetAttribute("SpawnProtection") then
                        invincible = true
                    end
                    if not invincible and _G.FighterController then
                        pcall(function()
                            local fighter = _G.FighterController:GetFighter(v)
                            if fighter and fighter.Entity and fighter.Entity:Get("IsInvincible") then
                                invincible = true
                            end
                        end)
                    end
                end
                if invincible then continue end

                local hasShield = defense and defense.HasShield
                if hasShield == nil then
                    hasShield = false
                    if Toggles.IgnoreShield and Toggles.IgnoreShield.Value then
                        local shield = char:FindFirstChild("RiotShield")
                        if shield and (shield:GetAttribute("Active") or shield:FindFirstChild("Handle")) then
                            hasShield = true
                        end
                    end
                    if Toggles.AntiShield and Toggles.AntiShield.Value and not hasShield then
                        if char:FindFirstChild("RiotShield") or char:FindFirstChild("Riot Shield") or DynamicWhitelist[v.Name] then
                            hasShield = true
                        end
                    end
                end
                if hasShield and ((Toggles.IgnoreShield and Toggles.IgnoreShield.Value) or (Toggles.AntiShield and Toggles.AntiShield.Value)) then continue end

                local isParrying = defense and defense.IsParrying
                if isParrying == nil then
                    isParrying = false
                    if Toggles.IgnoreKatana and Toggles.IgnoreKatana.Value then
                        local tool = char:FindFirstChildWhichIsA("Tool")
                        if tool and (tool.Name:lower():find("katana") or tool.Name:lower():find("blade")) then
                            if tool:GetAttribute("Deflecting") or tool:GetAttribute("Parrying") then
                                isParrying = true
                            end
                        end
                    end
                    if Toggles.AntiKatana and Toggles.AntiKatana.Value and not isParrying then
                        if char:FindFirstChild("_katana_deflect_active_not_local", true) or char:FindFirstChild("_katana_deflect_active", true) then
                            isParrying = true
                        end
                    end
                end
                if isParrying and ((Toggles.IgnoreKatana and Toggles.IgnoreKatana.Value) or (Toggles.AntiKatana and Toggles.AntiKatana.Value)) then continue end

                local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v] or hrp.CFrame
                local distance = (myHrp.Position - realCF.Position).Magnitude

                if distance < bestNearestDist then
                    bestNearestDist = distance
                    CachedNearestEnemyRoot = hrp
                end

                if distance < bestOrbitDist then
                    bestOrbitDist = distance
                    CachedOrbitTarget = v
                end

                local targetPart = cached.Head
                for _, part in ipairs(cached.HitboxParts) do
                    if part.Name == "HitboxHead" then
                        targetPart = part
                        break
                    end
                end
                if targetPart then
                    local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v]
                    local aimPos = realCF and (realCF.Position + Vector3.new(0, 1.5, 0)) or targetPart.Position
                    if Toggles.SilentAimPrediction and Toggles.SilentAimPrediction.Value then
                        local vel = hrp.AssemblyLinearVelocity
                        local dist = (aimPos - cam.CFrame.Position).Magnitude
                        local mult = (Options.PredictionStrength and Options.PredictionStrength.Value) or 1
                        aimPos = aimPos + vel * (dist / 999999) * mult
                    end

                    local screenPos, onScreen = cam:WorldToViewportPoint(aimPos)
                    if onScreen then
                        local isVisible = true
                        if Toggles.VisibleOnly and Toggles.VisibleOnly.Value then
                            local ray = workspace:Raycast(cam.CFrame.Position, (aimPos - cam.CFrame.Position), SharedRaycastParams)
                            if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then
                                isVisible = false
                            end
                        end
                        if isVisible then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D < bestAimDist then
                                bestAimDist = dist2D
                                CachedSilentAimTarget = v
                            end
                        end
                    end
                end
            end
        end

        local function getSilentAimTarget()
            if Toggles.DisableOnFlash and Toggles.DisableOnFlash.Value then
                local gui = lp:FindFirstChild("PlayerGui")
                if gui then
                    local fx = gui:FindFirstChild("Flash") or gui:FindFirstChild("Stun")
                    if fx and fx:IsA("GuiObject") and fx.Visible and fx.BackgroundTransparency < 0.5 then
                        return nil
                    end
                end
            end
            return CachedSilentAimTarget
        end

        GetClosestTarget = getSilentAimTarget


        -- [[ Triggerbot Backend Loop Engine ]]
        task.spawn(function()
            local mouse = lp:GetMouse()
            local lastTriggerTick = 0
            
            local function isTeammate(plr)
                if Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value and Teammates[plr] then 
                    return true 
                end
                return false
            end

            Library:Track(game:GetService("RunService").Heartbeat:Connect(function()
                pcall(function()
                    if not (Toggles.Triggerbot and Toggles.Triggerbot.Value) then return end
                    
                    -- Guard: Flash/stun check
                    if Toggles.DisableOnFlash and Toggles.DisableOnFlash.Value then
                        local gui = lp:FindFirstChild("PlayerGui")
                        if gui then
                            local fx = gui:FindFirstChild("Flash") or gui:FindFirstChild("Stun")
                            if fx and fx:IsA("GuiObject") and fx.Visible and fx.BackgroundTransparency < 0.5 then
                                return
                            end
                        end
                    end

                    local targetInstance = mouse.Target
                    if not targetInstance then return end
                    
                    local model = targetInstance:FindFirstAncestorOfClass("Model")
                    if not model then return end
                    
                    local enemyPlayer = game:GetService("Players"):GetPlayerFromCharacter(model)
                    if not enemyPlayer or enemyPlayer == lp then return end
                    
                    -- Check Teammate
                    if isTeammate(enemyPlayer) then return end
                    
                    local char = enemyPlayer.Character
                    if not char then return end
                    
                    local cachedEnemy = CharacterCache[char]
                    if not cachedEnemy then return end
                    local hum = cachedEnemy.Humanoid
                    if not hum or hum.Health <= 0 then return end
                    
                    local hrp = cachedEnemy.HumanoidRootPart
                    local cachedMyChar = lp.Character and CharacterCache[lp.Character]
                    local myHrp = cachedMyChar and cachedMyChar.HumanoidRootPart
                    if not hrp or not myHrp then return end
                    
                    -- Distance/Range Check
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    local maxRange = (Options.TriggerbotRange and Options.TriggerbotRange.Value) or 1000
                    if distance > maxRange then return end

                    local defense = PlayerDefenseStates[enemyPlayer]
                    -- Forcefield / Invincibility / Shield Check
                    if Toggles.TriggerbotForcefieldCheck and Toggles.TriggerbotForcefieldCheck.Value then
                        if defense and (defense.Invincible or defense.HasShield) then
                            return
                        end
                    end

                    -- Katana Parry/Deflect check
                    if Toggles.TriggerbotKatanaCheck and Toggles.TriggerbotKatanaCheck.Value then
                        if defense and defense.IsParrying then
                            return
                        end
                    end

                    -- Verify target is visible (optional but highly recommended for triggerbots)
                    if Toggles.VisibleOnly and Toggles.VisibleOnly.Value then
                        local cam = workspace.CurrentCamera
                        local ray = workspace:Raycast(cam.CFrame.Position, (hrp.Position - cam.CFrame.Position), SharedRaycastParams)
                        if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then 
                            return 
                        end
                    end

                    -- Execute Fire/Attack action
                    local now = tick()
                    if now - lastTriggerTick > 0.05 then -- Debounce/cooldown to emulate realistic click rates
                        lastTriggerTick = now
                        
                        -- Method 1: Tool activation
                        local activeTool = lp.Character and lp.Character:FindFirstChildWhichIsA("Tool")
                        if activeTool then
                            activeTool:Activate()
                        end
                        
                        -- Method 2: Executor native click simulation
                        if mouse1click then
                            mouse1click()
                        elseif mouse1press and mouse1release then
                            mouse1press()
                            task.wait(0.01)
                            mouse1release()
                        else
                            -- Method 3: Virtual Input Manager fallback
                            local vim = game:GetService("VirtualInputManager")
                            if vim then
                                vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
                                task.wait(0.01)
                                vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
                            end
                        end
                    end
                end)
            end))
        end)

        -- [[ FOV Visuals Engine ]]
        local FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1
        FOVCircle.NumSides = 100
        FOVCircle.Radius = 150
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.Color = Color3.fromRGB(180, 55, 255)

        local FOVFill = Drawing.new("Circle")
        FOVFill.Thickness = 1
        FOVFill.NumSides = 100
        FOVFill.Radius = 150
        FOVFill.Filled = true
        FOVFill.Visible = false
        FOVFill.Color = FOVCircle.Color
        FOVFill.Transparency = 0.2

        -- [[ ESP Logic Engine ]]
        local ESP_Cache = {}
        local Skeleton_Parts = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
        }

        local function CreateESP(plr)
            local data = {
                BoxOutline = Drawing.new("Square"),
                Box = Drawing.new("Square"),
                BoxFill = Drawing.new("Square"),
                Name = Drawing.new("Text"),
                Distance = Drawing.new("Text"),
                HealthBarBG = Drawing.new("Line"),
                HealthBar = Drawing.new("Line"),
                Tracer = Drawing.new("Line"),
                LookTracer = Drawing.new("Line"),
                OSIndicator = Drawing.new("Triangle"),
                Snapline = Drawing.new("Line"),
                HeadDot = Drawing.new("Circle"),
                Weapon = Drawing.new("Text"),
                HealthNum = Drawing.new("Text"),
                CornerOutlines = {},
                CornerLines = {},
                Skeleton = {}
            }
            for i=1, #Skeleton_Parts do data.Skeleton[i] = Drawing.new("Line") end
            for i=1, 8 do
                data.CornerOutlines[i] = Drawing.new("Line")
                data.CornerOutlines[i].Thickness = 3
                data.CornerOutlines[i].Color = Color3.new(0, 0, 0)
                data.CornerOutlines[i].Visible = false
                pcall(function() data.CornerOutlines[i].ZIndex = 1 end)

                data.CornerLines[i] = Drawing.new("Line")
                data.CornerLines[i].Thickness = 1
                data.CornerLines[i].Visible = false
                pcall(function() data.CornerLines[i].ZIndex = 2 end)
            end
            
            data.BoxOutline.Thickness = 3; data.BoxOutline.Color = Color3.new(0,0,0)
            pcall(function() data.BoxOutline.ZIndex = 1 end)
            
            data.Box.Thickness = 1; data.Box.Filled = false
            pcall(function() data.Box.ZIndex = 2 end)
            
            data.BoxFill.Thickness = 0; data.BoxFill.Filled = true; data.BoxFill.Visible = false
            pcall(function() data.BoxFill.ZIndex = 0 end)
            
            data.Name.Size = 13; data.Name.Center = true; data.Name.Outline = true
            data.Distance.Size = 11; data.Distance.Center = true; data.Distance.Outline = true
            
            data.HealthBarBG.Thickness = Options.ESPHealthThick and Options.ESPHealthThick.Value or 2; data.HealthBarBG.Color = Color3.new(0,0,0)
            pcall(function() data.HealthBarBG.ZIndex = 1 end)
            
            data.HealthBar.Thickness = Options.ESPHealthThick and Options.ESPHealthThick.Value or 2
            pcall(function() data.HealthBar.ZIndex = 2 end)
            
            data.Tracer.Thickness = 1; data.Tracer.Visible = false
            data.LookTracer.Thickness = 1.5; data.LookTracer.Visible = false
            data.OSIndicator.Thickness = 1.5; data.OSIndicator.Filled = true; data.OSIndicator.Visible = false
            data.Snapline.Thickness = 1; data.Snapline.Visible = false
            data.HeadDot.Radius = 4; data.HeadDot.Filled = true; data.HeadDot.Visible = false
            data.Weapon.Size = 11; data.Weapon.Center = true; data.Weapon.Outline = true; data.Weapon.Visible = false
            data.HealthNum.Size = 10; data.HealthNum.Center = true; data.HealthNum.Outline = true; data.HealthNum.Visible = false
            ESP_Cache[plr] = data
        end

        local function RemoveESP(plr)
            if ESP_Cache[plr] then
                pcall(function()
                    if ESP_Cache[plr].Highlight then ESP_Cache[plr].Highlight:Destroy() end
                end)
                for _, v in pairs(ESP_Cache[plr]) do 
                    if type(v) == "table" then
                        for _, l in pairs(v) do pcall(function() l:Remove() end) end
                    else
                        pcall(function() v:Remove() end)
                    end
                end
                ESP_Cache[plr] = nil
            end
        end

        -- Clean up ESP when a player leaves the game
        Library:Track(game:GetService("Players").PlayerRemoving:Connect(function(plr)
            RemoveESP(plr)
        end))

        -- Clean up ESP when a player's character is removed (respawn/death)
        -- so stale drawings don't ghost until the render loop catches up
        Library:Track(game:GetService("Players").PlayerAdded:Connect(function(plr)
            Library:Track(plr.CharacterRemoving:Connect(function()
                RemoveESP(plr)
            end))
        end))
        -- Also hook already-present players
        for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= lp then
                Library:Track(plr.CharacterRemoving:Connect(function()
                    RemoveESP(plr)
                end))
            end
        end

        local function setupWeather()
            pcall(function()
                local existing = workspace:FindFirstChild("AxisWeather")
                if existing then existing:Destroy() end
                
                Weather.Part = Instance.new("Part")
                Weather.Part.Name = "AxisWeather"
                Weather.Part.Size = Vector3.new(150, 2, 150)
                Weather.Part.Transparency = 1
                Weather.Part.Anchored = true
                Weather.Part.CanCollide = false
                Weather.Part.CanTouch = false
                Weather.Part.CanQuery = false
                Weather.Part.Parent = workspace
                
                Weather.Rain = Instance.new("ParticleEmitter")
                Weather.Rain.Name = "Rain"
                Weather.Rain.Texture = "rbxassetid://1084991219"
                Weather.Rain.Size = NumberSequence.new(0.4)
                Weather.Rain.Speed = NumberRange.new(60, 90)
                Weather.Rain.Lifetime = NumberRange.new(1, 1.5)
                Weather.Rain.Rate = 150
                Weather.Rain.Transparency = NumberSequence.new(0.5)
                Weather.Rain.Orientation = Enum.ParticleOrientation.VelocityParallel
                Weather.Rain.Enabled = false
                Weather.Rain.Parent = Weather.Part
                
                Weather.Snow = Instance.new("ParticleEmitter")
                Weather.Snow.Name = "Snow"
                Weather.Snow.Texture = "rbxassetid://1084991219"
                Weather.Snow.Size = NumberSequence.new(0.6)
                Weather.Snow.Speed = NumberRange.new(15, 25)
                Weather.Snow.Lifetime = NumberRange.new(2, 3)
                Weather.Snow.Rate = 80
                Weather.Snow.Transparency = NumberSequence.new(0.3)
                Weather.Snow.Enabled = false
                Weather.Snow.Parent = Weather.Part
            end)
        end
        setupWeather()

        -- [[ Viewmodel Optimization Caching ]]
        local lastVM = nil
        local cachedGunParts = {}
        local cachedArmParts = {}
        local cachedAllParts = {}
        local cachedJoints = {}
        local cachedDecals = {}

        -- [[ Consolidated RenderStepped Loop (Visuals & Targets) ]]
        Library:Track(rs.RenderStepped:Connect(function(dt)
            if not Library.Running then return end
            
            -- Run unified single-pass player scan
            pcall(updateTargets)
            
            -- 1. Target Acquisition (Shared for Silent Aim & Camera Aimbot / Cam Lock)
            local currentTarget = nil
            local silentAimActive = Toggles.SilentAim and Toggles.SilentAim.Value
            local camLockEnabled = Toggles.CamLock and Toggles.CamLock.Value
            local camLockActive = camLockEnabled and Options.CamLockKeybind and Options.CamLockKeybind:GetState()
            
            if silentAimActive or camLockActive then
                currentTarget = GetClosestTarget()
            end
            SilentAim.Target = currentTarget

            -- 1.1 Camera Aimbot (Cam Lock)
            if camLockActive and currentTarget and currentTarget.Character then
                local targetPart = currentTarget.Character:FindFirstChild("HitboxHead") or currentTarget.Character:FindFirstChild("Head")
                if targetPart then
                    local cam = workspace.CurrentCamera
                    local targetPos = targetPart.Position
                    local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
                    if Toggles.SilentAimPrediction and Toggles.SilentAimPrediction.Value and hrp then
                        local vel = hrp.AssemblyLinearVelocity
                        local dist = (targetPos - cam.CFrame.Position).Magnitude
                        local mult = Options.PredictionStrength and Options.PredictionStrength.Value or 1
                        targetPos = targetPos + vel * (dist / 999999) * mult
                    end
                    local targetCFrame = CFrame.new(cam.CFrame.Position, targetPos)
                    
                    local smoothingVal = Options.CamLockSmoothing and Options.CamLockSmoothing.Value or 20
                    local alpha = math.clamp((101 - smoothingVal) / 100, 0.01, 1)
                    
                    cam.CFrame = cam.CFrame:Lerp(targetCFrame, alpha)
                end
            end

            -- 2. FOV Visuals
            local showFovTog = Toggles.ShowFOV and Toggles.ShowFOV.Value
            local silentAimTog = Toggles.SilentAim and Toggles.SilentAim.Value
            local autoFireTog = Toggles.AutoFire and Toggles.AutoFire.Value
            local fovOutlineTog = Toggles.FOVOutline and Toggles.FOVOutline.Value
            local fovFillTog = Toggles.FOVFill and Toggles.FOVFill.Value
            
            local enabled = showFovTog and (silentAimTog or autoFireTog)
            local mousePos = uis:GetMouseLocation()
            
            pcall(function()
                FOVCircle.Visible = enabled and true or false
                if enabled and Options.SilentAimFOV and Options.SilentAimFOVColor then
                    FOVCircle.Radius = Options.SilentAimFOV.Value or 100
                    FOVCircle.Position = mousePos
                    FOVCircle.Thickness = fovOutlineTog and 3 or 1
                    FOVCircle.Color = Options.SilentAimFOVColor.Value or Color3.fromRGB(255, 255, 255)
                    
                    FOVFill.Visible = fovFillTog and true or false
                    FOVFill.Radius = FOVCircle.Radius
                    FOVFill.Position = mousePos
                    FOVFill.Color = Options.SilentAimFOVColor.Value or Color3.fromRGB(255, 255, 255)
                else
                    FOVCircle.Visible = false
                    FOVFill.Visible = false
                end
            end)
            
            -- 3. Camera & Viewmodel
            local thirdPersonTog = Toggles.ThirdPersonEnabled and Toggles.ThirdPersonEnabled.Value
            if thirdPersonTog and Options.ThirdPersonDist then
                lp.CameraMaxZoomDistance = Options.ThirdPersonDist.Value or 12.8
                lp.CameraMinZoomDistance = Options.ThirdPersonDist.Value or 12.8
            else
                lp.CameraMaxZoomDistance = 12.8
                lp.CameraMinZoomDistance = 0.5
            end

            local fovEnabledTog = Toggles.FOVEnabled and Toggles.FOVEnabled.Value
            if fovEnabledTog and Options.FOVValue then
                camera.FieldOfView = Options.FOVValue.Value or 70
            end

            pcall(function()
                local vm = currentVM
                if not vm then
                    vm = camera:FindFirstChild("ViewModel") or camera:FindFirstChildWhichIsA("Model")
                    if vm and vm ~= lastVM then
                        cachedItemVisual = vm:FindFirstChild("ItemVisual")
                    end
                end

                if vm then
                    if lastVM ~= vm then
                        lastVM = vm
                        cachedGunParts = {}
                        cachedArmParts = {}
                        cachedAllParts = {}
                        cachedJoints = {}
                        table.clear(cachedDecals)
                        
                        local itemVisual = cachedItemVisual
                        for _, part in ipairs(vm:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                table.insert(cachedAllParts, part)
                                if itemVisual and part:IsDescendantOf(itemVisual) then
                                    table.insert(cachedGunParts, part)
                                else
                                    if part.Name ~= "HumanoidRootPart" and part.Name ~= "RootPart" and part.Name ~= "PrimaryPart" then
                                        table.insert(cachedArmParts, part)
                                    end
                                end
                                
                                local partDecals = {}
                                for _, child in ipairs(part:GetChildren()) do
                                    if child:IsA("Decal") or child:IsA("Texture") then
                                        table.insert(partDecals, child)
                                    end
                                end
                                cachedDecals[part] = partDecals
                            end
                            if part:IsA("Motor6D") or part:IsA("Weld") or part:IsA("ManualWeld") then
                                table.insert(cachedJoints, part)
                            end
                        end
                    end

                    if Toggles.NoSway and Toggles.NoSway.Value then
                        -- Lock VM to camera to prevent sway
                        vm:PivotTo(camera.CFrame)
                    end

                    -- Pre-compute weapon override material
                    local weaponMaterial = Enum.Material.Plastic
                    if Toggles.VMWeaponOverride and Toggles.VMWeaponOverride.Value and Options.VMWeaponMaterial then
                        local matVal = Options.VMWeaponMaterial.Value
                        if type(matVal) == "number" then
                            local mats = {"Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Glass", "ForceField", "Foil", "DiamondPlate"}
                            weaponMaterial = Enum.Material[mats[matVal] or "Plastic"] or Enum.Material.Plastic
                        else
                            local ok, mat = pcall(function() return Enum.Material[matVal] end)
                            weaponMaterial = ok and mat or Enum.Material.Plastic
                        end
                    end

                    -- Apply Weapon Overrides
                    for _, part in ipairs(cachedGunParts) do
                        if not part:GetAttribute("OrigColor") then
                            part:SetAttribute("OrigColor", part.Color)
                            part:SetAttribute("OrigMaterial", part.Material.Name)
                            part:SetAttribute("OrigTrans", part.Transparency)
                            if part:IsA("MeshPart") then
                                part:SetAttribute("OrigTexture", part.TextureID)
                            end
                        end
                        if Toggles.VMWeaponOverride and Toggles.VMWeaponOverride.Value and Options.VMWeaponColor and Options.VMWeaponMaterial and Options.VMWeaponTransparency then
                            part.Color = Options.VMWeaponColor.Value
                            part.Material = weaponMaterial
                            part.Transparency = Options.VMWeaponTransparency.Value / 100
                            if part:IsA("MeshPart") then
                                part.TextureID = ""
                            end
                            local decals = cachedDecals[part]
                            if decals then
                                for _, child in ipairs(decals) do
                                    if not child:GetAttribute("OrigTrans") then
                                        child:SetAttribute("OrigTrans", child.Transparency)
                                    end
                                    child.Transparency = 1
                                end
                            end
                        else
                            part.Color = part:GetAttribute("OrigColor")
                            part.Material = Enum.Material[part:GetAttribute("OrigMaterial")]
                            part.Transparency = part:GetAttribute("OrigTrans")
                            if part:IsA("MeshPart") then
                                part.TextureID = part:GetAttribute("OrigTexture") or ""
                            end
                            local decals = cachedDecals[part]
                            if decals then
                                for _, child in ipairs(decals) do
                                    if child:GetAttribute("OrigTrans") then
                                        child.Transparency = child:GetAttribute("OrigTrans")
                                    end
                                end
                            end
                        end
                    end

                    -- Pre-compute arms override material
                    local armMaterial = Enum.Material.Plastic
                    if Toggles.VMArmsOverride and Toggles.VMArmsOverride.Value and Options.VMArmsMaterial then
                        local matVal = Options.VMArmsMaterial.Value
                        if type(matVal) == "number" then
                            local mats = {"Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Glass", "ForceField", "Foil", "DiamondPlate"}
                            armMaterial = Enum.Material[mats[matVal] or "Plastic"] or Enum.Material.Plastic
                        else
                            local ok, mat = pcall(function() return Enum.Material[matVal] end)
                            armMaterial = ok and mat or Enum.Material.Plastic
                        end
                    end

                    -- Apply Arms Overrides
                    for _, part in ipairs(cachedArmParts) do
                        if not part:GetAttribute("OrigColor") then
                            part:SetAttribute("OrigColor", part.Color)
                            part:SetAttribute("OrigMaterial", part.Material.Name)
                            part:SetAttribute("OrigTrans", part.Transparency)
                            if part:IsA("MeshPart") then
                                part:SetAttribute("OrigTexture", part.TextureID)
                            end
                        end
                        if Toggles.VMArmsOverride and Toggles.VMArmsOverride.Value and Options.VMArmsColor and Options.VMArmsMaterial and Options.VMArmsTransparency then
                            part.Color = Options.VMArmsColor.Value
                            part.Material = armMaterial
                            part.Transparency = Options.VMArmsTransparency.Value / 100
                            if part:IsA("MeshPart") then
                                part.TextureID = ""
                            end
                            local decals = cachedDecals[part]
                            if decals then
                                for _, child in ipairs(decals) do
                                    if not child:GetAttribute("OrigTrans") then
                                        child:SetAttribute("OrigTrans", child.Transparency)
                                    end
                                    child.Transparency = 1
                                end
                            end
                        else
                            part.Color = part:GetAttribute("OrigColor")
                            part.Material = Enum.Material[part:GetAttribute("OrigMaterial")]
                            part.Transparency = part:GetAttribute("OrigTrans")
                            if part:IsA("MeshPart") then
                                part.TextureID = part:GetAttribute("OrigTexture") or ""
                            end
                            local decals = cachedDecals[part]
                            if decals then
                                for _, child in ipairs(decals) do
                                    if child:GetAttribute("OrigTrans") then
                                        child.Transparency = child:GetAttribute("OrigTrans")
                                    end
                                end
                            end
                        end
                    end

                    -- Apply Arm & Weapon Positioning/Offsets via joints (Motor6D / Welds)
                    if Toggles.VMArmsPosEnabled and Toggles.VMArmsPosEnabled.Value and Options.VMArmsX and Options.VMArmsY and Options.VMArmsZ then
                        local armX = Options.VMArmsX.Value
                        local armY = Options.VMArmsY.Value
                        local armZ = Options.VMArmsZ.Value
                        local offsetCF = CFrame.new(armX, armY, armZ)

                        local itemVisual = cachedItemVisual
                        for _, joint in ipairs(cachedJoints) do
                            if joint.Part0 and joint.Part1 then
                                local p0Name = joint.Part0.Name:lower()
                                local p1Name = joint.Part1.Name:lower()

                                -- Shift only primary base joints to avoid double-offsetting when weapon is connected to hand
                                local isBase = not (p0Name:find("arm") or p0Name:find("hand") or p0Name:find("sleeve") or p0Name == "weapon" or p0Name == "handle" or (itemVisual and joint.Part0:IsDescendantOf(itemVisual)))
                                local isTarget = p1Name:find("arm") or p1Name:find("hand") or p1Name:find("sleeve") or (itemVisual and joint.Part1:IsDescendantOf(itemVisual))

                                if isBase and isTarget then
                                    if not joint:GetAttribute("OriginalC0") then
                                        joint:SetAttribute("OriginalC0", joint.C0)
                                    end
                                    joint.C0 = offsetCF * joint:GetAttribute("OriginalC0")
                                end
                            end
                        end
                    else
                        for _, joint in ipairs(cachedJoints) do
                            if joint:GetAttribute("OriginalC0") then
                                joint.C0 = joint:GetAttribute("OriginalC0")
                                joint:SetAttribute("OriginalC0", nil)
                            end
                        end
                    end
                end
            end)

            -- 4. ESP Rendering
            local function hideESP(data)
                if not data.Hidden then
                    data.Hidden = true
                    data.Box.Visible = false
                    data.BoxOutline.Visible = false
                    data.BoxFill.Visible = false
                    data.Name.Visible = false
                    data.Distance.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthBarBG.Visible = false
                    data.Tracer.Visible = false
                    data.LookTracer.Visible = false
                    data.Snapline.Visible = false
                    data.HeadDot.Visible = false
                    data.OSIndicator.Visible = false
                    data.Weapon.Visible = false
                    data.HealthNum.Visible = false
                    for i = 1, 8 do
                        data.CornerLines[i].Visible = false
                        data.CornerOutlines[i].Visible = false
                    end
                    for _, l in pairs(data.Skeleton) do
                        l.Visible = false
                    end
                    pcall(function()
                        if data.Highlight then
                            data.Highlight.Enabled = false
                        end
                    end)
                end
            end

            if Toggles.ESPEnabled and Toggles.ESPEnabled.Value then
                for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                    if v == lp or (lp and (v.UserId == lp.UserId or v.Name == lp.Name)) then continue end
                    if not ESP_Cache[v] then CreateESP(v) end
                    local data = ESP_Cache[v]
                    local char = v.Character
                    local cached = char and CharacterCache[char]
                    if char and not cached then
                        pcall(cacheCharacter, char)
                        cached = CharacterCache[char]
                    end
                    local hrp = cached and cached.HumanoidRootPart
                    local hum = cached and cached.Humanoid
                    
                    if hrp and hum and hum.Health > 0 then
                        -- Check for cached real position first
                        local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v] or hrp.CFrame
                        local realPos = realCF.Position

                        -- Teammate check negation (combines standard Team and custom TeammateLabel)
                        local isTeammate = Teammates[v] == true
                        if Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value and isTeammate then
                            hideESP(data)
                            continue
                        end

                        local pos, onScreen = camera:WorldToViewportPoint(realPos)
                        local isPrio = getgenv().IsPrioritized(v)
                        local dist = (camera.CFrame.Position - realPos).Magnitude

                        -- ── ESPExtras: Chams & Glow ──
                        local hasChams = Toggles.ChamsEnabled and Toggles.ChamsEnabled.Value
                        local hasGlow = Toggles.ESPGlow and Toggles.ESPGlow.Value
                        if hasChams or hasGlow then
                            if not data.Highlight or data.Highlight.Parent ~= char then
                                pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
                                local hl = Instance.new("Highlight")
                                hl.Name = "AxisChamGlow"
                                hl.Parent = char
                                data.Highlight = hl
                            end
                            data.Highlight.Enabled = true
                            data.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            
                            if hasChams then
                                data.Highlight.FillColor = Options.ChamsCol.Value
                                data.Highlight.FillTransparency = 0.5
                            else
                                data.Highlight.FillTransparency = 1
                            end
                            
                            if hasGlow then
                                data.Highlight.OutlineColor = Options.ESPGlowColor.Value
                                data.Highlight.OutlineTransparency = math.clamp(1 - (Options.ESPGlowDepth.Value / 10), 0, 0.9)
                            else
                                data.Highlight.OutlineColor = hasChams and Options.ChamsCol.Value or Color3.new(1,1,1)
                                data.Highlight.OutlineTransparency = 0
                            end
                        else
                            if data.Highlight then
                                data.Highlight.Enabled = false
                            end
                        end

                        -- If they are out of max distance, hide their drawings and continue
                        if dist > Options.ESPMaxDist.Value then
                            hideESP(data)
                            continue
                        end

                        -- ── ESPExtras: Off-Screen Indicators ──
                        if Toggles.OSIndicators and Toggles.OSIndicators.Value and not onScreen then
                            local camCF = camera.CFrame
                            local relative = camCF:PointToObjectSpace(realPos)
                            local angle = math.atan2(-relative.X, -relative.Z)
                            
                            local center = camera.ViewportSize / 2
                            local radius = 150
                            local dir = Vector2.new(math.sin(angle), math.cos(angle)).Unit
                            local indicatorPos = center + dir * radius
                            
                            local arrowSize = 12
                            local right = Vector2.new(-dir.Y, dir.X)
                            
                            data.OSIndicator.PointA = indicatorPos + dir * arrowSize
                            data.OSIndicator.PointB = indicatorPos - dir * (arrowSize / 2) + right * (arrowSize / 1.8)
                            data.OSIndicator.PointC = indicatorPos - dir * (arrowSize / 2) - right * (arrowSize / 1.8)
                            data.OSIndicator.Color = isTeammate and Options.ESPColorTeam.Value or (isPrio and Options.ESPPrioCol.Value or Options.ESPColorEnemy.Value)
                            
                            hideESP(data)
                            data.OSIndicator.Visible = true
                            continue
                        else
                            data.OSIndicator.Visible = false
                        end

                        if onScreen then
                            data.Hidden = false
                            local size = (camera:WorldToViewportPoint(realPos - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(realPos + Vector3.new(0, 3, 0)).Y)
                            local boxSize = Vector2.new(size * 0.6, size)
                            local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
                            
                            local color = isTeammate and Options.ESPColorTeam.Value or (isPrio and Options.ESPPrioCol.Value or Options.ESPColorEnemy.Value)
                            
                            -- ── Corner Boxes vs Full Boxes ──
                            if Toggles.ESPBoxes.Value then
                                local w, h = boxSize.X, boxSize.Y
                                local x, y = boxPos.X, boxPos.Y
                                local length = math.min(w / 4, 15)
                                local thick = Options.ESPBoxThick.Value or 1
                                
                                local tl_h_from = Vector2.new(x, y)
                                local tl_h_to = Vector2.new(x + length, y)
                                local tl_v_from = Vector2.new(x, y)
                                local tl_v_to = Vector2.new(x, y + length)
                                
                                local tr_h_from = Vector2.new(x + w, y)
                                local tr_h_to = Vector2.new(x + w - length, y)
                                local tr_v_from = Vector2.new(x + w, y)
                                local tr_v_to = Vector2.new(x + w, y + length)
                                
                                local bl_h_from = Vector2.new(x, y + h)
                                local bl_h_to = Vector2.new(x + length, y + h)
                                local bl_v_from = Vector2.new(x, y + h)
                                local bl_v_to = Vector2.new(x, y + h - length)
                                
                                local br_h_from = Vector2.new(x + w, y + h)
                                local br_h_to = Vector2.new(x + w - length, y + h)
                                local br_v_from = Vector2.new(x + w, y + h)
                                local br_v_to = Vector2.new(x + w, y + h - length)
                                
                                local boxCol = isPrio and Options.ESPPrioCol.Value or Options.ESPBoxCol.Value
                                
                                local l1, out1 = data.CornerLines[1], data.CornerOutlines[1]
                                l1.Thickness = thick; l1.Color = boxCol; l1.From = tl_h_from; l1.To = tl_h_to; l1.Visible = true
                                out1.Thickness = thick + 2; out1.From = tl_h_from; out1.To = tl_h_to; out1.Visible = true

                                local l2, out2 = data.CornerLines[2], data.CornerOutlines[2]
                                l2.Thickness = thick; l2.Color = boxCol; l2.From = tl_v_from; l2.To = tl_v_to; l2.Visible = true
                                out2.Thickness = thick + 2; out2.From = tl_v_from; out2.To = tl_v_to; out2.Visible = true

                                local l3, out3 = data.CornerLines[3], data.CornerOutlines[3]
                                l3.Thickness = thick; l3.Color = boxCol; l3.From = tr_h_from; l3.To = tr_h_to; l3.Visible = true
                                out3.Thickness = thick + 2; out3.From = tr_h_from; out3.To = tr_h_to; out3.Visible = true

                                local l4, out4 = data.CornerLines[4], data.CornerOutlines[4]
                                l4.Thickness = thick; l4.Color = boxCol; l4.From = tr_v_from; l4.To = tr_v_to; l4.Visible = true
                                out4.Thickness = thick + 2; out4.From = tr_v_from; out4.To = tr_v_to; out4.Visible = true

                                local l5, out5 = data.CornerLines[5], data.CornerOutlines[5]
                                l5.Thickness = thick; l5.Color = boxCol; l5.From = bl_h_from; l5.To = bl_h_to; l5.Visible = true
                                out5.Thickness = thick + 2; out5.From = bl_h_from; out5.To = bl_h_to; out5.Visible = true

                                local l6, out6 = data.CornerLines[6], data.CornerOutlines[6]
                                l6.Thickness = thick; l6.Color = boxCol; l6.From = bl_v_from; l6.To = bl_v_to; l6.Visible = true
                                out6.Thickness = thick + 2; out6.From = bl_v_from; out6.To = bl_v_to; out6.Visible = true

                                local l7, out7 = data.CornerLines[7], data.CornerOutlines[7]
                                l7.Thickness = thick; l7.Color = boxCol; l7.From = br_h_from; l7.To = br_h_to; l7.Visible = true
                                out7.Thickness = thick + 2; out7.From = br_h_from; out7.To = br_h_to; out7.Visible = true

                                local l8, out8 = data.CornerLines[8], data.CornerOutlines[8]
                                l8.Thickness = thick; l8.Color = boxCol; l8.From = br_v_from; l8.To = br_v_to; l8.Visible = true
                                out8.Thickness = thick + 2; out8.From = br_v_from; out8.To = br_v_to; out8.Visible = true
                                
                                data.Box.Visible = false
                                data.BoxOutline.Visible = false
                            else
                                for i = 1, 8 do
                                    data.CornerLines[i].Visible = false
                                    data.CornerOutlines[i].Visible = false
                                end
                                
                                if Toggles.ESPBoxFull.Value then
                                    local thick = Options.ESPBoxThick.Value or 1
                                    local boxCol = isPrio and Options.ESPPrioCol.Value or Options.ESPBoxCol.Value
                                    data.Box.Thickness = thick
                                    data.Box.Color = boxCol
                                    data.Box.Size = boxSize
                                    data.Box.Position = boxPos
                                    data.Box.Visible = true
                                    
                                    data.BoxOutline.Thickness = thick + 2
                                    data.BoxOutline.Size = boxSize
                                    data.BoxOutline.Position = boxPos
                                    data.BoxOutline.Visible = true
                                else
                                    data.Box.Visible = false
                                    data.BoxOutline.Visible = false
                                end
                            end

                            data.BoxFill.Visible = Toggles.ESPFill.Value
                            if data.BoxFill.Visible then
                                data.BoxFill.Size = boxSize
                                data.BoxFill.Position = boxPos
                                data.BoxFill.Color = Options.ESPColorFill.Value
                                data.BoxFill.Transparency = 0.25
                            end

                            data.Name.Visible = Toggles.ESPNames.Value
                            data.Name.Text = isPrio and ("[PRIO] " .. v.Name) or v.Name; data.Name.Position = Vector2.new(pos.X, boxPos.Y - 15)
                            data.Name.Color = isPrio and Options.ESPPrioCol.Value or Options.ESPColorName.Value
                            data.Name.Size = Options.ESPTextSize.Value or 13
                            
                            data.Distance.Visible = Toggles.ESPDistance.Value
                            data.Distance.Text = math.floor(dist) .. "m"; data.Distance.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 2); data.Distance.Color = color
                            data.Distance.Size = (Options.ESPTextSize.Value or 13) - 2
                            
                            -- ── ESP Weapons ──
                            if Toggles.ESPWeapon.Value then
                                local defense = PlayerDefenseStates[v]
                                local activeWeapon = defense and defense.ActiveWeapon
                                if activeWeapon then
                                    data.Weapon.Text = activeWeapon
                                    data.Weapon.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + (Toggles.ESPDistance.Value and 14 or 2))
                                    data.Weapon.Color = Color3.fromRGB(240, 240, 240)
                                    data.Weapon.Size = (Options.ESPTextSize.Value or 13) - 2
                                    data.Weapon.Visible = true
                                else
                                    data.Weapon.Visible = false
                                end
                            else
                                data.Weapon.Visible = false
                            end

                            data.HealthBar.Visible = Toggles.ESPHealth.Value
                            local hpPercent = hum.Health / hum.MaxHealth
                            local hbThick = Options.ESPHealthThick and Options.ESPHealthThick.Value or 2
                            data.HealthBar.Thickness = hbThick
                            data.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y)
                            data.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y - (boxSize.Y * hpPercent))
                            data.HealthBar.Color = Options.ESPColorHP.Value
                            data.HealthBarBG.Visible = data.HealthBar.Visible
                            data.HealthBarBG.Thickness = hbThick
                            data.HealthBarBG.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y)
                            data.HealthBarBG.To = Vector2.new(boxPos.X - 5, boxPos.Y)

                            -- ── ESP Health Number ──
                            if Toggles.ESPHealthNum.Value and Toggles.ESPHealth.Value then
                                data.HealthNum.Text = tostring(math.floor(hum.Health))
                                data.HealthNum.Position = Vector2.new(boxPos.X - 18, boxPos.Y + boxSize.Y - (boxSize.Y * hpPercent) - 5)
                                data.HealthNum.Color = Options.ESPColorHP.Value or Color3.fromRGB(50, 220, 80)
                                data.HealthNum.Size = (Options.ESPTextSize.Value or 13) - 3
                                data.HealthNum.Visible = true
                            else
                                data.HealthNum.Visible = false
                            end

                            -- ── ESP Tracers ──
                            if Toggles.ESPTracers.Value then
                                local tracerFrom = Options.ESPTracerOrigin.Value or "Bottom"
                                local startVector
                                if tracerFrom == "Bottom" then
                                    startVector = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                elseif tracerFrom == "Top" then
                                    startVector = Vector2.new(camera.ViewportSize.X / 2, 0)
                                else -- Center
                                    startVector = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                                end
                                
                                data.Tracer.Visible = true
                                data.Tracer.From = startVector
                                data.Tracer.To = Vector2.new(pos.X, pos.Y)
                                data.Tracer.Color = isPrio and Options.ESPPrioCol.Value or Options.ESPTracerCol.Value
                                data.Tracer.Thickness = Options.ESPTracerThick.Value or 1
                            else
                                data.Tracer.Visible = false
                            end

                            -- ── ESPExtras: Snaplines ──
                            if Toggles.ESPSnaplines and Toggles.ESPSnaplines.Value then
                                data.Snapline.Visible = true
                                data.Snapline.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                data.Snapline.To = Vector2.new(pos.X, pos.Y)
                                data.Snapline.Color = isPrio and Options.ESPPrioCol.Value or Options.ESPBoxCol.Value
                                data.Snapline.Thickness = Options.ESPBoxThick.Value or 1
                            else
                                data.Snapline.Visible = false
                            end

                            -- ── ESPExtras: Head Dot ──
                            if Toggles.ESPHeadDot and Toggles.ESPHeadDot.Value then
                                local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v]
                                local headPos3D = realCF and (realCF.Position + Vector3.new(0, 1.5, 0)) or (cached and cached.Head and cached.Head.Position)
                                if headPos3D then
                                    local headPos, headOn = camera:WorldToViewportPoint(headPos3D)
                                    if headOn then
                                        data.HeadDot.Visible = true
                                        data.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                                        data.HeadDot.Color = Options.ESPHeadDotColor.Value or Color3.new(1,1,1)
                                    else
                                        data.HeadDot.Visible = false
                                    end
                                else
                                    data.HeadDot.Visible = false
                                end
                            else
                                data.HeadDot.Visible = false
                            end

                            -- ── Look Tracers ──
                            if Toggles.LookTracers and Toggles.LookTracers.Value then
                                local realCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v] or (cached and cached.Head and cached.Head.CFrame)
                                if realCF then
                                    local lookDir = realCF.LookVector
                                    local headPos3D = realCF.Position + (getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v] and Vector3.new(0, 1.5, 0) or Vector3.zero)
                                    local fromPos, fromOn = camera:WorldToViewportPoint(headPos3D)
                                    local toPos, toOn = camera:WorldToViewportPoint(headPos3D + lookDir * 15)
                                    
                                    if fromOn and toOn then
                                        data.LookTracer.Visible = true
                                        data.LookTracer.From = Vector2.new(fromPos.X, fromPos.Y)
                                        data.LookTracer.To = Vector2.new(toPos.X, toPos.Y)
                                        data.LookTracer.Color = Options.LookTracerCol.Value or Color3.fromRGB(255, 0, 0)
                                    else
                                        data.LookTracer.Visible = false
                                    end
                                else
                                    data.LookTracer.Visible = false
                                end
                            else
                                data.LookTracer.Visible = false
                            end

                            if Toggles.ESPSkeleton.Value and not (getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[v]) then
                                for i = 1, #Skeleton_Parts do
                                    local partPair = Skeleton_Parts[i]
                                    local p1 = cached and cached.Parts[partPair[1]]
                                    local p2 = cached and cached.Parts[partPair[2]]
                                    if p1 and p2 then
                                        local sp1, on1 = camera:WorldToViewportPoint(p1.Position)
                                        local sp2, on2 = camera:WorldToViewportPoint(p2.Position)
                                        data.Skeleton[i].Visible = on1 and on2
                                        data.Skeleton[i].From = Vector2.new(sp1.X, sp1.Y)
                                        data.Skeleton[i].To = Vector2.new(sp2.X, sp2.Y)
                                        data.Skeleton[i].Color = Options.ESPColorSkel.Value
                                        data.Skeleton[i].Thickness = Options.ESPSkelThick.Value or 1
                                    else
                                        data.Skeleton[i].Visible = false
                                    end
                                end
                            else
                                for _, l in pairs(data.Skeleton) do l.Visible = false end
                            end
                            continue
                        end
                    end
                    hideESP(data)
                end
            else
                for _, data in pairs(ESP_Cache) do
                    hideESP(data)
                end
            end

            -- 5. Weather Effects
            if Weather.Part and Weather.Rain and Weather.Snow then
                local camPos = camera.CFrame.Position
                Weather.Part.CFrame = CFrame.new(camPos + Vector3.new(0, 45, 0))
                
                Weather.Rain.Enabled = (Toggles.WeatherRain and Toggles.WeatherRain.Value) or false
                Weather.Snow.Enabled = (Toggles.WeatherSnow and Toggles.WeatherSnow.Value) or false
            end

            -- GUI Snow overlay fallback (2D)
            if Toggles.GUISnow and Toggles.GUISnow.Value then
                local maxSnow = 30
                if #SnowParticles == 0 then
                    for i = 1, maxSnow do
                        local sDot = Drawing.new("Circle")
                        sDot.Radius = math.random(1, 3)
                        sDot.Filled = true
                        sDot.Position = Vector2.new(math.random(0, camera.ViewportSize.X), math.random(0, camera.ViewportSize.Y))
                        sDot.Color = Color3.new(1, 1, 1)
                        sDot.Visible = true
                        SnowParticles[i] = sDot
                    end
                end
                for i = 1, maxSnow do
                    local sDot = SnowParticles[i]
                    if sDot then
                        local newPos = sDot.Position + Vector2.new(math.random(-2, 2), 4)
                        if newPos.Y > camera.ViewportSize.Y then
                            newPos = Vector2.new(math.random(0, camera.ViewportSize.X), 0)
                            sDot.Radius = math.random(1, 3)
                        end
                        sDot.Position = newPos
                        sDot.Visible = true
                    end
                end
            else
                if #SnowParticles > 0 then
                    for i = 1, #SnowParticles do
                        pcall(function() SnowParticles[i]:Remove() end)
                    end
                    table.clear(SnowParticles)
                end
            end
        end))

        --// Custom Rage: Void Exploits & Aggressive Sling Bypass
        local VoidSpamTimer = 0
        local VoidHideState = true 
        local OriginalCF = nil
        local SlingTargets = {}
        local SlingBypass_Void = CFrame.new(0, 100000, 0)
        getgenv().RealPlayerPositions = {}

        Library:Track(workspace.ChildAdded:Connect(function(o)
            if not Toggles.SlingBypass or not Toggles.SlingBypass.Value then return end
            if not o:IsA("BasePart") then return end
            if o.Name == "CoreProjectile" then 
                SlingTargets[o] = true
            elseif o.Name == "Part" then 
                task.defer(function()
                    if o and o.Parent and o.AssemblyLinearVelocity.Magnitude > 50 then 
                        SlingTargets[o] = true 
                    end
                end)
            end 
        end))

        Library:Track(workspace.ChildRemoved:Connect(function(o)
            SlingTargets[o] = nil 
        end))

        Library:Track(rs.Heartbeat:Connect(function(dt)
            if not Library.Running then return end
            
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- [[ Aggressive Sling Bypass (Optimized for instant hits) ]]
            if Toggles.SlingBypass and Toggles.SlingBypass.Value then
                pcall(function()
                    -- 1. Void other players & capture real positions
                    local allPlayers = game:GetService("Players"):GetPlayers()
                    for i = 1, #allPlayers do
                        local p = allPlayers[i]
                        if p ~= lp and p.Character then
                            local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if pHrp then
                                getgenv().RealPlayerPositions[p] = pHrp.CFrame
                                pHrp.CFrame = SlingBypass_Void
                                pHrp.AssemblyLinearVelocity = Vector3.zero
                                pHrp.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end

                    -- 2. Teleport tracked projectiles to void
                    for _, o in pairs(workspace:GetChildren()) do
                        if o.Name == "CoreProjectile" and o:IsA("BasePart") then
                            o.CFrame = SlingBypass_Void
                            o.AssemblyLinearVelocity = Vector3.zero
                        end 
                    end
                    for p in pairs(SlingTargets) do
                        if p and p.Parent then 
                            p.CFrame = SlingBypass_Void
                            p.AssemblyLinearVelocity = Vector3.zero
                        else 
                            SlingTargets[p] = nil 
                        end 
                    end
                end)
            else
                table.clear(getgenv().RealPlayerPositions)
            end

            -- [[ Void Spam (Cycle) ]]
            if Toggles.VoidSpam and Toggles.VoidSpam.Value then
                VoidSpamTimer = VoidSpamTimer + dt
                if VoidHideState then
                    if not OriginalCF then OriginalCF = hrp.CFrame end
                    -- Keep current X/Z but drop Y to -250 studs (safe out-of-bounds boundary)
                    hrp.CFrame = CFrame.new(hrp.Position.X, -250, hrp.Position.Z)
                    hrp.Velocity = Vector3.zero
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if VoidSpamTimer >= Options.VoidHideTime.Value then
                        VoidSpamTimer = 0; VoidHideState = false
                    end
                else
                    if OriginalCF then
                        hrp.CFrame = OriginalCF
                        OriginalCF = nil
                    end
                    if VoidSpamTimer >= Options.VoidAttackTime.Value then
                        VoidSpamTimer = 0; VoidHideState = true
                    end
                end
            else
                OriginalCF = nil
                VoidSpamTimer = 0
                VoidHideState = true
            end

            -- [[ Void Spam (Aggressive/Random) ]]
            if Toggles.VoidSpamRandom and Toggles.VoidSpamRandom.Value then
                local offset = Vector3.new(hrp.Position.X + math.random(-10, 10), -250, hrp.Position.Z + math.random(-10, 10))
                hrp.CFrame = CFrame.new(offset)
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end))

        --// Custom Rage: Main Combat & Movement Loop
        do
            local OrbitAngle = 0
            local AntiAimYaw = 0
            local originalJoints = {}
            local MovementState = { JumpCount = 0 }
            local hitboxTimer = 0
            local randomTPTimer = 0
            local nearestEnemyRoot = nil
            local nearestEnemyScanTimer = 0
            local scriptBootTime = tick()
            local teleportRageTimer = 0
            local backFaceTimer = 0
            local cachedNeck  = nil
            local cachedWaist = nil
            local MC = nil
            local slideBoostApplied = false
            local slideWasActive = false      -- transition detection for slide boost
            local doubleJumpCooldown = 0

            -- Require MechanicsController singleton (deferred so PlayerScripts are ready)
            task.spawn(function()
                task.wait(2)
                pcall(function()
                    MC = require(lp.PlayerScripts.Controllers.MechanicsController)
                    -- PlayMechanicsSound hook removed so that DoubleJump retains its satisfying native sound effect.
                end)
            end)

            -- Bullet Tracer Function
            local function CreateTracer(from, to)
                if not Toggles.BulletTracers or not Toggles.BulletTracers.Value then return end
                local screenFrom, onScreenFrom = camera:WorldToViewportPoint(from)
                local screenTo, onScreenTo = camera:WorldToViewportPoint(to)
                if onScreenFrom or onScreenTo then
                    local line = Drawing.new("Line")
                    line.Color = Options.BulletTracerCol.Value
                    line.Thickness = 1.5
                    line.Transparency = 1
                    line.From = Vector2.new(screenFrom.X, screenFrom.Y)
                    line.To = Vector2.new(screenTo.X, screenTo.Y)
                    line.Visible = true
                    task.delay(1.5, function() line:Remove() end)
                end
            end

            -- Ragebot / AutoFire Logic (UE-Killer Aggression)
            task.spawn(function()
                while Library.Running do
                    task.wait()
                    local target = SilentAim.Target
                    if Toggles.AutoFire and Toggles.AutoFire.Value and target then
                        pcall(function()
                            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            local useItem = remotes and remotes:FindFirstChild("UseItem")
                            if useItem then
                                local targetPart = target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("Head")
                                if targetPart then
                                    local iterations = Toggles.RapidFire and Toggles.RapidFire.Value and Options.RapidFireSpam.Value or 1
                                    for i = 1, iterations do
                                        useItem:FireServer({
                                            ["Target"] = targetPart,
                                            ["Origin"] = targetPart.Position + Vector3.new(0, 0.5, 0), -- Spoofed Origin
                                            ["Direction"] = Vector3.new(0, -1, 0) -- Top-down hit
                                        })
                                    end
                                    CreateTracer(lp.Character.Head.Position, targetPart.Position)
                                end
                            end
                        end)
                        if not (Toggles.RapidFire and Toggles.RapidFire.Value) then
                            -- Minimal wait to prevent crash but maintain extreme speed
                            task.wait()
                        end
                    end
                end
            end)

            Library:Track(rs.Heartbeat:Connect(function(dt)
                if not Library.Running then return end
                
                local char = lp.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid") or char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then return end

                -- [[ Boot Grace Period: skip CFrame-writing features for 3s after load ]]
                local booted = (tick() - scriptBootTime) >= 3

                -- [[ Shared Nearest-Enemy Cache ]]
                -- Read directly from the centralized single-pass scanner
                if booted then
                    nearestEnemyRoot = CachedNearestEnemyRoot
                end

                -- [[ Instant Reload / State Reset ]]
                if Toggles.InstantReload and Toggles.InstantReload.Value then
                    local tool = char:FindFirstChildWhichIsA("Tool")
                    if tool and tool:FindFirstChild("Ammo") and tool.Ammo.Value < 1 then
                        char:SetAttribute("Reloading", false)
                        char:SetAttribute("UsingItem", false)
                    end
                end

                -- [[ Bunny Hop ]]
                if Toggles.BhopEnabled and Toggles.BhopEnabled.Value then
                    if uis:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
                        hum.Jump = true
                    end
                end

                -- [[ Anti-Ragdoll ]]
                if Toggles.AntiRagdoll and Toggles.AntiRagdoll.Value then
                    local ragdoll = char:FindFirstChild("Ragdoll") or char:FindFirstChild("RagdollConstraints")
                    if ragdoll then ragdoll:Destroy() end
                    if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end

                -- [[ Teleport Rage ]] (throttled to 20Hz to prevent physics engine overload)
                if booted and Toggles.TeleportRage and Toggles.TeleportRage.Value then
                    teleportRageTimer = teleportRageTimer + dt
                    if teleportRageTimer >= 0.05 then
                        teleportRageTimer = 0
                    pcall(function()
                        -- Use shared cache; prefer SilentAim locked target
                        local tpTarget = SilentAim.Target
                        if not tpTarget and nearestEnemyRoot and nearestEnemyRoot.Parent then
                            -- Wrap root back to player for character lookup
                            local rootChar = nearestEnemyRoot.Parent
                            tpTarget = playersService:GetPlayerFromCharacter(rootChar)
                        end

                        if tpTarget then
                            local tChar = tpTarget.Character
                            local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                            if tHrp and tHrp.Parent then
                                local mode      = Options.TeleportMode and Options.TeleportMode.Value or "Above"
                                local targetRealCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[tpTarget]
                                local targetPos = targetRealCF and targetRealCF.Position or tHrp.Position
                                local dist      = Options.TeleportDist and Options.TeleportDist.Value or 10

                                if targetPos.X ~= targetPos.X or targetPos.Y ~= targetPos.Y or targetPos.Z ~= targetPos.Z then return end

                                local newCF = nil
                                if mode == "Above" then
                                    newCF = CFrame.new(targetPos + Vector3.new(0, dist, 0), targetPos)
                                elseif mode == "Behind" then
                                    local realCF = targetRealCF or tHrp.CFrame
                                    newCF = realCF * CFrame.new(0, 0, 5)
                                elseif mode == "Back" then
                                    local realCF = targetRealCF or tHrp.CFrame
                                    local frontDir = realCF.LookVector
                                    local frontPos = realCF.Position + frontDir * dist
                                    frontPos = Vector3.new(frontPos.X, realCF.Position.Y + 2, frontPos.Z)
                                    -- Face AWAY from enemy: look in same direction as enemy's LookVector
                                    -- so our back is toward them (works with BackFaceEnemy joint desync)
                                    newCF = CFrame.new(frontPos, frontPos + frontDir)
                                elseif mode == "Orbit" then
                                    OrbitAngle = ((OrbitAngle or 0) + (dt * 5)) % (math.pi * 2)
                                    local offset = Vector3.new(math.cos(OrbitAngle) * dist, 5, math.sin(OrbitAngle) * dist)
                                    newCF = CFrame.new(targetPos + offset, targetPos)
                                end

                                if newCF then
                                    hrp.CFrame = newCF
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                end
                            end
                        end
                        end)
                    end -- /throttle 20Hz
                end

                -- [[ Fly Logic ]]
                if Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
                    local speed = Options.FlySpeed and Options.FlySpeed.Value or 70
                    local move = Vector3.zero
                    local camCF = camera.CFrame
                    if uis:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                    if uis:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
                    
                    if move.Magnitude > 0 then
                        hrp.Velocity = move.Unit * speed
                    else
                        hrp.Velocity = Vector3.zero
                    end
                    hrp.AssemblyLinearVelocity = hrp.Velocity
                end

                -- [[ Noclip Logic ]]
                if Toggles.NoclipEnabled and Toggles.NoclipEnabled.Value then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        elseif part:IsA("Model") then
                            for _, sub in ipairs(part:GetChildren()) do
                                if sub:IsA("BasePart") then
                                    sub.CanCollide = false
                                end
                            end
                        end
                    end
                end



                -- [[ Unified Joint (Anti-Aim / Back-Face) Manager ]]
                local aaActive = Toggles.AntiAimEnabled and Toggles.AntiAimEnabled.Value
                local bfActive = Toggles.BackFaceEnemy and Toggles.BackFaceEnemy.Value
                
                if booted and (aaActive or bfActive) then
                    local neck  = char:FindFirstChild("Neck",  true)
                    local waist = char:FindFirstChild("Waist", true)
                    
                    if neck and neck:IsA("Motor6D") and not originalJoints[neck] then 
                        originalJoints[neck] = neck.C0 
                    end
                    if waist and waist:IsA("Motor6D") and not originalJoints[waist] then 
                        originalJoints[waist] = waist.C0 
                    end

                    if aaActive then
                        local aaMode  = Options.AntiAimMode and Options.AntiAimMode.Value or "Jitter"
                        local aaSpeed = Options.AntiAimSpeed and Options.AntiAimSpeed.Value or 15
                        local jRange  = Options.AntiAimJitterRange and Options.AntiAimJitterRange.Value or 45
                        local aaPitch = Options.AntiAimPitch and Options.AntiAimPitch.Value or "Down"
                        
                        AntiAimYaw = AntiAimYaw or 0
                        local ao = 0
                        if aaMode == "Jitter" then
                            ao = math.rad(math.random(-jRange, jRange))
                        elseif aaMode == "Sway" then
                            AntiAimYaw = AntiAimYaw + dt * (aaSpeed * 10)
                            ao = math.sin(AntiAimYaw * (aaSpeed / 5)) * math.rad(jRange)
                        elseif aaMode == "Inverter" then
                            AntiAimYaw = AntiAimYaw + dt
                            ao = (math.floor(AntiAimYaw * 2) % 2 == 0) and 0 or math.rad(180)
                        end

                        local ap = 0
                        if aaPitch == "Down" then
                            ap = math.rad(-90)
                        elseif aaPitch == "Up" then
                            ap = math.rad(90)
                        elseif aaPitch == "Flip" then
                            ap = math.rad(-180)
                        end

                        pcall(function()
                            if neck and neck:IsA("Motor6D") then
                                neck.C0 = CFrame.new(originalJoints[neck].Position) * CFrame.Angles(ap, ao, 0)
                            end
                            if waist and waist:IsA("Motor6D") then
                                waist.C0 = CFrame.new(originalJoints[waist].Position) * CFrame.Angles(ap * 0.5, ao, 0)
                            end
                        end)
                    elseif bfActive and nearestEnemyRoot and nearestEnemyRoot.Parent then
                        backFaceTimer = backFaceTimer + dt
                        if backFaceTimer >= 0.05 then
                            backFaceTimer = 0
                            local enemyPlayer = playersService:GetPlayerFromCharacter(nearestEnemyRoot.Parent)
                            local enemyRealCF = getgenv().RealPlayerPositions and getgenv().RealPlayerPositions[enemyPlayer]
                            local enemyPos = enemyRealCF and enemyRealCF.Position or nearestEnemyRoot.Position
                            local toEnemy = (enemyPos - hrp.Position) * Vector3.new(1, 0, 1)
                            if toEnemy.Magnitude > 0.5 then
                                local awayYaw = math.atan2(-toEnemy.X, -toEnemy.Z)
                                pcall(function()
                                    if neck and neck:IsA("Motor6D") then
                                        neck.C0  = CFrame.new(originalJoints[neck].Position)  * CFrame.Angles(0, awayYaw, 0)
                                    end
                                    if waist and waist:IsA("Motor6D") then
                                        waist.C0 = CFrame.new(originalJoints[waist].Position) * CFrame.Angles(0, awayYaw, 0)
                                    end
                                end)
                            end
                        end
                    end
                else
                    if next(originalJoints) ~= nil then
                        for joint, c0 in pairs(originalJoints) do
                            pcall(function()
                                if joint and joint.Parent then joint.C0 = c0 end
                            end)
                        end
                        originalJoints = {}
                    end
                    AntiAimYaw = 0
                end

                -- [[ CFrame Speed Hack ]]
                if Toggles.CFrameSpeed and Toggles.CFrameSpeed.Value and hum.MoveDirection.Magnitude > 0 and not (Toggles.FlyEnabled and Toggles.FlyEnabled.Value) then
                    local speedMultiplier = Options.SpeedMult and Options.SpeedMult.Value or 2
                    hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (speedMultiplier - 1) * 16 * dt)
                end

                -- [[ Random TP ]] -- skipped if TeleportRage is active (they fight over hrp.CFrame)
                if booted and Toggles.RandomTP and Toggles.RandomTP.Value
                    and not (Toggles.TeleportRage and Toggles.TeleportRage.Value) then
                        randomTPTimer = randomTPTimer + dt
                        local tpRate  = Options.RandomTPSpeed and Options.RandomTPSpeed.Value or 12
                        local zSpread = Options.RandomTPRadius and Options.RandomTPRadius.Value or 30
                        if randomTPTimer >= (1 / tpRate) then
                            randomTPTimer = 0
                            -- Absolute zone teleport (map-specific bounds)
                            local newX = 6966 + math.random() * (7033 - 6966)  -- X: 6966 to 7033
                            local newY = 4000 + math.random() * 15              -- Y: 4000 to 4015
                            local newZ = 2044 + (math.random() - 0.5) * zSpread -- Z: 2044 ± zSpread
                            hrp.CFrame = CFrame.new(newX, newY, newZ)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        end
                else
                    randomTPTimer = 0
                end


                -- [[ SLIDE BOOST ]]
                if Toggles.SlideBoostEnabled and Toggles.SlideBoostEnabled.Value and Options.SlideBoost then
                    local isSliding = (hum:GetState() == Enum.HumanoidStateType.Physics)
                        or (char:GetAttribute("Sliding") == true)
                        or (MC and MC.IsSliding)
                    if isSliding and not slideWasActive then
                        slideWasActive = true
                        local boostAmt = Options.SlideBoost.Value
                        task.delay(0.1, function()
                            pcall(function()
                                if MC and MC.IsSliding and MC._sliding_velocity then
                                    local vel = MC._sliding_velocity.Velocity
                                    if vel.Magnitude > 0.1 then
                                        MC._sliding_velocity.Velocity = vel.Unit * math.min(vel.Magnitude + boostAmt, 120)
                                        return
                                    end
                                end
                                local c = lp.Character
                                local h = c and c:FindFirstChild("HumanoidRootPart")
                                if h then
                                    local v = h.AssemblyLinearVelocity
                                    local flatV = Vector3.new(v.X, 0, v.Z)
                                    if flatV.Magnitude > 0.1 then
                                        h.AssemblyLinearVelocity = v + flatV.Unit * boostAmt
                                    else
                                        h.AssemblyLinearVelocity = h.AssemblyLinearVelocity
                                            + (h.CFrame.LookVector * Vector3.new(1,0,1)).Unit * boostAmt
                                    end
                                end
                            end)
                        end)
                    elseif not isSliding then
                        slideWasActive = false
                    end
                end

                if hum:GetState() == Enum.HumanoidStateType.Landed then
                    MovementState.JumpCount = 0
                end

                -- [[ Hitbox Expander (UE-Killer Logic) ]]
                if Toggles.HitboxExpand and Toggles.HitboxExpand.Value then
                    hitboxTimer = hitboxTimer + dt
                    if hitboxTimer >= 0.5 then
                        hitboxTimer = 0
                        local size = Options.HitboxSize.Value
                        local knifeSize = Options.KnifeHitboxSize and Options.KnifeHitboxSize.Value or size
                        local isVisible = Toggles.HitboxVisible and Toggles.HitboxVisible.Value or false
                        
                        local function expandChar(char)
                            if not char then return end
                            local cache = CharacterCache[char]
                            if cache and cache.HitboxParts then
                                for _, p in ipairs(cache.HitboxParts) do
                                    p.Size = Vector3.new(size, size, size)
                                    p.Transparency = isVisible and 0.7 or 1
                                    p.CanCollide = false
                                    p.CanTouch = true
                                    p.CanQuery = true
                                    p.Massless = true
                                end
                            else
                                for _, p in pairs(char:GetDescendants()) do
                                    if p:IsA("BasePart") and (p.Name:find("Hitbox") or p.Name == "Head") then
                                        p.Size = Vector3.new(size, size, size)
                                        p.Transparency = isVisible and 0.7 or 1
                                        p.CanCollide = false
                                        p.CanTouch = true
                                        p.CanQuery = true
                                        p.Massless = true
                                    end
                                end
                            end
                        end

                        for _, v in pairs(playersService:GetPlayers()) do
                            if v ~= lp and v.Character then
                                local root = v.Character:FindFirstChild("HumanoidRootPart")
                                if root and not root:FindFirstChild("TeammateLabel") then
                                    expandChar(v.Character)
                                end
                            end
                        end
                        -- Support for custom entity folders
                        for _, folderName in pairs({"Entities", "Fighters", "Characters"}) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                for _, entity in pairs(folder:GetChildren()) do
                                    if entity:IsA("Model") and entity ~= lp.Character then
                                        expandChar(entity)
                                    end
                                end
                            end
                        end

                        -- [[ Knife / Melee Hitbox Expansion ]]
                        -- Enlarges all BaseParts in the local player's equipped Tool so
                        -- touch-based melee detection (knife, katana, etc.) has extended range.
                        pcall(function()
                            local char = lp.Character
                            if char then
                                for _, child in pairs(char:GetChildren()) do
                                    if child:IsA("Tool") then
                                        local toolName = child.Name:lower()
                                        if not (toolName:find("shield") or toolName:find("riot")) then
                                            for _, p in pairs(child:GetDescendants()) do
                                                if p:IsA("BasePart") then
                                                    p.Size = Vector3.new(knifeSize, knifeSize, knifeSize)
                                                    p.CanTouch = true
                                                    p.CanCollide = false
                                                    p.Massless = true
                                                    p.Transparency = isVisible and 0.5 or 1
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                else
                    hitboxTimer = 0
                end
            end))

            -- [[ Removed Hitbox Loop (Now in Heartbeat) ]]

            -- [[ GUI Snow Effect ]]
            local function createSnowParticle()
                if not Toggles.GUISnow or not Toggles.GUISnow.Value then return end
                local snow = Drawing.new("Circle")
                snow.Radius = math.random(1, 3)
                snow.Filled = true
                snow.Color = Color3.new(1, 1, 1)
                snow.Transparency = math.random(5, 10) / 10
                snow.Position = Vector2.new(math.random(0, camera.ViewportSize.X), -10)
                snow.Visible = true
                table.insert(SnowParticles, snow)

                task.spawn(function()
                    local drift = math.random(-1, 1)
                    for i = 1, 100 do
                        if not Library.Running or not Toggles.GUISnow.Value then break end
                        snow.Position = snow.Position + Vector2.new(drift, 5)
                        if snow.Position.Y > camera.ViewportSize.Y then break end
                        task.wait(0.02)
                    end
                    snow:Remove()
                    local idx = table.find(SnowParticles, snow)
                    if idx then table.remove(SnowParticles, idx) end
                end)
            end
            task.spawn(function()
                while task.wait(0.2) do
                    if not Library.Running then break end
                    if Toggles.GUISnow and Toggles.GUISnow.Value and Window.Visible then
                        createSnowParticle()
                    end
                end
            end)

            -- [[ Double Jump (MechanicsController-informed) ]]
            -- uis.JumpRequest fires every RenderStepped frame while Space is held (MC._SpamJumpRequests loop).
            -- Without a cooldown, PlayMechanicsSound fires 60x/sec → absurdly loud.
            Library:Track(uis.JumpRequest:Connect(function()
                if not Library.Running or not lp.Character then return end
                if not (Toggles.InfiniteDoubleJump and Toggles.InfiniteDoubleJump.Value) then return end
                if tick() < doubleJumpCooldown then return end  -- debounce spam
                pcall(function()
                    if MC and MC:IsAlive() and not MC:IsFrozen() then
                        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                        local state = hum and hum:GetState()
                        if state == Enum.HumanoidStateType.Freefall
                            or state == Enum.HumanoidStateType.Jumping
                            or state == Enum.HumanoidStateType.Physics then
                            doubleJumpCooldown = tick() + 0.5  -- 0.5s between double jumps
                            MC._double_jumps_used = {}
                            MC:DoubleJump()
                        end
                    else
                        -- MC not ready yet: fallback
                        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum:GetState() ~= Enum.HumanoidStateType.Landed then
                            doubleJumpCooldown = tick() + 0.5
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            hum.JumpPower = 50 * (Options.DoubleJumpHeight and Options.DoubleJumpHeight.Value or 1)
                        end
                    end
                end)
            end))
        end
    end)
