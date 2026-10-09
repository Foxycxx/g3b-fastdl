/*
    Contact Discord : cristian505
    Discord Server (AMXX Workshop) : https://discord.gg/Ff9bts6He7
    YouTube : https://www.youtube.com/@amxxworkshop 
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>
#include <zombieplague>
native revo_get_user_hero(id);
native exhero_cluster_unlocked(id);

/* ~ [ Resources ] ~ */
new const gls_Grenade_View_Model[] = "models/g3bmodel/ZTHEX/v_splitbomb_fix4.mdl";
new const gls_Grenade_Player_Model[] = "models/Custom_Weapons/Cluster_Bomb/p_splitbomb.mdl";
new const gls_Grenade_World_Model[] = "models/Custom_Weapons/Cluster_Bomb/w_splitbomb.mdl";

new const gls_Rocket_Model[] = "models/Custom_Weapons/Cluster_Bomb/ef_splitbomb_trail01.mdl";

new const gls_Grenade_BeamFollow_Sprite[] = "sprites/Common/laserbeam.spr";
new const gls_Rocket_Smoke_Sprite[] = "sprites/Custom_Weapons/Cluster_Bomb/ef_splitbomb_hit1.spr";
new const gls_Rocket_Explosion_Sprite[] = "sprites/Custom_Weapons/Cluster_Bomb/ef_splitbomb_split01.spr";

new const glsg_Explosion_Sounds[][] = 
{
    "Custom_Weapons/Cluster_Bomb/splitbomb_exp1_fix.wav",
    "Custom_Weapons/Cluster_Bomb/splitbomb_exp2_1.wav",
    "Custom_Weapons/Cluster_Bomb/splitbomb_exp2_2.wav",
    "Custom_Weapons/Cluster_Bomb/splitbomb_exp2_3.wav",
}

#define df_Grenade_WeaponList // Comment this to disable custom weaponlist.

#if defined df_Grenade_WeaponList
    new const glsg_Grenade_WeaponList_Resources[][] = 
    {
        "sprites/Common/640hud273.spr"
    };
    // Make sure to list every sprite the weaponlist requires.

    new const gls_Grenade_WeaponList[] = "Custom_Weapons/Cluster_Bomb/weapon_splitbomb"; // "sprites/*INSERT_WEAPONLIST_PATH_HERE*" 
#endif

#define df_Precache_View_Model_Sounds // Comment this if 'sv_auto_precache_sounds_in_models' is on.

#if defined df_Precache_View_Model_Sounds
    new const glsg_Grenade_View_Model_Sounds[][] = 
    {
        "sound/Custom_Weapons/Cluster_Bomb/splitbomb_draw.wav",
        "sound/Custom_Weapons/Cluster_Bomb/splitbomb_hold_fix2.wav",
        "sound/Custom_Weapons/Cluster_Bomb/splitbomb_throw.wav",
        "sound/Custom_Weapons/Cluster_Bomb/splitbomb_touch_fix2.wav"
    };
#endif

/* ~ [ Settings ] ~ */
// Grenade
new const gls_Grenade_Reference[] = "weapon_hegrenade";

const gli_Grenade_Unique_Index = 29314;

const gli_Grenade_Max_Ammo = 3;

enum 
{
    gli_GrenadeAnim_Idle = 0,
    gli_GrenadeAnim_Touch,
    gli_GrenadeAnim_Throw,
    gli_GrenadeAnim_Draw,
    gli_GrenadeAnim_Hold
}

const Float: glf_GrenadeAnim_Idle_Time = 2.03;
const Float: glf_GrenadeAnim_Touch_Time = 1.36;
const Float: glf_GrenadeAnim_Throw_Time = 0.86;
const Float: glf_GrenadeAnim_DrawHold_Time = 1.03;

const Float: glf_Real_GrenadeAnim_Touch_Time = 0.8;
const Float: glf_Real_GrenadeAnim_Throw_Time = 0.55;
const Float: glf_Real_GrenadeAnim_Draw_Time = 0.9;

#if defined df_Grenade_WeaponList
    new const glig_Grenade_WeaponList_Coords[] = { 12, 1, -1, -1, 3, 1, 4, 24 }; 
    // https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
#endif 

// Entity : Cluster Bomb
new const gls_ClusterBomb_Classname[] = "ent_cluster_bomb";

const gli_ClusterBomb_MaxRockets = 7;

const Float: glf_ClusterBomb_Spawn_Forward_Distance = 10.0; // Distance from player
const Float: glf_ClusterBomb_Fly_Speed = 150.0;
const Float: glf_ClusterBomb_Gravity = 0.5;
const Float: glf_ClusterBomb_NextThink = 0.1;
const Float: glf_ClusterBomb_Damage_Knockback_Radius = 210.0;
const Float: glf_ClusterBomb_Damage = 140.0;
const Float: glf_ClusterBomb_Knockback_Strenght = 500.0;

// Entity : Rocket
new const Float: glfg_Rocket_Gravity_Randomness[] = {2.3, 3.5};
new const Float: glfg_Rocket_Spawn_Find_Target_Time_Randomness[] = {0.1, 0.2};

new const gls_Rocket_Classname[] = "ent_cluster_bomb_rocket";

const Float: glf_Rocket_NextThink = 0.1;
const Float: glf_Rocket_Target_Origin_Distance = 300.0;
const Float: glf_Rocket_Fly_Speed_To_Target_Origin = 800.0; // Spawn Target Origin (not alive target)
const Float: glf_Rocket_Target_Detect_Radius = 665.0;
const Float: glf_Rocket_Fly_Speed_To_Target = 1650.0;
const Float: glf_Rocket_Damage_Knockback_Radius = 270.0;
const Float: glf_Rocket_Damage = 60.0;
const Float: glf_Rocket_Knockback_Strenght = 215.0;

/* ~ [ Globals ] ~ */
new gliv_SpriteIndex_LaserBeam,
    gliv_SpriteIndex_RocketSmoke,
    gliv_SpriteIndex_RocketExplosion;

