if SERVER then
    util.AddNetworkString("headtrauma_concussion_update")
end
hg.organism.module.concussion = {}
local module = hg.organism.module.concussion

local CONCUSSION_MAX = 6.0
local DECAY_BASE = 0.025
local DECAY_SEVERE_BONUS = 0.015
local ONSET_SPEED = 0.4
local POST_CONCUSSION_THRESHOLD = 0.3
local POST_CONCUSSION_DECAY = 0.008
local SECOND_IMPACT_WINDOW = 8.0
local SECOND_IMPACT_SCALE = 0.35
local LOC_THRESHOLD = 3.8
local LOC_CHANCE_BASE = 0.15
local LOC_CHANCE_PER_POINT = 0.12
local NAUSEA_WAVE_FREQ = 0.18
local NAUSEA_WAVE_AMP = 0.35
local NAUSEA_ONSET_DELAY_LIGHT = 25.0
local NAUSEA_ONSET_DELAY_SEVERE = 6.0
local NAUSEA_RAMP_SPEED = 0.025
local VOMIT_RELIEF = 0.6
local VOMIT_STAMINA_DRAIN = 8.0
local VOMIT_PULSE_SPIKE = 15.0
local VOMIT_DEHYDRATION = 0.4
local DRY_HEAVE_NAUSEA = 1.8
local DRY_HEAVE_CHANCE = 0.25
local LUCID_INTERVAL_CHANCE = 0.15
local LUCID_INTERVAL_MIN = 30.0
local LUCID_INTERVAL_MAX = 120.0
local SYMPTOM_WAVE_FREQ = 0.08
local SYMPTOM_WAVE_AMP = 0.25
local HEADACHE_BASE = 0.3
local HEADACHE_SEVERE = 0.8
local FATIGUE_DRAIN = 0.15
local COGNITIVE_THRESHOLD = 1.5
local PHOTOPHOBIA_THRESHOLD = 2.0
local PHONOPHOBIA_THRESHOLD = 1.8

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
    "Bleargh... I can't stop throwing up...",
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
local concussion_phrases_dryheave = {
    "Hkk... I can't... nothing's coming out...",
    "Uugh... dry heaving... my chest hurts...",
    "I'm trying to puke but... nothing...",
    "Hkk... hkk... god... my throat...",
    "Can't even throw up properly..."
}
local concussion_phrases_cognitive = {
    "What was I doing...?",
    "I can't remember...",
    "My thoughts are so slow...",
    "Why is it so hard to think...?",
    "I keep losing my train of thought...",
    "What happened just now...?",
    "I can't concentrate...",
    "My mind feels foggy...",
    "I'm so confused...",
    "I can't process anything..."
}
local concussion_phrases_photophobia = {
    "The light... it hurts my eyes...",
    "Everything's too bright...",
    "I can't stand the light...",
    "My eyes are burning...",
    "Please... turn off the lights..."
}
local concussion_phrases_phonophobia = {
    "Everything's too loud...",
    "The noise is unbearable...",
    "My ears... stop the noise...",
    "I can't stand any more sound...",
    "Even breathing sounds too loud..."
}
local concussion_phrases_headache = {
    "My head is pounding...",
    "The pain in my skull...",
    "It feels like my head's splitting...",
    "My temples are throbbing...",
    "The headache won't stop...",
    "Every heartbeat makes my head hurt more..."
}
local concussion_phrases_fatigue = {
    "I'm so tired...",
    "I just want to sleep...",
    "Can barely keep my eyes open...",
    "So exhausted...",
    "I need to rest... I can't go on..."
}

module[1] = function(org)
    org.concussion = 0
    org.concussion_onset = 0
    org.concussion_peak = 0
    org.concussion_impacts = 0
    org.concussion_lastImpact = 0
    org.concussion_lucid_end = 0
    org.concussion_symptom_wave_timer = 0
    org.nausea = 0
    org.nausea_target = 0
    org.nausea_pending = 0
    org.nausea_onset_time = 0
    org.nausea_wave_timer = 0
    org.nausea_vomit_count = 0
    org.nextConcussionVomit = 0
    org.nextConcussionPhrase = 0
    org.nextDryHeave = 0
    org.nextCognitivePhrase = 0
    org.nextSensoryPhrase = 0
    org.nextHeadachePhrase = 0
    org.nextFatiguePhrase = 0
    org.concussion_tinnitus = 0
    org.concussion_headache = 0
    org.concussion_fatigue = 0
    org.concussion_post = 0
    org.concussion_loc_timer = 0
    org.concussion_effects = {
        severity = 0,
        duration = 0,
        last_impact = 0
    }
