
/*
 * ============================================================================
 *
 *  [CSO] GenoCider VI
 *
 *  Copyright (C) 2025 StarGamerz. All Rights Reserved.
 *  This file is part of a PRIVATE PRODUCTION by StarGamerz.
 *
 *  Unauthorized copying, distribution, modification, or use of this file,
 *  via any medium, is strictly prohibited without the express written
 *  permission of StarGamers. in order to share plugin , share discord ;- https://discord.gg/mEzeYafgXu
 *
 *   SOME FUNCTIONS, CREDITS;- Arabas ( M3 BLACK DRAGON ) , eziekel | noFame ( M3 AZHI DAHAKA )
 * ============================================================================
 */
 
#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >
#include <zombieplague>

#define PLUGIN 		"GenoCider VI"   	                    // Custom Weapon Template
#define VERSION 	"1.2"					                // Version
#define AUTHOR 		"BadKEk ~x3 Elite Class BoSs BadBoy:@"  // Authors    


/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel     // [ xUnicorn ]


/* ~ [ Weapon Resources ] ~ */
new const WEAPON_MODEL_VIEW[] = "models/g3bmodel/ZTHEX/genocider/v_satellitemgex.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/genocider/p_satellitemgex.mdl";
new const WEAPON_MODEL_WORLD[] = "models/genocider/w_satellitemgex.mdl";

new const WEAPON_REFERENCE[] = "weapon_famas";
const WEAPON_SPECIAL_CODE = 21321321;

const WEAPON_BPAMMO = 300;
const WEAPON_AMMO = 100;

/* ~ [ Weapon Primary Attack ] ~ */
const Float: WEAPON_SHOOT_RATE = 0.13;
const Float: WEAPON_PUNCHANGLE = 1.0;
const Float: WEAPON_SHOOT_DAMAGE = 0.8;

/* ~ [ Weapon Muzzleflash ] ~ */
#define CUSTOM_MUZZLEFLASH_ENABLED

#if defined CUSTOM_MUZZLEFLASH_ENABLED
    new const ENTITY_MUZZLE_CLASSNAME[] = "ent_genocider_muzz";
    new const ENTITY_MUZZLE_SPRITE[] = "sprites/genocider/muzzleflash433.spr";
    new const ENTITY_MUZZLE_SPRITE_B[] = "sprites/genocider/muzzleflash434.spr";

    const Float: ENTITY_MUZZLE_NEXTTHINK = 0.067;
#endif

/* ~ [ Animations Settings ] ~ */
const Float: WEAPON_ANIM_IDLE_TIME = 4.03;
const Float: WEAPON_ANIM_RELOAD_TIME = 2.50;
const Float: WEAPON_ANIM_DRAW_TIME = 1.03;
const Float: WEAPON_ANIM_SHOOT_TIME = 1.03;

enum _: iWeaponAnims
{
    WEAPON_ANIM_IDLE = 0,
    WEAPON_ANIM_SHOOT,
    WEAPON_ANIM_SHOOT2,
    WEAPON_ANIM_DRAW,
    WEAPON_ANIM_RELOAD,
    WEAPON_ANIM_SHOOT_B,
}

/* ~ [ Weapon List ] ~ */
new const WEAPON_WEAPONLIST[] = "genocider/weapon_satellitemgex";
new const iWeaponList[] = { 4, 90, -1, -1, 0, 18, CSW_FAMAS, 0 };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump

/* ~ [ Definitions ] ~ */
#define IsCustomWeapon(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsPdataSafe(%0) (pev_valid(%0) == 2)

/* ~ [ Special Ammo ] ~ */
#define m_iGenociderBulletsCount              m_iGlock18ShotsFired
#define pev_special_ammo            pev_gaitsequence
const SPECIAL_AMMO_MAX              = 100;

new Float: g_flEnergyAmmoTimerx[33];



/* ~ [ Hud Configurations ] ~ */        // ~x3 Arabas Shooting Star <3
#define HIDEHUD_NONE        ( 1 << 7 )
#define SET_CUSTOM_HUD      ( HIDEHUD_MONEY )
#define RESET_HUD           ( HIDEHUD_NONE )

new gl_iMsgID_HideWeapon;

/* ~ [ Charges / Counting ] ~ */
#define set_chargeCount(%0,%1)  set_pdata_int( %0, m_iGenociderBulletsCount, %1, linux_diff_weapon )
#define get_chargeCount(%0)     get_pdata_int( %0, m_iGenociderBulletsCount, linux_diff_weapon )

#define set_lastShotTime(%0,%1) set_pev( %0, pev_fuser1, %1 )
#define get_lastShotTime(%0,%1) pev( %0, pev_fuser1, %1 )

new const BulletEffects[][] =  
{
	"sprites/genocider/ef_satellitemg_shoot01.spr",
	"sprites/genocider/ef_satellitemg_shoot02.spr",
	"sprites/genocider/ef_satellitemg_shoot03.spr",
    "sprites/genocider/ef_satellitemg_tailhit.spr"
};

/* ~ [ ENTITY BULLET EXPLOSION ] ~ */
new const ENTITY_GENOCIDER_BULLET_CLASSNAME[] = "ent_da_bullet_effect";
new const ENTITY_GENOCIDER_BULLET[] = "models/genocider/ef_satellitemg_hitB.mdl"; 
new gl_iszAllocString_GenociderBullet;

/* ~ [ ENTITY BULLET EXPLOSION B ] ~ */
new const ENTITY_GENOCIDER_EFFECT_B_CLASSNAME[] = "ent_da_B_effect";
new const ENTITY_GENOCIDER_EFFECT_B[] = "models/genocider/ef_satellitemg_explosion1.mdl"; 
new gl_iszAllocString_B_Effect;

