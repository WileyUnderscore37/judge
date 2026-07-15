if SERVER then
    util.AddNetworkString("headtrauma_concussion_update")
end
hg.organism.module.concussion = {}
local module = hg.organism.module.concussion

local CONCUSSION_THRESHOLDS = { 0.5, 1.0, 2.5, 4.0 }
local STAGE_NAUSEA_GAIN = { 0.0, 0.8, 1.6, 2.6, 4.0 }
local STAGE_NAUSEA_SPIKE_CHANCE = { 0.0, 0.0, 0.35, 0.65, 0.9 }
local STAGE_VOMIT_INTERVAL = { 0, 0, 6, 3.5, 2 }
local STAGE_NAUSEA_CAP = { 0.0, 0.4, 1.5, 3.0, 5.0 }

local concussion_phrases = {
    "My head is ringing...",
    "Everything is spinning...",
    "I can't focus...",
    "I feel sick...",
    "What happened...?",
    "Everything is so loud...",
    "My ears are ringing...",
    "I can't think straight...",
    "The world is tilting...",
    "I'm so dizzy...",
    "My head hurts so much...",
    "Something's wrong with me...",
    "I can't hear properly...",
    "Everything's a blur...",
    "My skull is pounding...",
    "I feel like I'm gonna throw up...",
    "Where am I...?",
    "I can't keep my balance...",
    "My vision is shaking...",
    "It feels like my brain's rattling...",
    "I'm seeing double...",
    "The noise is killing me...",
    "I can't stand the light...",
    "My head's about to explode...",
    "Everything's muffled..."
}
local concussion_phrases_severe = {
    "I think I'm going to pass out...",
    "I can't see properly...",
    "Everything is blurred...",
    "I'm going to be sick...",
    "Make it stop...",
    "I can't breathe right...",
    "My head's splitting open...",
    "I'm falling... I'm falling...",
    "Everything's going black...",
    "I can't feel my legs...",
    "Please... somebody help...",
    "It hurts... it hurts so much...",
    "I'm losing consciousness...",
    "The ground won't stop moving...",
    "I can't tell up from down...",
    "My eyes won't focus...",
    "I think I'm dying...",
    "Everything's spinning too fast...",
    "I can't move my arms...",
    "Get this noise out of my head..."
}
local concussion_phrases_vomit = {
    "I'm gonna be sick...",
    "Bleargh— I can't stop throwing up...",
    "My stomach's turning inside out...",
    "I think I'm gonna hurl again...",
    "Everything's making me puke...",
    "Ugh... my head and my stomach...",
    "I can't keep anything down...",
    "The nausea won't stop...",
    "I'm gonna throw up...",
    "My gut is killing me...",
    "Bleargh...",
    "I feel like puking my guts out...",
    "I'm gonna be sick all over the floor...",
    "My stomach's cramping so bad..."
}

module[1] = function(org)
    org.concussion = 0
    org.nausea = 0
    org.nextConcussionVomit = 0
    org.nextConcussionPhrase = 0
    org.concussion_tinnitus = 0
    org.concussion_effects = {
        severity = 0,
        duration = 0,
        last_impact = 0
    }
end

