#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

// ~ [ Macroses ] ~ //
#define IsCustomWeapon(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsCustomMuzzle(%0) (pev(%0, pev_impulse) == gl_iszAllocString_MuzzleKey)
#define IsPdataSafe(%0) (pev_valid(%0) == 2)

#define weaponHasMaxHits(%0) (get_pdata_int(%0, m_iShotCount, linux_diff_weapon) >= BERSERK_MODE_SHOT_COUNT)
#define weaponHasBerserkMode(%0) (get_pdata_int(%0, m_iBerserkMode, linux_diff_weapon))

#define m_iShotCount m_iGlock18ShotsFired
#define m_iBerserkMode m_iFamasShotsFired

// ~ [ Weapon Settings ] ~ //
new const WEAPON_ITEM_NAME[] = "Mecha Dino MK-4";
const WEAPON_ITEM_COST = 0;

new const WEAPON_NATIVE[] = "zp_give_user_y21s4janusd";

new const WEAPON_REFERENCE[] = "weapon_mp5navy";
new const WEAPON_WEAPONLIST[] = "weapon_y21s4janusd";
const WEAPON_SPECIAL_CODE = 08052024122;

new const WEAPON_MODEL_VIEW[] = "models/g3bmodel/ZTHEX/v_y21s4janusd.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/p_y21s4janusd.mdl";
new const WEAPON_MODEL_WORLD[] = "models/w_y21s4janusd.mdl";

new const WEAPON_SOUNDS[][] = 
{
	"weapons/y21s4janus-1.wav",
	"weapons/y21s4janus-2.wav",
	"weapons/y21s4janus-3.wav",
	"weapons/y21s4janus_ready.wav"
};

new const ENTITY_WEAPON_RESOURCES[][] = 
{
	"sprites/ef_y21s4janus_burn.spr",
	"sprites/ef_y21s4janus_explosion.spr",
	"sprites/steam1.spr"
};

new const WEAPON_MUZZLEFLASH_CLASSNAME[] = "ent_y21s4janusd_mf";
new const WEAPON_MUZZLEFLASH_SPRITES[][] = 
{
	"sprites/muzzleflash216.spr",
	"sprites/muzzleflash217.spr"
};

const WEAPON_DEFAULT_AMMO = 90;
const WEAPON_MAX_CLIP = 30;
const Float: WEAPON_RATE = 0.12;
const Float: WEAPON_PUNCHANGLE = 0.84;
const Float: WEAPON_DAMAGE = 1.35;

// ~ [ Special Mode: Berserk ] ~ //
const Float: BERSERK_MODE_TIME = 14.0;
const Float: BERSERK_MODE_RATE = 0.09;
const BERSERK_MODE_SHOT_COUNT = 28;

// ~ [ Special Skill: Berserk Explosion ] ~ //
const BERSERK_EXP_SHOT_COUNT = 19; 
const Float: BERSERK_EXP_DAMAGE = 132.0;
const Float: BERSERK_EXP_RADIUS = 300.0;
const ENTITY_BERSERK_EXP_DMGTYPE = DMG_BLAST|DMG_BURN;

new const iWeaponList[] =
{
	10, 120, -1, -1, 0, 7, 19, 0 // weapon_mp5navy
};

// ~ [ Weapon Animations ] ~ //
// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 121/30.0
#define WEAPON_ANIM_RELOAD_TIME 76/30.0
#define WEAPON_ANIM_DRAW_TIME 41/30.0
#define WEAPON_ANIM_SHOOT_TIME 31/30.0
#define WEAPON_ANIM_CHANGE1_TIME 31/30.0
#define WEAPON_ANIM_CHANGE2_TIME 26/30.0

enum _: eWeaponAnim
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_SHOOT1_1,
	WEAPON_ANIM_SHOOT_SIGNAL,
	WEAPON_ANIM_CHANGE1,
	WEAPON_ANIM_IDLE2,
	WEAPON_ANIM_DRAW2,
	WEAPON_ANIM_SHOOT2_1,
	WEAPON_ANIM_SHOOT2_2,
	WEAPON_ANIM_SHOOT2_3,
	WEAPON_ANIM_CHANGE2,
	WEAPON_ANIM_IDLE_SIGNAL,
	WEAPON_ANIM_RELOAD_SIGNAL,
	WEAPON_ANIM_DRAW_SIGNAL
};