/* ~ [ ENTITY PROJECTILE ] ~ */
new const ENTITY_PROJECTILE_CLASSNAME[] = "ent_da_projectile";
new const ENTITY_PROJECTILE_MODEL[]   = "models/genocider/ef_satellitemg_tail.mdl";
new gl_iszAllocString_Projectile;


/* ~ [ Sounds ] ~ */
new const WeaponSounds[ ][ ] =
{
	"weapons/satellitemg-1.wav",
	"weapons/satellitemg-1_exp.wav",
	"weapons/satellitemg-2.wav",
    "weapons/satellitemg-2_exp.wav"
};

enum 
{
	Sound_Shoot,
	Sound_Shoot_Exp,
	Sound_ShootB,
    Sound_ShootB_Exp
};


/* ~ [ Offsets ] ~ */
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rpgPlayerItems = 367;
const m_iFOV = 363;
const m_pNext = 42
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_iSecondaryAmmoType = 50;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flVelocityModifier = 108;
const m_flTimeWeaponIdle = 48;
const m_maxFrame = 35;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_iGlock18ShotsFired          = 70;
const m_rgpPlayerItems_iWeaponBox = 34;
const Weapon_Secondary_Ammo_Index   = 19;


/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,
    gl_iszAllocString_InfoTarget,

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        gl_iszAllocString_MuzzleFlash,
    #endif

    gl_iMsgID_Weaponlist;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    // Fakemeta
    register_forward(FM_UpdateClientData,    "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel,            "FM_Hook_SetModel_Pre",              false);

    // Hamsandwich
    RegisterHam(Ham_Item_Deploy,            WEAPON_REFERENCE,    "CWeapon__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,   WEAPON_REFERENCE,    "CWeapon__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE,    "CWeapon__SecondaryAttack_Pre",  false);
    RegisterHam(Ham_Weapon_Reload,          WEAPON_REFERENCE,	 "CWeapon__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,         WEAPON_REFERENCE,	 "CWeapon__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,           WEAPON_REFERENCE,	 "CWeapon__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,       WEAPON_REFERENCE,    "CWeapon__AddToPlayer_Post",      true);
    RegisterHam(Ham_Weapon_WeaponIdle,      WEAPON_REFERENCE,    "CWeapon__Idle_Pre",             false);

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,    "func_breakable",    "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",	     "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",            "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",    "CEntity__TraceAttack_Pre",  false);

    // Entity
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);
    #endif
    RegisterHam(Ham_Think,                  "info_target",      "CGenociderEffect__Think_Pre", false);
    RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre",          false);



    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
    gl_iszAllocString_InfoTarget  = engfunc(EngFunc_AllocString, "info_target");

    gl_iszAllocString_GenociderBullet = engfunc(EngFunc_AllocString, ENTITY_GENOCIDER_BULLET_CLASSNAME);
    gl_iszAllocString_Projectile        = engfunc(EngFunc_AllocString, ENTITY_PROJECTILE_CLASSNAME);
    gl_iszAllocString_B_Effect = engfunc(EngFunc_AllocString, ENTITY_GENOCIDER_EFFECT_B_CLASSNAME);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        gl_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
    #endif

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
    gl_iMsgID_HideWeapon = get_user_msgid( "HideWeapon" );

    // Ham Hook
    fm_ham_hook(false);

    // Commands
    RegisterHam(Ham_Killed,"player","GenoKilled",1);
}

public plugin_precache()
{
    precache_generic("sound/weapons/satellitemg_draw.wav");
    precache_generic("sound/weapons/satellitemg_reload.wav");
    precache_generic("sound/weapons/satellitemg_shootB.wav");

    // Precache Models
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
    engfunc(EngFunc_PrecacheModel, ENTITY_GENOCIDER_BULLET);
    engfunc(EngFunc_PrecacheModel, ENTITY_PROJECTILE_MODEL);
    engfunc(EngFunc_PrecacheModel, ENTITY_GENOCIDER_EFFECT_B);


    // Precache Sprites
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);
        engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE_B);
    #endif

    for(new i = 0; i < sizeof(BulletEffects); i++) 
        engfunc(EngFunc_PrecacheModel, BulletEffects[i]);

    // Precache Sounds
    for (new i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

    #if defined PrecacheSoundsFromModel
	    UTIL_PrecacheSoundsFromModel( WEAPON_MODEL_VIEW );
    #endif


    // Precache generic
    UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST)

    // Hook weapon
    register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");
}

/* ~ [ Commands ] ~ */
public Command_HookWeapon(pPlayer)
{
    engclient_cmd(pPlayer, WEAPON_REFERENCE);
    return PLUGIN_HANDLED;
}

public Command_GiveWeapon(pPlayer)
{
 if(!is_user_alive(pPlayer)||zp_get_user_zombie(pPlayer))return 0;
    static pItem; pItem = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsPdataSafe(pItem)) return PLUGIN_HANDLED;

    set_pev(pItem, pev_impulse, WEAPON_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, pItem);
    set_pdata_int(pItem, m_iClip, WEAPON_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(pPlayer, ExecuteHamB(Ham_Item_ItemSlot, pItem));

    if(!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pItem))
    {
        set_pev(pItem, pev_flags, pev(pItem, pev_flags) | FL_KILLME);
        return PLUGIN_HANDLED;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, pItem, pPlayer);
    UTIL_WeaponList(pPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
    set_pdata_int(pPlayer, iAmmoType, WEAPON_BPAMMO, linux_diff_player);

    emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return PLUGIN_HANDLED;
}

