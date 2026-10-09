native Float:exhero_blade_multiplier(attacker, victim);
/**
 * Plain Sword 1.1 by Yoshioka Haruki (xUnicorn)
 * Original: https://cso.fandom.com/wiki/Whip_Sword
 * 
 * Special thanks:
 * — Nexon: Idea, source
 * — nikolaygaus: Some help with functions
 * — Reega!: Edit effects model
 * 
 * [1.0] - First Release
 * [1.1] - Added api_muzzleflash support
 */

new const PluginName[ ] =						"[ZP] Knife: Whip Sword G3B";
new const PluginVersion[ ] =					"1.1";
new const PluginAuthor[ ] =						"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

/**
 * API: Muzzle-Flash
 * Used to create an additional sight as in CSO
 * 
 * Download latest version here:
 * https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash/releases
 * 
 * If you don't need it, you can simply delete this line
 */
#include <api_muzzleflash>

/* ~ [ Extra Item ] ~ */
#if defined _zombieplague_included
	// G3B: se entrega desde el menu de desbloqueo; no registrar como Extra Item gratis.
// new const ExtraItem_Name[ ] =				"Knife: Whip Sword";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Plugin Settings ] ~ */
const WeaponHandSubmodel =						0; // Hand Submodel (0: Male / 1: Female)
const WeaponUnicalIndex =						21042022;
new const WeaponReference[ ] =					"weapon_knife";
new const WeaponAnimation[ ] =					"knife"; // In CSO: katana
new const WeaponListDir[ ] =					"g3bsprite/knife_whipsword"; // Can comment this line
new const WeaponListData[ ] =					{ -1, -1, -1, -1, 2, 1, 29, 0 };
new const WeaponViewModel[ ] =					"models/g3bmodel/ZTHEX/g3bmodel/v_whipsword.mdl";
new const WeaponPlayerModel[ ] =				"models/g3bmodel/p_whipsword.mdl";
new const WeaponSounds[ ][ ] = {
	"g3bsound/dualsword_stab1_hit.wav", // 0
	"g3bsound/dualsword_stab2_hit.wav", // 1
	"g3bsound/whipsword_slash_end.wav", // 2
	"g3bsound/whipsword_slash_loop_start.wav", // 3
	"g3bsound/whipsword_slash_loop1.wav", // 4
	"g3bsound/whipsword_slash_loop2.wav", // 5
	"g3bsound/whipsword_slash_loop3.wav", // 6
	"g3bsound/whipsword_slash_skill.wav", // 7
	"g3bsound/whipsword_slash1.wav", // 8
	"g3bsound/whipsword_slash2.wav", // 9
	"g3bsound/whipsword_slash3.wav", // 10
	"g3bsound/whipsword_slash1_end.wav", // 11
	"g3bsound/whipsword_stab_end.wav", // 12
	"g3bsound/whipsword_stab_loop_all.wav", // 13
	"g3bsound/whipsword_stab_skill_flying.wav", // 14
	"g3bsound/whipsword_stab_skill_start.wav", // 15
	"g3bsound/whipsword_stab1.wav", // 16
	"g3bsound/whipsword_stab2.wav", // 17
	"g3bsound/whipsword_stab3.wav", // 18
	"g3bsound/whipsword_stab12_end.wav", // 19
	"g3bsound/turbulent9_stone1.wav" // 20
};

/* ~ [ Entity: Attack Effects ] ~ */
new const EntityEffectsReference[ ] =			"info_target";
new const EntityEffectsClassname[ ] =			"ent_whipsword_ef";
new const EntityEffectsModel[ ] =				"models/g3bmodel/ef_whipsword.mdl";
new const any: EntityEffectsData[ ][ ] = {
	// Body, Time, Loop, Aiment
	{ 0, 0.7,	false,	true },		// Slash
	{ 1, 1.0,	true,	true },		// Slash Loop
	{ 2, 1.0,	false,	false },	// Slash Skill
	{ 3, 0.7,	false,	true },		// Stab1
	{ 3, 0.7,	false,	true },		// Stab2
	{ 4, 1.4,	true,	true },		// Stab Loop
	{ 5, 0.87,	false,	true }		// Stab Skill
};

/**
 * I took the distance values from the CSO, it is measured in meters there
 * But in CS 1.6 it all works in units
 * 
 * Get units in meters: m / 0.0254
 * Where 'm' is a number in meters
 * 
 * 4m = 157.4 units
 * 5m = 196.8 units
 * 6m = 236.2 units
 * 7m = 275.5 units
 * 15m = 590.5 units
 */

/* ~ [ Slash: Default Attack ] ~ */
const Float: WeaponSlashNextAttack =			0.65;
const Float: WeaponSlashHitTime =				0.17;
const Float: WeaponSlashDamage =				200.0;
const Float: WeaponSlashDistance =				157.4;

/* ~ [ Slash: Special Attack ] ~ */
const WeaponSlashSpecialAttacks =				9;
const Float: WeaponSlashSpecialNextAttack =		0.45;
const Float: WeaponSlashSpecialDamage =			175.0;
const Float: WeaponSlashSpecialDistance =		196.8;

/* ~ [ Slash: Skill ] ~ */
const Float: WeaponSlashSkillNextAttack =		0.2;
const Float: WeaponSlashSkillRadius =			236.2;
const Float: WeaponSlashSkillDamage =			450.0;
const Float: WeaponSlashSkillKnockBack =		350.0;

/* ~ [ Stab: Default Attack ] ~ */
const Float: WeaponStabNextAttack =				0.65;
const Float: WeaponStabHitTime =				0.24;
const Float: WeaponStabDamage =					250.0;
const Float: WeaponStabDistance =				196.8;

/* ~ [ Stab: Special Attack ] ~ */
const WeaponStabSpecialAttacks =				18;
const Float: WeaponStabSpecialNextAttack =		0.3;
const Float: WeaponStabSpecialDamage =			100.0;
const Float: WeaponStabSpecialDistance =		236.2;

/* ~ [ Stab: Skill ] ~ */
const Float: WeaponStabSkillNextAttack =		0.1;
const Float: WeaponStabSkillVelocity =			750.0; // Speed of player velocity on skill
const Float: WeaponStabSkillDistance =			590.5;
const Float: WeaponStabSkillDamage =			500.0;

/* ~ [ TraceLine Angles ] ~ */
new const Float: flSendAnglesRight[ ] = { 
	0.0,  // 1
	-2.5, 2.5, // 3
	-5.0, 5.0, // 5
	-7.5, 7.5, // 7
	-10.0, 10.0, // 9
	-12.5, 12.5, // 11
	-15.0, 15.0, // 13
	-17.5, 17.5, // 15
	-20.0, 20.0, // 17
	-22.5, 22.5, // 19
	-25.0, 25.0 // 21
};
new const Float: flSendAnglesUp[ ] = { 
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
};

/* ~ [ Params ] ~ */
enum {
	WeaponAnim_Dummy,
	WeaponAnim_Idle,
	WeaponAnim_Slash1,
	WeaponAnim_Slash1_End,
	WeaponAnim_Slash_Loop,
	WeaponAnim_Slash_End,
	WeaponAnim_Slash_Skill,
	WeaponAnim_Stab1,
	WeaponAnim_Stab2,
	WeaponAnim_Stab12_End,
	WeaponAnim_Stab_Loop,
	WeaponAnim_Stab_End,
	WeaponAnim_Stab_Skill_Start,
	WeaponAnim_Stab_Skill_Loop,
	WeaponAnim_Stab_Skill_End,
	WeaponAnim_Draw
};

