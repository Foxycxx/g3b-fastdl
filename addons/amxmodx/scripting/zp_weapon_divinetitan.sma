#include <exhero_model_sounds>
/*
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 *
 * ┌─[ Latest versions of API's ]
 * │
 * └─┬─[ API: Muzzle-Flash ]
 *   └─ https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash
 *
 * ┌─[ Update 1.1 (02.08.2022) ]
 * │
 * ├─── Some bug-fixes
 * │
 * ├─[ Update 1.2 (03.08.2022) ]
 * │
 * ├─── Fix Muzzle-Flash sprites, if the charges ran out, the sprite was not updated
 * ├─── Fix If the player had an essence, it did not disappear, but was cheerful in the air
 * ├─── Fix if there was a restart of the game, the entity was deleted, however, it was possible to create a new one and it flew after the player, even if he does not have a weapon
 * └─── Now, at the end of the round, you will not be able to use weapons until a new round begins
 */

/* ~ [ Includes ] ~ */
#include <amxmodx>
native revo_get_user_hero(id);
native exhero_titan_unlocked(id);
new bool:g_heroCleaned[33];
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>

// If you don't use ZombiePlague, just comment this line
#include <zombieplague>

// If you are not using ReAPI, delete or comment out this line.
//#include <reapi>

/**
 * For these APIs to work, they need to be installed on your server.
 * API plugins must be registered in plugins*.ini above those plugins where they are used.
 */
#include <api_muzzleflash>

#if !defined DMG_GRENADE
	#define DMG_GRENADE							(1<<24)
#endif

/* ~ [ Extra Item ] ~ */
#if defined _zombieplague_included
	new const ExtraItem_Name[ ] =				"Sandalphon";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Weapon Settings ] ~ */
/**
 * When you turn on this mode, in KillFeed will show that you 
 * killed with your WeaponReference (tmp)
 * 
 * If turned off, it will show the name of the entity that killed
 */
#define UseWeaponAsMethodDamage

/**
 * Use changing hands for v_ model
 * NB! Can use more server resources (CPU, RAM)
 * 
 * Comment 'EnableSubmodelSupport' if you don't use third-party arm body for the v_ model
 */
// #define EnableSubmodelSupport
#if defined EnableSubmodelSupport
	const WeaponHandSubmodel =					0; // Hand Submodel (0: Male / 1: Female)
#endif

const WeaponUnicalIndex =						15062022;
new const WeaponName[ ] =						"Sandalphon";
new const WeaponNative[ ] =						"zp_give_user_divinetitan";
new const WeaponReference[ ] =					"weapon_tmp";
// Comment 'WeaponListDir' if u don't need custom weapon list
new const WeaponListDir[ ] =					"x_re/weapon_divinetitan";
new const WeaponAnimation[ ] =					"c4";
new const WeaponModelView[ ] =					"models/g3bmodel/ZTHEX/x_re/v_divinetitan.mdl";
new const WeaponModelPlayer[ ] =				"models/x_re/p_divinetitan.mdl";
new const WeaponSounds[ ] [ ] = {
	"weapons/divinetitan_A_mode-1_loop.wav",
	"weapons/divinetitan_A_mode-1_end.wav",
	"weapons/divinetitan_B_mode-2.wav",
	"weapons/divinetitan_B_mode-2_exp.wav",
	"weapons/divinetitan_charge.wav",
	"weapons/divinetitan_exp.wav",
	"weapons/divinetitan_fx.wav"
};

const WeaponDefaultAmmo =						25;
const WeaponMaxAmmo =							100;
const WeaponAmmoIndex =							31;
#if defined _reapi_included
	new const WeaponAmmoName[ ] =				"ammo_divinetitan";
	const WeaponWeight =						1;
#endif

const WeaponSlot =								4;
const WeaponPosition =							5;

/**
 * The Guardian Eye & Light of Judgment gives +1 for each victim hit
 */
const WeaponAttacksCountToModeC =				30;
const Float: WeaponTimeOfAddition =				0.2;
const Float: WeaponTimeOfDeduction =			0.2;

/* ~ [ Guardian Eye ] ~ */
/**
 * I do not advise reducing this value if your server is 
 * already voracious to server resources (RAM, CPU)
 */
const Float: GuardianEyeRate =					0.3;
const Float: GuardianEyeDamage =				210.0;
const GuardianEyeDamageType =					( DMG_BULLET|DMG_NEVERGIB );

/* ~ [ Light Of Judgment ] ~ */
const Float: LightOfJudgmentRate =				0.65;
const Float: LightOfJudgmentRadius =			150.0;
const Float: LightOfJudgmentDamage =			600.0;
const LightOfJudgmentDamageType =				( DMG_BULLET|DMG_NEVERGIB );

/* ~ [ Wrathful Strike ] ~ */
const Float: WrathfulStrikeRate =				0.1;
const Float: WrathfulStrikeRadius =				250.0;
new const Float: WrathfulStrikeDamage[ ] = {
	400.0, // Catch damage
	1500.0 // Last damage
};
const WrathfulStrikeDamageType =				( DMG_GRENADE|DMG_NEVERGIB );

/* ~ [ Entity: Guardian Eye ] ~ */
new const EntityGuardianEyeReference[ ] =		"env_spark";
new const EntityGuardianEyeClassName[ ] =		"ent_guardian_eye_x";
new const EntityGuardianEyeModel[ ] =			"models/x_re/w_divinetitan.mdl";
const Float: EntityGuardianEyeRadius =			250.0;
const Float: EntityGuardianEyeNextThink =		0.1;

/* ~ [ Entity: Light Of Judgment ] ~ */
new const EntityLoJReference[ ] =				"env_spark";
new const EntityLoJClassName[ ] =				"ent_loj_x";
new const EntityLoJModel[ ] =					"models/x_re/divinetitan_missile.mdl";
new const EntityLoJSprite[ ] =					"sprites/x_re/ef_divinetitan_bmode_explo.spr";
const Float: EntityLoJSpeed =					1500.0;
const EntityLoJExplosionFrameRate =				32;
const EntityLoJExplosionScale =					24;

/* ~ [ Entity: Wrathful Strike ] ~ */
new const EntityWrathfulStrikeReference[ ] =	"env_spark";
new const EntityWrathfulStrikeClassName[ ] =	"ent_titan_x";
new const EntityWrathfulStrikeModel[ ] =		"models/x_re/ef_divinetitan_summon.mdl";
new const EntityWrathfulStrikeSprites[ ][ ] = {
	"sprites/x_re/ef_divinetitan_summon0.spr",
	"sprites/x_re/ef_divinetitan_summon1.spr",
	"sprites/x_re/ef_divinetitan_summon2.spr"
};
const Float: EntityWrathfulStrikeNextThink =	0.1;
const Float: EntityWrathfulStrikeLifeTime =		3.0; // This value from model
const Float: EntityWrathfulStrikeSpeed =		1500.0;
const Float: EntityWrathfulStrikeCatchSpeed =	500.0;

/* ~ [ Entity: Guardian Eye Field ] ~ */
new const EntityFieldReference[ ] =				"env_spark";
new const EntityFieldClassName[ ] =				"ent_ft_field_x";
new const EntityFieldModel[ ] =					"models/x_re/ef_divinetitan_amode.mdl";

/* ~ [ Effect: Guardian Eye ] ~ */
new const BeamEffectSprite[ ] =					"sprites/x_re/ef_divinetitan_amode.spr";
const BeamEffectWidth = 						255; // Values: 1-255 | Any value: Don't show
const BeamEffectFrameRate =						128;
#define BeamEffectLifeTime						( floatround( GuardianEyeRate * 10.0 ) + 1 )
const BeamEffectBirghtness =					200;

/* ~ [ Effect: Guardian Eye ] ~ */
new const ExplosionEffectSprite[ ] =			"sprites/x_re/ef_divinetitan_amode_hit.spr";
const ExplosionEffectScale =					16;
const ExplosionEffectFrameRate =				16;

#if defined _api_muzzleflash_included
	/* ~ [ Muzzle Flashes ] ~ */
	new const MuzzleFlashSprites[ ][ ] = {
		"sprites/x_re/muzzleflash248.spr",
		"sprites/x_re/muzzleflash252.spr",
		"sprites/x_re/muzzleflash251.spr",
		"sprites/x_re/muzzleflash250.spr",
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Dummy,
	WeaponAnim_IdleDefault,
	WeaponAnim_PullPinn,
	WeaponAnim_IdlePullPinn,
	WeaponAnim_Throw,
	WeaponAnim_DrawDefault,
	WeaponAnim_StartModeA,
	WeaponAnim_IdleModeA,
	WeaponAnim_EndModeA,
	WeaponAnim_DrawModeA,
	WeaponAnim_ModeAtoB,
	WeaponAnim_IdleModeB,
	WeaponAnim_EndModeB,
	WeaponAnim_DrawModeB,
	WeaponAnim_ModeBtoA,
	WeaponAnim_StartModeB
};

const Float: WeaponAnim_IdleDefault_Time =		3.0; // Default Idle
const Float: WeaponAnim_IdleModeAB_Time =		2.0; // Mode A/B Idle
const Float: WeaponAnim_PullPinn_Time =			0.37;
const Float: WeaponAnim_IdlePullPinn_Time =		0.33;
const Float: WeaponAnim_Throw_Time =			0.5;
const Float: WeaponAnim_Draw_Time =				1.0;
const Float: WeaponAnim_StartModeAB_Time =		0.7;
const Float: WeaponAnim_SwitchMode_Time =		0.53;
const Float: WeaponAnim_EndModeAB_Time =		0.5;

/* ~ [ Params ] ~ */
enum {
	Sound_ModeA_Loop,
	Sound_ModeA_End,
	Sound_ModeB,
	Sound_ModeB_Exp,
	Sound_Charge,
	Sound_ModeC_Exp,
	Sound_ModeC
};

enum (<<= 1) {
	WeaponState_OnModeA = 1,
	WeaponState_OnModeB,

	WeaponState_HoldModeC,
	WeaponState_ThrowModeC,

	WeaponState_HasModeC
};

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif
new gl_iMaxPlayers;
new bool: gl_bRoundEnded;
new HamHook: gl_HamHook_TakeDamage_Pre;

enum {
	ModelIndex_LaserBeam,
	ModelIndex_Exp_ModeA,
	ModelIndex_Exp_ModeB,

	ModelIndex_Spawn_ModeC,
	ModelIndex_Post_ModeC,
	ModelIndex_Exp_ModeC,

	ModelIndex_List
};
new gl_iszModelIndex[ ModelIndex_List ];

#if defined _api_muzzleflash_included
	enum {
		MuzzleFlash: Muzzle_Deploy,
		MuzzleFlash: Muzzle_Idle_Default,
		MuzzleFlash: Muzzle_Idle_ModeA,
		MuzzleFlash: Muzzle_Idle_ModeB,

		Muzzle_List
	};
	new MuzzleFlash: gl_iMuzzleFlash[ Muzzle_List ];
#endif