/* ~ [ Hamsandwich ] ~ */
public CWeapon__Deploy_Post(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    set_pev_string(pPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(pPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_DRAW);

    Show_MoneyHud(pPlayer);

    Player_SetNextAttack(pPlayer, 0.5);
    Weapon_SetTimeWeaponIdle(pItem, WEAPON_ANIM_DRAW_TIME);
 
}

public CWeapon__PrimaryAttack_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        set_pdata_float(pItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

        return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
    fm_ham_hook(true);		

    ExecuteHam(Ham_Weapon_PrimaryAttack, pItem);
		
    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
    fm_ham_hook(false);

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    Weapon_DoRecoil( pPlayer, WEAPON_PUNCHANGLE * 0.67 )

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SHOOT);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITE, 0.067, 100.0, 1);
    #endif

    emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    Weapon_SetAllTimers( pItem, pPlayer, WEAPON_SHOOT_RATE, WEAPON_SHOOT_RATE, WEAPON_ANIM_SHOOT_TIME, WEAPON_SHOOT_RATE )

    set_chargeCount(pItem, get_chargeCount(pItem) + 1);
    set_lastShotTime(pItem, get_gametime());

    return HAM_SUPERCEDE;
}


public CWeapon__SecondaryAttack_Pre( pItem )
{
    if( !IsPdataSafe( pItem ) || !IsCustomWeapon( pItem ) ) return HAM_IGNORED;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    static iSpeicalAmmo; iSpeicalAmmo = Weapon_GetSpecialAmmo( pItem );

    if(iSpeicalAmmo >  29)
    {
        Weapon_SetSpecialAmmo(pItem, pPlayer, iSpeicalAmmo - 30 );
        Cweapon_CreateProjectile(pPlayer);
        Create_Special_B_Effect(pPlayer, 1000.0);
        UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SHOOT_B)

        emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[Sound_ShootB], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        #if defined CUSTOM_MUZZLEFLASH_ENABLED
            new pMuzzleFlash = FM_NULLENT;

            while((pMuzzleFlash = fm_find_ent_by_owner(pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, pPlayer)) > 0)
            if(IsPdataSafe(pMuzzleFlash)) set_pev(pMuzzleFlash, pev_flags, FL_KILLME);
        #endif
    }
    else if(29 > iSpeicalAmmo)
    {
        client_print(pPlayer, print_center, "No Energy")
        Weapon_SetNextSecondaryAttack(pItem, 0.5);
    }


    Weapon_SetAllTimers( pItem, pPlayer, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME )
    

    return HAM_SUPERCEDE;
}

public CWeapon__Reload_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
    if(iAmmo >= WEAPON_AMMO) return HAM_SUPERCEDE;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    if(!is_user_alive(pPlayer)||Weapon_GetReload(pItem)||get_pdata_float(pPlayer,m_flNextAttack,linux_diff_player)>0.0)return HAM_SUPERCEDE;
    new iSavedClip = Weapon_GetClip(pItem);
    Weapon_SetClip(pItem, 0);
    ExecuteHam(Ham_Weapon_Reload, pItem);
    Weapon_SetClip(pItem, iSavedClip);
    Weapon_SetReload(pItem, 1);

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_RELOAD);

    Weapon_SetAllTimers( pItem, pPlayer, WEAPON_ANIM_RELOAD_TIME, WEAPON_ANIM_RELOAD_TIME, WEAPON_ANIM_RELOAD_TIME, WEAPON_ANIM_RELOAD_TIME )

    return HAM_SUPERCEDE;
}

public CWeapon__PostFrame_Pre(pItem)
{ 
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    static Float: flGameTime; flGameTime = get_gametime();

    new iSpeicalAmmo = Weapon_GetSpecialAmmo(pItem);
    if(iSpeicalAmmo < SPECIAL_AMMO_MAX)
    {
        if(g_flEnergyAmmoTimerx[pPlayer] == 0.0)
        {
            g_flEnergyAmmoTimerx[pPlayer] = flGameTime + 0.23;
        }
        else if(flGameTime >= g_flEnergyAmmoTimerx[pPlayer])
        {
            Weapon_SetSpecialAmmo(pItem, pPlayer, ++iSpeicalAmmo);
            g_flEnergyAmmoTimerx[pPlayer] = (iSpeicalAmmo < SPECIAL_AMMO_MAX) ? flGameTime + 0.23 : 0.0;
        }
    }
    else
    {
        g_flEnergyAmmoTimerx[pPlayer] = 0.0;
    }

    new iCount = get_chargeCount(pItem);
    if(iCount > 0)
    {
        new Float: flLastShot;
        get_lastShotTime(pItem, flLastShot);

        if(flGameTime - flLastShot > WEAPON_SHOOT_RATE + 0.05)
        {

            if(iCount > 8)
            {
                new Float: vecOrigin[3];    
                fm_get_aim_origin( pPlayer, vecOrigin );

                CWeapon__Create_GenociderEffect(pPlayer, vecOrigin);

                emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[Sound_Shoot_Exp], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                EmitSound_FromPos(vecOrigin, WeaponSounds[Sound_Shoot_Exp]);                        // Don't Tell me bro 🥀


                if(iCount >= 30)
                {
                    UTIL_RadiusDamage(pPlayer, vecOrigin, 110.0, 900.0);
                }
                else if(iCount >= 20)
                {
                    UTIL_RadiusDamage(pPlayer, vecOrigin, 110.0, 600.0);
                }
                else if(iCount >= 10)
                {
                    UTIL_RadiusDamage(pPlayer, vecOrigin, 110.0, 300.0);
                }

            }
        
            set_chargeCount(pItem, 0);
            set_lastShotTime(pItem, 0.0);
        }
    }

    if(Weapon_GetReload(pItem) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
        new iClip = Weapon_GetClip(pItem);
        new iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);
        new j = min(WEAPON_AMMO - iClip, iAmmo);

        Weapon_SetClip(pItem, iClip + j);
        set_pdata_int(pPlayer, iAmmoType, iAmmo - j, linux_diff_player);
        Weapon_SetReload(pItem, 0);
    }

    return HAM_IGNORED;
}

