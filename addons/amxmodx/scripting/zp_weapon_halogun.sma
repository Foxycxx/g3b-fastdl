#include <exhero_model_sounds>
/**
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 * Reega! - Help with models
 *
 * Download links:
 * 
 * api_muzzleflash.inc - https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash
 * api_smokewallpuff.inc - https://github.com/YoshiokaHaruki/AMXX-API-Smoke-WallPuff
 * api_weapon_player_model.inc - https://github.com/YoshiokaHaruki/AMXX-API-Weapon-Player-Model
 */

new const PluginName[ ] =						"[ZP] Weapon: Arbalest";
new const PluginVersion[ ] =					"1.0-exhero1";
new const PluginAuthor[ ] =						"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#tryinclude <api_muzzleflash>
#tryinclude <api_smokewallpuff>
#tryinclude <api_weapon_player_model>

// #include <reapi>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

#if !defined DMG_GRENADE
	#define DMG_GRENADE							(1<<24)
#endif

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
// Model-event sounds supplied by exhero_model_sounds.inc

/**
 * Use optimized sprites.
 * Implies to use sprites that are smaller, fewer extra/repeated frames.
 * Also, with these sprites, you are less likely to catch
 * the "Hunk_AllocName: failed on n bytes" error when starting the server.
 * Also use this setting if you can't set the '-heapsize' value for your server.
 */
#define UseOptimizedSprites

/**
 * Using a sprite when using a skill from two sides
 * When the setting is enabled, +2 additional sprite will be loaded
 */
// #define CheckLeftHandCvar

#if defined _zombieplague_included
	/* ~ [ Extra Item ] ~ */
	new const ExtraItem_Name[ ] =				"Arbalest";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =						15012023;
new const WeaponReference[ ] =					"weapon_m249";
new const WeaponListDir[ ] =					"x_re/weapon_halogun";
new const WeaponNative[ ] =						"zp_give_user_halogun";
new const WeaponModelView[ ] =					"models/g3bmodel/ZTHEX/x_re/v_halogun.mdl";
new const WeaponModelPlayer[ ] =				"models/x_re/p_halogun.mdl";
new const WeaponModelWorld[ ] =					"models/x_re/w_halogun.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/halogun-1.wav",
	"weapons/halogun-1_exp.wav",
	"weapons/halogun-2.wav",
	"weapons/halogun-2_end.wav",
	"weapons/halogun-2_exp1.wav",
	"weapons/halogun-2_exp2.wav",
	"weapons/halogun-3.wav"
};
new const WeaponEffects[ ][ ][ ] = {
	// Sprite Path, FrameRate
#if defined UseOptimizedSprites
	{ "sprites/x_re/fx/ef_halogun_expA.spr", 24 },
	{ "sprites/x_re/fx/ef_halogun_shootA_hit.spr", 32 },
	{ "sprites/x_re/fx/ef_halogun_shootB_hit.spr", 32 },
	{ "sprites/x_re/fx/ef_halogun_projectile.spr", 0 }
#else
	{ "sprites/x_re/ef_halogun_expA.spr", 48 },
	{ "sprites/x_re/ef_halogun_shootA_hit.spr", 64 },
	{ "sprites/x_re/ef_halogun_shootB_hit.spr", 64 },
	{ "sprites/x_re/ef_halogun_projectile.spr", 0 }
#endif
};

const ModelWorldBody =							0; // w_ model body

const WeaponMaxClip =							60; // Max clip
const WeaponDefaultAmmo =						200; // Default ammo
const WeaponMaxAmmo =							200; // Max ammo

// Primary Attack
#if defined _reapi_included
	const WeaponDamage =						49; // Base Damage
	const WeaponShotPenetration =				2; // Penetration
	const Float: WeaponShotDistance =			8192.0 // Max. shoot distance
	const Bullet: WeaponBulletType =			BULLET_PLAYER_556MM; // Bullet Type
	const Float: WeaponRangeModifier =			0.97; // Range modifier (damage * 0.97 every 500 units)
#else
	const Float: WeaponDamage =					1.1; // Damage Multiplier (from WeaponReference)
#endif
const Float: WeaponAccuracy =					0.2; // Accuracy
const Float: WeaponRate =						0.13; // Shooting Rate
const Float: WeaponMaxSpeed =					240.0; // Max Speed with active weapon
const WeaponChargedBody =						30; // Charged v_ model body
const WeaponShootsForExplode =					7; // Count of shoots for explode
const Float: WeaponExplodeDamage =				150.0; // Damage from explode
const Float: WeaponExplodeRadius =				100.0; // Radius from explode
const WeaponExplodeDamageType =					DMG_GRENADE;

// Secondary Attack
/**
 * Use ammo2 hud to display Secondary Ammo in Ammo HUD. Works only with custom WeaponList.
 * If you'r server have money hud, disable this setting.
 */
// Keep the server money HUD; the original sprite charge indicator remains active.

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	const WeaponSecondaryAmmoIndex =			18; // 15-31 only. Change if conflict with another weapons
	#if defined _reapi_included
		new const WeaponSecondaryAmmoName[ ] =	"ammo_halogun_charge";
	#endif
#endif
const WeaponSecondaryAmmoDefault =				10; // Default secondary ammo when u buy weapon
const WeaponSecondaryAmmoMax =					50; // Max. secondary ammo 
const Float: WeaponSecondaryCharge =			0.426; // Charge time for get +1 ammo
const Float: WeaponSecondaryRate =				0.156; // Rate of secondary attack (-1 ammo)
const WeaponSecondaryShootsForCharge =			10; // Count of shoots for charged

const Float: WeaponSecondaryDamage =			250.0; // Damage
const Float: WeaponSecondaryRadius =			400.0; // Radius
const Float: WeaponSecondaryKnockBack =			100.0; // Knockback
const WeaponSecondaryDamageType =				( DMG_BULLET|DMG_NEVERGIB ); // Damage type

// Black Hole (Charged)
const Float: WeaponBlackHoleDamage =			1000.0; // Damage
const Float: WeaponBlackHoleRadius =			200.0; // Radius
const Float: WeaponBlackHoleKnockBack =			2500.0; // Knockback
const WeaponBlackHoleDamageType =				DMG_GRENADE; // Damage type

// Cosmic Wave
const WeaponCosmicWaveMax =						3; // Max cosmic waves count
const Float: WeaponCosmicWaveCharge =			15.0; // Charge time for get +1 cosmic wave
const Float: WeaponCosmicWaveDamage =			450.0; // Damage
const WeaponCosmicWaveDamageType =				DMG_GRENADE; // Damage type

// Cosmic Armor
const WeaponCosmicArmorHitCount =				20; // Count of hits fro activate Cosmic Armor
const Float: WeaponCosmicArmorTimer =			80.0; // How need weapon hold for activate Cosmic Armor
const Float: WeaponCosmicArmorDamageDeal =		100.0; // Damage threshold for activate Cosmic Armor (for owner, when deal damage from fall)
const Float: WeaponCosmicArmorDamage =			2000.0; // Damage
const Float: WeaponCosmicArmorRadius =			350.0; // Radius
const Float: WeaponCosmicArmorKnockBack =		5000.0; // Knockback
const WeaponCosmicArmorDamageType =				DMG_GRENADE; // Damage type

/* ~ [ Entity: Black Hole ] ~ */
new const EntityBlackHoleReference[ ] =			"info_target";
new const EntityBlackHoleClassName[ ] =			"ent_halogun_bh_x";
new const EntityBlackHoleModels[ ][ ] = {
	"models/x_re/ef_halogun_chargingshot.mdl",
	"models/x_re/ef_halogun_chargingshot2.mdl"
};
const Float: EntityBlackHoleMaxDistance =		575.0; // Max. distance for create blackhole
const Float: EntityBlackHoleLifeTime =			1.0; // Life time

/* ~ [ Entity: Cosmic Wave ] ~ */
new const EntityCosmicWaveReference[ ] =		"info_target";
new const EntityCosmicWaveClassName[ ] =		"ent_halogun_cw_x";
new const EntityCosmicWaveModel[ ] =			"models/x_re/ef_halogun_projectile.mdl";
const Float: EntityCosmicWaveSpeed =			750.0; // Speed of Cosmic Wave
const Float: EntityCosmicWaveCatchSpeed =		250.0; // Catch speed for victims
const Float: EntityCosmicWaveLifeTime =			10.0; // Life time
const Float: EntityCosmicWaveNextThink =		0.05; // Next Think
const Float: EntityCosmicWaveRadius =			128.0; // It's setted by EngFunc_SetSize
const Float: EntityCosmicWaveNextDamage =		0.3; // After this time, victim get damage

/**
 * Use a sprite for the Cosmic Wave Indicator,
 * Otherwise, the usual hudmessage is used
 */
#define IndicatorWithSprite

/* ~ [ Muzzle-Flash ] ~ */
#if defined _api_muzzleflash_included
	new const MuzzleFlashSprites[ ][ ] = {
	#if defined IndicatorWithSprite
		"sprites/x_re/halogun_aim.spr",
	#endif
	#if defined UseOptimizedSprites
		#if defined CheckLeftHandCvar
			"sprites/x_re/fx/muzzleflash279_l.spr",
			"sprites/x_re/fx/muzzleflash277_l.spr",
		#endif
		"sprites/x_re/fx/muzzleflash290.spr",
		"sprites/x_re/fx/muzzleflash281.spr",
		"sprites/x_re/fx/muzzleflash279.spr",
		"sprites/x_re/fx/muzzleflash282.spr",
		"sprites/x_re/fx/muzzleflash273.spr",
		"sprites/x_re/fx/muzzleflash274.spr",
		"sprites/x_re/fx/muzzleflash277.spr",
		"sprites/x_re/fx/muzzleflash278.spr"
	#else
		#if defined CheckLeftHandCvar
			"sprites/x_re/muzzleflash279_l.spr",
			"sprites/x_re/muzzleflash277_l.spr",
		#endif
		"sprites/x_re/muzzleflash290.spr",
		"sprites/x_re/muzzleflash281.spr",
		"sprites/x_re/muzzleflash279.spr",
		"sprites/x_re/muzzleflash282.spr",
		"sprites/x_re/muzzleflash273.spr",
		"sprites/x_re/muzzleflash274.spr",
		"sprites/x_re/muzzleflash277.spr",
		"sprites/x_re/muzzleflash278.spr"
	#endif
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Reload,
	WeaponAnim_Draw,
	WeaponAnim_ShootA,
	WeaponAnim_ShootB_Start,
	WeaponAnim_ShootB_Loop,
	WeaponAnim_ShootB_End,
	WeaponAnim_ShootB_Ch_Loop,
	WeaponAnim_ShootB_Ch_End,
	WeaponAnim_ShootC,
	WeaponAnim_ShootB_Change,
	WeaponAnim_Dummy
};