const Float: WeaponAnim_Idle_Time =				3.4;
const Float: WeaponAnim_Slash1_Time =			1.4;
const Float: WeaponAnim_Slash1_End_Time =		0.8;
const Float: WeaponAnim_Slash_Loop_Time =		0.7;
const Float: WeaponAnim_Slash_End_Time =		1.0;
const Float: WeaponAnim_Slash_Skill_Time =		1.0;
const Float: WeaponAnim_Stab12_Time =			1.4;
const Float: WeaponAnim_Stab12_End_Time =		0.7;
const Float: WeaponAnim_Stab_Loop_Time =		1.4;
const Float: WeaponAnim_Stab_End_Time =			1.0;
const Float: WeaponAnim_Stab_Skill_Start_Time =	1.0;
const Float: WeaponAnim_Stab_Skill_Loop_Time =	0.7;
const Float: WeaponAnim_Stab_Skill_End_Time =	0.7;
const Float: WeaponAnim_Draw_Time =				1.0;

enum {
	Sound_Hit1 = 0,
	Sound_Hit2,
	Sound_SlashSpecial_End,
	Sound_SlashSpecial_Start,
	Sound_SlashSpecial1,
	Sound_SlashSpecial2,
	Sound_SlashSpecial3,
	Sound_SlashSkill,
	Sound_Slash1,
	Sound_Slash2,
	Sound_Slash3,
	Sound_Slash123_End,
	Sound_StabSpecial_End,
	Sound_StabSpecial_Loop,
	Sound_StabSkill_Flying,
	Sound_StabSkill_Start,
	Sound_Stab1,
	Sound_Stab2,
	Sound_Stab3,
	Sound_Stab12_End,
	Sound_HitWall
};

enum {
	Effect_Slash = 0,
	Effect_SlashLoop,
	Effect_SlashSkill,
	Effect_Stab1,
	Effect_Stab2,
	Effect_StabLoop,
	Effect_StabSkill
};

enum (<<=1) {
	WeaponState_Slash = 1,
	WeaponState_Slash_Hit,
	WeaponState_Slash_End,

	WeaponState_SlashSpecial,
	WeaponState_SlashSpecial_End,

	WeaponState_SlashSkill,

	WeaponState_Stab,
	WeaponState_Stab_Hit,
	WeaponState_Stab_End,
	WeaponState_Stab_Anim,

	WeaponState_StabSpecial,
	WeaponState_StabSpecial_Hit,
	WeaponState_StabSpecial_LoopEnd,
	WeaponState_StabSpecial_End,

	WeaponState_StabSkill,
	WeaponState_StabSkill_End,

	WeaponState_ResetData
};

enum (<<=1) {
	HitResult_None = 1,
	HitResult_World,
	HitResult_Entity
};

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif
new gl_bitUserConnected;
new gl_iszAllocString_Effects;
#if defined _api_muzzleflash_included
	new MuzzleFlash: gl_iMuzzleId_Crosshair;
#endif

/* ~ [ Offsets ] ~ */
const linux_diff_weapon =						4;
const linux_diff_player =						5;
const linux_diff_animating =					5;
const m_flFrameRate =							36;
const m_flGroundSpeed =							37;
const m_flLastEventCheck =						38;
const m_fSequenceFinished =						39;
const m_fSequenceLoops =						40;
const m_pPlayer =								41;
const m_Weapon_flTimeWeaponIdle =				48;
const m_Weapon_flNextPrimaryAttack =			46;
const m_Weapon_flNextSecondaryAttack =			47;
const m_Weapon_iGlock18ShotsFired =				70;
const m_Weapon_iFamasShotsFired =				72;
const m_Activity =								73;
const m_IdealActivity =							74;
const m_Weapon_iWeaponState =					74;
const m_LastHitGroup = 							75;
const m_Weapon_flNextReload =					75;
const m_Weapon_flDecreaseShotsFired =			76;
const m_flNextAttack =							83;
const m_flVelocityModifier =					108;
const m_iTeam =									114;
const m_flLastAttackTime =						220;
const m_rgpPlayerItems =						367;
const m_pActiveItem =							373;
const m_szAnimExtention =						492;

/* ~ [ Macroses ] ~ */
#define DONT_BLEED								-1
#define PDATA_SAFE								2
#define KNIFE_SLOT								3
#define ACT_RANGE_ATTACK1						28

#define Vector3(%0)								Float: %0[ 3 ]
#define is_nullent(%0)							( %0 == 0 || pev_valid ( %0 ) != PDATA_SAFE )
#define IsCustomWeapon(%0,%1)					bool: ( pev( %0, pev_impulse ) == %1 )
#define GetWeaponState(%0)						get_pdata_int( %0, m_Weapon_iWeaponState, linux_diff_weapon )
#define SetWeaponState(%0,%1)					set_pdata_int( %0, m_Weapon_iWeaponState, %1, linux_diff_weapon )
#define GetUserKnife(%0)						get_pdata_cbase( %0, m_rgpPlayerItems + KNIFE_SLOT, linux_diff_player )

#define BIT(%0)									( 1 <<( %0 & 31 ) )
#define BIT_SUB(%0,%1)							( %0 &= ~%1 )
#define BIT_ADD(%0,%1)							( %0 |= %1 )
#define BIT_VALID(%0,%1)						( %0 & %1 )
#define BIT_INVERT(%0,%1)						( %0 ^= %1 )
#define BIT_CLEAR(%0)							( %0 = 0 )

#define pev_effect_cached						pev_weaponanim
#define pev_entity_state						pev_flSwimTime
#define pev_body_cached							pev_flTimeStepSound

#if defined _api_muzzleflash_included
	#define pev_muzzle_cached						pev_flDuckTime
#endif

#define m_Weapon_iSlashCount					m_Weapon_iGlock18ShotsFired
#define m_Weapon_iStabCount						m_Weapon_iFamasShotsFired
#define m_Weapon_flStabSpecialTime				m_Weapon_flDecreaseShotsFired

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( "zp_give_user_whipsword", "CBasePlayer__GiveKnife", 1 );
	register_native( "zp_get_user_whipsword", "CBasePlayer__GetKnife", 1 );
	register_native( "zp_remove_user_whipsword", "CBasePlayer__RemoveKnife", 1 );
}

