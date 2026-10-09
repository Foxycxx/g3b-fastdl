// G3B ONE-WAV SAFE BUILD - mechanics preserved; custom WAVs deduplicated
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZP] Primary: Black Dragon Cannon"
#define VERSION "2013 G3B ZP43"
#define AUTHOR "Dias"

#define V_MODEL "models/g3bmodel/ZTHEX/g3bmodel/v_cannon.mdl"
#define P_MODEL "models/g3bmodel/p_cannon.mdl"
#define W_MODEL "models/g3bmodel/w_cannon.mdl"

#define CANNON_DAMAGE_MIN 850.0
#define CANNON_DAMAGE_MAX 1150.0
#define RADIUS 400

#define CANNON_ROUND 20
#define ZP_ITEM_COST 0

#define TIME_DRAW 0.75
#define TIME_RELOAD 3.25

#define CSW_CANNON CSW_MP5NAVY
#define weapon_cannon "weapon_mp5navy"

#define WEAPON_EVENT "events/mp5n.sc"
#define WEAPON_W_MODEL "models/w_mp5.mdl"
#define WEAPON_ANIMEXT "carbine"
#define WEAPON_SECRET_CODE 5786

#define CANNONFIRE_CLASSNAME "cannon"

// Fire Start
#define WEAPON_ATTACH_F 30.0
#define WEAPON_ATTACH_R 10.0
#define WEAPON_ATTACH_U -5.0

new const WeaponSounds[3][] =
{
	"g3bsound/cannon-1.wav",
	"g3bsound/cannon-2.wav",
	"g3bsound/cannon-2.wav"
}

new const WeaponResources[1][] =
{
	"sprites/g3bsprite/fire_cannon.spr"
}

enum
{
	CANNON_ANIM_IDLE = 0,
	CANNON_ANIM_SHOOT1,
	CANNON_ANIM_SHOOT2,
	CANNON_ANIM_DRAW
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Cannon
new g_Had_Cannon, g_InTempingAttack
new g_OldWeapon[33], g_CannonRound[33], Float:g_LastAttack[33], Float:g_NextTime[33]
new g_SmokePuff_SprId, g_MsgCurWeapon, g_MsgAmmoX, g_MsgWeaponList
new g_PlayerConnected[33]

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

public plugin_natives()
{
	register_native("get_dragoncannon", "native_get_dragoncannon", 1)
	register_native("jumlah_cannon", "native_jumlah_cannon", 1)
	register_native("refill_dragoncannon", "native_refill_dragoncannon", 1)
    register_native("refill_dragoncannon_extra", "native_refill_dragoncannon_extra", 1)
}

public native_get_dragoncannon(id)
{
	if(id < 1 || id > 32 || !is_user_connected(id))
		return 0

	Get_Cannon(id)
	return 1
}

public native_jumlah_cannon()
{
	new count = 0
	for(new id = 1; id <= 32; id++)
	{
		if(is_user_connected(id) && Get_BitVar(g_Had_Cannon, id))
			count++
	}
	return count
}

public native_refill_dragoncannon_extra(id)
{
 if(!is_user_alive(id)||!Get_BitVar(g_Had_Cannon,id))return 0;
 g_CannonRound[id]=max(g_CannonRound[id],30);
 if(get_user_weapon(id)==CSW_CANNON)update_ammo(id,-1,g_CannonRound[id]);
 return 1;
}
public native_refill_dragoncannon(id)
{
	if(id < 1 || id > 32 || !is_user_connected(id))
		return 0

	if(!Get_BitVar(g_Had_Cannon, id))
		return 0

	g_CannonRound[id] = max(g_CannonRound[id], CANNON_ROUND)
	if(get_user_weapon(id)==CSW_CANNON) update_ammo(id, -1, g_CannonRound[id])

	return 1
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_think(CANNONFIRE_CLASSNAME, "fw_Cannon_Think")
	register_touch(CANNONFIRE_CLASSNAME, "*", "fw_Cannon_Touch")	
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_cannon, "fw_Item_AddToPlayer_Post", 1)
	
	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgAmmoX = get_user_msgid("AmmoX")
	g_MsgWeaponList = get_user_msgid("WeaponList")
	