/* ~ [ AMX Mod X ] ~ */
public plugin_natives(){
 register_native("exhero_give_cluster","NativeGive");
 register_native("exhero_cluster_double_ammo","NativeDouble");
}
public NativeGive(plugin,argc){return Give_Player_Custom_Grenade(get_param(1));}
public NativeDouble(plugin,argc){
 new id=get_param(1);if(!is_user_alive(id))return false;
 new item=UTIL_GetItemByName(id,gls_Grenade_Reference);
 if(is_nullent(item)||get_entvar(item,var_impulse)!=gli_Grenade_Unique_Index)return false;
 new at=get_member(item,m_Weapon_iPrimaryAmmoType), n=get_member(id,m_rgAmmo,at);
 if(n<gli_Grenade_Max_Ammo)set_member(id,m_rgAmmo,n+1,at);
 return true;
}
public ClusterCleanup(id){
 new e=-1;
 while((e=engfunc(EngFunc_FindEntityByString,e,"classname",gls_ClusterBomb_Classname))>0)
  if(get_entvar(e,var_owner)==id)set_entvar(e,var_flags,get_entvar(e,var_flags)|FL_KILLME);
 e=-1;
 while((e=engfunc(EngFunc_FindEntityByString,e,"classname",gls_Rocket_Classname))>0)
  if(get_entvar(e,var_owner)==id)set_entvar(e,var_flags,get_entvar(e,var_flags)|FL_KILLME);
}
public client_disconnected(id){ClusterCleanup(id);}
public zp_user_infected_pre(id){ClusterCleanup(id);}
public ClusterKilled(id){ClusterCleanup(id);}
stock bool:ClusterValid(e){
 if(is_nullent(e))return false;
 new id=get_entvar(e,var_owner);
 if((get_entvar(e,var_flags)&FL_KILLME)||!is_user_alive(id)||zp_get_user_zombie(id)||get_entvar(e,var_fuser4)<=get_gametime()){
  set_entvar(e,var_flags,get_entvar(e,var_flags)|FL_KILLME);return false;
 }
 return true;
}
public ClusterFlightThink(e){if(ClusterValid(e))set_entvar(e,var_nextthink,get_gametime()+0.1);}
public ClusterAddPre(item,id){
 if(get_entvar(item,var_impulse)==gli_Grenade_Unique_Index && (!is_user_alive(id)||zp_get_user_zombie(id)||revo_get_user_hero(id)||!exhero_cluster_unlocked(id))){SetHamReturnInteger(0);return HAM_SUPERCEDE;}
 return HAM_IGNORED;
}
public plugin_init()
{
    register_plugin("[Custom Grenade] Cluster Bomb", "2.0", "Cristian505");

    RegisterHam(Ham_Killed,"player","ClusterKilled",false);
    RegisterHam(Ham_Item_AddToPlayer,gls_Grenade_Reference,"ClusterAddPre",false);
    // Hamsandwich
    RegisterHam(Ham_Weapon_PrimaryAttack,   gls_Grenade_Reference,   "Ham_Grenade_PrimaryAttack_Pre",   false);
    RegisterHam(Ham_Item_PostFrame,         gls_Grenade_Reference,   "Ham_Grenade_PostFrame_Pre",       false);
    RegisterHam(Ham_Item_Holster,           gls_Grenade_Reference,   "Ham_Grenade_Holster_Post",         true);
    RegisterHam(Ham_Weapon_WeaponIdle,      gls_Grenade_Reference,   "Ham_Grenade_Idle_Pre",            false);

    #if defined df_Grenade_WeaponList
        RegisterHam(Ham_Item_AddToPlayer, gls_Grenade_Reference, "Ham_Grenade_AddToPlayer_Post", true);
    #endif

    // ReAPI
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "RG_Weapon_DefaultDeploy_Post", true);
    RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CleanUp_Map_Post", true);

    // Fakemeta
    register_forward(FM_UpdateClientData, "FM_UpdateClientData_Post", true);

    // Client Commands


    #if defined df_Grenade_WeaponList
        register_clcmd(gls_Grenade_WeaponList, "ClientCommand_Hook_Grenade");
    #endif
}

public plugin_precache()
{
    precache_generic("sound/Custom_Weapons/Cluster_Bomb/splitbomb_draw.wav");
    precache_generic("sound/Custom_Weapons/Cluster_Bomb/splitbomb_hold_fix2.wav");
    precache_generic("sound/Custom_Weapons/Cluster_Bomb/splitbomb_throw.wav");
    precache_generic("sound/Custom_Weapons/Cluster_Bomb/splitbomb_touch_fix2.wav");

    // Models
    SafePrecache_Model(gls_Grenade_View_Model);
    SafePrecache_Model(gls_Grenade_Player_Model);
    SafePrecache_Model(gls_Grenade_World_Model);
    SafePrecache_Model(gls_Rocket_Model);

    // Sprites
    gliv_SpriteIndex_LaserBeam = SafePrecache_Model(gls_Grenade_BeamFollow_Sprite);
    gliv_SpriteIndex_RocketSmoke = SafePrecache_Model(gls_Rocket_Smoke_Sprite);
    gliv_SpriteIndex_RocketExplosion = SafePrecache_Model(gls_Rocket_Explosion_Sprite);

    // Sounds
    for(new i = 0; i < sizeof glsg_Explosion_Sounds; i++)
    {
        SafePrecache_Sound(glsg_Explosion_Sounds[i]);
    }

    // Generic
    #if defined df_Grenade_WeaponList
        new szWeaponListPath[128]; formatex(szWeaponListPath, charsmax(szWeaponListPath), "sprites/%s.txt", gls_Grenade_WeaponList);

        SafePrecache_Generic(szWeaponListPath);

        for(new i = 0; i < sizeof glsg_Grenade_WeaponList_Resources; i++)
        {
            SafePrecache_Generic(glsg_Grenade_WeaponList_Resources[i]);
        }
    #endif

    #if defined df_Precache_View_Model_Sounds
        for(new i = 0; i < sizeof glsg_Grenade_View_Model_Sounds; i++)
        {
            SafePrecache_Generic(glsg_Grenade_View_Model_Sounds[i]);
        }
    #endif
}

