native Float:exhero_knife_range(kind=0);
native exhero_damage(victim,inflictor,attacker,Float:damage,bits,const ability[]);
native exhero_report_hit(victim,attacker,Float:before,const label[]);
/*
 * ============================================================================
 *
 *   ®---> https://cso.fandom.com/wiki/Impulse_Flail <---®
 *
 *  Copyright (C) 2025 StarGamerz. All Rights Reserved.
 *  This file is part of a PRIVATE PRODUCTION by StarGamerz.
 *
 *  Unauthorized copying, distribution, modification, or use of this file,
 *  via any medium, is strictly prohibited without the express written
 *  permission of StarGamers. in order to share plugin , share discord ;- https://discord.gg/GwyqRHHHC8
 *
 *   ONLY CREDITS;-  xUnicorn Base Knife
 * ============================================================================
 */


/* ~ [ Plugin Info ] ~ */
new const PluginName[]    = "Tyrant Mace"; 
new const PluginVersion[] = "ExHero V2";
new const PluginAuthor[]  = "~x3 Queen Lama";

/* ~ [ Includes ] ~ */
#include < amxmodx >
#include < hamsandwich >
#include < fakemeta_util >
#include < xs >


// Comment this line out if you don't want zombie plague
#include < zombieplague >


#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

// Comment this line out if your server does NOT have ReAPI
#include < reapi >

/**
 * ReAPI support for Non-ReAPI servers
 * 
 * This file created by Yoshioka Haruki (xUnicorn a.k.a t3rkecorejz)
 * It's not final version of this include, new features will be added over time
 * 
 * Latest update: 20.10.2022
 */
#if !defined _reapi_included
    #tryinclude <non_reapi_support>
#endif

/**
 * Automatically precache sounds from the view model MDL sequence events.
 * Not needed if your server has ReHLDS with sv_auto_precache_sounds_in_models 1
 */
#define PrecacheSoundsFromModel

/**
 * When using this method, the weapon Speical Ammo will be charged constantly,
 * regardless of whether the player has it in his hands or not, the main thing is that it should be.
 */
#define EnableChargeAlways      // do not delete or comment this 

#if defined EnableChargeAlways
    #define TASK_CHARGE_CHECK(%1)    ( 90000 + (%1) )
#endif



#if defined _zombieplague_included
	/**
	 * Problem: in default ZP, if you give out a custom knife model, then, at the beginning of a new round,
	 * if you had a knife in your hands, then the model becomes ordinary v_knife.mdl
	 * 
	 * Enable a fix for this problem
	 */
	#define FixDefaultKnifeModelAfterSpawn
#endif

#if defined _zombieplague_included
	/* ~ [ Extra-Items ] ~ */
	// ExHero menu supplies the item.
	const ExtraItem_Cost =						10;
#endif




// #define WF_DEBUG // not needed anymore 


// Note: If you don't want to use muzzleflash, comment the line below
#define MuzzleFlashEnabled


#if defined MuzzleFlashEnabled
    new const szMuzzleClassName[ ] = "ent_whipfalil_muzzle";
    new const szMuzzleSprites[ ][ ] =
    {
        "sprites/whipflail/muzzleflash478.spr",
        "sprites/whipflail/aim_fx.spr"
    };

    const Muzzle_Frame_Max = 57;

    enum _: eMuzzleType
    {
        MuzzleType_Auto = 0,
        MuzzleType_PingPong
    }

    #define var_max_frames    var_yaw_speed
    #define var_loop_frames   var_playerclass
    #define var_update_frames var_ideal_yaw
    #define var_direction     var_fuser1 
    #define var_muzzle_stored_frame  var_fuser3     // this is not necassary but idk why it doesn't work with only var_frame in non_reapi , maybe cuz of pev_frame doesn't work the same way ?
#endif


/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =       676968823;    // Unique stamp — change if conflict
new const WeaponReference[ ] =   "weapon_knife";
new const WeaponAnimation[ ] =   "knife";    // Player body animation extension
new const WeaponAnimation_B[ ] = "grenade";    // Player body animation extension ON B
new const WeaponListDir[ ]     = "whipflail/weapon_knife_whipflail";  // weaponlist
new const WeaponModelView[ ]   = "models/g3bmodel/ZTHEX/whipflail/v_whipflail_1dx.mdl";
new const WeaponModelPlayer[ ] = "models/whipflail/p_whipflail.mdl";
const WeaponChargedBody =       1;    // Charged Submodel index

/* ~ [ Sounds ] ~ */
enum _: eSounds
{
    Sound_HitWall = 0,  // Hit world geometry
    Sound_slash_a1,         
    Sound_slash_a2,         
    Sound_Skill,            // Sound on mouse 2 release
    Sound_Skill_Exp1,        // Sound on mouse 2 release perfect hit 
    Sound_Skill_Reload,       // Reload + the location of slashc_hit_range 
    Sound_Charge_Released 
}

new const WeaponSounds[ eSounds ][] =
{
    "weapons/whipflail_slash_end.wav",
    "weapons/whipflail_slash_a1.wav",
    "weapons/whipflail_slash_a2.wav",
    "weapons/whipflail_skill1.wav",
    "weapons/whipflail_skill1_exp1.wav",
    "weapons/whipflail_skill2_exp.wav",
    "weapons/whipflail_skill2.wav"
}

/* ~ [ Attack Settings ] ~ */

// Primary Attack (M1) — Slash
const Float: WeaponSlashHitTime    = 0.2;   // Delay before hit registers in PostFrame
const Float: WeaponSlashNextAttack = 0.5;  // Full cooldown after slash
const Float: WeaponSlashDistance   = 200.0; // Reach
const Float: WeaponSlashDamage     = 200.0; // Base damage
const Float: WeaponSlashKnockBack  = 350.0; // Push force

// Primary Attack slash fan:
// { Count, StartAngle (Right), StepAngle (Right), StartAngle (Up), StepAngle (Up) }
new const Float: WeaponSlashDirection[] = { 19.0, -90.0, 10.0, 0.0, 0.0 }   // 180*
new const Float: WeaponChargeEndDirections[] = { 3.0, -30.0, 30.0, 0.0, 0.0 }


// Secondary Attack (M2) — charge
const Float: WeaponChargeRadius   = 225.0;  // Reach
const Float: WeaponChargeDamage   = 160.0;  // damage
const Float: WeaponChargeDamage_C = 320.0;  // damage charged C
const Float: WeaponChargeKnockBack  = 500.0;  // Push force
const Float: WeaponChargeKnockUp    = 250.0;

// Holding M2
const Float: WeaponLoopRadius   = 167.0;  // Reach      // 67 🥀
const Float: WeaponLoopDamage   = 54.0;  // damage
const Float: WeaponLoopDamage_C = 108.0;  // damage charged C

// Perfect hit Mouse 2
const Float: WeaponChargeRadius_Perfect   = 250.0;  // Reach
const Float: WeaponChargeDamage_Perfect   = 270.0;  // damage
const Float: WeaponChargeDamage_C_Perfect = 400.0;  // damage charged C
const Float: WeaponChargeKnockBack_Perfect  = 500.0;  // Push force

/* ~ [ Animation Settings ] ~ */
const Float: WeaponAnim_Idle_Time  = 3.03;
const Float: WeaponAnim_Draw_Time  = 1.03;
const Float: WeaponAnim_Slash_Time = 2.20;
const Float: WeaponAnim_Stab_Time  = 1.0;
const Float: WeaponAnim_StartSlash_Time = 0.70;
const Float: WeaponAnim_ChargeEnd_Time = 1.70;
const Float: WeaponAnim_Slash_C_Time = 1.70;

enum _: eAnims
{
    WeaponAnim_Idle = 0,
    WeaponAnim_Idle_C_Mode_On,
    WeaponAnim_Draw,
    WeaponAnim_Draw_C_Mode_On,
    WeaponAnim_Slash_A1,
    WeaponAnim_Slash_A1_C_Mode_On,
    WeaponAnim_Slash_A2,
    WeaponAnim_Slash_A2_C_Mode_On,
    WeaponAnim_Charge,
    WeaponAnim_Charge_C_Mode_On,
    WeaponAnim_Charge_End_1,
    WeaponAnim_Charge_End_1_C_Mode_On,
    WeaponAnim_Charge_End_2,
    WeaponAnim_Charge_End_2_C_Mode_On,
    WeaponAnim_Slash_C,
    WeaponAnim_Slash_C_Off,
    WeaponAnim_DummyXs
}

/* ~ [ Hit Result Bitflags ] ~ */
enum ( <<= 1 )
{
    HitResult_None   = 1,
    HitResult_World,
    HitResult_Entity
}

/* ~ [ Weapon State Bitflags ] ~ */
enum ( <<= 1 )
{
    WeaponState_Slash_Hit = 1,  // Slash hit pending registration
    WeaponState_Slash_End,      // Slash end anim pending
    WeaponState_Slash_Anim,     // Slash anim toggle (alternate between slash1/2)
    WeaponState_Charge_Start,   // Stab hit pending registration
    WeaponState_Charged_C       // WeaponState Charged Mode   

}

/* ~ [ Weapon Timer Type ] ~ */
enum WeaponTimerType
{
    Timer_PlayerNextAttack = 0,
    Timer_WeaponIdle,
    Timer_WeaponPrimaryAttack,
    Timer_WeaponSecondaryAttack
}

/* ~ [ Damage Type ] ~ */
const WeaponDamageType = ( DMG_BULLET | DMG_NEVERGIB )

/* ~ [ Macros ] ~ */
#define BIT_PLAYER(%0)      ( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)      ( %0 |= %1 )
#define BIT_SUB(%0,%1)      ( %0 &= ~%1 )
#define BIT_VALID(%0,%1)    ( ( %0 & %1 ) == %1 )
#define BIT_INVERT(%0,%1)   ( %0 ^= %1 )

#define IsUserValid(%0)         bool: ( 0 < %0 <= MaxClients )
#define IsUserConnected(%0)     bool: ( IsUserValid( %0 ) && BIT_VALID( gl_bitsUserConnected, BIT_PLAYER( %0 ) ) )
#define IsCustomWeapon(%0,%1)   bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)      get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)   set_member( %0, m_Weapon_iWeaponState, %1 )
#define WeaponHasMaxAmmo(%0)    bool: ( get_member( %0, m_rgAmmo, WeaponPrimaryAmmoIndex ) >= WeaponPrimaryAmmoMax )
#define Weapon_HasCMode(%0)     BIT_VALID( %0, WeaponState_Charged_C )

#define m_Weapon_iHitCount						m_Weapon_iGlock18ShotsFired 
const ChargedHitCount =				3;

/* ~ [ Timer Settings ] ~ */
#define var_next_charge         var_starttime       // pWeapon
#define var_next_loop_damage    var_fuser2          // pWeapon 

#define var_slashc_count    var_iuser3  // pEntity

/**
 * 
 * Entity States According To Models
 * Check enum ( <<= 1 ) EntityState_FadingOut, For Entity States 
 */
#define var_entity_state        var_iuser1          // pEntity

/**
 * 
 * Muzzle Types According To Muzzleflashes
 * Check enum szMuzzleSprites , For Muzzleflashes Types 
 */
#define var_muzzle_type         var_iuser4          // pEntity