const Float: WeaponAnim_Idle_Time =				8.0;
const Float: WeaponAnim_Reload_Time =			2.0;
const Float: WeaponAnim_Draw_Time =				1.1;
const Float: WeaponAnim_ShootA_Time =			1.0;
const Float: WeaponAnim_ShootB_Start_Time =		0.37;
const Float: WeaponAnim_ShootB_LoopEnd_Time =	0.7;
const Float: WeaponAnim_ShootB_Ch_End_Time =	1.7;
const Float: WeaponAnim_ShootC_Time =			0.9;
const Float: WeaponAnim_ShootB_Change_Time =	0.7;

/* ~ [ Params ] ~ */
#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif
#if !defined _api_muzzleflash_included || defined _api_muzzleflash_included && !defined IndicatorWithSprite
	new gl_iHudSync_Indicator;
#endif
new gl_iMaxPlayers;
new gl_bitsUserConnected;
#if defined CheckLeftHandCvar
	new gl_bitsUserLeftHanded;
#endif
#if defined _reapi_included
	new HookChain: gl_HookChain_IsPenetrableEntity_Post;
#else
	new HamHook: gl_HamHook_TraceAttack[ 4 ];
#endif
#if defined _api_muzzleflash_included
	enum eMuzzleFlashes {
	#if defined IndicatorWithSprite
		MuzzleFlash: Muzzle_Indicator,
	#endif
	#if defined CheckLeftHandCvar
		MuzzleFlash: Muzzle_Reload_Left,
		MuzzleFlash: Muzzle_ShootC1_Left,
	#endif
		MuzzleFlash: Muzzle_Draw,
		MuzzleFlash: Muzzle_ShootA,
		MuzzleFlash: Muzzle_Reload,
		MuzzleFlash: Muzzle_ShootB,
		MuzzleFlash: Muzzle_ShootB_Ch,
		MuzzleFlash: Muzzle_ShootB_Ch_End,
		MuzzleFlash: Muzzle_ShootC1,
		MuzzleFlash: Muzzle_ShootC2
	};
	new MuzzleFlash: gl_iMuzzleId[ eMuzzleFlashes ];
#endif

enum {
	Sound_ShootA,
	Sound_ShootA_Exp,
	Sound_ShootB,
	Sound_ShootB_End,
	Sound_ShootB_Exp1,
	Sound_ShootB_Exp2,
	Sound_ShootC
};

enum any: eModelIndex {
	ModelIndex_ExplodeA,
	ModelIndex_HitA,
	ModelIndex_HitB,
	ModelIndex_Projectile_Trail
};
new gl_iszModelIndex[ eModelIndex ];

enum ( <<= 1 ) {
	WeaponState_CosmicArmor = 1,

	WeaponState_ShootA_Explode,

	WeaponState_ShootB_Start,
	WeaponState_ShootB_Loop,
	WeaponState_ShootB_StartSound,
	WeaponState_ShootB_Charged,
	WeaponState_ShootB_Change
};

/* ~ [ Macroses ] ~ */
#if AMXX_VERSION_NUM <= 183
	#define DONT_BLEED							-1
#endif

#if AMXX_VERSION_NUM <= 182
	#define OBS_IN_EYE							4

	#define write_coord_f(%0)					engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

#if !defined Vector3
	#define Vector3(%0)							Float: %0[ 3 ]
#endif

#define BIT_PLAYER(%0)							( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)							( %0 |= %1 )
#define BIT_SUB(%0,%1)							( %0 &= ~%1 )
#define BIT_VALID(%0,%1)						( %0 & %1 )
#define BIT_VALID_BOOL(%0,%1)					( ( %0 & %1 ) ? true : false )

// Origin, eModelIndex, Scale
#define _UTIL_TE_EXPLOSION(%0,%1,%2) \
	UTIL_TE_EXPLOSION( MSG_PVS, gl_iszModelIndex[ %1 ], %0, 0.0, %2, WeaponEffects[ %1 ][ 1 ][ 0 ] )
#define IsUserValid(%0)							bool: ( 0 < %0 <= 32 )
#define IsUserConnected(%0)						bool: ( IsUserValid( %0 ) && BIT_VALID_BOOL( gl_bitsUserConnected, BIT_PLAYER( %0 ) ) )
#define FixedUnsigned16(%0,%1)					clamp( floatround( %0 * %1 ), 0, 0xFFFF ) // 0xFFFF = 65535
#define IsNullVector(%0)						bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )

#define IsCustomWeapon(%0,%1)					bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)						get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)					set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponState(%0)						get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)					set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponAmmoType(%0)					get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)					get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)					set_member( %0, m_rgAmmo, %1, %2 )
#define WeaponHasCosmicArmor(%0)				BIT_VALID_BOOL( %0, WeaponState_CosmicArmor )
#define WeaponOnShootB(%0)						( BIT_VALID( %0, WeaponState_ShootB_Start ) || BIT_VALID( %0, WeaponState_ShootB_Loop ) || BIT_VALID( %0, WeaponState_ShootB_StartSound ) || BIT_VALID( %0, WeaponState_ShootB_Charged ) || BIT_VALID( %0, WeaponState_ShootB_Change ) )

#define m_Weapon_flHoldTime						m_Weapon_flNextReload
#define m_Weapon_iHitCount						m_Weapon_iGlock18ShotsFired 
#define m_Weapon_flNextUpdate					m_Weapon_flDecreaseShotsFired

#define var_secondary_ammo						var_gaitsequence // pWeapon
#define var_next_charge							var_starttime // pWeapon
#define var_charged_shoots						var_colormap // pWeapon
#define var_cosmic_waves						var_waterlevel // pWeapon
#define var_next_cosmic_wave					var_idealpitch // pWeapon
#define var_update_state						var_teleport_time // pWeapon

#if defined _api_muzzleflash_included && defined IndicatorWithSprite
	#define var_muzzle_cached					var_flSwimTime // pWeapon
#endif

// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/engine/shake.h#L43
#define FFADE_IN								0x0000 // Just here so we don't pass 0 into the function
#define FFADE_OUT								0x0001 // Fade out (not in)
#define FFADE_MODULATE							0x0002 // Modulate (don't blend)
#define FFADE_STAYOUT							0x0004 // ignores the duration, stays faded out until new ScreenFade message received

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( )
{
    precache_generic("sound/weapons/halogun_draw.wav");
    precache_generic("sound/weapons/halogun_reload.wav");
    precache_generic("sound/weapons/halogun_shootB_charging_end.wav");
    precache_generic("sound/weapons/halogun_shootB_end.wav");
    precache_generic("sound/weapons/halogun_shootB_start.wav");

    Exhero_PrecacheModelSounds();
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );

	for ( i = 0; i < sizeof EntityBlackHoleModels; i++ )
		engfunc( EngFunc_PrecacheModel, EntityBlackHoleModels[ i ] );

	engfunc( EngFunc_PrecacheModel, EntityCosmicWaveModel );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined PrecacheSoundsFromModel
	UTIL_PrecacheSoundsFromModel( WeaponModelView );
#endif

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

	/* -> Precache WeaponList <- */
	UTIL_PrecacheWeaponList( WeaponListDir );
#endif

#if defined _api_muzzleflash_included
	/* -> Muzzle-Flash <- */
	#if defined IndicatorWithSprite
		gl_iMuzzleId[ Muzzle_Indicator ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Indicator ], 0.07, 4, 0.0, MuzzleFlashFlag_Static );
	#endif
	#if defined CheckLeftHandCvar
		gl_iMuzzleId[ Muzzle_ShootC1_Left ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootC1_Left ], 0.088, 1, 0.75 );
		gl_iMuzzleId[ Muzzle_Reload_Left ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Reload_Left ], 0.032, 2, 1.1 );
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_Reload_Left ], ZC_MUZZLE_START_TIME, 0.2 );
	#endif
	gl_iMuzzleId[ Muzzle_Draw ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Draw ], 0.062, 3, WeaponAnim_Draw_Time );
	gl_iMuzzleId[ Muzzle_ShootA ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootA ], 0.09, 1, WeaponRate * 2.0 );
	gl_iMuzzleId[ Muzzle_Reload ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Reload ], 0.032, 2, 1.1 );
	zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_Reload ], ZC_MUZZLE_START_TIME, 0.2 );
	gl_iMuzzleId[ Muzzle_ShootB ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootB ], 0.09, 1, 1.0 );
	gl_iMuzzleId[ Muzzle_ShootB_Ch ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootB_Ch ], 0.09, 1, 1.0 );
	gl_iMuzzleId[ Muzzle_ShootB_Ch_End ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootB_Ch_End ], 0.07, 1, 1.0 );
	gl_iMuzzleId[ Muzzle_ShootC1 ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootC1 ], 0.088, 1, 0.75 );
	gl_iMuzzleId[ Muzzle_ShootC2 ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootC2 ], 0.088, 1, 0.75 );