public plugin_precache( )
{
	new iFile;

	#if defined _api_muzzleflash_included
		/* -> Muzzle Flash -> */
		gl_iMuzzleId_Crosshair = zc_muzzle_init( );
		{
			zc_muzzle_set_property( gl_iMuzzleId_Crosshair, ZC_MUZZLE_SPRITE, "sprites/g3bsprite/whipsword_aim.spr" );
			zc_muzzle_set_property( gl_iMuzzleId_Crosshair, ZC_MUZZLE_SCALE, 0.03 );
			zc_muzzle_set_property( gl_iMuzzleId_Crosshair, ZC_MUZZLE_FLAGS, MuzzleFlashFlag_Static );
		}
	#endif

	/* -> Precache Models -> */
	engfunc( EngFunc_PrecacheModel, WeaponViewModel );
	engfunc( EngFunc_PrecacheModel, WeaponPlayerModel );
	engfunc( EngFunc_PrecacheModel, EntityEffectsModel );

	/* -> Precache Sounds -> */
	for ( iFile = 0; iFile < sizeof WeaponSounds; iFile++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ iFile ] );

	#if defined WeaponListDir
		/* -> Hook Weapon -> */
		register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

		UTIL_PrecacheWeaponList( WeaponListDir );
	#endif

	/* -> Alloc String -> */
	gl_iszAllocString_Effects = engfunc( EngFunc_AllocString, EntityEffectsClassname );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> Events -> */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );

	#if defined _zombieplague_included
		register_event( "CurWeapon", "EV_CurWeapon", "be", "1=1" );
	#endif

	/* -> HamSandwich -> */
	#if defined WeaponListDir
		RegisterHam( Ham_Spawn, "player", "Ham_CBasePlayer__Spawn_Post", true );
	#endif

	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CBasePlayerWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CBasePlayerWeapon__Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CBasePlayerWeapon__PostFrame_Pre", false );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CBasePlayerWeapon__PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CBasePlayerWeapon__SecondaryAttack_Pre", false );

	RegisterHam( Ham_Think, EntityEffectsReference, "Ham_CBaseEntity__Think_Pre", false );

	/* -> Register on Extra-Items -> */
	#if defined _zombieplague_included && defined ExtraItem_Name
		gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
	#endif
}

public client_putinserver( pPlayer ) BIT_ADD( gl_bitUserConnected, BIT( pPlayer ) );
public client_disconnected( pPlayer ) BIT_SUB( gl_bitUserConnected, BIT( pPlayer ) );

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer )
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Zombie Plague ] ~ */
#if defined _zombieplague_included && defined ExtraItem_Name
	public zp_extra_item_selected( pPlayer, iItemId ) 
	{
		if ( iItemId != gl_iItemId ) 
			return PLUGIN_HANDLED;

		if ( CBasePlayer__GetKnife( pPlayer ) )
		{
			client_print( pPlayer, print_center, "You already have 'Plain Sword'" );
			return ZP_PLUGIN_HANDLED;
		}

		return CBasePlayer__GiveKnife( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
	}
#endif

#if defined _zombieplague_included
	public zp_user_infected_pre( pPlayer )
	{
		if ( !is_user_alive( pPlayer ) )
			return;

		CBasePlayer__RemoveKnife( pPlayer );
	}
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = pev( pPlayer, pev_iuser1 ) ) ? pev( pPlayer, pev_iuser2 ) : pPlayer;

	if ( !BIT_VALID( gl_bitUserConnected, BIT( pTarget ) ) )
		return;

	static pActiveItem; pActiveItem = get_pdata_cbase( pTarget, m_pActiveItem, linux_diff_player );
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

	static Float: flLastEventCheck; flLastEventCheck = get_pdata_float( pActiveItem, m_flLastEventCheck, linux_diff_weapon );
	if ( !flLastEventCheck )
	{
		set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_Dummy );
		return;
	}

	if ( flLastEventCheck <= get_gametime( ) )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, WeaponAnim_Draw );
		set_pdata_float( pActiveItem, m_flLastEventCheck, 0.0, linux_diff_weapon );
	}
}