/* ~ [ Macroses ] ~ */
#if !defined _reapi_included
	#define NULLENT								FM_NULLENT
	#define PDATA_SAFE							2
	#define MAX_ITEM_TYPES						6
	#define ACT_RANGE_ATTACK1					28

	new iWeaponList[ ] = {
		//6, 100,-1, -1, 0, 13,7, 0 // weapon_mac10
		//6, 100,-1, -1, 0, 15,12, 0 // weapon_ump45
		10, 120,-1, -1, 0, 11,23, 0 // weapon_tmp
		//7, 100, -1, -1, 0, 8, 30, 0 // weapon_p90
	};

	// EntVars
	#define get_entvar							pev
	#define set_entvar							set_pev

	#define var_impulse							pev_impulse
	#define var_flags							pev_flags
	#define var_impacttime						pev_impacttime
	#define var_skin							pev_skin
	#define var_gaitsequence					pev_gaitsequence
	#define var_iuser1							pev_iuser1
	#define var_iuser2							pev_iuser2
	#define var_fuser1							pev_fuser1
	#define var_fuser2							pev_fuser2
	#define var_fuser3							pev_fuser3
	#define var_viewmodel						pev_viewmodel2
	#define var_weaponmodel						pev_weaponmodel2
	#define var_body							pev_body
	#define var_owner							pev_owner
	#define var_button							pev_button
	#define var_classname						pev_classname
	#define var_movetype						pev_movetype
	#define var_solid							pev_solid
	#define var_dmg_inflictor					pev_dmg_inflictor
	#define var_nextthink						pev_nextthink
	#define var_origin							pev_origin
	#define var_velocity						pev_velocity
	#define var_angles							pev_angles
	#define var_bInDuck							pev_bInDuck
	#define var_ltime							pev_ltime
	#define var_renderfx						pev_renderfx
	#define var_rendercolor						pev_rendercolor
	#define var_rendermode						pev_rendermode
	#define var_renderamt						pev_renderamt
	#define var_frame							pev_frame
	#define var_framerate						pev_framerate
	#define var_animtime						pev_animtime
	#define var_sequence						pev_sequence
	#define var_weaponanim						pev_weaponanim
	#define var_v_angle							pev_v_angle
	#define var_punchangle						pev_punchangle
	#define var_view_ofs						pev_view_ofs
	#define var_takedamage						pev_takedamage
	#define var_weapons							pev_weapons

	// Offsets
	const linux_diff_weapon =					4;
	const linux_diff_animating =				4;
	const linux_diff_player =					5;

	const m_flFrameRate =						36;
	const m_flGroundSpeed =						37;
	const m_flLastEventCheck =					38;
	const m_fSequenceFinished =					39;
	const m_fSequenceLoops =					40;
	const m_pPlayer =							41;
	const m_pNext = 							42;
	const m_iId = 								43;
	const m_Weapon_flNextPrimaryAttack =		46;
	const m_Weapon_flNextSecondaryAttack =		47;
	const m_Weapon_flTimeWeaponIdle =			48;
	const m_Weapon_iPrimaryAmmoType =			49;
	const m_Weapon_iClip =						51;
	const m_Weapon_iGlock18ShotsFired =			70;
	const m_Activity =							73;
	const m_IdealActivity =						74;
	const m_Weapon_iWeaponState =				74;
	const m_Weapon_flDecreaseShotsFired =		76;
	const m_flNextAttack =						83;
	const m_iTeam =								114;
	const m_flLastAttackTime =					220;
	const m_rgpPlayerItems =					367;
	const m_pActiveItem =						373;
	const m_rgAmmo =							376;
	const m_szAnimExtention =					492;

	// Macroses
	#define BIT(%0)								( 1<<( %0 ) )
	#define is_nullent(%0)						( %0 == NULLENT || pev_valid( %0 ) != PDATA_SAFE )
#endif

// idk how to use AMXX version 1.8.2 and below, this is an outdated bullshit
#if AMXX_VERSION_NUM <= 183
	#define OBS_IN_EYE							4
	#define MAX_PLAYERS							32
	#define MAX_NAME_LENGTH						32
	#define MAX_RESOURCE_PATH_LENGTH			64
#endif

#if AMXX_VERSION_NUM <= 182
	#define write_coord_f(%0)					engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );

	stock Float: xs_vec_distance_2d( const Float: vec1[ ], const Float: vec2[ ] )
		return xs_sqrt( ( vec1[ 0 ] - vec2[ 0 ] ) * ( vec1[ 0 ] - vec2[ 0 ] ) +  ( vec1[ 1 ] - vec2[ 1 ] ) * ( vec1[ 1 ] - vec2[ 1 ] ) );

	stock Float: xs_vec_len_2d( const Float: vec[ ] )
		return xs_sqrt( vec[ 0 ] * vec[ 0 ] + vec[ 1 ] * vec[ 1 ] );
#endif

#define WEAPON_NOCLIP							-1

#if !defined Vector3
	#define Vector3(%0)							Float: %0[ 3 ]
#endif

#define GetWeaponAmmo(%0,%1)					get_member_ex( %0, m_rgAmmo, %1 )
#define GetWeaponState(%0)						get_member_ex( %0, m_Weapon_iWeaponState )
#define GetWeaponAmmoType(%0)					get_member_ex( %0, m_Weapon_iPrimaryAmmoType )
#define SetWeaponAmmo(%0,%1,%2)					set_member_ex( %0, m_rgAmmo, %1, %2 )
#define SetWeaponState(%0,%1)					set_member_ex( %0, m_Weapon_iWeaponState, %1 )
#define SetWeaponClip(%0,%1)					set_member_ex( %0, m_Weapon_iClip, %1 )

#define BIT_ADD(%0,%1)							( %0 |= %1 )
#define BIT_SUB(%0,%1)							( %0 &= ~%1 )
#define BIT_VALID(%0,%1)						( %0 & %1 )
#define BIT_CLEAR(%0)							( %0 = 0 )

#define FixedUnsigned16(%0,%1)					clamp( floatround( %0 * %1 ), 0, 0xFFFF )
#define IsNullString(%0)						bool: ( %0[ 0 ] == EOS )
#define IsVectorNull(%0)						bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsCustomWeapon(%0,%1)					bool: ( get_entvar( %0, var_impulse ) == %1 )
#define WeaponOnModeA(%0)						BIT_VALID( %0, WeaponState_OnModeA )
#define WeaponOnModeB(%0)						BIT_VALID( %0, WeaponState_OnModeB )
#define WeaponOnModes(%0)						( ( WeaponOnModeA( %0 ) || WeaponOnModeB( %0 ) ) ? true : false )

#define m_Weapon_iHitCount						m_Weapon_iGlock18ShotsFired // CWeapon
#define m_Weapon_flTimeSpent					m_Weapon_flDecreaseShotsFired // CWeapon

#define var_next_sound 							var_impacttime // CWeapon, CEntity
#define var_cached_entity 						var_iuser2 // CWeapon, CEntity
#define var_cached_muzzle 						var_gaitsequence // CWeapon
#define var_titan_state 						var_iuser1 // CEntity
#define var_attack_time 						var_fuser1 // CEntity
#define var_cached_attack_time 					var_fuser2 // CEntity
#define var_next_state 							var_fuser3 // CEntity

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native("exhero_titan_double_ammo", "Exhero_DoubleAmmo");
    register_native("exhero_titan_refill", "Exhero_Refill");

	register_native( WeaponNative, "native_give_user_weapon" );
}

public plugin_precache( )
{
    precache_generic("sound/weapons/divinetitan_A_mod_start.wav");
    precache_generic("sound/weapons/divinetitan_draw.wav");
    precache_generic("sound/weapons/divinetitan_mod_end.wav");
    precache_generic("sound/weapons/divinetitan_pullpin.wav");
    precache_generic("sound/weapons/divinetitan_throw.wav");

    Exhero_PrecacheModelSounds();
	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, EntityGuardianEyeModel );
	engfunc( EngFunc_PrecacheModel, EntityLoJModel );
	engfunc( EngFunc_PrecacheModel, EntityWrathfulStrikeModel );
	engfunc( EngFunc_PrecacheModel, EntityFieldModel );

	/* -> Precache Sound <- */
	for ( new i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if !defined _reapi_included
	// Model-event sounds are included in exhero resource manifest.
#endif

#if defined WeaponListDir
	/* -> Precache Generic <- */
	UTIL_PrecacheWeaponList( WeaponListDir );

	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );
    register_clcmd("divinetitanhud", "ClientCommand__HookWeapon"); // Legacy HUD alias
#endif

	/* -> Model Index <- */
	gl_iszModelIndex[ ModelIndex_LaserBeam ] = engfunc( EngFunc_PrecacheModel, BeamEffectSprite );
	gl_iszModelIndex[ ModelIndex_Exp_ModeA ] = engfunc( EngFunc_PrecacheModel, ExplosionEffectSprite );
	gl_iszModelIndex[ ModelIndex_Exp_ModeB ] = engfunc( EngFunc_PrecacheModel, EntityLoJSprite );

	for ( new i = 0; i < sizeof EntityWrathfulStrikeSprites; i++ )
		gl_iszModelIndex[ ModelIndex_Spawn_ModeC + i ] = engfunc( EngFunc_PrecacheModel, EntityWrathfulStrikeSprites[ i ] );

#if defined _api_muzzleflash_included
	/* -> Muzzle Flash <- */
	gl_iMuzzleFlash[ Muzzle_Deploy ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Deploy ], 0.2, 4, 0.5 );
	gl_iMuzzleFlash[ Muzzle_Idle_Default ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Idle_Default ], 0.1, 1, 0.5, MuzzleFlashFlag_Cyclical );
	gl_iMuzzleFlash[ Muzzle_Idle_ModeA ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Idle_ModeA ], 0.15, 3, 0.5, MuzzleFlashFlag_Cyclical );
	gl_iMuzzleFlash[ Muzzle_Idle_ModeB ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Idle_ModeB ], 0.15, 3, 0.5, MuzzleFlashFlag_Cyclical );
#endif
}

public plugin_init( )
{
	// https://cso.fandom.com/wiki/Sandalphon
	register_plugin( "[ZP] Weapon: Sandalphon", "1.2-exhero1", "Yoshioka Haruki" );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );
	register_message(get_user_msgid("WeaponList"), "Exhero_TitanWeaponList");

#if defined _reapi_included
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_RoundEnd, "RG_RoundEnd_Post", true );
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "RG_CSGameRules__CleanUpMap_Post", true );
#else
	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
	register_event( "TextMsg", "EV_RestartGame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in" );
#endif

	register_logevent( "EV_RoundEnd", 2, "1=Round_End" );

	/* -> HamSandwich <- */
#if defined _reapi_included
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif
	RegisterHam( Ham_Item_ItemSlot, WeaponReference, "Ham_CWeapon_Slot_Pre", true );
	RegisterHam( Ham_CS_Item_CanDrop, WeaponReference, "Ham_CWeapon_CanDrop_Pre", true );
	RegisterHam(Ham_Item_Deploy, WeaponReference, "Exhero_Deploy_Pre", false);
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Exhero_AddToHero_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

	/**
	 * Because in the original, the weapon can be charged/discharged while it is not in the hands
	 */
	RegisterHam( Ham_Killed, "player", "Ham_CPlayer_Killed_Post", true );
	RegisterHam( Ham_Player_PreThink, "player", "Ham_CPlayer_PreThink_Post", true );

	RegisterHam( Ham_RemovePlayerItem, "player", "Ham_CPlayer_RemoveItem_Pre", false );
	DisableHamForward( gl_HamHook_TakeDamage_Pre = RegisterHam( Ham_TakeDamage, "player", "Ham_CPlayer_TakeDamage_Pre", false ) );

#if !defined _reapi_included
	RegisterHam( Ham_Think, EntityGuardianEyeReference, "Ham_CEntity_Think_Post", true );
	RegisterHam( Ham_Touch, EntityGuardianEyeReference, "Ham_CEntity_Touch_Pre", false );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	//gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

	/* -> Other <- */
#if defined _reapi_included
	gl_iMaxPlayers = get_member_game( m_nMaxPlayers );
#else
	gl_iMaxPlayers = get_maxplayers( );
#endif
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer )
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

#if defined _zombieplague_included
	/* ~ [ Zombie Plague ] ~ */
	#if defined ExtraItem_Name