#endif

	/* -> Model Index <- */
	for ( i = 0; i < sizeof WeaponEffects; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WeaponEffects[ i ][ 0 ] );
}

public plugin_init( )
{
	RegisterHam(Ham_Killed, "player", "Exhero_HaloKilled", true);
	register_logevent("Exhero_HaloRoundEnd", 2, "1=Round_End");

	// https://cso.fandom.com/wiki/Arbalest
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );
#else
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "RG_CSGameRules__CleanUpMap_Post", true );
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );

	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post =
		RegisterHookChain( RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true )
	);

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif

	RegisterHam( Ham_CS_Item_GetMaxSpeed, WeaponReference, "Ham_CWeapon_GetMaxSpeed_Pre", false );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
#if !defined _reapi_included
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
#else
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
#endif
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

	/* -> HamSandwich: Player <- */
	RegisterHam( Ham_TakeDamage, "player", "Ham_CBasePlayer_TakeDamage_Pre", false );
	RegisterHam( Ham_TraceAttack, "player", "Ham_CBasePlayer_TraceAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandwich: Trace Attack -> */
	new const TraceAttack_CallBack[ ] = "Ham_CEntity_TraceAttack_Pre";

	gl_HamHook_TraceAttack[ 0 ] = RegisterHam( Ham_TraceAttack,	"func_breakable", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 1 ] = RegisterHam( Ham_TraceAttack,	"info_target", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 2 ] = RegisterHam( Ham_TraceAttack,	"player", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 3 ] = RegisterHam( Ham_TraceAttack,	"hostage_entity", TraceAttack_CallBack, false );
	
	ToggleTraceAttack( false );

	/* HamSandwich: Entity */
	RegisterHam( Ham_Think, EntityBlackHoleReference, "CInfoTarget__Think_Post", true );
	RegisterHam( Ham_Touch, EntityCosmicWaveReference, "CInfoTarget__Touch_Post", true );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	// Permanent cash unlock is provided by the ExHero primary weapon menu.
#endif

	/* -> Other <- */
#if defined _reapi_included
	gl_iMaxPlayers = get_member_game( m_nMaxPlayers );
#else
	gl_iMaxPlayers = get_maxplayers( );
#endif

#if !defined _api_muzzleflash_included || defined _api_muzzleflash_included && !defined IndicatorWithSprite
	gl_iHudSync_Indicator = CreateHudSyncObj( );
#endif
}

public client_putinserver( pPlayer )
{
	BIT_ADD( gl_bitsUserConnected, BIT_PLAYER( pPlayer ) );

#if defined CheckLeftHandCvar
	if ( !is_user_bot( pPlayer ) )
		query_client_cvar( pPlayer, "cl_righthand", "CPlayer_CheckLeftHand" );
#endif
}

public client_disconnected( pPlayer )
{
	Exhero_HaloCleanup(pPlayer);

	BIT_SUB( gl_bitsUserConnected, BIT_PLAYER( pPlayer ) );

#if defined CheckLeftHandCvar
	BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
#endif
}

public bool: native_give_user_weapon( ) 
{
	enum { arg_player = 1 };

	return CPlayer_GiveWeapon( get_param( arg_player ) );
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer ) 
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Zombie Plague ] ~ */
#if defined _zombieplague_included
	#if defined ExtraItem_Name
public zp_extra_item_selected(pPlayer, iItemId) { return PLUGIN_CONTINUE; }
	#endif
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !IsUserConnected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
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

	static Float: flLastEventCheck; flLastEventCheck = get_member( pActiveItem, m_flLastEventCheck );
	if ( !flLastEventCheck )
	{
		set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_Dummy );
		return;
	}

	if ( flLastEventCheck <= get_gametime( ) )
	{
#if defined _api_muzzleflash_included
		zc_muzzle_draw( pTarget, gl_iMuzzleId[ Muzzle_Draw ] );

	#if defined IndicatorWithSprite
		new pIndicator = zc_muzzle_draw( pTarget, gl_iMuzzleId[ Muzzle_Indicator ] );
		if ( !is_nullent( pIndicator ) )
			set_entvar( pActiveItem, var_muzzle_cached, pIndicator );
	#endif

		CWeapon_ChargeAfterDeploy( pActiveItem, pTarget );
#endif

		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, WeaponAnim_Draw );
		set_member( pActiveItem, m_flLastEventCheck, 0.0 );
	}
}

#if !defined _reapi_included
	public FM_Hook_SetModel_Pre( const pWeaponBox )
	{
		if ( !FClassnameIs( pWeaponBox, "weaponbox" ) )
			return FMRES_IGNORED;

		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	public FM_Hook_PlaybackEvent_Pre( ) return FMRES_SUPERCEDE;
	public FM_Hook_TraceLine_Post( const Vector3( vecSrc ), Vector3( vecEnd ), const bitsFlags, const pAttacker, const pTrace )
	{
		if ( bitsFlags & IGNORE_MONSTERS )
			return;

		static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
		if ( flFraction == 1.0 )
			return;

		get_tr2( pTrace, TR_vecEndPos, vecEnd );
		
		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		new pHit = ( pHit = get_tr2( pTrace, TR_pHit ) ) == -1 ? 0 : pHit;
		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) )
			return;

		CWeapon_ShootAExplode( pAttacker, pHit, vecEnd );

		if ( !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
	}
#else
	/* ~ [ ReGameDLL ] ~ */
	public RG_CSGameRules__CleanUpMap_Post( )
	{
		UTIL_DestroyEntitiesByClass( EntityBlackHoleClassName );
		UTIL_DestroyEntitiesByClass( EntityCosmicWaveClassName );
	}

	public RG_CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
	{
		new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HC_CONTINUE;

		SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return HC_CONTINUE;
	}

	public RG_IsPenetrableEntity_Post( const Vector3( vecStart ), Vector3( vecEnd ), const pAttacker, const pHit )
	{
		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) )
			return;

		CWeapon_ShootAExplode( pAttacker, pHit, vecEnd );

		if ( !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); global_get( glb_trace_plane_normal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
	}

	/* ~ [ HamSandwich ] ~ */
	public Ham_CWeapon_Spawn_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		SetWeaponClip( pItem, WeaponMaxClip );

		set_member( pItem, m_Weapon_iDefaultAmmo, WeaponDefaultAmmo );
		set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

	#if defined WeaponListDir
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
	#endif
		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
	}
#endif

public Ham_CWeapon_GetMaxSpeed_Pre( const pItem )
{
	if ( IsCustomWeapon( pItem, WeaponUnicalIndex ) )
	{
		SetHamReturnFloat( WeaponMaxSpeed );
		return HAM_SUPERCEDE;
	}

	// Other M249-based weapons keep their own speed result.
	return HAM_IGNORED;
}

public Ham_CWeapon_Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );

#if defined _api_wpn_player_included
	set_entvar( pPlayer, var_weaponmodel, "" );
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer );
#else
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
#endif

#if defined CheckLeftHandCvar
	if ( IsUserConnected( pPlayer ) )
		query_client_cvar( pPlayer, "cl_righthand", "CPlayer_CheckLeftHand" );
#endif

	if ( WeaponHasCosmicArmor( GetWeaponState( pItem ) ) )
		UTIL_ScreenFade( MSG_ONE, pPlayer, 1.0, 1.0, FFADE_IN, { 255, 0, 255 }, 34 );

	set_entvar( pItem, var_body, 0 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	set_member( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );
	set_member( pItem, m_Weapon_flAccuracy, WeaponAccuracy );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
}

public Ham_CWeapon_Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new Float: flGameTime = get_gametime( );
	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

#if defined _api_muzzleflash_included
	if ( IsUserConnected( pPlayer ) && !is_user_bot( pPlayer ) )
		zc_muzzle_destroy( pPlayer );
#endif

	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootB ], .flags = SND_STOP );

	BIT_SUB( bitsWeaponState, WeaponState_ShootA_Explode );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Start );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Loop );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_StartSound );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Charged );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Change );

	SetWeaponState( pItem, bitsWeaponState );
	set_entvar( pItem, var_charged_shoots, 0 );
	set_entvar( pItem, var_next_charge, flGameTime );
	set_entvar( pItem, var_update_state, flGameTime );
	set_member( pItem, m_Weapon_flNextUpdate, 0.0 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bitsButton; bitsButton = get_entvar( pPlayer, var_button );

#if !defined _reapi_included
	if ( bitsButton & IN_ATTACK2 && Float: get_member( pItem, m_Weapon_flNextSecondaryAttack ) < 0.0 )
	{
		ExecuteHamB( Ham_Weapon_SecondaryAttack, pItem );

		bitsButton &= ~IN_ATTACK2;
		set_entvar( pPlayer, var_button, bitsButton );

		return HAM_IGNORED;
	}

	if ( get_member( pItem, m_Weapon_fInReload ) )
	{
		new iClip = GetWeaponClip( pItem );
		new iAmmoType = GetWeaponAmmoType( pItem );
		new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		new iReloadClip = min( WeaponMaxClip - iClip, iAmmo );

		SetWeaponClip( pItem, iClip + iReloadClip );
		SetWeaponAmmo( pPlayer, iAmmo - iReloadClip, iAmmoType );
		set_member( pItem, m_Weapon_fInReload, false );

		return HAM_IGNORED;
	}
#endif

	if ( bitsButton & IN_ATTACK && bitsButton & IN_ATTACK2 )
	{
		if ( CWeapon_CosmicWave( pItem, pPlayer ) )
			return HAM_IGNORED;
	}

	CWeapon_Charge( pItem, pPlayer );

	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		// ShootB
		if ( WeaponOnShootB( bitsWeaponState ) && ~bitsButton & IN_ATTACK2 )
			CWeapon_ShootBEnd( pItem, pPlayer, bitsWeaponState );

		if ( bitsWeaponState != GetWeaponState( pItem ) )
			SetWeaponState( pItem, bitsWeaponState );
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
	#if defined WeaponListDir && defined UseSecondaryAmmoHud
		set_member( pItem, m_Weapon_iSecondaryAmmoType, WeaponSecondaryAmmoIndex );

		#if defined _reapi_included
			rg_set_iteminfo( pItem, ItemInfo_pszAmmo2, WeaponSecondaryAmmoName );
			rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo2, WeaponSecondaryAmmoMax );
		#endif
	#endif

		set_entvar( pItem, var_secondary_ammo, WeaponSecondaryAmmoDefault );

		new Float: flGameTime = get_gametime( );

		set_entvar( pItem, var_next_charge, flGameTime );
		set_entvar( pItem, var_update_state, flGameTime );
		set_member( pItem, m_Weapon_flHoldTime, flGameTime + WeaponCosmicArmorTimer );
	}

	CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, get_entvar( pItem, var_secondary_ammo ) );

