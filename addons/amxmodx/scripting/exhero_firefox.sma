#include <zombieplague>
/*
 * ============================================================================
 *
 *  [CSO] FireFox [ Bison ]
 *
 *  Copyright (C) 2025 StarGamerz. All Rights Reserved.
 *  This file is part of a PRIVATE PRODUCTION by StarGamerz.
 *
 *  Unauthorized copying, distribution, modification, or use of this file,
 *  via any medium, is strictly prohibited without the express written
 *  permission of StarGamers. in order to share plugin , share discord ;- https://discord.gg/mEzeYafgXu
 *
 *   SOME FUNCTIONS, CREDITS;- Arabas ( M3 BLACK DRAGON ) ,xUnicorn 
 * ============================================================================
*/



#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN 		"FireFox [ Bison ]"   	            // Custom Weapon Template
#define VERSION 	"1.2"					            // Version
#define AUTHOR 		"~x3PK PaKiStAn GaMeR X || ~x3Dg HaMdAn || FaXZeEl"   // Authors    

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
*/
#define PrecacheSoundsFromModel     // [ xUnicorn ]

/* ~ [ Weapon Resources ] ~ */
new const WEAPON_MODEL_VIEW[] = "models/g3bmodel/ZTHEX/firefox/v_bisonfox.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/firefox/p_bisonfox.mdl";
new const WEAPON_MODEL_WORLD[] = "models/firefox/w_bisonfox.mdl";

new const WEAPON_REFERENCE[] = "weapon_p90";
const WEAPON_SPECIAL_CODE = 908773;

const WEAPON_BPAMMO = 6767;
const WEAPON_AMMO = 67;

/* ~ [ Weapon Primary Attack ] ~ */
const Float: WEAPON_SHOOT_RATE = 0.13;
const Float: WEAPON_PUNCHANGLE = 1.0;
const Float: WEAPON_SHOOT_DAMAGE = 2.1;

/* ~ [ Weapon Muzzleflash ] ~ */
#define CUSTOM_MUZZLEFLASH_ENABLED
#define ENTITY_SPRITES_INTOLERANCE 100

#if defined CUSTOM_MUZZLEFLASH_ENABLED
new const ENTITY_MUZZLE_CLASSNAME[] = "ent_bison_muzz";
new const ENTITY_MUZZLE_SPRITE[] = "sprites/firefox/muzzleflash420.spr";
new const ENTITY_MUZZLE_SPRITE_B[] = "sprites/firefox/muzzleflash422.spr";

const Float: ENTITY_MUZZLE_NEXTTHINK = 0.07;
const Float: ENTITY_MUZZLE_IDLE_NEXTTHINK = 0.04;
#endif

// new const ENTITY_MUZZLE_IDLE_CLASSNAME[] = "ent_bison_idle_spr";
// new const ENTITY_MUZZLE_SPRITE_FIREBALL[] = "sprites/firefox/ef_bisonfox_fireball.spr";
// new const ENTITY_MUZZLE_SPRITE_TAIL[] = "sprites/firefox/ef_bisonfox_tail.spr";


/* ~ [ Animations Settings ] ~ */
const Float: WEAPON_ANIM_IDLE_TIME = 3.03;
const Float: WEAPON_ANIM_RELOAD_TIME = 2.53;
const Float: WEAPON_ANIM_DRAW_TIME = 1.03;
const Float: WEAPON_ANIM_SHOOT_TIME = 0.87;

enum _: iWeaponAnims
{
    WEAPON_ANIM_IDLE = 0,
    WEAPON_ANIM_RELOAD,
    WEAPON_ANIM_DRAW,
    WEAPON_ANIM_SHOOT,
    WEAPON_ANIM_SHOOT_B = 5

}

/* ~ [ Weapon List ] ~ */
new const WEAPON_WEAPONLIST[] = "firefox/weapon_bisonfox";
new const iWeaponList[] = 
{ 
    7, 100, -1, -1, 0, 8, CSW_P90, 0 
};
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
 


/* ~ [ ENTITY BISON EFFECT ] ~ */
new const ENTITY_BISON_EFFECT_CLASSNAME[] = "ent_bison_effect";
new const ENTITY_BISON_EFFECT[] = "models/firefox/ef_bisonfox_hitfx.mdl"; 
new gl_iszAllocString_Bisoneffect;


/* ~ [ ENTITY BISON PROJECTILE ] ~ */
new const ENTITY_BISON_PROJECTILE_CLASSNAME[] = "ent_bison_projectile";
new const ENTITY_BISON_PROJECTILE[] = "models/firefox/ef_bisonfox_missile.mdl"; 
new gl_iszAllocString_BisonProjectile;

/**
 * Pakistan Gamer X Help
 * 
 * SOME PROJECTILE FUNCTIONS
*/
enum _: iProjectileState
{
    PROJECTILE_STATE_BOUNCE = 0,
    PROJECTILE_STATE_HOMING
};

const Float: PROJECTILE_SCAN_RADIUS    = 250.0;
const Float: PROJECTILE_HOMING_SPEED   = 400.0;
const Float: PROJECTILE_EXPLODE_RADIUS = 150.0;
const Float: PROJECTILE_EXPLODE_DAMAGE = 80.0;

/* ~ [ Special Ammo ] ~ */
#define pev_special_ammo            pev_gaitsequence
const SPECIAL_AMMO_MAX              = 5;

