local MODE = MODE

local defenseSpawnMinPlayerDistanceSqr = 550 * 550
local defenseSpawnVisibilityDot = 0.2
local defenseSpawnStepDelay = 0.8


 local _OrigSpawn = SpawnZBaseNPC
 function SpawnZBaseNPC(ply, npcClass, pos, weaponClass)

     local npc
     if _OrigSpawn then
        npc = _OrigSpawn(ply, npcClass, pos, "default")
     else
         npc = ZBaseSpawnZBaseNPC(npcClass, pos, nil, "default")
   end
    if not IsValid(npc) then return end

     if weaponClass and weaponClass ~= "" then
         timer.Simple(0, function()
             if not IsValid(npc) then return end

             for _, wep in ipairs(npc:GetWeapons()) do
                 if IsValid(wep) then wep:Remove() end
             end

             npc:Give(weaponClass)
         end)
     end

    return npc
 end

function MODE:IsSpawnVisibleToAnyPlayer(spawnPos)
    local targetPos = spawnPos + Vector(0, 0, 48)

    for _, ply in player.Iterator() do
        if not (IsValid(ply) and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR) then
            continue
        end

        local eyePos = ply:EyePos()
        local toSpawn = targetPos - eyePos
        local distSqr = toSpawn:LengthSqr()

        if distSqr <= defenseSpawnMinPlayerDistanceSqr then
            return true
        end

        local direction = toSpawn:GetNormalized()
        if ply:EyeAngles():Forward():Dot(direction) < defenseSpawnVisibilityDot then
            continue
        end

        local trace = util.TraceLine({
            start = eyePos,
            endpos = targetPos,
            mask = MASK_BLOCKLOS,
            filter = ply
        })

        if not trace.Hit or trace.Fraction >= 0.98 then
            return true
        end
    end

    return false
end

function MODE:FindValidSpawnPoint(center, radius)
    local attempts = 10
    for i = 1, attempts do
        local randomOffset = Vector(math.random(-radius, radius), math.random(-radius, radius), 0)
        local spawnPos = center + randomOffset

        local trace = util.TraceLine({
            start = spawnPos + Vector(0, 0, 50),
            endpos = spawnPos - Vector(0, 0, 500),
            mask = MASK_SOLID_BRUSHONLY
        })

        if not trace.Hit then continue end
        spawnPos = trace.HitPos + Vector(0, 0, 10) 

        local hullTrace = util.TraceHull({
            start = spawnPos,
            endpos = spawnPos,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_PLAYERSOLID
        })

        if hullTrace.Hit then continue end

        local ceilingTrace = util.TraceLine({
            start = spawnPos,
            endpos = spawnPos + Vector(0, 0, 100),
            mask = MASK_SOLID
        })

        if ceilingTrace.Hit then continue end

        if self:IsSpawnVisibleToAnyPlayer(spawnPos) then continue end

        return spawnPos
    end

    return nil 
end

function MODE:IsValidNavMeshSpawn(spawnPos)
    if not spawnPos then
        return false
    end

    if bit.band(util.PointContents(spawnPos), CONTENTS_WATER) == CONTENTS_WATER then
        return false
    end

    local hullTrace = util.TraceHull({
        start = spawnPos,
        endpos = spawnPos,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID
    })

    if hullTrace.Hit then
        return false
    end

    if self:IsSpawnVisibleToAnyPlayer(spawnPos) then
        return false
    end

    return true
end

