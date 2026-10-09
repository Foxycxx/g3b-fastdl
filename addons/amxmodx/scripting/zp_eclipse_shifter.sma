/*
 *  [ CSO:Eclipse Shifter ]
 *
 *  Copyright (C) 2025 StarGamerz. All Rights Reserved.
 *  This file is part of a PRIVATE PRODUCTION by StarGamerz.
 *
 *  Unauthorized copying, distribution, modification
 *  via any medium, is strictly prohibited without the express written
 *  permission of StarGamers OR CREDITS TO AUTHOR. in order to share plugin , share discord ;- https://discord.gg/mEzeYafgXu
 */

// 🇵🇰: ye file ke author ka naam change krna sakhti se mana h, credits dena lazmi h , Copyright (C) 2025 StarGamerz. All Rights Reserved.


// Cristian505 & Batcoh: Code Base
// Big Thanks To ~x3Arabas For Helping

// Changelog > 01: Fixed The Bug, Entity Not Fading Out After Time < // 4-9-2026 \\ >
// Changelog > 02: Added Zombie Plague Support < // 4-9-2026 \\ >


// Pistol Template //
#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >

// Comment this line out if you Don't Want ZombiePlague ExtraItem
#include < zombieplague >


#if defined _zombieplague_included
	/* ~ [ Extra Item ] ~ */
	// If you need to remove weapon from Extra-Items, comment out this line
	// new const ExtraItem_Name[] =			"Eclipse Shifter";
	// const ExtraItem_Cost =					10;
#endif



const PISTOL_SPECIAL_CODE = 899787;    

// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
// Auto Fire ( PrimaryAttack_Pre ): --// set_pdata_int(pItem, m_iShotsFired, 0, linux_diff_weapon);
// UTIL_CreateMuzzleFlash(const pPlayer, const szClassname[], const SzImpulse, const szMuzzleSprite[], const bool: iMuzzleLoop, const Float: flScale, const Float: flBrightness, const iAttachment,
// Float: flNextThink, const Aiment )

// Pistol Reference and Hud Stuff //
#define WEAPON_CSW CSW_USP

new const PISTOL_WEAPONLIST[] = "eclipse/weapon_radiantx"; // Ex: weapon_balrog1
new const PISTOL_REFERENCE[] = "weapon_usp"; // Ex: weapon_usp
new const iPistolList[] = { 6, 100, -1, -1, 1, 4, WEAPON_CSW, 0 };

new const WEAPONLIST_SPRITES[][] =
{
	"sprites/eclipse/640hud41.spr", // 0
    "sprites/eclipse/640hud272.spr" // 1
}


// Pistol Models //
new const PISTOL_MODEL_VIEW[] = "models/g3bmodel/ZTHEX/eclipse/v_radiant.mdl";
new const PISTOL_MODEL_PLAYER_WORLD[] = "models/eclipse/q_radiant.mdl";

// Pistol Sounds //
new const PISTOL_SOUNDS[][] =
{
    "weapons/radiant-1.wav", // 0
    "weapons/radiant_B_mode.wav", // 1
    "weapons/radiant-2.wav" // 2
}



enum {
	SHOOT_SOUND,
    SHOOT_SOUND_B,
    SHOOT_RELOAD
}




// Pistol Muzzle Flash Sprites //
new const ENTITY_MUZZLE_CLASSNAME[] = "ent_eclipse_muzzleflash";
new const ENTITY_EXPLOSION_CLASSNAME[] = "ent_eclipse_attach_smn";
new const ENTITY_MUZZLE_SPRITES[][] =
{
	"sprites/eclipse/muzzleflash545.spr", // 0
    "sprites/eclipse/ef_radiant_v_ball.spr"
}


/**
 * Automatically precache sounds embedded in the view model.
 * Not needed if ReHLDS is running with:
 *   sv_auto_precache_sounds_in_models 1
 */
#define PrecacheSoundsFromModel

// Pistol Statistics //
const Float: SHOOT_RATE = 0.2;
new Float:g_NextVictimExplosion[33];
const Float: SHOOT_DAMAGE = 4.5;
const Float: SHOOT_ACCURACY = 1.0;
const Float: SHOOT_PUNCHANGLE = 2.31;

// Pistol Animations Time //
const Float: ANIM_IDLE_TIME = 4.03;
const Float: ANIM_DRAW_TIME = 1.03;
const Float: ANIM_SHOOT_TIME = 1.03;

const Float: ANIM_SHOOT_B_START_TIME = 0.37;
const Float: ANIM_SHOOT_B_LOOP_TIME = 1.37;
const Float: ANIM_SHOOT_B_END_TIME = 0.37;

const Float: ANIM_SHOOT_C_TIME = 1.37;

enum _: ePistolAnims
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
    ANIM_SHOOT_B_START,
    ANIM_SHOOT_B_LOOP,
    ANIM_SHOOT_B_END,
	ANIM_SHOOT_C,
	ANIM_DRAW
}


// Regeneration //
const MAX_BPAMMO            = 80;   // total goliyaan ?
const Float: REGEN_AMOUNT  = 0.1;  //  clip ka 6% per tick

const CUSTOM_AMMO_MAX = 100;        // energy ( % )

// Entity //
new const ENTITY_PLAYER_MODEL_CLASSNAME[ ] = "Eclipse_PlayerModel";                      // player model
new const ENTITY_DUMMY_CLASSNAME[ ] = "attachment_dummy";                               // dummy entity trick
new const ENTITY_ECLIPSE_GLOBAL[ ] = "models/eclipse/x_ef_radiant_global_v2.mdl";       // global model for all

// Passive Entity - Check Model
new const ENTITY_ECLIPSE_PASSIVE_CLASSNAME[ ] = "Ent_Eclipse_Passive";
const ECLIPSE_PASSIVE_BODY = 1;
const ECLIPSE_PASSIVE_SEQ = 1;

// Passive entity ticking damage + explosion sprite
new gl_is_modelEIndexSprite;
new const PASSIVE_EXPLOSION_SPRITE[] = "sprites/eclipse/ef_radiant_hit01.spr";
const Float: EXPLOSION_DAMAGE_AMOUNT = 25.0;
const Float: EXPLOSION_DAMAGE_RADIUS = 210.0;

// Summon 01 Entity
new const ENTITY_ECLIPSE_SUMMON_CLASSNAME[ ] = "Ent_Eclipse_Summon";
const ECLIPSE_SUMMON_A_BODY = 8;
const ECLIPSE_SUMMON_A_APPEAR_SEQ = 0;
const ECLIPSE_SUMMON_A_IDLE_SEQ = 0;


// Summon 02 Entity
// new const ENTITY_ECLIPSE_SUMMON_B_CLASSNAME[ ] = "Ent_Eclipse_Summon_B";
const ECLIPSE_SUMMON_B_BODY = 0;
const ECLIPSE_SUMMON_B_APPEAR_SEQ = 2;
const ECLIPSE_SUMMON_B_IDLE_SEQ = 3;
const Float:ECLIPSE_SUMMON_B_LIFETIME = 5.0;