/* ~ [ Hamsandwich ] ~ */
public Ham_Grenade_PrimaryAttack_Pre(iGrenade)
{
    if(!is_nullent(iGrenade) && get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index)
    {
        new iPlayer = get_member(iGrenade, m_pPlayer);

        new iGrenadeState = get_entvar(iGrenade, var_iuser1);

        if(!iGrenadeState)
        {
            iGrenadeState++;

            set_entvar(iGrenade, var_iuser1, iGrenadeState);

            UTIL_SendWeaponAnim(gli_GrenadeAnim_Touch, iPlayer, MSG_ONE, MSG_ONE_UNRELIABLE);

            set_member(iPlayer, m_flNextAttack, glf_Real_GrenadeAnim_Touch_Time);
            set_member(iGrenade, m_Weapon_flNextPrimaryAttack, glf_Real_GrenadeAnim_Touch_Time);
            set_member(iGrenade, m_Weapon_flNextSecondaryAttack, glf_GrenadeAnim_Touch_Time);
            set_member(iGrenade, m_Weapon_flTimeWeaponIdle, glf_GrenadeAnim_Touch_Time);
        }
        else if(iGrenadeState == 1 && get_member(iGrenade, m_Weapon_flNextSecondaryAttack) <= 0.0)
        {
            UTIL_SendWeaponAnim(gli_GrenadeAnim_Hold, iPlayer, MSG_ONE, MSG_ONE_UNRELIABLE);

            set_member(iGrenade, m_Weapon_flNextPrimaryAttack, glf_GrenadeAnim_DrawHold_Time);
            set_member(iGrenade, m_Weapon_flNextSecondaryAttack, glf_GrenadeAnim_DrawHold_Time);
            set_member(iGrenade, m_Weapon_flTimeWeaponIdle, glf_GrenadeAnim_DrawHold_Time);
        }
        else if(iGrenadeState == 2)
        {
            new iAmmoType = get_member(iGrenade, m_Weapon_iPrimaryAmmoType);
            new iAmmo = get_member(iPlayer, m_rgAmmo, iAmmoType);

            if(!iAmmo)
            {
                UTIL_StripWeaponByIndex(iPlayer, iGrenade);
                    
                return HAM_SUPERCEDE;
            }

            iGrenadeState = 0;

            set_entvar(iGrenade, var_iuser1, iGrenadeState);
        }

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public Ham_Grenade_PostFrame_Pre(iGrenade)
{
    if(!is_nullent(iGrenade) && get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index)
    {   
        new iPlayer = get_member(iGrenade, m_pPlayer);

        new iButton = get_entvar(iPlayer, var_button);

        new iGrenadeState = get_entvar(iGrenade, var_iuser1);

        if(iGrenadeState && !(iButton & IN_ATTACK))
        {
            new iAmmoType = get_member(iGrenade, m_Weapon_iPrimaryAmmoType);
            new iAmmo = get_member(iPlayer, m_rgAmmo, iAmmoType);

            if(iGrenadeState == 1)
            {
                Throw_Grenade(iPlayer);

                iGrenadeState++;

                set_entvar(iGrenade, var_iuser1, iGrenadeState);

                iAmmo--;

                set_member(iPlayer, m_rgAmmo, iAmmo, iAmmoType);

                UTIL_SendWeaponAnim(gli_GrenadeAnim_Throw, iPlayer, MSG_ONE, MSG_ONE_UNRELIABLE);

                set_member(iPlayer, m_flNextAttack, glf_Real_GrenadeAnim_Throw_Time);
                set_member(iGrenade, m_Weapon_flNextPrimaryAttack, glf_Real_GrenadeAnim_Throw_Time);
                set_member(iGrenade, m_Weapon_flNextSecondaryAttack, glf_GrenadeAnim_Throw_Time);
                set_member(iGrenade, m_Weapon_flTimeWeaponIdle, glf_GrenadeAnim_Throw_Time);
            }
            else if(get_member(iGrenade, m_Weapon_flNextSecondaryAttack) <= 0.0)
            {
                if(!iAmmo)
                {
                    UTIL_StripWeaponByIndex(iPlayer, iGrenade);
                    
                    return HAM_SUPERCEDE;
                }

                iGrenadeState = 0;

                set_entvar(iGrenade, var_iuser1, iGrenadeState);

                ExecuteHamB(Ham_Item_Deploy, iGrenade);
            }
        }
    }

    return HAM_IGNORED;
}

public Ham_Grenade_Holster_Post(iGrenade)
{
    if(!is_nullent(iGrenade) && get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index)
    {
        set_member(get_member(iGrenade, m_pPlayer), m_flNextAttack, 0.0);

        set_member(iGrenade, m_Weapon_flNextPrimaryAttack, 0.0);
        set_member(iGrenade, m_Weapon_flNextSecondaryAttack, 0.0);
        set_member(iGrenade, m_Weapon_flTimeWeaponIdle, 0.0);

        // Primary Attack Anim State
        set_entvar(iGrenade, var_iuser1, 0);
    }
}

public Ham_Grenade_Idle_Pre(iGrenade)
{
    if(!is_nullent(iGrenade) && get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index && get_member(iGrenade, m_Weapon_flTimeWeaponIdle) <= 0.0)
    {
        UTIL_SendWeaponAnim(gli_GrenadeAnim_Idle, get_member(iGrenade, m_pPlayer), MSG_ONE, MSG_ONE_UNRELIABLE);

        set_member(iGrenade, m_Weapon_flTimeWeaponIdle, glf_GrenadeAnim_Idle_Time);

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

#if defined df_Grenade_WeaponList
    public Ham_Grenade_AddToPlayer_Post(iGrenade, iPlayer)
    {
        if(!is_nullent(iGrenade))
        {
            if(get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index)
            {
                UTIL_WeaponList(MSG_ONE, iPlayer, gls_Grenade_WeaponList, glig_Grenade_WeaponList_Coords[0], glig_Grenade_WeaponList_Coords[1], glig_Grenade_WeaponList_Coords[2], glig_Grenade_WeaponList_Coords[3], glig_Grenade_WeaponList_Coords[4], glig_Grenade_WeaponList_Coords[5], glig_Grenade_WeaponList_Coords[6], glig_Grenade_WeaponList_Coords[7]);
            }
            else 
            {
                new szWeaponName[MAX_NAME_LENGTH]; rg_get_iteminfo(iGrenade, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

                UTIL_WeaponList(MSG_ONE, iPlayer, szWeaponName, get_member(iGrenade, m_Weapon_iPrimaryAmmoType), rg_get_iteminfo(iGrenade, ItemInfo_iMaxAmmo1), get_member(iGrenade, m_Weapon_iSecondaryAmmoType), rg_get_iteminfo(iGrenade, ItemInfo_iMaxAmmo2), rg_get_iteminfo(iGrenade, ItemInfo_iSlot), rg_get_iteminfo(iGrenade, ItemInfo_iPosition), rg_get_iteminfo(iGrenade, ItemInfo_iId), rg_get_iteminfo(iGrenade, ItemInfo_iFlags));
            }
        }
    }
#endif

/* ~ [ ReAPI ] ~ */
public RG_Weapon_DefaultDeploy_Post(iGrenade)
{
    if(!is_nullent(iGrenade) && get_entvar(iGrenade, var_impulse) == gli_Grenade_Unique_Index)
    {
        new iPlayer = get_member(iGrenade, m_pPlayer);

        set_entvar(iPlayer, var_viewmodel, gls_Grenade_View_Model);
        set_entvar(iPlayer, var_weaponmodel, gls_Grenade_Player_Model);

        set_member(iPlayer, m_flNextAttack, glf_Real_GrenadeAnim_Draw_Time);
        set_member(iGrenade, m_Weapon_flTimeWeaponIdle, glf_GrenadeAnim_DrawHold_Time);
    }
}

public RG_CleanUp_Map_Post()
{
    new iClusterBomb = NULLENT;

    while((iClusterBomb = engfunc(EngFunc_FindEntityByString, iClusterBomb, "classname", gls_ClusterBomb_Classname)) > 0)
    {
        if(!is_nullent(iClusterBomb))
        {
            rg_remove_entity(iClusterBomb);
        }
    }

    new iRocket = NULLENT;

    while((iRocket = engfunc(EngFunc_FindEntityByString, iRocket, "classname", gls_Rocket_Classname)) > 0)
    {
        if(!is_nullent(iRocket))
        {
            rg_remove_entity(iRocket);
        }
    }
}

public RG_Entity_ClusterBomb_Touch(iEntity, iTouch)
{
    if(!ClusterValid(iEntity)) return;
    if(!is_nullent(iEntity) && rg_classname_is(iEntity, gls_ClusterBomb_Classname) && !is_user_alive(iTouch) && !rg_classname_is(iTouch, gls_ClusterBomb_Classname) && !rg_classname_is(iTouch, gls_Rocket_Classname))
    {
        new Float: vecEntityOrigin[3]; get_entvar(iEntity, var_origin, vecEntityOrigin);

        if(engfunc(EngFunc_PointContents, vecEntityOrigin) != CONTENTS_SKY)
        {
            SetTouch(iEntity, "");
            set_entvar(iEntity,var_solid,SOLID_NOT);
            new iOwner = get_entvar(iEntity, var_owner);

            new iEnemy = NULLENT;

            while((iEnemy = engfunc(EngFunc_FindEntityInSphere, iEnemy, vecEntityOrigin, glf_ClusterBomb_Damage_Knockback_Radius)) > 0)
            {
                if(is_user_alive(iEnemy) && zp_get_user_zombie(iEnemy))
                {
                    ExecuteHamB(Ham_TakeDamage, iEnemy, iEntity, iOwner, glf_ClusterBomb_Damage, DMG_BLAST);

                    if(!is_user_alive(iEnemy) || !zp_get_user_zombie(iEnemy)) continue;
                    UTIL_Knockback(iEnemy, vecEntityOrigin, glf_ClusterBomb_Knockback_Strenght, 1.0);
                    UTIL_ScreenShake(iEnemy, MSG_ONE_UNRELIABLE, random_num(150, 200), random_num(2, 4), random_num(5, 15));
                }
            }

            new Float: vecNormal[3]; global_get(glb_trace_plane_normal, vecNormal);

            new Float: vecFixedOrigin[3];

            vecFixedOrigin[0] = vecEntityOrigin[0] + vecNormal[0] * 5.0;
            vecFixedOrigin[1] = vecEntityOrigin[1] + vecNormal[1] * 5.0;
            vecFixedOrigin[2] = vecEntityOrigin[2] + vecNormal[2] * 5.0;

            set_entvar(iEntity, var_origin, vecFixedOrigin);

            new Float: vecTargetOrigin[3];

            vecTargetOrigin[0] = vecFixedOrigin[0] + vecNormal[0] * glf_Rocket_Target_Origin_Distance;
            vecTargetOrigin[1] = vecFixedOrigin[1] + vecNormal[1] * glf_Rocket_Target_Origin_Distance;
            vecTargetOrigin[2] = vecFixedOrigin[2] + vecNormal[2] * glf_Rocket_Target_Origin_Distance;

            set_entvar(iEntity, var_vuser1, vecTargetOrigin);
            set_entvar(iEntity, var_nextthink, get_gametime());
            set_entvar(iEntity, var_movetype, MOVETYPE_NONE);

            SetThink(iEntity, "RG_Entity_ClusterBomb_Think");

            rh_emit_sound2(iEntity, 0, CHAN_AUTO, glsg_Explosion_Sounds[0]);

            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEntityOrigin, 0);
            write_byte(TE_EXPLOSION);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[0]);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[1]);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[2] + 120.6);
            write_short(gliv_SpriteIndex_RocketSmoke);
            write_byte(random_num(12, 16));
            write_byte(random_num(10, 14));
            write_byte(TE_EXPLFLAG_NOSOUND);
            message_end();

            UTIL_SetEntityAnim(iEntity, 0);
        }
        else 
        {
            rg_remove_entity(iEntity);
        }
    }
}

public RG_Entity_ClusterBomb_Think(iEntity)
{
    if(!ClusterValid(iEntity)) return;
    if(!is_nullent(iEntity) && rg_classname_is(iEntity, gls_ClusterBomb_Classname))
    {
        new iRockets_Count = get_entvar(iEntity, var_iuser1);

        if(iRockets_Count < gli_ClusterBomb_MaxRockets)
        {
            new Float: vecTargetOrigin[3]; get_entvar(iEntity, var_vuser1, vecTargetOrigin);

            vecTargetOrigin[0] += random_float(-200.0, 200.0);
            vecTargetOrigin[1] += random_float(-200.0, 200.0);
            vecTargetOrigin[2] += random_float(-30.0, 120.0);

            new Float: vecEntityOrigin[3]; get_entvar(iEntity, var_origin, vecEntityOrigin);

            Create_Rocket(get_entvar(iEntity, var_owner), vecEntityOrigin, vecTargetOrigin);

            iRockets_Count++;

            set_entvar(iEntity, var_iuser1, iRockets_Count);

            new Float: flGameTime = get_gametime();

            set_entvar(iEntity, var_nextthink, flGameTime + glf_ClusterBomb_NextThink);

            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEntityOrigin, 0);
            write_byte(TE_SPARKS);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[0]);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[1]);
            engfunc(EngFunc_WriteCoord, vecEntityOrigin[2]);
            message_end();

            if(iRockets_Count >= gli_ClusterBomb_MaxRockets)
            {
                rg_remove_entity(iEntity);
            }
        }
    }
}