end

module[2] = function(ply, org, timeValue)
    if not org.concussion then org.concussion = 0 end
    if not org.concussion_onset then org.concussion_onset = 0 end
    if not org.concussion_peak then org.concussion_peak = 0 end
    if not org.concussion_lucid_end then org.concussion_lucid_end = 0 end
    if not org.concussion_symptom_wave_timer then org.concussion_symptom_wave_timer = 0 end
    if not org.nausea then org.nausea = 0 end
    if not org.nausea_target then org.nausea_target = 0 end
    if not org.nausea_pending then org.nausea_pending = 0 end
    if not org.nausea_onset_time then org.nausea_onset_time = 0 end
    if not org.nausea_wave_timer then org.nausea_wave_timer = 0 end
    if not org.concussion_tinnitus then org.concussion_tinnitus = 0 end
    if not org.concussion_headache then org.concussion_headache = 0 end
    if not org.concussion_fatigue then org.concussion_fatigue = 0 end
    if not org.concussion_post then org.concussion_post = 0 end
    if not org.concussion_effects then
        org.concussion_effects = {severity = 0, duration = 0, last_impact = 0}
    end

    local hasConcussion = org.concussion > 0 or org.concussion_onset > 0
    local hasNausea = org.nausea > 0 or org.nausea_target > 0 or org.nausea_pending > 0
    local hasPost = org.concussion_post > POST_CONCUSSION_THRESHOLD
    local hasHeadache = org.concussion_headache > 0.1
    local hasFatigue = org.concussion_fatigue > 0.1

    if not hasConcussion and not hasNausea and not hasPost and not hasHeadache and not hasFatigue then return end

    local now = CurTime()

    if org.concussion_lucid_end > now then
        if org.concussion > 0 then
            org.concussion = math.max(org.concussion - timeValue * DECAY_BASE * 0.3, 0)
        end
        return
    end

    if org.concussion_onset > 0 then
        local onsetTransfer = math.min(org.concussion_onset, timeValue * ONSET_SPEED * (1 + org.concussion_peak * 0.15))
        org.concussion_onset = org.concussion_onset - onsetTransfer
        org.concussion = org.concussion + onsetTransfer
    end

    if org.concussion > 0 then
        local severityRatio = org.concussion / CONCUSSION_MAX
        local decayMul = 1.0 - severityRatio * 0.4
        local decay = DECAY_BASE * decayMul
        if org.concussion > 3.0 then
            decay = decay + DECAY_SEVERE_BONUS * (1.0 - severityRatio)
        end
        org.concussion = math.max(org.concussion - timeValue * decay, 0)

        if org.concussion < POST_CONCUSSION_THRESHOLD and org.concussion_peak > 1.0 then
            org.concussion_post = math.max(org.concussion_post, org.concussion_peak * 0.3)
        end

        if org.concussion_peak > org.concussion then
            org.concussion_peak = math.max(org.concussion_peak - timeValue * decay * 0.5, org.concussion)
        end

        org.concussion_symptom_wave_timer = (org.concussion_symptom_wave_timer or 0) + timeValue * SYMPTOM_WAVE_FREQ
        local symptomWave = math.sin(org.concussion_symptom_wave_timer * math.pi * 2) * SYMPTOM_WAVE_AMP
        local effectiveConcussion = org.concussion + org.concussion_post * 0.2 + symptomWave * org.concussion * 0.3

        if org.consciousness then
            local drainBase = 0.02 + severityRatio * 0.04
            local drainMul = 1.0 + (org.concussion_impacts * 0.08)
            org.consciousness = math.max(org.consciousness - (effectiveConcussion * drainBase * drainMul) * timeValue, 0)
        end

        if effectiveConcussion > 0.8 then
            org.disorientation = math.max(org.disorientation or 0, effectiveConcussion * 0.55 + severityRatio * 0.3)
        end

        if effectiveConcussion > 1.8 then
            org.needfake = true
            local immobScale = (effectiveConcussion - 1.8) * 6.0
            org.immobilization = math.max(org.immobilization or 0, immobScale)
        end

        if effectiveConcussion > 1.2 then
            local shockRate = 1.5 + severityRatio * 2.0
            org.shock = math.min((org.shock or 0) + timeValue * shockRate, 55)
            org.fearadd = math.min((org.fearadd or 0) + timeValue * 0.12 * effectiveConcussion, 2.5)
        end

        if effectiveConcussion > 0.5 then
            local pulseAdd = effectiveConcussion * 3.5
            org.pulse = math.min((org.pulse or 70) + timeValue * pulseAdd, 160)
        end

        local headacheTarget = HEADACHE_BASE * effectiveConcussion
        if effectiveConcussion > 2.5 then headacheTarget = headacheTarget + HEADACHE_SEVERE end
        org.concussion_headache = math.Approach(org.concussion_headache or 0, headacheTarget, timeValue * 0.05)

        local fatigueTarget = effectiveConcussion * FATIGUE_DRAIN
        if org.concussion_impacts > 1 then fatigueTarget = fatigueTarget * (1 + org.concussion_impacts * 0.15) end
        org.concussion_fatigue = math.Approach(org.concussion_fatigue or 0, fatigueTarget, timeValue * 0.03)
        if org.concussion_fatigue > 0.3 and org.stamina then
            org.stamina.subadd = (org.stamina.subadd or 0) + org.concussion_fatigue * timeValue * 2
        end

        if org.concussion > LOC_THRESHOLD and org.alive and not org.otrub then
            local locChance = LOC_CHANCE_BASE + (org.concussion - LOC_THRESHOLD) * LOC_CHANCE_PER_POINT
            org.concussion_loc_timer = (org.concussion_loc_timer or 0) + timeValue
            if org.concussion_loc_timer > 2.0 and math.random() < locChance * timeValue then
                if org.consciousness then
                    org.consciousness = math.max(org.consciousness - 0.4, 0)
                end
                org.concussion_loc_timer = 0
                if org.isPly and IsValid(ply) and ply:IsPlayer() then
                    ply:Notify("Everything goes black...", 6, "concussion_loc", 0)
                end
            end
        else
            org.concussion_loc_timer = math.max((org.concussion_loc_timer or 0) - timeValue * 0.5, 0)
        end

        local stage = module.GetStage(org)
        local nauseaTargetBase = 0
        if stage >= 1 then nauseaTargetBase = 0.4 end
        if stage >= 2 then nauseaTargetBase = 1.2 + (effectiveConcussion - 1.0) * 0.6 end
        if stage >= 3 then nauseaTargetBase = 2.5 + (effectiveConcussion - 2.5) * 0.8 end
        if stage >= 4 then nauseaTargetBase = 4.0 + (effectiveConcussion - 4.0) * 1.2 end

        if not org.nausea_pending then org.nausea_pending = 0 end
        if not org.nausea_onset_time then org.nausea_onset_time = 0 end
        if org.nausea_pending > 0 and now >= org.nausea_onset_time then
            local rampAmount = math.min(org.nausea_pending, timeValue * NAUSEA_RAMP_SPEED * (1 + stage * 0.15))
            org.nausea_target = math.min((org.nausea_target or 0) + rampAmount, nauseaTargetBase + org.nausea_pending)
            org.nausea_pending = org.nausea_pending - rampAmount
        end

        if nauseaTargetBase > (org.nausea_target or 0) then
            org.nausea_target = math.min((org.nausea_target or 0) + timeValue * NAUSEA_RAMP_SPEED * 0.5, nauseaTargetBase)
        elseif nauseaTargetBase < (org.nausea_target or 0) then
            org.nausea_target = math.Approach(org.nausea_target or 0, nauseaTargetBase, timeValue * 0.02)
        end

        if effectiveConcussion > 0.2 then
            org.concussion_tinnitus = math.max(org.concussion_tinnitus or 0, effectiveConcussion * 0.35)
        end

        if org.isPly and not org.otrub and IsValid(ply) and ply:IsPlayer() then
            if (org.nextConcussionPhrase or 0) < now then
                local phrase
                if org.nausea > 1.0 then
                    phrase = concussion_phrases_vomit[math.random(#concussion_phrases_vomit)]
                elseif effectiveConcussion > 2.5 then
                    phrase = concussion_phrases_severe[math.random(#concussion_phrases_severe)]
                elseif effectiveConcussion > 0.8 then
                    phrase = concussion_phrases[math.random(#concussion_phrases)]
                end
                if phrase then
                    ply:Notify(phrase, 5, "concussion_phrase", 0)
                    local phraseDelay = 10 + math.random(0, 12)
                    if stage >= 3 then phraseDelay = 6 + math.random(0, 8) end
                    org.nextConcussionPhrase = now + phraseDelay
                end
            end

            if effectiveConcussion > COGNITIVE_THRESHOLD and (org.nextCognitivePhrase or 0) < now then
                ply:Notify(concussion_phrases_cognitive[math.random(#concussion_phrases_cognitive)], 5, "concussion_cognitive", 0)
                org.nextCognitivePhrase = now + math.Rand(12, 20)
            end

            if effectiveConcussion > PHOTOPHOBIA_THRESHOLD and (org.nextSensoryPhrase or 0) < now then
                if math.random() < 0.5 then
                    ply:Notify(concussion_phrases_photophobia[math.random(#concussion_phrases_photophobia)], 5, "concussion_photophobia", 0)
                else
                    ply:Notify(concussion_phrases_phonophobia[math.random(#concussion_phrases_phonophobia)], 5, "concussion_phonophobia", 0)
                end
                org.nextSensoryPhrase = now + math.Rand(15, 25)
            end

            if org.concussion_headache > 0.5 and (org.nextHeadachePhrase or 0) < now then
                ply:Notify(concussion_phrases_headache[math.random(#concussion_phrases_headache)], 5, "concussion_headache", 0)
                org.nextHeadachePhrase = now + math.Rand(10, 18)
            end

            if org.concussion_fatigue > 0.4 and (org.nextFatiguePhrase or 0) < now then
                ply:Notify(concussion_phrases_fatigue[math.random(#concussion_phrases_fatigue)], 5, "concussion_fatigue", 0)
                org.nextFatiguePhrase = now + math.Rand(14, 22)
            end
        end

        if org.concussion_effects.duration > 0 then
            org.concussion_effects.duration = math.max(org.concussion_effects.duration - timeValue, 0)
            if org.concussion_effects.severity > 0.3 and IsValid(ply) and ply:IsPlayer() and (org.concussion_effects.last_impact or 0) < now - 1.5 then
                net.Start("headtrauma_concussion_update")
                    net.WriteFloat(org.concussion_effects.severity)
                    net.WriteFloat(org.concussion)
                net.Send(ply)
                org.concussion_effects.last_impact = now
            end
        end
    end

    if org.concussion_post > 0 then
        org.concussion_post = math.max(org.concussion_post - timeValue * POST_CONCUSSION_DECAY, 0)
        if org.concussion_post > POST_CONCUSSION_THRESHOLD then
            org.disorientation = math.max(org.disorientation or 0, org.concussion_post * 0.15)
            org.concussion_tinnitus = math.max(org.concussion_tinnitus or 0, org.concussion_post * 0.1)
        end
    end

    org.concussion_tinnitus = math.Approach(org.concussion_tinnitus or 0, 0, timeValue * 0.12)
    org.concussion_headache = math.Approach(org.concussion_headache or 0, 0, timeValue * 0.04)
    org.concussion_fatigue = math.Approach(org.concussion_fatigue or 0, 0, timeValue * 0.02)

    org.nausea_wave_timer = (org.nausea_wave_timer or 0) + timeValue * NAUSEA_WAVE_FREQ
    local waveOffset = math.sin(org.nausea_wave_timer * math.pi * 2) * NAUSEA_WAVE_AMP
    local nauseaTargetWithWave = math.max(0, (org.nausea_target or 0) + waveOffset * (org.nausea_target or 0) * 0.5)

    if nauseaTargetWithWave > 0 then
        local approachSpeed = timeValue * 0.08
        if org.nausea < nauseaTargetWithWave then
            org.nausea = math.min(org.nausea + approachSpeed * (1 + nauseaTargetWithWave * 0.1), nauseaTargetWithWave)
        else
            org.nausea = math.Approach(org.nausea, nauseaTargetWithWave, timeValue * 0.03)
        end
    else
        org.nausea = math.max(org.nausea - timeValue * 0.025, 0)
    end

    if org.nausea <= 0.05 then
        org.nausea = 0
        org.nausea_vomit_count = 0
        org.nextConcussionVomit = nil
    end

    if org.nausea > 0.8 and not org.otrub then
        org.disorientation = math.max(org.disorientation or 0, org.nausea * 0.35)
    end

    if org.nausea > 0.6 and not org.otrub then
        local stage = module.GetStage(org)
        local baseInterval
        if stage <= 1 then
            baseInterval = 0
        elseif stage == 2 then
            baseInterval = 8.0 - (org.nausea_vomit_count or 0) * 0.3
        elseif stage == 3 then
            baseInterval = 5.0 - (org.nausea_vomit_count or 0) * 0.2
        else
            baseInterval = 3.0 - (org.nausea_vomit_count or 0) * 0.15
        end
        baseInterval = math.max(baseInterval, 1.5)

        if org.nextConcussionVomit == nil then
            local initialDelay = math.Rand(3.0, 6.0)
            if stage >= 3 then initialDelay = math.Rand(1.5, 3.5) end
            org.nextConcussionVomit = now + initialDelay
        elseif now > org.nextConcussionVomit then
            local jitter = math.Rand(0.85, 1.15)
            org.nextConcussionVomit = now + baseInterval * jitter
            hg.organism.VomitConcussion(ply)
            org.nausea_vomit_count = (org.nausea_vomit_count or 0) + 1
            org.nausea = math.max(org.nausea - VOMIT_RELIEF, 0)

            if org.stamina then
                org.stamina.subadd = (org.stamina.subadd or 0) + VOMIT_STAMINA_DRAIN
            end
            org.pulse = math.min((org.pulse or 70) + VOMIT_PULSE_SPIKE, 180)
            if org.satiety then
                org.satiety = math.max((org.satiety or 0) - VOMIT_DEHYDRATION * 10, 0)
            end

            if stage >= 4 and math.random() < 0.35 then
                org.vomitInThroat = true
                if org.isPly and IsValid(ply) and ply:IsPlayer() then
                    ply:Notify("I'm choking... I can't breathe...", 4, "concussion_choke", 0)
                end
            end
        end
    else
        org.nextConcussionVomit = nil
    end

    if org.nausea > DRY_HEAVE_NAUSEA and not org.otrub and (org.nextDryHeave or 0) < now then
        if math.random() < DRY_HEAVE_CHANCE then
            if org.isPly and IsValid(ply) and ply:IsPlayer() then
                ply:Notify(concussion_phrases_dryheave[math.random(#concussion_phrases_dryheave)], 4, "concussion_dryheave", 0)
            end
            if org.stamina then
                org.stamina.subadd = (org.stamina.subadd or 0) + VOMIT_STAMINA_DRAIN * 0.4
            end
            org.nextDryHeave = now + math.Rand(4.0, 8.0)
        end
    end
end

function module.AddConcussion(org, intensity, duration)
    if not org then return end
    if not org.concussion then org.concussion = 0 end
    if not org.concussion_onset then org.concussion_onset = 0 end
    if not org.concussion_peak then org.concussion_peak = 0 end
    if not org.concussion_impacts then org.concussion_impacts = 0 end
    if not org.concussion_lastImpact then org.concussion_lastImpact = 0 end
    if not org.concussion_lucid_end then org.concussion_lucid_end = 0 end
    if not org.nausea then org.nausea = 0 end
    if not org.nausea_target then org.nausea_target = 0 end
    if not org.nausea_pending then org.nausea_pending = 0 end
    if not org.nausea_onset_time then org.nausea_onset_time = 0 end
    if not org.concussion_tinnitus then org.concussion_tinnitus = 0 end
    if not org.concussion_headache then org.concussion_headache = 0 end
    if not org.concussion_fatigue then org.concussion_fatigue = 0 end
    if not org.concussion_post then org.concussion_post = 0 end
    if not org.concussion_effects then
        org.concussion_effects = {severity = 0, duration = 0, last_impact = 0}
    end

    local now = CurTime()
    local sinceLast = now - org.concussion_lastImpact

    local rapidScale = 1.0
    if sinceLast < SECOND_IMPACT_WINDOW then
        rapidScale = 1.0 + SECOND_IMPACT_SCALE * (1.0 - sinceLast / SECOND_IMPACT_WINDOW)
    end

    local headroom = math.Clamp((CONCUSSION_MAX - org.concussion - org.concussion_onset) / CONCUSSION_MAX, 0.05, 1)
    local cumulativeBonus = 1.0 + org.concussion_impacts * 0.06
    local add = intensity * rapidScale * headroom * cumulativeBonus

    org.concussion_lastImpact = now
    org.concussion_impacts = org.concussion_impacts + 1

    if org.concussion_peak > 1.5 and math.random() < LUCID_INTERVAL_CHANCE then
        local lucidDuration = math.Rand(LUCID_INTERVAL_MIN, LUCID_INTERVAL_MAX)
        org.concussion_lucid_end = now + lucidDuration
        org.concussion_onset = org.concussion_onset + add
        org.concussion_peak = math.max(org.concussion_peak, org.concussion + org.concussion_onset)
        if org.isPly and IsValid(org.owner) and org.owner:IsPlayer() then
            org.owner:Notify("I feel... okay? Maybe it wasn't that bad...", 6, "concussion_lucid", 0)
        end
        return
    end

    local onsetPortion = math.min(add * 0.4, add)
    local immediatePortion = add - onsetPortion

    org.concussion = math.min(org.concussion + immediatePortion, CONCUSSION_MAX)
    org.concussion_onset = math.min(org.concussion_onset + onsetPortion, CONCUSSION_MAX - org.concussion)
    org.concussion_peak = math.max(org.concussion_peak, org.concussion + org.concussion_onset)

    org.concussion_effects.severity = math.max(org.concussion_effects.severity or 0, add)
    org.concussion_effects.duration = math.max(org.concussion_effects.duration or 0, duration or math.Clamp(intensity * 6, 5, 80))
    org.concussion_tinnitus = math.max(org.concussion_tinnitus or 0, add * 0.5)
    org.concussion_headache = math.max(org.concussion_headache or 0, add * 0.4)
    org.concussion_fatigue = math.max(org.concussion_fatigue or 0, add * 0.2)

    local stage = module.GetStage(org)
    local nauseaSpike = add * 0.25
    if stage >= 2 then nauseaSpike = nauseaSpike + 0.5 end
    if stage >= 3 then nauseaSpike = nauseaSpike + 1.2 end
    if stage >= 4 then nauseaSpike = nauseaSpike + 2.0 end

    local delay = NAUSEA_ONSET_DELAY_LIGHT
    if add > 2.0 then delay = NAUSEA_ONSET_DELAY_SEVERE
    elseif add > 1.0 then delay = NAUSEA_ONSET_DELAY_LIGHT * 0.6 end

    org.nausea_pending = org.nausea_pending + nauseaSpike
    org.nausea_onset_time = math.max(org.nausea_onset_time, now + delay)

    if add > 1.2 then
        org.disorientation = math.max(org.disorientation or 0, add * 0.45)
    end
    if add > 1.8 then
        org.panic = math.max(org.panic or 0, add * 0.25)
        org.needfake = true
    end
    if add > 2.5 and org.alive then
        org.shock = math.min((org.shock or 0) + add * 3, 60)
        if org.consciousness then
            org.consciousness = math.max(org.consciousness - add * 0.15, 0)
        end
    end
end

function module.HasConcussionSymptoms(org)
    return org and ((org.concussion and org.concussion > 0.4) or (org.concussion_post and org.concussion_post > POST_CONCUSSION_THRESHOLD))
end

function module.GetConcussionSeverity(org)
    if not org then return "none" end
    local c = (org.concussion or 0) + (org.concussion_post or 0) * 0.2
    if c < 0.8 then return "mild"
    elseif c < 2.0 then return "moderate"
    elseif c < 3.5 then return "severe"
    else return "critical" end
end

function module.GetStage(org)
    if not org then return 0 end
    local c = (org.concussion or 0) + (org.concussion_onset or 0) * 0.5
    if c < 0.5 then return 0
    elseif c < 1.0 then return 1
    elseif c < 2.5 then return 2
    elseif c < 4.0 then return 3
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