#if defined WeaponListDir
	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		static iSecondaryAmmoType, iSecondaryAmmoMax;
		#if defined UseSecondaryAmmoHud
			iSecondaryAmmoType = WeaponSecondaryAmmoIndex;
			iSecondaryAmmoMax = WeaponSecondaryAmmoMax;
		#else
			iSecondaryAmmoType = -2;
			iSecondaryAmmoMax = -2;
		#endif

		UTIL_WeaponList( MSG_ONE, pPlayer, pItem, WeaponListDir, _, _, iSecondaryAmmoType, iSecondaryAmmoMax );
	#endif
#endif
}

#if !defined _reapi_included
	public Ham_CWeapon_Reload_Pre( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return HAM_SUPERCEDE;

		new iClip = GetWeaponClip( pItem );
		if ( iClip >= WeaponMaxClip )
			return HAM_SUPERCEDE;

	#if defined _api_muzzleflash_included
		if ( IsUserConnected( pPlayer ) )
		{
		#if defined CheckLeftHandCvar
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? Muzzle_Reload_Left : Muzzle_Reload ] );
		#else
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_Reload ] );
		#endif
		}
	#endif

		SetWeaponClip( pItem, 0 );
		ExecuteHam( Ham_Weapon_Reload, pItem );
		SetWeaponClip( pItem, iClip );

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pItem, m_Weapon_fInReload, true );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );

		return HAM_SUPERCEDE;
	}
#else
	public Ham_CWeapon_Reload_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return;

		if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
			return;

	#if defined _api_muzzleflash_included
		if ( IsUserConnected( pPlayer ) )
		{
		#if defined CheckLeftHandCvar
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? Muzzle_Reload_Left : Muzzle_Reload ] );
		#else
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_Reload ] );
		#endif
		}
	#endif

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
	}
#endif

public Ham_CWeapon_WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	if ( !iClip )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsFlags = get_entvar( pPlayer, var_flags );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );

	if ( iShotsFired != 0 && !( iShotsFired % WeaponShootsForExplode ) )
		SetWeaponState( pItem, GetWeaponState( pItem ) | WeaponState_ShootA_Explode );

#if defined _api_muzzleflash_included
	if ( IsUserConnected( pPlayer ) )
		zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootA ] );
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_ShootA );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootA ] );

#if defined _reapi_included
	new Float: flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	new Float: flSpread;

	if ( ~bitsFlags & FL_ONGROUND )
		flSpread = 0.045 + ( 0.5 * flAccuracy );
	else if ( xs_vec_len_2d( vecVelocity ) > 140.0 )
		flSpread = 0.045 + ( 0.95 * flAccuracy );
	else flSpread = 0.03 * flAccuracy;

	iShotsFired++;
	if ( flAccuracy )
		flAccuracy = floatmin( ( ( iShotsFired * iShotsFired * iShotsFired ) / 175.0 ) + 0.4, 0.9 );

	new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
#else
	static _FM_Hook_PlayBackEvent_Pre; _FM_Hook_PlayBackEvent_Pre = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	static _FM_Hook_TraceLine_Post; _FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, _FM_Hook_PlayBackEvent_Pre );
	unregister_forward( FM_TraceLine, _FM_Hook_TraceLine_Post, true );
	ToggleTraceAttack( false );
#endif

	if ( ~bitsFlags & FL_ONGROUND )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.8, 0.65, 0.45, 0.125, 5.0, 3.5, 8 );
	else if ( xs_vec_len_2d( vecVelocity ) > 0.0 )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.1, 0.5, 0.3, 0.06, 4.0, 3.0, 8 );
	else if ( bitsFlags & FL_DUCKING )
		UTIL_WeaponKickBack( pItem, pPlayer, 0.75, 0.325, 0.25, 0.025, 3.5, 2.5, 9 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.8, 0.35, 0.3, 0.03, 3.75, 3.0, 9 );

	SetWeaponClip( pItem, --iClip );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponRate );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponRate );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_ShootA_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );
	new iAmmo = get_entvar( pItem, var_secondary_ammo );

	if ( !iAmmo )
	{
		if ( WeaponOnShootB( bitsWeaponState ) )
		{
			CWeapon_ShootBEnd( pItem, pPlayer, bitsWeaponState );
			SetWeaponState( pItem, bitsWeaponState );
		}
		else
		{
			ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
			set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.2 );
		}
		
		return HAM_SUPERCEDE;	
	}

	new iWeaponAnim = -1, Float: flIdleTime, Float: flNextAttack;

#if defined _api_muzzleflash_included
	new MuzzleFlash: iMuzzleId;
#endif

	// ShootB Loop
	if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_Loop ) )
	{
		flIdleTime = WeaponAnim_ShootB_LoopEnd_Time;
		flNextAttack = WeaponSecondaryRate;

		// Start Sound
		if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_StartSound ) )
		{
			rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootB ] );

		#if defined _api_wpn_player_included
			api_wpn_player_model_set( pPlayer, WeaponModelPlayer, 1 );
		#endif

			BIT_SUB( bitsWeaponState, WeaponState_ShootB_StartSound );
		}

		new Float: flGameTime = get_gametime( );

		// Charged
		if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_Charged ) )
		{
		#if defined _api_muzzleflash_included
			iMuzzleId = gl_iMuzzleId[ Muzzle_ShootB_Ch ];
		#endif

			// In change now
			if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_Change ) )
			{
				if ( 0.0 < Float: get_member( pItem, m_Weapon_flNextUpdate ) <= flGameTime )
				{
					iWeaponAnim = WeaponAnim_ShootB_Ch_Loop;

					BIT_SUB( bitsWeaponState, WeaponState_ShootB_Change );
					set_member( pItem, m_Weapon_flNextUpdate, 0.0 );
				}
			}
			else iWeaponAnim = WeaponAnim_ShootB_Ch_Loop;
		}

		// Default
		else
		{
			new iChargedShots = get_entvar( pItem, var_charged_shoots ) + 1;
			if ( iChargedShots >= WeaponSecondaryShootsForCharge )
			{
				BIT_ADD( bitsWeaponState, WeaponState_ShootB_Charged|WeaponState_ShootB_Change );

			#if defined _api_wpn_player_included
				api_wpn_player_model_set( pPlayer, WeaponModelPlayer, 1, 1 );
			#endif

				set_entvar( pItem, var_body, WeaponChargedBody );
				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_ShootB_Change );

				set_member( pItem, m_Weapon_flNextUpdate, flGameTime + WeaponAnim_ShootB_Change_Time - flNextAttack );

				iChargedShots = 0;
			#if defined _api_muzzleflash_included
				iMuzzleId = gl_iMuzzleId[ Muzzle_ShootB_Ch ];
			#endif
			}
			else
			{
				iWeaponAnim = WeaponAnim_ShootB_Loop;
				flIdleTime = WeaponAnim_ShootB_Change_Time;
			#if defined _api_muzzleflash_included
				iMuzzleId = gl_iMuzzleId[ Muzzle_ShootB ]
			#endif
			}

			set_entvar( pItem, var_charged_shoots, iChargedShots );
		}

	#if defined _reapi_included
		rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	#endif

		new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
		CWeapon_DoSphereDamage( pPlayer, pItem, vecOrigin, WeaponSecondaryDamage, WeaponSecondaryRadius, WeaponSecondaryDamageType, WeaponSecondaryKnockBack, true );

		CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, --iAmmo );
		set_entvar( pItem, var_next_charge, flGameTime + WeaponSecondaryCharge );
	}

	// ShootB Start
	else if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_Start ) )
	{
		iWeaponAnim = WeaponAnim_ShootB_Start;
		flIdleTime = flNextAttack = WeaponAnim_ShootB_Start_Time;
	#if defined _api_muzzleflash_included
		iMuzzleId = gl_iMuzzleId[ Muzzle_ShootB ];
	#endif

		BIT_SUB( bitsWeaponState, WeaponState_ShootB_Start );
		BIT_ADD( bitsWeaponState, WeaponState_ShootB_Loop|WeaponState_ShootB_StartSound );
		set_entvar( pItem, var_next_charge, 0.0 );
	}

	// Pre hold
	else
	{
	#if defined _api_muzzleflash_included
		iMuzzleId = Invalid_MuzzleFlash;
	#endif
		flNextAttack = 0.33;
		flIdleTime = 0.0;

		BIT_ADD( bitsWeaponState, WeaponState_ShootB_Start );
	}

#if defined _api_muzzleflash_included
	if ( IsUserConnected( pPlayer ) && iMuzzleId != Invalid_MuzzleFlash )
		zc_muzzle_draw( pPlayer, iMuzzleId );
#endif

	if ( iWeaponAnim != -1 && get_entvar( pPlayer, var_weaponanim ) != iWeaponAnim )
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iWeaponAnim );

	SetWeaponState( pItem, bitsWeaponState );
	if ( flIdleTime > 0.0 ) set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );

	return HAM_SUPERCEDE;
}