/**
 * 
 * Entity Types According To Model
 * Check enum zEntityModelTypes , For Model Types 
 */
#define var_entity_type         var_iuser2        // pEntity



#if defined WeaponListDir
    const WeaponPrimaryAmmoIndex =    23; // 15-31 only, must not conflict with other custom weapons
    #if defined _reapi_included
        new const WeaponPrimaryAmmoName[ ] = "ammo_ascalon"
    #endif
#endif
const WeaponPrimaryAmmoMax     = 5;  
const WeaponPrimaryAmmoDefault = 1;

const Float: WeaponPrimaryAmmoChargeTime = 9.0;  // seconds per charge tick
const WeaponPrimaryAmmoGive              = 1;    // % given per tick
const Float: WeaponHasImpactReserved     = 0.0;  // placeholder, unused unless you build an impact state

/* ~ [ Reload Effect Settings ] ~ */
const Float: ReloadEffect_SideOffset  = 160.0;  // left / right offset from player
const Float: ReloadEffect_FrontOffset = 200.0;  // forward offset

const Float: ReloadEffect_ExplosionUp    = 10.0;
const Float: ReloadEffect_ExplosionScale = 8.0;
const ReloadEffect_ExplosionFramerate    = 20;
const SlashC_MaxRepeats = 2;


/* ~ [ Entity: Explosion Sprite ] ~ */
new const SzExplosionSprites[ ][ ] =
{
    "sprites/whipflail/ef_whipflail_SlashC_hit.spr",
    "sprites/whipflail/ef_whipflail_SlashC_hit1.spr",
    "sprites/whipflail/ef_whipflail_hit.spr"
};

enum _: ModelIndexes
{
    IndexSlashC_Hit = 0,
    IndexSlashC_Hit_1,
    Index_Hit,
    ModelIndexes_MaxCount 
}


new gl_izModelIndexed[ ModelIndexes_MaxCount ];



/* ~ [ Entity: Global ] ~ */
new const EntityGlobalReferences[ ] =			"info_target";


/* ~ [ Entity Model Types ] ~ */
enum _: zEntityModelTypes
{
    Type_Charge_B = 0,        
    Type_Charge_B_End1,  
    Type_Charge_B_End2,
    Type_SlashC,        // not used 
    Type_SlashC_Range           
}

new const zEntityModel[ zEntityModelTypes ][ ] =    // Combining Every Model Into One Is Not The Best Approach, It Can Cause Client Performance Issues
{
    "models/whipflail/misc/ef_whipflail_chargeB.mdl",
    "models/whipflail/misc/ef_whipflail_chargeB_endxxs1.mdl",
    "models/whipflail/misc/ef_whipflail_chargeB_end2.mdl",
    "models/whipflail/misc/ef_whipflail_SlashC_hit.mdl",
    "models/whipflail/misc/ef_whipflail_SlashCx_range.mdl"
}

/* ~ [ Entity : Charge B ] ~ */
new const Entity_Charge_B_Classname[ ] = "Ent_Da_Charge_B";
const Entity_Charge_B_Sequence = 0;
const Entity_Charge_B_Skin = 0;
const Float: Entity_Charge_B_Lifetime = 0.70;

/* ~ [ Entity : Charge B End 1 ] ~ */
new const Entity_Charge_B_End1_Classname[ ] = "Ent_Da_Charge_B_End1";
const Entity_Charge_B_End1_Skin = 0;
const Entity_Charge_B_End1_Skins = 26;
const Entity_Charge_B_End1_Sequence = 0;
const Float: Entity_Charge_B_End1_Lifetime = 1.70;
const Float: Entity_Charge_B_End1_Nextthink = 0.05; // 0.06 x 26( skins ) = Entity_Charge_B_End1_Lifetime ( 1.70 ) , used diff approach directly at think

/* ~ [ Entity : Charge B End 2 ] ~ */
new const Entity_Charge_B_End2_Classname[ ] = "Ent_Da_Charge_B_End2";
const Entity_Charge_B_End2_Skins = 12;
const Entity_Charge_B_End2_Sequence = 0;
const Float: Entity_Charge_B_End2_Lifetime = 1.03;
const Float: Entity_Charge_B_End2_Nextthink = 0.08;// 0.085 is a better choice but not necassary // 0.085 x 12( skins ) = Entity_Charge_B_End2_Lifetime ( 1.03 )

/* ~ [ Entity : Slash C ] ~ */
const Entity_Slash_C_Skins = 17;
const Float: Entity_Slash_C_Lifetime = 1.03;
const Float: Entity_Slash_C_Nextthink = 0.06; // 0.06 x 17( skins ) = Entity_Slash_C_Lifetime ( 1.03 )

/* ~ [ Entity : Slash C Range ] ~ */
new const Entity_Slash_C_Range_Classname[] = "Ent_Da_Slash_C_Range";
const Entity_Slash_C_Range_Skins = 4;
const Float: Entity_Slash_C_Range_Lifetime = 1.03;





/* ~ [ Fade Out Effect ] ~ */
const Float: Entity_FadeOut_Time     = 1.0;    // total fade duration
const Float: Entity_FadeOut_TickRate = 0.05;   // think interval during fade
const Float: Entity_FadeOut_Speed    = 12.75;  // 255.0 / (1.0 / 0.05) — alpha per tick

enum ( <<= 1 )
{
    EntityState_FadingOut = 1
}


/* ~ [ Global Parameters ] ~ */
new gl_bitsUserConnected
#if AMXX_VERSION_NUM <= 182
    new MaxClients
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif



#if !defined _reapi_included && defined WeaponListDir
    new gl_iMsgHook_WeaponList;
    new gl_FM_Hook_RegUserMsg_Post;
    new gl_aWeaponListData[ 8 ];
#endif

new Float: g_vecReloadOrigin[ MAX_PLAYERS + 1 ][ 3 ];
new Float: g_vecReloadAngles[ MAX_PLAYERS + 1 ][ 3 ];


/* ~ [ AMX Mod X ] ~ */
#if defined _zombieplague_included
    public plugin_natives( )
    {
        register_native("exhero_give_flail","ExHeroGive");
        register_native("exhero_remove_flail","ExHeroRemove");
        register_native( "zp_get_user_whipflail", "CPlayer_GetWeapon", 1 );
        register_native( "zp_give_user_whipflail", "CPlayer_GiveWeapon", 1 );
        register_native( "zp_delete_user_whipflail", "CPlayer_RemoveWeapon", 1 );
    }
#endif

public plugin_precache()
{
    precache_generic("sound/weapons/whipflail_charge.wav");
    precache_generic("sound/weapons/whipflail_charge_end.wav");
    precache_generic("sound/weapons/whipflail_draw.wav");
    precache_generic("sound/weapons/whipflail_slash_end.wav");

    precache_model_ex( WeaponModelView )
    precache_model_ex( WeaponModelPlayer )
    precache_model_ex( "models/null.mdl" )

    new i 

    for ( i = 0; i < sizeof WeaponSounds; i++ )
        engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] )

    for ( i = 0; i < sizeof zEntityModel; i++ )
        precache_model_ex( zEntityModel[ i ] )

    for( i = 0; i < sizeof SzExplosionSprites; i++ )
        gl_izModelIndexed[ i ] = precache_model_ex( SzExplosionSprites[ i ] )


#if defined MuzzleFlashEnabled
    for( i = 0; i < sizeof szMuzzleSprites; i++ )
        precache_model_ex( szMuzzleSprites[ i ] );
#endif

#if defined PrecacheSoundsFromModel
    UTIL_PrecacheSoundsFromModel( WeaponModelView )
#endif

#if defined WeaponListDir
    register_clcmd( WeaponListDir, "ClientCommand_HookWeapon" );

    UTIL_PrecacheWeaponList( WeaponListDir );

    #if !defined _reapi_included
        new iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

        if ( !iMsgId_Weaponlist )
            gl_FM_Hook_RegUserMsg_Post = register_forward( FM_RegUserMsg, "FM_Hook_RegUserMsg_Post", true );
        else
            gl_iMsgHook_WeaponList = register_message( iMsgId_Weaponlist, "MsgHook_WeaponList" );
    #endif
#endif


}

new g_ExHud;new bool:g_ExHudVisible[33];
public plugin_init()
{
 g_ExHud=CreateHudSyncObj();set_task(0.1,"ExHeroHud",0,"",0,"b");
 RegisterHam(Ham_Killed,"player","ExHeroKilled",1);
    /* -> https://cso.fandom.com/wiki/Impulse_Flail <- */
    register_plugin( PluginName, PluginVersion, PluginAuthor )

#if AMXX_VERSION_NUM <= 182
    #if defined _reapi_included
        MaxClients = get_member_game( m_nMaxPlayers )
    #else
        MaxClients = get_maxplayers()
    #endif
#endif

    /* -> FakeMeta <- */
    register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true )

    /* -> Events <- */
    register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );

#if defined _zombieplague_included && defined FixDefaultKnifeModelAfterSpawn
    register_event( "CurWeapon", "EV_CurWeapon", "be", "1=1" );
#endif


    /* -> HamSandWich <- */
    RegisterHam( Ham_Item_Deploy,            WeaponReference, "Ham_CWeapon_Deploy_Post",          true  )
    RegisterHam( Ham_Item_Holster,           WeaponReference, "Ham_CWeapon_Holster_Post",         true  )
    RegisterHam( Ham_Item_PostFrame,         WeaponReference, "Ham_CWeapon_PostFrame_Pre",        false )
    RegisterHam( Ham_Item_AddToPlayer,       WeaponReference, "Ham_CWeapon_AddToPlayer_Post",     true  )
    RegisterHam( Ham_Weapon_WeaponIdle,      WeaponReference, "Ham_CWeapon_WeaponIdle_Pre",       false )
    RegisterHam( Ham_Weapon_PrimaryAttack,   WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre",    false )
    RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre",  false )
    RegisterHam( Ham_Weapon_Reload,          WeaponReference, "Ham_CWeapon_Reload_Post",          true  )

    RegisterHam( Ham_Think, EntityGlobalReferences, "CInfoTarget__Think_Post", true );
    
#if !defined _reapi_included
    /* HamSandwich: Entity */
    RegisterHam( Ham_Think, "env_sprite", "CSpriteInfo__Think_Post", true );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
    /* -> Register on Extra-Items <- */
    gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

#if !defined _zombieplague_included
    /* -> Commands <- */
    register_clcmd( "say /whipf", "Command_GiveKnife" )
#endif


#if defined WeaponListDir && !defined _reapi_included
    /* -> Weaponlist <- */
    if ( gl_FM_Hook_RegUserMsg_Post )
        unregister_forward( FM_RegUserMsg, gl_FM_Hook_RegUserMsg_Post, true );

    unregister_message( get_user_msgid( "WeaponList" ), gl_iMsgHook_WeaponList );
#endif
}

public client_putinserver( pPlayer )  BIT_ADD( gl_bitsUserConnected, BIT_PLAYER( pPlayer ) )
public client_disconnected(pPlayer){ExHeroCleanup(pPlayer);BIT_SUB(gl_bitsUserConnected,BIT_PLAYER(pPlayer));}


#if defined WeaponListDir
    public ClientCommand_HookWeapon( const pPlayer )
    {
        engclient_cmd( pPlayer, WeaponReference );
        return PLUGIN_HANDLED;
    }
#endif


