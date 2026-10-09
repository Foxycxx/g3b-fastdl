native Float:exhero_knife_range();
native exhero_damage(victim,inflictor,attacker,Float:damage,bits,const ability[]);
/******************************************
	Holy Sword Divine Crusader Update

Changelog :

1. ver 0.5 Initial Release (WIP)
2. ver 1.0 Free Release
3. ver 1.5 Optimized some code
4. ver 2.0 Final (Maybe XD)
******************************************/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombieplague>

#define PLUGIN "Holy Sword Divine Crusader"
#define VERSION "2.0"
#define AUTHOR "Mellowzy"

#define CSW_HOLY CSW_KNIFE
#define knife_holysword "weapon_knife"

//Weapon Model
#define P_MODEL "models/exhero_holy_compat26/p_holysword.mdl"
#define P_MODEL_FULLSTACK "models/exhero_holy_compat26/p_holysword_fullstack.mdl"
#define V_MODEL "models/g3bmodel/ZTHEX/exhero_holy_compat26/v_holysword.mdl"


#define CHARGE_CANNON "models/ef_holysword_chargecannon.mdl"
#define PARRYATTACK "models/ef_holysword_parryattack.mdl"
#define PARRYATTACK2 "models/ef_holysword_parryattack2.mdl"

#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2


#define MOUSE01					IN_ATTACK
#define MOUSE02					IN_ATTACK2

#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)
#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsObserver(%0) pev(%0,pev_iuser1)
#define OBS_IN_EYE 4

#define DMG_01 (DMG_FALL | DMG_BURN | DMG_SONIC | DMG_POISON | DMG_BLAST | DMG_ENERGYBEAM | DMG_GRENADE | DMG_SHOCK | DMG_SLASH| DMG_SLOWBURN | DMG_CLUB)
#define DMG_02 (DMG_ACID | DMG_NEVERGIB | DMG_GENERIC | DMG_MORTAR | DMG_FREEZE | DMG_CRUSH | DMG_BULLET)
#define ALL_DAMAGES (DMG_01 | DMG_02)

// OFFSET
const PDATA_SAFE 		= 2
const OFFSET_LINUX_WEAPONS 	= 4
const m_szAnimExtention 	= 492
const m_pPlayer			= 41
const m_iId			= 43
const m_flNextAttack		= 83
const m_flTimeWeaponIdle	= 48
const m_flNextPrimaryAttack	= 46
const m_flNextSecondaryAttack	= 47
const m_imode 			= 17
const m_delayattack 		= 18
new const Float:AttackDamage_Mul[3] =  { 1.0, 1.5, 2.0 }
	
new const holysword_sound[][] =
{
	"weapons/holysword_cannon.wav",
	"weapons/holysword_cannon_exp.wav",
	"weapons/holysword_charge_loop.wav",
	"weapons/holysword_charge_slash.wav",
	"weapons/holysword_charge_start.wav",
	"weapons/holysword_draw.wav",
	"weapons/holysword_paring.wav",
	"weapons/holysword_paring_slash.wav",
	"weapons/holysword_parryattack.wav",
	"weapons/holysword_slash_change.wav",
	"weapons/holysword_slash1.wav",
	"weapons/holysword_slash2.wav",
	"weapons/holysword_slash3.wav",
	"weapons/holysword_stack_idle.wav",
	"weapons/combatknife_wall.wav",
	"weapons/tomahawk_slash1_hit.wav"
}
new const holysword_hud[][] =
{
	"sprites/640hud43.spr",
	"sprites/640hud181.spr",
	"sprites/muzzleflash65.spr",
	"sprites/muzzleflash78.spr",
	"sprites/knife_holysword.txt"
}
new const holysword_special_spr[][]= {
	"sprites/ef_holysword_charge.spr",
	"sprites/ef_holysword_stack1.spr",
	"sprites/ef_holysword_stack2.spr",
	"sprites/ef_holysword_stack3.spr",
	"sprites/ef_holysword_stack4.spr"
}
//new g_hsword
new g_Had_HolySword[33], g_Exp_SprId, Slash[33], iStack[33], Check[33], gethit[33], exp2, IsDef[33]
new cvar_damagea_normal, cvar_damagea_fullstack, cvar_damage_paring, cvar_damage_exp, cvar_kb, cvar_radius_damage
new g_spr[33], g_spr2[33]
new Float:g_NextHoly[33],Float:g_ChargeHoly[33],Float:g_ParryUntil[33],g_HolyCombo[33],bool:g_ChargingHoly[33];

new g_HolyBloodSpr,g_HolyBloodDrop;
new Float:g_HolyParryNotice[33];
new g_HolyChargeHud, bool:g_HolyHudVisible[33];