new Float: g_flbisonAmmoTimerx[33];



/* ~ [ Hud Configurations ] ~ */        // ~x3 Arabas Shooting Star <3
#define HIDEHUD_NONE        ( 1 << 7 )
#define SET_CUSTOM_HUD      ( HIDEHUD_MONEY )
#define RESET_HUD           ( HIDEHUD_NONE )

new gl_iMsgID_HideWeapon;

/* ~ [ Definitions ] ~ */
#define IsCustomWeapon(%0) (pev_valid(%0) == 2 && pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsPdataSafe(%0) (pev_valid(%0) == 2)

/* ~ [ Sounds ] ~ */
new const WeaponSounds[ ][ ] =
{
	"weapons/bisonfox-1.wav",
	"weapons/bisonfox-2.wav",
	"weapons/bisonfox_fx_exp1.wav",
    "weapons/bisonfox_fx_damage.wav",
    "weapons/bisonfox_fx.wav"
};

enum 
{
	Sound_Shoot,
	Sound_ShootB,
	Sound_ShootB_Fx_End,
    Sound_ShootB_Fx_Damage,
    Sound_ShootB_Fx_Start
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
const Weapon_Secondary_Ammo_Index   = 19;
const m_rgpPlayerItems_iWeaponBox = 34;

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
    RegisterHam(Ham_Killed, "player", "Firefox_PlayerKilled_Post", true);
    RegisterHam(Ham_Item_Deploy,            WEAPON_REFERENCE,    "CWeapon__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,   WEAPON_REFERENCE,    "CWeapon__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE,    "CWeapon__SecondaryAttack_Pre",   false);
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

    RegisterHam(Ham_Think,					"info_target",		"CProjectile__Think_Pre", false);
    RegisterHam(Ham_Touch,					"info_target",		"CProjectile__Touch_Pre", false);

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
    gl_iszAllocString_InfoTarget  = engfunc(EngFunc_AllocString, "info_target");
    gl_iszAllocString_BisonProjectile = engfunc(EngFunc_AllocString, ENTITY_BISON_PROJECTILE_CLASSNAME);
    gl_iszAllocString_Bisoneffect = engfunc(EngFunc_AllocString, ENTITY_BISON_EFFECT_CLASSNAME);



    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    gl_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
    #endif

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
    gl_iMsgID_HideWeapon = get_user_msgid( "HideWeapon" );

    // Ham Hook
    fm_ham_hook(false);

    // Commands
    register_clcmd("say /ff", "Command_GiveWeapon");
}

public plugin_precache()
{
    precache_generic("sound/weapons/bisonfox_clipin1.wav");
    precache_generic("sound/weapons/bisonfox_clipout1.wav");
    precache_generic("sound/weapons/bisonfox_draw.wav");

    precache_generic("sound/weapons/bisonfox-1.wav");
    precache_generic("sound/weapons/bisonfox-2.wav");
    precache_generic("sound/weapons/bisonfox_clipin1.wav");
    precache_generic("sound/weapons/bisonfox_clipout1.wav");
    precache_generic("sound/weapons/bisonfox_draw.wav");
    precache_generic("sound/weapons/bisonfox_fx.wav");
    precache_generic("sound/weapons/bisonfox_fx_damage.wav");
    precache_generic("sound/weapons/bisonfox_fx_exp1.wav");
    precache_generic("sound/weapons/bisonfox_fx_exp2.wav");
    precache_generic("sound/weapons/bisonfox_fx_follow.wav");
    precache_generic("sound/weapons/bisonfox_idle1.wav");
    precache_generic("sound/weapons/bisonfox_idle2.wav");
    precache_generic("sound/weapons/bisonfox_idle_end.wav");
    // Precache Models
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
    engfunc(EngFunc_PrecacheModel, ENTITY_BISON_PROJECTILE);
    engfunc(EngFunc_PrecacheModel, ENTITY_BISON_EFFECT);
    engfunc(EngFunc_PrecacheModel, "sprites/firefox/ef_bisonfox_explo.spr");
    engfunc(EngFunc_PrecacheModel, "sprites/firefox/ef_bisonfox_fire.spr");

    // Precache Sprites
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);
    engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE_B);
    // engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE_FIREBALL);
    // engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE_TAIL);
    #endif

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
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || zp_get_user_survivor(pPlayer)) return 0;
    static pItem; pItem = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsPdataSafe(pItem)) return FM_NULLENT;

    set_pev(pItem, pev_impulse, WEAPON_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, pItem);
    set_pdata_int(pItem, m_iClip, WEAPON_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(pPlayer, ExecuteHamB(Ham_Item_ItemSlot, pItem));

    if(!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pItem))
    {
	set_pev(pItem, pev_flags, pev(pItem, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, pItem, pPlayer);
    UTIL_WeaponList(pPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);

    set_pdata_int(pPlayer, iAmmoType, WEAPON_BPAMMO, linux_diff_player);

    emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

/* ~ [ Hamsandwich ] ~ */
public CWeapon__Deploy_Post(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return ;

    set_pev_string(pPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(pPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_DRAW);

    Show_MoneyHud(pPlayer);

    Weapon_SetTimeWeaponIdle(pItem, WEAPON_ANIM_DRAW_TIME);
    Player_SetNextAttack(pPlayer, WEAPON_ANIM_DRAW_TIME);

    // UTIL_CreateScreenMuzzle(pPlayer, ENTITY_MUZZLE_SPRITE_FIREBALL, 0.028, 180.0, 1, gl_iszAllocString_IdleMuzzles);
    // UTIL_CreateScreenMuzzle(pPlayer, ENTITY_MUZZLE_SPRITE_TAIL,     0.028, 160.0, 1, gl_iszAllocString_IdleMuzzles);
}

public CWeapon__PrimaryAttack_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        Weapon_SetNextPrimaryAttack(pItem, 0.2);

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
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;

    Weapon_DoRecoil( pPlayer, WEAPON_PUNCHANGLE * 1.35 )

    UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SHOOT);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITE, 0.051, 200.0, 2, gl_iszAllocString_MuzzleFlash, SF_SPRITE_ONCE);
    #endif

    emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    Weapon_SetAllTimers( pItem, pPlayer, WEAPON_SHOOT_RATE, WEAPON_SHOOT_RATE, WEAPON_ANIM_SHOOT_TIME, WEAPON_SHOOT_RATE )

    return HAM_SUPERCEDE;
}