public RG_Entity_Rocket_Touch(iEntity, iTouch)
{
    if(!ClusterValid(iEntity)) return;
    if(!is_nullent(iEntity) && rg_classname_is(iEntity, gls_Rocket_Classname) && !rg_classname_is(iTouch, gls_ClusterBomb_Classname) && !rg_classname_is(iTouch, gls_Rocket_Classname))
    {
        new Float: vecEntityOrigin[3]; get_entvar(iEntity, var_origin, vecEntityOrigin);

        if(engfunc(EngFunc_PointContents, vecEntityOrigin) != CONTENTS_SKY)
        {
            new iOwner = get_entvar(iEntity, var_owner);

            if(!is_user_alive(iTouch) || is_user_alive(iTouch) && zp_get_user_zombie(iTouch))
            {
                SetTouch(iEntity, "");
                set_entvar(iEntity,var_solid,SOLID_NOT);
                SetThink(iEntity, "");
                set_entvar(iEntity,var_flags,get_entvar(iEntity,var_flags)|FL_KILLME);
                new iEnemy = NULLENT;

                while((iEnemy = engfunc(EngFunc_FindEntityInSphere, iEnemy, vecEntityOrigin, glf_Rocket_Damage_Knockback_Radius)) > 0)
                {
                    if(is_user_alive(iEnemy) && zp_get_user_zombie(iEnemy))
                    {
                        ExecuteHamB(Ham_TakeDamage, iEnemy, iEntity, iOwner, glf_Rocket_Damage, DMG_BLAST);

                        if(!is_user_alive(iEnemy) || !zp_get_user_zombie(iEnemy)) continue;
                    UTIL_Knockback(iEnemy, vecEntityOrigin, glf_Rocket_Knockback_Strenght, 1.0);
                        UTIL_ScreenShake(iEnemy, MSG_ONE_UNRELIABLE, random_num(150, 200), random_num(2, 4), random_num(5, 15));
                    }
                }

                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEntityOrigin, 0);
                write_byte(TE_EXPLOSION);
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[0] + random_float(-25.0, 25.0));
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[1] + random_float(-25.0, 25.0));
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[2] + random_float(-10.0, 25.0));
                write_short(gliv_SpriteIndex_RocketExplosion);
                write_byte(random_num(15, 22));
                write_byte(random_num(24, 29));
                write_byte(TE_EXPLFLAG_NOSOUND);
                message_end();

                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEntityOrigin, 0);
                write_byte(TE_EXPLOSION);
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[0] + random_float(-80.0, 80.0));
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[1] + random_float(-80.0, 80.0));
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[2] + 78.0);
                write_short(gliv_SpriteIndex_RocketSmoke);
                write_byte(random_num(7, 10));
                write_byte(random_num(12, 17));
                write_byte(TE_EXPLFLAG_NOSOUND);
                message_end();

                rh_emit_sound2(iEntity, 0, CHAN_AUTO, glsg_Explosion_Sounds[random_num(1, charsmax(glsg_Explosion_Sounds))]);

                rg_remove_entity(iEntity);
            }
        }
        else 
        {
            rg_remove_entity(iEntity);
        }
    }
}