public zp_extra_item_selected(pPlayer, iItemId) { return PLUGIN_CONTINUE; }
	#endif

	public zp_user_infected_pre( pPlayer )
	{
	Exhero_Cleanup(pPlayer);

		if ( !is_user_connected( pPlayer ) )
			return;

		static pItem; pItem = UTIL_GetItemByName( pPlayer, WeaponReference );
		if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
		if ( !is_nullent( pCachedEntity ) )
			CGuardianEye__DestroyEntity( pCachedEntity );

		UTIL_StripWeaponByIndex( pPlayer, pItem );
	}
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
#if !defined EnableSubmodelSupport
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member_ex( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
#else
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !is_user_connected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member_ex( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );

	enum eSpecInfo {
		SPEC_MODE,
		SPEC_TARGET
	};
	static aSpecInfo[ MAX_PLAYERS + 1 ][ eSpecInfo ];

	if ( iSpecMode )
	{
		if ( aSpecInfo[ pPlayer ][ SPEC_MODE ] != iSpecMode )
		{
			aSpecInfo[ pPlayer ][ SPEC_MODE ] = iSpecMode;
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = 0;
		}

		if ( iSpecMode == OBS_IN_EYE && aSpecInfo[ pPlayer ][ SPEC_TARGET ] != pTarget )
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = pTarget;
	}

	static Float: flLastEventCheck; flLastEventCheck = get_member_ex( pActiveItem, m_flLastEventCheck );
	if ( !flLastEventCheck )
	{
		set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_Dummy );
		return;
	}

	if ( flLastEventCheck <= get_gametime( ) )
	{
		static bitsWeaponState; bitsWeaponState = GetWeaponState( pActiveItem );

		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, 
			WeaponOnModeA( bitsWeaponState ) ? WeaponAnim_DrawModeA : 
			WeaponOnModeB( bitsWeaponState ) ? WeaponAnim_DrawModeB : 
			WeaponAnim_DrawDefault );
		set_member_ex( pActiveItem, m_flLastEventCheck, 0.0 );
	}
#endif
}

#if defined _reapi_included
	/* ~ [ ReGameDLL ] ~ */
	public RG_RoundEnd_Post( const WinStatus: iWinStatus, const ScenarioEventEndRound: iEvent )
	{
		if ( iEvent == ROUND_GAME_RESTART || iEvent == ROUND_GAME_COMMENCE )
		{
			for ( new pPlayer = 1, pEntity, pItem; pPlayer <= gl_iMaxPlayers; pPlayer++ )
			{
				if ( !is_user_connected( pPlayer ) )
					continue;

				if ( ( pItem = UTIL_GetItemByName( pPlayer, WeaponReference ) ) && !is_nullent( pItem ) && IsCustomWeapon(pItem, WeaponUnicalIndex) )
				{
					if ( ( pEntity = get_entvar( pItem, var_cached_entity ) ) && !is_nullent( pEntity ) )
						CGuardianEye__DestroyEntity( pEntity );

					UTIL_StripWeaponByIndex( pPlayer, pItem );
				}
			}
		}
	}

	public RG_CSGameRules__CleanUpMap_Post( )
	{
		gl_bRoundEnded = false;

		UTIL_DestroyEntitiesByClass( EntityLoJClassName );
		UTIL_DestroyEntitiesByClass( EntityWrathfulStrikeClassName );
	}
#else
	/* ~ [ Events ] ~ */
	public EV_RoundStart( )
	{
		gl_bRoundEnded = false;

		UTIL_DestroyEntitiesByClass( EntityLoJClassName );
		UTIL_DestroyEntitiesByClass( EntityWrathfulStrikeClassName );
	}

	public EV_RestartGame( )
	{
		for ( new pPlayer = 1, pEntity, pItem; pPlayer <= gl_iMaxPlayers; pPlayer++ )
		{
			if ( !is_user_connected( pPlayer ) )
				continue;

			if ( ( pItem = UTIL_GetItemByName( pPlayer, WeaponReference ) ) && !is_nullent( pItem ) && IsCustomWeapon(pItem, WeaponUnicalIndex) )
			{
				if ( ( pEntity = get_entvar( pItem, var_cached_entity ) ) && !is_nullent( pEntity ) )
					CGuardianEye__DestroyEntity( pEntity );

				UTIL_StripWeaponByIndex( pPlayer, pItem );
			}
		}
	}
#endif

public EV_RoundEnd( ) { gl_bRoundEnded = true; Exhero_Cleanup(); }

/* ~ [ HamSandwich ] ~ */
#if defined _reapi_included
	public Ham_CWeapon_Spawn_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		SetWeaponClip( pItem, WEAPON_NOCLIP );

		set_member( pItem, m_Weapon_iPrimaryAmmoType, WeaponAmmoIndex );
		set_member( pItem, m_Weapon_iSecondaryAmmoType, -1 );
		set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

	#if defined WeaponListDir
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
	#endif
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
		rg_set_iteminfo( pItem, ItemInfo_pszAmmo1, WeaponAmmoName );
		rg_set_iteminfo( pItem, ItemInfo_iSlot, WeaponSlot - 1 );
		rg_set_iteminfo( pItem, ItemInfo_iPosition, WeaponPosition );
		rg_set_iteminfo( pItem, ItemInfo_iWeight, WeaponWeight );
	}
#endif

public Ham_CWeapon_Slot_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	SetHamReturnInteger( WeaponSlot );
	return HAM_OVERRIDE;
}

public Ham_CWeapon_CanDrop_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	SetHamReturnInteger( false );
	return HAM_OVERRIDE;
}

public Ham_CWeapon_Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || get_member_ex(pPlayer,m_pActiveItem)!=pItem) return ;
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

    UTIL_WeaponList(MSG_ONE,pPlayer,pItem,WeaponListDir,WeaponAmmoIndex,WeaponMaxAmmo,-1,-1,WeaponSlot-1,WeaponPosition,CSW_TMP,0);
	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponOnModes( bitsWeaponState ) ? "" : WeaponModelPlayer );

#if defined EnableSubmodelSupport
	set_entvar( pItem, var_body, WeaponHandSubmodel );
	set_member_ex( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );
#else
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, 
		WeaponOnModeA( bitsWeaponState ) ? WeaponAnim_DrawModeA : 
		WeaponOnModeB( bitsWeaponState ) ? WeaponAnim_DrawModeB : 
		WeaponAnim_DrawDefault );
#endif

#if defined _api_muzzleflash_included
	if ( !WeaponOnModes( bitsWeaponState ) )
		zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ Muzzle_Deploy ] );
#endif

	set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time );
	set_member_ex( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
#if defined _reapi_included
	set_member( pPlayer, m_szAnimExtention, WeaponAnimation );
#else
	set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation, -1, linux_diff_player * linux_diff_animating );
#endif
}

public Ham_CWeapon_Holster_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_ThrowModeC );
 		BIT_SUB( bitsWeaponState, WeaponState_HoldModeC );

 		SetWeaponState( pItem, bitsWeaponState );
	}

#if defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) )
		zc_muzzle_destroy( pPlayer );

	set_entvar( pItem, var_cached_muzzle, NULLENT );
#endif

	set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member_ex( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
	#if !defined _reapi_included
		SetWeaponClip( pItem, WEAPON_NOCLIP );
		set_member_ex( pItem, m_Weapon_iPrimaryAmmoType, WeaponAmmoIndex );
	#endif

		static iAmmoType; iAmmoType = GetWeaponAmmoType( pItem );
		SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );
	}

#if !defined _reapi_included
	static szWeaponList[ MAX_NAME_LENGTH ];
	#if defined WeaponListDir
		copy( szWeaponList, charsmax( szWeaponList ), WeaponListDir );
	#else
		copy( szWeaponList, charsmax( szWeaponList ), WeaponReference );
	#endif

	UTIL_WeaponList( MSG_ONE, pPlayer, pItem, szWeaponList, WeaponAmmoIndex, WeaponMaxAmmo, .iSlot = WeaponSlot - 1, .iPosition = WeaponPosition );
#else
	UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
#endif
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || get_member_ex(pPlayer,m_pActiveItem)!=pItem) return HAM_SUPERCEDE;

#if !defined _reapi_included
	static bitsButton; bitsButton = get_entvar( pPlayer, var_button );
	if ( bitsButton & IN_ATTACK2 && Float: get_member_ex( pItem, m_Weapon_flNextSecondaryAttack ) < 0.0 )
	{
		bitsButton &= ~IN_ATTACK2;
		set_entvar( pPlayer, var_button, bitsButton );

		ExecuteHamB( Ham_Weapon_SecondaryAttack, pItem );
	}
#endif

	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		if ( BIT_VALID( bitsWeaponState, WeaponState_ThrowModeC ) )
		{
			BIT_CLEAR( bitsWeaponState );
			SetWeaponState( pItem, bitsWeaponState );

		#if defined _api_muzzleflash_included
			CWeapon__UpdateIdleMuzzleFlash( pPlayer, pItem, bitsWeaponState );
		#endif

			ExecuteHamB( Ham_Item_Deploy, pItem );
		}
		else if ( BIT_VALID( bitsWeaponState, WeaponState_HoldModeC ) )
		{
		#if defined _reapi_included
			static bitsButton; bitsButton = get_entvar( pPlayer, var_button );
		#endif
			if ( ~bitsButton & IN_RELOAD )
			{
				static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
				if ( !is_nullent( pCachedEntity ) )
					CGuardianEye__DestroyEntity( pCachedEntity );

				set_entvar( pItem, var_cached_entity, NULLENT );

				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Throw );

				BIT_SUB( bitsWeaponState, WeaponState_OnModeA );
				BIT_SUB( bitsWeaponState, WeaponState_OnModeB );
				BIT_SUB( bitsWeaponState, WeaponState_HoldModeC );
                BIT_SUB( bitsWeaponState, WeaponState_HasModeC );
                BIT_ADD( bitsWeaponState, WeaponState_ThrowModeC );

				SetWeaponState( pItem, bitsWeaponState );
				SetWeaponClip( pItem, WEAPON_NOCLIP );

				set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Throw_Time );
				set_member_ex( pPlayer, m_flNextAttack, WeaponAnim_Throw_Time );

			#if defined _reapi_included
				set_member( pPlayer, m_szAnimExtention, "grenade" );
				rg_set_animation( pPlayer, PLAYER_ATTACK1 );
			#else
				set_pdata_string( pPlayer, m_szAnimExtention * 4, "grenade", -1, linux_diff_player * linux_diff_animating );

				static szAnimation[ 32 ];
				formatex( szAnimation, charsmax( szAnimation ), "%s_shoot_%s", ( get_entvar( pPlayer, var_flags ) & FL_DUCKING ) ? "crouch" : "ref", "grenade" );

				UTIL_PlayerAnimation( pPlayer, szAnimation );
			#endif
				set_entvar( pPlayer, var_weaponmodel, "" );

				CWrathfulStrike__SpawnEntity( pPlayer, pItem );
			}
		}
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_Reload_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	// Only a pending pull/throw animation blocks another reload; idle does not.
	if ( (BIT_VALID(GetWeaponState(pItem), WeaponState_HoldModeC) || BIT_VALID(GetWeaponState(pItem), WeaponState_ThrowModeC)) && Float: get_member_ex( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_SUPERCEDE;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( !BIT_VALID( bitsWeaponState, WeaponState_HasModeC ) )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || get_member_ex(pPlayer,m_pActiveItem)!=pItem) return HAM_SUPERCEDE;
	if ( !BIT_VALID( bitsWeaponState, WeaponState_HoldModeC ) )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_PullPinn );

		BIT_ADD( bitsWeaponState, WeaponState_HoldModeC );
		SetWeaponState( pItem, bitsWeaponState );

		set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_PullPinn_Time );
		set_member_ex( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_PullPinn_Time );
		set_member_ex( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_PullPinn_Time );
	}
	else
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_IdlePullPinn );

		set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_IdlePullPinn_Time );
		set_member_ex( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_IdlePullPinn_Time );
		set_member_ex( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_IdlePullPinn_Time );
	}

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member_ex( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || get_member_ex(pPlayer,m_pActiveItem)!=pItem) return HAM_SUPERCEDE;
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, 
		WeaponOnModeA( bitsWeaponState ) ? WeaponAnim_IdleModeA :
		WeaponOnModeB( bitsWeaponState ) ? WeaponAnim_IdleModeB :
		WeaponAnim_IdleDefault );
	set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_IdleDefault_Time );

