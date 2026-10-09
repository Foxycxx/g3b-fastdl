#include <zombieplague>
/*
 * ============================================================================
 *
 *  [CSO] Divine Beast
 *
 *  Copyright (C) 2025 StarGamerz. All Rights Reserved.
 *  This file is part of a PRIVATE PRODUCTION by StarGamerz.
 *
 *  Unauthorized copying, distribution, modification, or use of this file,
 *  via any medium, is strictly prohibited without the express written
 *  permission of StarGamers. in order to share plugin , share discord ;- https://discord.gg/WW4xYFQBhj
 *
 * ============================================================================
*/

/* ~ [ Plugin Info ] ~ */
new const szPluginName[] = "Coin Dart [ USP ]";
new const szPluginVersion[] = "1.1";
new const szPluginAuthor[] = "Invisibl3:@";     // - kamrixx if anyone wondering

/* ~ [ Includes ] ~ */
#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel     // [ xUnicorn ]

const PISTOL_SPECIAL_CODE = 676762319;

// Auto Fire ( PrimaryAttack_Pre ): set_pdata_int(pItem, m_iShotsFired, 0, linux_diff_weapon);
// UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITES[0], 0, random_float(0.04, 0.05), 255.0, 1, 0.04);

/* ~ [ Weapon List ] ~ */
#define WEAPON_CSW CSW_USP

new const PISTOL_WEAPONLIST[] = "coindart/weapon_coindart"; 
new const PISTOL_REFERENCE[] = "weapon_usp"; 
new const iPistolList[] = { 6, 100, -1, -1, 1, 4, WEAPON_CSW, 0 };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump


// Pistol Models //
new const PISTOL_MODEL_VIEW[] = "models/g3bmodel/ZTHEX/coindart/v_coindart.mdl";
new const PISTOL_MODEL_PLAYER[] = "models/coindart/p_coindart.mdl";
new const PISTOL_MODEL_WORLD[] = "models/coindart/w_coindart.mdl";


// Pistol Muzzle Flash Sprites //

new const ENTITY_MUZZLE_CLASSNAME[] = "exhero_coindart_muzzle";
new const ENTITY_MUZZLE_SPRITES[][] =
{
	"sprites/coindart/muzzleflash474.spr" // 0
}

// Pistol Ammo //
const CLIP_AMMO = 67;
const DEFAULT_AMMO = 900;

// Pistol Statistics //
const Float: SHOOT_RATE = 0.51;
const Float: SHOOT_ACCURACY = 1.0;
const Float: WEAPON_PUNCHANGLE = 1.0;
const Float: SHOOT_PUNCHANGLE = 0.23;

// Pistol Animations Time //
const Float: ANIM_IDLE_TIME = 6.03;
const Float: ANIM_RELOAD_TIME = 2.37;
const Float: ANIM_DRAW_TIME = 1.03;
const Float: ANIM_SHOOT_TIME = 1.03;
const Float: ANIM_SHOOT_B_START_TIME   = 0.73;
const Float: ANIM_SHOOT_B_END_TIME    = 0.37;
const Float: ANIM_SHOOT_B_LOOP_TIME    = 1.03;
const Float: ANIM_SHOOT_B2_TIME        = 1.07;
const Float: ANIM_SHOOT_SKILL_TIME        = 0.70;

/* ~ [ Entity:Skill ] ~ */
new const ENTITY_SKILL_CLASSNAME[] = "ent_coin_skill";
new const ENTITY_SKILL_MODEL[] = "models/coindart/ef_coindart_shockwave_final02.mdl";

const Float: SHOOT_SKILLTRACE_DISTANCE          = 250.0;
const Float: SHOOT_SKILLDAMAGE                  = 169.0;
const Float: SHOOT_SKILLKNOCKBACK              = 570.0;
const Float: SHOOT_SKILLKNOCKUP               = 450.0;

new const Float: ShootSkillAngles[ ][ 2 ] =       // 3ihcsWex
{
    { 0.0,   0.0  },  
    { 20.0,   0.0  },   
    { -20.0,  0.0  },       
    { 0.0,   15.0  },     
    { 0.0,  -15.0  }    
};



/* ~ [ Projectile Entity: Coint ] ~ */
new const ENTITY_COIN_CLASSNAME[] = "ent_coin_projectile";
new const ENTITY_COIN_PROJECTILE_MODEL[] = "models/coindart/ef_coindart_projectile.mdl";

const Float: ENTITY_COIN_LIFETIME = 5.0;
const Float: ENTITY_PROJECTILE_DAMAGE = 87.5;   // projectile damage
const Float: ENTITY_PROJECTILE_DAMAGE_B = 175.0;   // projectile damage on b 
const Float: ENTITY_COIN_PROJECTILE_SPEED = 1700.0; // projectile speed 

/**
 * Cso Like trail
 * 
 * Better Not use cso trial , the default one looks better
 */
// #define CSO_TRAIL

#if defined CSO_TRAIL
    new const ENTITY_COIN_TRAIL[] = "sprites/coindart/ef_coindart_trail.spr";
#else
    new const ENTITY_COIN_TRAIL[] = "sprites/laserbeam.spr";
#endif


/**
 * When using this method, the weapon Speical Ammo will be charged constantly,
 * regardless of whether the player has it in his hands or not, the main thing is that it should be.
 * 
 * NB! This method uses Ham_Player_PreThink, which is why,
 * if you have a weak server, the load on your server (CPU, RAM) may increase
 */
#define EnableChargeAlways

enum _: ePistolAnims
{
    ANIM_IDLE = 0,
    ANIM_IDLE_READY,
    ANIM_IDLE_EMPTY,
    ANIM_RELOAD,
    ANIM_RELOAD_READY,
    ANIM_RELOAD_EMPTY,
    ANIM_DRAW,
    ANIM_DRAW_READY,
    ANIM_DRAW_EMPTY,
    ANIM_SHOOT_A,
    ANIM_SHOOT_A_READY,
    ANIM_SHOOT_B_START,
    ANIM_SHOOT_B_START_READY,
    ANIM_SHOOT_B_END,
    ANIM_SHOOT_B_END_READY,
    ANIM_SHOOT_B2_LOOP,
    ANIM_SHOOT_B2_LOOP_READY,
    ANIM_SHOOT_B2,
    ANIM_SHOOT_B2_READY,
    ANIM_SKILL1
}

/* -> Hit Results <- */
enum _: eHitResults
{
	HitResult_None = 0,
	HitResult_World,
	HitResult_Entity
};

// Offsets //
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rgpPlayerItems_CWeaponBox = 34;
const m_maxFrame = 35;
const m_pPlayer = 41;
const m_pNext = 42
const m_iId = 43;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_flTimeWeaponIdle = 48;
const m_iPrimaryAmmoType = 49;
const m_iSecondaryAmmoType      = 50;
const m_iClip = 51;
const m_fInReload = 54;
const m_flNextAttack = 83;
const m_flAccuracy = 62;
const m_iShotsFired = 64;
const m_rgAmmo = 376;
const m_rpgPlayerItems = 367;
const m_flVelocityModifier = 108;
const m_iWeaponState = 74;
const WeaponSecondaryAmmoIndex  = 18;
const m_pActiveItem = 373;
const m_LastHitGroup = 75;