public RG_Entity_Rocket_Think(iEntity)
{
    if(!ClusterValid(iEntity)) return;
    if(!is_nullent(iEntity) && rg_classname_is(iEntity, gls_Rocket_Classname))
    {
        new iState = get_entvar(iEntity, var_iuser1);

        if(!iState)
        {
            new Float: vecVelocity[3]; get_entvar(iEntity, var_velocity, vecVelocity);

            new Float: vecAngles[3]; vector_to_angle(vecVelocity, vecAngles);

            set_entvar(iEntity, var_angles, vecAngles);

            new Float: flStartVelocity_Time = get_entvar(iEntity, var_fuser1);

            new Float: flGameTime = get_gametime();

            if(flGameTime < flStartVelocity_Time)
            {
                set_entvar(iEntity, var_nextthink, flGameTime + glf_Rocket_NextThink);
            }
            else 
            {
                iState++;

                set_entvar(iEntity, var_iuser1, iState);

                set_entvar(iEntity, var_nextthink, flGameTime);
            }
        }
        else if(iState == 1)
        {
            new Float: vecEntityOrigin[3]; get_entvar(iEntity, var_origin, vecEntityOrigin);

            new Float: flClosestDistance = 999999.0;


            new iEnemy = NULLENT;
            new iClosestEnemy = NULLENT;

            while((iEnemy = engfunc(EngFunc_FindEntityInSphere, iEnemy, vecEntityOrigin, glf_Rocket_Target_Detect_Radius)) > 0)
            {
                if(is_user_alive(iEnemy) && zp_get_user_zombie(iEnemy) && UTIL_IsNoSolidBetweenPoints(iEnemy, vecEntityOrigin))
                {
                    new Float: vecEnemyOrigin[3]; get_entvar(iEnemy, var_origin, vecEnemyOrigin);

                    new Float: flDistance = xs_vec_distance(vecEnemyOrigin, vecEntityOrigin);

                    if(flDistance < flClosestDistance)
                    {
                        flClosestDistance = flDistance;
                        iClosestEnemy = iEnemy;
                    }
                }
            }

            if(iClosestEnemy != NULLENT)
            {
                set_entvar(iEntity, var_gravity, -0.000001);

                // Set Velocity
                new Float: vecClosestEnemyOrigin[3]; get_entvar(iClosestEnemy, var_origin, vecClosestEnemyOrigin);

                new Float: vecVelocity[3]; xs_vec_sub(vecClosestEnemyOrigin, vecEntityOrigin, vecVelocity);

                ClusterNormalize(vecVelocity);
                xs_vec_mul_scalar(vecVelocity, glf_Rocket_Fly_Speed_To_Target, vecVelocity);

                set_entvar(iEntity, var_velocity, vecVelocity);

                iState++;

                set_entvar(iEntity, var_iuser1, iState);

                set_entvar(iEntity, var_rendermode, kRenderTransAdd);
                set_entvar(iEntity, var_renderamt, 255.0);

                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEntityOrigin, 0);
                write_byte(TE_SPARKS);
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[0]);
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[1]);
                engfunc(EngFunc_WriteCoord, vecEntityOrigin[2]);
                message_end();
            }

            new Float: vecVelocity[3]; get_entvar(iEntity, var_velocity, vecVelocity);

            new Float: vecAngles[3]; vector_to_angle(vecVelocity, vecAngles);

            set_entvar(iEntity, var_angles, vecAngles);

            new Float: flGameTime = get_gametime();

            set_entvar(iEntity, var_nextthink, flGameTime + glf_Rocket_NextThink);
        }
        else {set_entvar(iEntity,var_nextthink,get_gametime()+glf_Rocket_NextThink);}
    }
}