public plugin_init() {
 g_HolyChargeHud=CreateHudSyncObj();
 set_task(0.2,"ExHero_HolyChargeHud",0,"",0,"b");
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "EventWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_forward(FM_CmdStart, "HolySword_Config")
	register_forward(FM_ClientCommand , "Fw_ClientCommand")
	RegisterHam(Ham_Item_Deploy, knife_holysword, "fw_WeaponDraw", 1)
 RegisterHam(Ham_Item_Holster,knife_holysword,"ExHero_HolyHolster",1)
 RegisterHam(Ham_Weapon_PrimaryAttack,knife_holysword,"ExHero_HolyBlock")
 RegisterHam(Ham_Weapon_SecondaryAttack,knife_holysword,"ExHero_HolyBlock")
 register_forward(FM_UpdateClientData,"ExHero_HolyClientData",1)
	RegisterHam(Ham_Weapon_WeaponIdle, knife_holysword, "fw_WeaponIdle", 1)
	
	RegisterHam(Ham_Spawn, "player", "remove_holysword", 1)
	RegisterHam(Ham_Killed, "player", "remove_holysword", 1)
	RegisterHam(Ham_TakeDamage, "player", "HamGetTakeDamage")
 RegisterHam(Ham_Killed,"player","AuditHolyKilled",1)
 RegisterHam(Ham_TraceAttack,"player","ExHero_HolyTraceAttack");
	
	register_think("holysword", "fw_ThinkHolySwordFx")
	register_think("mf_hsword", "fw_Muzzle_Think")
	register_think("mf_hsword2", "fw_Muzzle2_Think")
	
	register_think("holy_chargecannon", "Holy_Chargecannon_Think")
	register_touch("holy_chargecannon", "*", "Holy_Chargecannon_Touch")
	
	cvar_damagea_normal = register_cvar("Holy_Damage_Normal", "96.0")
	cvar_damagea_fullstack = register_cvar("Holy_Damage_Fullstack", "245.0")
	cvar_damage_paring = register_cvar("Holy_Damage_Paring", "180.0")
	cvar_damage_exp = register_cvar("Holy_Damage_Exp", "160.0")
	cvar_kb = register_cvar("Holy_KnockBack", "60.0")
	cvar_radius_damage = register_cvar("Holy_RadiusDamage", "250.0")
	
	// Granted by ExHero loadout
	register_clcmd("knife_holysword", "weapon_hook")
}