// Global Parameters //
new gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,
    gl_iszAllocString_Coin,
    gl_iszAllocString_Skill,
    gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,
    gl_iszAllocString_InfoTarget,

    gl_iszAllocString_TrailEffect,
    gl_iszAllocString_MuzzleKey;

// Pistol Conditions //
#define IsPdataValid(%0) (pev_valid(%0) == 2)
#define IsCustomPistol(%0) (pev_valid(%0) == 2 && pev(%0, pev_impulse) == PISTOL_SPECIAL_CODE)
#define IsCustomMuzzle(%0)	(pev(%0, pev_impulse) == gl_iszAllocString_MuzzleKey)
#define Weapon_HaveSpecialAmmo(%0) (Weapon_GetSpecialAmmo(%0) > 0)
#define IsEnemy(%1,%2) (IsValidVictim(%1,%2))

/* -> Bits <- */
#define BIT(%0) (1<<(%0))
#define BIT_ADD(%0,%1) (%0 |= %1)
#define BIT_VALID(%0,%1) ((%0 & %1) == %1)

/* ---> Hud Flags <--- */        // ~x3 Arabas shooting star 
#define HIDEHUD_NONE   (1<<7)           
#define SET_CUSTOM_HUD (HIDEHUD_MONEY)  
#define RESET_HUD      (HIDEHUD_NONE)   


/* ~ [ Special Ammo ] ~ */
#define pev_special_ammo            pev_gaitsequence
const SPECIAL_AMMO_MAX              = 5;
new Float: Special_CoinTimerX[33];

const Float: AMMO_REGEN_TIME        = 7.0;

/* ~ [ Weapon States ] ~ */
enum
{
    WEAPONSTATE_NULL = 0,
    WEAPONSTATE_SHOOT_B_START,
    WEAPONSTATE_SHOOT_B_LOOP,
    WEAPONSTATE_SHOOT_B_END
}

#define GetWeaponState(%0)      (get_pdata_int(%0, m_iWeaponState, linux_diff_weapon))
#define SetWeaponState(%0,%1)   (set_pdata_int(%0, m_iWeaponState, %1, linux_diff_weapon))


/* ~ [ Sound ] ~ */
new const xWeaponSounds[ ][ ] = 
{
	"weapons/coindart-1.wav",
	"weapons/coindart-1_1.wav",
	"weapons/coindart-2.wav"
};

enum _: iWeaponSounds
{
	Sound_ShootA,
	Sound_ShootA_Golden,
	Sound_ShootSkill
};



// AMX Mod X //
public plugin_init()
{
 RegisterHam(Ham_Killed,"player","CoinKilled",1);
    // https://cso.fandom.com/wiki/Divine_Beast
    register_plugin( szPluginName, szPluginVersion, szPluginAuthor );

    // Fakemeta
    register_forward(FM_UpdateClientData,      "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel, 			   "FM_Hook_SetModel_Pre",              false);

    // Pistol
    RegisterHam(Ham_Item_Deploy,             PISTOL_REFERENCE,    "CPistol__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,    PISTOL_REFERENCE,    "CPistol__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_SecondaryAttack,  PISTOL_REFERENCE,    "CPistol__SecondaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_Reload,           PISTOL_REFERENCE,	  "CPistol__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,          PISTOL_REFERENCE,	  "CPistol__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,            PISTOL_REFERENCE,	  "CPistol__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,		 PISTOL_REFERENCE,    "CPistol__AddToPlayer_Post",      true);
    RegisterHam(Ham_Weapon_WeaponIdle,       PISTOL_REFERENCE,	  "CPistol__Idle_Pre",             false);

    #if defined EnableChargeAlways
        RegisterHam( Ham_Player_PreThink, "player", "Ham_CPlayer_PreThink_Post", true );
    #endif

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, PISTOL_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, PISTOL_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, PISTOL_MODEL_PLAYER);
    gl_iszAllocString_Coin  = engfunc(EngFunc_AllocString, ENTITY_COIN_CLASSNAME);
    gl_iszAllocString_Skill  = engfunc(EngFunc_AllocString, ENTITY_SKILL_CLASSNAME);
    gl_iszAllocString_InfoTarget  = engfunc(EngFunc_AllocString, "info_target");
    
    RegisterHam(Ham_Think, "env_sprite", "CMuzzleFlash__Think_Pre", false);

    // Entity
    RegisterHam( Ham_Think, "info_target", "CEffects__Think_Pre", false );
    RegisterHam( Ham_Touch, "info_target", "CEffects__Touch_Pre", false );

    // Muzzle Flash
    gl_iszAllocString_MuzzleKey = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);

    // Console Command
    register_clcmd("say /cd", "Command_GivePistol");
}

public plugin_precache()
{
    precache_generic("sound/weapons/coindart_charge_loop.wav");
    precache_generic("sound/weapons/coindart_draw.wav");
    precache_generic("sound/weapons/coindart_reload1.wav");
    precache_generic("sound/weapons/coindart_reload2.wav");

    // Valve blood sprites must be precached during plugin_precache, never plugin_init.
    gl_iszModelIndex_BloodSpray = precache_model_ex("sprites/bloodspray.spr", true);
    gl_iszModelIndex_BloodDrop = precache_model_ex("sprites/blood.spr", true);

    precache_generic("sound/weapons/coindart-1.wav");
    precache_generic("sound/weapons/coindart-1_1.wav");
    precache_generic("sound/weapons/coindart-2.wav");
    precache_generic("sound/weapons/coindart_charge.wav");
    precache_generic("sound/weapons/coindart_charge_end.wav");
    precache_generic("sound/weapons/coindart_charge_fx.wav");
    precache_generic("sound/weapons/coindart_charge_idle.wav");
    precache_generic("sound/weapons/coindart_charge_loop.wav");
    precache_generic("sound/weapons/coindart_draw.wav");
    precache_generic("sound/weapons/coindart_reload1.wav");
    precache_generic("sound/weapons/coindart_reload2.wav");
    // Hook weapon
    register_clcmd(PISTOL_WEAPONLIST, "Command_HookWeapon");

    // Precache Models

    precache_model_ex( PISTOL_MODEL_VIEW );
    precache_model_ex( PISTOL_MODEL_PLAYER );
    precache_model_ex( PISTOL_MODEL_WORLD );
    precache_model_ex( ENTITY_COIN_PROJECTILE_MODEL );
    precache_model_ex( ENTITY_SKILL_MODEL );

    new i;

    // Precache Sounds
    for ( i = 0; i < sizeof xWeaponSounds; i++ )
	    engfunc( EngFunc_PrecacheSound, xWeaponSounds[ i ] );

    // Precache Muzzle Flash Sprites
    for(i = 0; i < sizeof ENTITY_MUZZLE_SPRITES;i++) 
        precache_model_ex( ENTITY_MUZZLE_SPRITES[i] );

    gl_iszAllocString_TrailEffect = precache_model_ex( ENTITY_COIN_TRAIL );
    


    #if defined PrecacheSoundsFromModel
	    UTIL_PrecacheSoundsFromModel( PISTOL_MODEL_VIEW );
    #endif

    // Precache Generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", PISTOL_WEAPONLIST);
    engfunc(EngFunc_PrecacheGeneric, szWeaponList);
}