/* ~ [ Events ] ~ */
public EV_RoundStart( )
{
	static pEntity; pEntity = FM_NULLENT;
	while ( ( pEntity = fm_find_ent_by_class( pEntity, EntityEffectsClassname ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

#if defined _zombieplague_included
	public EV_CurWeapon( const pPlayer )
	{
		if ( !is_user_alive( pPlayer ) || zp_get_user_zombie( pPlayer ) )
			return;

		static pActiveItem; pActiveItem = get_pdata_cbase( pPlayer, m_pActiveItem, linux_diff_player );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return;

		CBasePlayerWeapon__UpdateModel( pPlayer );
	}
#endif

/* ~ [ HamSandiwch ] ~ */
#if defined WeaponListDir
	// If you don't have a knife, but there is a WeaponList left
	public Ham_CBasePlayer__Spawn_Post( const pPlayer )
	{
		if ( !BIT_VALID( gl_bitUserConnected, BIT( pPlayer ) ) )
			return;

		static pItem; pItem = GetUserKnife( pPlayer );
		if ( !is_nullent( pItem ) && IsCustomWeapon( pItem, 0 ) )
			UTIL_WeaponList( MSG_ONE, pPlayer, WeaponReference );
	}
#endif

public Ham_CBasePlayerWeapon__Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	CBasePlayerWeapon__UpdateModel( pPlayer );

	static ModelViewParts[ 2 ];
	/**
	 * For example, you can put a native to get a human class with other hand textures
	 * Just change 'WeaponHandSubmodel' to your native
	 */
	ModelViewParts[ 0 ] = WeaponHandSubmodel;
	ModelViewParts[ 1 ] = 0;

	static iCalculatedBody; iCalculatedBody = CalculateModelBodyArr( ModelViewParts, { 2, 2 }, 2 );
	if ( pev( pItem, pev_body_cached ) != iCalculatedBody )
		set_pev( pItem, pev_body_cached, iCalculatedBody );

	set_pev( pItem, pev_body, pev( pItem, pev_body_cached ) );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	#if defined _api_muzzleflash_included
		new pSprite = FM_NULLENT;
		if ( ( pSprite = zc_muzzle_draw( pPlayer, gl_iMuzzleId_Crosshair ) ) && !is_nullent( pSprite ) )
			set_pev( pItem, pev_muzzle_cached, pSprite );
	#endif

	set_pdata_float( pItem, m_flLastEventCheck, get_gametime( ) + 0.1, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time, linux_diff_weapon );
	set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time, linux_diff_player );
}

public Ham_CBasePlayerWeapon__Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	emit_sound( pPlayer, CHAN_WEAPON, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	#if defined _api_muzzleflash_included
		if ( BIT_VALID( gl_bitUserConnected, BIT( pPlayer ) ) )
			zc_muzzle_destroy( pPlayer, gl_iMuzzleId_Crosshair );

		set_pev( pItem, pev_muzzle_cached, FM_NULLENT );
	#endif

	CBasePlayer__RemoveEffects( pPlayer );
	
	SetWeaponState( pItem, 0 );
	set_pdata_int( pItem, m_Weapon_iStabCount, 0, linux_diff_weapon );
	set_pdata_int( pItem, m_Weapon_iSlashCount, 0, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flNextReload, 0.0, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, 1.0, linux_diff_weapon );
	set_pdata_float( pPlayer, m_flNextAttack, 1.0, linux_diff_player );
}

public Ham_CBasePlayerWeapon__PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		static Float: flGameTime; flGameTime = get_gametime( );
		static pPlayer; pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );
		static bitsButton; bitsButton = pev( pPlayer, pev_button );

		static iSizeSendAnglesStab; if ( !iSizeSendAnglesStab ) iSizeSendAnglesStab = sizeof flSendAnglesRight;

		// Reset knife data
		if ( BIT_VALID( bitsWeaponState, WeaponState_ResetData ) )
		{
			set_pev( pItem, pev_body, pev( pItem, pev_body_cached ) );

			BIT_CLEAR( bitsWeaponState );

			set_pdata_int( pItem, m_Weapon_iStabCount, 0, linux_diff_weapon );
			set_pdata_int( pItem, m_Weapon_iSlashCount, 0, linux_diff_weapon );
			set_pdata_float( pPlayer, m_flNextAttack, 0.1, linux_diff_player );
		}

		// In Skill: Slash
		else if ( BIT_VALID( bitsWeaponState, WeaponState_SlashSkill ) )
		{
			BIT_ADD( bitsWeaponState, WeaponState_ResetData );

			CBasePlayerWeapon__RadiusDamage( pPlayer, pItem, WeaponSlashSkillRadius, WeaponSlashSkillDamage, WeaponSlashSkillKnockBack, DMG_GRENADE );
		}

		// In Skill: Stab
		else if ( BIT_VALID( bitsWeaponState, WeaponState_StabSkill ) )
		{
			// End Skill
			if ( BIT_VALID( bitsWeaponState, WeaponState_StabSkill_End ) )
			{
				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab_Skill_End );

				BIT_ADD( bitsWeaponState, WeaponState_ResetData );

				set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab_Skill_End_Time, linux_diff_weapon );
				set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Stab_Skill_End_Time, linux_diff_player );
			}

			// Hit
			else
			{
				BIT_ADD( bitsWeaponState, WeaponState_StabSkill_End );

				set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Stab_Skill_Start_Time - WeaponStabSkillNextAttack, linux_diff_player );
			}
		}

		// In Special Attack: Slash
		else if ( BIT_VALID( bitsWeaponState, WeaponState_SlashSpecial ) )
		{
			// End Attack
			if ( BIT_VALID( bitsWeaponState, WeaponState_SlashSpecial_End ) )
			{
				#if defined _api_muzzleflash_included
					static pSprite;
					if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
						set_pev( pSprite, pev_frame, 0.0 );
				#endif

				CBasePlayer__RemoveEffects( pPlayer );

				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash_End );
				emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_SlashSpecial_End ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

				BIT_ADD( bitsWeaponState, WeaponState_ResetData );

				set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash_End_Time, linux_diff_weapon );
				set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Slash1_End_Time, linux_diff_player );
			}

			// Hits
			else
			{
				static iSlashCount; iSlashCount = get_pdata_int( pItem, m_Weapon_iSlashCount, linux_diff_weapon );
				if ( ++iSlashCount && iSlashCount >= WeaponSlashSpecialAttacks )
				{
					BIT_ADD( bitsWeaponState, WeaponState_SlashSpecial_End );
					iSlashCount = 0;
				}

				CBasePlayerWeapon__RadiusDamage( pPlayer, pItem, WeaponSlashSpecialDistance, WeaponSlashSpecialDamage, _, DMG_BULLET );

				UTIL_FormatedPlayerAnimation( pPlayer, WeaponAnimation );
				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash_Loop );
				emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ random_num( Sound_SlashSpecial1, Sound_SlashSpecial3 ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

				set_pdata_int( pItem, m_Weapon_iSlashCount, iSlashCount, linux_diff_weapon );
				set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash_Loop_Time, linux_diff_weapon );
				set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Slash_Loop_Time - 0.2, linux_diff_player );
			}
		}

		// In Special Attack: Stab
		else if ( BIT_VALID( bitsWeaponState, WeaponState_StabSpecial ) )
		{
			// End Attack
			if ( BIT_VALID( bitsWeaponState, WeaponState_StabSpecial_End ) )
			{
				CBasePlayer__RemoveEffects( pPlayer );

				UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab_End );
				emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_StabSpecial_End ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

				BIT_ADD( bitsWeaponState, WeaponState_ResetData );

				set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab_End_Time, linux_diff_weapon );
				set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Stab_End_Time, linux_diff_player );
			}
			else
			{
				// Set End Attack
				if ( get_pdata_float( pItem, m_Weapon_flStabSpecialTime, linux_diff_weapon ) <= flGameTime )
				{
					#if defined _api_muzzleflash_included
						static pSprite;
						if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
							set_pev( pSprite, pev_frame, 0.0 );
					#endif

					BIT_ADD( bitsWeaponState, WeaponState_StabSpecial_End );
				}

				// Hits
				else
				{
					if ( BIT_VALID( bitsWeaponState, WeaponState_StabSpecial_Hit ) )
					{
						static bitsHitResult; bitsHitResult = UTIL_FakeTraceLine( pPlayer, pItem, WeaponStabSpecialDistance, WeaponStabSpecialDamage, DMG_BULLET, flSendAnglesRight, iSizeSendAnglesStab, flSendAnglesUp );

						CBasePlayerWeapon__HitSound( pPlayer, bitsHitResult );
						BIT_SUB( bitsWeaponState, WeaponState_StabSpecial_Hit );
					}

					#if defined _api_muzzleflash_included
						static pSprite;
						if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
							set_pev( pSprite, pev_frame, CBasePlayer__CanReachForTheWall( pPlayer, WeaponStabSkillDistance ) ? 1.0 : 0.0 );
					#endif

					if ( pev( pPlayer, pev_weaponanim ) != WeaponAnim_Stab_Loop )
						UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab_Loop );

					UTIL_FormatedPlayerAnimation( pPlayer, WeaponAnimation );

					BIT_ADD( bitsWeaponState, WeaponState_StabSpecial_Hit );
					set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab_Loop_Time, linux_diff_weapon );
					set_pdata_float( pPlayer, m_flNextAttack, WeaponStabSpecialNextAttack, linux_diff_player );
				}
			}
		}

		// In Slash
		else if ( BIT_VALID( bitsWeaponState, WeaponState_Slash ) )
		{
			// Hits
			if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_Hit ) )
			{
				new bitsVictims, iHitGroup;
				static bitsHitResult; bitsHitResult = UTIL_FakeTraceLine( pPlayer, pItem, WeaponSlashDistance, WeaponSlashDamage, DMG_BULLET, flSendAnglesRight, 5, flSendAnglesUp, bitsVictims, iHitGroup );

				CBasePlayerWeapon__RadiusDamage( pPlayer, pItem, WeaponSlashDistance, WeaponSlashDamage, _, DMG_BULLET, bitsVictims, iHitGroup, bitsHitResult );

				CBasePlayerWeapon__HitSound( pPlayer, bitsHitResult );
				BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );
			}

			// End Attack
			else if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_End ) )
			{
				static Float: flNextReload;
				if ( ( flNextReload = get_pdata_float( pItem, m_Weapon_flNextReload, linux_diff_weapon ) ) && ( !flNextReload || flNextReload >= flGameTime ) )
					return HAM_IGNORED;

				if ( ~bitsButton & IN_ATTACK )
				{
					UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash1_End );
					emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_Slash123_End ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

					BIT_ADD( bitsWeaponState, WeaponState_ResetData );

					set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash1_End_Time, linux_diff_weapon );
					set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Slash1_End_Time, linux_diff_player );
				}
			}
		}

		// In Stab
		else if ( BIT_VALID( bitsWeaponState, WeaponState_Stab ) )
		{
			// Hits
			if ( BIT_VALID( bitsWeaponState, WeaponState_Stab_Hit ) )
			{
				static bitsHitResult; bitsHitResult = UTIL_FakeTraceLine( pPlayer, pItem, WeaponStabDistance, WeaponStabDamage, DMG_BULLET, flSendAnglesRight, iSizeSendAnglesStab, flSendAnglesUp );

				CBasePlayerWeapon__HitSound( pPlayer, bitsHitResult );
				BIT_SUB( bitsWeaponState, WeaponState_Stab_Hit );
			}

			// End Attack
			else if ( BIT_VALID( bitsWeaponState, WeaponState_Stab_End ) )
			{
				static Float: flNextReload;
				if ( ( flNextReload = get_pdata_float( pItem, m_Weapon_flNextReload, linux_diff_weapon ) ) && ( !flNextReload || flNextReload >= flGameTime ) )
					return HAM_IGNORED;

				if ( ~bitsButton & IN_ATTACK2 )
				{
					UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab12_End );
					emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_Stab12_End ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

					BIT_ADD( bitsWeaponState, WeaponState_ResetData );

					set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab12_End_Time, linux_diff_weapon );
					set_pdata_float( pPlayer, m_flNextAttack, WeaponAnim_Stab12_End_Time, linux_diff_player );
				}
			}
		}

		// Update WeaponState
		if ( bitsWeaponState != GetWeaponState( pItem ) )
			SetWeaponState( pItem, bitsWeaponState );
	}

	return HAM_IGNORED;
}