public plugin_precache()
{
    precache_generic("sound/weapons/holysword_charge_loop.wav");
    precache_generic("sound/weapons/holysword_charge_start.wav");
    precache_generic("sound/weapons/holysword_draw.wav");
    precache_generic("sound/weapons/holysword_paring.wav");
    precache_generic("sound/weapons/holysword_slash_change.wav");
    precache_generic("sound/weapons/holysword_stack_idle.wav");

 g_HolyBloodSpr=precache_model("sprites/bloodspray.spr");
 g_HolyBloodDrop=precache_model("sprites/blood.spr");
	precache_model(P_MODEL)
	precache_model(P_MODEL_FULLSTACK)
	precache_model(V_MODEL)
	
	precache_model(CHARGE_CANNON)
	precache_model(PARRYATTACK)
	precache_model(PARRYATTACK2)
	
	for(new i = 0; i <sizeof(holysword_sound); i++)
		precache_sound(holysword_sound[i])
	for(new i = 0; i <sizeof(holysword_hud); i++)
		if(i == 4)precache_generic(holysword_hud[i])
			else precache_model(holysword_hud[i])
	for(new i = 0; i <sizeof(holysword_special_spr); i++)
		precache_model(holysword_special_spr[i])
		
	g_Exp_SprId = precache_model(holysword_hud[2])
	//g_hsword = zp_register_extra_item("Holy Sword Divine Order", 30, ZP_TEAM_HUMAN)
	exp2 = precache_model(holysword_hud[3])
	
}
public client_connect(id)remove_holysword(id)
public client_disconnected(id)remove_holysword(id)	
public get_holysword(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id)) return
	g_Had_HolySword[id] = 1
	Slash[id] = 0
	iStack[id] = 0
	Check[id] = 0
	gethit[id] = 0
	IsDef[id] = 0
	if(!user_has_weapon(id, CSW_KNIFE)) fm_give_item(id, knife_holysword)
	ExHero_RemoveEffects(id,"mf_hsword")
	g_spr[id] = 0
	ExHero_RemoveEffects(id,"mf_hsword2")
	g_spr2[id] = 0
	
	if(get_user_weapon(id) == CSW_HOLY)EventWeapon(id)
	else engclient_cmd(id, knife_holysword)
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_HOLY)
	if(!pev_valid(ent))return
	
	set_pdata_float(ent, 48, 1.5, 4)
	set_weapon_anim(id, 1)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_Had_HolySword[id]? "knife_holysword" : "weapon_knife")
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_HOLY)
	write_byte(0)
	message_end()
	
	ExHero_RemoveEffects(id, "mf_hsword")
	ExHero_RemoveEffects(id, "mf_hsword2")

}
/*public zp_extra_item_selected(id, itemid) if (itemid == g_hsword) get_holysword(id)
public zp_user_infected_post(id) remove_holysword(id)*/
public weapon_hook(id)
{
	engclient_cmd(id, knife_holysword)
	return PLUGIN_HANDLED
}
public remove_holysword(id)
{
 if(id<1 || id>32) return;
 g_HolyParryNotice[id]=0.0;g_NextHoly[id]=0.0;g_ChargeHoly[id]=0.0;g_ParryUntil[id]=0.0;g_ChargingHoly[id]=false;g_HolyCombo[id]=0; IsDef[id]=0; Slash[id]=0; iStack[id]=0; Check[id]=0; gethit[id]=0;
	ExHero_RemoveEffects(id, "holy_chargecannon");
 ExHero_RemoveEffects(id, "holysword");
 ExHero_RemoveEffects(id, "mf_hsword2");
 g_Had_HolySword[id] = 0
	ExHero_RemoveEffects(id,"mf_hsword")
	g_spr[id] = 0
	ExHero_RemoveEffects(id,"mf_hsword2")
	g_spr2[id] = 0
	
	ExHero_RemoveEffects(id, "mf_hsword")
}
public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new killer=get_msg_arg_int(1);
 if(killer<1 || killer>32 || !is_user_connected(killer)) return PLUGIN_CONTINUE;
 new iEntity = get_pdata_cbase(killer, 373)
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_HOLY || !g_Had_HolySword[get_msg_arg_int(1)])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "holysword")
	return PLUGIN_CONTINUE
}
// Knife TraceAttack runs before the ZP TakeDamage armor/infection path.
public ExHero_HolyTraceAttack(victim,attacker,Float:damage,Float:direction[3],trace,bits)
{
 if(attacker<1 || attacker>32 || !is_user_alive(attacker) || get_user_weapon(attacker)!=CSW_KNIFE)return HAM_IGNORED;
 return ExHero_HolyTryParry(victim,attacker)?HAM_SUPERCEDE:HAM_IGNORED;
}
public HamGetTakeDamage(victim,inflictor,attacker,Float:damage,bits)
{
 return ExHero_HolyTryParry(victim,attacker)?HAM_SUPERCEDE:HAM_IGNORED;
}
stock bool:ExHero_HolyTryParry(id,attacker)
{
 if(!ExHero_HolyOwner(id) || get_user_weapon(id)!=CSW_KNIFE || IsDef[id]!=1 || get_gametime()>g_ParryUntil[id])return false;
 if(attacker<1 || attacker>32 || !is_user_alive(attacker) || !zp_get_user_zombie(attacker))return false;
 IsDef[id]=0;g_HolyParryNotice[id]=get_gametime()+0.9;
 new ent=fm_get_user_weapon_entity(id,CSW_KNIFE);
 if(pev_valid(ent)==2)set_pdata_float(ent,48,0.90,4);
 g_NextHoly[id]=get_gametime()+0.90;
 set_weapon_anim(id,Check[id]?23:11);
 emit_sound(id, CHAN_WEAPON, holysword_sound[8], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
 holysword_effect(id); // Original successful-parry explosion/shields.
 ExHero_HolyHit(id,get_pcvar_float(cvar_damage_paring),"Holy Sword: contraataque");
 return true;
}
public Fw_ClientCommand(id) /*AsdianDx*/
{
	new sCmd[32]
	read_argv(0,sCmd,31)
	
	if(equal(sCmd,"lastinv") || equal(sCmd,"weapon_",7))
		if(IsDef[id]) return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}
public EventWeapon(id)
{
	if(!IsAlive(id)) return
	if(get_user_weapon(id) != CSW_HOLY || !g_Had_HolySword[id])
	{
		ExHero_RemoveEffects(id, "mf_hsword")
		if(iStack[id])ExHero_RemoveEffects(id, "mf_hsword2")
		return
	} else {
		ExHero_RemoveEffects(id, "mf_hsword")
		if(iStack[id])Stock_Muzzle2(id, iStack[id])
	}
	
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, !Check[id]?P_MODEL : P_MODEL_FULLSTACK)
}
public fw_WeaponDraw(ent){
 if(pev_valid(ent)!=2)return;
 new id=get_pdata_cbase(ent,41,4);if(!ExHero_HolyOwner(id))return;
 g_ChargingHoly[id]=false;IsDef[id]=0;g_ParryUntil[id]=0.0;
 set_pev(id,pev_viewmodel2,V_MODEL);set_pev(id,pev_weaponmodel2,Check[id]?P_MODEL_FULLSTACK:P_MODEL);
 set_pdata_string(id,m_szAnimExtention*4,"knife",-1,20);
 set_weapon_anim(id,Check[id]?14:1);g_NextHoly[id]=get_gametime()+1.03;
 set_pdata_float(ent,48,1.03,4);set_pdata_float(id,83,1.03,5);
}
public fw_WeaponIdle(ent){
 if(pev_valid(ent)!=2)return HAM_IGNORED;
 new id=get_pdata_cbase(ent,41,4);if(!ExHero_HolyOwner(id))return HAM_IGNORED;
 if(get_pdata_float(ent,48,4)<=0.0 && !g_ChargingHoly[id]){set_weapon_anim(id,Check[id]?13:0);set_pdata_float(ent,48,8.0,4);}
 return HAM_SUPERCEDE;
}
public HolySword_Config(id,uc,seed){
 if(!ExHero_HolyOwner(id) || get_user_weapon(id)!=CSW_KNIFE)return FMRES_IGNORED;
 new buttons=get_uc(uc,UC_Buttons);set_uc(uc,UC_Buttons,buttons & ~(IN_ATTACK|IN_ATTACK2));return ExHero_HolyInput(id,buttons);
}
public ExHero_HolyInput(id,buttons){
 if(!ExHero_HolyOwner(id) || get_user_weapon(id)!=CSW_KNIFE)return FMRES_IGNORED;
 new ent=fm_get_user_weapon_entity(id,CSW_KNIFE);
 if(pev_valid(ent)!=2)return FMRES_IGNORED;
 new Float:now=get_gametime();
 if(IsDef[id] && now>=g_ParryUntil[id])IsDef[id]=0;
 if(g_ChargingHoly[id] && (buttons & IN_ATTACK2)){g_ChargingHoly[id]=false;Slash[id]=0;}
 if(g_ChargingHoly[id]){
  if(!(buttons & IN_ATTACK)){
   g_ChargingHoly[id]=false;
   if(now-g_ChargeHoly[id]>=0.7){
    set_weapon_anim(id,Check[id]?20:8);emit_sound(id, CHAN_WEAPON, holysword_sound[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);Holy_Chargecannon(id);ExHero_HolyHit(id,160.0,"Holy Sword: corte cargado");
    Check[id]=0;iStack[id]=0;ExHero_RemoveEffects(id,"mf_hsword2");set_pev(id,pev_weaponmodel2,P_MODEL);
   }else{set_weapon_anim(id,2+g_HolyCombo[id]+(Check[id]?13:0));emit_sound(id, CHAN_WEAPON, holysword_sound[10 + g_HolyCombo[id]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);Control_HolySword_Damage(id);g_HolyCombo[id]=(g_HolyCombo[id]+1)%3;}
   g_NextHoly[id]=now+0.75;set_pdata_float(ent,48,1.8,4);
  }else if(now-g_ChargeHoly[id]>=0.7 && Slash[id]!=2){Slash[id]=2;set_weapon_anim(id,Check[id]?19:7);}
  return FMRES_HANDLED;
 }
 if(now<g_NextHoly[id])return FMRES_HANDLED;
 if(buttons & IN_ATTACK2){
  IsDef[id]=1;g_ParryUntil[id]=now+0.8;g_NextHoly[id]=now+1.2;
  set_weapon_anim(id,Check[id]?22:10);emit_sound(id, CHAN_WEAPON, holysword_sound[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);set_pdata_float(ent,48,1.2,4);
 }else if(buttons & IN_ATTACK){
  g_ChargingHoly[id]=true;g_ChargeHoly[id]=now;Slash[id]=1;set_weapon_anim(id,Check[id]?18:6);
 }
 return FMRES_HANDLED;
}
public Make_Some_effectMaBroh(id) /*AdsianDx*/
{
	new iHitResult
	new Float:fRange = (get_pcvar_float(cvar_radius_damage))
	
	iHitResult = KnifeAttack_Global(id, true, fRange, 90.0, 0.0, 5.0)
		
	new Float:vecSrc[3], Float:vecEnd[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, 50.0, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
 free_tr2(tr)
	switch (iHitResult)
	{
		case RESULT_HIT_PLAYER : emit_sound(id, CHAN_ITEM, holysword_sound[15], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		case RESULT_HIT_WORLD :  client_cmd(id, "spk %s", holysword_sound[14])
	}
		
	if(iHitResult != RESULT_HIT_NONE)
	{
		new Float:iVicOrig[3], pEntity = -1;
		new Float:realOrig[3]; pev(id, pev_origin, realOrig)
		
			
		if(iHitResult == RESULT_HIT_PLAYER)
		{
			while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, realOrig, fRange)) != 0)
			{
				if (!pev_valid(pEntity))
					continue;
				if (id == pEntity)
					continue;
				if (!IsAlive(pEntity))
					continue;
				if (!CheckAngle(id, pEntity, 180.0))
					continue;

				Stock_Get_Origin(pEntity, iVicOrig);
					
				iVicOrig[2] -= 15.0
				Make_EffSprite(iVicOrig)
			}
		} else Make_EffSprite(EndPos2)
	}
}
public Holy_Chargecannon(id)
{
	if(!ExHero_HolyOwner(id))return;
 static Float:vAvel[3],Float:targetOri[3], Float:vAngle[3], Float:vVelocity[3],Float:fOrigin2[3], Float:vPlayerVelocity[3];
	pev(id, pev_origin, fOrigin2)
	pev(id, pev_v_angle, vAngle)
	pev(id, pev_velocity, vPlayerVelocity);
	fm_get_aim_origin(id, targetOri)
	
	new HolyBomb = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
 if(!pev_valid(HolyBomb))return;
	Stock_GetSpeedVector(fOrigin2, targetOri, 1050.0, vVelocity);
	xs_vec_add(vVelocity, vPlayerVelocity, vVelocity);
	
	vector_to_angle(vVelocity, vAngle)
	if(vAngle[0] > 90.0) vAngle[0] = -(360.0 - vAngle[0]);
	
	dllfunc(DLLFunc_Spawn, HolyBomb)
	set_pev(HolyBomb, pev_classname, "holy_chargecannon")
	set_pev(HolyBomb, pev_animtime, get_gametime())
	set_pev(HolyBomb, pev_framerate, 1.0)
	set_pev(HolyBomb ,pev_angles, vAngle)
	set_pev(HolyBomb, pev_movetype, MOVETYPE_FLY)		
	set_pev(HolyBomb, pev_frame, 1.0)
	set_pev(HolyBomb, pev_scale, 1.5)
	engfunc(EngFunc_SetModel, HolyBomb, CHARGE_CANNON)
	engfunc(EngFunc_SetSize, HolyBomb, {-2.0,-2.0,-2.0}, {2.0,2.0,2.0})
	set_pev(HolyBomb, pev_origin, fOrigin2)
	set_pev(HolyBomb, pev_iuser1, 0)
	
	vAvel[2] = random_float(-1750.0, 1750.0)
	set_pev(HolyBomb, pev_avelocity, vAvel)
	set_pev(HolyBomb, pev_velocity, vVelocity)
	set_pev(HolyBomb, pev_solid, SOLID_TRIGGER)
	set_pev(HolyBomb, pev_owner, id)
 set_pev(HolyBomb,pev_iuser4,get_user_userid(id)); set_pev(HolyBomb,pev_fuser1,get_gametime()+3.0);
	set_pev(HolyBomb, pev_nextthink, get_gametime() + 0.01)
	
	client_cmd(id, "spk %s", "weapons/holysword_cannon.wav")
}
public Holy_Chargecannon_Think(Ent)
{
	if(!pev_valid(Ent) || (pev(Ent,pev_flags)&FL_KILLME))
		return
	
	new Float:fFrame
	new pevAtk = pev(Ent, pev_owner)
 if(!is_user_alive(pevAtk) || zp_get_user_zombie(pevAtk) || !g_Had_HolySword[pevAtk] || get_user_userid(pevAtk)!=pev(Ent,pev_iuser4)) {remove_entity(Ent);return;}
	pev(Ent, pev_frame, fFrame)
	fFrame += 0.5
	set_pev(Ent, pev_frame, fFrame)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.075)
	new Float:expires;pev(Ent,pev_fuser1,expires);
 if(entity_range(Ent, pevAtk) >= 600.0 || get_gametime()>=expires)
	{
		Explo_Lagi(Ent, pevAtk)
	}
}
public fw_Muzzle_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Owner; Owner = pev(iEnt, pev_owner)
	
	if(!is_user_alive(Owner)||zp_get_user_zombie(Owner)||(pev(iEnt,pev_flags)&FL_KILLME))
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		return
	}
	
	static iActiveItem; iActiveItem = get_pdata_cbase(Owner, 373, 5)
	
	if(!IsValidPev(iActiveItem))
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		return
	}
	if(!g_spr[Owner] || !g_Had_HolySword[Owner])
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		ExHero_RemoveEffects(Owner, "mf_hsword")
		return
	}
	static Float:Frame; pev(iEnt, pev_frame, Frame)
	if(Frame > 14.0)
	{
		Frame = 0.0
	}
	Frame += 0.7
	set_pev(iEnt, pev_frame, Frame)
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.04)
}
public fw_Muzzle2_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Owner; Owner = pev(iEnt, pev_owner)
	
	if(!is_user_alive(Owner)||zp_get_user_zombie(Owner)||(pev(iEnt,pev_flags)&FL_KILLME))
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		return
	}
	
	static iActiveItem; iActiveItem = get_pdata_cbase(Owner, 373, 5)
	
	if(!IsValidPev(iActiveItem))
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		return
	}
	if(!g_spr2[Owner] || !g_Had_HolySword[Owner])
	{
		set_pev(iEnt, pev_flags, FL_KILLME)
		ExHero_RemoveEffects(Owner, "mf_hsword2")
		return
	}
	static Float:Frame; pev(iEnt, pev_frame, Frame)
	if(Frame > 10.0)
	{
		Frame = 0.0
	}
	Frame += 0.6
	set_pev(iEnt, pev_frame, Frame)
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.04)
}
public Holy_Chargecannon_Touch(Ent, touch)
{
	if(!pev_valid(Ent) || (pev(Ent,pev_flags)&FL_KILLME))
		return
	
	static Classname[32], id; id = pev(Ent, pev_owner)
	pev(Ent, pev_classname, Classname, charsmax(Classname))
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_Had_HolySword[id]) return
	new Holy = fm_get_user_weapon_entity(id, CSW_HOLY)
		
	if(!equal(Classname, "holy_chargecannon"))
		return
		
	if(is_user_alive(touch) && pev(Ent, pev_owner) == touch)
		return
	
	if(pev_valid(touch))
	{
		static Classname2[32]
		pev(touch, pev_classname, Classname2, charsmax(Classname2))
		
		if(equal(Classname2, "holy_chargecannon")) return
		}
	set_pev(Ent,pev_solid,SOLID_NOT);set_pev(Ent,pev_flags,pev(Ent,pev_flags)|FL_KILLME);
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Exp_SprId) 
	write_byte(6)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp2) 
	write_byte(9)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()		
	emit_sound(id, CHAN_VOICE, holysword_sound[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 1; i <=32; i++)
	{
		if(!is_user_alive(i))
			continue
		if(!zp_get_user_zombie(i))
			continue
		if(entity_range(Ent, i) > get_pcvar_float(cvar_radius_damage))
			continue
		
		exhero_damage(i,Ent,id,get_pcvar_float(cvar_damage_exp),DMG_BLAST,"Holy Sword: canon")
		Stock_Fake_KnockBack(id, i, get_pcvar_float(cvar_kb))
	}
	set_pev(Ent,pev_flags,pev(Ent,pev_flags)|FL_KILLME)
}
public Explo_Lagi(Ent,id){if(pev_valid(Ent))Holy_Chargecannon_Touch(Ent,0);}
public Control_HolySword_Damage(id){
 if(!ExHero_HolyOwner(id))return;
 new hits=ExHero_HolyHit(id,Check[id]?get_pcvar_float(cvar_damagea_fullstack):get_pcvar_float(cvar_damagea_normal),"Holy Sword: corte");
 if(hits && !Check[id]){iStack[id]++;if(iStack[id]>=5){Check[id]=1;set_pev(id,pev_weaponmodel2,P_MODEL_FULLSTACK);}}
}
public fw_ThinkHolySwordFx(ent)
{
	if(!pev_valid(ent)) return FMRES_IGNORED
 static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_Had_HolySword[id]) {set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);return FMRES_IGNORED;}
	set_pev(ent, pev_nextthink, get_gametime()+0.01)
	new Float:fFrame
	pev(ent, pev_frame, fFrame)
	fFrame += 7.5
	set_pev(ent, pev_frame, fFrame)
	static Float:fTimeRemove, Float:fValue
	pev(ent, pev_ltime, fTimeRemove)
	if(get_gametime() >= fTimeRemove - 0.6)
	{
		pev(ent, pev_renderamt, fValue)
		fValue -= 15.0
		fValue = floatmax(fValue, 0.0)
		set_pev(ent, pev_renderamt, fValue)
	}
	if(get_gametime() >= fTimeRemove)
	{
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
	}
	return FMRES_IGNORED
}				
//Stock
stock Stock_Muzzle(id)
{
 ExHero_RemoveEffects(id,"mf_hsword");
	g_spr[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	static Ent; Ent = g_spr[id]
	if(!pev_valid(Ent)) return
	
	engfunc(EngFunc_SetModel, Ent, holysword_special_spr[0]);
	set_pev(Ent, pev_classname, "mf_hsword")
	set_pev(Ent, pev_nextthink, get_gametime() + 0.04);
	set_pev(Ent, pev_body, 1);
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(Ent, pev_rendermode, kRenderTransAdd);
	set_pev(Ent, pev_renderamt, 250.0);
	set_pev(Ent, pev_aiment, id);
	set_pev(Ent, pev_owner, id);
	
	if(!g_Had_HolySword[id])ExHero_RemoveEffects(id, "mf_hsword")

	set_pev(Ent, pev_scale, 0.06);
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_fuser1, get_gametime()+0.4)

	set_pev(Ent, pev_solid, SOLID_NOT);
	dllfunc(DLLFunc_Spawn, Ent);
}
stock Stock_Muzzle2(id, model_type)
{
 ExHero_RemoveEffects(id,"mf_hsword2");
	g_spr2[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	static Ent2; Ent2 = g_spr2[id]
	if(!pev_valid(Ent2)) return
	
	set_pev(Ent2, pev_classname, "mf_hsword2")
	
	set_pev(Ent2, pev_owner, id)
	set_pev(Ent2, pev_body, 1)
	set_pev(Ent2, pev_skin, 0)
	set_pev(Ent2, pev_aiment, id)
	set_pev(Ent2, pev_movetype, MOVETYPE_FOLLOW)
	
	set_pev(Ent2, pev_scale, 0.045)
	set_pev(Ent2, pev_frame, 0.0)
	set_pev(Ent2, pev_rendermode, kRenderTransAdd)
	set_pev(Ent2, pev_renderamt, 200.0)
	if(!g_Had_HolySword[id])ExHero_RemoveEffects(id, "mf_hsword2")
	
	set_pev(Ent2, pev_nextthink, get_gametime() + 0.04)
	dllfunc(DLLFunc_Spawn, Ent2);
	
	switch(model_type)
	{
		case 1:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[1])
		case 2:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[2])
		case 3:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[3])
		case 4:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[3])
		case 5:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[4])
		case 6:engfunc(EngFunc_SetModel, Ent2,  holysword_special_spr[4])
	}
}
stock Float:Adjust_Damage(id, iType, Float:flDamage1, Float:flDamage2)
{
 return (Check[id] ? flDamage2 : flDamage1) * AttackDamage_Mul[clamp(iType,0,2)];
}
stock holysword_effect(id)
{
	new Float:origin[3]
	pev(id, pev_origin, origin)

	if(pev(id, pev_flags) & FL_DUCKING) Stock_Get_Postion(id, 15.0, 5.0, -20.0, origin)
	else Stock_Get_Postion(id, 15.0, 5.0, -35.0, origin)

	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(iEnt)) return;
	set_pev(iEnt, pev_classname, "holysword")
	set_pev(iEnt, pev_origin, origin)
	set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
	set_pev(iEnt, pev_solid, SOLID_NOT)
	set_pev(iEnt, pev_light_level, 180)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 255.0)
	set_pev(iEnt, pev_animtime, 0.5)
	engfunc(EngFunc_SetModel, iEnt, Check[id]?PARRYATTACK2:PARRYATTACK)
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	set_pev(iEnt, pev_ltime, Check[id]?get_gametime()+1.5 : get_gametime()+1.0)
}
stock create_paring_damage(id)
{
	new Float:origin[3]
	pev(id, pev_origin, origin)
	if(!is_user_alive(id) || !g_Had_HolySword[id])
		return
		
	new i = -1
	while((i = find_ent_in_sphere(i, origin, get_pcvar_float(cvar_radius_damage))) != 0) 
	{
		if(i == id) continue
		if(pev(i, pev_takedamage) == DAMAGE_NO) continue
		if(pev(i, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) continue
		if(is_user_alive(i))
			if(get_user_team(i) == get_user_team(id)) continue
		ExecuteHamB(Ham_TakeDamage, i, fm_get_user_weapon_entity(id, CSW_HOLY), id, get_pcvar_float(cvar_damage_paring), DMG_SLASH)
		Stock_Fake_KnockBack22(id, i, get_pcvar_float(cvar_kb))
	}
}
stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, m_pPlayer, OFFSET_LINUX_WEAPONS)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	if(anim != -1)set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
}