#if defined _zombieplague_included && defined ExtraItem_Name
	/* ~ [ Zombie Plague ] ~ */
	public zp_extra_item_selected( pPlayer, iItemId ) 
	{
		if ( iItemId != gl_iItemId )
			return PLUGIN_HANDLED;

		return CPlayer_GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
	}
#endif

/* ~ [ Command ] ~ */
public Command_GiveKnife( pPlayer )
{
    if ( !IsUserConnected( pPlayer ) || !is_user_alive( pPlayer ) )
        return PLUGIN_HANDLED

    new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_REPLACE, WeaponUnicalIndex )
    if ( is_nullent( pItem ) )
        return PLUGIN_HANDLED

    return PLUGIN_HANDLED
}

#if defined WeaponListDir && !defined _reapi_included
    public MsgHook_WeaponList( const iMsgId, const iMsgDest, const pReceiver )
    {
        if ( !pReceiver )
        {
            new szWeaponName[ 32 ];
            get_msg_arg_string( 1, szWeaponName, charsmax( szWeaponName ) );

            if ( strcmp( szWeaponName, WeaponReference ) != 0 )
                return;

            for ( new i, a = sizeof gl_aWeaponListData; i < a; i++ )
                gl_aWeaponListData[ i ] = get_msg_arg_int( i + 2 );
        }
    }

    public FM_Hook_RegUserMsg_Post( const szName[ ] )
    {
        if ( strcmp( szName, "WeaponList" ) == 0 )
            gl_iMsgHook_WeaponList = register_message( get_orig_retval( ), "MsgHook_WeaponList" );
    }
#endif


/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !IsUserConnected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pTarget, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );

        enum eSpecInfo 
        {
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
            set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_DummyXs );
            return;
        }

        if ( flLastEventCheck <= get_gametime( ) )
        {
            static bitsWeaponState; bitsWeaponState = GetWeaponState( pActiveItem )
            UTIL_SendWeaponAnim( pTarget, pActiveItem, Weapon_HasCMode( bitsWeaponState ) ? WeaponAnim_Draw_C_Mode_On : WeaponAnim_Draw )

            set_member( pActiveItem, m_flLastEventCheck, 0.0 );
        }
}

/* ~ [ Events ] ~ */
public EV_RoundStart( )
{
	UTIL_DestroyEntitiesByClass( Entity_Charge_B_Classname );
    UTIL_DestroyEntitiesByClass( Entity_Charge_B_End1_Classname );
    UTIL_DestroyEntitiesByClass( Entity_Charge_B_End2_Classname );
    UTIL_DestroyEntitiesByClass( Entity_Slash_C_Range_Classname );
}

#if defined _zombieplague_included && defined FixDefaultKnifeModelAfterSpawn
	public EV_CurWeapon( const pPlayer )
	{
		if ( !is_user_alive( pPlayer ) || zp_get_user_zombie( pPlayer ) )
			return;

		static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return;

		static szViewModel[ 64 ]; get_entvar( pPlayer, var_viewmodel, szViewModel, charsmax( szViewModel ) );
		if ( strcmp( szViewModel, WeaponModelView ) != 0 )
			return;

		ExecuteHamB( Ham_Item_Deploy, pActiveItem );
	}
#endif



/* ~ [ HamSandwich ] ~ */
public Ham_CWeapon_Deploy_Post( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return

    set_entvar( pPlayer, var_viewmodel,  WeaponModelView )
    set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer )

    // Reset weapon state on draw
    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )
    BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );
    BIT_SUB( bitsWeaponState, WeaponState_Slash_End );
    BIT_SUB( bitsWeaponState, WeaponState_Charge_Start );
    SetWeaponState( pItem, bitsWeaponState )

// #if defined MuzzleFlashEnabled
//     if( Weapon_HasCMode( bitsWeaponState ) )
//         UTIL_CreateMuzzleFlash( pPlayer, szMuzzleSprites[ 0 ], 0.1, 0.03, 255.0, 1, true, 29.0);     // i don't suggest using this 
// #endif

    UTIL_SendWeaponAnim( pPlayer, pItem, WeaponAnim_DummyXs )
    set_member( pItem, m_flLastEventCheck,  get_gametime() + 0.1 )

    SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle, WeaponAnim_Draw_Time )
    SetWeaponTimer( pPlayer, pItem, Timer_PlayerNextAttack, WeaponAnim_Draw_Time )

#if defined _reapi_included
    set_member( pPlayer, m_szAnimExtention, WeaponAnimation )
#else
    set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation, -1, linux_diff_player * linux_diff_animating )
#endif

#if defined EnableChargeAlways
    set_task( 0.1, "Task_ChargeCheck", TASK_CHARGE_CHECK( pPlayer ), .flags = "b" ); // Global set_task instead of prethink, i know this is alot but you can't compare exact time in postframe, since it fires after nextattack
#endif

}

public Ham_CWeapon_Holster_Post( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )
    BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );
    BIT_SUB( bitsWeaponState, WeaponState_Slash_End );
    BIT_SUB( bitsWeaponState, WeaponState_Charge_Start );
    SetWeaponState( pItem, bitsWeaponState )

#if defined MuzzleFlashEnabled
    #if defined _reapi_included
        new pEntity; pEntity = ExHeroFindMuzzle(pPlayer);
    #else
        new pEntity; pEntity = ExHeroFindMuzzle(pPlayer);
    #endif
    if( !is_nullent( pEntity ) )
        Util_DestroyMuzzleFlash(pPlayer);     
#endif

    Weapon_SetAllTimers( pPlayer, pItem, 1.0, 1.0, 0.0, 0.0 )

#if defined EnableChargeAlways
    remove_task( TASK_CHARGE_CHECK( pPlayer ) );
#endif

}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return HAM_IGNORED

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return HAM_IGNORED

    if ( get_entvar( pPlayer, var_button ) & IN_RELOAD )
        ExecuteHamB( Ham_Weapon_Reload, pItem );

    #if !defined EnableChargeAlways
        CWeapon_Charge( pItem, pPlayer );
    #endif

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )
    if ( !bitsWeaponState )
        return HAM_IGNORED
    
    static iHitCount; iHitCount = 0

    // Slash hit — register damage
    if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_Hit ) )
    {
        CWeapon_HitSound( pPlayer, UTIL_FakeTraceLine( pPlayer, pItem, Float: WeaponSlashDirection, exhero_knife_range(1), WeaponSlashDamage, WeaponSlashKnockBack, WeaponDamageType, iHitCount ) )

        BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );
        BIT_ADD( bitsWeaponState, WeaponState_Slash_End )

        SetWeaponTimer( pPlayer, pItem, Timer_PlayerNextAttack, WeaponSlashNextAttack - WeaponSlashHitTime )
    }

    // Slash end — send end anim, toggle for next slash
    else if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_End ) )
    {
        BIT_SUB( bitsWeaponState, WeaponState_Slash_End );
        BIT_INVERT( bitsWeaponState, WeaponState_Slash_Anim )

        SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle, WeaponAnim_Slash_Time )
    }

    // Charge hold/release loop
    else if ( BIT_VALID( bitsWeaponState, WeaponState_Charge_Start ) )
    {
        static bool: bIsCMode; bIsCMode = Weapon_HasCMode( bitsWeaponState )
        new Float: vecOrigin[ 3 ]; 
        get_entvar( pPlayer, var_origin, vecOrigin )

        if ( get_entvar( pPlayer, var_button ) & IN_ATTACK2 )
        {

            UTIL_SendWeaponAnim( pPlayer, pItem, bIsCMode ? WeaponAnim_Charge_C_Mode_On : WeaponAnim_Charge )
            UTIL_CreateMuzzleFlash( pPlayer, szMuzzleSprites[ 1 ], 0.02, 0.01, 0.0, 2, false, 57.0, MuzzleType_PingPong, 1.0 );

            new pDummy = CreateDummy( pPlayer )
            CWeapon_WhipFlail_Entity( pPlayer, vecOrigin, Type_Charge_B, Entity_Charge_B_Classname, Entity_Charge_B_Sequence, Entity_Charge_B_End2_Skins, .flNextThink = Entity_Charge_B_Lifetime, .pAttachEnt = pDummy )

            SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle,       WeaponAnim_StartSlash_Time )
            SetWeaponTimer( pPlayer, pItem, Timer_PlayerNextAttack, WeaponAnim_StartSlash_Time )
        }
        else
        {
            set_entvar( pItem, var_next_loop_damage, 0.0 );

            #if defined _reapi_included
                new pEntity; pEntity = ExHeroFindMuzzle(pPlayer);
            #else
                new pEntity; pEntity = ExHeroFindMuzzle(pPlayer);
            #endif

            // ✅ READ FROM BACKUP STORAGE
            new Float: FlFrame = 0.0;
            if ( !is_nullent( pEntity ) )
                get_entvar( pEntity, var_muzzle_stored_frame, FlFrame );

            #if defined WF_DEBUG
                WF_Debug( "RELEASE-CHECK: found ent=%d stored_frame=%.1f (perfect-window 22-38? %s)", pEntity, FlFrame, ( FlFrame >= 22.0 && FlFrame <= 38.0 ) ? "YES" : "no" );
            #endif

            new pHitCount = get_member( pItem, m_Weapon_iHitCount );

            if ( FlFrame >= 22.0 && FlFrame <= 38.0 )
            {
                UTIL_SendWeaponAnim( pPlayer, pItem, bIsCMode ? WeaponAnim_Charge_End_1_C_Mode_On : WeaponAnim_Charge_End_1 )

                if ( pHitCount < ChargedHitCount )
                    pHitCount++

                Perfect_Hit_Effect( pPlayer, bIsCMode );

                UTIL_FakeTraceLine( pPlayer, pItem, Float: WeaponChargeEndDirections, exhero_knife_range(1), WeaponSlashDamage, 0.0, WeaponDamageType, iHitCount )
            }
            else
            {
                UTIL_SendWeaponAnim( pPlayer, pItem, bIsCMode ? WeaponAnim_Charge_End_2_C_Mode_On : WeaponAnim_Charge_End_2 )

                pHitCount = 0;

                rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[Sound_Skill] )

                new Float: vecViewAngle[ 3 ];
                get_entvar( pPlayer, var_v_angle, vecViewAngle );
                vecViewAngle[ 0 ] = 0.0;

                new Float: vecRight[ 3 ];
                engfunc( EngFunc_AngleVectors, vecViewAngle, Float:{0.0,0.0,0.0}, vecRight, Float:{0.0,0.0,0.0} );

                new Float: vecOrigin[ 3 ];
                get_entvar( pPlayer, var_origin, vecOrigin );

                vecOrigin[ 0 ] += vecRight[ 0 ] * 15.0; 
                vecOrigin[ 1 ] += vecRight[ 1 ] * 15.0;

                CWeapon_WhipFlail_Entity( pPlayer, vecOrigin, Type_Charge_B_End2, Entity_Charge_B_End2_Classname, Entity_Charge_B_End2_Sequence, Entity_Charge_B_Skin, Entity_Charge_B_End2_Lifetime, Entity_Charge_B_End2_Nextthink, .vecAngles = vecViewAngle )                
                UTIL_FakeTraceLine( pPlayer, pItem, Float: WeaponChargeEndDirections, exhero_knife_range(1), WeaponSlashDamage, 0.0, WeaponDamageType, iHitCount )

                UTIL_RadiusDamage( pPlayer, vecOrigin, WeaponChargeRadius, bIsCMode ? WeaponChargeDamage_C : WeaponChargeDamage, true, WeaponChargeKnockBack, Index_Hit, 1.5, 20, WeaponChargeKnockUp )
            }

            set_member( pItem, m_Weapon_iHitCount, pHitCount );

            if ( get_member( pItem, m_Weapon_iHitCount ) >= ChargedHitCount )
            {
                BIT_ADD( bitsWeaponState, WeaponState_Charged_C );

                set_entvar( pItem, var_body, WeaponChargedBody );
                new iCurrentAnim = get_entvar( pPlayer, var_weaponanim );

                UTIL_SendWeaponAnim( pPlayer, pItem, iCurrentAnim );
            }

            Util_DestroyMuzzleFlash(pPlayer);

            SetWeaponTimer( pPlayer, pItem, Timer_PlayerNextAttack, WeaponAnim_ChargeEnd_Time )     
            SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle,       WeaponAnim_ChargeEnd_Time ) 

            BIT_SUB( bitsWeaponState, WeaponState_Charge_Start );
        }
    }

    SetWeaponState( pItem, bitsWeaponState )

    return HAM_IGNORED
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return
#if defined WeaponListDir
    if ( get_entvar( pItem, var_owner ) <= 0 )
    {
        set_member( pItem, m_Weapon_iPrimaryAmmoType, WeaponPrimaryAmmoIndex );

        #if defined _reapi_included
            rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
            rg_set_iteminfo( pItem, ItemInfo_pszAmmo1, WeaponPrimaryAmmoName );
            rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponPrimaryAmmoMax );
        #endif

        set_member( pPlayer, m_rgAmmo, WeaponPrimaryAmmoDefault, WeaponPrimaryAmmoIndex );

        set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponPrimaryAmmoChargeTime );  
    }

    #if defined _reapi_included
        UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
    #else
        UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir, WeaponPrimaryAmmoIndex, WeaponPrimaryAmmoMax );
    #endif