// skins for both
const ECLIPSE_SUMMON__START_SKIN = 2;
const ECLIPSE_SUMMON__TOTAL_SKIN = 31;



// sCosts
const RELOAD_ATTACK_COST = 30;
const SECONDARY_ATTACK_COST = 20;


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
const m_iClip = 51;
const m_fInReload = 54;
const m_flNextAttack = 83;
const m_flAccuracy = 62;
const m_iShotsFired = 64;
const m_rgAmmo = 376;
const m_rpgPlayerItems = 367;
const m_pActiveItem = 373;
const m_iWeaponState = 74;
const m_iSecondaryAmmoType      = 50;
const WeaponSecondaryAmmoIndex  = 30; // Separate from Gigabreaker charge (19).
const m_flVelocityModifier = 108;


// Global Parameters //
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_PlayerModel,
    gl_iszAllocString_EntityDummy,
    gl_iszAllocString_EntityPassive,
    gl_iszAllocString_EntityStatic,
    gl_iszAllocString_MuzzleKey,
    gl_iszAllocString_AttachMuzzle,
    gl_iszAllocString_InfoTarget,
    gl_iBitImmortal,
    Float:gl_fAmmoTimer[33],
    gl_iMsgID_Weaponlist;

// Pistol Conditions & defines //
#define IsPdataValid(%0) (pev_valid(%0) == 2)
#define IsCustomMuzzle(%0,%1)	(pev(%0, pev_impulse) == %1)
#define KillEntity(%0) set_pev(%0, pev_flags, FL_KILLME)
#define IsCustomPistol(%0) (pev(%0, pev_impulse) == PISTOL_SPECIAL_CODE)
#define IsPlayerImmortal(%1) get_bit(gl_iBitImmortal, %1)

// ~x3 Arabas Shooting Star <3 
#define get_bit(%1,%2) ((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2) %1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2) %1 &= ~(1 << (%2 & 31))


#define GetWeaponState(%0)      ( get_pdata_int( %0, m_iWeaponState, linux_diff_weapon ) )      // sthreexty   ( Balrog- 9 )  // Arabas ~x3 <3
#define SetWeaponState(%0,%1)   ( set_pdata_int( %0, m_iWeaponState, %1, linux_diff_weapon ) )  // sthreexty   ( Balrog- 9 )  // Arabas ~x3 <3

// #if !defined DMG_BLAST
//     #define DMG_BLAST                       (1<<6)      // Explosive blast damage
// #endif

#if !defined EF_FORCEVISIBILITY
    #define EF_FORCEVISIBILITY                       2048     // pev_effects
#endif


#if AMXX_VERSION_NUM <= 182
	#define write_coord_f(%0)					engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

// pevs 
#define pev_secondary_ammo          pev_gaitsequence

// ~ [ Hud Configurations ] ~        // ~x3 Arabas Shooting Star <3 
#define HIDEHUD_MONEY  (1<<5)           
#define HIDEHUD_NONE   (1<<7)           
#define SET_CUSTOM_HUD (HIDEHUD_MONEY)  
#define RESET_HUD      (HIDEHUD_NONE)  


// Secondary attack dash
const Float:DASH_SPEED_H_GROUND = 670.0;    // horizontal speed on ground
const Float:DASH_SPEED_V_MIN = 180.0;   // guaranteed lift the moment you're looking even slightly up
const Float:DASH_SPEED_V_MAX = 420.0;   // lift when looking close to the pitch clamp
const Float:DASH_PITCH_CLAMP = 50.0;    // clamp for ground
const Float:DASH_SPEED_H_AIR = 450.0;   // if in air horizontal speed ?

// Weapon States
enum _: iWeaponStates
{
    WEAPONSTATE_NULL = 0,
    WEAPONSTATE_PRESS,
    WEAPONSTATE_END
};


#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif


// AMX Mod X //
native revo_get_user_hero(id);
native Float:exhero_shop_jump_gravity(id);
new Float:g_BeforeDashGravity[33];
public plugin_natives(){register_native("exhero_give_eclipse", "NativeGiveEclipse");}
public NativeGiveEclipse(plugin, argc){return Command_GivePistol(get_param(1));}
public EclipseCleanup(id){
    UTIL_KillEntByOwner(id, ENTITY_PLAYER_MODEL_CLASSNAME);
    UTIL_KillEntByOwner(id, ENTITY_DUMMY_CLASSNAME);
    UTIL_KillEntByOwner(id, ENTITY_ECLIPSE_PASSIVE_CLASSNAME);
    UTIL_KillEntByOwner(id, ENTITY_ECLIPSE_SUMMON_CLASSNAME);
    UTIL_KillMuzzleFlash(id, false); UTIL_KillMuzzleFlash(id, true);
    if(IsPlayerImmortal(id) && is_user_connected(id)) EclipseRestoreGravity(id);
    reset_bit(gl_iBitImmortal,id); gl_fAmmoTimer[id]=0.0;
}
public zp_user_infected_pre(id){EclipseCleanup(id);}
public EclipseKilled(id){EclipseCleanup(id);}
public plugin_init()
{
    // https://cso.fandom.com/wiki/Eclipse_Shifter
    register_plugin("[CSO] Eclipse Shifter", "1.3", "Supreme aka dam"); 

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

    RegisterHam(Ham_Killed, "player", "EclipseKilled", false);

    // Take Damage
    RegisterHam( Ham_TakeDamage,             "player",             "CPistol_TakeDamage" );

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre",  false);

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, PISTOL_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, PISTOL_MODEL_VIEW);
    gl_iszAllocString_PlayerModel = engfunc(EngFunc_AllocString, ENTITY_PLAYER_MODEL_CLASSNAME);
    gl_iszAllocString_EntityDummy = engfunc(EngFunc_AllocString, ENTITY_DUMMY_CLASSNAME);
    gl_iszAllocString_EntityPassive = engfunc(EngFunc_AllocString, ENTITY_ECLIPSE_PASSIVE_CLASSNAME);
    gl_iszAllocString_EntityStatic = engfunc(EngFunc_AllocString, ENTITY_ECLIPSE_SUMMON_CLASSNAME);
    gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
    
    // Entity
    RegisterHam(Ham_Think, "env_sprite", "CMuzzleFlash__Think_Pre", false);
    RegisterHam(Ham_Think, "info_target", "CEntity__Think_Pre", false);

    // Muzzle Flash
    gl_iszAllocString_MuzzleKey = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
    gl_iszAllocString_AttachMuzzle = engfunc(EngFunc_AllocString, ENTITY_EXPLOSION_CLASSNAME);

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

    
#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

#if !defined _zombieplague_included 
    // Console Command
    register_clcmd("say /es", "Command_GivePistol");
#endif

    // Ham Hook
    fm_ham_hook(false);
}