public CWeapon__Holster_Post(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    Weapon_SetAllTimers( pItem, pPlayer, 0.0, 0.0, 0.0, 0.0 )

    Show_MoneyHud(pPlayer);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
        new pMuzzleFlash = FM_NULLENT;

        while((pMuzzleFlash = fm_find_ent_by_owner(pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, pPlayer)) > 0)
        if(IsPdataSafe(pMuzzleFlash)) set_pev(pMuzzleFlash, pev_flags, FL_KILLME);
    #endif
}

public CEntity__TraceAttack_Pre(pVictim, pAttacker, Float: flDamage)
{
    if(!is_user_alive(pAttacker)||zp_get_user_zombie(pAttacker))return;
    if(is_user_connected(pVictim)&&!zp_get_user_zombie(pVictim)){SetHamParamFloat(3,0.0);return;}
	
    static pItem; pItem = get_pdata_cbase(pAttacker, 373, 5);
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    flDamage *= WEAPON_SHOOT_DAMAGE

    new iCount = get_chargeCount(pItem);

    if(iCount >= 30)
    {
        flDamage *= 1.1
    }
    else if(iCount >= 20)
    {
        flDamage *= 1.2
    }
    else if(iCount >= 10)
    {
        flDamage *= 1.3
    }

    SetHamParamFloat(3, flDamage);
}

public CWeapon__AddToPlayer_Post( pItem, pPlayer )
{
    if( IsPdataSafe( pItem ) && IsCustomWeapon( pItem ) )
    {
        if( pev( pItem, pev_owner ) <= 0 )
        {
            set_pdata_int( pItem, m_iSecondaryAmmoType, Weapon_Secondary_Ammo_Index, linux_diff_weapon );
            set_pev( pItem, pev_special_ammo, 0 );
        }

        Weapon_SetSpecialAmmo( pItem, pPlayer, Weapon_GetSpecialAmmo( pItem ) );
        UTIL_WeaponList( pPlayer, true );
    }
    else if( !IsCustomWeapon( pItem ) )
    {
        UTIL_WeaponList( pPlayer, false );
    }
}