	register_clcmd("weapon_cannon", "HookWeapon")
	g_Cannon = zp_register_extra_item("Black Dragon Cannon", ZP_ITEM_COST, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
    precache_generic("sound/weapons/cannon_draw.wav");

	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	new i
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i = 0; i < sizeof(WeaponResources); i++)
		engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/smokepuff.spr")
	//g_Cannon = zbheroex_register_weapon("Cannon", WEAPON_PRIMARY, CSW_CANNON, 13999)
}

public client_putinserver(id) g_PlayerConnected[id] = 1
public client_disconnect(id)
{
	g_PlayerConnected[id] = 0
	Remove_Cannon(id)
}

public zp_round_started(gamemode, id)
{
	remove_entity_name(CANNONFIRE_CLASSNAME)
}

public zp_round_ended(winteam)
{
	remove_entity_name(CANNONFIRE_CLASSNAME)
}

public zp_extra_item_selected(id, ItemID)
{
	if(ItemID != g_Cannon)
		return

	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return

	Get_Cannon(id)
}

public zp_user_infected_post(id, attacker)
{
	Remove_Cannon(id)
}

public zp_user_humanized_post(id)
{
	Remove_Cannon(id)
}

public Get_Cannon(id)
{
	Set_BitVar(g_Had_Cannon, id)
	UnSet_BitVar(g_InTempingAttack, id)
	g_CannonRound[id] = CANNON_ROUND
	
	fm_give_item(id, weapon_cannon)
	update_ammo(id, -1, CANNON_ROUND)
	
	g_NextTime[id] = 0.0
}

public Remove_Cannon(id)
{
	UnSet_BitVar(g_Had_Cannon, id)
	UnSet_BitVar(g_InTempingAttack, id)
	g_CannonRound[id] = 0
}

public HookWeapon(id)
{
	engclient_cmd(id, weapon_cannon)
	return PLUGIN_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	static CSWID; CSWID = read_data(2)
	if((CSWID == CSW_CANNON && g_OldWeapon[id] != CSW_CANNON) && Get_BitVar(g_Had_Cannon, id))
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		set_weapon_anim(id, CANNON_ANIM_DRAW)
		set_pdata_float(id, 83, TIME_DRAW, 5)
		
		set_pdata_string(id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)
		update_ammo(id, -1, g_CannonRound[id])
	} else if((CSWID == CSW_CANNON && g_OldWeapon[id] == CSW_CANNON) && Get_BitVar(g_Had_Cannon, id)) {
        set_pev(id,pev_viewmodel2,V_MODEL)
        set_pev(id,pev_weaponmodel2,P_MODEL)
		update_ammo(id, -1, g_CannonRound[id])
	}
	
	g_OldWeapon[id] = CSWID
}


public fw_Cannon_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame, Float:fNextThink, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	static iMoveType; iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.0015
		fFrame += random_float(0.25, 0.75)
		fScale += 0.01
		
		if(fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	} else {
		fNextThink = 0.045
		
		fFrame += random_float(0.5, 1.0)
		fScale += 0.001
		
		fFrame = floatmin(21.0, fFrame)
		fScale = floatmin(2.0, fFrame)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if(get_gametime() >= fTimeRemove)
	{
		static Float:Amount; pev(iEnt, pev_renderamt, Amount)
		if(Amount <= 5.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		} else {
			Amount -= 5.0
			set_pev(iEnt, pev_renderamt, Amount)
		}
	}
}

public fw_Cannon_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	if(pev_valid(id))
	{
		static Classname[32]
		pev(id, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, CANNONFIRE_CLASSNAME)) return
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}

public fw_AddToFullPack_Post(State, E, Ent, Host, HostFlag, Player, PSet)
{
	if(!pev_valid(Ent) || Host <= 0 || Host >= 33 || !g_PlayerConnected[Host])
		return FMRES_IGNORED
	
	static Classname[32]; pev(Ent, pev_classname, Classname, sizeof(Classname))
	if(!equal(Classname, CANNONFIRE_CLASSNAME))
		return FMRES_IGNORED
	
	if(!pev(Ent, pev_iuser4) && pev(Ent, pev_owner) != Host) set_es(State, ES_RenderAmt, 0.0)
	
	return FMRES_IGNORED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_CANNON || !Get_BitVar(g_Had_Cannon, id))
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_CANNON || !Get_BitVar(g_Had_Cannon, id))
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		HandleShoot_Cannon(id)
	}
	
	Check_CannonTime(id)
	
	return FMRES_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, WEAPON_W_MODEL))
	{
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_cannon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(Get_BitVar(g_Had_Cannon, id))
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRET_CODE)
			set_pev(weapon, pev_iuser1, g_CannonRound[id])
			
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			Remove_Cannon(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w')  return FMRES_SUPERCEDE
			else  return FMRES_SUPERCEDE
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRET_CODE)
	{
		Remove_Cannon(id)
		
		Set_BitVar(g_Had_Cannon, id)
		// Restore remaining charges from dropped weapon.
		g_CannonRound[id] = max(0,pev(ent,pev_iuser1))
	}
	
	// Stock MP5 HUD/WeaponList retained: saves weapon_cannon.txt + 2 HUD sprites.
