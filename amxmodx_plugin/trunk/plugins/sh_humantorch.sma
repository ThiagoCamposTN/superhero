// HUMAN TORCH! - BASED ON FlameThrower by Ludwig

/* CVARS - copy and paste to shconfig.cfg

//Human Torch
htorch_level 0
htorch_armorcost 15		//How much amour each flame uses
htorch_numburns 5		//How many time to burn the victim
htorch_burndamage 10		//How much damage each burn does

*/

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Human Torch"
new bool:gHasHumanTorch[SH_MAXSLOTS+1]
new bool:gIsBurning[SH_MAXSLOTS+1]
new const gSoundBurning[] = "ambience/burning1.wav"
new const gSoundFlameBlast[] = "ambience/flameburst1.wav"
new const gSoundScream[] = "scientist/c1a0_sci_catscream.wav"
new gSpriteSmoke, gSpriteFire, gSpriteBurning
new pCvarArmorCost, pCvarNumBurns, pCvarBurnDamage
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Human Torch", SH_VERSION_STR, "{HOJ} Batman/JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("htorch_level", "0")
	pCvarArmorCost = register_cvar("htorch_armorcost", "15")
	pCvarNumBurns = register_cvar("htorch_numburns", "5")
	pCvarBurnDamage = register_cvar("htorch_burndamage", "10")

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Flame Blast", "Ignite your enemies on fire with a Flame Blast")
	sh_set_hero_bind(gHeroID)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteSmoke = precache_model("sprites/steam1.spr")
	gSpriteFire = precache_model("sprites/explode1.spr")
	gSpriteBurning = precache_model("sprites/xfire.spr")
	precache_sound(gSoundBurning)
	precache_sound(gSoundFlameBlast)
	precache_sound(gSoundScream)
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasHumanTorch[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gIsBurning[id] = false

	stop_fire_sound(id)
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if ( gHeroID != heroID || sh_is_freezetime() ) return
	if ( !is_user_alive(id) || !gHasHumanTorch[id] ) return

	if ( key == SH_KEYDOWN ) {
		// Ludwigs flame thrower
		if ( pev(id, pev_waterlevel) == 3 ) {
			sh_chat_message(id, gHeroID, "You cannot use the Flame Blast while underwater")
			sh_sound_deny(id)
			return
		}

		new armorCost = get_pcvar_num(pCvarArmorCost)

		if ( armorCost > 0 ) {
			new CsArmorType:armorType
			new userArmor = cs_get_user_armor(id, armorType)

			if ( userArmor < armorCost ) {
				sh_chat_message(id, gHeroID, "Flame Blasts cost %d armor point%s each", armorCost, armorCost == 1 ? "" : "s")
				sh_sound_deny(id)
				return
			}

			cs_set_user_armor(id, userArmor - armorCost, armorType)
		}

		emit_sound(id, CHAN_WEAPON, gSoundFlameBlast, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		new vec[3], aimvec[3]
		get_user_origin(id, vec)
		get_user_origin(id, aimvec, 2)

		new dist = get_distance(vec, aimvec)
		new speed = 10
		new speed1 = 160
		new speed2 = 350
		new radius = 105

		switch(dist)
		{
			case 0..49: {
				radius = 0
				speed = 5
			}
			case 50..149: {
				speed1 = speed2 = 1
				speed = 5
				radius = 50
			}
			case 150..199: {
				speed1 = speed2 = 1
				speed = 5
				radius = 90
			}
			case 200..249: {
				speed1 = speed2 = 90
				speed = 6
				radius = 90
			}
			case 250..299: {
				speed1 = speed2 = 140
				speed = 7
			}
			case 300..349: {
				speed1 = speed2 = 190
				speed = 7
			}
			case 350..399: {
				speed1 = 150
				speed2 = 240
				speed = 8
			}
			case 400..449: {
				speed1 = 150
				speed2 = 290
				speed = 8
			}
			case 450..499: {
				speed1 = 180
				speed2 = 340
				speed = 9
			}
		}

		new vecdif[3], velocityvec[3], length

		vecdif[0] = aimvec[0]-vec[0]
		vecdif[1] = aimvec[1]-vec[1]
		vecdif[2] = aimvec[2]-vec[2]

		length = sqroot(vecdif[0]*vecdif[0] + vecdif[1]*vecdif[1] + vecdif[2]*vecdif[2])

		// Make sure 0 is not returned so we don't devide by it
		if ( length == 0 ) length++

		velocityvec[0] = vecdif[0]*speed/length
		velocityvec[1] = vecdif[1]*speed/length
		velocityvec[2] = vecdif[2]*speed/length

		new args[6]
		args[0] = vec[0]
		args[1] = vec[1]
		args[2] = vec[2]
		args[3] = velocityvec[0]
		args[4] = velocityvec[1]
		args[5] = velocityvec[2]

		set_task(0.1, "te_spray", 0, args, 6, "a", 2)

		check_burnzone(id, vec, vecdif, length, speed1, speed2, radius)
	}
}
//----------------------------------------------------------------------------------------------
public te_spray(args[])
{
	// Throws a shower of sprites or models
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRAY)		// 120
	write_coord(args[0])		// start pos
	write_coord(args[1])
	write_coord(args[2])
	write_coord(args[3])		// velocity
	write_coord(args[4])
	write_coord(args[5])
	write_short(gSpriteFire)	// spr
	write_byte(8)		// count
	write_byte(70)		// speed
	write_byte(100)		// noise
	write_byte(5)		// rendermode
	message_end()
}
//----------------------------------------------------------------------------------------------
check_burnzone(id, vec[], vecdif[], length, speed1, speed2, radius)
{
	if ( !is_user_connected(id) ) return

	new tbody, tid
	get_user_aiming(id, tid, tbody, 550)

	if ( tid <= 0 || tid > sh_maxplayers() ) return

	new FFOn = sh_friendlyfire_on()
	new CsTeams:idTeam = cs_get_user_team(id)

	if ( is_user_alive(tid) ) {
		if ( FFOn ) {
			burn_victim(tid, id)
		}
		else if ( idTeam != cs_get_user_team(tid) ) {
			burn_victim(tid, id)
		}
	}

	new burnvec1[3], burnvec2[3]

	burnvec1[0] = vecdif[0]*speed1/length + vec[0]
	burnvec1[1] = vecdif[1]*speed1/length + vec[1]
	burnvec1[2] = vecdif[2]*speed1/length + vec[2]

	burnvec2[0] = vecdif[0]*speed2/length + vec[0]
	burnvec2[1] = vecdif[1]*speed2/length + vec[1]
	burnvec2[2] = vecdif[2]*speed2/length + vec[2]

	new players[SH_MAXSLOTS], origin[3]
	new playerCount, player
	get_players(players, playerCount, "a")

	for ( new i = 0; i < playerCount; i++ ) {
		player = players[i]

		if ( player != id && (idTeam != cs_get_user_team(player) || FFOn) ) {
			get_user_origin(player, origin)

			if ( get_distance(origin, burnvec1) < radius ) {
				burn_victim(player, id)
			}
			else if ( get_distance(origin, burnvec2) < radius ) {
				burn_victim(player, id)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
burn_victim(victim, attacker)
{
	if ( pev(victim, pev_waterlevel) == 3 || gIsBurning[victim] ) return

	gIsBurning[victim] = true

	emit_sound(victim, CHAN_ITEM, gSoundBurning, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	new args[2]
	args[0] = victim
	args[1] = attacker
	set_task(0.3, "on_fire", 451, args, 2, "a", get_pcvar_num(pCvarNumBurns))
	set_task(0.7, "fire_scream", victim)
	set_task(5.5, "stop_fire_sound", victim)
}
//----------------------------------------------------------------------------------------------
public on_fire(args[])
{
	new id = args[0]
	new attacker = args[1]

	if ( !is_user_alive(id) || pev(id, pev_waterlevel) == 3 ) {
		gIsBurning[id] = false
		return
	}

	if ( !gIsBurning[id] )
		return

	new rx, ry, rz, Float:forigin[3]
	rx = random_num(-30, 30)
	ry = random_num(-30, 30)
	rz = random_num(-30, 30)

	pev(id, pev_origin, forigin)

	// Additive sprite, plays 1 cycle
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)		// 17
	engfunc(EngFunc_WriteCoord, forigin[0] + rx)	// coord, coord, coord (position)
	engfunc(EngFunc_WriteCoord, forigin[1] + ry)
	engfunc(EngFunc_WriteCoord, forigin[2] + 10 + rz)
	write_short(gSpriteBurning)	// short (sprite index)
	write_byte(30)		// byte (scale in 0.1's)
	write_byte(200)		// byte (brightness)
	message_end()

	// Smoke
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SMOKE)		// 5
	engfunc(EngFunc_WriteCoord, forigin[0] + (rx*2))	// coord, coord, coord (position)
	engfunc(EngFunc_WriteCoord, forigin[1] + (ry*2))
	engfunc(EngFunc_WriteCoord, forigin[2] + 100 + (rz*2))
	write_short(gSpriteSmoke)	// short (sprite index)
	write_byte(60)		// byte (scale in 0.1's)
	write_byte(15)		// byte (framerate)
	message_end()

	sh_extra_damage(id, attacker, get_pcvar_num(pCvarBurnDamage), "flame blast", _, SH_DMG_NORM, _, false, forigin)
}
//----------------------------------------------------------------------------------------------
public fire_scream(id)
{
	emit_sound(id, CHAN_AUTO, gSoundScream, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------
public stop_fire_sound(id)
{
	gIsBurning[id] = false
	emit_sound(id, CHAN_ITEM, gSoundBurning, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasHumanTorch[id] = false
	gIsBurning[id] = false
}
//----------------------------------------------------------------------------------------------