#if defined _api_muzzleflash_included
	static pCachedMuzzle; pCachedMuzzle = get_entvar( pItem, var_cached_muzzle );
	if ( is_nullent( pCachedMuzzle ) )
		CWeapon__UpdateIdleMuzzleFlash( pPlayer, pItem, bitsWeaponState );
#endif

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( gl_bRoundEnded )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
 if(!is_user_alive(pPlayer)||zp_get_user_zombie(pPlayer)||get_member_ex(pPlayer,m_pActiveItem)!=pItem)return HAM_SUPERCEDE;
 if(Float:get_member_ex(pPlayer,m_flNextAttack)>0.0)return HAM_SUPERCEDE;
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	static Float: flNextAttack, iAnim;

	if ( WeaponOnModeA( bitsWeaponState ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_OnModeA );
		iAnim = WeaponAnim_EndModeA;
		flNextAttack = WeaponAnim_EndModeAB_Time;
	}
	else if ( WeaponOnModeB( bitsWeaponState ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_OnModeB );
		BIT_ADD( bitsWeaponState, WeaponState_OnModeA );
		iAnim = WeaponAnim_ModeBtoA;
		flNextAttack = WeaponAnim_SwitchMode_Time;
	}
	else
	{
		BIT_ADD( bitsWeaponState, WeaponState_OnModeA );
		iAnim = WeaponAnim_StartModeA;
		flNextAttack = WeaponAnim_StartModeAB_Time;
	}

#if defined _api_muzzleflash_included
	CWeapon__UpdateIdleMuzzleFlash( pPlayer, pItem, bitsWeaponState );
#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnim );
	set_entvar( pPlayer, var_weaponmodel, WeaponOnModes( bitsWeaponState ) ? "" : WeaponModelPlayer );

	if ( WeaponOnModes( bitsWeaponState ) )
		set_entvar( pItem, var_cached_entity, CGuardianEye__SpawnEntity( pPlayer, pItem, true ) );
	else
	{
		static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
		if ( !is_nullent( pCachedEntity ) )
			CGuardianEye__DestroyEntity( pCachedEntity );

		set_entvar( pItem, var_cached_entity, NULLENT );
	}

	BIT_SUB( bitsWeaponState, WeaponState_HoldModeC );
	BIT_SUB( bitsWeaponState, WeaponState_ThrowModeC );

	SetWeaponState( pItem, bitsWeaponState );
	set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, flNextAttack );
	set_member_ex( pPlayer, m_flNextAttack, flNextAttack );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( gl_bRoundEnded )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member_ex( pItem, m_pPlayer );
 if(!is_user_alive(pPlayer)||zp_get_user_zombie(pPlayer)||get_member_ex(pPlayer,m_pActiveItem)!=pItem)return HAM_SUPERCEDE;
 if(Float:get_member_ex(pPlayer,m_flNextAttack)>0.0)return HAM_SUPERCEDE;
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	static Float: flNextAttack, iAnim;

	if ( WeaponOnModeB( bitsWeaponState ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_OnModeB );
		iAnim = WeaponAnim_EndModeB;
		flNextAttack = WeaponAnim_EndModeAB_Time;
	}
	else if ( WeaponOnModeA( bitsWeaponState ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_OnModeA );
		BIT_ADD( bitsWeaponState, WeaponState_OnModeB );
		iAnim = WeaponAnim_ModeAtoB;
		flNextAttack = WeaponAnim_SwitchMode_Time;
	}
	else
	{
		BIT_ADD( bitsWeaponState, WeaponState_OnModeB );
		iAnim = WeaponAnim_StartModeB;
		flNextAttack = WeaponAnim_StartModeAB_Time;
	}

#if defined _api_muzzleflash_included
	CWeapon__UpdateIdleMuzzleFlash( pPlayer, pItem, bitsWeaponState );
#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnim );
	set_entvar( pPlayer, var_weaponmodel, WeaponOnModes( bitsWeaponState ) ? "" : WeaponModelPlayer );

	if ( WeaponOnModes( bitsWeaponState ) )
		set_entvar( pItem, var_cached_entity, CGuardianEye__SpawnEntity( pPlayer, pItem, false ) );
	else
	{
		static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
		if ( !is_nullent( pCachedEntity ) )
			CGuardianEye__DestroyEntity( pCachedEntity );

		set_entvar( pItem, var_cached_entity, NULLENT );
	}

	BIT_SUB( bitsWeaponState, WeaponState_HoldModeC );
	BIT_SUB( bitsWeaponState, WeaponState_ThrowModeC );

	SetWeaponState( pItem, bitsWeaponState );
	set_member_ex( pItem, m_Weapon_flTimeWeaponIdle, flNextAttack );
	set_member_ex( pPlayer, m_flNextAttack, flNextAttack );

	return HAM_SUPERCEDE;
}

public Ham_CPlayer_Killed_Post( const pVictim )
{
	Exhero_Cleanup(pVictim);

	static pItem; pItem = UTIL_GetItemByName( pVictim, WeaponReference );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pEntity;
	if ( ( pEntity = get_entvar( pItem, var_cached_entity ) ) && !is_nullent( pEntity ) )
		CGuardianEye__DestroyEntity( pEntity );
}

public Ham_CPlayer_PreThink_Post( const pPlayer )
{
	if (is_user_alive(pPlayer) && revo_get_user_hero(pPlayer))
	{
		if (!g_heroCleaned[pPlayer]) Exhero_RemoveTitan(pPlayer);
		return;
	}

	g_heroCleaned[pPlayer] = false;
	if ( !is_user_alive( pPlayer ) )
		return;

#if defined _zombieplague_included
	if ( zp_get_user_zombie( pPlayer ) )
		return;
#endif

	static pItem; pItem = UTIL_GetItemByName( pPlayer, WeaponReference );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flTimeSpent; flTimeSpent = get_member_ex( pItem, m_Weapon_flTimeSpent );
	if ( flTimeSpent >= flGameTime )
		return;

	static iAmmoType; iAmmoType = GetWeaponAmmoType( pItem );
	static iAmmo; iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

	if ( WeaponOnModes( bitsWeaponState ) )
	{
		iAmmo = max(0, iAmmo - 1);
		if ( !iAmmo || gl_bRoundEnded )
		{
			static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
			if ( !is_nullent( pCachedEntity ) )
				CGuardianEye__DestroyEntity( pCachedEntity );

			set_entvar( pItem, var_cached_entity, NULLENT );

			static pActiveItem;
			if ( ( pActiveItem = get_member_ex( pPlayer, m_pActiveItem ) ) && !is_nullent( pActiveItem ) && pItem == pActiveItem )
			{
			#if defined _api_muzzleflash_included
				CWeapon__UpdateIdleMuzzleFlash( pPlayer, pActiveItem, bitsWeaponState );
			#endif

				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pActiveItem, WeaponOnModeA( bitsWeaponState ) ? WeaponAnim_EndModeA : WeaponAnim_EndModeB );

				set_member_ex( pActiveItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_EndModeAB_Time );
				set_member_ex( pActiveItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_EndModeAB_Time );
				set_member_ex( pActiveItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_EndModeAB_Time );
			}

			BIT_SUB( bitsWeaponState, WeaponState_OnModeA );
			BIT_SUB( bitsWeaponState, WeaponState_OnModeB );

			SetWeaponState( pItem, bitsWeaponState );
		}

		SetWeaponAmmo( pPlayer, iAmmo, iAmmoType );
		set_member_ex( pItem, m_Weapon_flTimeSpent, flGameTime + WeaponTimeOfDeduction );
	}
	else
	{
		// Titan passively regenerates one energy every 0.2 seconds, capped at 100.
        if(!gl_bRoundEnded && iAmmo < WeaponMaxAmmo) SetWeaponAmmo(pPlayer, iAmmo + 1, iAmmoType);

		set_member_ex( pItem, m_Weapon_flTimeSpent, flGameTime + WeaponTimeOfAddition );
	}
}

public Ham_CPlayer_RemoveItem_Pre( const pPlayer, const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

#if defined _api_muzzleflash_included
	if (is_user_connected(pPlayer)) zc_muzzle_destroy( pPlayer );
#endif

	static pCachedEntity; pCachedEntity = get_entvar( pItem, var_cached_entity );
	if ( !is_nullent( pCachedEntity ) )
		CGuardianEye__DestroyEntity( pCachedEntity );

	set_entvar( pItem, var_cached_entity, NULLENT );

	return HAM_IGNORED;
}

public Ham_CPlayer_TakeDamage_Pre( const pVictim, const pInflictor, const pAttacker, const Float: flDamage )
{
#if defined UseWeaponAsMethodDamage
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
#else
	if ( is_nullent( pInflictor ) )
#endif
		return HAM_SUPERCEDE;

	if ( pVictim == pAttacker || !rg_is_player_can_takedamage( pVictim, pAttacker ) )
		return HAM_SUPERCEDE;

#if !defined UseWeaponAsMethodDamage
	if ( IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
#endif
	{
		static bitsWeaponState;
		if ( ( bitsWeaponState = GetWeaponState( pInflictor ) ) && WeaponOnModes( bitsWeaponState ) && !BIT_VALID( bitsWeaponState, WeaponState_HasModeC ) )
		{
			static iHitCount; iHitCount = get_member_ex( pInflictor, m_Weapon_iHitCount );
			if ( ++iHitCount && iHitCount >= WeaponAttacksCountToModeC )
			{
				rg_emit_sound( pAttacker, CHAN_WEAPON, WeaponSounds[ Sound_Charge ] );
				UTIL_ScreenFade( MSG_ONE, pAttacker, 0.5, 0.5, 0x0000, { 255, 215, 0 }, 64 );

				BIT_ADD( bitsWeaponState, WeaponState_HasModeC );
				SetWeaponState( pInflictor, bitsWeaponState );
				SetWeaponClip( pInflictor, 1 );
				iHitCount = 0;
			}

			set_member_ex( pInflictor, m_Weapon_iHitCount, iHitCount );
		}
	}

	return HAM_IGNORED;
}

#if !defined _reapi_included
	public Ham_CEntity_Touch_Pre( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityLoJClassName ) )
			CLightOfJudgment__Touch( pEntity, pTouch );

		if ( FClassnameIs( pEntity, EntityWrathfulStrikeClassName ) && get_entvar( pEntity, var_movetype ) == MOVETYPE_FLY )
			CWrathfulStrike__Touch( pEntity, pTouch );
	}

	public Ham_CEntity_Think_Post( const pEntity )
	{
    if (pev_valid(pEntity) && (FClassnameIs(pEntity, EntityLoJClassName) || (FClassnameIs(pEntity, EntityWrathfulStrikeClassName) && get_entvar(pEntity, var_movetype) == MOVETYPE_FLY)))
    {
        if (UTIL_InvalidEntityOwner(pEntity, pev(pEntity, pev_owner))) return;
        new Float:expiry; pev(pEntity, pev_fuser4, expiry);
        if (get_gametime() >= expiry) UTIL_KillEntity(pEntity);
        else set_pev(pEntity, pev_nextthink, get_gametime() + 0.5);
        return;
    }

		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityGuardianEyeClassName ) )
			CGuardianEye__Think( pEntity );

		if ( FClassnameIs( pEntity, EntityWrathfulStrikeClassName ) && get_entvar( pEntity, var_movetype ) == MOVETYPE_NONE )
			CWrathfulStrike__Think( pEntity );

		if ( FClassnameIs( pEntity, EntityFieldClassName ) )
			CField__Think( pEntity );
	}
#endif