return HAM_HANDLED	
}

public HandleShoot_Cannon(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(g_CannonRound[id] <= 0)
		return
	if(get_gametime() - TIME_RELOAD <= g_LastAttack[id])
	{
		set_player_nextattack(id, g_LastAttack[id] - get_gametime())
		return
	}
		
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_CANNON)
	if(!pev_valid(Ent)) return		
	
	g_CannonRound[id]--;
	Create_FakeAttack(id)
	
	set_weapon_anim(id, random_num(CANNON_ANIM_SHOOT1, CANNON_ANIM_SHOOT2))
	PlaySound(id, WeaponSounds[1])
	//emit_sound(id, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	Create_CannonFire(id, 0)

	set_player_nextattack(id, TIME_RELOAD)
	set_weapons_timeidle(id, CSW_CANNON, TIME_RELOAD)
	
	g_LastAttack[id] = get_gametime()
	g_NextTime[id] = get_gametime()
}

public Check_CannonTime(id)
{
	if(g_NextTime[id] == 0.0)
		return
	
	if(get_gametime() - 0.1 > g_NextTime[id])
	{
		//if(zbheroex_get_user_zombie(id))
		//	return
		
		// Finite charges.
		update_ammo(id, -1, g_CannonRound[id])
		
		emit_sound(id, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		Make_FireSmoke(id)
		Remove_OldCannon(id)
		Create_CannonFire(id, 1)
		
		Make_Push(id)
		Check_RadiusDamage(id)
		
		// Stop
		g_NextTime[id] = 0.0
	}
}

public Remove_OldCannon(id)
{
	if(!is_user_alive(id))
		return
		
	static Classname[32]
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
			
		pev(i, pev_classname, Classname, sizeof(Classname))
		if(!equal(Classname, CANNONFIRE_CLASSNAME))
			continue
		if(pev(i, pev_owner) != id)
			continue
			
		engfunc(EngFunc_RemoveEntity, i)
	}
}

public Create_CannonFire(id, OffSet)
{
	const MAX_FIRE = 12
	static Float:StartOrigin[3], Float:TargetOrigin[MAX_FIRE][3], Float:Speed[MAX_FIRE]

	// Get Target
	
	// -- Left
	get_position(id, 100.0, random_float(-10.0, -40.0), WEAPON_ATTACH_U, TargetOrigin[0]); Speed[0] = 150.0
	get_position(id, 100.0, random_float(-10.0, -40.0), WEAPON_ATTACH_U, TargetOrigin[1]); Speed[1] = 180.0
	get_position(id, 100.0,	random_float(-10.0, -40.0), WEAPON_ATTACH_U, TargetOrigin[2]); Speed[2] = 210.0
	get_position(id, 100.0, random_float(-10.0, -30.0), WEAPON_ATTACH_U + random_float(-5.0, -10.0), TargetOrigin[3]); Speed[3] = 240.0
	get_position(id, 100.0, random_float(-10.0, -20.0), WEAPON_ATTACH_U + random_float(-5.0, -10.0), TargetOrigin[4]); Speed[4] = 300.0

	// -- Center
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U - random_float(10.0, 20.0), TargetOrigin[5]); Speed[5] = 200.0
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U + random_float(10.0, 20.0), TargetOrigin[6]); Speed[6] = 200.0
	
	// -- Right
	get_position(id, 100.0, random_float(10.0, 20.0), WEAPON_ATTACH_U + random_float(5.0, 10.0), TargetOrigin[7]); Speed[7] = 150.0
	get_position(id, 100.0, random_float(10.0, 30.0) , WEAPON_ATTACH_U + random_float(5.0, 10.0), TargetOrigin[8]); Speed[8] = 180.0
	get_position(id, 100.0,	random_float(10.0, 40.0), WEAPON_ATTACH_U, TargetOrigin[9]); Speed[9] = 210.0
	get_position(id, 100.0, random_float(10.0, 40.0), WEAPON_ATTACH_U, TargetOrigin[10]); Speed[10] = 240.0
	get_position(id, 100.0, random_float(10.0, 40.0), WEAPON_ATTACH_U, TargetOrigin[11]); Speed[11] = 300.0

	for(new i = 0; i < MAX_FIRE; i++)
	{
		// Get Start
		get_position(id, random_float(30.0, 40.0), 0.0, WEAPON_ATTACH_U, StartOrigin)
		Create_Fire(id, StartOrigin, TargetOrigin[i], Speed[i], OffSet)
	}
}