public Ham_CBasePlayerWeapon__WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) || get_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, linux_diff_weapon ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time, linux_diff_weapon );

	return HAM_SUPERCEDE;
}

public Ham_CBasePlayerWeapon__PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( BIT_VALID( bitsWeaponState, WeaponState_Stab ) || BIT_VALID( bitsWeaponState, WeaponState_SlashSpecial ) || BIT_VALID( bitsWeaponState, WeaponState_ResetData ) )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	#if defined _api_muzzleflash_included
		static pSprite;
	#endif

	if ( BIT_VALID( bitsWeaponState, WeaponState_StabSpecial ) )
	{
		if ( !CBasePlayer__CanReachForTheWall( pPlayer, WeaponStabSkillDistance ) )
			return HAM_SUPERCEDE;

		#if defined _api_muzzleflash_included
			if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
				set_pev( pSprite, pev_frame, 0.0 );
		#endif

		static bitsHitResult; bitsHitResult = UTIL_FakeTraceLine( pPlayer, pItem, WeaponStabSkillDistance, WeaponStabSkillDamage, DMG_BULLET, flSendAnglesRight, 11, flSendAnglesUp );

		CEffects__SpawnEntity( pPlayer, Effect_StabSkill );
		CBasePlayerWeapon__HitSound( pPlayer, bitsHitResult );
		CBasePlayer__PullToTheWall( pPlayer, WeaponStabSkillVelocity );

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab_Skill_Start );
		emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_StabSkill_Start ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		emit_sound( pPlayer, CHAN_ITEM, WeaponSounds[ Sound_StabSkill_Flying ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		BIT_SUB( bitsWeaponState, WeaponState_StabSpecial );
		BIT_ADD( bitsWeaponState, WeaponState_StabSkill );

		set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab_Skill_Start_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Stab_Skill_Start_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Stab_Skill_Start_Time, linux_diff_weapon );
		set_pdata_float( pPlayer, m_flNextAttack, WeaponStabSkillNextAttack, linux_diff_player );
	}
	else
	{
		static iSlashCount; iSlashCount = get_pdata_int( pItem, m_Weapon_iSlashCount, linux_diff_weapon );
		if ( ++iSlashCount && iSlashCount >= 5 )
		{
			#if defined _api_muzzleflash_included
				if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
					set_pev( pSprite, pev_frame, 1.0 );
			#endif

			CEffects__SpawnEntity( pPlayer, Effect_SlashLoop );
			CBasePlayerWeapon__UpdateWeaponBody( pPlayer, pItem );

			emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_SlashSpecial_Start ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			iSlashCount = 0;
			BIT_SUB( bitsWeaponState, WeaponState_Slash );
			BIT_ADD( bitsWeaponState, WeaponState_SlashSpecial );
		}
		else
		{
			CEffects__SpawnEntity( pPlayer, Effect_Slash );

			UTIL_FormatedPlayerAnimation( pPlayer, WeaponAnimation );
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash1 );
			emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ random_num( Sound_Slash1, Sound_Slash3 ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			BIT_ADD( bitsWeaponState, WeaponState_Slash|WeaponState_Slash_Hit|WeaponState_Slash_End );
			set_pdata_float( pPlayer, m_flNextAttack, WeaponSlashHitTime, linux_diff_player );
		}

		BIT_SUB( bitsWeaponState, WeaponState_Stab );

		set_pdata_int( pItem, m_Weapon_iSlashCount, iSlashCount, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash1_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextReload, get_gametime( ) + WeaponSlashNextAttack, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, WeaponSlashNextAttack, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextSecondaryAttack, WeaponSlashNextAttack, linux_diff_weapon );
	}

	if ( bitsWeaponState != GetWeaponState( pItem ) )
		SetWeaponState( pItem, bitsWeaponState );

	return HAM_SUPERCEDE;
}

public Ham_CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( BIT_VALID( bitsWeaponState, WeaponState_Slash ) || BIT_VALID( bitsWeaponState, WeaponState_StabSpecial ) || BIT_VALID( bitsWeaponState, WeaponState_ResetData ) )
		return HAM_SUPERCEDE;

	static Float: flGameTime; flGameTime = get_gametime( );
	static pPlayer; pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	if ( BIT_VALID( bitsWeaponState, WeaponState_SlashSpecial ) )
	{
		#if defined _api_muzzleflash_included
			static pSprite;
			if ( ( pSprite = pev( pItem, pev_muzzle_cached ) ) && !is_nullent( pSprite ) )
				set_pev( pSprite, pev_frame, 0.0 );
		#endif

		CEffects__SpawnEntity( pPlayer, Effect_SlashSkill );

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash_Skill );
		emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_SlashSkill ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		BIT_SUB( bitsWeaponState, WeaponState_SlashSpecial );
		BIT_ADD( bitsWeaponState, WeaponState_SlashSkill );

		set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash_Skill_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Slash_Skill_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Slash_Skill_Time, linux_diff_weapon );
		set_pdata_float( pPlayer, m_flNextAttack, WeaponSlashSkillNextAttack, linux_diff_player );
	}
	else
	{
		static iStabCount; iStabCount = get_pdata_int( pItem, m_Weapon_iStabCount, linux_diff_weapon );
		if ( ++iStabCount && iStabCount >= 5 )
		{
			CEffects__SpawnEntity( pPlayer, Effect_StabLoop );
			CBasePlayerWeapon__UpdateWeaponBody( pPlayer, pItem );

			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Stab_Loop );
			emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_StabSpecial_Loop ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			iStabCount = 0;
			BIT_SUB( bitsWeaponState, WeaponState_Stab );
			BIT_ADD( bitsWeaponState, WeaponState_StabSpecial|WeaponState_StabSpecial_Hit );

			set_pdata_float( pItem, m_Weapon_flStabSpecialTime, flGameTime + WeaponStabSpecialAttacks * WeaponStabSpecialNextAttack, linux_diff_weapon );
		}
		else
		{
			CEffects__SpawnEntity( pPlayer, Effect_Stab1 + ( BIT_VALID( bitsWeaponState, WeaponState_Stab_Anim ) ? 1 : 0 ) );
			
			UTIL_FormatedPlayerAnimation( pPlayer, WeaponAnimation );
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, BIT_VALID( bitsWeaponState, WeaponState_Stab_Anim ) ? WeaponAnim_Stab2 : WeaponAnim_Stab1 );
			emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ random_num( Sound_Stab1, Sound_Stab3 ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			BIT_ADD( bitsWeaponState, WeaponState_Stab|WeaponState_Stab_Hit|WeaponState_Stab_End );
			BIT_INVERT( bitsWeaponState, WeaponState_Stab_Anim );
			set_pdata_float( pPlayer, m_flNextAttack, WeaponStabHitTime, linux_diff_player );
		}

		BIT_SUB( bitsWeaponState, WeaponState_Slash );

		set_pdata_int( pItem, m_Weapon_iStabCount, iStabCount, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Stab12_Time, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextReload, flGameTime + WeaponStabNextAttack, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, WeaponStabNextAttack, linux_diff_weapon );
		set_pdata_float( pItem, m_Weapon_flNextSecondaryAttack, WeaponStabNextAttack, linux_diff_weapon );
	}

	if ( bitsWeaponState != GetWeaponState( pItem ) )
		SetWeaponState( pItem, bitsWeaponState );

	return HAM_SUPERCEDE;
}