public plugin_precache()
{
    precache_generic("sound/weapons/radiant_draw.wav");
    precache_generic("sound/weapons/radiant_shoot.wav");
    precache_generic("sound/weapons/radiant_shootC.wav");

    // Hook weapon
    register_clcmd(PISTOL_WEAPONLIST, "Command_HookWeapon");

    // Precache Models
    precache_model_ex(PISTOL_MODEL_VIEW);
    precache_model_ex(PISTOL_MODEL_PLAYER_WORLD);
    precache_model_ex(ENTITY_ECLIPSE_GLOBAL);

    precache_model_ex("models/eclipse/null.mdl");

    gl_is_modelEIndexSprite = precache_model_ex(PASSIVE_EXPLOSION_SPRITE);

    new i;

    // Precache Sounds
    for(i = 0; i < sizeof PISTOL_SOUNDS; i++) engfunc(EngFunc_PrecacheSound, PISTOL_SOUNDS[i]);


#if defined PrecacheSoundsFromModel
    UTIL_PrecacheSoundsFromModel( PISTOL_MODEL_VIEW );
#endif

    // Precache Muzzle Flash Sprites
    for(i = 0; i < sizeof ENTITY_MUZZLE_SPRITES;i++) precache_model_ex(ENTITY_MUZZLE_SPRITES[i]);

    // Precache Generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", PISTOL_WEAPONLIST);
    precache_generic_ex(szWeaponList);

    for( i = 0; i < sizeof WEAPONLIST_SPRITES; i++ ) precache_generic_ex(WEAPONLIST_SPRITES[i]);
}

public Command_HookWeapon(pPlayer)
{
    engclient_cmd(pPlayer, PISTOL_REFERENCE);
    return PLUGIN_HANDLED;
}

#if defined _zombieplague_included && defined ExtraItem_Name
	/* ~ [ Zombie Plague ] ~ */
	public zp_extra_item_selected( pPlayer, iItemId ) 
	{
		if ( iItemId != gl_iItemId )
			return PLUGIN_HANDLED;

		Command_GivePistol( pPlayer );
	}
#endif

public Command_GivePistol(pPlayer)
{
    if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || revo_get_user_hero(pPlayer)) return 0;
    static pPistol; pPistol = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsPdataValid(pPistol)) return FM_NULLENT;

    set_pev(pPistol, pev_impulse, PISTOL_SPECIAL_CODE);

    ExecuteHam(Ham_Spawn, pPistol); 
    UTIL_DropWeapon(pPlayer, ExecuteHamB(Ham_Item_ItemSlot, pPistol));

    if(!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pPistol))
    {
        set_pev(pPistol, pev_flags, pev(pPistol, pev_flags) | FL_KILLME);
        return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, pPistol, pPlayer);

    UTIL_WeaponList(pPlayer, true);

    new Ent = pPistol;
    new iAmmoType = m_rgAmmo + get_pdata_int(Ent, m_iPrimaryAmmoType, linux_diff_weapon);
    
    if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) < MAX_BPAMMO)
        set_pdata_int(pPlayer, iAmmoType, MAX_BPAMMO, linux_diff_player);

    emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

public client_disconnected(pPlayer){ EclipseCleanup(pPlayer); }
public client_connect(pPlayer){ reset_bit(gl_iBitImmortal, pPlayer);g_BeforeDashGravity[pPlayer]=0.0; }