public Create_Fire(id, Float:Origin[3], Float:TargetOrigin[3], Float:Speed, Offset)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	static Float:Velocity[3]

	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 75.0)
	set_pev(Ent, pev_fuser1, get_gametime() + 0.75)	// time remove
	set_pev(Ent, pev_scale, random_float(0.25, 0.75))
	set_pev(Ent, pev_nextthink, halflife_time() + 0.05)
	
	entity_set_string(Ent, EV_SZ_classname, CANNONFIRE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[0])
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_iuser4, Offset)
	
	get_speed_vector(Origin, TargetOrigin, Speed, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
}

public Make_FireSmoke(id)
{
	static Float:Origin[3]
	get_position(id, WEAPON_ATTACH_F, WEAPON_ATTACH_R, WEAPON_ATTACH_U, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_EXPLOSION) 
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 5.0)
	write_short(g_SmokePuff_SprId)
	write_byte(10)
	write_byte(15)
	write_byte(14)
	message_end()
}

public Check_RadiusDamage(id)
{
	static Float:Origin[3], Float:MyOrigin[3], Float:Speed, Float:DamageMulti, Float:DmgMulti
	pev(id, pev_origin, MyOrigin)
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		pev(i, pev_origin, Origin)
		if(!is_in_viewcone(id, Origin, 1))
			continue
		if(entity_range(id, i) > float(RADIUS))
			continue
			
		DmgMulti = 1.1;
		DamageMulti = entity_range(id, i) / float(RADIUS)
		DmgMulti -= DamageMulti
		
		// G3B balanced cannon damage: strong but capped below 1200.
		static Float:CannonDamage
		CannonDamage = random_float(CANNON_DAMAGE_MIN, CANNON_DAMAGE_MAX)
		do_attack(id, i, 0, CannonDamage)
		
		if(cs_get_user_team(id) != cs_get_user_team(i))
		{
			Speed = float(RADIUS) - entity_range(id, i)
			hook_ent2(i, MyOrigin, Speed, 7.0 * DmgMulti , 2)
		}
	}
}

public Create_FakeAttack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_InTempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
	
	// Set Real Attack Anim
	static iAnimDesired,  szAnimation[64]

	formatex(szAnimation, charsmax(szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMEXT)
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0
	
	set_pev(id, pev_sequence, iAnimDesired)
	UnSet_BitVar(g_InTempingAttack, id)
}

public Make_Push(id)
{
	static Float:VirtualVec[3]
	VirtualVec[0] = random_float(-5.0, -10.0)
	VirtualVec[1] = random_float(1.0, -1.0)
	VirtualVec[2] = 0.0	
	
	set_pev(id, pev_punchangle, VirtualVec)		
}

public update_ammo(id, Ammo, BpAmmo)
{
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_CANNON)
	write_byte(Ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgAmmoX, _, id)
	write_byte(10)
	write_byte(BpAmmo)
	message_end()
	
	cs_set_user_bpammo(id, CSW_CANNON, BpAmmo)
}

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	static Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	static Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	static iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	static ptr; ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	static pHit; pHit = get_tr2(ptr, TR_pHit)
	static iHitgroup; iHitgroup = get_tr2(ptr, TR_iHitgroup)
	static Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	static iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		static Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		static iAngleToVictim; iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		static Float:fDis; fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		static Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			static ptr2; ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			static pHit2; pHit2 = get_tr2(ptr2, TR_pHit)
			static iHitgroup2; iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			static ptr3; ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)

	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	static Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	static Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	static iResult; iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		static Float:fTan; fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		static fAngleToTargetSize; fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	static Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	static iResult; iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	static Float:fl_Time2; fl_Time2 = distance_f / (speed * multi)
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