public Ham_CBasePlayer_TakeDamage_Pre( const pVictim, const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType )
{
	if ( ~bitsDamageType & DMG_FALL )
		return HAM_IGNORED;

	static pWeapon;
	if ( ( pWeapon = get_member( pVictim, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT ) ) && !is_nullent( pWeapon ) && IsCustomWeapon( pWeapon, WeaponUnicalIndex ) )
	{
		if ( WeaponHasCosmicArmor( GetWeaponState( pWeapon ) ) )
		{
			static Float: flHealth; get_entvar( pVictim, var_health, flHealth );
			if ( flDamage >= flHealth || flDamage >= WeaponCosmicArmorDamageDeal )
			{
				CWeapon_CosmicArmor( pWeapon, pVictim );
				return HAM_SUPERCEDE;
			}
		}
	}

	return HAM_IGNORED;
}

public Ham_CBasePlayer_TraceAttack_Pre( const pVictim, const pAttacker )
{
	if ( !is_user_alive( pAttacker ) )
		return HAM_IGNORED;

	if ( !zp_get_user_zombie( pVictim ) && zp_get_user_zombie( pAttacker ) )
	{
		static pWeapon;
		if ( ( pWeapon = get_member( pVictim, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT ) ) && !is_nullent( pWeapon ) && IsCustomWeapon( pWeapon, WeaponUnicalIndex ) )
		{
			if ( WeaponHasCosmicArmor( GetWeaponState( pWeapon ) ) )
			{
				CWeapon_CosmicArmor( pWeapon, pVictim );
				return HAM_SUPERCEDE;
			}
		}
	}

	return HAM_IGNORED;
}

#if !defined _reapi_included
	public Ham_CEntity_TraceAttack_Pre( const pVictim, const pAttacker, const Float: flDamage )
	{
		if ( !is_user_connected( pAttacker ) )
			return HAM_IGNORED;

		static pActiveItem; pActiveItem = get_member( pAttacker, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		SetHamParamFloat( 3, flDamage * WeaponDamage );
		return HAM_IGNORED;
	}

	public CInfoTarget__Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return

		if ( FClassnameIs( pEntity, EntityBlackHoleClassName ) )
			CBlackHole__Think( pEntity );

		if ( FClassnameIs( pEntity, EntityCosmicWaveClassName ) )
			CCosmicWave__Think( pEntity );
	}

	public CInfoTarget__Touch_Post( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return

		if ( FClassnameIs( pEntity, EntityCosmicWaveClassName ) )
			CCosmicWave__Touch( pEntity, pTouch );
	}
#endif

/* ~ [ Other ] ~ */
public bool: CPlayer_GiveWeapon( const pPlayer )
{
	if (!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer)) return false;

	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_DROP_AND_REPLACE, WeaponUnicalIndex );
	if ( is_nullent( pItem ) )
		return false;

	new iAmmoType = GetWeaponAmmoType( pItem );
	if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
		SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );

#if !defined _reapi_included
	SetWeaponClip( pItem, WeaponMaxClip );
#endif

	return true;
}

#if defined CheckLeftHandCvar
	public CPlayer_CheckLeftHand( const pPlayer, const szCvar[ ], const szValue[ ] )
		equal( szValue, "1" ) ? BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) : BIT_ADD( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
#endif

CWeapon_DoSphereDamage( const pPlayer, const pItem, const Vector3( vecOrigin ), const Float: flCachedDamage, const Float: flRadius, const bitsDamageType, const Float: flKnockBack = 0.0, const bool: bShowBlood = false )
{
	new pVictim = 1;
	new Vector3( vecVictimOrigin ), Float: flDamage;

	while ( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, vecOrigin, flRadius ) ) > 0 )
	{
		if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
			continue;

		if ( !UTIL_IsWallBetweenPoints( pPlayer, pVictim ) )
			continue;

		if ( IsUserValid( pVictim ) )
		{
			if ( !is_user_alive( pVictim ) )
				continue;

			if ( !zp_get_user_zombie( pVictim ) )
				continue;

			get_entvar( pVictim, var_origin, vecVictimOrigin );

			flDamage = flCachedDamage;
			flDamage *= ( 1.0 - floatclamp( xs_vec_distance_2d( vecOrigin, vecVictimOrigin ) / flRadius, 0.1, 0.99 ) );

			CPlayer_TakeDamage( pVictim, pItem, pPlayer, flDamage, bitsDamageType, flKnockBack, bShowBlood );

		}
		else
		{
			if ( get_entvar( pVictim, var_solid ) == SOLID_BSP )
			{
				if ( get_entvar( pVictim, var_spawnflags ) & SF_BREAK_TRIGGER_ONLY )
					continue;
			}

			ExecuteHamB( Ham_TakeDamage, pVictim, pItem, pPlayer, flCachedDamage, bitsDamageType );
		}
	}
}

CWeapon_DoRadiusDamage( const pPlayer, const pItem, const Vector3( vecOrigin ), const Float: flCachedDamage, const Float: flRadius, const bitsDamageType, const Float: flKnockBack = 0.0, const bool: bShowBlood = false )
{
	new Vector3( vecVictimOrigin ), Float: flDistance, Float: flDamage;

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) )
			continue;

		if ( !zp_get_user_zombie( pVictim ) )
			continue;

		if ( !UTIL_IsWallBetweenPoints( pPlayer, pVictim ) )
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		flDistance = xs_vec_distance_2d( vecOrigin, vecVictimOrigin );
		if ( flDistance > flRadius )
			continue;

		flDamage = flCachedDamage;
		flDamage *= ( 1.0 - floatclamp( flDistance / flRadius, 0.1, 0.99 ) );

		CPlayer_TakeDamage( pVictim, pItem, pPlayer, flDamage, bitsDamageType, flKnockBack, bShowBlood );
	}
}

CPlayer_TakeDamage( const pVictim, const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType, const Float: flKnockBack = 0.0, const bool: bShowBlood )
{
	set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
	ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType );

	if ( flKnockBack != 0.0 )
		UTIL_PlayerKnockBack( pVictim, pAttacker, flKnockBack, 1.0 );

	if ( bShowBlood )
	{
		static Vector3( vecVictimOrigin ); get_entvar( pVictim, var_origin, vecVictimOrigin );

		static iBloodColor;
		if ( ( iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim ) ) != DONT_BLEED )
			UTIL_TE_BLOODSPRITE( MSG_PVS, vecVictimOrigin, iBloodColor, floatround( flDamage ) );

		static bitsWeaponState;
		if ( ( bitsWeaponState = GetWeaponState( pInflictor ) ) && BIT_VALID( bitsWeaponState, WeaponState_ShootB_Loop ) )
		{
			static iHitCount; iHitCount = get_member( pInflictor, m_Weapon_iHitCount );
			if ( iHitCount < WeaponCosmicArmorHitCount )
			{
				if ( zp_get_user_zombie( pVictim ) )
					set_member( pInflictor, m_Weapon_iHitCount, ++iHitCount );
			}

			_UTIL_TE_EXPLOSION( vecVictimOrigin, ModelIndex_HitB, 2 );
		}
	}
}

public CWeapon_Charge( const pItem, const pPlayer )
{
	static Float: flGameTime; flGameTime = get_gametime( );

	// Secondary
	static Float: flNextCharge;
	static iAmmo; iAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( iAmmo < WeaponSecondaryAmmoMax )
	{
		get_entvar( pItem, var_next_charge, flNextCharge );

		if ( 0.0 < flNextCharge <= flGameTime )
		{
			CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, ++iAmmo );
			set_entvar( pItem, var_next_charge, flGameTime + WeaponSecondaryCharge );
		}
	}

	// Cosmic Wave
	iAmmo = get_entvar( pItem, var_cosmic_waves );
	if ( iAmmo < WeaponCosmicWaveMax )
	{
		get_entvar( pItem, var_update_state, flNextCharge );

		if ( 0.0 < flNextCharge <= flGameTime )
		{
			get_entvar( pItem, var_next_cosmic_wave, flNextCharge );

			if ( flNextCharge >= WeaponCosmicWaveCharge )
			{
				set_entvar( pItem, var_cosmic_waves, ++iAmmo );
				flNextCharge = ( iAmmo >= WeaponCosmicWaveMax ) ? 0.0 : 1.0
			}
			else flNextCharge += 1.0;
			
			set_entvar( pItem, var_next_cosmic_wave, flNextCharge );
			set_entvar( pItem, var_update_state, ( iAmmo >= WeaponCosmicWaveMax ) ? 0.0 : flGameTime + 1.0 );

			CIndicator__UpdateState( pItem, pPlayer, iAmmo, flNextCharge );
		}
	}

	// Cosmic Armor
	if ( 0.0 < Float: get_member( pItem, m_Weapon_flHoldTime ) < flGameTime )
	{
		if ( get_member( pItem, m_Weapon_iHitCount ) >= WeaponCosmicArmorHitCount )
		{
			UTIL_ScreenFade( MSG_ONE, pPlayer, 1.0, 1.0, FFADE_IN, { 255, 0, 255 }, 34 );

			SetWeaponState( pItem, GetWeaponState( pItem ) | WeaponState_CosmicArmor );
			set_member( pItem, m_Weapon_flHoldTime, 0.0 );
		}
	}
}