stock Stock_Get_Postion(id, Float:depan, Float:kanan, Float:atas, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * depan + vRight[0] * kanan + vUp[0] * atas
	vStart[1] = vOrigin[1] + vForward[1] * depan + vRight[1] * kanan + vUp[1] * atas
	vStart[2] = vOrigin[2] + vForward[2] * depan + vRight[2] * kanan + vUp[2] * atas
}
stock Stock_Fake_KnockBack(id, iVic, Float:ikb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0;
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, ikb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}
stock Stock_Fake_KnockBack22(id, iVic, Float:iKb)
{
    if (iVic > 32)
    {
        return 0;
    }
    new Float:vAttacker[3];
    new Float:vVictim[3];
    new Float:vVelocity[3];
    new flags = 0;
    pev(id, pev_origin, vAttacker);
    pev(iVic, pev_origin, vVictim);
    flags = pev(id, pev_flags);
    xs_vec_sub(vVictim, vAttacker, vVictim);
    new Float:fDistance;
    fDistance = xs_vec_len(vVictim);
    xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim);
    pev(iVic, pev_velocity, vVelocity);
    xs_vec_mul_scalar(vVictim, iKb, vVictim);
    xs_vec_mul_scalar(vVictim, 50.00, vVictim);
    vVictim[2] = xs_vec_len(vVictim) * 0.15;
    if (flags & -513)
    {
        xs_vec_mul_scalar(vVictim, 1.20, vVictim);
        vVictim[2] *= 0.40;
    }
    if (xs_vec_len(vVictim) > xs_vec_len(vVelocity))
    {
        set_pev(iVic, pev_velocity, vVictim);
    }
    return 0;
}
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}
stock bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
stock KnifeAttack_Global(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		iHitResult = RESULT_HIT_WORLD;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 1.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			if(is_user_alive(pEntity)) set_pdata_int(pEntity,75,get_tr2(tr,TR_iHitgroup),5);
			ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, bitsDamageType)
			Stock_Fake_KnockBack22(id, pEntity, flKnockBack)
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}
stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0)
{
	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	pev(id, pev_origin, vecOrigin);

	new iHitResult = RESULT_HIT_NONE;
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
	
	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction < 1.0) 
	{
		iHitResult = RESULT_HIT_WORLD;
	}
	
	new Float:vecEndZ = vecEnd[2];
	
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
		if (id == pEntity)
			continue;
		if (!IsAlive(pEntity))
			continue;
		if (!CheckAngle(id, pEntity, fAngle))
			continue;

		GetGunPosition(id, vecSrc);
		Stock_Get_Origin(pEntity, vecEnd);

		vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRange);

		xs_vec_sub(vecEnd, vecSrc, vecForward);
		xs_vec_normalize(vecForward, vecForward);
		xs_vec_mul_scalar(vecForward, flRange, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction < 1.0)
		{
			if (IsPlayer(pEntity) || IsHostage(pEntity))
			{
				iHitResult = RESULT_HIT_PLAYER;
				
				if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
					flDamage *= 1.0;
			}

			if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				if(is_user_alive(pEntity)) set_pdata_int(pEntity,75,get_tr2(tr,TR_iHitgroup),5);
				ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, DMG_NEVERGIB | DMG_CLUB)
				
				Stock_Fake_KnockBack22(id, pEntity, flKnockBack)
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}
stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}
stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}
stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if (angle < -180.0) angle += 360.0
	if (angle <= 45.0 && angle >= -45.0) return 1
	return 0
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))

stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	Stock_Get_Origin(id, vId_ori)
	Stock_Get_Origin(iTarget, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if (fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	return fRad   //->   RAD 90' = 0.5rad
}
stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:fKnockBack, bitsDamageType, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	new pEntity = -1, tr = create_tr2(), Float:flAdjustedDamage, Float:falloff, iHitResult = RESULT_HIT_NONE

	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	vecSrc[2] += 1.0
	if(!pevAttacker) pevAttacker = pevInflictor
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue
		if(bInWater && !pev(pEntity, pev_waterlevel))
			continue
		if(!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue
		if(bCheckTeam && IsPlayer(pEntity) && pEntity != pevAttacker)
			if(!can_damage(pEntity, pevAttacker))
				continue
		if(bSkipAttacker && pEntity == pevAttacker)
			continue
		
		new Float:vecEnd[3]
		pev(pEntity, pev_origin, vecEnd)

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

		new Float:flFraction
		get_tr2(tr, TR_flFraction, flFraction)

		if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
		
		if(pev_valid(pEntity))
		{
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = floatmax(0.0, flDamage - fDistance * falloff)
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			if(is_user_alive(pEntity)) set_pdata_int(pEntity,75,get_tr2(tr,TR_iHitgroup),5);
			ExecuteHamB(Ham_TakeDamage, pEntity, pevAttacker, pevAttacker, flAdjustedDamage, bitsDamageType);
			Stock_Fake_KnockBack(pevAttacker, pEntity, fKnockBack)
			
			iHitResult = RESULT_HIT_PLAYER
		}
	}
	free_tr2(tr)
	return iHitResult
}
stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if (pev(id, pev_solid) == SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id, pev_origin, origin)
}
stock Make_EffSprite(Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(exp2) 
	write_byte(3)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:len=vector_length(new_velocity); if(len<0.001) return; new Float:num=speed/len;
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}
stock Stock_Get_Velocity_Angle(entity, Float:output[3])
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	vector_to_angle(velocity, output)
	if( output[0] > 90.0 ) output[0] = -(360.0 - output[0])
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/