// ~ [ Offsets ] ~ //
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rpgPlayerItems = 367;
const m_pNext = 42
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle = 48;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_rgpPlayerItems_iWeaponBox = 34;
const m_iGlock18ShotsFired = 70;
const m_iFamasShotsFired = 72;
const m_maxFrame = 35;

// ~ [ Params ] ~ //
new HamHook: gl_HamHook_TraceAttack[4],

	gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_MuzzleKey,

	gl_iszModelIndex_Resources[sizeof ENTITY_WEAPON_RESOURCES],
	
	gl_iMsgID_Weaponlist,

	gl_iItemID;

// ~ [ AMX Mod X ] ~ //
public plugin_init()
{
 RegisterHam(Ham_Killed,"player","AuditMechaCleanup",1);
	// https://cso.fandom.com/wiki/Mechasaurus_MK-4
	register_plugin("[ZP] Extra-Item: Mecha Dino MK-4", "v1.0 | 2023", "SPACE | Cristian505 \ Batcoh: Code Base")

	// Fakemeta
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post",			true);
	register_forward(FM_SetModel,		"FM_Hook_SetModel_Pre",					false);

	// Weapon
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERENCE,	"CWeapon__Deploy_Post",		true);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre",	false);
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERENCE,	"CWeapon__Reload_Pre",		false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre",	false);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERENCE,	"CWeapon__Holster_Post",	true);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post",	true);

	// Entity
	RegisterHam(Ham_Think,			"env_sprite",		"CMuzzleFlash__Think_Pre",	false);

	// Trace Attack
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre",  false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre",  false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",		"CEntity__TraceAttack_Pre",  false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre",  false);

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_MuzzleKey = engfunc(EngFunc_AllocString, WEAPON_MUZZLEFLASH_CLASSNAME);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	// Ham Hook
	fm_ham_hook(false);

	// Register weapon
	gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);
}

public plugin_precache()
{
    precache_generic("sound/weapons/y21s4janus_boltpull.wav");
    precache_generic("sound/weapons/y21s4janus_changeAB.wav");
    precache_generic("sound/weapons/y21s4janus_changeBA.wav");
    precache_generic("sound/weapons/y21s4janus_clipin1.wav");
    precache_generic("sound/weapons/y21s4janus_clipin2.wav");
    precache_generic("sound/weapons/y21s4janus_clipout.wav");
    precache_generic("sound/weapons/y21s4janus_draw.wav");

	new i;
	
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	for(i = 0; i < sizeof WEAPON_MUZZLEFLASH_SPRITES; i++)
		engfunc(EngFunc_PrecacheModel, WEAPON_MUZZLEFLASH_SPRITES[i]);

	// Precache generic
	new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
	engfunc(EngFunc_PrecacheGeneric, szWeaponList);

	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);
		
	// Model index
	for(i = 0; i < sizeof ENTITY_WEAPON_RESOURCES; i++)
		gl_iszModelIndex_Resources[i] = engfunc(EngFunc_PrecacheModel, ENTITY_WEAPON_RESOURCES[i]);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

// ~ [ Zombie Plague ] ~ //
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public Command_GiveWeapon(iPlayer)
{
	static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(!IsPdataSafe(iWeapon)) return FM_NULLENT;

	set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iWeapon);
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
	{
		set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);
	UTIL_WeaponList(iPlayer, true);

	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) < WEAPON_DEFAULT_AMMO)
	set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return 1;
}