public CWeapon__Idle_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem) || get_pdata_float(pItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_IDLE);
    Weapon_SetTimeWeaponIdle( pItem, WEAPON_ANIM_IDLE_TIME );

    return HAM_SUPERCEDE;
}

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

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(pPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(pPlayer)) return;

    static pItem; pItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(pEntity)
{
    static i, szClassName[32], pItem;
    pev(pEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        pItem = get_pdata_cbase(pEntity, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
        if(IsPdataSafe(pItem) && IsCustomWeapon(pItem))
        {
            engfunc(EngFunc_SetModel, pEntity, WEAPON_MODEL_WORLD);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, pAttacker, iTrace)
{
    if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(pAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

    static pItem; pItem = get_pdata_cbase(pAttacker, m_pActiveItem, linux_diff_player);
    new iCount = get_chargeCount(pItem);

    if(iCount <= 8)
    {
        UTIL_WorldDecal( vecEndPos, random_num( 41, 45 ) );
        UTIL_StreakSplash( vecEndPos, 5, 70, 3, 75 );
    }


    new Float: vecAimOrigin[3];    
    fm_get_aim_origin( pAttacker, vecAimOrigin );

    if(iCount >= 30)
    {
        UTIL_Explosion(vecAimOrigin, 0.0, engfunc(EngFunc_ModelIndex, BulletEffects[2]), 3, 25, 2|4|8);
        UTIL_RadiusDamage(pAttacker, vecAimOrigin, 30.0, 60.0);
    }
    else if(iCount >= 20)
    {
        UTIL_Explosion(vecAimOrigin, 0.0, engfunc(EngFunc_ModelIndex, BulletEffects[1]), 2, 25, 2|4|8);
        UTIL_RadiusDamage(pAttacker, vecAimOrigin, 25.0, 40.0);
    }
    else if(iCount >= 10)
    {
        UTIL_Explosion(vecAimOrigin, 0.0, engfunc(EngFunc_ModelIndex, BulletEffects[0]), 1, 25, 2|4|8);
        UTIL_RadiusDamage(pAttacker, vecAimOrigin, 20.0, 20.0);
    }

    return FMRES_IGNORED;
}

/* ~ [ Entity ] ~ */
#if defined CUSTOM_MUZZLEFLASH_ENABLED
    public CMuzzleFlash__Think_Pre(iSprite)
    {
        if(!IsPdataSafe(iSprite)) return HAM_IGNORED;
        if(pev(iSprite, pev_classname) == gl_iszAllocString_MuzzleFlash)
        {
            static Float: flFrame;
            if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
            {
                set_pev(iSprite, pev_frame, flFrame);
                set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_NEXTTHINK);
                    
                return HAM_SUPERCEDE;
            }

            set_pev(iSprite, pev_flags, FL_KILLME);
            return HAM_SUPERCEDE;
        }

        return HAM_IGNORED;
    }
#endif

public CGenociderEffect__Think_Pre(pEntity)
{
    if(!IsPdataSafe(pEntity)) return HAM_IGNORED;

    new cls=pev(pEntity,pev_classname);
    if(cls!=gl_iszAllocString_GenociderBullet&&cls!=gl_iszAllocString_B_Effect&&cls!=gl_iszAllocString_Projectile)return HAM_IGNORED;
    new owner=pev(pEntity,pev_owner);
    if((pev(pEntity,pev_flags)&FL_KILLME)||!is_user_alive(owner)||zp_get_user_zombie(owner)){set_pev(pEntity,pev_flags,pev(pEntity,pev_flags)|FL_KILLME);return HAM_SUPERCEDE;}
    static iClassname; iClassname = pev( pEntity, pev_classname );
    static Float: flGameTime; flGameTime = get_gametime();
    static Float: flLifeTime; pev(pEntity, pev_ltime, flLifeTime);
    new iSkin = pev( pEntity, pev_skin ) + 1;

    if(iClassname == gl_iszAllocString_GenociderBullet)
    {
        if( iSkin >= 32 )
        {
            set_pev( pEntity, pev_flags, FL_KILLME );
            return HAM_SUPERCEDE;
        }

        set_pev( pEntity, pev_skin, iSkin );

        if(flGameTime >= flLifeTime)
        {
            set_pev(pEntity, pev_flags, FL_KILLME);
            return HAM_SUPERCEDE;
        }

        set_pev(pEntity, pev_nextthink, flGameTime + 0.06);
    }

    if(iClassname == gl_iszAllocString_B_Effect)
    {
        if(flGameTime >= flLifeTime || iSkin >= 27)
        {
            set_pev(pEntity,pev_flags,pev(pEntity,pev_flags)|FL_KILLME);
            new iVictim   = pev(pEntity, pev_euser1);
            new iHitsLeft = pev(pEntity, pev_iuser1);
            new pOwner    = pev(pEntity, pev_owner);

            if(iHitsLeft > 0 && IsValidVictim(iVictim,pOwner))
            {
                new Float: vecOrigin[3]; pev(pEntity, pev_origin, vecOrigin);

                ExecuteHamB(Ham_TakeDamage, iVictim, pOwner, pOwner, 40.0, DMG_ALWAYSGIB);

                emit_sound(pOwner, CHAN_WEAPON, WeaponSounds[Sound_ShootB_Exp], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                EmitSound_FromPos(vecOrigin, WeaponSounds[Sound_ShootB_Exp]);

                Cweapon__CreateEffect_B(pOwner, iVictim, iHitsLeft - 1);
            }

            set_pev(pEntity, pev_flags, FL_KILLME);
            return HAM_SUPERCEDE;
        }

        set_pev(pEntity, pev_skin, iSkin);

        if(iSkin >= 17)
            set_pev(pEntity, pev_nextthink, flGameTime + 0.034);            // yea bro it's heaver then prethink 🥀
        else
            set_pev(pEntity, pev_nextthink, flGameTime + 0.067);            // 6 7 🥀

        return HAM_SUPERCEDE;
    }
    if(iClassname == gl_iszAllocString_Projectile)
    {
        set_pev(pEntity, pev_flags, FL_KILLME);
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public CEntity__Touch_Pre(pEntity, pTouch)
{
    if(!IsPdataSafe(pEntity)) return HAM_IGNORED;

    new cls=pev(pEntity,pev_classname);
    if(cls!=gl_iszAllocString_GenociderBullet&&cls!=gl_iszAllocString_B_Effect&&cls!=gl_iszAllocString_Projectile)return HAM_IGNORED;
    new owner=pev(pEntity,pev_owner);
    if((pev(pEntity,pev_flags)&FL_KILLME)||!is_user_alive(owner)||zp_get_user_zombie(owner)){set_pev(pEntity,pev_flags,pev(pEntity,pev_flags)|FL_KILLME);return HAM_SUPERCEDE;}
    static iClassname; iClassname = pev(pEntity, pev_classname);

    if(iClassname == gl_iszAllocString_Projectile)
    {
        new Float: vecOrigin[3]; pev(pEntity, pev_origin, vecOrigin);

        if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
        {
            set_pev(pEntity, pev_flags, FL_KILLME);
            return HAM_IGNORED;
        }

        if(!is_user_alive(pTouch)) return HAM_SUPERCEDE;

        new pOwner = pev(pEntity, pev_owner);

        if(!IsValidVictim(pTouch,pOwner))return HAM_SUPERCEDE;
        set_pev(pEntity,pev_flags,pev(pEntity,pev_flags)|FL_KILLME);

        UTIL_Explosion(vecOrigin,  47.0, engfunc(EngFunc_ModelIndex, BulletEffects[3]), 10, 30, 2|4|8);     // Agent 47 🕵️‍♀️
        UTIL_RadiusDamage(pOwner, vecOrigin, 30.0, 30.0);

        set_pev(pEntity, pev_flags, FL_KILLME);
    }

    return HAM_IGNORED;
}

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
    set_pev(pPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, pPlayer);
    write_byte(iAnim);
    write_byte(0);
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
    set_pdata_int( pPlayer, m_rgAmmo + Weapon_Secondary_Ammo_Index, iAmount, linux_diff_player );
}

stock Weapon_GetSpecialAmmo( pItem )
{
    return pev( pItem, pev_special_ammo );
}

stock Show_MoneyHud( pPlayer )
{
    message_begin( MSG_ONE, gl_iMsgID_HideWeapon, _, pPlayer );
    write_byte( RESET_HUD );
    message_end();
}

stock Hide_MoneyHud( pPlayer )
{
    message_begin( MSG_ONE, gl_iMsgID_HideWeapon, _, pPlayer );
    write_byte( SET_CUSTOM_HUD );
    message_end();
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


#if defined CUSTOM_MUZZLEFLASH_ENABLED
    stock UTIL_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
    {
        set_pev(iSprite, pev_rendermode, iRendermode);
        set_pev(iSprite, pev_renderamt, flAmt);
        set_pev(iSprite, pev_renderfx, iFx);
    }

    stock UTIL_CreateMuzzleFlash(pPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment)
    {
        #define ENTITY_SPRITES_INTOLERANCE 100
        if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
            
        static iSprite, iszAllocStringCached;
        if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
        iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
            
        if(!IsPdataSafe(iSprite)) return FM_NULLENT;
            
        set_pev(iSprite, pev_model, szMuzzleSprite);
        set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
            
        set_pev_string(iSprite, pev_classname, gl_iszAllocString_MuzzleFlash);
        set_pev(iSprite, pev_owner, pPlayer);
        set_pev(iSprite, pev_aiment, pPlayer);
        set_pev(iSprite, pev_body, iAttachment);
            
        UTIL_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
        set_pev(iSprite, pev_scale, flScale);
            
        dllfunc(DLLFunc_Spawn, iSprite);

        return iSprite;
    }
#endif

stock UTIL_WeaponList(const pPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, pPlayer);
    write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
    write_byte(iWeaponList[0]);
    write_byte(bEnabled ? WEAPON_AMMO        : iWeaponList[1]);
    write_byte(bEnabled ? Weapon_Secondary_Ammo_Index : -1);
    write_byte(bEnabled ? SPECIAL_AMMO_MAX   : -1);
    write_byte(iWeaponList[4]);
    write_byte(iWeaponList[5]);
    write_byte(iWeaponList[6]);
    write_byte(iWeaponList[7]);
    message_end();
}

stock UTIL_PrecacheSpritesFromTxt( const szWeaponList[] )
{
	new szTxtDir[64], szSprDir[64]; 
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if(!strlen(szFileData)) 
			continue;

		new pos = containi(szFileData, "640");	
			
		if(pos == -1)
			continue;
			
		format(szFileData, charsmax(szFileData), "%s", szFileData[pos+3]);		
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);
		
		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}
	if(iFile) fclose(iFile);
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

stock CWeapon__Create_GenociderEffect(pPlayer, const Float: vecOrigin[3])
{
    if(!is_user_alive(pPlayer)) return FM_NULLENT;

    static Float: flGameTime; flGameTime = get_gametime();

    new Float: vecEnd[3], Float: vecGround[3];
    vecEnd[0] = vecOrigin[0];
    vecEnd[1] = vecOrigin[1];
    vecEnd[2] = vecOrigin[2] - 9999.0;

    new iTrace = create_tr2();
    engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, IGNORE_MONSTERS, pPlayer, iTrace);
    get_tr2(iTrace, TR_vecEndPos, vecGround);
    free_tr2(iTrace);

    vecGround[2] += 3.0;

    new pEntity = UTIL_CreateEntity( gl_iszAllocString_GenociderBullet, ENTITY_GENOCIDER_BULLET, vecGround, Float:{-16.0, -16.0, -16.0}, Float:{ 16.0,  16.0,  16.0}, MOVETYPE_NONE, SOLID_NOT );

    if(!pEntity) return 0;

    new Float: vecAngles[ 3 ];
    pev( pPlayer, pev_angles, vecAngles );
    vecAngles[ 0 ] = 0.0;          
    vecAngles[ 1 ] += 90.0;       
    if( vecAngles[ 1 ] > 360.0 )   vecAngles[ 1 ] -= 360.0;
                

    set_pev( pEntity, pev_angles,    vecAngles           );

    set_pev(pEntity, pev_owner,     pPlayer           );
    set_pev(pEntity, pev_ltime,     flGameTime + 2.03 );
    set_pev(pEntity, pev_nextthink, flGameTime + 0.1  );
    set_pev(pEntity, pev_skin,      0                 );

    UTIL_SetEntityAnim(pEntity, 0);

    return pEntity;
}

stock Cweapon_CreateProjectile(pPlayer)
{
    if(!is_user_alive(pPlayer)) return FM_NULLENT;

    static Float: flGameTime; flGameTime = get_gametime();

    new Float: vecOrigin[3];
    UTIL_GetBarrelPosition(pPlayer, vecOrigin);

    new pEntity = UTIL_CreateEntity(gl_iszAllocString_Projectile, ENTITY_PROJECTILE_MODEL, vecOrigin, Float:{-8.0, -8.0, -8.0}, Float:{8.0, 8.0, 8.0}, MOVETYPE_NOCLIP, SOLID_TRIGGER);

    if(!pEntity) return FM_NULLENT;

    new Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
    pev(pPlayer, pev_v_angle, vAngle);
    engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp);
    xs_vec_normalize(vForward, vForward);

    new Float: vecAngles[3];
    vector_to_angle(vForward, vecAngles);
    set_pev(pEntity, pev_angles, vecAngles);

    new Float: vecVelocity[3];
    velocity_by_aim(pPlayer, 2676, vecVelocity);
    set_pev(pEntity, pev_velocity, vecVelocity);

    set_pev(pEntity, pev_owner,     pPlayer);
    set_pev(pEntity, pev_nextthink, flGameTime + 0.70);

    UTIL_SetEntityAnim(pEntity, 0);

    return pEntity;
}

stock UTIL_RadiusDamage( pAttacker, const Float: origin[3], Float: flRadius, Float: flDamage )  // ~x3 Arabas Pookie <3 Shooting Star "Create_explosion"
{
    new pVictim = FM_NULLENT;
    while( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, origin, flRadius ) ) > 0 )
    {
        if( !IsValidVictim( pVictim, pAttacker ) ) continue;

        ExecuteHamB( Ham_TakeDamage, pVictim, pAttacker, pAttacker, flDamage, DMG_ALWAYSGIB );
    }
}