public CWeapon__SecondaryAttack_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;

    
    static iSpeicalAmmo; iSpeicalAmmo = Weapon_GetSpecialAmmo( pItem );

    if(iSpeicalAmmo >  0)
    {
        if(!CWeapon__Create_Projectile(pPlayer))
        {
            Weapon_SetAllTimers(pItem, pPlayer, 0.2, 0.2, 0.2, 0.2);
            return HAM_SUPERCEDE;
        }
        Weapon_SetSpecialAmmo(pItem, pPlayer, --iSpeicalAmmo );
        UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SHOOT_B)

        Weapon_SetAllTimers( pItem, pPlayer, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME, WEAPON_ANIM_SHOOT_TIME )

        emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[Sound_ShootB], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        #if defined CUSTOM_MUZZLEFLASH_ENABLED

            UTIL_KillEnt_ByClass(pPlayer, ENTITY_MUZZLE_CLASSNAME);
            UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_SPRITE_B, 0.065, 175.0, 2, gl_iszAllocString_MuzzleFlash, SF_SPRITE_ONCE);
        #endif
    }
    else if(iSpeicalAmmo == 0)
    {
        client_print(pPlayer, print_center, "No Ammos")
        Weapon_SetNextSecondaryAttack(pItem, 0.5);
    }

    return HAM_SUPERCEDE;
}



public CWeapon__Reload_Pre(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
    if(iAmmo >= WEAPON_AMMO) return HAM_SUPERCEDE;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    // Ignore repeated reload requests while reloading or waiting for draw/attack.
    if(Weapon_GetReload(pItem) || get_pdata_float(pPlayer, m_flNextAttack, linux_diff_player) > 0.0) return HAM_SUPERCEDE;

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
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;
    static pButton; pButton = pev(pPlayer, pev_button);

    if((pButton & IN_ATTACK2) && Weapon_GetNextSecondaryAttack(pItem) <= 0.0)
    {
        ExecuteHamB(Ham_Weapon_SecondaryAttack, pItem);
        pButton &= ~IN_ATTACK2;
        set_pev(pPlayer, pev_button, pButton);
    }

    if(Weapon_GetReload(pItem) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
        static pPlayer2; pPlayer2 = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
        if(!is_user_connected(pPlayer2)) return HAM_IGNORED;

        new iClip = Weapon_GetClip(pItem);
        new iAmmo = get_pdata_int(pPlayer2, iAmmoType, linux_diff_player);
        new j = min(WEAPON_AMMO - iClip, iAmmo);

        Weapon_SetClip(pItem, iClip + j);
        set_pdata_int(pPlayer2, iAmmoType, iAmmo - j, linux_diff_player);
        Weapon_SetReload(pItem, 0);
    }

    // ~ [ Aura Damage Tick ] ~
    new Float: flGameTime = get_gametime();
    new Float: flNextAuraTick; pev(pItem, pev_fuser1, flNextAuraTick);

    if(flGameTime >= flNextAuraTick)
    {
        set_pev(pItem, pev_fuser1, flGameTime + 1.5);

        new Float: vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
        new pVictim = FM_NULLENT;

        while((pVictim = engfunc(EngFunc_FindEntityInSphere, pVictim, vecOrigin, 250.0)) > 0)
        {
            if(!IsValidVictim(pVictim, pPlayer)) continue;

            ExecuteHamB(Ham_TakeDamage, pVictim, pItem, pPlayer, 50.0, DMG_ALWAYSGIB);

            new Float: vecVictimOrigin[3]; pev(pVictim, pev_origin, vecVictimOrigin);

            UTIL_Explosion(vecVictimOrigin, 0.0, engfunc(EngFunc_ModelIndex, "sprites/firefox/ef_bisonfox_fire.spr"), 4, 20, 2|4|8);
        }
    }

    new iSpeicalAmmo = Weapon_GetSpecialAmmo(pItem);
    if(iSpeicalAmmo < SPECIAL_AMMO_MAX)
    {
        if(g_flbisonAmmoTimerx[pPlayer] == 0.0)
        {
            g_flbisonAmmoTimerx[pPlayer] = flGameTime + 5.0;
        }
        else if(flGameTime >= g_flbisonAmmoTimerx[pPlayer])
        {
            Weapon_SetSpecialAmmo(pItem, pPlayer, ++iSpeicalAmmo);
            g_flbisonAmmoTimerx[pPlayer] = (iSpeicalAmmo < SPECIAL_AMMO_MAX) ? flGameTime + 5.0 : 0.0;
        }
    }
    else
    {
        g_flbisonAmmoTimerx[pPlayer] = 0.0;
    }

    return HAM_IGNORED;
}

