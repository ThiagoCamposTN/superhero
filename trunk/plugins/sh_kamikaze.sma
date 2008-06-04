// Kamikaze! - Credits AssKicR & Scarzzurs/The_Unbound & {HOJ} Batman

/* CVARS - copy and paste to shconfig.cfg

//Kamikaze
kamikaze_level 0
kamikaze_radius 300				//Radius of people affected by blast
kamikaze_fuse 15				//# of seconds before kamikaze blows Up
kamikaze_maxdamage 125			//Maximum damage to deal to a player

*/

#include <amxmod>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Kamikaze"
new bool:gHasKamikazePower[SH_MAXSLOTS+1]
new smoke, white, fire
new IsKamikaze[33]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Kamikaze","1.18","AssKicR/JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("kamikaze_level", "0" )
	register_cvar("kamikaze_radius", "300" )
	register_cvar("kamikaze_fuse", "15" )
	register_cvar("kamikaze_maxdamage", "125" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Kamikaze", "Blow up the enemies with a Kamikazi attack", true, "kamikaze_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")
	register_event("DeathMsg","death","a")

	// KEY DOWN
	register_srvcmd("kamikaze_kd", "kamikaze_kd")
	shRegKeyDown(gHeroName, "kamikaze_kd")

	// INIT
	register_srvcmd("kamikaze_init", "kamikaze_init")
	shRegHeroInit(gHeroName, "kamikaze_init")

	set_task(1.0,"kamikaze_timer",0,"",0,"b") //forever loop
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	smoke = precache_model("sprites/steam1.spr")
	white = precache_model("sprites/white.spr")
	fire = precache_model("sprites/explode1.spr")
	precache_sound( "buttons/blip2.wav")
}
//----------------------------------------------------------------------------------------------
public kamikaze_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has kamikaze powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	gHasKamikazePower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public explode( vec1[3] )
{
	// blast circles
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 21 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 2 ) // life 2
	write_byte( 20 ) // width 16
	write_byte( 0 ) // noise
	write_byte( 188 ) // r
	write_byte( 220 ) // g
	write_byte( 255 ) // b
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()

	//Explosion2
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 12 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte( 188 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	message_end()

	//TE_Explosion
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 3 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( fire )
	write_byte( 60 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	write_byte( 0 ) // byte flags
	message_end()

	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 5 ) // 5
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( smoke )
	write_byte( 10 )  // 2
	write_byte( 10 )  // 10
	message_end()

}
//----------------------------------------------------------------------------------------------
public death()
{
	new id = read_data(2)
	if ( IsKamikaze[id] > 0 ) BlowUp(id)
}
//----------------------------------------------------------------------------------------------
public Kamikaze_check(id)
{
	emit_sound(id,CHAN_ITEM, "buttons/blip2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	IsKamikaze[id] -= 1

	if (IsKamikaze[id] <= 0 ) {
		BlowUp(id)
	}
	else {
		// Decrement the counter
		set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, 85)
		show_hudmessage(id,"You will explode in %d seconds.",IsKamikaze[id])

		// Say Time Remaining to the User Only.
		if ( IsKamikaze[id] == 11 ) client_cmd(id,"spk ^"fvox/remaining^"")
		if ( IsKamikaze[id] < 11 ) {
			new temp[48]
			num_to_word(IsKamikaze[id],temp,47)
			client_cmd(id,"spk ^"fvox/%s^"",temp)
		}
	}
}
//----------------------------------------------------------------------------------------------
public kamikaze_timer()
{
	for(new id = 1; id <= SH_MAXSLOTS; id++)  {
		if (IsKamikaze[id] > 0) Kamikaze_check(id)
	}
}
//----------------------------------------------------------------------------------------------
public BlowUp(id)
{
	new Float:dRatio, damage, distanceBetween
	new damradius = get_cvar_num("kamikaze_radius")
	new maxdamage = get_cvar_num("kamikaze_maxdamage")
	IsKamikaze[id] = 0

	new name[32]
	get_user_name(id,name,31)
	shUnglow(id)
	set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, 85)
	show_hudmessage(0,"%s has exploded.",name)
	new FFOn = get_cvar_num("mp_friendlyfire")
	new origin[3], origin1[3]
	get_user_origin(id,origin)

	explode(origin) // blowup even if dead

	for(new a = 1; a <= SH_MAXSLOTS; a++) {
		if( is_user_alive(a) && ( get_user_team(id) != get_user_team(a) || FFOn || a == id ) ) {

			get_user_origin(a,origin1)

			distanceBetween = get_distance(origin, origin1 )
			if( distanceBetween < damradius ) {
				if ( a == id ) {
					damage = maxdamage * 4
				}
				else {
					dRatio = float(distanceBetween) / float(damradius)
					damage = maxdamage - floatround( maxdamage * dRatio)
				}
				shExtraDamage(a, id, damage, "Kamikaze Bomber")
			} // distance
		} // alive
	} // loop
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id] = false
	IsKamikaze[id] = 0
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public kamikaze_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id with kamikaze Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)
	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	// Let them know they already used their ultimate if they have
	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	gPlayerUltimateUsed[id] = true
	IsKamikaze[id] = get_cvar_num("kamikaze_fuse")
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasKamikazePower[id] = false
	IsKamikaze[id] = 0
}
//----------------------------------------------------------------------------------------------
public client_disconnect(id)
{
	gHasKamikazePower[id] = false
	IsKamikaze[id] = 0
}
//----------------------------------------------------------------------------------------------