stock bool: IsValidVictim( pVictim, pAttacker )
{
    if( !is_user_alive( pVictim )                              ) return false;
    if( pVictim == pAttacker                                   ) return false;
    if(!is_user_alive(pAttacker)||zp_get_user_zombie(pAttacker)||!zp_get_user_zombie(pVictim))return false;

    return true;
}

stock Create_Special_B_Effect(const pPlayer, const Float: flRadius)
{
    static iVictim, Float: vecOrigin[3];
    pev(pPlayer, pev_origin, vecOrigin);

    iVictim = FM_NULLENT;
    while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
    {
        if(!IsValidVictim(iVictim, pPlayer)) continue;

        new Float: vecVictimOrigin[3];
        pev(iVictim, pev_origin, vecVictimOrigin);

        new Float: flDist = get_distance_f(vecOrigin, vecVictimOrigin);

        ExecuteHamB(Ham_TakeDamage, iVictim, pPlayer, pPlayer, 20.0, DMG_ALWAYSGIB);

        emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[Sound_ShootB_Exp], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        EmitSound_FromPos(vecVictimOrigin, WeaponSounds[Sound_ShootB_Exp]);

        if(flDist <= 500.0)
            Cweapon__CreateEffect_B(pPlayer, iVictim, 4);
        else
            Cweapon__CreateEffect_B(pPlayer, iVictim, 0);
    }
}