public Command_HookWeapon(pPlayer)
{
    engclient_cmd(pPlayer, PISTOL_REFERENCE);
    return PLUGIN_HANDLED;
}

public Command_GivePistol(pPlayer)
{
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || zp_get_user_survivor(pPlayer)) return 0;
    static pPistol; pPistol = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);

    if(!IsPdataValid(pPistol)) return FM_NULLENT;
    set_pev(pPistol, pev_impulse, PISTOL_SPECIAL_CODE);

    ExecuteHam(Ham_Spawn, pPistol);

    Weapon_SetClip(pPistol, CLIP_AMMO);

    UTIL_DropWeapon(pPlayer, ExecuteHamB(Ham_Item_ItemSlot, pPistol));

    if(!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pPistol))
    {
        set_pev(pPistol, pev_flags, pev(pPistol, pev_flags) | FL_KILLME);
        return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, pPistol, pPlayer);

    UTIL_WeaponList(pPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pPistol, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) < DEFAULT_AMMO)
    set_pdata_int(pPlayer, iAmmoType, DEFAULT_AMMO, linux_diff_player);

    emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

// Fakemeta //
public FM_Hook_UpdateClientData_Post(pPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(pPlayer)) return;

    static pItem; pItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);

    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(pEntity)
{
    if(pev_valid(pEntity) != 2) return FMRES_IGNORED;
    static i, szClassName[32], pItem;
    pev(pEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        pItem = get_pdata_cbase(pEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);
            
        if(IsPdataValid(pItem) && IsCustomPistol(pItem))
        {
            engfunc(EngFunc_SetModel, pEntity, PISTOL_MODEL_WORLD);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

// Hamsandwich //
public CPistol__Holster_Post(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return ;

    UTIL_KillMuzzleFlash(pPlayer);

    Hud_Set(pPlayer, RESET_HUD)

    Weapon_SetAllTimers(pItem, pPlayer, 0.0, 0.0, 0.0, 0.0 );
    
    SetWeaponState(pItem, WEAPONSTATE_NULL);
}

public CPistol__Deploy_Post(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return ;

    set_pev_string(pPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(pPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(pPlayer, ANIM_DRAW);

    Hud_Set(pPlayer, RESET_HUD);

    if(Weapon_HaveSpecialAmmo(pItem))
        UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITES[0], 0, 0.035, 255.0, 1, 0.04);

    Player_SetNextAttack(pPlayer, ANIM_DRAW_TIME);
    Weapon_SetTimeWeaponIdle(pItem, ANIM_DRAW_TIME);
}

public CPistol__PostFrame_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;
    static iButton; iButton = pev(pPlayer, pev_button);
    static iState;  iState  = GetWeaponState(pItem);

    // Reload logic
    static iClip; iClip = Weapon_GetClip(pItem);
    if(Weapon_GetReload(pItem) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
        static iAmmo; iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);
        static j; j = min(CLIP_AMMO - iClip, iAmmo);
        set_pdata_int(pPlayer, iAmmoType, iAmmo - j, linux_diff_player);

        Weapon_SetClip(pItem, iClip + j);
        Weapon_SetReload(pItem, 0);
    }

    #if !defined EnableChargeAlways
        CWeapon_ChargeAmmo(pItem, pPlayer, SPECIAL_AMMO_MAX, AMMO_REGEN_TIME);
    #endif

    if((iButton & IN_ATTACK2) && Weapon_GetNextSecondaryAttack(pItem) <= 0.0)
        ExecuteHamB(Ham_Weapon_SecondaryAttack, pItem);

    if(iState == WEAPONSTATE_SHOOT_B_START)
    {
        if(iButton & IN_ATTACK2)
        {
            if(Weapon_GetNextPrimaryAttack(pItem) > 0.0) 
                return HAM_IGNORED;

            UTIL_SendWeaponAnim(pPlayer, ANIM_SHOOT_B_END);
            Weapon_SetAllTimers(pItem, pPlayer, ANIM_SHOOT_B_END_TIME, ANIM_SHOOT_B_END_TIME, ANIM_SHOOT_B_END_TIME, 0.1 );

            SetWeaponState(pItem, WEAPONSTATE_SHOOT_B_LOOP);
        }
        else
        {
            new Float: flPressTime; pev(pItem, pev_fuser2, flPressTime);
            new Float: flHeldTime = get_gametime() - flPressTime;

            if(flHeldTime >= 0.01 && flHeldTime <= 0.2 )
            {
                // Consume the tap once before damage can enter other hooks.
                SetWeaponState(pItem, WEAPONSTATE_SHOOT_B_END);
                // client_print(pPlayer, print_center, "M2 PRESSED")
                if(Weapon_HaveSpecialAmmo( pItem ) )
                    CWeapon__CreateSkill( pPlayer, true, 1 );

                return HAM_SUPERCEDE;
            }

            CPistol__DoShootBEnd(pItem, pPlayer, ANIM_SHOOT_B2, ANIM_SHOOT_B2_TIME, 0, 0);
        }
    }

    if(iState == WEAPONSTATE_SHOOT_B_LOOP)
    {
        if(~iButton & IN_ATTACK2)
            CPistol__DoShootBEnd(pItem, pPlayer, ANIM_SHOOT_B2, ANIM_SHOOT_B2_TIME, 0, 1);
    }

    if(iState == WEAPONSTATE_SHOOT_B_END)
    {
        if(Weapon_GetNextPrimaryAttack(pItem) > 0.0) 
            return HAM_IGNORED;

        SetWeaponState(pItem, WEAPONSTATE_NULL);
    }

    return HAM_IGNORED;
}

public CPistol__AddToPlayer_Post( pItem, pPlayer )
{
    if( IsPdataValid( pItem ) && IsCustomPistol( pItem ) )
    {
        if( pev( pItem, pev_owner ) <= 0 )
        {
            set_pdata_int( pItem, m_iSecondaryAmmoType, WeaponSecondaryAmmoIndex, linux_diff_weapon );
            set_pev( pItem, pev_special_ammo, 0 );
        }

        Weapon_SetSpecialAmmo( pItem, pPlayer, Weapon_GetSpecialAmmo( pItem ) );
        UTIL_WeaponList( pPlayer, true );
    }
    else if( !IsCustomPistol( pItem ) )
    {
        UTIL_WeaponList( pPlayer, false );
    }
}


public CPistol__Idle_Pre(pItem)
{
	if(!IsPdataValid(pItem) || !IsCustomPistol(pItem) || get_pdata_float(pItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	
	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(!is_user_connected(pPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(pPlayer, ANIM_IDLE);
	Weapon_SetTimeWeaponIdle(pItem, ANIM_IDLE_TIME);

	return HAM_SUPERCEDE;
}

#if defined EnableChargeAlways
    public Ham_CPlayer_PreThink_Post( const pPlayer )
    {
        if( !is_user_alive( pPlayer ) )
            return;

        static pItem; pItem = get_pdata_cbase( pPlayer, m_pActiveItem, linux_diff_player );
        
        if( !IsPdataValid( pItem ) || !IsCustomPistol( pItem ) )
            return;


        if( Special_CoinTimerX[ pPlayer ] > get_gametime() )
            return;

        CWeapon_ChargeAmmo( pItem, pPlayer, SPECIAL_AMMO_MAX, AMMO_REGEN_TIME );
    }
#endif


public CPistol__Reload_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;

    static iClip; iClip = get_pdata_int(pItem, m_iClip, linux_diff_weapon);

    if(iClip >= CLIP_AMMO) return HAM_SUPERCEDE;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    Weapon_SetClip(pItem, 0);

    ExecuteHam(Ham_Weapon_Reload, pItem);

    Weapon_SetClip(pItem, iClip);
    Weapon_SetReload(pItem, 1);

    UTIL_SendWeaponAnim(pPlayer, ANIM_RELOAD);
    Weapon_SetAllTimers(pItem, pPlayer, ANIM_RELOAD_TIME, ANIM_RELOAD_TIME, ANIM_RELOAD_TIME, ANIM_RELOAD_TIME );
    
    return HAM_SUPERCEDE;
}

public CPistol__PrimaryAttack_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;
    if(get_pdata_int(pItem, m_iShotsFired, 4) != 0) return HAM_SUPERCEDE;

    static iClip; iClip = Weapon_GetClip(pItem);
    if(!iClip)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        Weapon_SetNextPrimaryAttack(pItem, 0.2);

        return HAM_SUPERCEDE;
    }

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;

    CWeapon__Create_Projectile( pPlayer, 0 );
    Weapon_SetClip(pItem, iClip - 1);

    UTIL_SendWeaponAnim(pPlayer, ANIM_SHOOT_A);
    Weapon_SetAllTimers(pItem, pPlayer, SHOOT_RATE, SHOOT_RATE, ANIM_SHOOT_TIME, SHOOT_RATE );

    set_pdata_float(pItem, m_flAccuracy, SHOOT_ACCURACY, linux_diff_weapon);


    return HAM_SUPERCEDE;
}

public CPistol__SecondaryAttack_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem))
        return HAM_IGNORED;

    static iState; iState = GetWeaponState(pItem);

    if(iState == WEAPONSTATE_SHOOT_B_END)
        return HAM_SUPERCEDE;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;

    switch(iState)
    {
        case WEAPONSTATE_NULL:
        {
            SetWeaponState(pItem, WEAPONSTATE_SHOOT_B_START);
            set_pev(pItem, pev_fuser2, get_gametime());

            UTIL_SendWeaponAnim(pPlayer, ANIM_SHOOT_B_START);
            Weapon_SetAllTimers(pItem, pPlayer, ANIM_SHOOT_B_START_TIME, ANIM_SHOOT_B_START_TIME, ANIM_SHOOT_B_START_TIME, 0.1 );
        }
        case WEAPONSTATE_SHOOT_B_START:
        { 

        }
        case WEAPONSTATE_SHOOT_B_LOOP:
        {
            // Keep looping
            UTIL_SendWeaponAnim(pPlayer, ANIM_SHOOT_B2_LOOP);
            Weapon_SetAllTimers(pItem, pPlayer, ANIM_SHOOT_B_LOOP_TIME, ANIM_SHOOT_B_LOOP_TIME, ANIM_SHOOT_B_LOOP_TIME, 0.1 );
        }
    }

    return HAM_SUPERCEDE;
}