/* ~ [ Other ] ~ */
public bool: CPlayer__GiveWeapon( const pPlayer, const szWeaponReference[ ], const iWeaponUId )
{
    if (!exhero_titan_unlocked(pPlayer) || Exhero_TitanUsers(pPlayer) >= 2) return false;
	if (gl_bRoundEnded || !is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || revo_get_user_hero(pPlayer)) return false;

	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = UTIL_GetItemByName( pPlayer, szWeaponReference );
	if ( !is_nullent( pItem ) && IsCustomWeapon( pItem, iWeaponUId ) )
	{
		client_print( pPlayer, print_center, "*** You already have [%s] ***", WeaponName );
		return false;
	}
	else
	{
	#if defined _reapi_included
		pItem = rg_give_custom_item( pPlayer, szWeaponReference, GT_APPEND, iWeaponUId );
	#else
		pItem = UTIL_GiveCustomWeapon( pPlayer, szWeaponReference, iWeaponUId );
	#endif
		if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, iWeaponUId ) )
			return false;
	}

	// Publish the final slot after AddPlayerItem/AttachToPlayer has finished.
	UTIL_WeaponList(MSG_ONE, pPlayer, pItem, WeaponListDir, WeaponAmmoIndex, WeaponMaxAmmo, -1, -1, WeaponSlot - 1, WeaponPosition, CSW_TMP, 0);
	return true;
}

#if defined _api_muzzleflash_included
	public CWeapon__UpdateIdleMuzzleFlash( const pPlayer, const pItem, const bitsWeaponState )
	{
		if (is_user_connected(pPlayer)) zc_muzzle_destroy( pPlayer );

		set_entvar( pItem, var_cached_muzzle, zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ 
			WeaponOnModeA( bitsWeaponState ) ? Muzzle_Idle_ModeA :
			WeaponOnModeB( bitsWeaponState ) ? Muzzle_Idle_ModeB :
			Muzzle_Idle_Default ] )
		);
	}
#endif

public CGuardianEye__SpawnEntity( const pPlayer, const pInflictor, const bool: bLaser )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flAttackTime; flAttackTime = bLaser ? GuardianEyeRate : LightOfJudgmentRate;

	static pEntity; pEntity = fm_find_ent_by_owner( NULLENT, EntityGuardianEyeClassName, pPlayer );

	if ( is_nullent( pEntity ) )
	{
		if ( ( pEntity = rg_create_entity( EntityGuardianEyeReference ) ) && is_nullent( pEntity ) )
			return NULLENT;
	}
	else
	{
		UTIL_ResetTimingSound( pEntity, pEntity );

		set_entvar( pEntity, var_cached_attack_time, flAttackTime );
		set_entvar( pEntity, var_attack_time, flGameTime + flAttackTime );
		set_entvar( pEntity, var_titan_state, bLaser );

		static pCachedEntity; pCachedEntity = get_entvar( pEntity, var_cached_entity );
		if ( !is_nullent( pCachedEntity ) )
			UTIL_KillEntity( pCachedEntity );

		set_entvar( pEntity, var_cached_entity, bLaser ? CField__SpawnEntity( pPlayer ) : NULLENT );

		return pEntity;
	}

	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );

	/**
	 * Yes, im don't use MOVETYPE_FOLLOW with var_aiment
	 * bcz me need a create Beam from Entity Attachment,
	 * but, with aiment + MOVETYPE_FOLLOW, i can't do this correctly (Thanks GoldSrc engine).
	 * Therefore, I do my movement for the entity
	 */
	set_entvar( pEntity, var_classname, EntityGuardianEyeClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_solid, SOLID_NOT );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_nextthink, flGameTime + EntityGuardianEyeNextThink );
	set_entvar( pEntity, var_origin, vecOrigin );

	set_entvar( pEntity, var_cached_entity, bLaser ? CField__SpawnEntity( pPlayer ) : NULLENT );
	set_entvar( pEntity, var_titan_state, bLaser );
	set_entvar( pEntity, var_cached_attack_time, flAttackTime );
	set_entvar( pEntity, var_attack_time, flGameTime + flAttackTime );

	engfunc( EngFunc_SetModel, pEntity, EntityGuardianEyeModel );

	UTIL_SetEntityAnim( pEntity, 1 );

#if defined _reapi_included
	SetThink( pEntity, "CGuardianEye__Think" );
#endif

	return pEntity;
}

public CGuardianEye__DestroyEntity( const pEntity )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pCachedEntity; pCachedEntity = get_entvar( pEntity, var_cached_entity );
	if ( !is_nullent( pCachedEntity ) )
		UTIL_KillEntity( pCachedEntity );

	UTIL_ResetTimingSound( pEntity, pEntity );
	UTIL_KillEntity( pEntity );
}

public CGuardianEye__Think( const pEntity )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	CGuardianEye__Move( pEntity, pOwner );
	if (!Exhero_EffectActive(pEntity) || !is_user_alive(pOwner)) return;

	static Vector3( vecAngles ); get_entvar( pOwner, var_angles, vecAngles );
	set_entvar( pEntity, var_angles, vecAngles );

	static Float: flGameTime; flGameTime = get_gametime( );
	set_entvar( pEntity, var_nextthink, flGameTime + EntityGuardianEyeNextThink );

	static Float: flAttackTime; get_entvar( pEntity, var_attack_time, flAttackTime );
	if ( flAttackTime >= flGameTime )
		return;

	static bool: bLaser; bLaser = bool: get_entvar( pEntity, var_titan_state );
	if ( bLaser )
	{
		static pLastFindedVictim;
		static pFindedVictim; pFindedVictim = UTIL_FindClosestVictim( pEntity, EntityGuardianEyeRadius );
		if ( !is_nullent( pFindedVictim ) )
		{
			pLastFindedVictim = pFindedVictim;

			UTIL_PlayTimingSound( pEntity, pEntity, WeaponSounds[ Sound_ModeA_Loop ], _, 1.5 );
			CGuardianEye__DoDamage( pOwner, pEntity, pFindedVictim, GuardianEyeDamage, GuardianEyeDamageType );
			if (!Exhero_EffectActive(pEntity)) return;

			UTIL_TE_BEAMENTS( MSG_BROADCAST, ( pEntity | 0x1000 ), pFindedVictim, gl_iszModelIndex[ ModelIndex_LaserBeam ], .iFrameRate = BeamEffectFrameRate, .iLife = BeamEffectLifeTime, .iWidth = BeamEffectWidth, .iBrightness = BeamEffectBirghtness );

			static bitsAttacked, pLastVictim; pLastVictim = pFindedVictim;
			BIT_CLEAR( bitsAttacked );
			BIT_ADD( bitsAttacked, BIT( pFindedVictim ) );

			for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
			{
				if ( !is_user_alive( pVictim ) || BIT_VALID( bitsAttacked, BIT( pVictim ) ) )
					continue;

			#if defined _zombieplague_included
				if ( !zp_get_user_zombie( pVictim ) )
			#else
				if ( IsSimilarPlayersTeam( pVictim, pOwner ) )
			#endif
					continue;

				if ( !UTIL_IsWallBetweenPoints( pVictim, pFindedVictim ) )
					continue;

				if ( UTIL_GetEntitiesDistance( pVictim, pFindedVictim ) > EntityGuardianEyeRadius )
					continue;

				CGuardianEye__DoDamage( pOwner, pEntity, pVictim, GuardianEyeDamage, GuardianEyeDamageType );
				if (!Exhero_EffectActive(pEntity)) return;
				UTIL_TE_BEAMENTS( MSG_BROADCAST, pLastVictim, pVictim, gl_iszModelIndex[ ModelIndex_LaserBeam ], .iFrameRate = BeamEffectFrameRate, .iLife = BeamEffectLifeTime, .iWidth = BeamEffectWidth, .iBrightness = BeamEffectBirghtness );

				BIT_ADD( bitsAttacked, BIT( pVictim ) );
				pLastVictim = pVictim;
				// Each player is visited once; the chain uses the same origin/radius.
			}
		}
		else if ( !is_nullent( pLastFindedVictim ) )
		{
			UTIL_ResetTimingSound( pEntity, pEntity, .szSound = WeaponSounds[ Sound_ModeA_End ] );
			pLastFindedVictim = NULLENT;
		}
	}
	else
	{
		static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
		static Vector3( vecAiming ); UTIL_GetVectorAiming( pOwner, vecAiming );
		static pInflictor; pInflictor = get_entvar( pEntity, var_dmg_inflictor );

		CLightOfJudgment__SpawnEntity( pOwner, pInflictor, vecOrigin, vecAiming );
	}

	get_entvar( pEntity, var_cached_attack_time, flAttackTime );
	set_entvar( pEntity, var_attack_time, flGameTime + flAttackTime );
}

public CGuardianEye__Move( const pEntity, const pTarget )
{
	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecTargetOrigin ); get_entvar( pTarget, var_origin, vecTargetOrigin );
	static Float: flDistance; flDistance = xs_vec_distance_2d( vecOrigin, vecTargetOrigin );
	static Vector3( vecVelocity ), Float: flSpeed;

	flSpeed = ( flDistance < 16.0 ) ? flDistance : flDistance * 3.0;
	if ( flSpeed <= 4.0 )
		vecVelocity = Float: { 1.0, 1.0, 0.0 };
	else UTIL_GetSpeedVector( vecOrigin, vecTargetOrigin, flSpeed, vecVelocity );

	if ( !IsVectorNull( vecVelocity ) )
		set_entvar( pEntity, var_velocity, vecVelocity );
}

public CGuardianEye__DoDamage( const pAttacker, const pEntity, const pVictim, const Float: flDamage, const bitsDamageType )
{
	if (!Exhero_EffectActive(pEntity) || !is_user_alive(pAttacker) || !is_user_alive(pVictim)) return;

	static Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );
	UTIL_TE_EXPLOSION( MSG_PAS, gl_iszModelIndex[ ModelIndex_Exp_ModeA ], vecOrigin, -4.0, ExplosionEffectScale, ExplosionEffectFrameRate );

	static Vector3( vecAttackerOrigin ); get_entvar( pAttacker, var_origin, vecAttackerOrigin );
	static Float: flFraction; flFraction = floatclamp( xs_vec_distance_2d( vecAttackerOrigin, vecOrigin ) / 1024.0, 0.0, 0.99 );

	static pInflictor;
#if defined UseWeaponAsMethodDamage
	pInflictor = get_entvar( pEntity, var_dmg_inflictor );
#else
	pInflictor = pEntity;
#endif

	if (is_nullent(pInflictor)) return;
	EnableHamForward( gl_HamHook_TakeDamage_Pre );
	ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, ( 1.0 - flFraction ) * flDamage, bitsDamageType );
	DisableHamForward( gl_HamHook_TakeDamage_Pre );
}

public CField__SpawnEntity( const pPlayer )
{
	new pEntity = rg_create_entity( EntityFieldReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	vecOrigin[ 2 ] -= get_entvar( pPlayer, var_bInDuck ) ? 12.0 : 32.0;

	set_entvar( pEntity, var_classname, EntityFieldClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_origin, vecOrigin );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	engfunc( EngFunc_SetModel, pEntity, EntityFieldModel );

	UTIL_SetEntityAnim( pEntity );
	UTIL_SetEntityRendering( pEntity, _, _, kRenderTransAdd, 255.0 );

#if defined _reapi_included
	SetThink( pEntity, "CField__Think" );
#endif

	return pEntity;
}

public CField__Think( const pEntity )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecOwnerOrigin ); get_entvar( pOwner, var_origin, vecOwnerOrigin );
	static Float: flDistance; flDistance = floatmax( 2.0, xs_vec_distance_2d( vecOrigin, vecOwnerOrigin ) );
	static Vector3( vecVelocity ), Float: flSpeed;
	
	flSpeed = ( flDistance < 16.0 ) ? flDistance : flDistance * 10.0;
	vecOwnerOrigin[ 2 ] -= get_entvar( pOwner, var_bInDuck ) ? 12.0 : 32.0;
	if ( flSpeed <= 4.0 )
		vecVelocity = Float: { 1.0, 1.0, 0.0 };
	else UTIL_GetSpeedVector( vecOrigin, vecOwnerOrigin, flSpeed, vecVelocity );

	if ( !IsVectorNull( vecVelocity ) )
		set_entvar( pEntity, var_velocity, vecVelocity );

	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.05 );
}