#endif
}

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return HAM_IGNORED

    if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
        return HAM_IGNORED

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return HAM_IGNORED

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )


    UTIL_SendWeaponAnim( pPlayer, pItem, Weapon_HasCMode( bitsWeaponState ) ? WeaponAnim_Idle_C_Mode_On : WeaponAnim_Idle )
    SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle, WeaponAnim_Idle_Time )

    return HAM_SUPERCEDE
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return HAM_IGNORED

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return HAM_IGNORED

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )
    if ( BIT_VALID( bitsWeaponState, WeaponState_Charge_Start ) )
        return HAM_SUPERCEDE;
    
    static bool: bIsCMode; bIsCMode = Weapon_HasCMode( bitsWeaponState )
    static bool: bIsSlash2; bIsSlash2 = BIT_VALID( bitsWeaponState, WeaponState_Slash_Anim )

    static iSlashAnim;
    if ( bIsCMode )
        iSlashAnim = bIsSlash2 ? WeaponAnim_Slash_A2_C_Mode_On : WeaponAnim_Slash_A1_C_Mode_On
    else
        iSlashAnim = bIsSlash2 ? WeaponAnim_Slash_A2 : WeaponAnim_Slash_A1

    UTIL_SendWeaponAnim( pPlayer, pItem, iSlashAnim )

    rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ bIsSlash2 ? Sound_slash_a2 : Sound_slash_a1 ] )

#if defined _reapi_included
    set_member( pPlayer, m_szAnimExtention, WeaponAnimation_B )
    rg_set_animation( pPlayer, PLAYER_ATTACK1 )
#else
    static szAnim[32]
    formatex( szAnim, charsmax( szAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation_B )
    UTIL_PlayerAnimation( pPlayer, szAnim )
#endif


    BIT_ADD( bitsWeaponState, WeaponState_Slash_Hit )
    SetWeaponState( pItem, bitsWeaponState )

    Weapon_SetAllTimers( pPlayer, pItem, WeaponSlashHitTime, WeaponAnim_Slash_Time, WeaponSlashNextAttack, WeaponSlashNextAttack )

    return HAM_SUPERCEDE
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return HAM_IGNORED

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return HAM_IGNORED

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )

    if ( BIT_VALID( bitsWeaponState, WeaponState_Charge_Start ) )
        return HAM_SUPERCEDE;
    

#if defined _reapi_included
    set_member( pPlayer, m_szAnimExtention, WeaponAnimation_B )
    rg_set_animation( pPlayer, PLAYER_ATTACK1 )
#else
    static szAnim[32]
    formatex( szAnim, charsmax( szAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation_B )
    UTIL_PlayerAnimation( pPlayer, szAnim )
#endif

    BIT_ADD( bitsWeaponState, WeaponState_Charge_Start );
    SetWeaponState( pItem, bitsWeaponState )

    return HAM_SUPERCEDE
}

public Ham_CWeapon_Reload_Post( const pItem )
{
    if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        return HAM_IGNORED

    static pPlayer; pPlayer = get_member( pItem, m_pPlayer )
    if ( pPlayer <= 0 )
        return HAM_IGNORED

    static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem )

    if ( !Weapon_HasCMode( bitsWeaponState ) )
        return HAM_IGNORED

    static pAmmo; pAmmo = get_member( pPlayer, m_rgAmmo, WeaponPrimaryAmmoIndex );
    if ( pAmmo <= 0 )
        return HAM_IGNORED

    set_member( pPlayer, m_rgAmmo, pAmmo - 1, WeaponPrimaryAmmoIndex );
    
    get_entvar( pPlayer, var_origin, g_vecReloadOrigin[ pPlayer ] );
    get_entvar( pPlayer, var_v_angle, g_vecReloadAngles[ pPlayer ] );
    g_vecReloadAngles[ pPlayer ][ 0 ] = 0.0;

    if( pAmmo > 0 && 2 > pAmmo )
    {
        set_entvar( pItem, var_body, 0 )
        set_member( pItem, m_Weapon_iHitCount, 0 )

        BIT_SUB( bitsWeaponState, WeaponState_Charged_C );
        SetWeaponState( pItem, bitsWeaponState );

        UTIL_SendWeaponAnim( pPlayer, pItem, WeaponAnim_Slash_C_Off )

    }
    else
    {
        UTIL_SendWeaponAnim( pPlayer, pItem, WeaponAnim_Slash_C )
    }

    Reload_Effect( pPlayer, ReloadEffect_SideOffset, ReloadEffect_FrontOffset );
    set_member( pItem, m_Weapon_iHitCount, 0 );
    SetWeaponTimer( pPlayer, pItem, Timer_WeaponIdle,       WeaponAnim_Slash_C_Time )
    SetWeaponTimer( pPlayer, pItem, Timer_PlayerNextAttack, WeaponAnim_Slash_C_Time )

    return HAM_SUPERCEDE
}

/* ~ [ Entity : info_target ] ~ */
public CInfoTarget__Think_Post( const pEntity )
{
    if ( is_nullent( pEntity ) )
        return

    if ( FClassnameIs( pEntity, Entity_Charge_B_Classname ) || FClassnameIs( pEntity, Entity_Charge_B_End1_Classname ) || FClassnameIs( pEntity, Entity_Charge_B_End2_Classname ) || FClassnameIs( pEntity, Entity_Slash_C_Range_Classname ) )
        CEntity_WFThink( pEntity )
}

#if !defined _reapi_included
    /* ~ [ Entity : env_sprite ] ~ */
    public CSpriteInfo__Think_Post( pEntity )
    {
        if( is_nullent( pEntity ) )
            return


        if ( FClassnameIs( pEntity, szMuzzleClassName ) )
            CEntity_MuzzleThink( pEntity );
    }

#endif

#if defined EnableChargeAlways

    public Task_ChargeCheck( pTaskID )
    {
        static pPlayer; pPlayer = pTaskID - 90000;
        new Float: flGameTime = get_gametime( );

        if ( !IsUserValid( pPlayer ) || !IsUserConnected( pPlayer ) || !is_user_alive( pPlayer ) )
        {
            remove_task( pTaskID );
            return;
        }

        static pItem; pItem = get_member( pPlayer, m_pActiveItem );

        if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
        {
            remove_task( pTaskID );
            return;
        }
        #if defined MuzzleFlashEnabled
            new bitsState = GetWeaponState( pItem );
            new bool: bIsCMode = Weapon_HasCMode( bitsState );

            new Float: vecOrigin[ 3 ];
            get_entvar( pPlayer, var_origin, vecOrigin );

            if ( BIT_VALID( bitsState, WeaponState_Charge_Start ) )
            {
                if ( get_entvar( pPlayer, var_button ) & IN_ATTACK2 )
                {
                    static Float: flNextLoopDamage;
                    get_entvar( pItem, var_next_loop_damage, flNextLoopDamage );

                    if ( flNextLoopDamage <= flGameTime )
                    {
                        UTIL_RadiusDamage( pPlayer, vecOrigin, WeaponLoopRadius, bIsCMode ? WeaponLoopDamage_C : WeaponLoopDamage, false, 0.0, IndexSlashC_Hit_1, 1.5, 20 );
                        set_entvar( pItem, var_next_loop_damage, flGameTime + 0.25 );
                    }
                }
                else
                    Weapon_SetAllTimers( pPlayer, pItem, 0.0, 0.0, 0.0, 0.0 )
            }
        #endif



        static Float: flNextCharge;
        get_entvar( pItem, var_next_charge, flNextCharge );

        if ( flNextCharge > flGameTime )
            return;

        CWeapon_Charge( pItem, pPlayer );
    }
#endif



/* ~ [ Weapon Logic ] ~ */
stock CWeapon_HitSound( const pPlayer, const bitsHitResult )
{
    if ( !bitsHitResult ) return

    if ( BIT_VALID( bitsHitResult, HitResult_World ) )
        rh_emit_sound2( pPlayer, 0, CHAN_STATIC, WeaponSounds[Sound_HitWall] )
}

/* ~ [ Other ] ~ */
public bool: CPlayer_GiveWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	if ( CPlayer_GetWeapon( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_REPLACE, WeaponUnicalIndex );
	if ( is_nullent( pItem ) )
		return false;

	return true;
}

public bool: CPlayer_GetWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	new pItem = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return false;

	return true;
}

public bool: CPlayer_RemoveWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	new pItem = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return false;

	return is_nullent( rg_give_item( pPlayer, WeaponReference, GT_REPLACE ) ) ? false : true;
}



/* ~ [ Stocks ] ~ */

/**
 * Fan trace — casts multiple rays in an arc pattern.
 * flSendAngles: { Count, StartAngle, StepAngle, StartUpAngle, StepUpAngle }
 * Returns bitflags of what was hit (HitResult_None/World/Entity).
 * iHitCount is incremented for each unique player hit.
 */