public CWeapon_ChargeAfterDeploy( const pItem, const pPlayer )
{
	new Float: flGameTime = get_gametime( );
	new Float: flNextCharge;

	// Secondary
	new iGiveAmmo;
	new iAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( iAmmo < WeaponSecondaryAmmoMax )
	{
		get_entvar( pItem, var_next_charge, flNextCharge );

		if ( 0.0 < flNextCharge <= flGameTime )
		{
			iGiveAmmo = floatround( ( flGameTime - flNextCharge ) / WeaponSecondaryCharge, floatround_floor );
			iAmmo = min( iAmmo + iGiveAmmo, WeaponSecondaryAmmoMax );

			CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, iAmmo );
			set_entvar( pItem, var_next_charge, ( iAmmo >= WeaponSecondaryAmmoMax ) ? 0.0 : flGameTime + WeaponSecondaryCharge );
		}
	}

	// Cosmic Wave
	iAmmo = get_entvar( pItem, var_cosmic_waves );
	if ( iAmmo < WeaponCosmicWaveMax )
	{
		get_entvar( pItem, var_update_state, flNextCharge );

		if ( 0.0 < flNextCharge <= flGameTime )
		{
			new Float: flChargeNow; get_entvar( pItem, var_next_cosmic_wave, flChargeNow );
			flChargeNow += flGameTime - flNextCharge;

			while ( ( flChargeNow >= WeaponCosmicWaveCharge ) )
			{
				flChargeNow -= WeaponCosmicWaveCharge;
				iAmmo++;

				if ( iAmmo >= WeaponCosmicWaveMax )
				{
					flChargeNow = 0.0;
					break;
				}
			}

			set_entvar( pItem, var_cosmic_waves, iAmmo );
			set_entvar( pItem, var_next_cosmic_wave, flChargeNow );
			set_entvar( pItem, var_update_state, ( iAmmo >= WeaponCosmicWaveMax ) ? 0.0 : flGameTime + 1.0 );

			CIndicator__UpdateState( pItem, pPlayer, iAmmo, flChargeNow );
		}
	}
	else
		CIndicator__UpdateState( pItem, pPlayer, iAmmo );
}

public CWeapon_UpdateSecondaryAmmo( const pItem, const pPlayer, const iSecondaryAmmo )
{
	set_entvar( pItem, var_secondary_ammo, iSecondaryAmmo );

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	SetWeaponAmmo( pPlayer, iSecondaryAmmo, WeaponSecondaryAmmoIndex );
#else
	client_print( pPlayer, print_center, "[ Arbalest Charge: %i ]", iSecondaryAmmo );
#endif

	return true;
}

public CWeapon_ShootAExplode( const pAttacker, const pHit, const Vector3( vecEnd ) )
{
	static pActiveItem;
	if ( ( pActiveItem = get_member( pAttacker, m_pActiveItem ) ) && !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
	{
		static iHitCount; iHitCount = get_member( pActiveItem, m_Weapon_iHitCount );
		if ( IsUserConnected( pHit ) && iHitCount < WeaponCosmicArmorHitCount )
		{
			if ( zp_get_user_zombie( pHit ) )
				set_member( pActiveItem, m_Weapon_iHitCount, ++iHitCount );
		}
		
		static bitsWeaponState;
		if ( ( bitsWeaponState = GetWeaponState( pActiveItem ) ) && BIT_VALID( bitsWeaponState, WeaponState_ShootA_Explode ) )
		{
			_UTIL_TE_EXPLOSION( vecEnd, ModelIndex_ExplodeA, 4 );

		#if defined _reapi_included
			rh_emit_sound2( 0, 0, CHAN_ITEM, WeaponSounds[ Sound_ShootA_Exp ], .origin = vecEnd );
		#else
			static const TempEntityReference[ ] = "info_target";
			new pTempEntity = rg_create_entity( TempEntityReference );
			if ( !is_nullent( pTempEntity ) )
			{
				engfunc( EngFunc_SetOrigin, pTempEntity, vecEnd );
				rh_emit_sound2( pTempEntity, 0, CHAN_ITEM, WeaponSounds[ Sound_ShootA_Exp ] );

				UTIL_KillEntity( pTempEntity );
			}
		#endif

			CWeapon_DoRadiusDamage( pAttacker, pActiveItem, vecEnd, WeaponExplodeDamage, WeaponExplodeRadius, WeaponExplodeDamageType );

			BIT_SUB( bitsWeaponState, WeaponState_ShootA_Explode );
			SetWeaponState( pActiveItem, bitsWeaponState );
		}
		else
			_UTIL_TE_EXPLOSION( vecEnd, ModelIndex_HitA, 1 );
	}
}

public CWeapon_ShootBEnd( const pItem, const pPlayer, &bitsWeaponState )
{
	new iWeaponAnim = -1, Float: flNextAttack;

	if ( !BIT_VALID( bitsWeaponState, WeaponState_ShootB_Start ) )
	{
		if ( BIT_VALID( bitsWeaponState, WeaponState_ShootB_Charged ) )
		{
			iWeaponAnim = WeaponAnim_ShootB_Ch_End;
			flNextAttack = WeaponAnim_ShootB_Ch_End_Time;

			CBlackHole__SpawnEntity( pPlayer, pItem, false );

		#if defined _api_muzzleflash_included
			if ( IsUserConnected( pPlayer ) )
				zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootB_Ch_End ] );
		#endif
		}
		else
		{
			iWeaponAnim = WeaponAnim_ShootB_End;
			flNextAttack = WeaponAnim_ShootB_LoopEnd_Time;

		#if defined _api_muzzleflash_included
			if ( IsUserConnected( pPlayer ) )
				zc_muzzle_destroy( pPlayer, gl_iMuzzleId[ Muzzle_ShootB ] );
		#endif
		}
	}

#if defined _api_wpn_player_included
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer );
#endif

	if ( iWeaponAnim != -1 )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iWeaponAnim );
		rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootB_End ] );
	}

	set_entvar( pItem, var_body, 0 );

	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Start );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Loop );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_StartSound );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Charged );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Change );

	if ( flNextAttack > 0.0 )
	{
		set_member( pItem, m_Weapon_flTimeWeaponIdle, flNextAttack );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
	}

	set_entvar( pItem, var_charged_shoots, 0 );
	set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponSecondaryCharge );
}

public bool: CWeapon_CosmicWave( const pItem, const pPlayer )
{
	new iCosmicWaves = get_entvar( pItem, var_cosmic_waves );
	if ( !iCosmicWaves )
		return false;

	if ( Float: get_member( pItem, m_Weapon_flNextPrimaryAttack ) > 0.0 )
		return false;

	iCosmicWaves--;

#if defined _api_muzzleflash_included
	if ( IsUserConnected( pPlayer ) )
	{
	#if defined IndicatorWithSprite
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId[ Muzzle_ShootA ] );
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId[ Muzzle_ShootB ] );
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId[ Muzzle_ShootB_Ch ] );
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId[ Muzzle_ShootB_Ch_End ] );
	#else
		zc_muzzle_destroy( pPlayer );
	#endif
		#if defined CheckLeftHandCvar
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? Muzzle_ShootC1_Left : Muzzle_ShootC1 ] );
		#else
			zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootC1 ] );
		#endif

		zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootC2 ] );
	}
#endif

	CIndicator__UpdateState( pItem, pPlayer, iCosmicWaves );

	new bitsWeaponState = GetWeaponState( pItem );

	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Loop );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_StartSound );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Charged );
	BIT_SUB( bitsWeaponState, WeaponState_ShootB_Change );

#if defined _api_wpn_player_included
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer );
#endif

	CCosmicWave__SpawnEntity( pPlayer, pItem );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_ShootC );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootC ] );

#if defined _reapi_included
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
#endif

	set_entvar( pItem, var_body, 0 );
	set_entvar( pItem, var_cosmic_waves, iCosmicWaves );
	set_entvar( pItem, var_update_state, get_gametime( ) + 1.0 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_ShootC_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_ShootC_Time );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_ShootC_Time );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_ShootC_Time );

	SetWeaponState( pItem, bitsWeaponState );

	return true;
}

public CWeapon_CosmicArmor( const pItem, const pPlayer )
{
	new bitsWeaponState = GetWeaponState( pItem );

	BIT_SUB( bitsWeaponState, WeaponState_CosmicArmor );

	CBlackHole__SpawnEntity( pPlayer, pItem, true );

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pItem, m_Weapon_iHitCount, 0 );
	set_member( pItem, m_Weapon_flHoldTime, get_gametime( ) + WeaponCosmicArmorTimer );
}

CIndicator__UpdateState( const pItem, const pPlayer, const iAmmo, Float: flNextCharge = -1.0 )
{
	if ( !IsUserConnected( pPlayer ) )
		return;

	if ( flNextCharge <= -1.0 )
		get_entvar( pItem, var_next_cosmic_wave, flNextCharge );

#if defined _api_muzzleflash_included && defined IndicatorWithSprite
	new pIndicator = get_entvar( pItem, var_muzzle_cached );
	if ( is_nullent( pIndicator ) )
		return;

	set_entvar( pIndicator, var_frame, floatmin( float( iAmmo ) * WeaponCosmicWaveCharge + flNextCharge, 44.0 ) );
#else
	set_hudmessage(
		255, 128, 255,
		-1.0, 0.4,
		0,
		1.0, 1.0, 0.1, 0.2
	);
	ShowSyncHudMsg( pPlayer, gl_iHudSync_Indicator, "[ COSMIC WAVE ]^n%i%%^t^t^t^t^t^t%i|%i", min( floatround( flNextCharge / WeaponCosmicWaveCharge * 100.0 ), 100 ), iAmmo, WeaponCosmicWaveMax );
#endif
}

public CBlackHole__SpawnEntity( const pPlayer, const pInflictor, const bool: bCosmicArmor )
{
	new pEntity = rg_create_entity( EntityBlackHoleReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin )
	
	if ( !bCosmicArmor )
	{
		new Vector3( vecTemp ); get_entvar( pPlayer, var_v_angle, vecTemp );
		vecTemp[ 0 ] = floatabs( vecTemp[ 0 ] );
		new Vector3( vecForward ); angle_vector( vecTemp, ANGLEVECTOR_FORWARD, vecForward );

		xs_vec_add_scaled( vecOrigin, vecForward, EntityBlackHoleMaxDistance, vecTemp );

		engfunc( EngFunc_TraceLine, vecOrigin, vecTemp, DONT_IGNORE_MONSTERS, pPlayer, 0 );
		get_tr2( 0, TR_vecEndPos, vecOrigin );
	}

	UTIL_DropVectorToFloor( vecOrigin );
	vecOrigin[ 2 ] += 24.0;

	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetModel, pEntity, EntityBlackHoleModels[ any: bCosmicArmor ] );

	set_entvar( pEntity, var_classname, EntityBlackHoleClassName );
	set_entvar(pEntity, var_owner, pPlayer);
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityBlackHoleLifeTime );

	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );

	UTIL_SetEntityAnim( pEntity );