public CWeapon__Holster_Post(pItem)
{
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!is_user_connected(pPlayer)) return ;

    Weapon_SetAllTimers( pItem, pPlayer, 0.0, 0.0, 0.0, 0.0 )

    Show_MoneyHud(pPlayer); 

    set_pev(pItem, pev_fuser1, 0.0);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    UTIL_KillEnt_ByClass(pPlayer, ENTITY_MUZZLE_CLASSNAME);
    #endif
}

public CEntity__TraceAttack_Pre(pVictim, iAttacker, Float: flDamage)
{
    if(!is_user_connected(iAttacker)) return;
	
    static pItem; pItem = get_pdata_cbase(iAttacker, 373, 5);
    if(!IsPdataSafe(pItem) || !IsCustomWeapon(pItem)) return;

    flDamage *= WEAPON_SHOOT_DAMAGE
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
    if(!is_user_connected(pPlayer)) return HAM_IGNORED;

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

public FM_Hook_SetModel_Pre(pEnt)
{
    if(pev_valid(pEnt) != 2) return FMRES_IGNORED;
    static i, szClassName[32], pItem;
    pev(pEnt, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        pItem = get_pdata_cbase(pEnt, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
        if(IsPdataSafe(pItem) && IsCustomWeapon(pItem))
        {
            engfunc(EngFunc_SetModel, pEnt, WEAPON_MODEL_WORLD);
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
    write_byte(random_num(41, 45));
    message_end();
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_STREAK_SPLASH);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20)); 
    write_byte(5);
    write_short(70);
    write_short(3);
    write_short(75);
    message_end();

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

public CProjectile__Think_Pre( pEnt )
{
    if( !IsPdataSafe( pEnt ) ) return HAM_IGNORED;

    if ((pev(pEnt, pev_classname) == gl_iszAllocString_BisonProjectile || pev(pEnt, pev_classname) == gl_iszAllocString_Bisoneffect) && (pev(pEnt, pev_flags) & FL_KILLME)) return HAM_SUPERCEDE;
    new pFounder = pev( pEnt, pev_owner );
    if((pev(pEnt,pev_classname)==gl_iszAllocString_BisonProjectile || pev(pEnt,pev_classname)==gl_iszAllocString_Bisoneffect) && (!is_user_alive(pFounder) || zp_get_user_zombie(pFounder))) { set_pev(pEnt,pev_flags,FL_KILLME); return HAM_SUPERCEDE; }
    new Float: flGameTime = get_gametime();
    new Float: vecOrigin[ 3 ]; pev( pEnt, pev_origin, vecOrigin );

    if( pev( pEnt, pev_classname ) == gl_iszAllocString_BisonProjectile )
    {
        static Float: flLifeTime; pev( pEnt, pev_ltime, flLifeTime );
        if( flLifeTime <= flGameTime )
        {
            Projectile_Finish(pEnt);
            UTIL_RadiusDamage( pFounder, vecOrigin, PROJECTILE_EXPLODE_RADIUS, PROJECTILE_EXPLODE_DAMAGE );
            return HAM_SUPERCEDE;
        }

        if( pev( pEnt, pev_iuser1 ) == PROJECTILE_STATE_HOMING )
        {
            Projectile_ProcessHoming( pEnt, pFounder, flGameTime );
            return HAM_SUPERCEDE;
        }

        Projectile_AlignAnglesToVelocity( pEnt );

        new pTarget = Projectile_FindClosestEnemy( pEnt, vecOrigin, pFounder, PROJECTILE_SCAN_RADIUS );
        if( pTarget )
        {
            Projectile_StartHoming( pEnt, pTarget );
            Projectile_ProcessHoming( pEnt, pFounder, flGameTime );
            return HAM_SUPERCEDE;
        }

        set_pev( pEnt, pev_nextthink, flGameTime + 0.1 );
        return HAM_SUPERCEDE;
    }

    if( pev( pEnt, pev_classname ) == gl_iszAllocString_Bisoneffect )
    {
        static Float: flLifeTime; pev( pEnt, pev_ltime, flLifeTime );

        if( flLifeTime <= flGameTime )
        {
            Projectile_Finish(pEnt);
            UTIL_RadiusDamage( pFounder, vecOrigin, PROJECTILE_EXPLODE_RADIUS, PROJECTILE_EXPLODE_DAMAGE * 2.5 );
            UTIL_Explosion(vecOrigin,  47.0, engfunc(EngFunc_ModelIndex, "sprites/firefox/ef_bisonfox_explo.spr"), 10, 30, 2|4|8);     // Agent 47 🕵️‍♀️

            emit_sound(pFounder, CHAN_WEAPON, WeaponSounds[ Sound_ShootB_Fx_End ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

            set_pev( pEnt, pev_flags, FL_KILLME );
            return HAM_SUPERCEDE;
        }

        emit_sound(pFounder, CHAN_WEAPON, WeaponSounds[ Sound_ShootB_Fx_Damage ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        UTIL_RadiusDamage( pFounder, vecOrigin, PROJECTILE_EXPLODE_RADIUS, PROJECTILE_EXPLODE_DAMAGE );
        set_pev( pEnt, pev_nextthink, flGameTime + 0.3 );
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public CProjectile__Touch_Pre( pEnt, pTouch )
{
    if( !IsPdataSafe( pEnt ) ) return HAM_IGNORED;
    if( pev( pEnt, pev_classname ) != gl_iszAllocString_BisonProjectile ) return HAM_IGNORED;

    if ((pev(pEnt, pev_classname) == gl_iszAllocString_BisonProjectile || pev(pEnt, pev_classname) == gl_iszAllocString_Bisoneffect) && (pev(pEnt, pev_flags) & FL_KILLME)) return HAM_SUPERCEDE;
    new pFounder = pev( pEnt, pev_owner );
    if((pev(pEnt,pev_classname)==gl_iszAllocString_BisonProjectile || pev(pEnt,pev_classname)==gl_iszAllocString_Bisoneffect) && (!is_user_alive(pFounder) || zp_get_user_zombie(pFounder))) { set_pev(pEnt,pev_flags,FL_KILLME); return HAM_SUPERCEDE; }

    if( pTouch == pFounder ) return HAM_SUPERCEDE;

    if( pev_valid( pTouch ) && pev( pTouch, pev_classname ) == gl_iszAllocString_BisonProjectile )
        return HAM_IGNORED;

    new Float: vecOrigin[ 3 ]; pev( pEnt, pev_origin, vecOrigin );

    if( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
    {
        set_pev( pEnt, pev_flags, FL_KILLME );
        return HAM_SUPERCEDE;
    }
    if( pev( pEnt, pev_iuser1 ) == PROJECTILE_STATE_HOMING && is_user_alive( pTouch ) && IsValidVictim( pTouch, pFounder ) )
    {
        Projectile_HomingHit( pEnt, pFounder, pTouch );
        return HAM_SUPERCEDE;
    }

    if( pev( pEnt, pev_iuser1 ) != PROJECTILE_STATE_BOUNCE )
        return HAM_IGNORED;

    if( pTouch == 0 )
    {
        new tr = create_tr2();
        new Float: vecEnd[3];
        vecEnd[0] = vecOrigin[0];
        vecEnd[1] = vecOrigin[1];
        vecEnd[2] = vecOrigin[2] - 1.0;

        engfunc( EngFunc_TraceLine, vecOrigin, vecEnd, IGNORE_MONSTERS, pEnt, tr );

        new Float: vecPlaneNormal[3];
        get_tr2( tr, TR_vecPlaneNormal, vecPlaneNormal );
        free_tr2( tr );

        if( vecPlaneNormal[2] > 0.7 )  
        {
            new Float: vecEffectPos[3];
            vecEffectPos[0] = vecOrigin[0];
            vecEffectPos[1] = vecOrigin[1];
            vecEffectPos[2] = vecOrigin[2];

            CWeapon__CreateBisonEffect( pFounder, vecEffectPos, 1, 2, 0 );

            set_pev( pEnt, pev_flags, FL_KILLME );
            return HAM_SUPERCEDE;
        }
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
    static pEnt, iNext, szWeaponName[32];
    pEnt = get_pdata_cbase(pPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(pEnt > 0)
    {       
        do 
        {
            iNext = get_pdata_cbase(pEnt, m_pNext, linux_diff_weapon);
            if(get_weaponname(get_pdata_int(pEnt, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
            engclient_cmd(pPlayer, "drop", szWeaponName);
        } 
		
        while((pEnt = iNext) > 0);
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

stock UTIL_CreateMuzzleFlash(pPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment, iClassname, iSpawnFlags)
{
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
		
    static iSprite, iszAllocStringCached;
    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
    if(!IsPdataSafe(iSprite)) return FM_NULLENT;
		
    set_pev(iSprite, pev_model, szMuzzleSprite);
    set_pev(iSprite, pev_spawnflags, iSpawnFlags);

    set_pev_string(iSprite, pev_classname, iClassname);
    set_pev(iSprite, pev_owner, pPlayer);
    set_pev(iSprite, pev_aiment, pPlayer);
    set_pev(iSprite, pev_body, iAttachment);
		
    UTIL_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
    set_pev(iSprite, pev_scale, flScale);
		
    dllfunc(DLLFunc_Spawn, iSprite);

    return iSprite;
}
#endif

// stock UTIL_CreateScreenMuzzle(pPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment, iClassname)     // not working as it should, so i stopped
// {
//     if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;

//     static iSprite, iszAllocStringCached;
//     if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
//     iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);

//     if(!IsPdataSafe(iSprite)) return FM_NULLENT;

//     set_pev(iSprite, pev_model, szMuzzleSprite);
//     set_pev(iSprite, pev_spawnflags, SF_SPRITE_STARTON);

//     set_pev_string(iSprite, pev_classname, iClassname);
//     set_pev(iSprite, pev_owner, pPlayer);
//     set_pev(iSprite, pev_aiment, pPlayer);
//     set_pev(iSprite, pev_body, iAttachment);

//     UTIL_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
//     set_pev(iSprite, pev_scale, flScale);
//     set_pev(iSprite, pev_frame, 0.0);

//     dllfunc(DLLFunc_Spawn, iSprite);


//     set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_IDLE_NEXTTHINK);

//     return iSprite;
// }

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


stock UTIL_RadiusDamage( iAttacker, const Float: origin[3], Float: flRadius, Float: flDamage )  // ~x3 Arabas Pookie <3 Shooting Star "Create_explosion"
{
    new pVictim = FM_NULLENT;
    while( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, origin, flRadius ) ) > 0 )
    {
        if( !IsValidVictim( pVictim, iAttacker ) ) continue;

        ExecuteHamB( Ham_TakeDamage, pVictim, iAttacker, iAttacker, flDamage, DMG_ALWAYSGIB );
    }
}

stock bool: IsValidVictim(pVictim, iAttacker)
{
    return is_user_alive(pVictim) && is_user_alive(iAttacker) && zp_get_user_zombie(pVictim) && !zp_get_user_zombie(iAttacker);
}

stock Projectile_HomingHit( const pEnt, const pFounder, const pTouch )
{
    if(!pev_valid(pEnt) || (pev(pEnt,pev_flags) & FL_KILLME)) return;
    Projectile_Finish(pEnt);
    new Float: vecTarget[ 3 ]; pev( pTouch, pev_origin, vecTarget );
    new Float: vecEffectPos[ 3 ];
    vecEffectPos[ 0 ] = vecTarget[ 0 ];
    vecEffectPos[ 1 ] = vecTarget[ 1 ];
    vecEffectPos[ 2 ] = vecTarget[ 2 ] - 32.0;

    CWeapon__CreateBisonEffect( pFounder, vecEffectPos, 0, 1, pTouch );

    UTIL_RadiusDamage( pFounder, vecTarget, PROJECTILE_EXPLODE_RADIUS, PROJECTILE_EXPLODE_DAMAGE );
    set_pev( pEnt, pev_flags, FL_KILLME );
}



stock Projectile_AlignAnglesToVelocity( const pEnt )        // ~x3 Arabas 
{
    new Float: vecVelocity[ 3 ]; pev( pEnt, pev_velocity, vecVelocity );
    if( xs_vec_len( vecVelocity ) < 80.0 ) return;

    new Float: vecAngles[ 3 ];
    engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );     // makes life easier || low cortisol <3 
    set_pev( pEnt, pev_angles, vecAngles );
}

stock bool: Is_Wall_BetWeen_Points( const pEnt, const Float: Start[ 3 ], const Float: End[ 3 ] )
{
    new iTrace = create_tr2();
    engfunc( EngFunc_TraceLine, Start, End, IGNORE_MONSTERS, pEnt, iTrace );

    new Float: flFraction;
    get_tr2( iTrace, TR_flFraction, flFraction );
    free_tr2( iTrace );

    return ( flFraction >= 1.0 );
}

stock Projectile_FindClosestEnemy( const pEnt, const Float: vecOrigin[ 3 ], const pFounder, const Float: flRadius )
{
    new pBest = FM_NULLENT;
    new Float: flBestDist = flRadius;
    new pVictim = FM_NULLENT;

    new Float: vecTraceStart[ 3 ];
    vecTraceStart[ 0 ] = vecOrigin[ 0 ];
    vecTraceStart[ 1 ] = vecOrigin[ 1 ];
    vecTraceStart[ 2 ] = vecOrigin[ 2 ];

    while( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, vecOrigin, flRadius ) ) > 0 )
    {
        if( !IsValidVictim( pVictim, pFounder ) ) continue;

        new Float: vecVictim[ 3 ]; pev( pVictim, pev_origin, vecVictim );
        new Float: flDist = get_distance_f( vecOrigin, vecVictim );

        if( flDist >= flBestDist ) continue;

        new Float: vecTraceEnd[ 3 ];
        vecTraceEnd[ 0 ] = vecVictim[ 0 ];
        vecTraceEnd[ 1 ] = vecVictim[ 1 ];
        vecTraceEnd[ 2 ] = vecVictim[ 2 ] + 17.0;       // to make it on chest level

        if( !Is_Wall_BetWeen_Points( pEnt, vecTraceStart, vecTraceEnd ) ) continue;

        flBestDist = flDist;
        pBest = pVictim;
    }

    return pBest;
}

stock Projectile_StartHoming( const pEnt, const pTarget )
{
    set_pev( pEnt, pev_iuser1, PROJECTILE_STATE_HOMING );
    set_pev( pEnt, pev_enemy,   pTarget );
    set_pev( pEnt, pev_movetype, MOVETYPE_FLY );
    set_pev( pEnt, pev_gravity,  0.0 );
}

stock Projectile_ProcessHoming( const pEnt, const pFounder, const Float: flGameTime )
{
    new pTarget = pev( pEnt, pev_enemy );

    if( !is_user_alive( pTarget ) || !IsValidVictim( pTarget, pFounder ) )
    {
        set_pev( pEnt, pev_iuser1, PROJECTILE_STATE_BOUNCE );
        set_pev( pEnt, pev_enemy, 0 );
        set_pev( pEnt, pev_movetype, MOVETYPE_BOUNCE );
        set_pev( pEnt, pev_gravity,  1.0 );
        set_pev( pEnt, pev_nextthink, flGameTime + 0.1 );
        return;
    }

    new Float: vecOrigin[ 3 ]; pev( pEnt, pev_origin, vecOrigin );
    new Float: vecTarget[ 3 ]; pev( pTarget, pev_origin, vecTarget );

    new Float: vecLosEnd[ 3 ];
    vecLosEnd[ 0 ] = vecTarget[ 0 ];
    vecLosEnd[ 1 ] = vecTarget[ 1 ];
    vecLosEnd[ 2 ] = vecTarget[ 2 ] + 17.0;     // chest levcel

    if( !Is_Wall_BetWeen_Points( pEnt, vecOrigin, vecLosEnd ) )
    {
        set_pev( pEnt, pev_iuser1, PROJECTILE_STATE_BOUNCE );
        set_pev( pEnt, pev_enemy, 0 );
        set_pev( pEnt, pev_movetype, MOVETYPE_BOUNCE );
        set_pev( pEnt, pev_gravity,  1.0 );
        set_pev( pEnt, pev_nextthink, flGameTime + 0.1 );
        return;
    }

    new Float: vecDir[ 3 ];
    xs_vec_sub( vecTarget, vecOrigin, vecDir );

    if( xs_vec_len( vecDir ) <= 48.0 )
    {
        Projectile_HomingHit( pEnt, pFounder, pTarget );
        
        return;
    }

    xs_vec_normalize( vecDir, vecDir );

    new Float: vecVelocity[ 3 ];
    vecVelocity[ 0 ] = vecDir[ 0 ] * PROJECTILE_HOMING_SPEED;
    vecVelocity[ 1 ] = vecDir[ 1 ] * PROJECTILE_HOMING_SPEED;
    vecVelocity[ 2 ] = vecDir[ 2 ] * PROJECTILE_HOMING_SPEED;
    set_pev( pEnt, pev_velocity, vecVelocity );

    Projectile_AlignAnglesToVelocity( pEnt );

    set_pev( pEnt, pev_nextthink, flGameTime + 0.1 );
}

stock CWeapon__CreateBisonEffect( pPlayer, Float: vecOrigin[3], iSequence, iBody, pHomingTarget = 0 )
{
    new pEnt = engfunc( EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget );
    if( !pEnt ) return FM_NULLENT;

    new Float: flGameTime = get_gametime();

    set_pev_string( pEnt, pev_classname, gl_iszAllocString_Bisoneffect );
    set_pev( pEnt, pev_movetype,  MOVETYPE_FLY );   
    set_pev( pEnt, pev_solid,     SOLID_NOT );
    set_pev( pEnt, pev_owner,     pPlayer );
    set_pev( pEnt, pev_nextthink, flGameTime + 0.3 );
    set_pev( pEnt, pev_ltime,     flGameTime + 1.53 );

    set_pev( pEnt, pev_iuser2, pHomingTarget );

    set_pev( pEnt, pev_body, iBody );

    engfunc( EngFunc_SetModel,  pEnt, ENTITY_BISON_EFFECT );
    engfunc( EngFunc_SetOrigin, pEnt, vecOrigin );
    engfunc( EngFunc_SetSize,   pEnt, Float:{ -2.0, -2.0, -2.0 }, Float:{ 2.0, 2.0, 2.0 } );

    UTIL_SetEntityAnim( pEnt, iSequence );

    emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_ShootB_Fx_Start ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return pEnt;
}

stock Projectile_Finish(pEnt)
{
    set_pev(pEnt, pev_solid, SOLID_NOT);
    set_pev(pEnt, pev_velocity, Float:{0.0, 0.0, 0.0});
    set_pev(pEnt, pev_nextthink, 0.0);
    set_pev(pEnt, pev_flags, pev(pEnt, pev_flags) | FL_KILLME);
}

stock CWeapon__Create_Projectile( pPlayer )
{
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer)) return FM_NULLENT;
    new pEnt = engfunc( EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget );
    if( !pEnt ) return FM_NULLENT;

    new Float: vecOrigin[ 3 ]; UTIL_GetBarrelPosition( pPlayer, vecOrigin );
    // Sweep the muzzle placement from the eyes; never spawn through nearby walls.
    new Float: vecEyes[3], Float: vecView[3];
    pev(pPlayer, pev_origin, vecEyes);
    pev(pPlayer, pev_view_ofs, vecView);
    xs_vec_add(vecEyes, vecView, vecEyes);
    new tr = create_tr2();
    engfunc(EngFunc_TraceHull, vecEyes, vecOrigin, IGNORE_MONSTERS, HULL_POINT, pPlayer, tr);
    new blocked = get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid);
    new Float:fraction; get_tr2(tr, TR_flFraction, fraction);
    free_tr2(tr);
    if(blocked || fraction < 1.0)
    {
        Projectile_Finish(pEnt);
        return FM_NULLENT;
    }

    new Float: vecAngles[ 3 ]; pev( pPlayer, pev_v_angle, vecAngles );
    new Float: vecForward[ 3 ]; angle_vector( vecAngles, ANGLEVECTOR_FORWARD, vecForward );
    new Float: vecVelocity[ 3 ]; xs_vec_copy( vecForward, vecVelocity );
    new Float: flGameTime = get_gametime();

    xs_vec_mul_scalar( vecVelocity, 600.0, vecVelocity );

    set_pev_string( pEnt, pev_classname, gl_iszAllocString_BisonProjectile );
    set_pev( pEnt, pev_movetype,  MOVETYPE_BOUNCE );
    set_pev( pEnt, pev_solid,     SOLID_TRIGGER );
    set_pev( pEnt, pev_owner,     pPlayer );
    set_pev( pEnt, pev_velocity,  vecVelocity );
    set_pev( pEnt, pev_gravity,   1.0 );
    set_pev( pEnt, pev_iuser1,    PROJECTILE_STATE_BOUNCE );
    set_pev( pEnt, pev_enemy,     0 );
    set_pev( pEnt, pev_nextthink, flGameTime + 0.1 );
    set_pev( pEnt, pev_ltime,     flGameTime + 5.0 );

    engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );
    set_pev( pEnt, pev_angles, vecAngles );

    engfunc( EngFunc_SetModel,  pEnt, ENTITY_BISON_PROJECTILE );
    engfunc( EngFunc_SetOrigin, pEnt, vecOrigin );
    engfunc( EngFunc_SetSize,   pEnt, Float:{ -2.0, -2.0, -2.0 }, Float:{ 2.0, 2.0, 2.0 } );

    UTIL_SetEntityAnim( pEnt, 0 );

    return pEnt;
}

stock UTIL_SetEntityAnim( pEnt, iSequence )  // xunicorn Dread nova
{
    set_pev( pEnt, pev_frame,     1.0            );
    set_pev( pEnt, pev_framerate, 1.0            );
    set_pev( pEnt, pev_animtime,  get_gametime() );
    set_pev( pEnt, pev_sequence,  iSequence      );
}

stock UTIL_GetSpeedVector(Float: vecStartOrigin[3], Float: vecEndOrigin[3], Float: flSpeed = 0.0, Float: flTime = 1.0, Float: vecVelocity[3])   // 3ihcsWex
{
	if(!flSpeed)
        flSpeed = xs_vec_distance(vecStartOrigin, vecEndOrigin) / flTime;
	else
		flSpeed /= flTime;

	xs_vec_sub(vecEndOrigin, vecStartOrigin, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
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

stock UTIL_GetBarrelPosition( pPlayer, Float: vecOut[ 3 ] ) // cristian 505
{
    static Float: vecOrigin[ 3 ], Float: vecAngles[ 3 ];
    static Float: vecForward[ 3 ], Float: vecRight[ 3 ], Float: vecUp[ 3 ];
    static Float: vecViewOfs[ 3 ];

    pev( pPlayer, pev_origin,   vecOrigin );
    pev( pPlayer, pev_v_angle,  vecAngles );
    pev( pPlayer, pev_view_ofs, vecViewOfs );

    engfunc( EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp );

    static const Float: BARREL_FORWARD = 22.0;
    static const Float: BARREL_RIGHT   = 6.0;
    static const Float: BARREL_DOWN    = -5.0;

    vecOut[ 0 ] = vecOrigin[ 0 ] + vecViewOfs[ 0 ] + vecForward[ 0 ] * BARREL_FORWARD + vecRight[ 0 ] * BARREL_RIGHT + vecUp[ 0 ] * BARREL_DOWN;
    vecOut[ 1 ] = vecOrigin[ 1 ] + vecViewOfs[ 1 ] + vecForward[ 1 ] * BARREL_FORWARD + vecRight[ 1 ] * BARREL_RIGHT + vecUp[ 1 ] * BARREL_DOWN;
    vecOut[ 2 ] = vecOrigin[ 2 ] + vecViewOfs[ 2 ] + vecForward[ 2 ] * BARREL_FORWARD + vecRight[ 2 ] * BARREL_RIGHT + vecUp[ 2 ] * BARREL_DOWN;
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

stock EmitSound_FromPos( const Float: vecOrigin[3], const szSound[], Float: flVol = VOL_NORM, Float: flAttn = ATTN_NORM, iFlags = 0, iPitch = PITCH_NORM )
{
    engfunc( EngFunc_EmitAmbientSound, 0, vecOrigin, szSound, flVol, flAttn, iFlags, iPitch );
}

stock UTIL_KillEnt_ByClass(iOwner, const szClassname[])
{
    new pEnt = FM_NULLENT;
    while((pEnt = fm_find_ent_by_owner(pEnt, szClassname, iOwner)) > 0)
    {
        if(IsPdataSafe(pEnt))
            set_pev(pEnt, pev_flags, FL_KILLME);
    }
}
public plugin_natives() { register_native("exhero_give_firefox","ExheroGive"); }
public ExheroGive(plugin,params) { return Command_GiveWeapon(get_param(1)); }

public client_disconnected(id) {
    ExheroCleanup(id); g_flbisonAmmoTimerx[id]=0.0; }

public Firefox_PlayerKilled_Post(id) { ExheroCleanup(id); }

stock ExheroCleanup(id) {
    g_flbisonAmmoTimerx[id] = 0.0;
    new e;
    e=0; while((e=fm_find_ent_by_owner(e,"ent_bison_projectile",id))>0) set_pev(e,pev_flags,FL_KILLME);
    e=0; while((e=fm_find_ent_by_owner(e,"ent_bison_effect",id))>0) set_pev(e,pev_flags,FL_KILLME);
    e=0; while((e=fm_find_ent_by_owner(e,"ent_bison_muzz",id))>0) set_pev(e,pev_flags,FL_KILLME);
}
public zp_user_infected_pre(id) { ExheroCleanup(id); }