stock UTIL_FakeTraceLine( const pPlayer, const pItem, const Float: flSendAngles[5], const Float: flDistance, const Float: flDamage = 0.0, const Float: flKnockBack = 0.0, const bitsDamageType = DMG_GENERIC, &iHitCount )
{
    new bitsHitResult, bitsVictims

    new Float: vecStart[3]; UTIL_GetEyePosition( pPlayer, vecStart )

    new Float: vecViewAngle[3]; get_entvar( pPlayer, var_v_angle, vecViewAngle )
    new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3]
    engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp )

    new Float: flTan, Float: vecEnd[3]
    new pTrace = create_tr2(), pHit, Float: flFraction

    for ( new i = 0; i < floatround( flSendAngles[0] ); i++ )
    {
        flTan = floattan( flSendAngles[1] + ( flSendAngles[2] * i ), degrees )

        vecEnd[0] = ( vecForward[0] * flDistance ) + ( vecRight[0] * flTan * flDistance )
        vecEnd[1] = ( vecForward[1] * flDistance ) + ( vecRight[1] * flTan * flDistance )
        vecEnd[2] = ( vecForward[2] * flDistance ) + ( vecRight[2] * flTan * flDistance )

        if ( flSendAngles[3] )
            xs_vec_add_scaled( vecEnd, vecUp, flSendAngles[3] + ( flSendAngles[4] * i ), vecEnd )

        xs_vec_add_scaled( vecStart, vecEnd, flDistance / xs_vec_len( vecEnd ), vecEnd )

        engfunc( EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace )
        get_tr2( pTrace, TR_flFraction, flFraction )

        if ( flFraction == 1.0 )
        {
            BIT_ADD( bitsHitResult, HitResult_None )
            continue
        }

        pHit = get_tr2( pTrace, TR_pHit )

        if ( is_nullent( pHit ) )
        {
            BIT_ADD( bitsHitResult, HitResult_World )
            continue
        }

        BIT_ADD( bitsHitResult, HitResult_Entity )

        if ( IsUserValid( pHit ) )
        {
            if ( BIT_VALID( bitsVictims, BIT_PLAYER( pHit ) ) )
                continue
        }

        if ( flDamage )
        {
new Float:exBefore;if(is_user_alive(pHit))pev(pHit,pev_health,exBefore);
#if defined _reapi_included
            rg_multidmg_clear()
            ExecuteHamB( Ham_TraceAttack, pHit, pPlayer, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecForward, pTrace, bitsDamageType )
            rg_multidmg_apply( pItem, pPlayer )
#else
            UTIL_FakeTraceAttack( pHit, pItem, pPlayer, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecForward, pTrace, bitsDamageType )
#endif
            if(exBefore>0.0){new label[48];formatex(label,47,"Tyrant Mace: golpe [%s]",get_tr2(pTrace,TR_iHitgroup)==HIT_HEAD?"HEAD":"BODY");exhero_report_hit(pHit,pPlayer,exBefore,label);}
        }

        if ( is_user_alive( pHit ) )
        {
            BIT_ADD( bitsVictims, BIT_PLAYER( pHit ) )

            if ( flKnockBack > 0.0 )
                UTIL_PlayerKnockBack( pHit, pPlayer, flKnockBack )

            iHitCount++
        }
    }

    free_tr2( pTrace )
    return bitsHitResult
}

#if !defined _reapi_included
    stock UTIL_FakeTraceAttack( const pVictim, const pInflictor, const pAttacker, const Float: flBaseDamage, const Float: vecDirection[3], const pTrace, const bitsDamageType )
    {
        if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
            return false

        if ( is_user_alive( pVictim ) )
        {
            if ( get_member( pVictim, m_iTeam ) == get_member( pAttacker, m_iTeam ) )
                return false
        }

        static Float: vecEndPos[3]; get_tr2( pTrace, TR_vecEndPos, vecEndPos )
        static iHitGroup; iHitGroup = get_tr2( pTrace, TR_iHitgroup )
        static Float: flDamage; flDamage = flBaseDamage

        static Float: vecPunchAngle[3]
        vecPunchAngle[0] = vecPunchAngle[1] = vecPunchAngle[2] = 0.0

        switch ( iHitGroup )
        {
            case HIT_HEAD:
            {
                flDamage *= 4.0
                vecPunchAngle[0] = floatmax( flDamage * -0.5, -12.0 )
                vecPunchAngle[2] = floatclamp( flDamage * random_float( -1.0, 1.0 ), -9.0, 9.0 )
            }
            case HIT_CHEST:    flDamage *= 1.0
            case HIT_STOMACH:  flDamage *= 1.25
            case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75
        }

        if ( xs_vec_len( vecPunchAngle ) )
            set_entvar( pVictim, var_punchangle, vecPunchAngle )

        set_member( pVictim, m_LastHitGroup, iHitGroup )
        ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType )

        static iBloodColor; iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim )
        if ( iBloodColor != DONT_BLEED )
        {
            UTIL_TE_BLOODSPRITE( MSG_PVS, vecEndPos, iBloodColor, floatround( flDamage ) )
            ExecuteHamB( Ham_TraceBleed, pVictim, flDamage, vecDirection, pTrace, bitsDamageType )
        }

        return true
    }
#endif

stock UTIL_SendWeaponAnim( const pPlayer, const pItem, const iAnim )
{
    static iBody; iBody = get_entvar( pItem, var_body )
    set_entvar( pPlayer, var_weaponanim, iAnim )

    message_begin( MSG_ONE, SVC_WEAPONANIM, .player = pPlayer )
    write_byte( iAnim )
    write_byte( iBody )
    message_end()

    if ( get_entvar( pPlayer, var_iuser1 ) )
        return

    // Mirror to in-eye spectators
    static i, iCount, pSpectator, aSpectators[32]
    get_players( aSpectators, iCount, "bch" )

    for ( i = 0; i < iCount; i++ )
    {
        pSpectator = aSpectators[i]
        if ( get_entvar( pSpectator, var_iuser1 ) != OBS_IN_EYE ) continue
        if ( get_entvar( pSpectator, var_iuser2 ) != pPlayer    ) continue

        set_entvar( pSpectator, var_weaponanim, iAnim )
        message_begin( MSG_ONE, SVC_WEAPONANIM, .player = pSpectator )
        write_byte( iAnim )
        write_byte( iBody )
        message_end()
    }
}

stock UTIL_RadiusDamage( const pAttacker, const Float: vecOrigin[3], const Float: flRadius, const Float: flDamage, const bool: flKnock = false, const Float: flKnockBack = 0.0, const iExplosionModel = -1, const Float: flExplosionScale = 1.0, const iExplosionFramerate = 20, const Float: flKnockUp = 0.0 )
{
    new pVictim = FM_NULLENT;
    while( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, vecOrigin, flRadius ) ) > 0 )
    {
        if( !IsValidVictim( pVictim, pAttacker ) )
            continue;
        new tr=create_tr2(),Float:end[3],Float:fraction;pev(pVictim,pev_origin,end);
        engfunc(EngFunc_TraceLine,vecOrigin,end,IGNORE_MONSTERS,pAttacker,tr);get_tr2(tr,TR_flFraction,fraction);free_tr2(tr);if(fraction<0.99)continue;


        if( flKnock && flKnockBack > 0.0 )
            UTIL_PlayerKnockBack( pVictim, pAttacker, flKnockBack, flKnockUp );

        if ( iExplosionModel != -1 )
        {
            new Float: vecVictimOrigin[3];
            get_entvar( pVictim, var_origin, vecVictimOrigin );
            vecVictimOrigin[ 2 ] += 13.0;

            UTIL_TE_EXPLOSION( gl_izModelIndexed[ iExplosionModel ], vecVictimOrigin, 0.0, flExplosionScale, iExplosionFramerate );
        }

        set_pdata_int(pVictim,75,HIT_GENERIC,5);
        exhero_damage(pVictim,pAttacker,pAttacker,flDamage,DMG_BLAST,"Tyrant Mace: area [AREA]");
    }
}

// Muzzleflash
#if defined MuzzleFlashEnabled      
    stock UTIL_CreateMuzzleFlash( pPlayer, szMuzzleSprite[ ], Float: flScale, Float: flNextThink, Float: flBrightness, iAttachment, bool: iMuzzleLoop, Float: flFrameAmount, const iType, Float: flSetFrame = 0.0 )
    {
        new pEntity = FM_NULLENT;

        #if defined _reapi_included
            while ( ( pEntity = rg_find_ent_by_class( pEntity, szMuzzleClassName ) ) > 0 )
        #else
            while ( ( pEntity = fm_find_ent_by_class( pEntity, szMuzzleClassName ) ) > 0 )
        #endif
        {
            if ( get_entvar( pEntity, var_owner ) == pPlayer )
                return pEntity;
        }

        #if defined _reapi_included
            pEntity = rg_create_entity( "env_sprite" );
        #else
            pEntity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_sprite" ) );
        #endif

        if ( is_nullent( pEntity ) )
            return NULLENT;

        set_entvar( pEntity, var_classname, szMuzzleClassName );
        engfunc( EngFunc_SetModel, pEntity, szMuzzleSprite );
        
        #if !defined _reapi_included
            dllfunc( DLLFunc_Spawn, pEntity );
        #endif

        set_entvar( pEntity, var_owner,        pPlayer );
        set_entvar( pEntity, var_solid,        SOLID_NOT );
        set_entvar( pEntity, var_body,         iAttachment );
        set_entvar( pEntity, var_aiment,       pPlayer );
        set_entvar( pEntity, var_movetype,     MOVETYPE_FOLLOW );
        set_entvar( pEntity, var_loop_frames,  iMuzzleLoop );
        set_entvar( pEntity, var_max_frames,   flFrameAmount );
        set_entvar( pEntity, var_skin,         pPlayer );
        set_entvar( pEntity, var_scale,        flScale );
        set_entvar( pEntity, var_update_frames, flNextThink );
        set_entvar( pEntity, var_muzzle_type,  iType );

        if ( iType == MuzzleType_PingPong )
        {
            set_entvar( pEntity, var_frame,              flSetFrame );
            set_entvar( pEntity, var_muzzle_stored_frame, flSetFrame );  
            set_entvar( pEntity, var_direction,          1.0 );
            set_entvar( pEntity, var_framerate,          0.0 );
            set_entvar( pEntity, var_rendermode,         kRenderTransAdd );
            set_entvar( pEntity, var_renderamt,          175.0 );
        }
        else
        {
            set_entvar( pEntity, var_frame,      0.0 );
            set_entvar( pEntity, var_rendermode, kRenderTransAdd );
            set_entvar( pEntity, var_renderamt,  flBrightness );
        }

        set_entvar( pEntity, var_nextthink, get_gametime() );

        #if defined _reapi_included
            SetThink( pEntity, "CEntity_MuzzleThink" );
        #endif

        return pEntity;
    }

    public CEntity_MuzzleThink( pEntity )
    {
        if ( is_nullent( pEntity ) )
            return;

        new owner=get_entvar(pEntity,var_owner);if(owner<1 || owner>32 || !is_user_alive(owner) || zp_get_user_zombie(owner)){UTIL_KillEntity(pEntity);return;}
        new iType = get_entvar( pEntity, var_muzzle_type );
        
        if ( iType == MuzzleType_PingPong )
        {
            new Float: flMaxFrame;      get_entvar( pEntity, var_max_frames, flMaxFrame );
            new Float: flDirection;     get_entvar( pEntity, var_direction, flDirection );
            new Float: flNextThink;     get_entvar( pEntity, var_update_frames, flNextThink );
            
            new Float: FlFrame;
            get_entvar( pEntity, var_muzzle_stored_frame, FlFrame );

            #if defined WF_DEBUG
                new Float: FlEngineFrame; 
                get_entvar( pEntity, var_frame, FlEngineFrame );
                WF_Debug( "THINK ent=%d: stored=%.1f engine=%.1f dir=%.1f", pEntity, FlFrame, FlEngineFrame, flDirection );
            #endif


            FlFrame += flDirection;

            if ( FlFrame >= flMaxFrame )
            {
                FlFrame = flMaxFrame;
                flDirection = -1.0;
            }
            else if ( FlFrame <= 0.0 )
            {
                FlFrame = 0.0;
                flDirection = 1.0;
            }

            set_entvar( pEntity, var_frame,              FlFrame );
            set_entvar( pEntity, var_muzzle_stored_frame, FlFrame );  
            set_entvar( pEntity, var_direction,          flDirection );
            set_entvar( pEntity, var_nextthink,          get_gametime() + flNextThink );

            return;
        }

        new Float: flFrameAmount; get_entvar( pEntity, var_max_frames, flFrameAmount );
        new iMuzzleLoop = get_entvar( pEntity, var_loop_frames );
        new Float: flFrame; get_entvar( pEntity, var_frame, flFrame );
        new Float: flNextThink; get_entvar( pEntity, var_update_frames, flNextThink );

        if ( flFrame >= flFrameAmount )
        {
            if ( iMuzzleLoop )
                flFrame = 0.0;
            else
            {
                UTIL_KillEntity( pEntity );
                return;
            }
        }
        else
            flFrame += 1.0;

        set_entvar( pEntity, var_frame,     flFrame );
        set_entvar( pEntity, var_nextthink, get_gametime() + flNextThink );
    }

    stock Util_DestroyMuzzleFlash(pPlayer)
    {
        new e;while((e=ExHeroFindMuzzle(pPlayer))>0)engfunc(EngFunc_RemoveEntity,e);
    }