public CLightOfJudgment__SpawnEntity( const pPlayer, const pInflictor, Vector3( vecOrigin ), Vector3( vecDirection ) )
{


	new pEntity = rg_create_entity( EntityLoJReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Float: flSpeed;
	if ( !flSpeed )
		flSpeed = floatmin( EntityLoJSpeed, 2000.0 );

	vecOrigin[ 2 ] += 48.0;
	xs_vec_mul_scalar( vecDirection, flSpeed, vecDirection );

	set_entvar( pEntity, var_classname, EntityLoJClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_origin, vecOrigin );
	set_entvar( pEntity, var_velocity, vecDirection );
	set_pev(pEntity, pev_fuser4, get_gametime() + 20.0);
	set_pev(pEntity, pev_nextthink, get_gametime() + 0.5);

	engfunc( EngFunc_VecToAngles, vecDirection, vecDirection );
	set_entvar( pEntity, var_angles, vecDirection );

	engfunc( EngFunc_SetModel, pEntity, EntityLoJModel );

	UTIL_SetEntityAnim( pEntity );
	UTIL_SetEntityRendering( pEntity, _, _, kRenderTransAdd, 255.0 );

	rg_emit_sound( pEntity, CHAN_BODY, WeaponSounds[ Sound_ModeB ] );

#if defined _reapi_included
	SetTouch( pEntity, "CLightOfJudgment__Touch" );
#endif

	return pEntity;
}

public CLightOfJudgment__Touch( const pEntity, const pTouch )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	if ( pTouch == pOwner )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	UTIL_TE_EXPLOSION( MSG_PAS, gl_iszModelIndex[ ModelIndex_Exp_ModeB ], vecOrigin, -8.0, EntityLoJExplosionScale, EntityLoJExplosionFrameRate );

	rg_emit_sound( pEntity, CHAN_BODY, WeaponSounds[ Sound_ModeB_Exp ] );

	static pInflictor;
#if defined UseWeaponAsMethodDamage
	pInflictor = get_entvar( pEntity, var_dmg_inflictor );
#else
	pInflictor = pEntity
#endif

	EnableHamForward( gl_HamHook_TakeDamage_Pre );
	rg_dmg_radius( vecOrigin, pInflictor, pOwner, LightOfJudgmentDamage, LightOfJudgmentRadius, 0, LightOfJudgmentDamageType );
	DisableHamForward( gl_HamHook_TakeDamage_Pre );

	UTIL_KillEntity( pEntity );
}

public CWrathfulStrike__SpawnEntity( const pPlayer, const pInflictor )
{
	new pEntity = rg_create_entity( EntityWrathfulStrikeReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Float: flSpeed;
	if ( !flSpeed )
		flSpeed = floatmin( EntityWrathfulStrikeSpeed, 2000.0 );

	static Vector3( vecEyeLevel ); UTIL_GetEyePosition( pPlayer, vecEyeLevel );
	static Vector3( vecDirection ); UTIL_GetVectorAiming( pPlayer, vecDirection );

	xs_vec_mul_scalar( vecDirection, flSpeed, vecDirection );

	set_entvar( pEntity, var_classname, EntityWrathfulStrikeClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_origin, vecEyeLevel );
	set_entvar( pEntity, var_velocity, vecDirection );
    set_pev(pEntity, pev_fuser4, get_gametime() + 20.0);
    set_pev(pEntity, pev_nextthink, get_gametime() + 0.5);

	engfunc( EngFunc_VecToAngles, vecDirection, vecDirection );
	vecDirection[ 0 ] -= 90.0;
	set_entvar( pEntity, var_angles, vecDirection );

	engfunc( EngFunc_SetModel, pEntity, EntityGuardianEyeModel );

#if defined _reapi_included
	SetTouch( pEntity, "CWrathfulStrike__Touch" );
    SetThink( pEntity, "CWrathfulStrike__FlightThink" );
#endif

	return pEntity;
}

public CWrathfulStrike__Touch( const pEntity, const pTouch )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	if ( pTouch == pOwner )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	engfunc( EngFunc_DropToFloor, pEntity );

	static Float: flGameTime; flGameTime = get_gametime( );
	static Vector3( vecAngles ); get_entvar( pEntity, var_angles, vecAngles );
	vecAngles[ 0 ] = 0.0;

	set_entvar( pEntity, var_movetype, MOVETYPE_NONE );
	set_entvar( pEntity, var_solid, SOLID_NOT );
	set_entvar( pEntity, var_angles, vecAngles );
	set_entvar( pEntity, var_titan_state, false );
	set_entvar( pEntity, var_next_state, flGameTime + 44/30.0 );
	set_entvar( pEntity, var_attack_time, flGameTime + WrathfulStrikeRate );
	set_entvar( pEntity, var_ltime, flGameTime + EntityWrathfulStrikeLifeTime );
	set_entvar( pEntity, var_nextthink, flGameTime );

	engfunc( EngFunc_SetModel, pEntity, EntityWrathfulStrikeModel );

	UTIL_SetEntityAnim( pEntity );
	UTIL_SetEntityRendering( pEntity, _, _, kRenderTransAdd, 255.0 );
	UTIL_TE_EXPLOSION( MSG_PAS, gl_iszModelIndex[ ModelIndex_Spawn_ModeC ], vecOrigin, 64.0, 12, 24 );

	rg_emit_sound( pEntity, CHAN_ITEM, WeaponSounds[ Sound_ModeC ] );
	rg_emit_sound( pEntity, CHAN_STATIC, WeaponSounds[ Sound_ModeC_Exp ] );

#if defined _reapi_included
	SetTouch( pEntity, "" );
	SetThink( pEntity, "CWrathfulStrike__Think" );
#endif
}

public CWrathfulStrike__Think( const pEntity )
{
	if (!Exhero_EffectActive(pEntity)) return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLifeTime; get_entvar( pEntity, var_ltime, flLifeTime );
	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( flLifeTime < flGameTime )
	{
		UTIL_TE_EXPLOSION( MSG_PAS, gl_iszModelIndex[ ModelIndex_Post_ModeC ], vecOrigin, 64.0, 12, 48 );
		UTIL_KillEntity( pEntity );
		return;
	}

	set_entvar( pEntity, var_nextthink, flGameTime + EntityWrathfulStrikeNextThink );

	static bool: bTitanState; bTitanState = bool: get_entvar( pEntity, var_titan_state );
	static Float: flNextState; get_entvar( pEntity, var_next_state, flNextState );
	if ( flNextState < flGameTime )
	{
		bTitanState = true;
		set_entvar( pEntity, var_titan_state, bTitanState );
	}

	static Float: flAttackTime; get_entvar( pEntity, var_attack_time, flAttackTime );
	if ( !flAttackTime || flAttackTime >= flGameTime )
		return;

	static pInflictor;
#if defined UseWeaponAsMethodDamage
	pInflictor = get_entvar( pEntity, var_dmg_inflictor );
#else
	pInflictor = pEntity
#endif

	if (is_nullent(pInflictor)) return;
	if ( bTitanState )
	{
		UTIL_TE_EXPLOSION( MSG_PAS, gl_iszModelIndex[ ModelIndex_Exp_ModeC ], vecOrigin, 96.0, 12, 48 );

		EnableHamForward( gl_HamHook_TakeDamage_Pre );
		rg_dmg_radius( vecOrigin, pInflictor, pOwner, WrathfulStrikeDamage[ 1 ], WrathfulStrikeRadius, 0, WrathfulStrikeDamageType );
		DisableHamForward( gl_HamHook_TakeDamage_Pre );
		if (!Exhero_EffectActive(pEntity) || is_nullent(pInflictor)) return;

		set_entvar( pEntity, var_attack_time, 0.0 );
	}
	else
	{
		static Vector3( vecVictimOrigin ), Vector3( vecVelocity );
		for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
		{
			if ( !is_user_alive( pVictim ) )
				continue;

		#if defined _zombieplague_included
			if ( !zp_get_user_zombie( pVictim ) )
		#else
			if ( IsSimilarPlayersTeam( pVictim, pOwner ) )
		#endif
				continue;

			if ( UTIL_GetEntitiesDistance( pEntity, pVictim ) >= WrathfulStrikeRadius )
				continue;

			get_entvar( pVictim, var_origin, vecVictimOrigin );
			UTIL_GetSpeedVector( vecVictimOrigin, vecOrigin, EntityWrathfulStrikeCatchSpeed, vecVelocity );

			EnableHamForward( gl_HamHook_TakeDamage_Pre );
			ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pOwner, WrathfulStrikeDamage[ 0 ], WrathfulStrikeDamageType );
			DisableHamForward( gl_HamHook_TakeDamage_Pre );
			if (!Exhero_EffectActive(pEntity) || is_nullent(pInflictor)) return;

			if ( is_user_alive(pVictim) && !IsVectorNull( vecVelocity ) )
				set_entvar( pVictim, var_velocity, vecVelocity );
		}

		set_entvar( pEntity, var_attack_time, flGameTime + WrathfulStrikeRate );
	}
}

/* ~ [ Natives ] ~ */
public bool: native_give_user_weapon( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_connected( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid Player (%i)", pPlayer );
		return false;
	}

	return CPlayer__GiveWeapon( pPlayer, WeaponReference, WeaponUnicalIndex );
}

/* ~ [ Stocks ] ~ */
stock bool: IsSimilarPlayersTeam( const pPlayer, const pTarget )
{
	if ( get_member_ex( pPlayer, m_iTeam ) == get_member_ex( pTarget, m_iTeam ) )
		return true;

	return false;
}

#if !defined _reapi_included
	stock rg_create_entity( const szClassName[ ] )
	{
		static iszAllocStringCached;
		if ( !iszAllocStringCached )
			iszAllocStringCached = engfunc( EngFunc_AllocString, szClassName );

		return engfunc( EngFunc_CreateNamedEntity, iszAllocStringCached );
	}

	stock bool: rg_is_player_can_takedamage( const pVictim, const pAttacker )
	{
		if ( !pAttacker )
			return true;

		if ( !IsSimilarPlayersTeam( pVictim, pAttacker ) )
			return true;

		return false;
	}

	stock rg_dmg_radius( const Vector3( vecSrc ), const pInflictor, const pAttacker, const Float: flDamage, const Float: flRadius, const iClassIgnore, const bitsDamageType )
	{
		static pTrace; pTrace = create_tr2( );
		static Float: flFraction;
		static Vector3( vecOrigin );
		for ( new pVictim = NULLENT; pVictim <= gl_iMaxPlayers; pVictim++ )
		{
			if ( !is_user_alive( pVictim ) )
				continue;

			get_entvar( pVictim, var_origin, vecOrigin );
			if ( xs_vec_distance_2d( vecSrc, vecOrigin ) > flRadius )
				continue;

			if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
				continue;

			engfunc( EngFunc_TraceLine, vecSrc, vecOrigin, iClassIgnore, pAttacker, pTrace );

			get_tr2( pTrace, TR_flFraction, flFraction );
			if ( flFraction == 1.0 )
				continue;

			ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage * ( 1.0 - flFraction ), bitsDamageType );
		}

		free_tr2( pTrace );
	}

	stock FClassnameIs( const pEntity, const szClassName[ ] )
	{
		static szBuffer[ MAX_NAME_LENGTH ];
		get_entvar( pEntity, var_classname, szBuffer, charsmax( szBuffer ) );

		return equal( szClassName, szBuffer );
	}

	stock UTIL_GiveCustomWeapon( const pPlayer, const szWeaponReference[ ], const iWeaponUId )
	{
		static iszAllocStringCached;
		if ( !iszAllocStringCached )
			iszAllocStringCached = engfunc( EngFunc_AllocString, szWeaponReference );

		new pItem = engfunc( EngFunc_CreateNamedEntity, iszAllocStringCached );
		if ( is_nullent( pItem ) )
			return NULLENT;

		set_entvar( pItem, var_impulse, iWeaponUId );
		ExecuteHam( Ham_Spawn, pItem );

		if ( !ExecuteHamB( Ham_AddPlayerItem, pPlayer, pItem ) )
		{
			UTIL_KillEntity( pItem );
			return false;
		}

		ExecuteHamB( Ham_Item_AttachToPlayer, pItem, pPlayer );
		rg_emit_sound( pPlayer, CHAN_ITEM, "items/gunpickup2.wav" );

		return pItem;
	}
