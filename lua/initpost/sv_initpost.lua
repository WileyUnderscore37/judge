

--[[---------------------------------------------------------
	Name: gamemode:ScalePlayerDamage( ply, hitgroup, dmginfo )
	Desc: Scale the damage based on being shot in a hitbox
		 Return true to not take damage
-----------------------------------------------------------]]
function GAMEMODE:ScalePlayerDamage( ply, hitgroup, dmginfo )
    do return end
	-- More damage if we're shot in the head
	if ( hitgroup == HITGROUP_HEAD ) then

		dmginfo:ScaleDamage( 2 )

	end

	-- Less damage if we're shot in the arms or legs
	if ( hitgroup == HITGROUP_LEFTARM ||
		 hitgroup == HITGROUP_RIGHTARM ||
		 hitgroup == HITGROUP_LEFTLEG ||
		 hitgroup == HITGROUP_RIGHTLEG ||
		 hitgroup == HITGROUP_GEAR ) then

		dmginfo:ScaleDamage( 0.25 )

	end

end