#endif


// ~ [ Weapon Idle Stocks ] ~ //

stock Float: Weapon_GetIdle( pItem )
{
    return get_member( pItem, m_Weapon_flTimeWeaponIdle );
}

stock Weapon_SetIdle( pItem, Float: flTime )
{
    set_member( pItem, m_Weapon_flTimeWeaponIdle, flTime );
}

// ~ [ Weapon Primary Attack Stocks ] ~ //

stock Float: Weapon_GetPrimaryAttack( pItem )
{
    return get_member( pItem, m_Weapon_flNextPrimaryAttack );
}

stock Weapon_SetPrimaryAttack( pItem, Float: flTime )
{
    set_member( pItem, m_Weapon_flNextPrimaryAttack, flTime );
}

// ~ [ Weapon Secondary Attack Stocks ] ~ //

stock Float: Weapon_GetSecondaryAttack( pItem )
{
    return get_member( pItem, m_Weapon_flNextSecondaryAttack );
}

stock Weapon_SetSecondaryAttack( pItem, Float: flTime )
{
    set_member( pItem, m_Weapon_flNextSecondaryAttack, flTime );
}

// ~ [ Player Next Attack Stocks ] ~ //

stock Float: Player_GetAttack( pPlayer )
{
    return get_member( pPlayer, m_flNextAttack );
}

stock Player_SetAttack( pPlayer, Float: flTime )
{
    set_member( pPlayer, m_flNextAttack, flTime );
}

// ~ [ Weapon - Set ALL Timers Together ] ~ //

stock Weapon_SetAllTimers( pPlayer, pItem, Float: flNextAttack, Float: flIdleTime, Float: flPrimaryAttack, Float: flSecondaryAttack )
{
    set_member( pPlayer, m_flNextAttack,                  flNextAttack );
    set_member( pItem,   m_Weapon_flTimeWeaponIdle,       flIdleTime );
    set_member( pItem,   m_Weapon_flNextPrimaryAttack,    flPrimaryAttack );
    set_member( pItem,   m_Weapon_flNextSecondaryAttack,  flSecondaryAttack );
}

// ~ [ Independent Single Timer Setter ] ~ //
// type: 0 = Player NextAttack | 1 = Weapon Idle | 2 = Weapon PrimaryAttack | 3 = Weapon SecondaryAttack

stock SetWeaponTimer( pPlayer, pItem, WeaponTimerType: type, Float: flTime )
{
    switch( type )
    {
        case Timer_PlayerNextAttack:        set_member( pPlayer, m_flNextAttack,                 flTime );
        case Timer_WeaponIdle:              set_member( pItem,   m_Weapon_flTimeWeaponIdle,      flTime );
        case Timer_WeaponPrimaryAttack:     set_member( pItem,   m_Weapon_flNextPrimaryAttack,   flTime );
        case Timer_WeaponSecondaryAttack:   set_member( pItem,   m_Weapon_flNextSecondaryAttack, flTime );
    }
}

#if !defined _reapi_included
    stock UTIL_PlayerAnimation( const pPlayer, const szAnim[] )
    {
        new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops
        if ( ( iAnimDesired = lookup_sequence( pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed ) ) == -1 )
            iAnimDesired = 0

        new Float: flGameTime = get_gametime()

        set_entvar( pPlayer, var_frame,     0.0 )
        set_entvar( pPlayer, var_framerate, 1.0 )
        set_entvar( pPlayer, var_animtime,  flGameTime )
        set_entvar( pPlayer, var_sequence,  iAnimDesired )

        set_member( pPlayer, m_fSequenceLoops,    bLoops )
        set_member( pPlayer, m_fSequenceFinished, 0 )
        set_member( pPlayer, m_flFrameRate,       flFrameRate )
        set_member( pPlayer, m_flGroundSpeed,     flGroundSpeed )
        set_member( pPlayer, m_flLastEventCheck,  flGameTime )
        set_member( pPlayer, m_Activity,          ACT_RANGE_ATTACK1 )
        set_member( pPlayer, m_IdealActivity,     ACT_RANGE_ATTACK1 )
        set_member( pPlayer, m_flLastFired,       flGameTime )
    }
#endif

/* -> Is Victim Valid <- */
stock bool: IsValidVictim( const pVictim, const pAttacker )
{
    if( !is_user_alive( pVictim ) )
        return false;

    if(!is_user_alive(pAttacker) || zp_get_user_zombie(pAttacker) || !zp_get_user_zombie(pVictim))return false;
    if( pVictim == pAttacker )
        return false;

    if( get_member( pVictim, m_iTeam ) == get_member( pAttacker, m_iTeam ) )
        return false;

    return true;
}

/* -> Trace Ground <- */
stock UTIL_TraceToGround( const Float: vecStart[3], Float: vecGround[ 3 ] )     // BlackPanther
{
    new Float: vecEnd[3];
    vecEnd[0] = vecStart[0];
    vecEnd[1] = vecStart[1];
    vecEnd[2] = vecStart[2] - 9999.0;

    new iTrace = create_tr2();
    engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, FM_NULLENT, iTrace );
    get_tr2( iTrace, TR_vecEndPos, vecGround );
    free_tr2( iTrace );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> Destro Entities by ClassName <- */
stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
    static pEntity; pEntity = NULLENT;

#if defined _reapi_included
    while ( ( pEntity = rg_find_ent_by_class( pEntity, szClassName ) ) > 0 )
        UTIL_KillEntity( pEntity );
#else
    while ( ( pEntity = fm_find_ent_by_class( pEntity, szClassName ) ) > 0 )
        UTIL_KillEntity( pEntity );
#endif
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/* -> Entity Transparency <- */
stock UTIL_SetEntityTransparency( const pEntity, const iRenderMode = kRenderTransAdd, const Float: flRenderAmt = 255.0, const iRenderFx = kRenderFxNone, const Float: vecRenderColor[3] = { 255.0, 255.0, 255.0 } )
{
    if ( is_nullent( pEntity ) )
        return;

    set_entvar( pEntity, var_rendermode,  iRenderMode );
    set_entvar( pEntity, var_renderamt,   flRenderAmt );
    set_entvar( pEntity, var_renderfx,    iRenderFx );
    set_entvar( pEntity, var_rendercolor, vecRenderColor );
}


stock UTIL_GetEyePosition( const pPlayer, Float: vecEyeLevel[3] )
{
    new Float: vecOrigin[3];  
    get_entvar( pPlayer, var_origin,   vecOrigin )

    new Float: vecViewOfs[3]; 
    get_entvar( pPlayer, var_view_ofs, vecViewOfs )

    xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel )
}

stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flKnockUp = 0.0 )
{
    if ( !IsValidVictim( pVictim, pAttacker ) )
        return;

    new Float: vecVictimOrigin[ 3 ], Float: vecAttackerOrigin[ 3 ];
    get_entvar( pVictim,   var_origin, vecVictimOrigin );
    get_entvar( pAttacker, var_origin, vecAttackerOrigin );

    new Float: vecDir[ 3 ];
    xs_vec_sub( vecVictimOrigin, vecAttackerOrigin, vecDir );
    vecDir[ 2 ] = 0.0;

    new Float: flLen = xs_vec_len_2d( vecDir );
    if ( flLen <= 0.0 )
        return;

    new Float: vecVelocity[ 3 ];
    get_entvar( pVictim, var_velocity, vecVelocity );

    vecVelocity[ 0 ] = ( vecDir[ 0 ] / flLen ) * flForce;
    vecVelocity[ 1 ] = ( vecDir[ 1 ] / flLen ) * flForce;

    if ( flKnockUp > 0.0 )
        vecVelocity[ 2 ] = flKnockUp;
    else
        vecVelocity[ 2 ] += flForce * 0.67; // 67 🥀  
        
    new iFlags = get_entvar( pVictim, var_flags );
    if ( iFlags & FL_ONGROUND )
        set_entvar( pVictim, var_flags, iFlags & ~FL_ONGROUND );

    set_entvar( pVictim, var_velocity, vecVelocity );
}

stock UTIL_TE_BLOODSPRITE( const iDest, const Float: vecOrigin[3], const iColor, iAmount )
{
    if ( iColor == DONT_BLEED || !iAmount ) return

    iAmount = clamp( iAmount * 2, 1, 255 )

    static _iszModelIndexBloodSpray
    if ( !_iszModelIndexBloodSpray )
        _iszModelIndexBloodSpray = engfunc( EngFunc_ModelIndex, "sprites/bloodspray.spr" )

    static _iszModelIndexBloodDrop
    if ( !_iszModelIndexBloodDrop )
        _iszModelIndexBloodDrop = engfunc( EngFunc_ModelIndex, "sprites/blood.spr" )

    engfunc( EngFunc_MessageBegin, iDest, SVC_TEMPENTITY, vecOrigin, 0 )
    write_byte( TE_BLOODSPRITE )
    engfunc( EngFunc_WriteCoord, vecOrigin[0] )
    engfunc( EngFunc_WriteCoord, vecOrigin[1] )
    engfunc( EngFunc_WriteCoord, vecOrigin[2] )
    write_short( _iszModelIndexBloodSpray )
    write_short( _iszModelIndexBloodDrop )
    write_byte( iColor )
    write_byte( clamp( iAmount / 10, 3, 16 ) )
    message_end()
}