public CEffects__Think_Pre( pEnt )
{
    if( !IsPdataValid( pEnt ) )
        return HAM_IGNORED;

    static pClassname; pClassname = pev(pEnt, pev_classname);
    if(pClassname == gl_iszAllocString_Coin) { set_pev(pEnt,pev_flags,FL_KILLME); return HAM_SUPERCEDE; }

    if(pClassname == gl_iszAllocString_Skill)
    {
        set_pev( pEnt, pev_flags, FL_KILLME );

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}


public CEffects__Touch_Pre( pEnt, pTouch )
{
    if( !IsPdataValid(pEnt) )
        return HAM_IGNORED;

    static pClassname; 
    pClassname = pev(pEnt, pev_classname);

    if(pClassname != gl_iszAllocString_Coin)
        return HAM_IGNORED;
    if(pev(pEnt, pev_flags) & FL_KILLME) return HAM_SUPERCEDE;

    static pOwner; 
    pOwner = pev( pEnt, pev_owner );
    if(!is_user_alive(pOwner) || zp_get_user_zombie(pOwner)) { set_pev(pEnt,pev_flags,FL_KILLME); return HAM_SUPERCEDE; }

    if( pTouch == pOwner ) 
        return HAM_IGNORED;

    if( is_user_connected(pTouch) && !zp_get_user_zombie(pTouch) ) 
    {
        set_pev( pEnt, pev_flags, pev(pEnt, pev_flags) | FL_KILLME );
        return HAM_IGNORED;
    }

    static Float: vecOrigin[3];
    pev( pEnt, pev_origin, vecOrigin );

    if( engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY )
    {
        set_pev( pEnt, pev_flags, pev(pEnt, pev_flags) | FL_KILLME );
        return HAM_SUPERCEDE;
    }

    set_pev( pEnt, pev_solid,    SOLID_NOT );
    set_pev( pEnt, pev_movetype, MOVETYPE_NONE );
    set_pev( pEnt, pev_velocity, Float:{0.0, 0.0, 0.0} );

    set_pev(pEnt,pev_flags,pev(pEnt,pev_flags)|FL_KILLME);
    new Float: flDamage = pev(pEnt, pev_iuser2) ? ENTITY_PROJECTILE_DAMAGE_B : ENTITY_PROJECTILE_DAMAGE;

    if( is_user_alive(pTouch) )
    {
        ExecuteHamB(Ham_TakeDamage, pTouch, pEnt, pOwner, flDamage, DMG_BULLET);
    }
    else if(pev_valid(pTouch))
    {
        static szClassName[32];
        pev(pTouch, pev_classname, szClassName, charsmax(szClassName));

        if(equal(szClassName, "func_breakable") || equal(szClassName, "func_pushable") || equal(szClassName, "hostage_entity"))
        {
            ExecuteHamB(Ham_TakeDamage, pTouch, pEnt, pOwner, flDamage, DMG_BULLET);
        }
    }

    set_pev( pEnt, pev_flags, pev(pEnt, pev_flags) | FL_KILLME );
 
    return HAM_SUPERCEDE; 
}

public CMuzzleFlash__Think_Pre(const pSprite)
{
    if(!IsPdataValid(pSprite) || !IsCustomMuzzle(pSprite)) return HAM_IGNORED;
 new owner=pev(pSprite,pev_owner);if((pev(pSprite,pev_flags)&FL_KILLME)||!is_user_alive(owner)||zp_get_user_zombie(owner)){set_pev(pSprite,pev_flags,pev(pSprite,pev_flags)|FL_KILLME);return HAM_SUPERCEDE;}

    new Float: flFrame; pev(pSprite, pev_frame, flFrame);
    new Float: flNextThink; pev(pSprite, pev_fuser3, flNextThink);

    flFrame++;

    if(flFrame >= get_pdata_float(pSprite, m_maxFrame, 4))
        flFrame = 0.0;

    set_pev(pSprite, pev_frame, flFrame);
    set_pev(pSprite, pev_nextthink, get_gametime() + flNextThink);

    return HAM_SUPERCEDE;
}

// Stocks //
stock UTIL_CreateMuzzleFlash(const pPlayer, const szMuzzleSprite[], const iMuzzleLoop, const Float: flScale, const Float: flBrightness, const iAttachment, Float: flNextThink)
{
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100) return FM_NULLENT;
        
    static pSprite, iszAllocStringCached;

    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    	pSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
        
    if(!IsPdataValid(pSprite)) return FM_NULLENT;
        
    set_pev(pSprite, pev_model, szMuzzleSprite);
    set_pev(pSprite, pev_spawnflags, SF_SPRITE_ONCE);
        
    set_pev(pSprite, pev_classname, ENTITY_MUZZLE_CLASSNAME);
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

stock UTIL_KillMuzzleFlash(const pPlayer)
{
	new pMuzzleFlash = FM_NULLENT;

	while((pMuzzleFlash = fm_find_ent_by_owner(pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, pPlayer)) > 0)
    if(IsPdataValid(pMuzzleFlash)) 
        set_pev(pMuzzleFlash, pev_flags, FL_KILLME);
}

stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
    set_pev(pPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, pPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}


stock Hud_Set(pPlayer, Hud)
{
    static gl_iMsgID_HideWeapon; 
    if ( !gl_iMsgID_HideWeapon ) 
        gl_iMsgID_HideWeapon = get_user_msgid( "HideWeapon" );


    message_begin(MSG_ONE, gl_iMsgID_HideWeapon, _, pPlayer);
    write_byte(Hud);
    message_end();
}


stock UTIL_WeaponList(const pPlayer, bool: bEnabled)
{

    static iMsgId_Weaponlist; 
    if ( !iMsgId_Weaponlist ) 
        iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

    message_begin(MSG_ONE, iMsgId_Weaponlist, _, pPlayer);
    write_string(bEnabled ? PISTOL_WEAPONLIST : PISTOL_REFERENCE);
    write_byte(iPistolList[0]);
    write_byte(bEnabled ?  CLIP_AMMO : iPistolList[1]);
    write_byte(bEnabled ? WeaponSecondaryAmmoIndex : -1);
    write_byte(bEnabled ? SPECIAL_AMMO_MAX   : -1);
    write_byte(iPistolList[4]);
    write_byte(iPistolList[5]);
    write_byte(iPistolList[6]);
    write_byte(iPistolList[7]);
    message_end();
}

stock UTIL_DropWeapon(const pPlayer, const iSlot)
{
    static pEntity, iNext, szWeaponName[32];
    pEntity = get_pdata_cbase(pPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(pEntity > 0)
    {       
        do 
        {
            iNext = get_pdata_cbase(pEntity, m_pNext, linux_diff_weapon);
            if(get_weaponname(get_pdata_int(pEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
            engclient_cmd(pPlayer, "drop", szWeaponName);
        } 
        while((pEntity = iNext) > 0);
    }
}

stock Weapon_DoRecoil( pPlayer, Float: flValue )
{
    static Float: vecPunch[ 3 ];
    vecPunch[ 0 ] = flValue * -1.0;
    vecPunch[ 1 ] = random_float( flValue * -0.5, flValue * 0.5 );
    vecPunch[ 2 ] = 0.0;
    set_pev( pPlayer, pev_punchangle, vecPunch );
}


// ~ [ Weapon Time Stocks ] ~ //
stock Weapon_SetNextPrimaryAttack( pItem, Float: flTime )
{
    set_pdata_float( pItem, m_flNextPrimaryAttack, flTime, linux_diff_weapon );
}

stock Weapon_SetNextSecondaryAttack( pItem, Float: flTime )
{
    set_pdata_float( pItem, m_flNextSecondaryAttack, flTime, linux_diff_weapon );
}

stock Weapon_SetTimeWeaponIdle( pItem, Float: flTime )
{
    set_pdata_float( pItem, m_flTimeWeaponIdle, flTime, linux_diff_weapon );
}

stock Player_SetNextAttack( pPlayer, Float: flTime )
{
    set_pdata_float( pPlayer, m_flNextAttack, flTime, linux_diff_player );
}

// Set all attack timers at once
stock Weapon_SetAllTimers( pItem, pPlayer, Float: flPrimary, Float: flSecondary, Float: flIdle, Float: flNext )
{
    set_pdata_float( pItem, m_flNextPrimaryAttack,   flPrimary,   linux_diff_weapon );
    set_pdata_float( pItem, m_flNextSecondaryAttack, flSecondary, linux_diff_weapon );
    set_pdata_float( pItem, m_flTimeWeaponIdle,      flIdle,      linux_diff_weapon );
    set_pdata_float( pPlayer, m_flNextAttack,          flNext,      linux_diff_player );
}

// ~ [ Weapon Clip / Reload Stocks ] ~ //

stock Weapon_GetClip( pItem )
{
    return get_pdata_int( pItem, m_iClip, linux_diff_weapon );
}

stock Weapon_SetClip( pItem, iClip )
{
    set_pdata_int( pItem, m_iClip, iClip, linux_diff_weapon );
}

stock Weapon_GetReload( pItem )
{
    return get_pdata_int( pItem, m_fInReload, linux_diff_weapon );
}

stock Weapon_SetReload( pItem, iState )
{
    set_pdata_int( pItem, m_fInReload, iState, linux_diff_weapon );
}


// ~ [ Ammo Stocks ] ~ //
stock Weapon_SetSpecialAmmo( pItem, pPlayer, iAmount )
{
    set_pev( pItem, pev_special_ammo, iAmount );
    set_pdata_int( pPlayer, m_rgAmmo + WeaponSecondaryAmmoIndex, iAmount, linux_diff_player );
}

stock Weapon_GetSpecialAmmo( pItem )
{
    return pev( pItem, pev_special_ammo );
}

// ~ [ Weapon Get Time Stocks ] ~ //

stock Float: Weapon_GetNextPrimaryAttack( pItem )
{
    return get_pdata_float( pItem, m_flNextPrimaryAttack, linux_diff_weapon );
}

stock Float: Weapon_GetNextSecondaryAttack( pItem )
{
    return get_pdata_float( pItem, m_flNextSecondaryAttack, linux_diff_weapon );
}

stock Float: Weapon_GetTimeWeaponIdle( pItem )
{
    return get_pdata_float( pItem, m_flTimeWeaponIdle, linux_diff_weapon );
}

stock Float: Player_GetNextAttack( pPlayer )
{
    return get_pdata_float( pPlayer, m_flNextAttack, linux_diff_player );
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


/* ~ [ Vector Helper Stocks ] ~ */

// eye-position se forward direction 
stock UTIL_GetEyePosition(const pPlayer, Float: vecOut[3])
{
    static Float: vecOrigin[3], Float: vecViewOfs[3];

    pev(pPlayer, pev_origin, vecOrigin);
    pev(pPlayer, pev_view_ofs, vecViewOfs);

    xs_vec_add(vecOrigin, vecViewOfs, vecOut);
}

// forward-looking direction se unit
stock UTIL_GetForwardVector(const pPlayer, Float: vecOut[3])
{
    static Float: vecAngles[3];
    pev(pPlayer, pev_v_angle, vecAngles);

    angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecOut);
}

// eyes se thora fixed distance aage
stock UTIL_GetForwardSpawnPoint(const pPlayer, const Float: flDistance, Float: vecOut[3])
{
    static Float: vecEye[3], Float: vecForward[3];

    UTIL_GetEyePosition(pPlayer, vecEye);
    UTIL_GetForwardVector(pPlayer, vecForward);

    xs_vec_mul_scalar(vecForward, flDistance, vecForward);
    xs_vec_add(vecEye, vecForward, vecOut);
}


public CWeapon__Create_Projectile( pPlayer, pColor )
{
    if( !is_user_alive( pPlayer ) ) 
        return FM_NULLENT;

    static pEntity;
    pEntity = engfunc( EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget );
    if( !IsPdataValid( pEntity ) ) 
        return FM_NULLENT;

    static Float: vAngles[3], Float: vecForward[3];
    static Float: VecStart[3], Float: vecVel[3];

    UTIL_GetForwardVector(pPlayer, vecForward);

    UTIL_GetForwardSpawnPoint(pPlayer, 5.0, VecStart);

    vecVel[0] = vecForward[0] * ENTITY_COIN_PROJECTILE_SPEED;
    vecVel[1] = vecForward[1] * ENTITY_COIN_PROJECTILE_SPEED;
    vecVel[2] = vecForward[2] * ENTITY_COIN_PROJECTILE_SPEED;

    engfunc( EngFunc_VecToAngles, vecVel, vAngles );

    set_pev_string( pEntity, pev_classname, gl_iszAllocString_Coin );
    set_pev( pEntity, pev_owner,     pPlayer );
    set_pev( pEntity, pev_movetype,  MOVETYPE_FLY );
    set_pev( pEntity, pev_solid,     SOLID_BBOX );
    set_pev( pEntity, pev_gravity,   0.0 );
    set_pev( pEntity, pev_friction,   0.0 );
    set_pev( pEntity, pev_angles,    vAngles );
    set_pev( pEntity, pev_velocity,  vecVel );
    set_pev( pEntity, pev_iuser2, pColor );
    set_pev(pEntity,pev_nextthink,get_gametime()+ENTITY_COIN_LIFETIME);

    engfunc( EngFunc_SetOrigin, pEntity, VecStart );
    engfunc( EngFunc_SetModel,  pEntity, ENTITY_COIN_PROJECTILE_MODEL );

    static Float: mins[3] = { -1.0, -1.0, -1.0 };
    static Float: maxs[3] = {  1.0,  1.0,  1.0 };
    engfunc( EngFunc_SetSize, pEntity, mins, maxs );

    new iLife, iWidth;
    new iWhite[ 3 ] = { 255, 255, 255 };
    new iGolden[ 3 ] = { 204, 224, 0 };

    #if defined CSO_TRAIL
        iLife = 1, iWidth = 5
    #else
        iLife = 2 , iWidth = 2
    #endif

    UTIL_TE_BEAMFOLLOW( MSG_BROADCAST, pEntity, gl_iszAllocString_TrailEffect, iLife, iWidth, pColor ? iGolden : iWhite, 200 );
    Weapon_DoRecoil(pPlayer, WEAPON_PUNCHANGLE * SHOOT_PUNCHANGLE );

    emit_sound(pPlayer, CHAN_WEAPON, pColor ? xWeaponSounds[Sound_ShootA_Golden] : xWeaponSounds[Sound_ShootA], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return pEntity;
}

stock UTIL_GetSkillSpawnPoint(const pPlayer, const Float: flForwardDist, Float: vecOut[3])
{
    static Float: vecOrigin[3], Float: vecForward[3];
    static Float: flDownOffset;

    static pFlags; pFlags = pev( pPlayer, pev_flags );
    pev(pPlayer, pev_origin, vecOrigin);
    UTIL_GetForwardVector(pPlayer, vecForward);

    flDownOffset = (pFlags & FL_DUCKING) ? 15.0 : 30.0;

    vecOut[0] = vecOrigin[0] + (vecForward[0] * flForwardDist);
    vecOut[1] = vecOrigin[1] + (vecForward[1] * flForwardDist);
    vecOut[2] = vecOrigin[2] - flDownOffset;
}

public CWeapon__CreateSkill( pPlayer, bool: CheckAmmo_KillMuzzle, bDeductAmmo )
{
    if( !is_user_alive( pPlayer ) || zp_get_user_zombie(pPlayer) ) 
        return FM_NULLENT;

    new pItem = get_pdata_cbase(pPlayer,m_pActiveItem,linux_diff_player);
    if(!IsPdataValid(pItem)||!IsCustomPistol(pItem))return FM_NULLENT;
    if(bDeductAmmo && !Weapon_HaveSpecialAmmo(pItem))return FM_NULLENT;
    static Float: flGameTime; flGameTime = get_gametime();

    static pEntity;
    pEntity = engfunc( EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget );
    if( !IsPdataValid( pEntity ) ) 
        return FM_NULLENT;


    static Float: vecSpawnPoint[3], Float: vAngles[3];
    UTIL_GetSkillSpawnPoint(pPlayer, 5.0, vecSpawnPoint);

    pev(pPlayer, pev_v_angle, vAngles);
    vAngles[0] = 0.0;   

    set_pev_string( pEntity, pev_classname, gl_iszAllocString_Skill );
    set_pev( pEntity, pev_owner, pPlayer );
    set_pev( pEntity, pev_movetype, MOVETYPE_NONE );
    set_pev( pEntity, pev_solid, SOLID_NOT );
    set_pev( pEntity, pev_angles, vAngles );

    engfunc( EngFunc_SetOrigin, pEntity, vecSpawnPoint );
    engfunc( EngFunc_SetModel, pEntity, ENTITY_SKILL_MODEL );

    UTIL_SetEntityAnim(pEntity, 0);

    set_pev( pEntity, pev_nextthink, flGameTime + 0.70 );   



    if(bDeductAmmo)
    {
        new iAmmo; iAmmo = Weapon_GetSpecialAmmo(pItem) - 1;
        Weapon_SetSpecialAmmo(pItem, pPlayer, iAmmo);

        if(CheckAmmo_KillMuzzle)
        {
            if(iAmmo <= 0)
                UTIL_KillMuzzleFlash(pPlayer);
        }
    }

    UTIL_SendWeaponAnim(pPlayer, ANIM_SKILL1);
    Weapon_SetAllTimers(pItem, pPlayer, ANIM_SHOOT_SKILL_TIME, ANIM_SHOOT_SKILL_TIME, ANIM_SHOOT_SKILL_TIME, 0.3);

    new Float: vecPlayerOrigin[ 3 ];
    pev( pPlayer, pev_origin, vecPlayerOrigin ) 
    UTIL_RadiusDamage( pPlayer, vecPlayerOrigin, 100.0, 125.0, 150.0, 50.0 );

    UTIL_FakeTraceLine( pPlayer, pItem, SHOOT_SKILLDAMAGE, SHOOT_SKILLTRACE_DISTANCE, SHOOT_SKILLKNOCKBACK, SHOOT_SKILLKNOCKUP, ShootSkillAngles, sizeof( ShootSkillAngles ) );

    emit_sound(pPlayer, CHAN_WEAPON, xWeaponSounds[Sound_ShootSkill], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return pEntity;

}

stock CWeapon_ChargeAmmo( const pItem, const pPlayer, const iMaxAmmo, Float:flRate )
{
    new iAmmo; iAmmo = Weapon_GetSpecialAmmo( pItem );
    new Float:flGameTime; flGameTime = get_gametime( );

    if( iAmmo < iMaxAmmo )
    {
        if( Special_CoinTimerX[ pPlayer ] <= 0.0 )
        {
            Special_CoinTimerX[ pPlayer ] = flGameTime + flRate;
        }
        else if( flGameTime >= Special_CoinTimerX[ pPlayer ] )
        {
            new PrevAmmo; PrevAmmo = iAmmo;
            iAmmo++;
            Weapon_SetSpecialAmmo( pItem, pPlayer, iAmmo );

            if(PrevAmmo == 0)
                UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITES[0], 0, 0.035, 255.0, 1, 0.04);

            Special_CoinTimerX[ pPlayer ] = ( iAmmo < iMaxAmmo ) ? flGameTime + flRate : 0.0;
        }
    }
    else
    {
        Special_CoinTimerX[ pPlayer ] = 0.0;
    }
}

stock CPistol__DoShootBEnd(pItem, pPlayer, iAnim, Float: flTimer, bDeductAmmo, CreateProjectile)
{
    if(bDeductAmmo)
    {
        new iAmmo; iAmmo = Weapon_GetSpecialAmmo(pItem) - 1;
        Weapon_SetSpecialAmmo(pItem, pPlayer, iAmmo);
    }

    if( CreateProjectile )
        CWeapon__Create_Projectile(pPlayer, 1)
        
    SetWeaponState(pItem, WEAPONSTATE_SHOOT_B_END);

    UTIL_SendWeaponAnim(pPlayer, iAnim);
    Weapon_SetAllTimers(pItem, pPlayer, flTimer, flTimer, flTimer, flTimer);
}

stock UTIL_SetEntityAnim(const pEntity, const iSequence)
{
    set_pev(pEntity, pev_frame, 1.0);
    set_pev(pEntity, pev_framerate, 1.0);
    set_pev(pEntity, pev_animtime, get_gametime());
    set_pev(pEntity, pev_sequence, iSequence);
}

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

/* -> By Nordic Warrior (https://dev-cs.ru/threads/222/page-19#post-151804) <- */
stock precache_model_ex(const szFileName[], bool: bValvePath = false) 
{
	if(file_exists(szFileName, bValvePath))
		return engfunc(EngFunc_PrecacheModel, szFileName);

	set_fail_state("Model <%s> not found. The plugin has been stopped.", szFileName);

	return false;
}


stock UTIL_FakeTraceLine(const pPlayer, const pItem, Float: flDamage, Float: flDistance, Float: flKnockBack, Float: flKnockUp, const Float: flSendAngles[][], iSendAnglesRight)     // 3ihcsWex
{
	new bitsHitResult, bitsVictims;
	new Float: vecStart[3]; UTIL_GetEyePosition(pPlayer, vecStart);

	new Float: vecViewAngle[3]; pev(pPlayer, pev_v_angle, vecViewAngle);
	new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];

	engfunc(EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp);

	new Float: flTan, Float: vecEnd[3];
	new pTrace = create_tr2(), pHit, Float: flFraction;

	for(new i; i < iSendAnglesRight; i++)
	{
		flTan = floattan(flSendAngles[i][0], degrees);
		vecEnd[0] = (vecForward[0] * flDistance) + (vecRight[0] * flTan * flDistance) + (vecUp[0] * flSendAngles[i][1]);
		vecEnd[1] = (vecForward[1] * flDistance) + (vecRight[1] * flTan * flDistance) + (vecUp[1] * flSendAngles[i][1]);
		vecEnd[2] = (vecForward[2] * flDistance) + (vecRight[2] * flTan * flDistance) + (vecUp[2] * flSendAngles[i][1]);

		xs_vec_add_scaled(vecStart, vecEnd, flDistance / xs_vec_len(vecEnd), vecEnd);

		engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace);
		get_tr2(pTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, vecStart, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, pPlayer, pTrace);
			get_tr2(pTrace, TR_flFraction, flFraction);

			if(flFraction == 1.0)
			{
				BIT_ADD(bitsHitResult, HitResult_None);
				continue;
			}

			engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace);
			get_tr2(pTrace, TR_flFraction, flFraction);

			if(flFraction == 1.0)
			{
				BIT_ADD(bitsHitResult, HitResult_None);
				continue;
			}

			pHit = get_tr2(pTrace, TR_pHit);
		}
		else pHit = get_tr2(pTrace, TR_pHit);

		if(!IsPdataValid(pHit))
		{
			BIT_ADD(bitsHitResult, HitResult_World);
			continue;
		}

		BIT_ADD(bitsHitResult, HitResult_Entity);

		if(BIT_VALID(bitsVictims, BIT(pHit)))
			continue;

		UTIL_FakeTraceAttack( pHit, pItem, pPlayer, flDamage * (1.0 - floatmin(flFraction, 0.7)), vecForward, pTrace, DMG_BULLET | DMG_NEVERGIB, flKnockBack, flKnockUp );

		if(is_user_alive(pHit))
		{
			BIT_ADD(bitsVictims, BIT(pHit));

		}
	}

	free_tr2(pTrace);
	return bitsHitResult;
}

stock UTIL_FakeTraceAttack(const pVictim, const pItem, const pPlayer, Float: flDamage, Float: vecDirection[3], const pTrace, bitsDamageType, Float: flKnockBack, Float: flKnockUp )
{
    if(pev_valid(pVictim) != 2) return false;
    if(!is_user_connected(pVictim)) {
        new cls[32];pev(pVictim,pev_classname,cls,charsmax(cls));
        if(!equal(cls,"func_breakable") && !equal(cls,"func_pushable") && !equal(cls,"hostage_entity"))return false;
        ExecuteHamB(Ham_TakeDamage,pVictim,pItem,pPlayer,flDamage,bitsDamageType);return true;
    }
    if(!is_user_alive(pVictim)||!IsEnemy(pVictim,pPlayer))return false;
    if(pev(pVictim, pev_takedamage) == DAMAGE_NO)
        return false;

    if(is_user_alive(pVictim))
    {
        if(!IsEnemy(pVictim, pPlayer))
            return false;
    }

    if(IsEnemy(pVictim, pPlayer))
		UTIL_PlayerKnockBack(pVictim, pPlayer, flKnockBack, flKnockUp);

    new Float: vecPunchAngle[3];
    static Float: vecEnd[3]; get_tr2(pTrace, TR_vecEndPos, vecEnd);
    static iHitGroup; iHitGroup = get_tr2(pTrace, TR_iHitgroup);

    switch(iHitGroup)
    {
        case HIT_HEAD:
        {
            flDamage *= 4.0;
            vecPunchAngle[0] = floatmax(flDamage * -0.5, -12.0);
            vecPunchAngle[2] = floatclamp(flDamage * random_float(-1.0, 1.0), -9.0, 9.0);
        }
        case HIT_CHEST:
        {
            flDamage *= 1.25;
            vecPunchAngle[0] = floatmax(flDamage * -0.1, -4.0);
        }
        case HIT_STOMACH:
        {
            flDamage *= 1.0;
            vecPunchAngle[0] = floatmax(flDamage * -0.1, -4.0);
        }
        case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
        case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
    }

    if(xs_vec_len(vecPunchAngle))
        set_pev(pVictim, pev_punchangle, vecPunchAngle);

    set_pdata_int(pVictim, m_LastHitGroup, iHitGroup, linux_diff_player);

    ExecuteHamB(Ham_TakeDamage, pVictim, pItem, pPlayer, flDamage, bitsDamageType) 


    UTIL_TE_BLOODSPRITE(MSG_PVS, vecEnd, ExecuteHamB(Ham_BloodColor, pVictim), floatround(flDamage));
    ExecuteHamB(Ham_TraceBleed, pVictim, flDamage, vecDirection, pTrace, bitsDamageType);

    return true;
}

stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, Float: flKnockBack, Float: flKnockUp = 0.0, Float: flVelocityModifier = 1.0 )     // 3ihcsWex
{
    if( flKnockBack == 0.0 ) return;

    new Float: vecOrigin[3];         pev( pVictim,   pev_origin,   vecOrigin         );
    new Float: vecVelocity[3];       pev( pVictim,   pev_velocity, vecVelocity       );
    new Float: vecAttackerOrigin[3]; pev( pAttacker, pev_origin,   vecAttackerOrigin );
    new Float: vecDirection[3];      xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
    new Float: flLen = xs_vec_len_2d( vecDirection );

    // Avoid division by zero / invalid velocity when attacker and victim overlap.
    if( flLen > 0.001 )
    {
        for( new i = 0; i < 2; ++i )
            vecVelocity[i] = ( vecDirection[i] / flLen ) * flKnockBack;
    }

    if( flKnockUp > 0.0 )
        vecVelocity[2] = flKnockUp;

    set_pev( pVictim, pev_velocity, vecVelocity );

    if( flVelocityModifier )
        set_pdata_float( pVictim, m_flVelocityModifier, flVelocityModifier, linux_diff_player );
}

stock UTIL_TE_BLOODSPRITE(const iDest, Float: vecOrigin[3], const iColor, iAmount)      // 3IhcsWex
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_BLOODSPRITE

	if(iColor == DONT_BLEED || !iAmount)
		return;

	iAmount = clamp(iAmount * 2, 1, 255);

	message_begin_f(iDest, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BLOODSPRITE);
	write_coord_f(vecOrigin[0]); // X
	write_coord_f(vecOrigin[1]); // Y
	write_coord_f(vecOrigin[2]); // Z
	write_short(gl_iszModelIndex_BloodSpray); // Sprite
	write_short(gl_iszModelIndex_BloodDrop); // Sprite
	write_byte(iColor); // Color
	write_byte(clamp(iAmount / 10, 3, 16)); // Amount
	message_end();
}