function MODE:FindNavMeshSpawnPoint(center, minRadius, maxRadius)
    local areas = navmesh.GetAllNavAreas() or {}
    if #areas == 0 then
        return nil
    end

    minRadius = minRadius or 0
    maxRadius = maxRadius or 4000

    local minRadiusSqr = minRadius * minRadius
    local maxRadiusSqr = maxRadius * maxRadius
    local candidates = {}

    for _, area in ipairs(areas) do
        if area:IsUnderwater() then
            continue
        end

        local spawnPos = area:GetCenter() + Vector(0, 0, 10)

        if center then
            local distSqr = center:DistToSqr(spawnPos)
            if distSqr < minRadiusSqr or distSqr > maxRadiusSqr then
                continue
            end
        end

        if self:IsValidNavMeshSpawn(spawnPos) then
            candidates[#candidates + 1] = spawnPos
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[math.random(#candidates)]
end


function MODE:AssignNPCTarget(npc)
    if not IsValid(npc) then return end  
    local function GetValidPlayers()
        local validPlayers = {}
        for _, ply in player.Iterator() do
            if IsValid(ply) and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
                table.insert(validPlayers, ply)
            end
        end
        return validPlayers
    end

    local validPlayers = GetValidPlayers()
    if #validPlayers == 0 then return end  

    local targetPlayer = validPlayers[math.random(#validPlayers)]  
    npc:UpdateEnemyMemory(targetPlayer, targetPlayer:GetPos())  
end

function MODE:StartNewWave()
    self.Wave = self.Wave or 0
    self.TotalWaves = self.TotalWaves or 6
    
    if self.Wave < self.TotalWaves then
        self.Wave = self.Wave + 1
        self.WaveCompleted = false
        
        if self.Wave % 2 == 0 then
            timer.Simple(0.5, function()
                for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
                    if IsValid(ent) then
                        local org = ent.organism
                        //if org and org.critical then
                            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                                ent:GetPhysicsObjectNum(i):Sleep()
                            end
                        //end
                    end
                end
            end)
        end
        
        self:CreateTimer("new_wave_timer", 60, 1, function() 
            self:SpawnWave() 
            self:StartWave() 
        end)

        net.Start("npc_defense_newwave")
            net.WriteFloat(CurTime() + 60)
            net.WriteInt(self.Wave, 4)
        net.Broadcast()
    elseif self.Wave == self.TotalWaves then
        self.WaveCompleted = true
        timer.Simple(5, function()
            if zb and zb.ROUND_STATE == 1 then
                zb.EndMatch()
            end
        end)
    end
end


function MODE:SpawnWave()
    local spawnPoints = self.GetDefenseAnchorPoints and self:GetDefenseAnchorPoints() or {}
    if not spawnPoints or #spawnPoints == 0 then
        return
    end
    
    local waveDefinitions = DEFENSE_WAVE_DEFINITIONS[self.CurrentSubMode]
    if not waveDefinitions or not waveDefinitions[self.Wave] then
        return
    end
    
    self.NPCCount = 0
    self.DefenseWaveEntities = {}
    self.WaveSpawnInProgress = true
    
    local currentWave = waveDefinitions[self.Wave]
    local spawnRadius = 2500
    local spawnQueue = {}
    self.SpawnBatchID = (self.SpawnBatchID or 0) + 1
    local spawnBatchID = self.SpawnBatchID
    

    local hasBoss = false
    for _, npcDef in ipairs(currentWave) do
        if npcDef.boss then
            hasBoss = true
            break
        end
    end
    

    if hasBoss then
        net.Start("defense_boss_incoming")
        net.Broadcast()
        

        for _, ply in player.Iterator() do
            if ply:GetNWString("PlayerRole") == "Commander" and ply:Alive() then
                net.Start("defense_commander_notification")
                net.WriteString("Boss wave! You'll receive double points after completing this wave!")
                net.WriteInt(0, 16)
                net.Send(ply)
            end
        end
    end
    
    print("[DEFENSE] Starting Wave " .. self.Wave .. " - Spawning NPCs...")
    
    for _, npcDef in ipairs(currentWave) do
        for i = 1, npcDef.count do
            spawnQueue[#spawnQueue + 1] = npcDef
        end
    end

    local totalPlannedSpawns = #spawnQueue

    if totalPlannedSpawns <= 0 then
        self.WaveSpawnInProgress = false
        return
    end

    for queueIndex, npcDef in ipairs(spawnQueue) do
        local queuedIndex = queueIndex
        local queuedNpcDef = npcDef
        local timerName = "defense_spawn_" .. spawnBatchID .. "_" .. queuedIndex

        self:CreateTimer(timerName, (queuedIndex - 1) * defenseSpawnStepDelay, 1, function()
            if self.SpawnBatchID ~= spawnBatchID then
                return
            end

            local point = spawnPoints[math.random(#spawnPoints)]
            local center = point.pos or point
            local spawnPos = self:FindNavMeshSpawnPoint(center, 250, spawnRadius)

            if not spawnPos then
                spawnPos = self:FindNavMeshSpawnPoint(nil, 0, 0)
            end

            if not spawnPos then
                spawnPos = self:FindValidSpawnPoint(center, 300)
            end
            
            if not spawnPos then
                if queuedIndex == totalPlannedSpawns then
                    self.WaveSpawnInProgress = false

                    if self.NPCCount <= 0 and self:IsWaveActive() then
                        self:EndWave()

                        if self.Wave and self.TotalWaves and self.Wave < self.TotalWaves then
                            timer.Simple(1, function()
                                if type(self.StartNewWave) == "function" then
                                    self:StartNewWave()
                                end
                            end)
                        end
                    end
                end

                return
            end
            
            local npc
            
            local t = queuedNpcDef.type
            if     string.sub(t, 1, 3) == "zb_"
                or string.sub(t, 1, 3) == "ej_"
                or string.sub(t, 1, 5) == "beta_"
            then
                npc = SpawnZBaseNPC(nil, queuedNpcDef.type, spawnPos, queuedNpcDef.weapon)
            elseif string.sub(queuedNpcDef.type, 1, 10) == "terminator" or string.find(queuedNpcDef.type, "sent_vj_") then
                npc = ents.Create(queuedNpcDef.type)
                if not IsValid(npc) then
                    if queuedIndex == totalPlannedSpawns then
                        self.WaveSpawnInProgress = false
                    end

                    return
                end
                npc:SetPos(spawnPos)
                npc:Spawn()
                
                npc.IsDefenseWaveNPC = true
            else
                npc = ents.Create(queuedNpcDef.type)
                if not IsValid(npc) then 
                    if queuedIndex == totalPlannedSpawns then
                        self.WaveSpawnInProgress = false
                    end

                    return
                end
                
                npc:SetPos(spawnPos)
                
                if queuedNpcDef.model then
                    npc:SetModel(queuedNpcDef.model)
                end
                
                if queuedNpcDef.keyvalues then
                    for key, value in pairs(queuedNpcDef.keyvalues) do
                        npc:SetKeyValue(key, value)
                    end
                end
                
                if queuedNpcDef.aggressive then
                    npc:SetKeyValue("aggressivebehavior", "1")
                    npc:SetKeyValue("spawnflags", "256") 
                    
                    if queuedNpcDef.type == "npc_zombie" or queuedNpcDef.type == "npc_fastzombie" or queuedNpcDef.type == "npc_poisonzombie" then
                        npc:SetKeyValue("incominghate", "1")
                    end
                end
                
                npc:Spawn()
                npc:Activate()
                
                if queuedNpcDef.weapon and queuedNpcDef.weapon ~= "" and not queuedNpcDef.default_weapon and 
                   (queuedNpcDef.type == "npc_combine_s" or queuedNpcDef.type == "npc_metropolice") then
                    npc:Give(queuedNpcDef.weapon)
                end
            end

            if not IsValid(npc) then 
                if queuedIndex == totalPlannedSpawns then
                    self.WaveSpawnInProgress = false
                end

                return
            end
            
            if npc:GetClass() == "zb_temporary_ent" then
                if queuedIndex == totalPlannedSpawns then
                    self.WaveSpawnInProgress = false
                end

                return
            end
            
            npc.IsDefenseWaveNPC = true
            npc.DefenseNPCCountedAsDead = false
            npc.DefenseEntityID = "defense_npc_" .. npc:EntIndex() .. "_" .. math.random(1000, 9999)
            
            self.DefenseWaveEntities[npc.DefenseEntityID] = npc
            
            print("[DEFENSE] Spawned NPC: " .. queuedNpcDef.type .. ", EntIndex: " .. npc:EntIndex())
            
            if queuedNpcDef.health and not (string.sub(queuedNpcDef.type, 1, 3) == "zb_") then
                npc:SetHealth(queuedNpcDef.health)
                npc:SetMaxHealth(queuedNpcDef.health)
            end

            if queuedNpcDef.type == "npc_turret_floor" and queuedNpcDef.no_target then
                timer.Simple(0.5, function()
                    if IsValid(npc) then
                        npc:Fire("Enable")
                        npc:SetKeyValue("spawnflags", "0") 
                    end
                end)
            end
            
            
            self:AssignNPCTarget(npc)

            if queuedNpcDef.relationship then
                local targetClass = queuedNpcDef.relationship.class
                local disposition = queuedNpcDef.relationship.disposition

                for _, targetNPC in ipairs(ents.FindByClass(targetClass)) do
                    if IsValid(targetNPC) then
                        npc:AddEntityRelationship(targetNPC, disposition, 99)
                        targetNPC:AddEntityRelationship(npc, disposition, 99)
                    end
                end
            end

            self.NPCCount = self.NPCCount + 1
            if queuedIndex == totalPlannedSpawns then
                self.WaveSpawnInProgress = false

                if self.NPCCount <= 0 and self:IsWaveActive() then
                    self:EndWave()

                    if self.Wave and self.TotalWaves and self.Wave < self.TotalWaves then
                        timer.Simple(1, function()
                            if type(self.StartNewWave) == "function" then
                                self:StartNewWave()
                            end
                        end)
                    end
                end
            end
        end)
    end
    
    print("[DEFENSE] Wave " .. self.Wave .. " started with " .. self.NPCCount .. " NPCs")
end


function MODE:OnNPCKilled(npc, attacker, inflictor)    
    if not npc or not IsValid(npc) then return end
    
    if npc:GetClass() == "zb_temporary_ent" then return end
    
    if not self.NPCCount then
        self.NPCCount = 0
    end
    

    self.Wave = self.Wave or 0
    self.TotalWaves = self.TotalWaves or 6

    if npc.IsDefenseWaveNPC then
        self.NPCCount = math.max(0, self.NPCCount - 1)
    
        if self.NPCCount <= 0 and not self.WaveSpawnInProgress then
            self:EndWave() 
            

            if self.Wave and self.TotalWaves and self.Wave < self.TotalWaves then
                timer.Simple(1, function()
                    if type(self.StartNewWave) == "function" then
                        self:StartNewWave()
                    end
                end)
            end
        end
    end
end