public plugin_natives() { register_native("exhero_give_holy","ExHero_GiveNative"); register_native("exhero_remove_holy","ExHero_RemoveNative"); }
public ExHero_GiveNative(plugin,params) { get_holysword(get_param(1)); return 1; }
public ExHero_RemoveNative(plugin,params) { remove_holysword(get_param(1)); return 1; }
public zp_user_infected_pre(id) { remove_holysword(id); }
stock ExHero_RemoveEffects(id, const cls[]) {
 new ent=-1;
 while((ent=find_ent_by_class(ent,cls))>0) if(pev(ent,pev_owner)==id){set_pev(ent,pev_solid,SOLID_NOT);set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);}
}
stock bool:ExHero_HolyOwner(id){return id>=1 && id<=32 && is_user_alive(id) && !zp_get_user_zombie(id) && g_Had_HolySword[id]!=0;}
public ExHero_HolyBlock(ent){if(pev_valid(ent)!=2)return HAM_IGNORED;return ExHero_HolyOwner(get_pdata_cbase(ent,41,4))?HAM_SUPERCEDE:HAM_IGNORED;}
public ExHero_HolyHolster(ent){
 if(pev_valid(ent)!=2)return;
 new id=get_pdata_cbase(ent,41,4);if(id<1 || id>32 || !g_Had_HolySword[id])return;
 g_ChargingHoly[id]=false;IsDef[id]=0;g_ParryUntil[id]=0.0;Slash[id]=0;
 ExHero_RemoveEffects(id,"mf_hsword");ExHero_RemoveEffects(id,"mf_hsword2");g_spr[id]=0;g_spr2[id]=0;
}
public ExHero_HolyClientData(id,send,cd){if(ExHero_HolyOwner(id) && get_user_weapon(id)==CSW_KNIFE)set_cd(cd,CD_flNextAttack,get_gametime()+0.001);}
stock ExHero_HolyHit(id,Float:damage,const label[])
{
 new Float:src[3],Float:eye[3],Float:dst[3],Float:dir[3],Float:angles[3],Float:fwd[3],Float:end[3],Float:point[3],hits;
 pev(id,pev_origin,src);pev(id,pev_view_ofs,eye);xs_vec_add(src,eye,eye);
 pev(id,pev_v_angle,angles);angle_vector(angles,ANGLEVECTOR_FORWARD,fwd);
 new Float:range=exhero_knife_range();xs_vec_mul_scalar(fwd,range,end);xs_vec_add(eye,end,end);
 new aim=create_tr2(),tr=create_tr2(),weapon=fm_get_user_weapon_entity(id,CSW_KNIFE);
 engfunc(EngFunc_TraceLine,eye,end,DONT_IGNORE_MONSTERS,id,aim);
 new aimed=get_tr2(aim,TR_pHit);
 for(new v=1;v<=32;v++)
 {
  if(!is_user_alive(v) || !zp_get_user_zombie(v))continue;
  pev(v,pev_origin,dst);xs_vec_sub(dst,src,dir);new Float:dist=vector_length(dir);if(dist>range)continue;
  if(dist>0.01){xs_vec_mul_scalar(dir,1.0/dist,dir);if(xs_vec_dot(dir,fwd)<0.25)continue;}
  new group;
  if(aimed==v){group=get_tr2(aim,TR_iHitgroup);get_tr2(aim,TR_vecEndPos,point);}
  else{
   // The surrounding sword sweep targets the torso, never invents a headshot.
   dst[2]+=8.0;engfunc(EngFunc_TraceLine,eye,dst,DONT_IGNORE_MONSTERS,id,tr);
   if(get_tr2(tr,TR_pHit)!=v)continue;
   group=get_tr2(tr,TR_iHitgroup);get_tr2(tr,TR_vecEndPos,point);
  }
  new text[80];formatex(text,charsmax(text),"%s [%s]",label,group==HIT_HEAD?"HEAD":"BODY");
  // Preserve the existing damage balance; report the actual hit region.
  set_pdata_int(v,75,group,5);
  if(exhero_damage(v,weapon,id,damage,DMG_SLASH,text)>0){hits++;ExHero_HolyBlood(point);}
 }
 free_tr2(aim);free_tr2(tr);return hits;
}
stock ExHero_HolyBlood(const Float:point[3])
{
 engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,point,0);
 write_byte(TE_BLOODSPRITE);
 engfunc(EngFunc_WriteCoord,point[0]);engfunc(EngFunc_WriteCoord,point[1]);engfunc(EngFunc_WriteCoord,point[2]);
 write_short(g_HolyBloodSpr);write_short(g_HolyBloodDrop);write_byte(247);write_byte(8);message_end();
}
public zp_user_infect_attempt(id,infector,nemesis)
{
 if(!nemesis && ExHero_HolyTryParry(id,infector))return ZP_PLUGIN_HANDLED;
 return PLUGIN_CONTINUE;
}