public Ham_CBaseEntity__Think_Pre( const pEntity )
{
	if ( is_nullent( pEntity ) )
		return HAM_IGNORED;

	if ( pev( pEntity, pev_classname ) != gl_iszAllocString_Effects )
		return HAM_IGNORED;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLifeTime; pev( pEntity, pev_ltime, flLifeTime );
	if ( flLifeTime <= flGameTime )
	{
		static iEffectState; iEffectState = pev( pEntity, pev_entity_state );
		if ( EntityEffectsData[ iEffectState ][ 2 ] ) // Loop animation
		{
			set_pev( pEntity, pev_ltime, flGameTime + Float: EntityEffectsData[ iEffectState ][ 1 ] );
			UTIL_SetEntityAnim( pEntity, iEffectState );
		}
		else
		{
			UTIL_KillEntity( pEntity );
			return HAM_IGNORED;
		}
	}

	set_pev( pEntity, pev_nextthink, flGameTime + 0.05 );
	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
public CBasePlayerWeapon__UpdateModel( const pPlayer )
{
	set_pev( pPlayer, pev_viewmodel2, WeaponViewModel );
	set_pev( pPlayer, pev_weaponmodel2, WeaponPlayerModel );

	set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation, -1, linux_diff_player * linux_diff_animating );
}

public CBasePlayerWeapon__UpdateWeaponBody( const pPlayer, const pItem )
{
	static ModelViewParts[ 2 ];
	/**
	 * For example, you can put a native to get a human class with other hand textures
	 * Just change 'WeaponHandSubmodel' to your native
	 */
	ModelViewParts[ 0 ] = WeaponHandSubmodel;
	ModelViewParts[ 1 ] = 1;

	set_pev( pItem, pev_body, CalculateModelBodyArr( ModelViewParts, { 2, 2 }, 2 ) );
}