/* ~ [ Fakemeta ] ~ */
public FM_UpdateClientData_Post(iPlayer, iSendWeapons, iClientData)
{
    if(is_user_alive(iPlayer))
    {
        static iActiveItem; iActiveItem = get_member(iPlayer, m_pActiveItem);
        
        if(!is_nullent(iActiveItem) && get_entvar(iActiveItem, var_impulse) == gli_Grenade_Unique_Index)
        {
            set_cd(iClientData, CD_flNextAttack, 2.0);
        }
    }
}

/* ~ [ Client Commands ] ~ */
public ClientCommand_Give_Player_Grenade(iPlayer)
{
    Give_Player_Custom_Grenade(iPlayer);
}

#if defined df_Grenade_WeaponList
    public ClientCommand_Hook_Grenade(iPlayer) 
    {
        engclient_cmd(iPlayer, gls_Grenade_Reference);

        return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Custom Functions ] ~ */
public Give_Player_Custom_Grenade(iPlayer)
{
 if(!is_user_alive(iPlayer)||zp_get_user_zombie(iPlayer)||revo_get_user_hero(iPlayer)||!exhero_cluster_unlocked(iPlayer))return false;
 new titan=UTIL_GetItemByName(iPlayer,"weapon_tmp");
 if(!is_nullent(titan)&&get_entvar(titan,var_impulse)==15062022)return false;
 new item=UTIL_GetItemByName(iPlayer,gls_Grenade_Reference);
 if(!is_nullent(item)) {
  if(get_entvar(item,var_impulse)==gli_Grenade_Unique_Index)return false;
  if(!UTIL_StripWeaponByIndex(iPlayer,item))return false;
 }
 item=rg_give_custom_item(iPlayer,gls_Grenade_Reference,GT_APPEND,gli_Grenade_Unique_Index);
 if(is_nullent(item))return false;
 set_member(iPlayer,m_rgAmmo,1,get_member(item,m_Weapon_iPrimaryAmmoType));
 return true;
}