#if defined WeaponListDir
    stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
	{
		new szBuffer[ 128 ], pFile;

		format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
		engfunc(EngFunc_PrecacheGeneric, szBuffer );

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
			engfunc(EngFunc_PrecacheGeneric, szBuffer );
		#else
			engfunc(EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}

    #if defined _reapi_included
        stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ 64 ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 )
        {
            if ( szWeaponName[ 0 ] == EOS )
                rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) )

            static iMsgId_Weaponlist; 
            if ( !iMsgId_Weaponlist ) 
                iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

            message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
            write_string( szWeaponName );
            write_byte( ( iPrimaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iPrimaryAmmoType ) : iPrimaryAmmoType );
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
        stock UTIL_WeaponList( const iDist, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 )
        {
            static iMsgId_Weaponlist; 
            if ( !iMsgId_Weaponlist ) 
                iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

            message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
            write_string( szWeaponName );
            write_byte( ( iPrimaryAmmoType <= -2 ) ? gl_aWeaponListData[ 0 ] : iPrimaryAmmoType );
            write_byte( ( iMaxPrimaryAmmo <= -2 ) ? gl_aWeaponListData[ 1 ] : iMaxPrimaryAmmo );
            write_byte( ( iSecondaryAmmoType <= -2 ) ? gl_aWeaponListData[ 2 ] : iSecondaryAmmoType );
            write_byte( ( iMaxSecondaryAmmo <= -2 ) ? gl_aWeaponListData[ 3 ] : iMaxSecondaryAmmo );
            write_byte( ( iSlot <= -2 ) ? gl_aWeaponListData[ 4 ] : iSlot );
            write_byte( ( iPosition <= -2 ) ? gl_aWeaponListData[ 5 ] : iPosition );
            write_byte( ( iWeaponId <= -2 ) ? gl_aWeaponListData[ 6 ] : iWeaponId );
            write_byte( ( iFlags <= -2 ) ? gl_aWeaponListData[ 7 ] : iFlags );
            message_end( );
        }
    #endif
#endif

#if defined PrecacheSoundsFromModel
    stock UTIL_PrecacheSoundsFromModel( const szModelPath[] )
    {
        new pFile
        if ( !( pFile = fopen( szModelPath, "rb" ) ) ) return

        new szSoundPath[64], iNumSeq, iSeqIndex, iEvent, iNumEvents, iEventIndex

        fseek( pFile, 164, SEEK_SET )
        fread( pFile, iNumSeq,    BLOCK_INT )
        fread( pFile, iSeqIndex,  BLOCK_INT )

        for ( new i = 0; i < iNumSeq; i++ )
        {
            fseek( pFile, iSeqIndex + 48 + 176 * i, SEEK_SET )
            fread( pFile, iNumEvents,  BLOCK_INT )
            fread( pFile, iEventIndex, BLOCK_INT )
            fseek( pFile, iEventIndex + 176 * i, SEEK_SET )

            for ( new k = 0; k < iNumEvents; k++ )
            {
                fseek( pFile, iEventIndex + 4 + 76 * k, SEEK_SET )
                fread( pFile, iEvent, BLOCK_INT )
                fseek( pFile, 4, SEEK_CUR )

                if ( iEvent != 5004 ) continue

                fread_blocks( pFile, szSoundPath, 64, BLOCK_CHAR )
                if ( strlen( szSoundPath ) )
                {
                    strtolower( szSoundPath )
                    engfunc(EngFunc_PrecacheGeneric, fmt( "sound/%s", szSoundPath ) )
                }
            }
        }

        fclose( pFile )
    }
#endif

/* -> By Nordic Warrior (https://dev-cs.ru/threads/222/page-19#post-151804) <- */
stock precache_model_ex(const szFileName[], bool: bValvePath = false) 
{
	if(file_exists(szFileName, bValvePath))
		return engfunc(EngFunc_PrecacheModel, szFileName);

	set_fail_state("Model <%s> not found. The plugin has been stopped.", szFileName);

	return false;
}

#if defined EnableChargeAlways
    public CWeapon_Charge( const pItem, const pPlayer )
    {
        static Float: flGameTime; flGameTime = get_gametime( );
        static Float: flNextCharge; 
        get_entvar( pItem, var_next_charge, flNextCharge );

        if ( 0.0 < flNextCharge < flGameTime )
        {
            static iAmmo; iAmmo = get_member( pPlayer, m_rgAmmo, WeaponPrimaryAmmoIndex );
            iAmmo = min( iAmmo + WeaponPrimaryAmmoGive, WeaponPrimaryAmmoMax );

            set_member( pPlayer, m_rgAmmo, iAmmo, WeaponPrimaryAmmoIndex );
            set_entvar( pItem, var_next_charge, flGameTime + WeaponPrimaryAmmoChargeTime );

            if ( WeaponHasMaxAmmo( pPlayer ) )
            {
                set_entvar( pItem, var_next_charge, 0.0 );
            }
        }
    }
#endif

stock Perfect_Hit_Effect( const pPlayer, const bool: bIsCMode )
{
    static Float: vecOrigin[ 3 ];
    get_entvar( pPlayer, var_origin, vecOrigin );

    static Float: vecViewAngle[ 3 ];
    get_entvar( pPlayer, var_v_angle, vecViewAngle );
    vecViewAngle[ 0 ] = 0.0;

    new Float: vecEntAngles[ 3 ];
    vecEntAngles[ 0 ] = 0.0;
    vecEntAngles[ 1 ] = vecViewAngle[ 1 ];  // yaw
    vecEntAngles[ 2 ] = 0.0;

    static Float: vecForward[ 3 ];
    engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, Float:{ 0.0, 0.0, 0.0 }, Float:{ 0.0, 0.0, 0.0 } );

    new Float: vecTraceStart[ 3 ];
    vecTraceStart[ 0 ] = vecOrigin[ 0 ] + ( vecForward[ 0 ] * 50.0 );
    vecTraceStart[ 1 ] = vecOrigin[ 1 ] + ( vecForward[ 1 ] * 50.0 );
    vecTraceStart[ 2 ] = vecOrigin[ 2 ];

    new Float: vecEnd[ 3 ], Float: vecXOrigin[ 3 ];
    vecEnd[ 0 ] = vecTraceStart[ 0 ];
    vecEnd[ 1 ] = vecTraceStart[ 1 ];
    vecEnd[ 2 ] = vecTraceStart[ 2 ] - 9999.0;

    new iTrace = create_tr2();
    engfunc( EngFunc_TraceLine, vecTraceStart, vecEnd, IGNORE_MONSTERS, pPlayer, iTrace );
    get_tr2( iTrace, TR_vecEndPos, vecXOrigin );
    free_tr2( iTrace );

    vecXOrigin[ 2 ] += 5.0;

    new pEntity = CWeapon_WhipFlail_Entity( pPlayer, vecXOrigin, Type_Charge_B_End1, Entity_Charge_B_End1_Classname, Entity_Charge_B_End1_Sequence, Entity_Charge_B_End1_Skin, Entity_Charge_B_End1_Lifetime, Entity_Charge_B_End1_Nextthink, .vecAngles = vecEntAngles );

    rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[Sound_Skill_Exp1] )

    UTIL_RadiusDamage( pPlayer, vecXOrigin, WeaponChargeRadius_Perfect, bIsCMode ? WeaponChargeDamage_C_Perfect : WeaponChargeDamage_Perfect, true, WeaponChargeKnockBack_Perfect, Index_Hit, 1.5, 20 )

    return pEntity;
}

stock Reload_Effect( const pPlayer, const Float: flSideOffset, const Float: flFrontOffset, const iWave = 0 )
{
    new Float: vecOrigin[3];
    vecOrigin[0] = g_vecReloadOrigin[ pPlayer ][0];
    vecOrigin[1] = g_vecReloadOrigin[ pPlayer ][1];
    vecOrigin[2] = g_vecReloadOrigin[ pPlayer ][2];

    new Float: vecViewAngle[3];
    vecViewAngle[0] = g_vecReloadAngles[ pPlayer ][0];
    vecViewAngle[1] = g_vecReloadAngles[ pPlayer ][1];
    vecViewAngle[2] = g_vecReloadAngles[ pPlayer ][2];

    new Float: vecForward[3], Float: vecRight[3];
    engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, Float:{0.0, 0.0, 0.0} );

    new Float: vecLeftPos[3], Float: vecRightPos[3], Float: vecFrontPos[3];

    vecLeftPos[0] = vecOrigin[0] - (vecRight[0] * flSideOffset);
    vecLeftPos[1] = vecOrigin[1] - (vecRight[1] * flSideOffset);
    vecLeftPos[2] = vecOrigin[2];

    vecRightPos[0] = vecOrigin[0] + (vecRight[0] * flSideOffset);
    vecRightPos[1] = vecOrigin[1] + (vecRight[1] * flSideOffset);
    vecRightPos[2] = vecOrigin[2];

    new Float: flCurrentFront = flFrontOffset + (175.0 * float(iWave));

    vecFrontPos[0] = vecOrigin[0] + (vecForward[0] * flCurrentFront);
    vecFrontPos[1] = vecOrigin[1] + (vecForward[1] * flCurrentFront);
    vecFrontPos[2] = vecOrigin[2];

    ReloadEffect_SpawnPoint( pPlayer, vecLeftPos,  vecViewAngle, iWave );
    ReloadEffect_SpawnPoint( pPlayer, vecRightPos, vecViewAngle, iWave );
    ReloadEffect_SpawnPoint( pPlayer, vecFrontPos, vecViewAngle, iWave, true );
}

stock ReloadEffect_SpawnPoint( const pPlayer, const Float: vecPos[3], const Float: vecAngles[3], const iWave = 0, const bool:advance = false )
{
    new Float: vecGround[3];
    UTIL_TraceToGround( vecPos, vecGround );
    vecGround[2] += 5.0;

    new pEntity = CWeapon_WhipFlail_Entity( pPlayer, vecGround, Type_SlashC_Range, Entity_Slash_C_Range_Classname, 0, 0, Entity_Slash_C_Range_Lifetime, (Entity_Slash_C_Range_Lifetime / float(Entity_Slash_C_Range_Skins)), .vecAngles = vecAngles, .iStartCount = iWave );
    
    if ( is_nullent( pEntity ) )
        return FM_NULLENT;

    set_entvar(pEntity,var_frags,advance?1.0:0.0);
    EmitSound_FromPos( vecGround, WeaponSounds[Sound_Skill_Reload] );

    UTIL_TE_EXPLOSION( gl_izModelIndexed[ IndexSlashC_Hit ], vecGround, ReloadEffect_ExplosionUp, ReloadEffect_ExplosionScale, ReloadEffect_ExplosionFramerate );
    UTIL_RadiusDamage( pPlayer, vecGround, WeaponChargeRadius_Perfect, WeaponChargeDamage_Perfect, true, WeaponChargeKnockBack_Perfect );

    return pEntity
}

stock CreateDummy(pPlayer)
{
    new pDummy = rg_create_entity( EntityGlobalReferences );
    
    if( is_nullent( pDummy ) ) 
        return FM_NULLENT;
    
    set_entvar( pDummy, var_classname, "exhero_mace_dummy" );
    set_entvar( pDummy, var_owner, pPlayer );

    engfunc(EngFunc_SetModel, pDummy, "models/null.mdl"); 
    
    set_entvar( pDummy, var_movetype, MOVETYPE_FOLLOW );
    set_entvar( pDummy, var_aiment, pPlayer );
    
    return pDummy;
}