stock UTIL_RadiusDamage( pAttacker, const Float: origin[3], Float: flRadius, Float: flDamage, Float:flKnockBack, Float:flKnockUp )  // ~x3 Arabas Pookie <3 Shooting Star "Create_explosion"
{
    new pVictim = FM_NULLENT;
    while( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, origin, flRadius ) ) > 0 )
    {
        if( !IsValidVictim( pVictim, pAttacker ) ) continue;

        ExecuteHamB( Ham_TakeDamage, pVictim, pAttacker, pAttacker, flDamage, DMG_ALWAYSGIB );
        UTIL_PlayerKnockBack(pVictim, pAttacker, flKnockBack, flKnockUp);
    }
}

stock bool: IsValidVictim(pVictim, pAttacker)
{
    return is_user_alive(pVictim) && is_user_alive(pAttacker) && zp_get_user_zombie(pVictim) && !zp_get_user_zombie(pAttacker);
}
public plugin_natives() { register_native("exhero_give_coindart","ExheroGive"); }
public ExheroGive(plugin,params) { return Command_GivePistol(get_param(1)); }

public client_disconnected(id) {
    ExheroCleanup(id); Special_CoinTimerX[id]=0.0; UTIL_KillMuzzleFlash(id); }

stock ExheroCleanup(id) {
    new e;
    e=0; while((e=fm_find_ent_by_owner(e,"ent_coin_projectile",id))>0) set_pev(e,pev_flags,FL_KILLME);
    e=0; while((e=fm_find_ent_by_owner(e,"ent_coin_skill",id))>0) set_pev(e,pev_flags,FL_KILLME);
    e=0; while((e=fm_find_ent_by_owner(e,"exhero_coindart_muzzle",id))>0) set_pev(e,pev_flags,FL_KILLME);
}
public zp_user_infected_pre(id) { ExheroCleanup(id); }

public CoinKilled(id){ExheroCleanup(id);Special_CoinTimerX[id]=0.0;}