public Throw_Grenade(iPlayer)
{
    if(!is_user_alive(iPlayer)||zp_get_user_zombie(iPlayer))return;
    new iClusterBomb = rg_create_entity("info_target");

    if(!is_nullent(iClusterBomb))
    {
        set_entvar(iClusterBomb, var_classname, gls_ClusterBomb_Classname);
        set_entvar(iClusterBomb, var_owner, iPlayer);
        set_entvar(iClusterBomb, var_solid, SOLID_TRIGGER);
        set_entvar(iClusterBomb, var_movetype, MOVETYPE_TOSS);
        set_entvar(iClusterBomb, var_owner, iPlayer);

        new Float: vecPlayerViewAngles[3]; get_entvar(iPlayer, var_v_angle, vecPlayerViewAngles);

        new Float: vecPlayerViewForward[3]; angle_vector(vecPlayerViewAngles, ANGLEVECTOR_FORWARD, vecPlayerViewForward);

        xs_vec_mul_scalar(vecPlayerViewForward, glf_ClusterBomb_Spawn_Forward_Distance, vecPlayerViewForward);

        new Float: vecPlayerViewOfs[3]; get_entvar(iPlayer, var_view_ofs, vecPlayerViewOfs);

        xs_vec_add(vecPlayerViewOfs, vecPlayerViewForward, vecPlayerViewOfs);

        new Float: vecPlayerOrigin[3]; get_entvar(iPlayer, var_origin, vecPlayerOrigin);

        xs_vec_add(vecPlayerOrigin, vecPlayerViewOfs, vecPlayerOrigin);

        engfunc(EngFunc_SetOrigin, iClusterBomb, vecPlayerOrigin);   

        new Float: vecVelocity[3]; xs_vec_copy(vecPlayerViewForward, vecVelocity);

        xs_vec_mul_scalar(vecVelocity, glf_ClusterBomb_Fly_Speed, vecVelocity);

        engfunc(EngFunc_SetModel, iClusterBomb, gls_Grenade_World_Model);
        engfunc(EngFunc_SetSize, iClusterBomb, {-2.0, -2.0, -2.0}, {2.0, 2.0, 2.0});   

        set_entvar(iClusterBomb, var_velocity, vecVelocity);  
        set_entvar(iClusterBomb, var_gravity, glf_ClusterBomb_Gravity);

        SetTouch(iClusterBomb, "RG_Entity_ClusterBomb_Touch");
        set_entvar(iClusterBomb,var_fuser4,get_gametime()+15.0);
        SetThink(iClusterBomb,"ClusterFlightThink");
        set_entvar(iClusterBomb,var_nextthink,get_gametime()+0.1);

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(iClusterBomb);
        write_short(gliv_SpriteIndex_LaserBeam); // Sprite Index
        write_byte(3); // Life
        write_byte(4); // Width
        write_byte(255); // R
        write_byte(30); // G
        write_byte(0); // B
        write_byte(255); // Alpha
        message_end();

        UTIL_SetEntityAnim(iClusterBomb, 1, _, 1.03);
    }
}

public Create_Rocket(iPlayer, Float: vecSpawnOrigin[3], Float: vecTargetOrigin[3])
{
    new iEntity = rg_create_entity("info_target");

    if(!is_nullent(iEntity))
    {
        set_entvar(iEntity, var_classname, gls_Rocket_Classname);
        set_entvar(iEntity, var_owner, iPlayer);
        set_entvar(iEntity, var_solid, SOLID_TRIGGER);
        set_entvar(iEntity, var_movetype, MOVETYPE_TOSS);
        set_entvar(iEntity, var_gravity, random_float(glfg_Rocket_Gravity_Randomness[0], glfg_Rocket_Gravity_Randomness[1]));

        engfunc(EngFunc_SetModel, iEntity, gls_Rocket_Model);
        engfunc(EngFunc_SetOrigin, iEntity, vecSpawnOrigin);

        set_entvar(iEntity, var_mins, Float: {-2.0, -2.0, -2.0});
        set_entvar(iEntity, var_maxs, Float: {2.0, 2.0, 2.0});

        set_entvar(iEntity,var_fuser4,get_gametime()+10.0);
        SetThink(iEntity, "RG_Entity_Rocket_Think");
        SetTouch(iEntity, "RG_Entity_Rocket_Touch");

        new Float: flGameTime = get_gametime();

        set_entvar(iEntity, var_nextthink, flGameTime);

        set_entvar(iEntity, var_fuser1, flGameTime + random_float(glfg_Rocket_Spawn_Find_Target_Time_Randomness[0], glfg_Rocket_Spawn_Find_Target_Time_Randomness[1]));

        UTIL_SetEntityAnim(iEntity, 1, _, 0.8);

        // Set Velocity
        new Float: vecVelocity[3]; xs_vec_sub(vecTargetOrigin, vecSpawnOrigin, vecVelocity);

        ClusterNormalize(vecVelocity);
        xs_vec_mul_scalar(vecVelocity, glf_Rocket_Fly_Speed_To_Target_Origin, vecVelocity);

        set_entvar(iEntity, var_velocity, vecVelocity);

        // Set Angles
        new Float: vecDirection[3]; xs_vec_sub(vecTargetOrigin, vecSpawnOrigin, vecDirection);

        new Float: vecAngles[3]; vector_to_angle(vecDirection, vecAngles);

        set_entvar(iEntity, var_angles, vecAngles);

        // Trail
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(iEntity);          // entity index to follow
        write_short(gliv_SpriteIndex_LaserBeam);      // trail sprite
        write_byte(3);              // life in 0.1 seconds
        write_byte(2);             // trail width
        write_byte(255);               // R
        write_byte(60);             // G
        write_byte(0);              // B
        write_byte(255);             // brightness
        message_end();
    }
}

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const iAnimation, const iReceiver, const iReceiverMsgDest, const iSpectatorMsgDest) 
{
    set_entvar(iReceiver, var_weaponanim, iAnimation);

    message_begin(iReceiverMsgDest, SVC_WEAPONANIM, _, iReceiver);
    write_byte(iAnimation);
    write_byte(0);
    message_end();

    if(get_entvar(iReceiver, var_iuser1) == OBS_NONE)
    {
        static iSpectators[MAX_PLAYERS];
        static iSpectatorsCount;

        get_players(iSpectators, iSpectatorsCount, "bch"); // Not Alive, Bot or HLTV Proxy.

        static iSpectator;

        for(new i = 0; i < iSpectatorsCount; i++)
        {
            iSpectator = iSpectators[i];

            if(get_entvar(iSpectator, var_iuser2) == iReceiver && get_entvar(iSpectator, var_iuser1) == OBS_IN_EYE)
            {
                set_entvar(iSpectator, var_weaponanim, iAnimation);

                message_begin(iSpectatorMsgDest, SVC_WEAPONANIM, _, iSpectator);
                write_byte(iAnimation);
                write_byte(0);
                message_end();
            }
        }
    }
}

