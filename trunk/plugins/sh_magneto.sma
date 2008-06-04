// Magneto!

/* CVARS - copy and paste to shconfig.cfg

//Magneto
magneto_level 10
magneto_cooldown 45				//Time delay bewtween automatic uses
magneto_boost 125				//How much of an upward throw to give weapons
magneto_giveglock 1				//Give the poor victim a glock?

*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Magneto"
new bool:gHasMagnetoPowers[SH_MAXSLOTS+1]
new gSpriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Magneto","1.18","AssKicR / JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("magneto_level", "10" )
	register_cvar("magneto_cooldown", "45" )
	register_cvar("magneto_boost", "125" )
	register_cvar("magneto_giveglock", "1" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Metal Control", "Get players guns when they shoot you", false, "magneto_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)

	// INIT
	register_srvcmd("magneto_init", "magneto_init")
	shRegHeroInit(gHeroName, "magneto_init")

	// GET MORE GUNZ!
	register_event("ResetHUD","newRound","b")
	register_event("Damage", "magneto_damage", "b", "2!0")

	//Shield Restrict
	shSetShieldRestrict(gHeroName)

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("ambience/deadsignal1.wav")
	gSpriteLightning = precache_model("sprites/lgtning.spr")
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id] = false
}
//----------------------------------------------------------------------------------------------
public magneto_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasMagnetoPowers[id] = (hasPowers != 0)

	//Reset thier shield restrict status
	//Shield restrict MUST be before weapons are given out
	shResetShield(id)
}
//----------------------------------------------------------------------------------------------
public magneto_damage(id)
{
	if (!shModActive() || !gHasMagnetoPowers[id] || gPlayerUltimateUsed[id] || !is_user_alive(id)) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

	//Don't want to do anything with some weapons
	if (weapon == CSW_C4 || weapon == CSW_KNIFE || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG) {
		return
	}

	if ( is_user_alive(id) && id != attacker ) {
		// Start Timer
		ultimateTimer(id, get_cvar_num("magneto_cooldown") * 1.0)

		// Disarm enemy and get their gun!
		playSound(id)
		playSound(attacker)
		magneto_disarm(id,attacker)

		//Screen Flash
		new alphanum = damage * 2
		if (alphanum > 200) alphanum = 200
		else if (alphanum < 40) alphanum = 40
		setScreenFlash(attacker, 100, 100, 100, 10, alphanum )
	}
}
//----------------------------------------------------------------------------------------------
public magneto_disarm(id,victim)
{
	new Float:velocity[3]

	Entvars_Get_Vector(victim, EV_VEC_velocity, velocity)
	velocity[2] = velocity[2] + get_cvar_num("magneto_boost")

	// Give em an upwards Jolt
	Entvars_Set_Vector(victim, EV_VEC_velocity, velocity)

	new iweapons[32], inum, weapname[24]
	get_user_weapons(victim,iweapons,inum)

	for(new a = 0; a < inum; a++) {
		//Don't want to do anything with some weapons
		if (iweapons[a] == CSW_C4 || iweapons[a] == CSW_KNIFE || iweapons[a] == CSW_HEGRENADE || iweapons[a] == CSW_SMOKEGRENADE || iweapons[a] == CSW_FLASHBANG) {
			continue
		}

		get_weaponname(iweapons[a], weapname, 23)

		engclient_cmd(victim,"drop", weapname)
		shGiveWeapon(id, weapname)
	}

	new iCurrent = -1
	new Float:weapvel[3]

	while ( (iCurrent = FindEntity(iCurrent, "weaponbox")) > 0 ) {

		//Skip anything not owned by this client
		if ( Entvars_Get_Edict(iCurrent, EV_ENT_owner) != victim) continue

		Entvars_Get_Vector(iCurrent, EV_VEC_velocity, weapvel)

		//If Velocities are all Zero its on the ground already and should stay there
		if (weapvel[0] == 0.0 && weapvel[1] == 0.0 && weapvel[2] == 0.0) continue

		RemoveEntity(iCurrent)
	}

	if ( get_cvar_num("magneto_giveglock") ) {
		shGiveWeapon(victim, "weapon_glock18", true)
	}
	else {
		engclient_cmd(victim,"weapon_knife")
	}

	lightning_effect(id, victim, 10)

	client_print(victim,print_chat,"[SH] Magneto's power has removed your weapons")

}
//----------------------------------------------------------------------------------------------
public lightning_effect(id, targetid, linewidth)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 8 )
	write_short(id)	// start entity
	write_short(targetid)	// entity
	write_short(gSpriteLightning )	// model
	write_byte( 0 ) // starting frame
	write_byte( 15 )  // frame rate
	write_byte( 10 )  // life
	write_byte( linewidth )  // line width
	write_byte( 10 )  // noise amplitude
	write_byte( 255 )	// r, g, b
	write_byte( 255 )	// r, g, b
	write_byte( 255 )	// r, g, b
	write_byte( 255 )	// brightness
	write_byte( 0 )	// scroll speed
	message_end()
}
//----------------------------------------------------------------------------------------------
public playSound(id)
{
	new parm[1]
	parm[0] = id

	emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
	set_task(1.5,"stopSound", 0, parm, 1)
}
//----------------------------------------------------------------------------------------------
public stopSound(parm[])
{
	new sndStop = (1<<5)
	emit_sound(parm[0], CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------