#if defined _reapi_included
	SetThink( pEntity, "CBlackHole__Think" );
#endif

	rh_emit_sound2( pEntity, 0, CHAN_WEAPON, WeaponSounds[ bCosmicArmor ? Sound_ShootB_Exp2 : Sound_ShootB_Exp1 ] );

	new Float: flDamage, Float: flRadius, Float: flKnockBack, bitsDamageType;
	flDamage = bCosmicArmor ? WeaponCosmicArmorDamage : WeaponBlackHoleDamage;
	flRadius = bCosmicArmor ? WeaponCosmicArmorRadius : WeaponBlackHoleRadius;
	flKnockBack = bCosmicArmor ? WeaponCosmicArmorKnockBack : WeaponBlackHoleKnockBack;
	bitsDamageType = bCosmicArmor ? WeaponCosmicArmorDamageType : WeaponBlackHoleDamageType;

	CWeapon_DoRadiusDamage( pPlayer, pInflictor, vecOrigin, flDamage, flRadius, bitsDamageType, flKnockBack );

	return pEntity;
}

public CBlackHole__Think( const pEntity ) UTIL_KillEntity( pEntity );

public CCosmicWave__SpawnEntity( const pPlayer, const pInflictor )
{
	new pEntity = rg_create_entity( EntityCosmicWaveReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	new Vector3( vecDirection ); UTIL_GetVectorAiming( pPlayer, vecDirection );

	xs_vec_add_scaled( vecOrigin, vecDirection, 20.0, vecOrigin );
	xs_vec_mul_scalar( vecDirection, EntityCosmicWaveSpeed, vecDirection );

	static Vector3( vecMins ), Vector3( vecMaxs );
	if ( IsNullVector( vecMins ) && IsNullVector( vecMaxs ) )
	{
		vecMins[ 0 ] = vecMins[ 1 ] = vecMins[ 2 ] = -EntityCosmicWaveRadius;
		vecMins[ 2 ] *= 2.0;

		vecMaxs[ 0 ] = vecMaxs[ 1 ] = vecMaxs[ 2 ] = EntityCosmicWaveRadius;
		vecMaxs[ 2 ] /= 2.0;
	}

	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetModel, pEntity, EntityCosmicWaveModel );
	engfunc( EngFunc_SetSize, pEntity, vecMins, vecMaxs );

	set_entvar( pEntity, var_classname, EntityCosmicWaveClassName );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, MOVETYPE_NOCLIP );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_velocity, vecDirection );

	engfunc( EngFunc_VecToAngles, vecDirection, vecDirection );
	set_entvar( pEntity, var_angles, vecDirection );

	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );

	new Float: flGameTime = get_gametime( );

	set_entvar( pEntity, var_ltime, flGameTime + EntityCosmicWaveLifeTime );
	set_entvar( pEntity, var_nextthink, flGameTime + EntityCosmicWaveNextThink );

	UTIL_SetEntityAnim( pEntity );
	UTIL_TE_BEAMFOLLOW( MSG_BROADCAST, pEntity, gl_iszModelIndex[ ModelIndex_Projectile_Trail ], 8, 16, { 255, 255, 255 }, 255 );

#if defined _reapi_included
	SetThink( pEntity, "CCosmicWave__Think" );
	SetTouch( pEntity, "CCosmicWave__Touch" );
#endif

	return pEntity;
}

public CCosmicWave__Think( const pEntity )
{
	if (Exhero_HaloInvalidOwner(pEntity)) return;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLifeTime; get_entvar( pEntity, var_ltime, flLifeTime );
	if ( flLifeTime < flGameTime )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	set_entvar( pEntity, var_nextthink, flGameTime + EntityCosmicWaveNextThink );

	static Vector3( vecAngles ); get_entvar( pEntity, var_angles, vecAngles );
	vecAngles[ 2 ] += 16.0;
	set_entvar( pEntity, var_angles, vecAngles );
}

public CCosmicWave__Touch( const pEntity, const pTouch )
{
	if (Exhero_HaloInvalidOwner(pEntity)) return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	if ( !IsUserValid( pTouch ) )
		return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner || !zp_get_user_zombie( pTouch ) )
		return;

	static Vector3( vecVelocity );
	static Vector3( vecVictimOrigin ); get_entvar( pTouch, var_origin, vecVictimOrigin );
	UTIL_GetSpeedVector( vecVictimOrigin, vecOrigin, EntityCosmicWaveCatchSpeed, 1.0, vecVelocity );
	set_entvar( pTouch, var_velocity, vecVelocity );

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flDamageTime; get_entvar( pTouch, var_dmgtime, flDamageTime );
	if ( flDamageTime < flGameTime )
	{
		static pInflictor; pInflictor = get_entvar( pEntity, var_dmg_inflictor );
		if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
			pInflictor = pEntity;

		CPlayer_TakeDamage( pTouch, pInflictor, pOwner, WeaponCosmicWaveDamage, WeaponCosmicWaveDamageType, 0.0, true );
		set_entvar( pTouch, var_dmgtime, flGameTime + EntityCosmicWaveNextDamage );
	}
}

/* ~ [ Stocks ] ~ */
#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
	}
#endif

#if defined _api_muzzleflash_included
	/* -> Simple initalize Muzzle-Flash <- */
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

#if defined PrecacheSoundsFromModel
	/* -> Automaticly precache Sounds from Model <- */
	/**
	 * This stock is not needed if you use ReHLDS
	 * with this console command 'sv_auto_precache_sounds_in_models 1'
	 **/
	stock UTIL_PrecacheSoundsFromModel( const szModelPath[ ] )
	{
		new pFile;
		if ( !( pFile = fopen( szModelPath, "rb" ) ) )
			return;
		
		new szSoundPath[ 64 ];
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
					strtolower( szSoundPath );
				#if AMXX_VERSION_NUM < 190
					format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
					engfunc( EngFunc_PrecacheGeneric, szSoundPath );
				#else
					engfunc( EngFunc_PrecacheGeneric, fmt( "sound/%s", szSoundPath ) );
				#endif
				}
			}
		}
		
		fclose( pFile );
	}
#endif

#if defined WeaponListDir
	/* -> Automaticly precache WeaponList <- */
	stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
	{
		new szBuffer[ 128 ], pFile;

		format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
		engfunc( EngFunc_PrecacheGeneric, szBuffer );

		if ( !( pFile = fopen( szBuffer, "rb" ) ) )
			return;

		new szSprName[ 64 ], iPos;
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

		#if AMXX_VERSION_NUM < 190
			formatex( szBuffer, charsmax( szBuffer ), "sprites/%s.spr", szSprName );
			engfunc( EngFunc_PrecacheGeneric, szBuffer );
		#else
			engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}

	/* -> Weapon List <- */
	#if defined _reapi_included
		stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			if ( szWeaponName[ 0 ] == EOS )
				rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) )

			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

			message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? GetWeaponAmmoType( pItem ) : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo1 ) : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iSecondaryAmmoType ) : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo2 ) : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iSlot ) : iSlot );
			write_byte( ( iPosition <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iPosition ) : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iId ) : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iFlags ) : iFlags );
			message_end( );
		}
	#else
		new const iWeaponList[ ][ ] = {
			{ 9, 52, -1, -1, 1, 3, 1, 0 }, // weapon_p228
			{ -1, -1, -1, -1, 0, 20, 2, 0 }, // dummy
			{ 2, 90, -1, -1, 0, 9, 3, 0 }, // weapon_scout
			{ 12, 1, -1, -1, 3, 1, 4, 24 }, // weapon_hegrenade
			{ 5, 32, -1, -1, 0, 12,5, 0 }, // weapon_xm1014
			{ 14, 1, -1, -1, 4, 3, 6, 24 }, // weapon_c4
			{ 6, 100,-1, -1, 0, 13,7, 0 }, // weapon_mac10
			{ 4, 90, -1, -1, 0, 14,8, 0 }, // weapon_aug
			{ 13, 1, -1, -1, 3, 3, 9, 24 }, // weapon_smokegrenade
			{ 10, 120,-1, -1, 1, 5, 10, 0 }, // weapon_elite
			{ 7, 100,-1, -1, 1, 6, 11, 0 }, // weapon_fiveseven
			{ 6, 100,-1, -1, 0, 15,12, 0 }, // weapon_ump45
			{ 4, 90, -1, -1, 0, 16,13, 0 }, // weapon_sg550
			{ 4, 90, -1, -1, 0, 17,14, 0 }, // weapon_galil
			{ 4, 90, -1, -1, 0, 18,15, 0 }, // weapon_famas
			{ 6, 100,-1, -1, 1, 4, 16, 0 }, // weapon_usp
			{ 10, 120,-1, -1, 1, 2, 17, 0 }, // weapon_glock18
			{ 1, 30, -1, -1, 0, 2, 18, 0 }, // weapon_awp
			{ 10, 120,-1, -1, 0, 7, 19, 0 }, // weapon_mp5navy
			{ 3, 200,-1, -1, 0, 4, 20, 0 }, // weapon_m249
			{ 5, 32, -1, -1, 0, 5, 21, 0 }, // weapon_m3
			{ 4, 90, -1, -1, 0, 6, 22, 0 }, // weapon_m4a1
			{ 10, 120,-1, -1, 0, 11,23, 0 }, // weapon_tmp
			{ 2, 90, -1, -1, 0, 3, 24, 0 }, // weapon_g3sg1
			{ 11, 2, -1, -1, 3, 2, 25, 24 }, // weapon_flashbang
			{ 8, 35, -1, -1, 1, 1, 26, 0 }, // weapon_deagle
			{ 4, 90, -1, -1, 0, 10,27, 0 }, // weapon_sg552
			{ 2, 90, -1, -1, 0, 1, 28, 0 }, // weapon_ak47
			{ -1, -1, -1, -1, 2, 1, 29, 0 }, // weapon_knife
			{ 7, 100, -1, -1, 0, 8, 30, 0 } // weapon_p90
		};

		/* -> Weapon List <- */
		stock UTIL_WeaponList( const iDist, const pReceiver, const pItem, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );
			static iId; iId = get_member( pItem, m_iId ) - 1;

			message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ iId ][ 0 ] : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ iId ][ 1 ] : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ iId ][ 2 ] : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ iId ][ 3 ] : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? iWeaponList[ iId ][ 4 ] : iSlot );
			write_byte( ( iPosition <= -2 ) ? iWeaponList[ iId ][ 5 ] : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ iId ][ 6 ] : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? iWeaponList[ iId ][ 7 ] : iFlags );
			message_end( );
		}
	#endif