stock UTIL_SetEntityAnim(const iEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0)
{
	set_entvar(iEntity, var_frame, flFrame);
	set_entvar(iEntity, var_framerate, flFrameRate);
	set_entvar(iEntity, var_animtime, get_gametime());
	set_entvar(iEntity, var_sequence, iSequence);
}

stock UTIL_GetItemByName(const iPlayer, const szItemName[])
{
	for(new i, iItem = NULLENT; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_member(iPlayer, m_rgpPlayerItems, i);

		while(!is_nullent(iItem))
		{
			if(rg_classname_is(iItem, szItemName)) return iItem;

			iItem = get_member(iItem, m_pNext);
		}
	}

	return NULLENT;
}

stock UTIL_IsNoSolidBetweenPoints(const iPlayer, const Float: vecEnd[3])
{
    new iTrace = create_tr2();

    new Float: vecPlayerOrigin[3]; get_entvar(iPlayer, var_origin, vecPlayerOrigin);

    engfunc(EngFunc_TraceLine, vecPlayerOrigin, vecEnd, IGNORE_MONSTERS, iPlayer, iTrace);

    new Float: vecEndPos[3];

    get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    free_tr2(iTrace);

    return xs_vec_equal(vecEnd, vecEndPos);
}

stock UTIL_ScreenShake(const iPlayer, const iMessageDest, const iAmplitude, const iDuration, const iFrequency)
{
    static iMessageID_ScreenShake;

    if(!iMessageID_ScreenShake)
    {
        iMessageID_ScreenShake = get_user_msgid("ScreenShake");
    }

    message_begin(iMessageDest, iMessageID_ScreenShake, _, iPlayer);
    write_short((1<<12) * iAmplitude);
    write_short((1<<12) * iDuration);
    write_short((1<<12) * iFrequency);
    message_end();
}

stock UTIL_Knockback(const iVictim, const Float: vecKnockbackOrigin[3], const Float: flKnockbackStrenght, const Float: flVictimVelocityModifier)
{
    new Float: vecVictimOrigin[3]; get_entvar(iVictim, var_origin, vecVictimOrigin);

    new Float: vecDirection[3]; xs_vec_sub(vecVictimOrigin, vecKnockbackOrigin, vecDirection);

    if(xs_vec_len(vecDirection) > 0.0)
    {
        xs_vec_normalize(vecDirection, vecDirection);
        xs_vec_mul_scalar(vecDirection, flKnockbackStrenght, vecDirection);

        new Float: vecVictimVelocity[3]; get_entvar(iVictim, var_velocity, vecVictimVelocity);

        xs_vec_add(vecVictimVelocity, vecDirection, vecVictimVelocity);

        set_entvar(iVictim, var_velocity, vecVictimVelocity);

        set_member(iVictim, m_flVelocityModifier, flVictimVelocityModifier);
    }
}

stock bool: UTIL_StripWeaponByIndex(const iPlayer, const iItem)
{
    if(!is_nullent(iItem))
    {
        if(get_member(iPlayer, m_pActiveItem) == iItem)
        {
            ExecuteHamB(Ham_Weapon_RetireWeapon, iItem);
        }

        new weaponId=get_member(iItem,m_iId);
        if(ExecuteHamB(Ham_RemovePlayerItem, iPlayer, iItem))
        {
            ExecuteHamB(Ham_Item_Kill, iItem);

            set_entvar(iPlayer, var_weapons, get_entvar(iPlayer, var_weapons) & ~ (1 << weaponId));

            return true;
        }
    }

    return false;
}

#if defined df_Grenade_WeaponList
    stock UTIL_WeaponList(const iDest, const iReceiver, const szWeaponName[], const iPrimaryAmmoType, const iMaxPrimaryAmmo, const iSecondaryAmmoType, const iMaxSecondaryAmmo, const iSlot, const iPosition, const iWeaponID, const iFlags)
    {
        static iMsgID_WeaponList;

        if(iMsgID_WeaponList || (iMsgID_WeaponList = get_user_msgid("WeaponList")))
        {
            message_begin(iDest, iMsgID_WeaponList, .player = iReceiver);
            write_string(szWeaponName);
            write_byte(iPrimaryAmmoType);
            write_byte(iMaxPrimaryAmmo);
            write_byte(iSecondaryAmmoType);
            write_byte(iMaxSecondaryAmmo);
            write_byte(iSlot);
            write_byte(iPosition);
            write_byte(iWeaponID);
            write_byte(iFlags);
            message_end();
        }
    }
#endif

stock bool: rg_classname_is(const iEntity, const szClassName[])
{
	new szBuffer[MAX_NAME_LENGTH]; get_entvar(iEntity, var_classname, szBuffer, charsmax(szBuffer));

	return bool: (strcmp(szClassName, szBuffer) == 0);
}

stock SafePrecache_Model(const szFileName[])
{
    if(file_exists(szFileName)) return engfunc(EngFunc_PrecacheModel, szFileName);

    set_fail_state("Model/Sprite <%s> not found. The plugin has been stopped.", szFileName);

    return 0;
}

stock SafePrecache_Sound(const szFileName[])
{
    if(file_exists(fmt("sound/%s", szFileName))) return engfunc(EngFunc_PrecacheSound, szFileName);

    set_fail_state("Sound <%s> not found. The plugin has been stopped.", szFileName);

    return 0;
}

stock SafePrecache_Generic(const szFileName[])
{
    if(file_exists(szFileName)) return engfunc(EngFunc_PrecacheGeneric, szFileName);

    set_fail_state("Generic <%s> not found. The plugin has been stopped.", szFileName);

    return 0;
}
stock ClusterNormalize(Float:velocity[3]) {
 new Float:length=vector_length(velocity);
 if(length>0.001){xs_vec_mul_scalar(velocity,1.0/length,velocity);}
 else {velocity[0]=0.0;velocity[1]=0.0;velocity[2]=1.0;}
}