// ~ [ HamSandwich ] ~ //
public CWeapon__Deploy_Post(iWeapon)
{
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

	static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	static iAnim;
	if(weaponHasBerserkMode(iWeapon)) iAnim = WEAPON_ANIM_DRAW2;
	else iAnim = weaponHasMaxHits(iWeapon) ? WEAPON_ANIM_DRAW_SIGNAL : WEAPON_ANIM_DRAW;

	UTIL_SendWeaponAnim(iPlayer, iAnim);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsPdataSafe(iItem) || !IsCustomWeapon(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static iAnim;
	if(weaponHasBerserkMode(iItem)) iAnim = WEAPON_ANIM_IDLE2;
	else iAnim = weaponHasMaxHits(iItem) ? WEAPON_ANIM_IDLE_SIGNAL : WEAPON_ANIM_IDLE;

	UTIL_SendWeaponAnim(iPlayer, iAnim);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iWeapon)
{
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;
	
	static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
	static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);		

	ExecuteHam(Ham_Weapon_PrimaryAttack, iWeapon);
		
	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float: vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHANGLE
	vecPunchangle[1] *= WEAPON_PUNCHANGLE
	vecPunchangle[2] *= WEAPON_PUNCHANGLE
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	static iAnim, iSound;
	if(weaponHasBerserkMode(iWeapon))
	{
		iAnim = random_num(WEAPON_ANIM_SHOOT2_1, WEAPON_ANIM_SHOOT2_3);
		iSound = 2;
		
		UTIL_CreateMuzzleFlash(iPlayer, WEAPON_MUZZLEFLASH_SPRITES[1], 0, random_float(0.04, 0.08), 255.0, 1, 0.04);

		set_pdata_int(iWeapon, m_iClip, iAmmo - 0, linux_diff_weapon);
		
		// Thanks to Tech2Cool.
		static AttackCount = 0;
		if(AttackCount >= BERSERK_EXP_SHOT_COUNT)
		{
			Create_BerserkExplosion(iWeapon);
			AttackCount = 0;
		} 
		AttackCount++;
	}
	else
	{
		if(!iAmmo)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iWeapon);
			set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

			return HAM_SUPERCEDE;
		}

		iAnim = weaponHasMaxHits(iWeapon) ? WEAPON_ANIM_SHOOT_SIGNAL : WEAPON_ANIM_SHOOT1_1; 
		iSound = weaponHasMaxHits(iWeapon) ? 1 : 0;
		
		UTIL_CreateMuzzleFlash(iPlayer, WEAPON_MUZZLEFLASH_SPRITES[0], 0, random_float(0.02, 0.04), 255.0, 1, 0.04);

		if(!weaponHasMaxHits(iWeapon))
		{
			set_pdata_int(iWeapon, m_iShotCount, get_pdata_int(iWeapon, m_iShotCount, linux_diff_weapon) + 1, linux_diff_weapon);
			
			if(weaponHasMaxHits(iWeapon)) 
				emit_sound(iPlayer, CHAN_AUTO, WEAPON_SOUNDS[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	UTIL_SendWeaponAnim(iPlayer, iAnim);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
	set_pdata_float(iPlayer, m_flNextAttack, weaponHasBerserkMode(iWeapon) ? BERSERK_MODE_RATE : WEAPON_RATE, linux_diff_player);
	set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flNextPrimaryAttack, weaponHasBerserkMode(iWeapon) ? BERSERK_MODE_RATE : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flNextSecondaryAttack, weaponHasBerserkMode(iWeapon) ? BERSERK_MODE_RATE : WEAPON_RATE, linux_diff_weapon);
	
	
	return HAM_SUPERCEDE;
}

public CWeapon__Reload_Pre(iWeapon)
{
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

	static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
	if(iAmmo >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;
	if(weaponHasBerserkMode(iWeapon)) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iWeapon, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iWeapon);
	set_pdata_int(iWeapon, m_iClip, iAmmo, linux_diff_weapon);
	set_pdata_int(iWeapon, m_fInReload, 1, linux_diff_weapon);
	
	UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iWeapon) ? WEAPON_ANIM_RELOAD_SIGNAL : WEAPON_ANIM_RELOAD);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
	set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PostFrame_Pre(iWeapon)
{ 
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);

	if(get_pdata_int(iWeapon, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);
		
		set_pdata_int(iWeapon, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iWeapon, m_fInReload, 0, linux_diff_weapon);
	}

	static iButton; iButton = pev(iPlayer, pev_button);
	if(iButton & IN_ATTACK2 && weaponHasMaxHits(iWeapon) && get_pdata_float(iWeapon, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
	{
		if(!iClip) return 1;

		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);

		set_pdata_int(iWeapon, m_iShotCount, 0, linux_diff_weapon);
		set_pdata_int(iWeapon, m_iBerserkMode, 1, linux_diff_weapon);
		set_pev(iWeapon, pev_fuser4, get_gametime() + BERSERK_MODE_TIME);

		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE1);

		set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);
		set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);
		set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);
	}

	static Float: flBerserkTime; pev(iWeapon, pev_fuser4, flBerserkTime);
	if(weaponHasBerserkMode(iWeapon) && flBerserkTime < get_gametime())
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE2);
		
		set_pdata_int(iWeapon, m_iBerserkMode, 0, linux_diff_weapon);
		set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
		set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
		set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
	}

	return HAM_IGNORED;
}