public CBasePlayerWeapon__HitSound( const pPlayer, const bitsHitResult )
{
	if ( !bitsHitResult )
		return;

	if ( BIT_VALID( bitsHitResult, HitResult_Entity ) )
		emit_sound( pPlayer, CHAN_STATIC, WeaponSounds[ random_num( Sound_Hit1, Sound_Hit2 ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	else if ( BIT_VALID( bitsHitResult, HitResult_World ) )
		emit_sound( pPlayer, CHAN_STATIC, WeaponSounds[ Sound_HitWall ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

/**
 * @param bitsIgnore			Bitsum of ignored enemies
 * @param iHitGroup				To which hit group to send a traceline
 * @param bitsHitsResult		Bitsum of hits (for sounds)
 */
CBasePlayerWeapon__RadiusDamage( const pAttacker, const pInflictor, const Float: flRadius, const Float: flDamage, const Float: flKnockBack = 0.0, const bitsDamageType, const bitsIgnore = 0, const iHitGroup = HIT_CHEST, &bitsHitResult = 0 )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pAttacker, vecStart );
	new Vector3( vecEndPos );
	new pTrace = create_tr2( ), Float: flFraction;

	new aPlayers[ 32 ], iPlayersNum;
	get_players( aPlayers, iPlayersNum, "aeh", "TERRORIST" );

	/**
	 * Yes, I could do damage to the sphere so that the entity also counts,
	 * but I thought it was unnecessary, since unnecessary searches for
	 * unnecessary entities are called (weaponbox, etc. from the map)
	 */
	for ( new i = 0, pVictim = FM_NULLENT; i < iPlayersNum; i++ )
	{
		pVictim = aPlayers[ i ];
		if ( !BIT_VALID( gl_bitUserConnected, BIT( pVictim ) ) )
			continue;

		if ( bitsIgnore & BIT( pVictim ) )
			continue;

		pev( pVictim, pev_origin, vecEndPos );
		if ( xs_vec_distance( vecStart, vecEndPos ) > flRadius )
			continue;

		if ( pev( pVictim, pev_takedamage ) == DAMAGE_NO )
			continue;

		if ( iHitGroup == HIT_HEAD )
		{
			UTIL_GetEyePosition( pVictim, vecEndPos );
			vecEndPos[ 2 ] += 8.0;
		}

		engfunc( EngFunc_TraceLine, vecStart, vecEndPos, DONT_IGNORE_MONSTERS, pAttacker, pTrace );

		get_tr2( pTrace, TR_flFraction, flFraction );
		if ( flFraction == 1.0 )
			continue;

		UTIL_FakeTraceAttack( pVictim, pInflictor, pAttacker, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecEndPos, pTrace, bitsDamageType );

		if ( flKnockBack > 0.0 )
			UTIL_PlayerKnockBack( pVictim, pAttacker, flKnockBack * 5.0 );

		BIT_ADD( bitsHitResult, HitResult_Entity );
	}

	free_tr2( pTrace );
}

public bool: CBasePlayer__CanReachForTheWall( const pPlayer, const Float: flDistance )
{
	static Vector3( vecPunchAngle ); pev( pPlayer, pev_punchangle, vecPunchAngle );
	static Vector3( vecViewAngle ); pev( pPlayer, pev_v_angle, vecViewAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );

	static Vector3( vecForward ); angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	static Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	static Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecForward, flDistance, vecEnd );

	static pTrace; pTrace = create_tr2( );
	engfunc( EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace );

	static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
	if ( engfunc( EngFunc_PointContents, vecEndPos ) == CONTENTS_SKY )
	{
		free_tr2( pTrace );
		return false;
	}

	static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
	free_tr2( pTrace );

	return ( flFraction != 1.0 ) ? true : false;
}

public CBasePlayer__PullToTheWall( const pPlayer, const Float: flSpeed )
{
	static Vector3( vecViewAngle ); pev( pPlayer, pev_v_angle, vecViewAngle );

	// The fix of looking at the floor
	vecViewAngle[ 0 ] = floatmin( -15.0, vecViewAngle[ 0 ] );
	
	static Vector3( vecPunchangle ); pev( pPlayer, pev_punchangle, vecPunchangle );

	xs_vec_add( vecViewAngle, vecPunchangle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecViewAngle );

	static Vector3( vecVelocity );
	xs_vec_mul_scalar( vecViewAngle, flSpeed, vecVelocity );

	set_pev( pPlayer, pev_velocity, vecVelocity );
}

public bool: CBasePlayer__GiveKnife( const pPlayer )
{
	if ( !BIT_VALID( gl_bitUserConnected, BIT( pPlayer ) ) )
		return false;

	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = GetUserKnife( pPlayer );
	if ( is_nullent( pItem ) )
		return false;

	#if defined WeaponListDir
		UTIL_WeapPickup( MSG_ONE, pPlayer, CSW_KNIFE );
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir );
	#endif

	set_pev( pItem, pev_impulse, WeaponUnicalIndex );
	emit_sound( pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	new pActiveItem = get_pdata_cbase( pPlayer, m_pActiveItem, linux_diff_player );
	if( !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
	{
		ExecuteHamB( Ham_Item_Deploy, pActiveItem );

		#if defined _zombieplague_included
			EV_CurWeapon( pPlayer );
		#endif
	}

	return IsCustomWeapon( pItem, WeaponUnicalIndex ) ? true : false;
}

public bool: CBasePlayer__GetKnife( const pPlayer )
{
	if ( !BIT_VALID( gl_bitUserConnected, BIT( pPlayer ) ) )
		return false;

	new pItem = GetUserKnife( pPlayer );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return false;

	return true;
}

public bool: CBasePlayer__RemoveKnife( const pPlayer )
{
	if ( !BIT_VALID( gl_bitUserConnected, BIT( pPlayer ) ) )
		return false;

	new pItem = GetUserKnife( pPlayer );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return false;

	#if defined WeaponListDir
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponReference );
	#endif

	#if defined _api_muzzleflash_included
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId_Crosshair );
		set_pev( pItem, pev_muzzle_cached, FM_NULLENT );
	#endif

	CBasePlayer__RemoveEffects( pPlayer );

	// Clear attack state before removing its custom identity.
	Ham_CBasePlayerWeapon__Holster_Post( pItem );
	set_pev( pItem, pev_impulse, 0 );
	return true;
}

public CBasePlayer__RemoveEffects( const pPlayer )
{
	static pEntity; pEntity = FM_NULLENT;
	while ( ( pEntity = fm_find_ent_by_owner( pEntity, EntityEffectsClassname, pPlayer ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

public CEffects__SpawnEntity( const pPlayer, const iEffectState )
{
	static Float: flGameTime; flGameTime = get_gametime( );

	new pEntity = fm_find_ent_by_owner( FM_NULLENT, EntityEffectsClassname, pPlayer );
	if ( is_nullent( pEntity ) )
	{
		if ( ( pEntity = fm_create_entity( EntityEffectsReference ) ) && is_nullent( pEntity ) )
			return FM_NULLENT;
	}

	static bool: bAimEnt; bAimEnt = EntityEffectsData[ iEffectState ][ 3 ];

	set_pev_string( pEntity, pev_classname, gl_iszAllocString_Effects );
	set_pev( pEntity, pev_movetype, MOVETYPE_FOLLOW );
	set_pev( pEntity, pev_owner, pPlayer );
	set_pev( pEntity, pev_aiment, bAimEnt ? pPlayer : FM_NULLENT );
	set_pev( pEntity, pev_entity_state, iEffectState );
	set_pev( pEntity, pev_body, EntityEffectsData[ iEffectState ][ 0 ] );
	set_pev( pEntity, pev_ltime, flGameTime + Float: EntityEffectsData[ iEffectState ][ 1 ] );
	set_pev( pEntity, pev_nextthink, flGameTime );

	if ( !bAimEnt )
	{
		static Vector3( vecOrigin ); pev( pPlayer, pev_origin, vecOrigin );
		if ( pev( pPlayer, pev_flags ) & FL_DUCKING )
			vecOrigin[ 2 ] += 16.0;

		set_pev( pEntity, pev_origin, vecOrigin );

		static Vector3( vecAngles ); pev( pPlayer, pev_angles, vecAngles );
		vecAngles[ 0 ] = 0.0;
		set_pev( pEntity, pev_angles, vecAngles );
	}

	engfunc( EngFunc_SetModel, pEntity, EntityEffectsModel );

	UTIL_SetEntityAnim( pEntity, iEffectState );

	return pEntity;
}

/* ~ [ Stocks ] ~ */

// https://dev-cs.ru/threads/222/page-7#post-77015
stock CalculateModelBodyArr( const parts[ ], const sizes[ ], const count )
{
	static bodyInt32 = 0, temp = 0, it = 0, tempCount; bodyInt32 = 0; tempCount = count;
	while ( tempCount-- )
	{
		if ( sizes[ tempCount ] == 1 )
			continue;

		temp = parts[ tempCount ];
		for ( it = 0; it < tempCount; it++ )
			temp *= sizes[it];

		bodyInt32 += temp;
	}
	return bodyInt32;
}

/* -> Automaticly precache WeaponList <- */
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

		engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
	}

	fclose( pFile );
}

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = pev( pItem, pev_body );
	set_pev( pReceiver, pev_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

	if ( pev( pReceiver, pev_iuser1 ) )
		return;

	static i, iCount, pSpectator, iszSpectators[ MAX_PLAYERS ];
	get_players( iszSpectators, iCount, "bch" );

	for ( i = 0; i < iCount; i++ )
	{
		pSpectator = iszSpectators[ i ];

		if ( pev( pSpectator, pev_iuser1 ) != OBS_IN_EYE )
			continue;

		if ( pev( pSpectator, pev_iuser2 ) != pReceiver )
			continue;

		set_pev( pSpectator, pev_weaponanim, iAnim );

		message_begin( iDest, SVC_WEAPONANIM, .player = pSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity ) 
{
	set_pev( pEntity, pev_flags, FL_KILLME );
	set_pev( pEntity, pev_nextthink, get_gametime( ) );
}

/* -> WeapPickup <- */
stock UTIL_WeapPickup( const iDest, const pReceiver, const iWeaponId )
{
	static iMsgId_WeapPickup; if ( !iMsgId_WeapPickup ) iMsgId_WeapPickup = get_user_msgid( "WeapPickup" );

	message_begin( iDest, iMsgId_WeapPickup, .player = pReceiver );
	write_byte( iWeaponId );
	message_end();
}

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
	write_string( szWeaponName );
	write_byte( ( iPrimaryAmmoType <= -2 ) ? WeaponListData[ 0 ] : iPrimaryAmmoType );
	write_byte( ( iMaxPrimaryAmmo <= -2 ) ? WeaponListData[ 1 ] : iMaxPrimaryAmmo );
	write_byte( ( iSecondaryAmmoType <= -2 ) ? WeaponListData[ 2 ] : iSecondaryAmmoType );
	write_byte( ( iMaxSecondaryAmmo <= -2 ) ? WeaponListData[ 3 ] : iMaxSecondaryAmmo );
	write_byte( ( iSlot <= -2 ) ? WeaponListData[ 4 ] : iSlot );
	write_byte( ( iPosition <= -2 ) ? WeaponListData[ 5 ] : iPosition );
	write_byte( ( iWeaponId <= -2 ) ? WeaponListData[ 6 ] : iWeaponId );
	write_byte( ( iFlags <= -2 ) ? WeaponListData[ 7 ] : iFlags );
	message_end( );
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); pev( pPlayer, pev_origin, vecOrigin );
	static Vector3( vecViewOfs ); pev( pPlayer, pev_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce )
{
	static Vector3( vecOrigin ); pev( pVictim, pev_origin, vecOrigin );
	static Vector3( vecVelocity ); pev( pVictim, pev_velocity, vecVelocity );
	static Vector3( vecAttackerOrigin ); pev( pAttacker, pev_origin, vecAttackerOrigin );
	static Vector3( vecDirection ); xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
	static Float: flLen; flLen = xs_vec_len_2d( vecDirection );
    if (flLen <= 0.001) return;

	for ( new i = 0; i < 2; ++i )
		vecVelocity[ i ] = ( vecDirection[ i ] / flLen ) * flForce;

	set_pev( pVictim, pev_velocity, vecVelocity );
	set_pdata_float( pVictim, m_flVelocityModifier, 1.0, linux_diff_player );
}

/* -> Formated Player Animation <- */
stock UTIL_FormatedPlayerAnimation( const pPlayer, const szAnimExtention[ ] )
{
	static szAnimation[ 32 ];
	formatex( szAnimation, charsmax( szAnimation ), pev( pPlayer, pev_flags ) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", szAnimExtention );
	UTIL_PlayerAnimation( pPlayer, szAnimation );
}

/* -> Player Animation <- */
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

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_pev( pEntity, pev_frame, flFrame );
	set_pev( pEntity, pev_framerate, flFrameRate );
	set_pev( pEntity, pev_animtime, get_gametime( ) );
	set_pev( pEntity, pev_sequence, iSequence );
}

/* -> TE_BLOODSPRITE <- */
stock UTIL_TE_BLOODSPRITE( const Float: vecOrigin[ 3 ], const iColor, iAmount )
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

/* -> Fake TraceLine <- */
stock UTIL_FakeTraceLine( const pPlayer, const pInflictor, const Float: flDistance, const Float: flDamage, const bitsDamageType, const Float: flSendAnglesRight[ ], const iSendAnglesRight, const Float: flSendAnglesUp[ ], &bitsVictims = 0, &iHitGroup = HIT_CHEST )
{
	new bitsHitResult;
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );

	new Vector3( vecViewAngle ); pev( pPlayer, pev_v_angle, vecViewAngle );
	new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

	xs_vec_mul_scalar( vecForward, flDistance, vecForward );

	new Float: flTan, Vector3( vecEnd ), Vector3( vecEndPos );
	new pTrace = create_tr2( ), pHit, Float: flFraction;

	for ( new i; i < iSendAnglesRight; i++ )
	{
		flTan = floattan( flSendAnglesRight[ i ], degrees );
		vecEnd[ 0 ] = vecForward[ 0 ] + ( vecRight[ 0 ] * flTan * flDistance ) + ( vecUp[ 0 ] * flSendAnglesUp[ i ] );
		vecEnd[ 1 ] = vecForward[ 1 ] + ( vecRight[ 1 ] * flTan * flDistance ) + ( vecUp[ 1 ] * flSendAnglesUp[ i ] );
		vecEnd[ 2 ] = vecForward[ 2 ] + ( vecRight[ 2 ] * flTan * flDistance ) + ( vecUp[ 2 ] * flSendAnglesUp[ i ] );
		xs_vec_add_scaled( vecStart, vecEnd, flDistance / xs_vec_len( vecEnd ), vecEnd );

		engfunc( EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace );
		get_tr2( pTrace, TR_flFraction, flFraction );

		if ( flFraction == 1.0 )
		{
			engfunc( EngFunc_TraceHull, vecStart, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, pPlayer, pTrace );
			get_tr2( pTrace, TR_flFraction, flFraction );

			if ( flFraction == 1.0 )
			{
				BIT_ADD( bitsHitResult, HitResult_None );
				continue;
			}

			engfunc( EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace );
			get_tr2( pTrace, TR_flFraction, flFraction );

			if ( flFraction == 1.0 )
			{
				BIT_ADD( bitsHitResult, HitResult_None );
				continue;
			}

			pHit = get_tr2( pTrace, TR_pHit );
		}
		else pHit = get_tr2( pTrace, TR_pHit );

		if ( is_nullent( pHit ) )
		{
			BIT_ADD( bitsHitResult, HitResult_World );
			continue;
		}

		BIT_ADD( bitsHitResult, HitResult_Entity );

		if ( BIT_VALID( bitsVictims, BIT( pHit ) ) )
			continue;

		get_tr2( pTrace, TR_vecEndPos, vecEndPos );

		UTIL_FakeTraceAttack( pHit, pInflictor, pPlayer, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecEndPos, pTrace, bitsDamageType );

		iHitGroup = get_tr2( pTrace, TR_iHitgroup );

		if ( is_user_alive( pHit ) )
			BIT_ADD( bitsVictims, BIT( pHit ) );
	}

	free_tr2( pTrace );
	return bitsHitResult;
}

/* -> Fake TraceAttack <- */
stock UTIL_FakeTraceAttack( const pVictim, const pInflictor, const pAttacker, const Float: flBaseDamage, const Vector3( vecDirection ), const pTrace, bitsDamageType )
{
	if ( pev( pVictim, pev_takedamage ) == DAMAGE_NO )
		return false;

	if ( is_user_alive( pVictim ) )
	{
		#if defined _zombieplague_included
			if ( !zp_get_user_zombie( pVictim ) )
				return false;
		#else
			if ( get_pdata_int( pVictim, m_iTeam, linux_diff_player ) == get_pdata_int( pAttacker, m_iTeam, linux_diff_player ) )
				return false;
		#endif
	}

	new Vector3( vecPunchAngle );
	static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
	static iHitGroup; iHitGroup = get_tr2( pTrace, TR_iHitgroup );
	static Float: flDamage; flDamage = flBaseDamage;

	switch ( iHitGroup )
	{
		case HIT_HEAD:
		{
			flDamage *= 4.0;
			vecPunchAngle[ 0 ] = floatmin( flDamage * -0.5, -12.0 );
			vecPunchAngle[ 2 ] = floatclamp( flDamage * random_float( -1.0, 1.0 ), -9.0, 9.0 );
		}
		case HIT_CHEST:
		{
			flDamage *= 1.0;
			vecPunchAngle[ 0 ] = floatmin( flDamage * -0.1, -4.0 );
		}
		case HIT_STOMACH:
		{
			flDamage *= 1.25;
			vecPunchAngle[ 0 ] = floatmin( flDamage * -0.1, -4.0 );
		}
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
	}

	if ( xs_vec_len( vecPunchAngle ) )
		set_pev( pVictim, pev_punchangle, vecPunchAngle );

	set_pdata_int( pVictim, m_LastHitGroup, iHitGroup, linux_diff_player );
	// Apply Bloody Blade once to melee hits; exclude explosive skill damage.
    if (!(bitsDamageType & DMG_GRENADE)) flDamage *= exhero_blade_multiplier(pAttacker, pVictim);
    ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType );

	static iBloodColor;
	if ( ( iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim ) ) != DONT_BLEED )
	{
		message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecEndPos );
		UTIL_TE_BLOODSPRITE( vecEndPos, iBloodColor, floatround( flDamage ) );

		ExecuteHamB( Ham_TraceBleed, pVictim, flDamage, vecDirection, pTrace, bitsDamageType );
	}

	return true;
}