stock CWeapon_WhipFlail_Entity( const pPlayer, const Float: vecOrigin[ 3 ], const Ptype, const SzClassname[ ] = "", const pSequence = 0, const pSkin = 0, const Float: SzLifeTime = 0.0, const Float: flNextThink = 0.0, const pAttachEnt = 0, const Float: vecAngles[ 3 ] = { 0.0, 0.0, 0.0 }, const iStartCount = 0 )
{
    new pEntity = rg_create_entity( EntityGlobalReferences );
    new Float: flGameTime = get_gametime( )

    if ( is_nullent( pEntity ) )
        return FM_NULLENT;

    set_entvar( pEntity, var_classname,   SzClassname );
    set_entvar( pEntity, var_owner,       pPlayer );
    set_entvar(pEntity,var_team,get_user_userid(pPlayer));
    set_entvar( pEntity, var_entity_type, Ptype );
    set_entvar( pEntity, var_skin,        pSkin );
    set_entvar( pEntity, var_solid,       SOLID_NOT );
    set_entvar( pEntity, var_angles,      vecAngles );

    UTIL_SetEntityAnim( pEntity, pSequence );

    new bool:bDummy = ( pAttachEnt != 0 && !is_nullent( pAttachEnt ) );

    if( bDummy )
    {
        set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
        set_entvar( pEntity, var_aiment,   pAttachEnt );
    }
    else
    {
        UTIL_SetEntityTransparency( pEntity );
        set_entvar( pEntity, var_movetype, MOVETYPE_NONE );
        engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
    }

    engfunc( EngFunc_SetModel, pEntity, zEntityModel[ Ptype ] );

    if( Ptype == Type_SlashC_Range )
    {
        set_entvar( pEntity, var_slashc_count, iStartCount );   
    }
    
    if( SzLifeTime > 0.0 )
    {
        set_entvar( pEntity, var_nextthink, flGameTime + flNextThink );
        set_entvar( pEntity, var_ltime,     flGameTime + SzLifeTime );
    }
    else if( SzLifeTime == 0.0 )
        set_entvar( pEntity, var_nextthink, flGameTime + flNextThink );

// #if defined _reapi_included
//     SetThink( pEntity, "CEntity_WFThink" );
// #endif
    return pEntity;
}

public CEntity_WFThink( pEntity )
{
    if ( is_nullent( pEntity ) )
        return;

    new pState = get_entvar( pEntity, var_entity_state );
    new pType = get_entvar( pEntity, var_entity_type );
    new pOwner = get_entvar( pEntity, var_owner );
    if(pOwner<1 || pOwner>32 || !is_user_alive(pOwner) || zp_get_user_zombie(pOwner) || get_entvar(pEntity,var_team)!=get_user_userid(pOwner)){UTIL_KillEntity(pEntity);return;}
    new pSkin = get_entvar( pEntity, var_skin );
    new iCount = get_entvar( pEntity, var_slashc_count );
    new Float: GNextThink = Float:get_entvar( pEntity, var_nextthink );
    new Float: SzLifeTime = Float:get_entvar( pEntity, var_ltime );
    new Float: flGameTime = get_gametime( )

    // Handle fade-out phase first
    if ( BIT_VALID( pState, EntityState_FadingOut ) )
    {
        new Float: flAlpha; flAlpha = Float:get_entvar( pEntity, var_renderamt );
        flAlpha -= Entity_FadeOut_Speed;

        if ( flAlpha <= 0.0 )
        {
            UTIL_KillEntity( pEntity )
            return
        }

        set_entvar( pEntity, var_renderamt, flAlpha );
        set_entvar( pEntity, var_nextthink, flGameTime + Entity_FadeOut_TickRate );
        return
    }

    if( is_nullent( pOwner ) )
    {
        UTIL_KillEntity( pEntity );
        return;
    }

    if( SzLifeTime == 0.0 )
        UTIL_KillEntity( pEntity )     

    else if( SzLifeTime > 0.0 )
    {
        switch( pType )
        {
            case Type_Charge_B:
            {
                if( GNextThink > 0.0 )
                    UTIL_KillEntity( pEntity )
            }

            case Type_SlashC_Range:
            {
                if( ++pSkin >= Entity_Slash_C_Range_Skins )
                {
                    if ( iCount < SlashC_MaxRepeats && Float:get_entvar(pEntity,var_frags)>0.5 )
                        Reload_Effect( pOwner, ReloadEffect_SideOffset, ReloadEffect_FrontOffset, iCount + 1 );

                    UTIL_KillEntity( pEntity )
                    return
                    
                }

                set_entvar( pEntity, var_nextthink, flGameTime + 0.1 )
            }

            case Type_Charge_B_End1:
            {
                if( ++pSkin >= Entity_Charge_B_End1_Skins )
                {
                    BIT_ADD( pState, EntityState_FadingOut );
                    set_entvar( pEntity, var_entity_state, pState );
                    set_entvar( pEntity, var_nextthink, flGameTime + Entity_FadeOut_TickRate );
                    return
                }

                // if( GNextThink > 0.0 && flGameTime >= SzLifeTime )           // well the condition is impossible since it already kills it self in the skins advancing section before coming to this point 
                // {
                //     BIT_ADD( pState, EntityState_FadingOut );
                //     set_entvar( pEntity, var_entity_state, pState );
                //     set_entvar( pEntity, var_nextthink, flGameTime + Entity_FadeOut_TickRate );
                //     return
                // }

                set_entvar( pEntity, var_nextthink, flGameTime + Entity_Charge_B_End1_Nextthink )
            }

            case Type_Charge_B_End2:
            {
                if( ++pSkin >= Entity_Charge_B_End2_Skins )
                {
                    UTIL_KillEntity( pEntity )
                    return
                }

                // if( GNextThink > 0.0 && flGameTime >= SzLifeTime )   // same here, the condition is impossible since it already kills it self in the skins advancing section before coming to this point 
                // {
                //     UTIL_KillEntity( pEntity )
                //     return
                // }

                set_entvar( pEntity, var_nextthink, flGameTime + Entity_Charge_B_End2_Nextthink )
            }
            
            case Type_SlashC:
            {
                if( ++pSkin >= Entity_Slash_C_Skins )
                {
                    UTIL_KillEntity( pEntity )
                    return
                }

                if( GNextThink > 0.0 && flGameTime >= SzLifeTime )
                {
                    UTIL_KillEntity( pEntity )
                    return
                }

                set_entvar( pEntity, var_nextthink, flGameTime + Entity_Slash_C_Nextthink )
            }
        }

        set_entvar( pEntity, var_skin, pSkin );
        set_entvar( pEntity, var_slashc_count, iCount )
    }
}

/* -> TE_EXPLOSION <- */
stock UTIL_TE_EXPLOSION( const iszModelIndex, const Float: vecOrigin[3], const Float: flUp, const Float: flScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
    message_begin_f( MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin )
    write_byte( TE_EXPLOSION )
    write_coord_f( vecOrigin[ 0 ] )
    write_coord_f( vecOrigin[ 1 ] )
    write_coord_f( vecOrigin[ 2 ] + flUp )
    write_short( iszModelIndex )
    write_byte( floatround( flScale ) ) 
    write_byte( iFramerate )
    write_byte( bitsFlags )
    message_end()
}

stock EmitSound_FromPos( const Float: vecOrigin[3], const szSound[], Float: flVol = VOL_NORM, Float: flAttn = ATTN_NORM, iFlags = 0, iPitch = PITCH_NORM )
{
    engfunc( EngFunc_EmitAmbientSound, 0, vecOrigin, szSound, flVol, flAttn, iFlags, iPitch );
}
#if defined WF_DEBUG
    stock WF_Debug( const szFmt[ ], any: ... )
    {
        new szMsg[ 256 ];
        vformat( szMsg, charsmax( szMsg ), szFmt, 2 );
        server_print( "[WF_DEBUG] %s", szMsg );
        log_amx( "[WF_DEBUG] %s", szMsg );
    }
#endif
public ExHeroGive(plugin,params){new id=get_param(1);if(!is_user_alive(id) || zp_get_user_zombie(id))return 0;return CPlayer_GiveWeapon(id);}
public ExHeroRemove(plugin,params){new id=get_param(1);ExHeroCleanup(id);return CPlayer_RemoveWeapon(id);}
public zp_user_infected_pre(id){ExHeroCleanup(id);CPlayer_RemoveWeapon(id);}
public ExHeroKilled(id){ExHeroCleanup(id);}
stock ExHeroFindMuzzle(id){new e=-1;while((e=engfunc(EngFunc_FindEntityByString,e,"classname",szMuzzleClassName))>0)if(get_entvar(e,var_owner)==id)return e;return 0;}
stock ExHeroCleanup(id){
 remove_task(TASK_CHARGE_CHECK(id));
 new const classes[][]={"ent_whipfalil_muzzle","Ent_Da_Charge_B","Ent_Da_Charge_B_End1","Ent_Da_Charge_B_End2","Ent_Da_Slash_C_Range","exhero_mace_dummy"};
 for(new c=0;c<sizeof classes;c++){new e=-1;while((e=engfunc(EngFunc_FindEntityByString,e,"classname",classes[c]))>0)if(get_entvar(e,var_owner)==id)engfunc(EngFunc_RemoveEntity,e);}
 if(is_user_connected(id))ClearSyncHud(id,g_ExHud);g_ExHudVisible[id]=false;
}
public ExHeroHud(){
 for(new id=1;id<=32;id++){
  if(!is_user_connected(id)){g_ExHudVisible[id]=false;continue;}
  new item=0;if(is_user_alive(id) && !zp_get_user_zombie(id) && get_user_weapon(id)==CSW_KNIFE)item=get_member(id,m_pActiveItem);
  if(item<=0 || is_nullent(item) || !IsCustomWeapon(item,WeaponUnicalIndex)){
   if(g_ExHudVisible[id]){ClearSyncHud(id,g_ExHud);g_ExHudVisible[id]=false;}continue;
  }
  new ammo=get_member(id,m_rgAmmo,WeaponPrimaryAmmoIndex),bits=GetWeaponState(item),hits=get_member(item,m_Weapon_iHitCount),e=ExHeroFindMuzzle(id),status[48];new Float:frame;
  if(e>0)get_entvar(e,var_muzzle_stored_frame,frame);
  if(Weapon_HasCMode(bits) && ammo>0)copy(status,47,"ESPECIAL 3 LISTO: PULSA [R]");
  else if(Weapon_HasCMode(bits))copy(status,47,"ESPECIAL 3: ESPERA UNA CARGA");
  else if(e>0)copy(status,47,(frame>=22.0 && frame<=38.0)?"SUELTA AHORA - GIRO PERFECTO":"MANTEN CLIC DERECHO");
  else copy(status,47,"Haz 3 perfectos seguidos para [R]");
  set_hudmessage((Weapon_HasCMode(bits) && ammo>0) || (e>0 && frame>=22.0 && frame<=38.0)?70:255,220,100,0.72,0.78,0,0.0,0.2,0.0,0.0,-1);
  ShowSyncHudMsg(id,g_ExHud,"TYRANT MACE^nCargas: %d/5^nPerfectos: %d/3^n%s",ammo,clamp(hits,0,3),status);g_ExHudVisible[id]=true;
 }
}