module[2] = function(ply, org, timeValue)
    if not org.concussion then org.concussion = 0 end
    if not org.nausea then org.nausea = 0 end
    if not org.concussion_tinnitus then org.concussion_tinnitus = 0 end
    if not org.concussion_effects then
        org.concussion_effects = {severity = 0, duration = 0, last_impact = 0}
    end
    if org.concussion <= 0 and org.nausea <= 0 then return end

    if org.concussion > 0 then
        local decayRate = 0.04 + (org.concussion > 3 and 0.02 or 0)
        org.concussion = math.max(org.concussion - timeValue * decayRate, 0)

        if org.consciousness then
            local drainRate = 0.032 + (org.concussion_effects.severity * 0.02)
            org.consciousness = math.max(org.consciousness - (org.concussion * drainRate) * timeValue, 0)
        end

        if org.concussion > 1.0 then
            org.disorientation = math.max(org.disorientation or 0, org.concussion * 0.6)
        end

        if org.concussion > 2.0 then
            org.needfake = true
            org.immobilization = math.max(org.immobilization or 0, org.concussion * 8)
        end

        if org.concussion > 1.5 then
            org.shock = math.min((org.shock or 0) + timeValue * 2 * org.concussion, 50)
            org.fearadd = math.min((org.fearadd or 0) + timeValue * 0.15 * org.concussion, 2)
        end

        local curStage = module.GetStage(org)
        local stageCap = STAGE_NAUSEA_CAP[curStage + 1] or 0
        if stageCap > 0 then
            local drift = (stageCap - (org.nausea or 0)) * timeValue * 0.05
            org.nausea = math.min((org.nausea or 0) + drift, stageCap)
        end

        if org.concussion > 0.3 then
            org.concussion_tinnitus = math.max(org.concussion_tinnitus or 0, org.concussion * 0.4)
        end

        if org.isPly and not org.otrub and IsValid(ply) and ply:IsPlayer() and (org.nextConcussionPhrase or 0) < CurTime() then
            local phrase
            if org.nausea > 0.6 then
                phrase = concussion_phrases_vomit[math.random(#concussion_phrases_vomit)]
            elseif org.concussion > 2.5 then
                phrase = concussion_phrases_severe[math.random(#concussion_phrases_severe)]
            elseif org.concussion > 1.0 then
                phrase = concussion_phrases[math.random(#concussion_phrases)]
            end
            if phrase then
                ply:Notify(phrase, 5, "concussion_phrase", 0)
                org.nextConcussionPhrase = CurTime() + math.random(8, 18)
            end
        end

        if org.concussion_effects.duration > 0 then
            org.concussion_effects.duration = math.max(org.concussion_effects.duration - timeValue, 0)
            if org.concussion_effects.severity > 0.3 and IsValid(ply) and ply:IsPlayer() and (org.concussion_effects.last_impact or 0) < CurTime() - 1.5 then
                net.Start("headtrauma_concussion_update")
                    net.WriteFloat(org.concussion_effects.severity)
                    net.WriteFloat(org.concussion)
                net.Send(ply)
                org.concussion_effects.last_impact = CurTime()
            end
        end
    end

    org.concussion_tinnitus = math.Approach(org.concussion_tinnitus or 0, 0, timeValue * 0.15)

    if (org.nausea or 0) > 0 then
        org.nausea = math.max(org.nausea - timeValue * 0.04, 0)
        if org.nausea == 0 then org.nextConcussionVomit = nil end

        local curStage = module.GetStage(org)
        local vomitInterval = STAGE_VOMIT_INTERVAL[curStage + 1] or 0
        if vomitInterval > 0 and org.nausea > 0.6 and not org.otrub then
            local now = CurTime()
            if org.nextConcussionVomit == nil then
                org.nextConcussionVomit = now + math.Rand(2.5, 5)
            elseif now > org.nextConcussionVomit then
                local jitter = math.Rand(0.8, 1.2)
                org.nextConcussionVomit = now + vomitInterval * jitter
                hg.organism.VomitConcussion(ply)

                if curStage >= 4 and math.random() < 0.4 then
                    org.vomitInThroat = true
                    if org.isPly and IsValid(ply) and ply:IsPlayer() then
                        ply:Notify("I'm choking... I can't breathe...", 4, "concussion_choke", 0)
                    end
                end
            end
        end

        if org.nausea > 2.0 and not org.otrub then
            org.disorientation = math.max(org.disorientation or 0, org.nausea * 0.4)
        end
    end
end

function module.AddConcussion(org, intensity, duration)
    if not org then return end
    if not org.concussion then org.concussion = 0 end
    if not org.nausea then org.nausea = 0 end
    if not org.concussion_tinnitus then org.concussion_tinnitus = 0 end
    if not org.concussion_effects then
        org.concussion_effects = {severity = 0, duration = 0, last_impact = 0}
    end

    local now = CurTime()
    org.concussion_lastImpact = org.concussion_lastImpact or 0
    local sinceLast = now - org.concussion_lastImpact
    local rapidScale = math.Clamp(sinceLast / 1.5, 0.15, 1)
    org.concussion_lastImpact = now

    local headroom = math.Clamp((5.0 - org.concussion) / 5.0, 0, 1)
    local add = intensity * rapidScale * (0.35 + 0.65 * headroom)

    local prevStage = module.GetStage(org)

    org.concussion = math.min(org.concussion + add, 5.0)
    org.concussion_effects.severity = math.max(org.concussion_effects.severity or 0, add)
    org.concussion_effects.duration = math.max(org.concussion_effects.duration or 0, duration or math.Clamp(intensity * 5, 5, 60))
    org.concussion_tinnitus = math.max(org.concussion_tinnitus or 0, add * 0.6)

    local newStage = module.GetStage(org)
    local stageGain = STAGE_NAUSEA_GAIN[newStage + 1] or 0
    local nauseaAdd = add * 0.3 + stageGain * 0.4
    if newStage > prevStage then
        nauseaAdd = nauseaAdd + STAGE_NAUSEA_GAIN[newStage + 1] * 0.5
        if math.random() < (STAGE_NAUSEA_SPIKE_CHANCE[newStage + 1] or 0) then
            nauseaAdd = nauseaAdd + STAGE_NAUSEA_GAIN[newStage + 1] * 0.8
        end
    end
    local nauseaCap = STAGE_NAUSEA_CAP[newStage + 1] or 0
    org.nausea = math.min(math.max(org.nausea or 0, nauseaAdd), nauseaCap)

    if add > 1.5 then
        org.disorientation = math.max(org.disorientation or 0, add * 0.5)
    end
    if add > 2.0 then
        org.panic = math.max(org.panic or 0, add * 0.3)
        org.needfake = true
    end
end

function module.HasConcussionSymptoms(org)
    return org and org.concussion and org.concussion > 0.5
end

function module.GetConcussionSeverity(org)
    if not org or not org.concussion then return "none" end
    if org.concussion < 1.0 then return "mild"
    elseif org.concussion < 2.5 then return "moderate"
    elseif org.concussion < 4.0 then return "severe"
    else return "critical" end
end

function module.GetStage(org)
    if not org or not org.concussion then return 0 end
    local c = org.concussion
    if c < CONCUSSION_THRESHOLDS[1] then return 0
    elseif c < CONCUSSION_THRESHOLDS[2] then return 1
    elseif c < CONCUSSION_THRESHOLDS[3] then return 2
    elseif c < CONCUSSION_THRESHOLDS[4] then return 3
    else return 4 end
end

local min, max, Clamp, Approach = math.min, math.max, math.Clamp, math.Approach
hg.organism.module.trauma_combo = {}
local module = hg.organism.module.trauma_combo
module[1] = function(org)
	org.combo_hemohypoxia = 0
	org.combo_painhypovolemia = 0
	org.nextComboPhrase = 0
end
local combo_hemohypoxia_phrases = {
	"I can't breathe... and I'm freezing...",
	"I'm fading out...",
	"Everything is going dark..."
}
local combo_painhypovolemia_phrases = {
	"Too much pain... I can't move...",
	"I feel weak and dizzy...",
	"I might collapse..."
}
module[2] = function(owner, org, timeValue)
	if not org.alive then
		org.combo_hemohypoxia = 0
		org.combo_painhypovolemia = 0
		return
	end
	local o2 = org.o2 and org.o2[1] or 30
	local blood = org.blood or 5000
	local hemoPart = Clamp((2600 - blood) / 1100, 0, 1)
	local hypoPart = Clamp((14 - o2) / 10, 0, 1)
	local comboHemohypoxiaTarget = hemoPart * hypoPart
	org.combo_hemohypoxia = Approach(org.combo_hemohypoxia or 0, comboHemohypoxiaTarget, timeValue / 6)
	local painPart = Clamp((org.pain - 60) / 35, 0, 1)
	local hypoVolPart = Clamp((3300 - blood) / 1000, 0, 1)
	local comboPainHypovolemiaTarget = painPart * hypoVolPart
	org.combo_painhypovolemia = Approach(org.combo_painhypovolemia or 0, comboPainHypovolemiaTarget, timeValue / 6)
	local hemohypoxia = org.combo_hemohypoxia or 0
	if hemohypoxia > 0 then
		org.shock = min((org.shock or 0) + timeValue * 8 * hemohypoxia, 85)
		org.disorientation = min((org.disorientation or 0) + timeValue * 1.3 * hemohypoxia, 10)
		org.fearadd = min((org.fearadd or 0) + timeValue * 0.4 * hemohypoxia, 3)
		org.consciousness = Approach(org.consciousness or 1, max(0.05, 0.35 - hemohypoxia * 0.25), timeValue / 10 * hemohypoxia)
	end
	local painhypo = org.combo_painhypovolemia or 0
	if painhypo > 0 then
		org.immobilization = min((org.immobilization or 0) + timeValue * 12 * painhypo, 90)
		org.shock = min((org.shock or 0) + timeValue * 6 * painhypo, 90)
		org.fearadd = min((org.fearadd or 0) + timeValue * 0.25 * painhypo, 3)
		if org.stamina then
			org.stamina.subadd = (org.stamina.subadd or 0) + painhypo * 0.35
		end
	end
	if org.isPly and not org.otrub and (org.nextComboPhrase or 0) < CurTime() then
		if hemohypoxia > 0.5 then
			org.nextComboPhrase = CurTime() + math.random(14, 22)
			owner:Notify(combo_hemohypoxia_phrases[math.random(#combo_hemohypoxia_phrases)], 6, "combo_hemohypoxia", 0)
		elseif painhypo > 0.55 then
			org.nextComboPhrase = CurTime() + math.random(14, 22)
			owner:Notify(combo_painhypovolemia_phrases[math.random(#combo_painhypovolemia_phrases)], 6, "combo_painhypovolemia", 0)
		end
	end
end

if SERVER then
    concommand.Add("hg_concussion_test", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        local intensity = tonumber(args[1]) or 1.5
        local duration = tonumber(args[2]) or 15
        if not ply.organism then return end
        hg.organism.module.concussion.AddConcussion(ply.organism, intensity, duration)
        ply:Notify("Concussion: " .. math.Round(intensity, 2) .. " / " .. math.Round(duration, 1) .. "s", 5, "conc_test", 0)
    end)
end