// Dedicated synchronized HUD, positioned above the usual ammunition area.
public ExHero_HolyChargeHud()
{
 for(new id=1;id<=32;id++)
 {
  if(!is_user_connected(id)){g_HolyHudVisible[id]=false;continue;}
  if(!ExHero_HolyOwner(id) || get_user_weapon(id)!=CSW_KNIFE)
  {
   if(g_HolyHudVisible[id]){ClearSyncHud(id,g_HolyChargeHud);g_HolyHudVisible[id]=false;}
   continue;
  }
  new count=Check[id]?5:clamp(iStack[id],0,5), bar[6];
  for(new k=0;k<5;k++)bar[k]=k<count?'|':'.';
  bar[5]=0;
  if(Check[id])set_hudmessage(80,230,255,0.76,0.80,0,0.0,0.3,0.0,0.0,-1);
  else set_hudmessage(255,195,65,0.76,0.80,0,0.0,0.3,0.0,0.0,-1);
  if(get_gametime()<g_HolyParryNotice[id])ShowSyncHudMsg(id,g_HolyChargeHud,"HOLY SWORD^n[%s] %d/5^nPARREO!",bar,count);
  else if(IsDef[id] && get_gametime()<g_ParryUntil[id])ShowSyncHudMsg(id,g_HolyChargeHud,"HOLY SWORD^n[%s] %d/5^nDEFENDIENDO",bar,count);
  else if(Check[id])ShowSyncHudMsg(id,g_HolyChargeHud,"HOLY SWORD^n[%s] 5/5^nCARGA COMPLETA",bar);
  else ShowSyncHudMsg(id,g_HolyChargeHud,"HOLY SWORD^n[%s] %d/5",bar,count);
  g_HolyHudVisible[id]=true;
 }
}

public AuditHolyKilled(id){remove_holysword(id);}