public CWeapon__Holster_Post(iWeapon)
{
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

	static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

	set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iWeapon, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;
	
	static iWeapon; iWeapon = get_pdata_cbase(iAttacker, 373, 5);
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

	flDamage *= WEAPON_DAMAGE;
	SetHamParamFloat(3, flDamage);
}

public CWeapon__AddToPlayer_Post(iWeapon, iPlayer)
{
	if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon)) UTIL_WeaponList(iPlayer, true);
	else if(!pev(iWeapon, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

public CMuzzleFlash__Think_Pre(const pSprite)
{
	if(pev_valid(pSprite) != 2 || !IsCustomMuzzle(pSprite)) return HAM_IGNORED;

	new owner=pev(pSprite,pev_owner);if((pev(pSprite,pev_flags)&FL_KILLME)||!is_user_alive(owner)||zp_get_user_zombie(owner)){set_pev(pSprite,pev_flags,FL_KILLME);return HAM_SUPERCEDE;}
	new Float: flFrame; pev(pSprite, pev_frame, flFrame);
	new Float: flNextThink; pev(pSprite, pev_fuser3, flNextThink);
	new iSpriteType = pev(pSprite, pev_iuser1);

	if(flFrame < get_pdata_float(pSprite, m_maxFrame, 4))
	{
		flFrame++;

		set_pev(pSprite, pev_frame, flFrame);
		set_pev(pSprite, pev_nextthink, get_gametime() + flNextThink);
		
		return HAM_SUPERCEDE;
	}
	else if(iSpriteType)
	{
		flFrame = 0.0;
		
		set_pev(pSprite, pev_frame, flFrame);
		set_pev(pSprite, pev_nextthink, get_gametime() + flNextThink);
		
		return HAM_SUPERCEDE;
	}

	set_pev(pSprite, pev_flags, FL_KILLME);
		
	return HAM_SUPERCEDE;
}

// ~ [ Fakemeta ] ~ //
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iWeapon; iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iWeapon;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
		if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
	if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_byte(random_num(41, 45)); // Decal
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_STREAK_SPLASH);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_coord(random_num(-20, 20));
	write_coord(random_num(-20, 20));
	write_coord(random_num(-20, 20)); 
	write_byte(5); // Color
	write_short(random_num(16, 24)); // Count
	write_short(3); // Speed
	write_short(80); // Speed noise
	message_end();

	return FMRES_IGNORED;
}

// ~ [ Others ] ~ //
public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(gl_HamHook_TraceAttack[0]);
		EnableHamForward(gl_HamHook_TraceAttack[1]);
		EnableHamForward(gl_HamHook_TraceAttack[2]);
		EnableHamForward(gl_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(gl_HamHook_TraceAttack[0]);
		DisableHamForward(gl_HamHook_TraceAttack[1]);
		DisableHamForward(gl_HamHook_TraceAttack[2]);
		DisableHamForward(gl_HamHook_TraceAttack[3]);
	}
}

public Create_BerserkExplosion(iItem)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	new Float: vecOrigin[3]; fm_get_aim_origin(iPlayer, vecOrigin);

	// Effects
	UTIL_CreateExplosion(vecOrigin, 90.0, gl_iszModelIndex_Resources[1], 8, 20, 0);
	UTIL_CreateSmoke(vecOrigin, 30.0, gl_iszModelIndex_Resources[2], 30, 5);
	UTIL_CreateSpriteTrail(vecOrigin, 120.0, 50.0, gl_iszModelIndex_Resources[0], 20, 1, random_num(2,3), 20, 15);
	
	static Float: flDamage, iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, BERSERK_EXP_RADIUS)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
			continue;

		if(is_user_alive(iVictim))
		{
			if(iVictim == iPlayer || get_user_team(iVictim) != 1)
				continue;
		}
		else if(pev(iVictim, pev_solid) == SOLID_BSP)
		{
			if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
				continue;
		}

		flDamage = BERSERK_EXP_DAMAGE * random_float(0.75, 1.25);
		ExecuteHamB(Ham_TakeDamage, iVictim, iPlayer, iPlayer, flDamage, ENTITY_BERSERK_EXP_DMGTYPE);
	}
}
// ~ [ Stocks ] ~ //
stock UTIL_SendWeaponAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_DropWeapon(const iPlayer, const iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(iEntity > 0)
	{	   
		do 
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);
			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
			engclient_cmd(iPlayer, "drop", szWeaponName);
		} 
		
		while((iEntity = iNext) > 0);
	}
}