// Fakemeta //
public FM_Hook_UpdateClientData_Post(pPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(pPlayer)) return;

    static pItem; pItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);

    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem) ) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(pEntity)
{
    static i, szClassName[32], pItem;
    pev(pEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        pItem = get_pdata_cbase(pEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

        if(IsPdataValid(pItem) && IsCustomPistol(pItem))
        {
            engfunc(EngFunc_SetModel, pEntity, PISTOL_MODEL_PLAYER_WORLD);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], pFlags, pAttacker, iTrace)
{
    if(pFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(pAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

    // Wall Decal
    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
    write_byte(TE_WORLDDECAL)
    engfunc(EngFunc_WriteCoord, vecEndPos[0])
    engfunc(EngFunc_WriteCoord, vecEndPos[1])
    engfunc(EngFunc_WriteCoord, vecEndPos[2])
    write_byte(random_num(41, 45))
    message_end()

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


// Hamsandwich //
public CPistol__Holster_Post(pItem)
{
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;


    UTIL_KillEntByOwner( pPlayer, ENTITY_PLAYER_MODEL_CLASSNAME );
    UTIL_KillEntByOwner( pPlayer, ENTITY_DUMMY_CLASSNAME );
    UTIL_KillEntByOwner( pPlayer, ENTITY_ECLIPSE_PASSIVE_CLASSNAME );

    SetWeaponState( pItem, WEAPONSTATE_NULL );


    UTIL_KillMuzzleFlash(pPlayer, false);
    UTIL_KillMuzzleFlash(pPlayer, true);
    gl_fAmmoTimer[pPlayer] = 0.0;
    Weapon_SetAllTimers(pItem, pPlayer, 0.0, 0.0, 0.0, 0.0 );
    EclipseCleanup(pPlayer);
}

public CPistol__Deploy_Post(pItem)
{
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;


    set_pev_string(pPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);

    Weapon_SetClip( pItem, -1 );



    Eclipse_Player_Model( pPlayer );       
    CreateDummyAnchor( pPlayer );

    UTIL_SendWeaponAnim(pPlayer, ANIM_DRAW);
    
    gl_fAmmoTimer[pPlayer] = get_gametime() + 1.34;

    Player_SetNextAttack(pPlayer, 0.2 );
    Weapon_SetTimeWeaponIdle( pItem, ANIM_DRAW_TIME );
}

public CPistol__AddToPlayer_Post( pItem, pPlayer )
{
    if ( IsPdataValid( pItem ) && IsCustomPistol( pItem ) )
    {
        if ( pev( pItem, pev_owner ) <= 0 )
        {
            set_pdata_int( pItem, m_iSecondaryAmmoType, WeaponSecondaryAmmoIndex, linux_diff_weapon );
            set_pev( pItem, pev_secondary_ammo, 0 );
        }

        CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, Weapon_GetSecondaryAmmo( pItem ) );
        UTIL_WeaponList( pPlayer, true );
    }
    else if ( !pev( pItem, pev_impulse ) )
    {
        UTIL_WeaponList( pPlayer, false );
    }
}



public CPistol__Idle_Pre(pItem)
{
	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(!IsPdataValid(pItem) || !IsCustomPistol(pItem) || get_pdata_float(pItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	

	UTIL_SendWeaponAnim(pPlayer, ANIM_IDLE);
	set_pdata_float(pItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CPistol__Reload_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;

    if(Weapon_GetNextPrimaryAttack(pItem)>0.0 || Weapon_GetNextSecondaryAttack(pItem)>0.0) return HAM_SUPERCEDE;
    new pState  = GetWeaponState( pItem );
    if(pState != WEAPONSTATE_NULL) return HAM_SUPERCEDE;

    new pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    new Float:flGameTime = get_gametime();

    new pEnt = fm_find_ent_by_owner(FM_NULLENT, ENTITY_ECLIPSE_PASSIVE_CLASSNAME, pPlayer);

    if(!IsPdataValid(pEnt) || pev(pEnt, pev_body) == ECLIPSE_SUMMON_B_BODY)
        return HAM_SUPERCEDE;

    new iSecondaryAmmo = Weapon_GetSecondaryAmmo(pItem);

    if (iSecondaryAmmo < RELOAD_ATTACK_COST)
    {
        client_print(pPlayer, print_center, "No Ammo");
        return HAM_SUPERCEDE;
    }

    UTIL_SendWeaponAnim( pPlayer, ANIM_SHOOT_C );
    Weapon_SetAllTimers(pItem, pPlayer, ANIM_SHOOT_C_TIME, ANIM_SHOOT_C_TIME, ANIM_SHOOT_C_TIME, ANIM_SHOOT_C_TIME);
    CWeapon_UpdateSecondaryAmmo(pItem, pPlayer, iSecondaryAmmo - RELOAD_ATTACK_COST);

    if(IsPdataValid(pEnt))
    {
        set_pev(pEnt, pev_body, ECLIPSE_SUMMON_B_BODY);
        set_pev(pEnt, pev_skin, 2);

        UTIL_SetEntityAnim(pEnt, ECLIPSE_SUMMON_B_APPEAR_SEQ);

        set_pev(pEnt, pev_nextthink, flGameTime);
        set_pev(pEnt, pev_ltime, flGameTime + ECLIPSE_SUMMON_B_LIFETIME);

        set_pev(pEnt, pev_fuser2, flGameTime + 1.03);   // Time when appear animation finishes
        set_pev(pEnt, pev_fuser3, 0.0); // Muzzle 

        set_pev(pEnt, pev_fuser4, flGameTime + ECLIPSE_SUMMON_B_LIFETIME - 3.0);
    }

    emit_sound(pPlayer, CHAN_WEAPON, PISTOL_SOUNDS[SHOOT_RELOAD], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_SUPERCEDE;
}


public CPistol__PrimaryAttack_Pre(pItem)
{
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;
    // if(get_pdata_int(pItem, m_iShotsFired, 4) != 0) return HAM_SUPERCEDE;

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
    static iAmmo; iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);

    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        Weapon_SetNextPrimaryAttack(pItem, 0.2);

        return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);

    set_pdata_int(pItem, m_iShotsFired, 0, linux_diff_weapon);

    fm_ham_hook(true);

    Weapon_SetClip(pItem, 1);           // sets ammo here, taake register ho ske trace

    ExecuteHam(Ham_Weapon_PrimaryAttack, pItem);

    Weapon_SetClip(pItem, -1);      // then remove ammo, ye tricky sirf aur sirf attack trace krne ke liye use kri h 

    // server_print("Clip: %d", get_pdata_int(pItem, m_iClip, linux_diff_weapon));
    // server_print("Shots: %d", get_pdata_int(pItem, m_iShotsFired, linux_diff_weapon));
    // server_print("Accuracy: %.3f", get_pdata_float(pItem, m_flAccuracy, linux_diff_weapon));

    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);


    fm_ham_hook(false);

    Weapon_DoRecoil(pPlayer, 1.0 * SHOOT_PUNCHANGLE)
    UTIL_SendWeaponAnim(pPlayer, ANIM_SHOOT);
    Weapon_DeductBpAmmo( pItem, pPlayer, 1 ); 

    emit_sound(pPlayer, CHAN_WEAPON, PISTOL_SOUNDS[SHOOT_SOUND], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    UTIL_CreateMuzzleFlash(pPlayer, ENTITY_MUZZLE_CLASSNAME, gl_iszAllocString_MuzzleKey, ENTITY_MUZZLE_SPRITES[0], false, 0.037, 255.0, 1, 0.03, pPlayer);        // 67🥀

    gl_fAmmoTimer[pPlayer] = get_gametime() + 1.0;

    set_pdata_float(pItem, m_flAccuracy, SHOOT_ACCURACY, linux_diff_weapon);
    Weapon_SetAllTimers(pItem, pPlayer, SHOOT_RATE, SHOOT_RATE, ANIM_SHOOT_TIME, SHOOT_RATE);

    return HAM_SUPERCEDE;
}


public CPistol__SecondaryAttack_Pre(pItem)
{
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;
    new pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

    new pState = GetWeaponState( pItem );
    if( pState != WEAPONSTATE_NULL ) return HAM_SUPERCEDE;

    new iSecondaryAmmo = Weapon_GetSecondaryAmmo(pItem);

    if (iSecondaryAmmo < SECONDARY_ATTACK_COST)
    {
        client_print(pPlayer, print_center, "No Ammo");
        return HAM_SUPERCEDE; 
    }

    CWeapon_UpdateSecondaryAmmo(pItem, pPlayer, iSecondaryAmmo - SECONDARY_ATTACK_COST);

    new pEnt = FM_NULLENT;
    while((pEnt = fm_find_ent_by_owner(pEnt, ENTITY_ECLIPSE_PASSIVE_CLASSNAME, pPlayer)) > 0)
        if(IsPdataValid(pEnt)) set_pev(pEnt, pev_fuser4, get_gametime() + 0.8);

    SetWeaponState( pItem, WEAPONSTATE_PRESS );

    UTIL_SendWeaponAnim( pPlayer, ANIM_SHOOT_B_START );
    Weapon_SetAllTimers( pItem, pPlayer, 0.1, 0.1, ANIM_SHOOT_B_START_TIME, 0.1 );
    CreateStaticEntity( pPlayer );
    DoDash( pPlayer );

    return HAM_SUPERCEDE;
}

public CPistol__PostFrame_Pre(pItem)
{ 
    static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return HAM_IGNORED;
    
    CWeapon_ChargeAmmo( pItem, pPlayer, MAX_BPAMMO, REGEN_AMOUNT );
    

    static pState;  pState  = GetWeaponState( pItem );

    switch( pState )
    {
        case WEAPONSTATE_PRESS:
        {
            if(Weapon_GetTimeWeaponIdle(pItem) >= 0.0)
                return HAM_SUPERCEDE;

            SetWeaponState( pItem, WEAPONSTATE_END );

            UTIL_SendWeaponAnim( pPlayer, ANIM_SHOOT_B_END );

            Weapon_SetAllTimers( pItem, pPlayer, 0.1, 0.1, ANIM_SHOOT_B_END_TIME, 0.1 );
            
        }

        case WEAPONSTATE_END:
            SetWeaponState( pItem, WEAPONSTATE_NULL );
        
    }

    return HAM_IGNORED;
}


public CPistol_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
    if (!is_user_alive(victim))
        return HAM_IGNORED;

    if ((damagebits & DMG_FALL) && IsPlayerImmortal(victim))
    {
        EclipseRestoreGravity(victim);
        reset_bit(gl_iBitImmortal, victim);
        return HAM_SUPERCEDE; 
    }

    return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(pVictim, pAttacker, Float: flDamage)
{
    if(!is_user_connected(pAttacker)) return;
	
    static pItem; pItem = get_pdata_cbase(pAttacker, m_pActiveItem, linux_diff_player);
    if(!IsPdataValid(pItem) || !IsCustomPistol(pItem)) return;

    SetHamParamFloat(3, flDamage * SHOOT_DAMAGE);
}


// Ham Hook //
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

public CMuzzleFlash__Think_Pre(const pSprite)
{
    if(!IsPdataValid(pSprite)) return HAM_IGNORED;

    if(IsCustomMuzzle(pSprite, gl_iszAllocString_MuzzleKey) || IsCustomMuzzle(pSprite, gl_iszAllocString_AttachMuzzle)) {
        new owner=pev(pSprite,pev_owner), anchor=pev(pSprite,pev_aiment);
        if((pev(pSprite,pev_flags)&FL_KILLME) || !is_user_alive(owner) || zp_get_user_zombie(owner) || !pev_valid(anchor) || (pev(anchor,pev_flags)&FL_KILLME)) {KillEntity(pSprite);return HAM_SUPERCEDE;}
    }
    new Float: flFrame; pev(pSprite, pev_frame, flFrame);
    new Float: flNextThink; pev(pSprite, pev_fuser3, flNextThink);
    new iSpriteType = pev(pSprite, pev_iuser1);
    new Float: flGameTime = get_gametime( );

    if(IsCustomMuzzle(pSprite , gl_iszAllocString_MuzzleKey))
    {

        if(flFrame < get_pdata_float(pSprite, m_maxFrame, 4))
        {
            flFrame++;

            set_pev(pSprite, pev_frame, flFrame);
            set_pev(pSprite, pev_nextthink, flGameTime + flNextThink);
            
            return HAM_SUPERCEDE;
        }
        else if(iSpriteType)
        {
            flFrame = 0.0;
            
            set_pev(pSprite, pev_frame, flFrame);
            set_pev(pSprite, pev_nextthink, flGameTime + flNextThink);
            
            return HAM_SUPERCEDE;
        }

        set_pev(pSprite, pev_flags, FL_KILLME);

    }

    if(IsCustomMuzzle(pSprite , gl_iszAllocString_AttachMuzzle))
    {
        if(flFrame < get_pdata_float(pSprite, m_maxFrame, 4))
        {
            flFrame++;

            set_pev(pSprite, pev_frame, flFrame);
            set_pev(pSprite, pev_nextthink, flGameTime + flNextThink);
            
            return HAM_SUPERCEDE;
        }
        else if(iSpriteType)
        {
            flFrame = 0.0;
            
            set_pev(pSprite, pev_frame, flFrame);
            set_pev(pSprite, pev_nextthink, flGameTime + flNextThink);
            
            return HAM_SUPERCEDE;
        }

        set_pev(pSprite, pev_flags, FL_KILLME);

    }

    return HAM_IGNORED;
}

public CEntity__Think_Pre(const pEntity)
{
    if(!IsPdataValid(pEntity))
        return HAM_IGNORED;

    new szClassname = pev(pEntity, pev_classname);
    // Never alter unrelated info_target entities belonging to other weapons.
    if(szClassname != gl_iszAllocString_EntityPassive && szClassname != gl_iszAllocString_EntityDummy && szClassname != gl_iszAllocString_EntityStatic) return HAM_IGNORED;
    if(pev(pEntity, pev_flags) & FL_KILLME) return HAM_SUPERCEDE;

    new Float:flGameTime = get_gametime();

    new pOwner = pev(pEntity, pev_owner);
    if(!is_user_alive(pOwner) || zp_get_user_zombie(pOwner)) {KillEntity(pEntity);return HAM_SUPERCEDE;}

    new Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    new Float:vecOwnerOrigin[3];
    pev(pOwner, pev_origin, vecOwnerOrigin);

    new pSkin = pev(pEntity, pev_skin);

    new Float:flNextThink;

    static Float:flLifetime;
    pev(pEntity, pev_ltime, flLifetime);


    if(szClassname == gl_iszAllocString_EntityPassive)
    {
        if(UTIL_DamageThinkReady(pEntity, 0.2))
            UTIL_RadiusDamage( pEntity, pOwner, vecOwnerOrigin, EXPLOSION_DAMAGE_RADIUS, EXPLOSION_DAMAGE_AMOUNT, 3.0, .flKnockBack = 350.0, .flKnockUp = 425.0, .flVelocityModifier = 0.75 );
        
        static Float:flChangeTime;
        pev(pEntity, pev_fuser2, flChangeTime);

        if(flGameTime >= flChangeTime)
        {
            if(pev(pEntity, pev_sequence) != ECLIPSE_SUMMON_B_IDLE_SEQ)
            {
                UTIL_SetEntityAnim(pEntity, ECLIPSE_SUMMON_B_IDLE_SEQ);

                static Float:flSpawned;
                pev(pEntity, pev_fuser3, flSpawned);

                if(flSpawned == 0.0)
                {
                    UTIL_CreateMuzzleFlash( pOwner, ENTITY_EXPLOSION_CLASSNAME, gl_iszAllocString_AttachMuzzle, ENTITY_MUZZLE_SPRITES[1], true, 0.04, 255.0, 1, 0.03, pEntity );

                    UTIL_CreateMuzzleFlash( pOwner, ENTITY_EXPLOSION_CLASSNAME, gl_iszAllocString_AttachMuzzle, ENTITY_MUZZLE_SPRITES[1], true, 0.04, 255.0, 2, 0.03, pEntity );

                    UTIL_CreateMuzzleFlash( pOwner, ENTITY_EXPLOSION_CLASSNAME, gl_iszAllocString_AttachMuzzle, ENTITY_MUZZLE_SPRITES[1], true, 0.04, 255.0, 3, 0.03, pEntity );

                    set_pev(pEntity, pev_fuser3, 1.0);
                }
            }
        }
        

        if(flLifetime <= flGameTime)
        {
            new Float:flAlpha;
            pev(pEntity, pev_renderamt, flAlpha);

            flAlpha -= 15.0;

            if(flAlpha <= 0.0)
            {
                UTIL_KillEntByOwner( pOwner, ENTITY_DUMMY_CLASSNAME );
                UTIL_KillEntByOwner( pOwner, ENTITY_ECLIPSE_PASSIVE_CLASSNAME );

                CreateDummyAnchor( pOwner );
                UTIL_KillMuzzleFlash( pOwner, true );

                return HAM_SUPERCEDE;
            }

            set_pev(pEntity, pev_renderamt, flAlpha);
            flNextThink = 0.02;

            set_pev(pEntity, pev_nextthink, flGameTime + flNextThink);
            return HAM_SUPERCEDE;
        }

        if(++pSkin == 61)
            pSkin = 32;

        flNextThink = 0.03;
    }

    if(szClassname == gl_iszAllocString_EntityDummy)
    {
        if(UTIL_DamageThinkReady(pEntity, 0.4))
            UTIL_RadiusDamage( pEntity, pOwner, vecOwnerOrigin, EXPLOSION_DAMAGE_RADIUS, EXPLOSION_DAMAGE_AMOUNT, 3.0 );
        
        flNextThink = 0.1;
    }

    if(szClassname == gl_iszAllocString_EntityStatic)
    {

        if(UTIL_DamageThinkReady(pEntity, 0.3))
            UTIL_RadiusDamage( pEntity, pOwner, vecOrigin, EXPLOSION_DAMAGE_RADIUS, EXPLOSION_DAMAGE_AMOUNT + 37.5, 4.5, 7 );
        
        if(flLifetime <= flGameTime)
        {
            new Float:flAlpha;
            pev(pEntity, pev_renderamt, flAlpha);

            flAlpha -= 15.0;

            if(flAlpha <= 0.0)
            {
                KillEntity(pEntity);
                UTIL_KillMuzzleFlash(pOwner, true);

                if(IsPlayerImmortal(pOwner))
                {
                    EclipseRestoreGravity(pOwner);
                    reset_bit(gl_iBitImmortal, pOwner);
                }
                
                return HAM_SUPERCEDE;
            }

            set_pev(pEntity, pev_renderamt, flAlpha);
            flNextThink = 0.02;

            set_pev(pEntity, pev_nextthink, flGameTime + flNextThink); 
            return HAM_SUPERCEDE;
        }

        if(++pSkin == 31)
            pSkin = 2;

        flNextThink = 0.05;
    }

    set_pev(pEntity, pev_skin, pSkin);
    set_pev(pEntity, pev_nextthink, flGameTime + flNextThink);

    return HAM_IGNORED;
}

/* -> Auto-precache sounds from model <- */
#if defined PrecacheSoundsFromModel
    stock UTIL_PrecacheSoundsFromModel( const szModelPath[] )
    {
        new pFile;
        if ( !( pFile = fopen( szModelPath, "rb" ) ) )
            return;

        new szSoundPath[64];
        new iNumSeq, iSeqIndex, iEvent, iNumEvents, iEventIndex;

        fseek( pFile, 164, SEEK_SET );
        fread( pFile, iNumSeq,   BLOCK_INT );
        fread( pFile, iSeqIndex, BLOCK_INT );

        for ( new i = 0; i < iNumSeq; i++ )
        {
            fseek( pFile, iSeqIndex + 48 + 176 * i, SEEK_SET );
            fread( pFile, iNumEvents,  BLOCK_INT );
            fread( pFile, iEventIndex, BLOCK_INT );
            fseek( pFile, iEventIndex + 176 * i, SEEK_SET );

            for ( new k = 0; k < iNumEvents; k++ )
            {
                fseek( pFile, iEventIndex + 4 + 76 * k, SEEK_SET );
                fread( pFile, iEvent, BLOCK_INT );
                fseek( pFile, 4, SEEK_CUR );

                if ( iEvent != 5004 ) continue;

                fread_blocks( pFile, szSoundPath, 64, BLOCK_CHAR );
                if ( strlen( szSoundPath ) )
                {
                    strtolower( szSoundPath );
                    #if AMXX_VERSION_NUM < 190
                        format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
                        precache_generic_ex( szSoundPath );
                    #else
                        precache_generic_ex( fmt( "sound/%s", szSoundPath ) );
                    #endif
                }
            }
        }

        fclose( pFile );
    }
#endif


// Stocks //
stock UTIL_CreateMuzzleFlash(const pPlayer, const szClassname[], const SzImpulse, const szMuzzleSprite[], const bool: iMuzzleLoop, const Float: flScale, const Float: flBrightness, const iAttachment,
Float: flNextThink, const Aiment ) {
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100) return FM_NULLENT;
        
    static pSprite, iszAllocStringCached;

    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    	pSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
        
    if(!IsPdataValid(pSprite)) return FM_NULLENT;
        
    set_pev(pSprite, pev_model, szMuzzleSprite);
    set_pev(pSprite, pev_spawnflags, SF_SPRITE_ONCE);
        
    set_pev(pSprite, pev_classname, szClassname);
    set_pev(pSprite, pev_impulse, SzImpulse);
    set_pev(pSprite, pev_owner, pPlayer);
    set_pev(pSprite, pev_fuser3, flNextThink);
    set_pev(pSprite, pev_iuser1, iMuzzleLoop);
    set_pev(pSprite, pev_aiment, Aiment);
    set_pev(pSprite, pev_body, iAttachment);

    set_pev(pSprite, pev_rendermode, kRenderTransAdd);
    set_pev(pSprite, pev_renderamt, flBrightness);

    set_pev(pSprite, pev_scale, flScale);
        
    dllfunc(DLLFunc_Spawn, pSprite)

    return pSprite;
}

stock UTIL_KillMuzzleFlash(const pPlayer, const bool:bKillExplosion)
{
    if(bKillExplosion)
        UTIL_KillEntByOwner( pPlayer, ENTITY_EXPLOSION_CLASSNAME );
    else
	    UTIL_KillEntByOwner( pPlayer, ENTITY_MUZZLE_CLASSNAME );
}

stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
    set_pev(pPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, pPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}

stock UTIL_WeaponList(const pPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, pPlayer);
    write_string(bEnabled ? PISTOL_WEAPONLIST : PISTOL_REFERENCE);
    write_byte(iPistolList[0]);
    write_byte(bEnabled ? MAX_BPAMMO : iPistolList[1]);
    write_byte( bEnabled ? WeaponSecondaryAmmoIndex   : -1 );
    write_byte( bEnabled ? CUSTOM_AMMO_MAX             : -1 );
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

/* ~ [ Entity ] ~ */
public Eclipse_Player_Model( pPlayer )
{
    new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);

    if(!iEntity) 
        return FM_NULLENT;

    set_pev_string(iEntity, pev_classname, gl_iszAllocString_PlayerModel);
    set_pev(iEntity, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(iEntity, pev_aiment, pPlayer);
    set_pev(iEntity, pev_owner, pPlayer);

    set_pev(iEntity, pev_body, 1);
    set_pev(iEntity, pev_sequence, 1);

    engfunc(EngFunc_SetModel, iEntity, PISTOL_MODEL_PLAYER_WORLD);

    return iEntity;
}

public CreateDummyAnchor(pPlayer)
{
    new pDummy = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
    
    if(!IsPdataValid(pDummy)) 
        return FM_NULLENT;
    
    set_pev_string(pDummy, pev_classname, gl_iszAllocString_EntityDummy);
    set_pev(pDummy, pev_owner, pPlayer);

    engfunc(EngFunc_SetModel, pDummy, "models/eclipse/null.mdl"); 
    
    set_pev(pDummy, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(pDummy, pev_aiment, pPlayer);
    set_pev(pDummy, pev_nextthink, get_gametime() + 0.1);
    set_pev(pDummy, pev_effects, pev(pDummy, pev_effects) | EF_FORCEVISIBILITY);    // ~x3 Arabas <3
    set_pev(pDummy, pev_rendermode, kRenderTransAdd);
    set_pev(pDummy, pev_renderamt, 255.0);

    new pNewEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
    
    if(!IsPdataValid(pNewEntity)) 
        return FM_NULLENT;

    if(IsPdataValid(pNewEntity))
    {
        set_pev_string(pNewEntity, pev_classname, gl_iszAllocString_EntityPassive);
        set_pev(pNewEntity, pev_owner, pPlayer);
        
        engfunc(EngFunc_SetModel, pNewEntity, ENTITY_ECLIPSE_GLOBAL);
        
        set_pev(pNewEntity, pev_body, ECLIPSE_PASSIVE_BODY);

        UTIL_SetEntityAnim( pNewEntity, ECLIPSE_PASSIVE_SEQ );
        set_pev(pNewEntity, pev_rendermode, kRenderTransAdd);
        set_pev(pNewEntity, pev_renderamt, 255.0);
        set_pev(pNewEntity, pev_skin, 2);

        set_pev(pNewEntity, pev_movetype, MOVETYPE_NOCLIP);
        set_pev(pNewEntity, pev_aiment, pDummy);

        set_pev(pNewEntity, pev_effects, pev(pNewEntity, pev_effects) | EF_FORCEVISIBILITY);
    }
    
    return pDummy;
}

public CreateStaticEntity( pPlayer )
{
    new pStaticEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);

    if(!IsPdataValid(pStaticEntity)) 
        return FM_NULLENT;

    set_pev_string(pStaticEntity, pev_classname, gl_iszAllocString_EntityStatic);
    set_pev(pStaticEntity, pev_owner, pPlayer);

    engfunc(EngFunc_SetModel, pStaticEntity, ENTITY_ECLIPSE_GLOBAL);

    set_pev(pStaticEntity, pev_body, ECLIPSE_SUMMON_A_BODY);
    UTIL_SetEntityAnim( pStaticEntity, ECLIPSE_SUMMON_A_IDLE_SEQ );

    set_pev(pStaticEntity, pev_movetype, MOVETYPE_NOCLIP);

    set_pev(pStaticEntity, pev_rendermode, kRenderTransAdd);
    set_pev(pStaticEntity, pev_renderamt, 255.0);

    set_pev(pStaticEntity, pev_skin, ECLIPSE_SUMMON__START_SKIN);

    new Float:VecPlayerPosition[3]
    pev(pPlayer, pev_origin, VecPlayerPosition);

    VecPlayerPosition[2] -= 1.0;

    engfunc(EngFunc_SetOrigin, pStaticEntity, VecPlayerPosition);
    set_pev(pStaticEntity, pev_ltime, get_gametime() + 4.02);
    set_pev(pStaticEntity, pev_nextthink, get_gametime() + 0.1);

    UTIL_CreateMuzzleFlash(pPlayer, ENTITY_EXPLOSION_CLASSNAME, gl_iszAllocString_AttachMuzzle, ENTITY_MUZZLE_SPRITES[1], true, 0.025, 255.0, 4, 0.03, pStaticEntity);       
    emit_sound(pPlayer, CHAN_WEAPON, PISTOL_SOUNDS[SHOOT_SOUND_B], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return pStaticEntity;
}

public CWeapon_ChargeAmmo(const pItem, const pPlayer, const iMaxAmmo, Float:flRate)
{
    if (get_gametime() < gl_fAmmoTimer[pPlayer])
        return;

    gl_fAmmoTimer[pPlayer] = get_gametime() + flRate; 

    // bp ammo
    new iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
    new iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);

    if (iAmmo < iMaxAmmo)
        set_pdata_int(pPlayer, iAmmoType, iAmmo + 1, linux_diff_player);

    // secondary ammo
    new iSecondaryAmmo = Weapon_GetSecondaryAmmo(pItem);
    if (iSecondaryAmmo < CUSTOM_AMMO_MAX)
        CWeapon_UpdateSecondaryAmmo(pItem, pPlayer, iSecondaryAmmo + 1);
}


stock UTIL_SetEntityAnim( pEnt, iSequence )  // xunicorn Dread nova
{
    set_pev( pEnt, pev_frame,     1.0            );
    set_pev( pEnt, pev_framerate, 1.0            );
    set_pev( pEnt, pev_animtime,  get_gametime() );
    set_pev( pEnt, pev_sequence,  iSequence      );
}



stock UTIL_KillEntByOwner(const pPlayer, const szClassname[])
{
    new pEnt = FM_NULLENT;

    while((pEnt = fm_find_ent_by_owner(pEnt, szClassname, pPlayer)) > 0)
        if(IsPdataValid(pEnt)) KillEntity(pEnt);
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

stock Weapon_DeductBpAmmo(pItem, pPlayer, pValue)
{
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
    static iAmmo; iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);
    
    set_pdata_int( pPlayer, iAmmoType, iAmmo - pValue, linux_diff_player );
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


/* ~ [ Weapon Ammo ] ~ */
stock Weapon_GetSecondaryAmmo( pItem )
{
    return pev( pItem, pev_secondary_ammo );
}

stock CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, iAmount )
{
    set_pev( pItem, pev_secondary_ammo, iAmount );
    set_pdata_int( pPlayer, m_rgAmmo + WeaponSecondaryAmmoIndex, iAmount, linux_diff_player );
}


/* ~ [ Custom Hud ] ~ */
stock SetHud( const pPlayer, const HudType )
{
    static iMsgID; 
    if ( !iMsgID ) 
        iMsgID = get_user_msgid( "HideWeapon" );

    message_begin( MSG_ONE, iMsgID, _, pPlayer );
    write_byte( HudType );
    message_end( );
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

/* -> TE_EXPLOSION <- */
stock UTIL_TE_EXPLOSION( const iDest, const iszModelIndex, const Float:vecOrigin[ 3 ], const Float: flUp, const iScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
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

stock DoDash(const pPlayer) {
    new Float:angles[3];
    new Float:vecForward[3];
    new Float:velocity[3];
    new Float:curVelocity[3];

    pev(pPlayer, pev_v_angle, angles);

    if(angles[0] < -DASH_PITCH_CLAMP)
        angles[0] = -DASH_PITCH_CLAMP;
    else if(angles[0] > DASH_PITCH_CLAMP)
        angles[0] = DASH_PITCH_CLAMP;

    engfunc(EngFunc_MakeVectors, angles);
    global_get(glb_v_forward, vecForward);

    pev(pPlayer, pev_velocity, curVelocity);

    new flags = pev(pPlayer, pev_flags);
    new bool:isAirborne = !(flags & FL_ONGROUND);


    vecForward[2] = 0.0;

    new Float:flLength = floatsqroot( vecForward[0] * vecForward[0] + vecForward[1] * vecForward[1] );

    if(flLength > 0.0) {
        vecForward[0] /= flLength;
        vecForward[1] /= flLength;
    }


    new Float:verticalLaunch = DASH_SPEED_V_MIN;

    if(angles[0] < 0.0) {
        new Float:pitchFactor = (-angles[0]) / DASH_PITCH_CLAMP;
        pitchFactor = floatsqroot(pitchFactor);

        verticalLaunch = DASH_SPEED_V_MIN + (DASH_SPEED_V_MAX - DASH_SPEED_V_MIN) * pitchFactor;
    }

    if(isAirborne) {
        velocity[0] = vecForward[0] * DASH_SPEED_H_GROUND;
        velocity[1] = vecForward[1] * DASH_SPEED_H_GROUND;

        velocity[2] = verticalLaunch;

        if(!IsPlayerImmortal(pPlayer))pev(pPlayer,pev_gravity,g_BeforeDashGravity[pPlayer]);
        set_pev(pPlayer, pev_gravity, 0.67); // 67🥀
    }
    else {
        velocity[0] = vecForward[0] * DASH_SPEED_H_GROUND;
        velocity[1] = vecForward[1] * DASH_SPEED_H_GROUND;
        velocity[2] = verticalLaunch;

        set_pev(pPlayer, pev_velocity, velocity);

        flags &= ~FL_ONGROUND;
        set_pev(pPlayer, pev_flags, flags);

        new Float:origin[3];
        pev(pPlayer, pev_origin, origin);
        origin[2] += 0.1;
        set_pev(pPlayer, pev_origin, origin);

        return;
    }

    set_pev(pPlayer, pev_velocity, velocity);
    set_bit(gl_iBitImmortal, pPlayer);
}

stock UTIL_RadiusDamage( const pEntity, const pAttacker, const Float:vecOrigin[3], const Float:flRadius, const Float:flDamage, const Float:flExplosionScale, const iExplosionFrames = 5, 
const iExplosionFramerate = 32, const Float:flKnockBack = 0.0, const Float:flKnockUp = 0.0, const Float:flVelocityModifier = 1.0) {

    if(!is_user_alive(pAttacker) || zp_get_user_zombie(pAttacker)) return;
    new pVictim = FM_NULLENT;
    while((pVictim = engfunc(EngFunc_FindEntityInSphere, pVictim, vecOrigin, flRadius))) {
        if(pVictim == pEntity)
            continue;

        if(!IsPdataValid(pVictim))
            continue;

        if(!is_user_alive(pVictim))
            continue;

        if(!zp_get_user_zombie(pVictim))
            continue;

        static Float:vecVictimOrigin[3];
        pev(pVictim, pev_origin, vecVictimOrigin);

        // Shared visual budget across overlapping fields; damage cadence is unchanged.
        if(g_NextVictimExplosion[pVictim] <= get_gametime())
        {
            g_NextVictimExplosion[pVictim] = get_gametime() + 0.25;
            UTIL_TE_EXPLOSION( MSG_PVS, gl_is_modelEIndexSprite, vecVictimOrigin, flExplosionScale, iExplosionFrames, iExplosionFramerate );
        }

        ExecuteHamB( Ham_TakeDamage, pVictim, pEntity, pAttacker, flDamage, DMG_BLAST );

        if(is_user_alive(pVictim) && zp_get_user_zombie(pVictim) && (flKnockBack > 0.0 || flKnockUp > 0.0))
            UTIL_PlayerKnockBack( pVictim, pAttacker, flKnockBack, flKnockUp, flVelocityModifier );
        
    }
}

stock bool:UTIL_DamageThinkReady(const pEntity, const Float:flDelay) {
    static Float:flNext;
    pev(pEntity, pev_fuser4, flNext);

    new Float:flTime = get_gametime();

    if(flTime < flNext)
        return false;

    set_pev(pEntity, pev_fuser4, flTime + flDelay);

    return true;
}


stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float:flHorizontal, const Float:flVertical = 0.0, const Float:flVelocityModifier = 1.0, const bool:bAddVertical = false ) {
    if(flHorizontal <= 0.0)
        return;

    new Float:vecVictimOrigin[3];
    new Float:vecAttackerOrigin[3];
    new Float:vecVelocity[3];
    new Float:vecDirection[3];

    pev(pVictim, pev_origin, vecVictimOrigin);
    pev(pAttacker, pev_origin, vecAttackerOrigin);
    pev(pVictim, pev_velocity, vecVelocity);

    xs_vec_sub(vecVictimOrigin, vecAttackerOrigin, vecDirection);

    vecDirection[2] = 0.0;

    new Float:flLength = floatsqroot( vecDirection[0] * vecDirection[0] + vecDirection[1] * vecDirection[1] );

    if(flLength <= 0.001)
        return;

    vecDirection[0] /= flLength;
    vecDirection[1] /= flLength;

    vecVelocity[0] = vecDirection[0] * flHorizontal;
    vecVelocity[1] = vecDirection[1] * flHorizontal;

    if(flVertical != 0.0) {
        if(bAddVertical)
            vecVelocity[2] += flVertical;
        else
            vecVelocity[2] = flVertical;
    }

    set_pev(pVictim, pev_velocity, vecVelocity);

    if(flVelocityModifier != 1.0)
        set_pdata_float( pVictim, m_flVelocityModifier, flVelocityModifier, linux_diff_player );
}


/* -> By Nordic Warrior (https://dev-cs.ru/threads/222/page-19#post-151804) <- */
stock precache_model_ex(const szFileName[], bool: bValvePath = false) 
{
	if(file_exists(szFileName, bValvePath))
		return engfunc(EngFunc_PrecacheModel, szFileName);

	set_fail_state("Model <%s> not found. The plugin has been stopped.", szFileName);

	return false;
}


stock precache_generic_ex(const szFileName[], bool: bValvePath = false) 
{
	if(file_exists(szFileName, bValvePath))
		return engfunc(EngFunc_PrecacheGeneric, szFileName);

	set_fail_state("Generic <%s> not found. The plugin has been stopped.", szFileName);

	return false;
}

stock EclipseRestoreGravity(id)
{
 if(!is_user_connected(id))return;
 new Float:current;pev(id,pev_gravity,current);
 // Restore only our temporary gravity; do not overwrite a newer class/ability setting.
 if(floatabs(current-0.67)<0.001)
 {
  new Float:restore=exhero_shop_jump_gravity(id);
  if(restore<=0.0)restore=g_BeforeDashGravity[id];
  if(restore<=0.0)restore=1.0;
  set_pev(id,pev_gravity,restore);
 }
 g_BeforeDashGravity[id]=0.0;
}