#endif

stock rg_emit_sound( const pEntity, const iChannel, const szSound[ ] )
{
#if defined _reapi_included
	rh_emit_sound2( pEntity, 0, iChannel, szSound );
#else
	emit_sound( pEntity, iChannel, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
#endif
}

stock any: get_member_ex( const pEntity, const any: mOffset, const any: iValue = 0 )
{
#if defined _reapi_included
	return any: get_member( pEntity, mOffset, iValue );
#else
	switch ( mOffset )
	{
		// Int Weapon
		case m_iId, m_Weapon_iGlock18ShotsFired, m_Weapon_iWeaponState, m_Weapon_iPrimaryAmmoType: {
			return get_pdata_int( pEntity, mOffset, linux_diff_weapon );
		}
		// Float Weapon
		case m_Weapon_flTimeWeaponIdle, m_Weapon_flNextSecondaryAttack, m_Weapon_flDecreaseShotsFired, m_flLastEventCheck: {
			return Float: get_pdata_float( pEntity, mOffset, linux_diff_weapon );
		}
		// CBase Weapon
		case m_pPlayer, m_pNext: {
			return get_pdata_cbase( pEntity, mOffset, linux_diff_weapon );
		}
		// Int Player
		case m_iTeam, m_rgAmmo: {
			return get_pdata_int( pEntity, mOffset + iValue, linux_diff_player );
		}
		// CBase Player
		case m_pActiveItem, m_rgpPlayerItems: {
			return get_pdata_cbase( pEntity, mOffset + iValue, linux_diff_player );
		}
	}

	return NULLENT;
#endif
}

stock set_member_ex( const pEntity, const any: mOffset, const any: iValue, const any: iExtraValue = 0 )
{
#if defined _reapi_included
	set_member( pEntity, mOffset, iValue, iExtraValue );
#else
	switch ( mOffset )
	{
		// Int Weapon
		case m_Weapon_iGlock18ShotsFired, m_Weapon_iPrimaryAmmoType, m_Weapon_iWeaponState, m_Weapon_iClip: {
			set_pdata_int( pEntity, mOffset, iValue, linux_diff_weapon );
		}
		// Float Weapon
		case m_Weapon_flTimeWeaponIdle, m_Weapon_flNextPrimaryAttack, m_Weapon_flNextSecondaryAttack, m_Weapon_flDecreaseShotsFired, m_flLastEventCheck: {
			set_pdata_float( pEntity, mOffset, iValue, linux_diff_weapon );
		}
		// Int Player
		case m_rgAmmo: {
			set_pdata_int( pEntity, mOffset + iExtraValue, iValue, linux_diff_player );
		}
		// Float Player
		case m_flNextAttack: {
			set_pdata_float( pEntity, mOffset, iValue, linux_diff_player );
		}
	}
#endif
}

#if defined _api_muzzleflash_included
	stock MuzzleFlash: UTIL_MuzzleFlashInit( const szSprite[ ], const Float: flScale, const iAttachment, const Float: flFramerateMlt, const iFlag = MuzzleFlashFlag_Once )
	{
		new MuzzleFlash: iMuzzleId = zc_muzzle_init( );
		{
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SPRITE, szSprite );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SCALE, flScale );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_ATTACHMENT, iAttachment );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_FRAMERATE_MLT, flFramerateMlt );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_FLAGS, iFlag );
		}

		return iMuzzleId;
	}
#endif

stock UTIL_SetEntityRendering( const pEntity, const iRenderFx = kRenderFxNone, const Float: flRenderColor[ 3 ] = { 255.0, 255.0, 255.0 }, const iRenderMode = kRenderNormal, const Float: flRenderAmount = 16.0 )
{
	set_entvar( pEntity, var_renderfx, iRenderFx );
	set_entvar( pEntity, var_rendercolor, flRenderColor );
	set_entvar( pEntity, var_rendermode, iRenderMode );
	set_entvar( pEntity, var_renderamt, flRenderAmount );
}

#if !defined _reapi_included
	stock UTIL_PlayerAnimation( const pPlayer, const szAnim[ ] ) 
	{
		new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		if ( ( iAnimDesired = lookup_sequence( pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed ) ) == -1 ) 
			iAnimDesired = 0;

		UTIL_SetEntityAnim( pPlayer, iAnimDesired );

		static Float: flGameTime; flGameTime = get_gametime( );

		set_pdata_int( pPlayer, m_fSequenceLoops, bLoops, linux_diff_animating );
		set_pdata_int( pPlayer, m_fSequenceFinished, 0, linux_diff_animating );
		set_pdata_float( pPlayer, m_flFrameRate, flFrameRate, linux_diff_animating );
		set_pdata_float( pPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating );
		set_pdata_float( pPlayer, m_flLastEventCheck, flGameTime, linux_diff_animating );
		set_pdata_int( pPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player );
		set_pdata_int( pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player );
		set_pdata_float( pPlayer, m_flLastAttackTime, flGameTime, linux_diff_player );
	}
#endif

stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim )
{
    if(!is_user_alive(pReceiver) || pev_valid(pItem)!=2 || !IsCustomWeapon(pItem,WeaponUnicalIndex))return;
    if(get_member_ex(pReceiver,m_pActiveItem)!=pItem || iAnim<0 || iAnim>15)return;
    static Float:lastTime[33], lastAnim[33], lastItem[33], lastUser[33];
    new Float:now=get_gametime(), userid=get_user_userid(pReceiver);
    if(lastUser[pReceiver]==userid && lastItem[pReceiver]==pItem && lastAnim[pReceiver]==iAnim && now-lastTime[pReceiver]<0.05)return;
    lastUser[pReceiver]=userid;lastItem[pReceiver]=pItem;lastAnim[pReceiver]=iAnim;lastTime[pReceiver]=now;

	static iBody; iBody = get_entvar( pItem, var_body );
	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

	if ( get_entvar( pReceiver, var_iuser1 ) )
		return;

	static i, iCount, pSpectator, aSpectators[ MAX_PLAYERS ];
	get_players( aSpectators, iCount, "bch" );

	for ( i = 0; i < iCount; i++ )
	{
		pSpectator = aSpectators[ i ];

		if ( get_entvar( pSpectator, var_iuser1 ) != OBS_IN_EYE )
			continue;

		if ( get_entvar( pSpectator, var_iuser2 ) != pReceiver )
			continue;

		set_entvar( pSpectator, var_weaponanim, iAnim );

		message_begin( MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = pSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}
}

stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
	static pEntity; pEntity = NULLENT;
	while ( ( pEntity = fm_find_ent_by_class( pEntity, szClassName ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

stock UTIL_KillEntity( const pEntity )
{
	if (is_nullent(pEntity)) return;

	set_entvar( pEntity, var_flags, get_entvar(pEntity, var_flags) | FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

stock bool: UTIL_InvalidEntityOwner(const pEntity, const pOwner)
{
    if (!Exhero_EffectActive(pEntity)) return true;
    if (!gl_bRoundEnded && pOwner >= 1 && pOwner <= gl_iMaxPlayers && is_user_alive(pOwner))
    {
        if (!zp_get_user_zombie(pOwner)) return false;
    }
    UTIL_KillEntity(pEntity);
    return true;
}

stock UTIL_GetItemByName( const pPlayer, const szItemName[ ] )
{
	for ( new i, pItem = NULLENT; i < MAX_ITEM_TYPES; i++ )
	{
		pItem = get_member_ex( pPlayer, m_rgpPlayerItems, i );
		while ( !is_nullent( pItem ) )
		{
			if ( FClassnameIs( pItem, szItemName ) )
				return pItem;

			pItem = get_member_ex( pItem, m_pNext );
		}
	}

	return -1;
}

stock bool: UTIL_StripWeaponByIndex( const pPlayer, const pItem )
{
	if ( is_nullent( pItem ) )
		return false;

	static mId; mId = get_member_ex( pItem, m_iId );
	if ( get_member_ex( pPlayer, m_pActiveItem ) == pItem )
		ExecuteHamB( Ham_Weapon_RetireWeapon, pItem );

	if ( !ExecuteHamB( Ham_RemovePlayerItem, pPlayer, pItem ) )
		return false;

	ExecuteHamB( Ham_Item_Kill, pItem );
	set_entvar( pPlayer, var_weapons, get_entvar( pPlayer, var_weapons ) & ~( 1<<mId ) );

	return true;
}

stock UTIL_FindClosestVictim( const pEntity, const Float: flMaxDistance )
{
	static pFindedVictim; pFindedVictim = NULLENT;
	static Float: flDistance; flDistance = 0.0;
	static Float: flCurrentDistance; flCurrentDistance = flMaxDistance;

#if !defined _zombieplague_included
	static pOwner; pOwner = get_entvar( pEntity, var_owner );
#endif

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) )
			continue;

	#if defined _zombieplague_included
		if ( !zp_get_user_zombie( pVictim ) )
	#else
		if ( IsSimilarPlayersTeam( pVictim, pOwner ) )
	#endif
			continue;

		if ( !UTIL_IsWallBetweenPoints( pEntity, pVictim ) )
			continue;

		flDistance = UTIL_GetEntitiesDistance( pEntity, pVictim );
		if ( flDistance < flCurrentDistance )
		{
			flCurrentDistance = flDistance;
			pFindedVictim = pVictim;
		}
	}

	return pFindedVictim;
}

stock Float: UTIL_GetEntitiesDistance( const pEntity, const pTarget )
{
	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecTargetOrigin ); get_entvar( pTarget, var_origin, vecTargetOrigin );

	return xs_vec_distance_2d( vecOrigin, vecTargetOrigin );
}

stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecPunchangle ); get_entvar( pPlayer, var_punchangle, vecPunchangle );

	xs_vec_add( vecViewAngle, vecPunchangle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), const Float: flSpeed = 0.0, Vector3( vecVelocity ) )
{
	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

stock UTIL_ResetTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ] = "common/null.wav" )
{
	set_entvar( pEntity, var_next_sound, get_gametime( ) );
	rg_emit_sound( pPlayer, iChannel, szSound );
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const szSound[ ], const iChannel = CHAN_WEAPON, const Float: flSoundTime )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rg_emit_sound( pPlayer, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

	return true;
}


#if !defined _reapi_included
	/**
	 * This stock is not needed if you use ReHLDS
	 * with this console command 'sv_auto_precache_sounds_in_models 1'
	 **/
	/* -> Automaticly precache Sounds from Model <- */
	stock UTIL_PrecacheSoundsFromModel( const szModelPath[ ] )
	{
		new pFile;
		if ( !( pFile = fopen( szModelPath, "rb" ) ) )
			return;
		
		new szSoundPath[ MAX_RESOURCE_PATH_LENGTH ];
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek( pFile, 164, SEEK_SET );
		fread( pFile, iNumSeq, BLOCK_INT );
		fread( pFile, iSeqIndex, BLOCK_INT );
		
		for ( new i = 0; i < iNumSeq; i++ )
		{
			fseek( pFile, iSeqIndex + 48 + 176 * i, SEEK_SET );
			fread( pFile, iNumEvents, BLOCK_INT );
			fread( pFile, iEventIndex, BLOCK_INT );
			fseek( pFile, iEventIndex + 176 * i, SEEK_SET );
			
			for ( new k = 0; k < iNumEvents; k++ )
			{
				fseek( pFile, iEventIndex + 4 + 76 * k, SEEK_SET );
				fread( pFile, iEvent, BLOCK_INT );
				fseek( pFile, 4, SEEK_CUR );
				
				if ( iEvent != 5004 )
					continue;
				
				fread_blocks( pFile, szSoundPath, 64, BLOCK_CHAR );
                szSoundPath[63]=0;
				
				if ( strlen( szSoundPath ) )
				{
					new szBuffer[ MAX_RESOURCE_PATH_LENGTH ];

					strtolower( szSoundPath );
					format( szBuffer, charsmax( szBuffer ), "sound/%s", szSoundPath );
					engfunc( EngFunc_PrecacheGeneric, szBuffer );
				}
			}
		}
		
		fclose( pFile );
	}