#endif

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = get_entvar( pItem, var_body );
	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
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

		message_begin( iDest, SVC_WEAPONANIM, .player = pSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}
}

/* -> Destroy All Entities by ClassName <- */
stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
	static pEntity; pEntity = NULLENT;
	while ( ( pEntity = rg_find_ent_by_class( pEntity, szClassName ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> Get Weapon Box Item <- */
stock UTIL_GetWeaponBoxItem( const pWeaponBox )
{
	for ( new iSlot, pItem; iSlot < MAX_ITEM_TYPES; iSlot++ )
	{
		if ( !is_nullent( ( pItem = get_member( pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot ) ) ) )
			return pItem;
	}
	return NULLENT;
}

/* -> Gunshot Decal Trace <- */
stock UTIL_GunshotDecalTrace( const pEntity, const Vector3( vecOrigin ) )
{	
	new iDecalId = UTIL_DamageDecal( pEntity );
	if ( iDecalId == -1 )
		return;

	UTIL_TE_GUNSHOTDECAL( MSG_PAS, vecOrigin, pEntity, iDecalId );
}

stock UTIL_DamageDecal( const pEntity )
{
	new iRenderMode = get_entvar( pEntity, var_rendermode );
	if ( iRenderMode == kRenderTransAlpha )
		return -1;

	static iGlassDecalId; if ( !iGlassDecalId ) iGlassDecalId = engfunc( EngFunc_DecalIndex, "{bproof1" );
	if ( iRenderMode != kRenderNormal )
		return iGlassDecalId;

	static iShotDecalId; if ( !iShotDecalId ) iShotDecalId = engfunc( EngFunc_DecalIndex, "{shot1" );
	return ( iShotDecalId - random_num( 0, 4 ) );
}

/* -> TE_GUNSHOTDECAL <- */
stock UTIL_TE_GUNSHOTDECAL( const iDest, const Vector3( vecOrigin ), const pEntity, const iDecalId )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_GUNSHOTDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( pEntity );
	write_byte( iDecalId );
	message_end( );
}

/* -> TE_STREAK_SPLASH <- */
stock UTIL_TE_STREAK_SPLASH( const iDest, const Vector3( vecOrigin ), const Vector3( vecDirection ), const iColor, const iCount, const iSpeed, const iNoise )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_STREAK_SPLASH );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecDirection[ 0 ] );
	write_coord_f( vecDirection[ 1 ] );
	write_coord_f( vecDirection[ 2 ] );
	write_byte( iColor );
	write_short( iCount );
	write_short( iSpeed );
	write_short( iNoise );
	message_end( );
}

/* -> ScreenFade <- */
stock UTIL_ScreenFade( const iDest, const pReceiver, Float: flDuration = 0.0, Float: flHoldTime = 0.0, const bitsFlags = FFADE_IN, const iColor[ 3 ] = { 0, 0, 0 }, const iAlpha = 255 )
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

/* -> TE_EXPLOSION <- */
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

/* -> TE_BEAMFOLLOW <- */
stock UTIL_TE_BEAMFOLLOW( const iDest, const pEntity, const iszModelIndex, const iLife, const iWidth, const iColor[ 3 ], const iBrightness )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( pEntity ); // Entity: attachment to follow
	write_short( iszModelIndex ); // Model Index
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Line width in 0.1's
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	message_end( );
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Get Player vector Aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

/* -> Weapon Kick Back <- */
stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
	new Float: flKickUp, Float: flKickLateral;
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
	new iDirection = get_member( pItem, m_Weapon_iDirection );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	if ( iShotsFired == 1 ) 
	{
		flKickUp = flUpBase;
		flKickLateral = flLateralBase;
	}
	else
	{
		flKickUp = iShotsFired * flUpModifier + flUpBase;
		flKickLateral = iShotsFired * flLateralModifier + flLateralBase;
	}

	vecPunchAngle[ 0 ] -= flKickUp;

	if ( vecPunchAngle[ 0 ] < -flUpMax ) 
		vecPunchAngle[ 0 ] = -flUpMax;

	if ( iDirection ) 
	{
		vecPunchAngle[ 1 ] += flKickLateral;
		if ( vecPunchAngle[ 1 ] > flLateralMax ) 
			vecPunchAngle[ 1 ] = flLateralMax;
	}
	else
	{
		vecPunchAngle[ 1 ] -= flKickLateral;
		if ( vecPunchAngle[ 1 ] < -flLateralMax ) 
			vecPunchAngle[ 1 ] = -flLateralMax;
	}

	if ( iDirectionChange != 0 && !random_num( 0, iDirectionChange ) ) 
		set_member( pItem, m_Weapon_iDirection, !iDirection );

	set_entvar( pPlayer, var_punchangle, vecPunchAngle );
}

/* -> The target is behind the wall <- */
stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer ) || is_nullent( pTarget ) )
		return false;

	static Vector3( vecStart ); get_entvar( pPlayer, var_origin, vecStart );
	static Vector3( vecEnd ); get_entvar( pTarget, var_origin, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecStart );

	return xs_vec_equal( vecEnd, vecStart );
}

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flVelocityModifier = 0.0 )
{
	static Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );
	static Vector3( vecVelocity ); get_entvar( pVictim, var_velocity, vecVelocity );
	static Vector3( vecAttackerOrigin ); get_entvar( pAttacker, var_origin, vecAttackerOrigin );
	static Vector3( vecDirection ); xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
	static Float: flLen; flLen = xs_vec_len_2d( vecDirection );
    if (flLen <= 0.001) return;

	for ( new i = 0; i < 2; ++i )
		vecVelocity[ i ] = ( vecDirection[ i ] / flLen ) * flForce;

	set_entvar( pVictim, var_velocity, vecVelocity );

	if ( flVelocityModifier )
		set_member( pVictim, m_flVelocityModifier, flVelocityModifier );
}

/* -> TE_BLOODSPRITE < - */
stock UTIL_TE_BLOODSPRITE( const iDest, const Vector3( vecOrigin ), const iColor, iAmount )
{
	if ( iColor == DONT_BLEED || !iAmount )
		return;

	iAmount = clamp( iAmount * 2, 1, 255 );

	static _iszModelIndex_BloodSpray;
	if ( !_iszModelIndex_BloodSpray )
		_iszModelIndex_BloodSpray = engfunc( EngFunc_ModelIndex, "sprites/bloodspray.spr" );

	static _iszModelIndex_BloodDrop;
	if ( !_iszModelIndex_BloodDrop )
		_iszModelIndex_BloodDrop = engfunc( EngFunc_ModelIndex, "sprites/blood.spr" );
	
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BLOODSPRITE );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( _iszModelIndex_BloodSpray );
	write_short( _iszModelIndex_BloodDrop );
	write_byte( iColor );
	write_byte( clamp( iAmount / 10, 3, 16 ) );
	message_end( );
}

/* -> Drop Vector to floor <- */
stock UTIL_DropVectorToFloor( Vector3( vecOrigin ) )
{
	new Vector3( vecStart ); xs_vec_copy( vecOrigin, vecStart );
	vecOrigin[ 2 ] = -4096.0;

	engfunc( EngFunc_TraceLine, vecStart, vecOrigin, IGNORE_MONSTERS, 0, 0 );
	get_tr2( 0, TR_vecEndPos, vecOrigin );
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/* -> Get speed Vector to 2 points <- */
stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), Float: flSpeed = 0.0, Float: flTime = 1.0, Vector3( vecVelocity ) )
{
	if ( !flSpeed )
		flSpeed = xs_vec_distance( vecStartOrigin, vecEndOrigin ) / flTime;
	else flSpeed /= flTime;

	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

public Exhero_HaloKilled(id) { Exhero_HaloCleanup(id); }
public zp_user_infected_pre(id) { Exhero_HaloCleanup(id); }
public Exhero_HaloRoundEnd() { Exhero_HaloCleanup(); }
stock bool:Exhero_HaloInvalidOwner(ent)
{
    if (!pev_valid(ent)) return true;
    new owner = pev(ent, pev_owner);
    if (owner >= 1 && owner <= get_maxplayers() && is_user_alive(owner) && !zp_get_user_zombie(owner)) return false;
    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    return true;
}
stock Exhero_HaloCleanup(player = 0)
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityBlackHoleClassName)) > 0)
        if (!player || pev(ent, pev_owner) == player) engfunc(EngFunc_RemoveEntity, ent);
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EntityCosmicWaveClassName)) > 0)
        if (!player || pev(ent, pev_owner) == player) engfunc(EngFunc_RemoveEntity, ent);
}