stock Cweapon__CreateEffect_B(pPlayer, iVictim, iHitsLeft)
{
    if(!IsValidVictim(iVictim,pPlayer)) return FM_NULLENT;

    static Float: flGameTime; flGameTime = get_gametime();

    new Float: vecVictimOrigin[3];
    pev(iVictim, pev_origin, vecVictimOrigin);

    new Float: vecEnd[3], Float: vecGround[3];
    vecEnd[0] = vecVictimOrigin[0];
    vecEnd[1] = vecVictimOrigin[1];
    vecEnd[2] = vecVictimOrigin[2] - 9999.0;

    new iTrace = create_tr2();
    engfunc(EngFunc_TraceLine, vecVictimOrigin, vecEnd, IGNORE_MONSTERS, pPlayer, iTrace);
    get_tr2(iTrace, TR_vecEndPos, vecGround);
    free_tr2(iTrace);

    vecGround[2] += 3.0;

    new pEntity = UTIL_CreateEntity(gl_iszAllocString_B_Effect, ENTITY_GENOCIDER_EFFECT_B, vecGround, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0}, MOVETYPE_NONE, SOLID_NOT);

    if(!pEntity) return 0;

    new Float: vecAngles[3];
    pev(pPlayer, pev_angles, vecAngles);
    vecAngles[0] = 0.0;
    vecAngles[1] += 90.0;
    if(vecAngles[1] > 360.0) vecAngles[1] -= 360.0;

    set_pev(pEntity, pev_angles,    vecAngles);
    set_pev(pEntity, pev_owner,     pPlayer);
    set_pev(pEntity, pev_euser1,    iVictim);   
    set_pev(pEntity, pev_iuser1,    iHitsLeft); 
    set_pev(pEntity, pev_ltime,     flGameTime + 2.03);
    set_pev(pEntity, pev_nextthink, flGameTime);
    set_pev(pEntity, pev_skin,      0);

    UTIL_SetEntityAnim(pEntity, 0);

    return pEntity;
}

stock UTIL_CreateEntity( const szClassname, const szModel[], const Float: vecOrigin[ 3 ], const Float: vecMins[ 3 ] = { -1.0, -1.0, -1.0 }, const Float: vecMaxs[ 3 ] = { 1.0, 1.0, 1.0 }, iMoveType = MOVETYPE_FLY, iSolid = SOLID_NOT, Float: flRenderAmt = 255.0, iRenderMode = kRenderTransAdd, iRenderFx = kRenderFxNone )
{
    new pEntity = engfunc( EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget );
    if( !IsPdataSafe( pEntity ) ) return 0;

    set_pev_string( pEntity, pev_classname, szClassname );

    engfunc( EngFunc_SetModel,  pEntity, szModel    );
    engfunc( EngFunc_SetOrigin, pEntity, vecOrigin  );
    engfunc( EngFunc_SetSize,   pEntity, vecMins, vecMaxs );

    set_pev( pEntity, pev_movetype, iMoveType );
    set_pev( pEntity, pev_solid,    iSolid    );

    UTIL_Set_Entity_Transparency( pEntity, flRenderAmt, iRenderMode, iRenderFx );

    return pEntity;
}

stock UTIL_Set_Entity_Transparency( const pEntity, Float: flRenderAmt = 255.0, const iRenderMode = kRenderTransAdd, const iRenderFx = kRenderFxNone )  // 3ihcsWex
{
    set_pev( pEntity, pev_rendermode, iRenderMode );
    set_pev( pEntity, pev_renderamt,  flRenderAmt );
    set_pev( pEntity, pev_renderfx,   iRenderFx   );
}

stock UTIL_SetEntityAnim( pEntity, iSequence )  // xunicorn Dread nova
{
    set_pev( pEntity, pev_frame,     1.0            );
    set_pev( pEntity, pev_framerate, 1.0            );
    set_pev( pEntity, pev_animtime,  get_gametime() );
    set_pev( pEntity, pev_sequence,  iSequence      );
}

stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, Float: flKnockBack, Float: flKnockUp = 0.0, Float: flVelocityModifier = 1.0 )     // 3ihcsWex
{
    if( flKnockBack == 0.0 ) return;

    new Float: vecOrigin[3];         pev( pVictim,   pev_origin,   vecOrigin         );
    new Float: vecVelocity[3];       pev( pVictim,   pev_velocity, vecVelocity       );
    new Float: vecAttackerOrigin[3]; pev( pAttacker, pev_origin,   vecAttackerOrigin );
    new Float: vecDirection[3];      xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
    new Float: flLen = xs_vec_len_2d( vecDirection );

    for( new i = 0; i < 2; ++i )
        vecVelocity[i] = ( vecDirection[i] / flLen ) * flKnockBack;

    if( flKnockUp > 0.0 )
        vecVelocity[2] = flKnockUp;

    set_pev( pVictim, pev_velocity, vecVelocity );

    if( flVelocityModifier )
        set_pdata_float( pVictim, m_flVelocityModifier, flVelocityModifier, linux_diff_player );
}

stock UTIL_GetBarrelPosition(iPlayer, Float:vecOut[3]) // cristian 505
{
    static Float:vecOrigin[3], Float:vecAngles[3];
    static Float:vecForward[3], Float:vecRight[3], Float:vecUp[3];
    static Float:vecViewOfs[3];

    pev(iPlayer, pev_origin, vecOrigin);
    pev(iPlayer, pev_v_angle, vecAngles);
    pev(iPlayer, pev_view_ofs, vecViewOfs);

    engfunc(EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp);

    static const Float:BARREL_FORWARD = 22.0; 
    static const Float:BARREL_RIGHT   = 6.0;  
    static const Float:BARREL_DOWN    = -5.0;  

    vecOut[0] = vecOrigin[0] + vecViewOfs[0] + vecForward[0] * BARREL_FORWARD + vecRight[0] * BARREL_RIGHT + vecUp[0] * BARREL_DOWN;
    vecOut[1] = vecOrigin[1] + vecViewOfs[1] + vecForward[1] * BARREL_FORWARD + vecRight[1] * BARREL_RIGHT + vecUp[1] * BARREL_DOWN;
    vecOut[2] = vecOrigin[2] + vecViewOfs[2] + vecForward[2] * BARREL_FORWARD + vecRight[2] * BARREL_RIGHT + vecUp[2] * BARREL_DOWN;
}


stock UTIL_Explosion(const Float:vecPos[3], Float: flSpriteUp, iSprIdx, iScale, iFps, iFlags)
{
    // https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION#networkmessage-function
    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecPos, 0);
    write_byte(TE_EXPLOSION);
    engfunc(EngFunc_WriteCoord, vecPos[0]);
    engfunc(EngFunc_WriteCoord, vecPos[1]);
    engfunc(EngFunc_WriteCoord, vecPos[2] + flSpriteUp);
    write_short(iSprIdx);
    write_byte(iScale);
    write_byte(iFps);
    write_byte(iFlags);
    message_end();
}

stock UTIL_WorldDecal( const Float: vecPos[ 3 ], iDecal )
{
    // https://github.com/baso88/SC_AngelScript/wiki/TE_WORLDDECAL
    engfunc( EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecPos, 0 );
    write_byte( TE_WORLDDECAL );
    engfunc( EngFunc_WriteCoord, vecPos[ 0 ] );
    engfunc( EngFunc_WriteCoord, vecPos[ 1 ] );
    engfunc( EngFunc_WriteCoord, vecPos[ 2 ] );
    write_byte( iDecal );
    message_end();
}

stock UTIL_StreakSplash( const Float: vecPos[ 3 ], iColor, iCount, iSpeed, iSpeedNoise )
{
    // https://github.com/baso88/SC_AngelScript/wiki/TE_STREAK_SPLASH
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
    write_byte( TE_STREAK_SPLASH );
    engfunc( EngFunc_WriteCoord, vecPos[ 0 ]          );
    engfunc( EngFunc_WriteCoord, vecPos[ 1 ]          );
    engfunc( EngFunc_WriteCoord, vecPos[ 2 ]          );
    write_coord( random_num( -20, 20 ) );
    write_coord( random_num( -20, 20 ) );
    write_coord( random_num( -20, 20 ) );
    write_byte(  iColor      );
    write_short( iCount      );
    write_short( iSpeed      );
    write_short( iSpeedNoise );
    message_end();
}

stock EmitSound_FromPos( const Float: vecOrigin[3], const szSound[], Float: flVol = VOL_NORM, Float: flAttn = ATTN_NORM, iFlags = 0, iPitch = PITCH_NORM )
{
    engfunc( EngFunc_EmitAmbientSound, 0, vecOrigin, szSound, flVol, flAttn, iFlags, iPitch );
}

public plugin_natives(){register_native("exhero_give_genocider","GenoGive");}
public GenoGive(plugin,params){return Command_GiveWeapon(get_param(1));}
public GenoKilled(id){GenoCleanup(id);}
public client_disconnected(id){GenoCleanup(id);}
public zp_user_infected_pre(id){GenoCleanup(id);}
stock GenoCleanup(id){new e;new const classes[][]={"ent_da_bullet_effect","ent_da_B_effect","ent_da_projectile","ent_genocider_muzz"};for(new i=0;i<sizeof classes;i++){e=0;while((e=fm_find_ent_by_owner(e,classes[i],id))>0)set_pev(e,pev_flags,pev(e,pev_flags)|FL_KILLME);}}