#endif

#if defined WeaponListDir
	stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
	{
		new szBuffer[ 128 ], pFile;

		format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
		engfunc( EngFunc_PrecacheGeneric, szBuffer );

		if ( !( pFile = fopen( szBuffer, "rb" ) ) )
			return;

		new szSprName[ MAX_RESOURCE_PATH_LENGTH ], iPos;

		while ( !feof( pFile ) ) 
		{
			fgets( pFile, szBuffer, charsmax( szBuffer ) );
			trim( szBuffer );

			if ( !strlen( szBuffer ) ) 
				continue;

			if ( ( iPos = containi( szBuffer, "640" ) ) == -1 )
				continue;
					
			format( szBuffer, charsmax( szBuffer ), "%s", szBuffer[ iPos + 3 ] );		
			trim( szBuffer );

			strtok( szBuffer, szSprName, charsmax( szSprName ), szBuffer, charsmax( szBuffer ), ' ', 1 );
			trim( szSprName );

		#if AMXX_VERSION_NUM <= 183
			format( szBuffer, charsmax( szBuffer ), "sprites/%s.spr", szSprName );
			engfunc( EngFunc_PrecacheGeneric, szBuffer );
		#else
			engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}
#endif

stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, const szWeaponName[ ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );

#if defined _reapi_included
	static szWeaponList[ MAX_NAME_LENGTH ];
	if ( IsNullString( szWeaponName ) )
		rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponList, charsmax( szWeaponList ) );

	write_string( szWeaponList );
	write_byte( ( iPrimaryAmmoType <= -2 ) ? GetWeaponAmmoType( pItem ) : iPrimaryAmmoType );
	write_byte( ( iMaxPrimaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo1 ) : iMaxPrimaryAmmo );
	write_byte( ( iSecondaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iSecondaryAmmoType ) : iSecondaryAmmoType );
	write_byte( ( iMaxSecondaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo2 ) : iMaxSecondaryAmmo );
	write_byte( ( iSlot <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iSlot ) : iSlot );
	write_byte( ( iPosition <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iPosition ) : iPosition );
	write_byte( ( iWeaponId <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iId ) : iWeaponId );
	write_byte( ( iFlags <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iFlags ) : iFlags );
#else
	#pragma unused pItem

	write_string( szWeaponName );
	write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ 0 ] : iPrimaryAmmoType );
	write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ 1 ] : iMaxPrimaryAmmo );
	write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ 2 ] : iSecondaryAmmoType );
	write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ 3 ] : iMaxSecondaryAmmo );
	write_byte( ( iSlot <= -2 ) ? iWeaponList[ 4 ] : iSlot );
	write_byte( ( iPosition <= -2 ) ? iWeaponList[ 5 ] : iPosition );
	write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ 6 ] : iWeaponId );
	write_byte( ( iFlags <= -2 ) ? iWeaponList[ 7 ] : iFlags );
#endif

	message_end( );
}

stock UTIL_ScreenFade( const iDest, const pReceiver, Float: flDuration, Float: flHoldTime, const bitsFlags, const iColor[ 3 ], const iAlpha )
{
	static iMsgId_ScreenFade; if ( !iMsgId_ScreenFade ) iMsgId_ScreenFade = get_user_msgid( "ScreenFade" );

	message_begin( iDest, iMsgId_ScreenFade, .player = pReceiver );
	write_short( FixedUnsigned16( flDuration, (1<<12) ) ); // Duration
	write_short( FixedUnsigned16( flHoldTime, (1<<12) ) ); // Hold Time
	write_short( bitsFlags ); // Flags
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iAlpha ); // Alpha
	message_end( );
}

stock UTIL_TE_BEAMENTS( const iDest, const pPlayer, const pTarget, const iszModelIndex, const iStartFrame = 0, const iFrameRate = 1, const iLife = 1, const iWidth = 1, const iNoise = 0, const iColor[ 3 ] = { 255, 255, 255 }, const iBrightness = 255, const iScroll = 0 )
{
	new source=pPlayer & 0x0FFF, target=pTarget & 0x0FFF;
    if(!Exhero_EffectActive(source)||!Exhero_EffectActive(target))return;
    new Float:origin[3];pev(source,pev_origin,origin);
    message_begin_f(MSG_PVS,SVC_TEMPENTITY,origin);
	write_byte( TE_BEAMENTS );
	write_short( pPlayer );
	write_short( pTarget );
	write_short( iszModelIndex ); // Model Index
	write_byte( iStartFrame ); // Start Frame
	write_byte( iFrameRate ); // FrameRate
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Width
	write_byte( iNoise ); // Noise
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	write_byte( iScroll ); // Scroll speed in 0.1's
	message_end( );
}

stock UTIL_TE_EXPLOSION( const iDest, const iszModelIndex, const Vector3( vecOrigin ), const Float: flUp, const iScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_EXPLOSION );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] + flUp );
	write_short( iszModelIndex );
	write_byte( iScale ); // Scale
	write_byte( iFramerate ); // Framerate
	write_byte( bitsFlags ); // Flags
	message_end( );
}

stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer ) || is_nullent( pTarget ) )
		return false;

	static Vector3( vecStart ); get_entvar( pPlayer, var_origin, vecStart );
	static Vector3( vecEnd ); get_entvar( pTarget, var_origin, vecEnd );

	static pTrace; pTrace = create_tr2( );
	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, pTrace );
	static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
	free_tr2( pTrace );

	return xs_vec_equal( vecEnd, vecEndPos );
}

stock Exhero_Cleanup(const player = 0)
{
    new ent, owner;
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityFieldClassName)) > 0)
    {
        if (!pev_valid(ent)) continue;
        owner = pev(ent, pev_owner);
        if (!player || owner == player) UTIL_KillEntity(ent);
    }
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityGuardianEyeClassName)) > 0)
    {
        if (!pev_valid(ent)) continue;
        owner = pev(ent, pev_owner);
        if (!player || owner == player) UTIL_KillEntity(ent);
    }
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityLoJClassName)) > 0)
    {
        if (!pev_valid(ent)) continue;
        owner = pev(ent, pev_owner);
        if (!player || owner == player) UTIL_KillEntity(ent);
    }
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityWrathfulStrikeClassName)) > 0)
    {
        if (!pev_valid(ent)) continue;
        owner = pev(ent, pev_owner);
        if (!player || owner == player) UTIL_KillEntity(ent);
    }
}

public client_disconnected(pPlayer) { g_heroCleaned[pPlayer] = false; Exhero_Cleanup(pPlayer); }

public Exhero_DoubleAmmo(plugin, argc)
{
    new id = get_param(1);
    if (!is_user_alive(id) || zp_get_user_zombie(id) || revo_get_user_hero(id)) return false;
    new item = UTIL_GetItemByName(id, WeaponReference);
    if (is_nullent(item) || !IsCustomWeapon(item, WeaponUnicalIndex)) return false;
    new ammoType = get_member_ex(item, m_Weapon_iPrimaryAmmoType);
    SetWeaponAmmo(id, min(WeaponMaxAmmo, GetWeaponAmmo(id, ammoType) + WeaponDefaultAmmo), ammoType);
    return true;
}

// Fired immediately on Hero selection, before the Hero weapons are granted.
public exhero_user_hero_pre(id)
{
    Exhero_RemoveTitan(id);
}

stock Exhero_RemoveTitan(id)
{
    if (!is_user_connected(id)) return;
    new item = UTIL_GetItemByName(id, WeaponReference);
    if (!is_nullent(item) && IsCustomWeapon(item, WeaponUnicalIndex))
    {
        // Clear cached references before removing their entities.
        set_entvar(item, var_cached_entity, NULLENT);
        SetWeaponState(item, 0);
        UTIL_StripWeaponByIndex(id, item);
    }
    Exhero_Cleanup(id);
    g_heroCleaned[id] = true;
}

public Exhero_AddToHero_Pre(item, id)
{
    if (IsCustomWeapon(item, WeaponUnicalIndex) && (!is_user_alive(id) || zp_get_user_zombie(id) || revo_get_user_hero(id) || !exhero_titan_unlocked(id) || Exhero_TitanUsers(id) >= 2))
    {
        SetHamReturnInteger(false);
        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

// Also reject entities marked for deferred cleanup in the current frame.
stock bool:Exhero_EffectActive(ent)
{
    return pev_valid(ent) && !(pev(ent, pev_flags) & FL_KILLME);
}

// The engine can resend the TMP list after AddToPlayer. Rewrite its fields
// in place so Titan stays in the grenade HUD slot without extra messages.
public Exhero_TitanWeaponList(msgid, destination, id)
{
    if (id < 1 || id > 32 || !is_user_connected(id) || get_msg_arg_int(8) != CSW_TMP)
        return PLUGIN_CONTINUE;
    new item = UTIL_GetItemByName(id, WeaponReference);
    if (is_nullent(item) || !IsCustomWeapon(item, WeaponUnicalIndex))
        return PLUGIN_CONTINUE;
    set_msg_arg_string(1, WeaponListDir);
    set_msg_arg_int(2, ARG_BYTE, WeaponAmmoIndex);
    set_msg_arg_int(3, ARG_BYTE, WeaponMaxAmmo);
    set_msg_arg_int(4, ARG_BYTE, -1);
    set_msg_arg_int(5, ARG_BYTE, -1);
    set_msg_arg_int(6, ARG_BYTE, WeaponSlot - 1);
    set_msg_arg_int(7, ARG_BYTE, WeaponPosition);
    return PLUGIN_CONTINUE;
}

public CWrathfulStrike__FlightThink(const pEntity)
{
    if (!Exhero_EffectActive(pEntity)) return;
    if (UTIL_InvalidEntityOwner(pEntity, pev(pEntity, pev_owner))) return;
    new Float:expiry; pev(pEntity, pev_fuser4, expiry);
    if (get_gametime() >= expiry) UTIL_KillEntity(pEntity);
    else set_pev(pEntity, pev_nextthink, get_gametime() + 0.5);
}

stock Exhero_TitanUsers(excluded)
{
 new users;
 for(new id=1;id<=MaxClients;id++){
  if(id==excluded || !is_user_alive(id) || zp_get_user_zombie(id))continue;
  new item=UTIL_GetItemByName(id,WeaponReference);
  if(!is_nullent(item) && IsCustomWeapon(item,WeaponUnicalIndex))users++;
 }
 return users;
}

public Exhero_Refill(plugin,argc)
{
 new id=get_param(1);
 if(!is_user_alive(id)||zp_get_user_zombie(id))return false;
 new item=UTIL_GetItemByName(id,WeaponReference);
 if(is_nullent(item)||!IsCustomWeapon(item,WeaponUnicalIndex))return false;
 new amount=min(WeaponMaxAmmo,WeaponDefaultAmmo*(get_param(2)?2:1));
 SetWeaponAmmo(id,max(GetWeaponAmmo(id,WeaponAmmoIndex),amount),WeaponAmmoIndex);
 UTIL_WeaponList(MSG_ONE,id,item,WeaponListDir,WeaponAmmoIndex,WeaponMaxAmmo,-1,-1,WeaponSlot-1,WeaponPosition,CSW_TMP,0);
 return true;
}

public Exhero_Deploy_Pre(item) {
 if(!IsCustomWeapon(item,WeaponUnicalIndex)) return HAM_IGNORED;
 new id=get_member_ex(item,m_pPlayer);
 if(!is_user_alive(id) || zp_get_user_zombie(id) || get_member_ex(id,m_pActiveItem)!=item) {SetHamReturnInteger(0);return HAM_SUPERCEDE;}
 return HAM_IGNORED;
}