stock UTIL_WeaponList(const iPlayer, bool: bEnabled)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_MAX_CLIP : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}

stock UTIL_CreateMuzzleFlash(const pPlayer, const szMuzzleSprite[], const iMuzzleLoop, const Float: flScale, const Float: flBrightness, const iAttachment, Float: flNextThink)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100) return FM_NULLENT;
		
	static pSprite, iszAllocStringCached;

	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
		pSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
	if(pev_valid(pSprite) != 2) return FM_NULLENT;
		
	set_pev(pSprite, pev_model, szMuzzleSprite);
	set_pev(pSprite, pev_spawnflags, SF_SPRITE_ONCE);
		
	set_pev(pSprite, pev_classname, WEAPON_MUZZLEFLASH_CLASSNAME);
	set_pev(pSprite, pev_impulse, gl_iszAllocString_MuzzleKey);
	set_pev(pSprite, pev_owner, pPlayer);
	set_pev(pSprite, pev_fuser3, flNextThink);
	set_pev(pSprite, pev_iuser1, iMuzzleLoop);
	set_pev(pSprite, pev_aiment, pPlayer);
	set_pev(pSprite, pev_body, iAttachment);

	set_pev(pSprite, pev_rendermode, kRenderTransAdd);
	set_pev(pSprite, pev_renderamt, flBrightness);

	set_pev(pSprite, pev_scale, flScale);
		
	dllfunc(DLLFunc_Spawn, pSprite)

	return pSprite;
}

stock UTIL_CreateExplosion(Float: iVecPos[3], Float: flAddUp, iszModelIndex, iScale, iFramerate, iFlags)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, iVecPos[0]); // Position X
	engfunc(EngFunc_WriteCoord, iVecPos[1]); // Position Y
	engfunc(EngFunc_WriteCoord, iVecPos[2] + flAddUp); // Position Z
	write_short(iszModelIndex); // Model Index
	write_byte(iScale); // Scale
	write_byte(iFramerate); // Framerate
	write_byte(iFlags); // Flags
	message_end();
}

stock UTIL_CreateSmoke(Float: iVecPos[3], Float: flAddUp, iszModelIndex, iScale, iFramerate)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_SMOKE
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE); // TE
	engfunc(EngFunc_WriteCoord, iVecPos[0]); // Position X
	engfunc(EngFunc_WriteCoord, iVecPos[1]); // Position Y
	engfunc(EngFunc_WriteCoord, iVecPos[2] + flAddUp); // Position Z
	write_short(iszModelIndex); // Model Index
	write_byte(iScale); // Scale
	write_byte(iFramerate); // Framerate
	message_end();
}

stock UTIL_CreateSpriteTrail(Float: iVecPos[3], Float: flStartUp, Float: flEndUp, iszModelIndex, iCount, iLife, iScale, iSpeedNoise, iSpeed)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_SPRITETRAIL
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITETRAIL); // TE
	engfunc(EngFunc_WriteCoord, iVecPos[0]); // Position X
	engfunc(EngFunc_WriteCoord, iVecPos[1]); // Position Y
	engfunc(EngFunc_WriteCoord, iVecPos[2] + flStartUp); // Position Z
	engfunc(EngFunc_WriteCoord, iVecPos[0]); // Position X
	engfunc(EngFunc_WriteCoord, iVecPos[1]); // Position Y
	engfunc(EngFunc_WriteCoord, iVecPos[2] + flEndUp); // Position Z
	write_short(iszModelIndex); // Model index
	write_byte(iCount); // Count
	write_byte(iLife); // Life
	write_byte(iScale); // Scale
	write_byte(iSpeedNoise); // Speed noise
	write_byte(iSpeed); // Speed
	message_end();
}

public AuditMechaCleanup(id){new e;while((e=engfunc(EngFunc_FindEntityByString,e,"classname",WEAPON_MUZZLEFLASH_CLASSNAME))>0)if(pev(e,pev_owner)==id)set_pev(e,pev_flags,pev(e,pev_flags)|FL_KILLME);}
public client_disconnected(id){AuditMechaCleanup(id);}
public zp_user_infected_pre(id){AuditMechaCleanup(id);}
