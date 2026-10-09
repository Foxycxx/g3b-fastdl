/*
 * Zombie Hero ReAPI - BASE Custom Weapon Lifecycle Template
 *
 * CLEAN BASE ONLY:
 *   - NO custom effect entities
 *   - NO custom skill objects
 *   - NO custom think/touch effect logic
 *   - NO beams / sprites / temp effects
 *   - NO debuffs / slows / radius skills
 *   - NO secondary-ammo system
 *   - NO player effect state
 *
 * LIFECYCLE INCLUDED:
 *   plugin_precache
 *   plugin_init
 *   give weapon
 *   weapon spawn
 *   add to player / pickup
 *   deploy
 *   holster
 *   postframe stub
 *   primary attack
 *   secondary attack stub
 *   reload
 *   idle
 *   weaponbox / world model
 *   Zombie Hero round hooks
 *   Zombie Hero spawn / infection / hero hooks
 *   player death / disconnect cleanup hooks
 *   map cleanup
 *
 * weaponapi.inc MUST be included before plugin_precache().
 */

#include <amxmodx>
#include <exhero_drakar2_weaponapi>
#include <zombieplague>
native revo_get_user_hero(id);

// ---------------------------------------------------------------------------
// Optional Zombie Hero weapon-menu integration
// 1 = register this weapon automatically in zh_weapon_menu
// 0 = weapon works normally but is NOT shown in zh_weapon_menu
// ---------------------------------------------------------------------------
#define REGISTER_IN_ZH_WEAPON_MENU 0

#if REGISTER_IN_ZH_WEAPON_MENU
    #include <zh_weapon_menu_api>
#endif

#pragma semicolon 1

// ---------------------------------------------------------------------------
// Zombie Hero API
// ---------------------------------------------------------------------------
#define zh_is_zombie zp_get_user_zombie

// ---------------------------------------------------------------------------
// Plugin
// ---------------------------------------------------------------------------
new const PLUGIN_NAME[]    = "ZP Weapon: Drakar II";
new const PLUGIN_VERSION[] = "1.1";
new const PLUGIN_AUTHOR[]  = "Kozmuteli";

#if REGISTER_IN_ZH_WEAPON_MENU
    // Change these for every weapon created from this template.
    new const szMenuWeaponName[] = "Drakar";
    const iMenuRequiredLevel = 29;
    const iMenuSlot = ZH_MENU_SLOT_PRIMARY;
#endif

// ---------------------------------------------------------------------------
// Weapon identity
// IMPORTANT: every custom weapon must have a UNIQUE impulse code.
// ---------------------------------------------------------------------------
const iWeaponImpulseCode = 927081;
// Standalone release: the W model contains only Drakar, so body 0 is used.
const iWorldModelBody = 0;

// Change these together if you change the base CS weapon.
new const szWeaponReference[] = "weapon_m249";
new const szWeaponAnim[] = "m249";

// Replace with your custom models.
new const szWeaponModelView[]   = "models/g3bmodel/ZTHEX/v_transformgun_progress_v3.mdl";
new const szWeaponModelPlayer[] = "models/zpt/drakar2/p_transformgun.mdl";
new const szWeaponModelWorld[]  = "models/zpt/drakar2/w_transformgun.mdl";
new const szSlashModel[] = "models/zpt/drakar2/ef_transformgun.mdl";
new const g_DrakarFX[][]={"models/g3bmodel/ZTHEX/zpt/drakar2/v_transformgun_fx0.mdl","models/g3bmodel/ZTHEX/zpt/drakar2/v_transformgun_fx1.mdl"};
new g_ChargeHUD;
new const szSlashClassname[] = "zh_drakar_slash";

// Replace with your custom fire sound if needed.
new const szWeaponSoundFire[] = "weapons/transformgun-1.wav";
new const szWeaponSoundDraw[] = "weapons/transformgun_draw.wav";
new const szWeaponSoundClipOut[] = "weapons/transformgun_clipout.wav";
new const szWeaponSoundClipIn[] = "weapons/transformgun_clipin.wav";
new const szWeaponSoundBoltPull[] = "weapons/transformgun_boltpull.wav";
new const szWeaponSoundMaxCharge[] = "transformgunadv_beep.wav";
new const szSlashSoundSpawn[] = "weapons/transformgunadv_shoot3.wav";
new const szSlashSoundEnd[] = "weapons/transformgunadv_shoot_end.wav";

// ---------------------------------------------------------------------------
// WeaponList
// Enable only after you create the .txt and HUD sprites.
// ---------------------------------------------------------------------------
#define USE_CUSTOM_WEAPONLIST

#if defined USE_CUSTOM_WEAPONLIST
    // Unique HUD command/file name so clients download this updated layout.
new const szWeaponListPath[] = "drakarhud3";

    new const szWeaponListResources[][] =
    {
        "sprites/drakarhud3.txt",
        "sprites/zhero/drakarhud3.spr"
    };
#else
    new const szWeaponListPath[] = "weapon_m249";
#endif

// M249 WeaponList base data.
// ammo1, maxammo1, ammo2, maxammo2, slot, position, weapon id, flags
// The skin charge is represented directly by the v_model and no longer uses AmmoX.
new const iWeaponListMessage[8] = { 3, 250, -1, -1, 0, 4, 20, 0 };
new const szConflictingM249WeaponList[] = "deathcuehud";
new const iHiddenM249WeaponList[8] = { 3, 200, -1, -1, -1, -1, CSW_M249, 0 };


// ---------------------------------------------------------------------------
// Base weapon balance
// ---------------------------------------------------------------------------
const iPrimaryAmmoClip  = 50;
const iPrimaryAmmoTotal = 200;
const iPrimaryShots     = 1;
const iPrimaryDamage    = 42;

const Float:flPrimaryAttackRate = 0.16;
const Float:flPrimaryRecoil = 0.55;

// ---------------------------------------------------------------------------
// M2 skin-charged slash barrage
// ---------------------------------------------------------------------------
const iSkinShotsPerLevel = 4;
const iSkinMaxLevel = 5;
const iWeaponBodyStride = 1;
const iSlashClipCost = 30;
const iSlashCountMin = 16;
const iSlashCountMax = 16;
const Float:flSlashSpawnInterval = 0.125;
const Float:flSlashRange = 700.0;
const Float:flSlashSpeed = 1300.0;
const Float:flSlashDamageMin = 100.0;
const Float:flSlashDamageMax = 160.0;
const Float:flSlashHitRadius = 42.0;
const Float:flSlashThinkInterval = 0.03;
const Float:flSlashFadeStep = 38.0;
const Float:flSlashKnockback = 24.0;
const Float:flSlashKnockbackUp = 6.0;
const Float:flSlashFinalKnockback = 280.0;
const Float:flSlashFinalKnockbackUp = 45.0;
// M2 barrage coverage relative to the first-person camera. The horizontal
// distribution is stratified so every barrage covers both screen edges,
// instead of randomly clustering all projectiles around the crosshair.
const Float:flSlashCameraYaw = 6.0;
const Float:flSlashCameraPitch = 4.0;

// Non-linear screen order for sequential projectile spawning. This preserves
// the one-by-one barrage timing without producing a left-to-right sweep.
new const Float:g_flSlashYawPattern[] =
{
     0.00, -1.00,  1.00, -0.48,  0.48, -0.76,  0.76,
    -0.24,  0.24, -0.90,  0.90, -0.10,  0.10,  0.62,
    -0.62,  0.36, -0.36,  0.82
};

const TASK_SLASH_BARRAGE = 27500;
const TASK_M2_AUTO_RELOAD = 27600;

new g_iSlashShot[MAX_PLAYERS + 1];
new g_iSlashTotal[MAX_PLAYERS + 1];
new g_iSlashWeapon[MAX_PLAYERS + 1];
new g_iSlashSkinLevel[MAX_PLAYERS + 1];
new bool:g_bSlashCasting[MAX_PLAYERS + 1];
new bool:g_bM2Held[MAX_PLAYERS + 1];

// ---------------------------------------------------------------------------
// Animations
// Change indices/times for your custom v_model.
// ---------------------------------------------------------------------------
const WeaponAnim_Shoot   = 1;
const WeaponAnim_Reload  = 3;
const WeaponAnim_Draw    = 4;
const WeaponAnim_Idle    = 0;
const WeaponAnim_SlashA  = 5;
const WeaponAnim_SlashB  = 6;
const WeaponAnim_SlashEnd = 7;

const Float:WeaponAnim_Idle_Time   = 5.55;
const Float:WeaponAnim_Draw_Time   = 1.0;
const Float:WeaponAnim_Reload_Time = 2.50;
const Float:WeaponAnim_Shoot_Time  = 0.96;

// ---------------------------------------------------------------------------
// AMXX lifecycle
// ---------------------------------------------------------------------------
public plugin_natives()
{
    // Optional external integration:
    register_native("zh_give_drakar", "native_give_weapon", 1);
    register_native("refill_drakar2","DrakarRefill",1);

#if REGISTER_IN_ZH_WEAPON_MENU
    // Allows this weapon plugin to load even when zh_weapon_menu is absent.
    set_native_filter("weapon_native_filter");
#endif
}

#if REGISTER_IN_ZH_WEAPON_MENU
public weapon_native_filter(const native_name[], index, trap)
{
    #pragma unused index
    #pragma unused trap

    if(equal(native_name, "zh_weapon_menu_register"))
        return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}
#endif

public plugin_precache()
{
    precache_generic("sound/weapons/transformgun_boltpull.wav");
    precache_generic("sound/weapons/transformgun_clipin.wav");
    precache_generic("sound/weapons/transformgun_clipout.wav");
    precache_generic("sound/weapons/transformgun_draw.wav");
    precache_generic("sound/weapons/transformgunadv_boltpull01.wav");
    precache_generic("sound/weapons/transformgunadv_boltpull10.wav");

#if defined USE_CUSTOM_WEAPONLIST
    // Custom WeaponList command -> real base weapon command.
    register_clcmd(szWeaponListPath, "command_hookweapon");
#endif

    precache_model_ex(szWeaponModelView);
    precache_model_ex(szWeaponModelPlayer);
    precache_model_ex(szWeaponModelWorld);
    precache_model_ex(szSlashModel);
    for(new i;i<sizeof g_DrakarFX;i++)precache_model_ex(g_DrakarFX[i]);

    precache_sound_ex(szWeaponSoundFire);
    precache_sound_ex(szWeaponSoundDraw);
    precache_sound_ex(szWeaponSoundClipOut);
    precache_sound_ex(szWeaponSoundClipIn);
    precache_sound_ex(szWeaponSoundBoltPull);
    precache_sound_ex(szWeaponSoundMaxCharge);
    precache_sound_ex(szSlashSoundSpawn);
    precache_sound_ex(szSlashSoundEnd);

#if defined USE_CUSTOM_WEAPONLIST
    for(new i = 0; i < sizeof szWeaponListResources; i++)
        precache_generic_ex(szWeaponListResources[i]);
#endif
}

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    g_ChargeHUD=CreateHudSyncObj();set_task(0.5,"DrakarChargeHUD",29001,_,_,"b");
    register_forward(FM_UpdateClientData, "Drakar_UpdateClientData_Post", true);
    register_event("HLTV", "zh_round_new", "a", "1=0", "2=0");
    register_logevent("Drakar_RoundEnd", 2, "1=Round_End");

    // Public release test command. The give routine itself rejects dead players
    // and zombies, and also prevents duplicate Drakar copies.
    // Available through the existing primary-weapon menu.


    // ReGameDLL / ReAPI.
    RegisterHookChain(RG_CWeaponBox_SetModel, "rg_cweaponbox_setmodel_pre", false);
    RegisterHookChain(RG_CSGameRules_CleanUpMap, "rg_csgamerules_cleanupmap_post", true);

    // Player lifecycle.
    RegisterHam(Ham_Killed, "player", "ham_player_killed_post", true);

    // Weapon lifecycle.
    RegisterHam(Ham_Spawn, szWeaponReference, "ham_weapon_spawn_post", true);
    RegisterHam(Ham_Item_AddToPlayer, szWeaponReference, "ham_item_addtoplayer_post", true);
    RegisterHam(Ham_Item_Deploy, szWeaponReference, "ham_item_deploy_post", true);
    RegisterHam(Ham_Item_Holster, szWeaponReference, "ham_item_holster_post", true);
    RegisterHam(Ham_Item_PostFrame, szWeaponReference, "ham_item_postframe_pre", false);

    RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponReference, "ham_weapon_primaryattack_pre", false);
    RegisterHam(Ham_Weapon_SecondaryAttack, szWeaponReference, "ham_weapon_secondaryattack_pre", false);
    RegisterHam(Ham_Weapon_Reload, szWeaponReference, "ham_weapon_reload_post", true);
    RegisterHam(Ham_Weapon_WeaponIdle, szWeaponReference, "ham_weapon_weaponidle_pre", false);
}

#if REGISTER_IN_ZH_WEAPON_MENU
public plugin_cfg()
{
    // plugin_cfg runs after plugin initialization, which makes this safer for
    // optional cross-plugin registration than doing it directly in plugin_init.
    if(LibraryExists("zh_weapon_menu", LibType_Library))
    {
        zh_weapon_menu_register(
            iMenuSlot,
            szMenuWeaponName,
            iMenuRequiredLevel,
            "zh_weapon_menu_give"
        );
    }
}

// Public callback invoked by zh_weapon_menu when the player chooses this weapon.
public zh_weapon_menu_give(pPlayer)
{
    return give_custom_weapon(pPlayer);
}
#endif

public client_disconnected(pPlayer)
{
    weapon_player_cleanup(pPlayer);
}

// ---------------------------------------------------------------------------
// Zombie Hero lifecycle
// These names match zombie_hero_reapi.sma forwards.
// ---------------------------------------------------------------------------
public zh_round_new()
{
    for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
        weapon_player_cleanup(pPlayer);
}

public zh_round_started()
{
    // Base template: nothing to start.
}

public zh_round_ended(win_team)
{
    #pragma unused win_team

    for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
        weapon_player_cleanup(pPlayer);
}

public zh_user_spawned(pPlayer, is_zombie)
{
    #pragma unused is_zombie

    weapon_player_cleanup(pPlayer);
}

public zh_user_infected(pPlayer, pAttacker, first_zombie)
{
    #pragma unused pAttacker
    #pragma unused first_zombie

    // Zombie Hero itself normally replaces/strips the human loadout.
    // We only clear weapon-local HUD/state here because this base has no effects.
    weapon_player_cleanup(pPlayer);
}

public zh_user_hero(pPlayer, heroine)
{
    #pragma unused heroine

    weapon_player_cleanup(pPlayer);
}

// ---------------------------------------------------------------------------
// Native / command
// ---------------------------------------------------------------------------
public native_give_weapon(pPlayer)
{
    return give_custom_weapon(pPlayer);
}

#if defined USE_CUSTOM_WEAPONLIST
public command_hookweapon(pPlayer)
{
    engclient_cmd(pPlayer, szWeaponReference);
    return PLUGIN_HANDLED;
}
#endif

public command_giveweapon(pPlayer)
{
    give_custom_weapon(pPlayer);
    return PLUGIN_HANDLED;
}

stock give_custom_weapon(pPlayer)
{
    if(!is_user_alive(pPlayer))
        return NULLENT;

    if(zh_is_zombie(pPlayer) || revo_get_user_hero(pPlayer))
        return NULLENT;

    // Prevent duplicate copies of the same custom weapon.
    new pExisting = util_find_custom_item_by_impulse(pPlayer, iWeaponImpulseCode);
    if(!is_nullent(pExisting))
        return pExisting;

    /*
     * GT_APPEND            = just give
     * GT_REPLACE           = replace slot content
     * GT_DROP_AND_REPLACE  = drop current slot content and replace it
     */
    new pItem = rg_give_custom_item(
        pPlayer,
        szWeaponReference,
        GT_DROP_AND_REPLACE,
        iWeaponImpulseCode
    );

    if(!is_nullent(pItem))
    {
        set_entvar(pItem, var_iuser2, 0);
        set_entvar(pItem, var_iuser3, 0);
        set_entvar(pItem, var_body, 0);

        // ReGameDLL/Linux may deliver the base M249 WeaponList after
        // AddToPlayer. Send ours again after the custom item is complete.
        resolve_shared_m249_weaponlist(pPlayer);
    }

    return pItem;
}

stock resolve_shared_m249_weaponlist(pPlayer)
{
    if(!is_user_connected(pPlayer))
        return;

    // Both Drakar and DeathCue are based on CSW_M249. Keep only the active
    // alias in the selectable HUD list so it cannot corrupt other slots.
    util_weaponlist_send(pPlayer, szConflictingM249WeaponList, iHiddenM249WeaponList);
    util_weaponlist_send(pPlayer, szWeaponListPath, iWeaponListMessage);


}

// ---------------------------------------------------------------------------
// WeaponBox / drop lifecycle
// ---------------------------------------------------------------------------
public rg_cweaponbox_setmodel_pre(pWeaponBox, const szModel[])
{
    #pragma unused szModel

    new pItem = util_get_weapon_box_item(pWeaponBox);

    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return HC_CONTINUE;

    SetHookChainArg(2, ATYPE_STRING, szWeaponModelWorld);
    set_entvar(pWeaponBox, var_body, iWorldModelBody);

    return HC_CONTINUE;
}

public rg_csgamerules_cleanupmap_post()
{
    remove_all_slash_entities();

    for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
        weapon_player_cleanup(pPlayer);
}

// ---------------------------------------------------------------------------
// Player death
// ---------------------------------------------------------------------------
public ham_player_killed_post(pVictim, pAttacker, shouldgib)
{
    #pragma unused pAttacker
    #pragma unused shouldgib

    weapon_player_cleanup(pVictim);
}

// ---------------------------------------------------------------------------
// Weapon spawn
// Called when the base weapon entity is spawned.
// Only modify entities marked with our custom impulse.
// ---------------------------------------------------------------------------
public ham_weapon_spawn_post(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return;

    set_member(pItem, m_Weapon_iClip, iPrimaryAmmoClip);
    set_member(pItem, m_Weapon_iDefaultAmmo, iPrimaryAmmoTotal);

    rg_set_iteminfo(pItem, ItemInfo_pszName, szWeaponListPath);
    rg_set_iteminfo(pItem, ItemInfo_iMaxClip, iPrimaryAmmoClip);
    rg_set_iteminfo(pItem, ItemInfo_iMaxAmmo1, iPrimaryAmmoTotal);
}

// ---------------------------------------------------------------------------
// Pickup / AddToPlayer
// Re-send custom WeaponList when our custom item is picked up.
// Restore normal WeaponList for a normal MP5 entity.
// ---------------------------------------------------------------------------
public ham_item_addtoplayer_post(pItem, pPlayer)
{
    if(is_nullent(pItem) || !is_user_connected(pPlayer))
        return;

    if(is_custom_weapon(pItem, iWeaponImpulseCode))
    {
        resolve_shared_m249_weaponlist(pPlayer);
    }
    else if(get_entvar(pItem, var_impulse) == 0)
    {
        util_weaponlist_send_from_item(pPlayer, pItem, szWeaponReference);
    }
}

// ---------------------------------------------------------------------------
// Deploy
// ---------------------------------------------------------------------------
public ham_item_deploy_post(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return;

    resolve_shared_m249_weaponlist(get_member(pItem, m_pPlayer));

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer))
        return;

    // Always restore the custom HUD when the weapon is selected. This also
    // covers Linux event-order differences and weapon switching.
    util_weaponlist_send(pPlayer, szWeaponListPath, iWeaponListMessage);

    // Humans only.
    if(zh_is_zombie(pPlayer))
        return;

    set_entvar(pPlayer, var_viewmodel, szWeaponModelView);
    set_entvar(pPlayer, var_weaponmodel, szWeaponModelPlayer);
    // Standalone P model has one body. Packed-model body 22 must not be used.
    // Preserve the player model body.

    set_member(pPlayer, m_szAnimExtention, szWeaponAnim);

    apply_weapon_skin_level(pItem);
    DrakarAnimation(pPlayer, pItem, WeaponAnim_Draw);

    set_member(pPlayer, m_flNextAttack, WeaponAnim_Draw_Time);
    set_member(pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time);
}

// ---------------------------------------------------------------------------
// Holster
// Keep this hook even when empty: future weapon-specific state can be stopped here.
// ---------------------------------------------------------------------------
public ham_item_holster_post(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return;

    new pPlayer = get_member(pItem, m_pPlayer);
    remove_task(TASK_M2_AUTO_RELOAD + pPlayer);
    stop_slash_barrage(pPlayer);
}

// ---------------------------------------------------------------------------
// Item_PostFrame
// Base stub for future hold/combo/reload logic.
// ---------------------------------------------------------------------------
public ham_item_postframe_pre(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return HAM_IGNORED;

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return HAM_SUPERCEDE;

    // While the custom M2 barrage is active (and during its short ending
    // delay), do not let M249::ItemPostFrame see an empty clip. Otherwise the
    // engine starts its automatic reload and our delayed reload starts it a
    // second time, which duplicates/restarts the reload animation.
    if(g_bSlashCasting[pPlayer] || task_exists(TASK_M2_AUTO_RELOAD + pPlayer))
    {
        new iBlockedButtons = get_entvar(pPlayer, var_button);
        set_entvar(
            pPlayer,
            var_button,
            iBlockedButtons & ~(IN_ATTACK | IN_ATTACK2 | IN_RELOAD)
        );
        return HAM_SUPERCEDE;
    }

    new iButtons = get_entvar(pPlayer, var_button);

    if(iButtons & IN_ATTACK2)
    {
        if(!g_bM2Held[pPlayer])
        {
            g_bM2Held[pPlayer] = true;
            try_activate_slash_barrage(pPlayer, pItem);
        }

        // M249 has no dependable secondary attack callback. Consume M2 here
        // so the custom PostFrame handling is the single source of truth.
        set_entvar(pPlayer, var_button, iButtons & ~IN_ATTACK2);

        // try_activate_slash_barrage() may have started the barrage on this
        // very frame. Suppress the original M249 PostFrame immediately so it
        // cannot also begin an empty-clip auto reload.
        if(g_bSlashCasting[pPlayer])
            return HAM_SUPERCEDE;
    }
    else
    {
        g_bM2Held[pPlayer] = false;
    }

    return HAM_IGNORED;
}

// ---------------------------------------------------------------------------
// Primary Attack
// Pure bullet attack: no custom effect objects/entities.
// ---------------------------------------------------------------------------
public ham_weapon_primaryattack_pre(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return HAM_IGNORED;

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return HAM_SUPERCEDE;

    if(get_member(pPlayer,m_pActiveItem)!=pItem || get_member(pPlayer,m_flNextAttack)>0.0 || g_bSlashCasting[pPlayer])return HAM_SUPERCEDE;
    new iClip = get_weapon_clip(pItem);

    if(iClip <= 0)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        set_member(pItem, m_Weapon_flNextPrimaryAttack, 0.20);
        return HAM_SUPERCEDE;
    }

    new Float:flAccuracy[3];
    weapon_set_accuracy(pPlayer, flAccuracy);

    weapon_base_bullet_attack(
        pPlayer,
        pItem,
        iPrimaryShots,
        iPrimaryDamage,
        flAccuracy
    );

    weapon_create_recoil(pPlayer, flPrimaryRecoil);

    // Advance before sending the animation so every fourth shot immediately
    // displays the newly unlocked viewmodel skin/body variant.
    advance_weapon_skin(pItem);
    rg_set_animation(pPlayer, PLAYER_ATTACK1);
    DrakarAnimation(pPlayer, pItem, WeaponAnim_Shoot);

    emit_sound(
        pPlayer,
        CHAN_WEAPON,
        szWeaponSoundFire,
        VOL_NORM,
        ATTN_NORM,
        0,
        PITCH_NORM
    );

    set_weapon_clip(pItem, iClip - 1);

    set_member(pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time);
    set_member(pItem, m_Weapon_flNextPrimaryAttack, flPrimaryAttackRate);
    set_member(pItem, m_Weapon_flNextSecondaryAttack, flPrimaryAttackRate);

    return HAM_SUPERCEDE;
}

// ---------------------------------------------------------------------------
// Secondary Attack
// Intentionally empty base hook.
// Add a skill later without changing the rest of the weapon lifecycle.
// ---------------------------------------------------------------------------
public ham_weapon_secondaryattack_pre(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return HAM_IGNORED;

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return HAM_SUPERCEDE;

    try_activate_slash_barrage(pPlayer, pItem);

    return HAM_SUPERCEDE;
}

stock try_activate_slash_barrage(pPlayer, pItem)
{
    if(g_bSlashCasting[pPlayer] || get_member(pPlayer,m_pActiveItem)!=pItem || get_member(pPlayer,m_flNextAttack)>0.0 || get_member(pItem,m_Weapon_flNextSecondaryAttack)>0.0 || get_member(pItem,m_Weapon_fInReload))
        return;

    new iSkinLevel = clamp(get_entvar(pItem, var_iuser2), 0, iSkinMaxLevel);

    if(iSkinLevel <= 0)
    {
        set_member(pItem, m_Weapon_flNextSecondaryAttack, 0.25);
        return;
    }

    new iClip = get_weapon_clip(pItem);
    if(iClip <= 0)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
        set_member(pItem, m_Weapon_flNextSecondaryAttack, 0.25);
        return;
    }

    // Spend up to 30 rounds. A partially filled clip can still activate M2;
    // for example, 20 remaining rounds are all consumed and barrage proceeds.
    new iAmmoCost = min(iClip, iSlashClipCost);
    set_weapon_clip(pItem, iClip - iAmmoCost);
    g_iSlashSkinLevel[pPlayer] = iSkinLevel;

    start_slash_barrage(pPlayer, pItem);
}

stock advance_weapon_skin(pItem)
{
    if(is_nullent(pItem))
        return;

    new iSkinLevel = clamp(get_entvar(pItem, var_iuser2), 0, iSkinMaxLevel);
    if(iSkinLevel >= iSkinMaxLevel)
        return;

    new iShots = get_entvar(pItem, var_iuser3) + 1;
    if(iShots >= iSkinShotsPerLevel)
    {
        iShots = 0;
        iSkinLevel++;
        set_entvar(pItem, var_iuser2, iSkinLevel);
        set_entvar(pItem, var_body, (iSkinLevel + (iSkinLevel>=iSkinMaxLevel ? 6 : 0)));

        if(iSkinLevel >= iSkinMaxLevel)
        {
            new pPlayer = get_member(pItem, m_pPlayer);
            if(is_user_alive(pPlayer))
                emit_sound(pPlayer, CHAN_ITEM, szWeaponSoundMaxCharge, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        }
    }

    set_entvar(pItem, var_iuser3, iShots);
}

stock apply_weapon_skin_level(pItem)
{
    if(is_nullent(pItem))
        return;

    new iSkinLevel = clamp(get_entvar(pItem, var_iuser2), 0, iSkinMaxLevel);
    set_entvar(pItem, var_body, (iSkinLevel + (iSkinLevel>=iSkinMaxLevel ? 6 : 0)));
}

stock start_slash_barrage(pPlayer, pItem)
{
    g_bSlashCasting[pPlayer] = true;
    g_iSlashShot[pPlayer] = 0;
    g_iSlashTotal[pPlayer] = random_num(iSlashCountMin, iSlashCountMax);
    g_iSlashWeapon[pPlayer] = pItem;

    set_member(pPlayer, m_flNextAttack, 3.0);
    set_member(pItem, m_Weapon_flNextPrimaryAttack, 3.0);
    set_member(pItem, m_Weapon_flNextSecondaryAttack, 3.0);
    set_member(pItem, m_Weapon_flTimeWeaponIdle, 3.0);

    set_entvar(pPlayer,var_viewmodel,g_DrakarFX[g_iSlashSkinLevel[pPlayer]>=iSkinMaxLevel?1:0]);
    DrakarSlashAnimation(pPlayer,0);
    // First projectile at 0.125 s; last at 2.0 s, matching the attack sequence.
    set_task(flSlashSpawnInterval, "task_slash_barrage", TASK_SLASH_BARRAGE + pPlayer, _, _, "b");
}

public task_slash_barrage(iTask)
{
    new pPlayer = iTask - TASK_SLASH_BARRAGE;
    new pItem = g_iSlashWeapon[pPlayer];

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer) || is_nullent(pItem)
    || !is_custom_weapon(pItem, iWeaponImpulseCode)
    || get_member(pPlayer, m_pActiveItem) != pItem)
    {
        stop_slash_barrage(pPlayer);
        return;
    }

    g_iSlashShot[pPlayer]++;
    create_slash_projectile(pPlayer, pItem);

    if(g_iSlashShot[pPlayer] >= g_iSlashTotal[pPlayer])
    {
        new iAmmoType = get_weapon_ammo_type(pItem);
        new bool:bAutoReload = bool:(get_weapon_clip(pItem) <= 0
            && get_weapon_ammo(pPlayer, iAmmoType) > 0);

        emit_sound(pPlayer, CHAN_WEAPON, szSlashSoundEnd, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        set_entvar(pPlayer,var_viewmodel,szWeaponModelView);
        DrakarAnimation(pPlayer, pItem, WeaponAnim_SlashEnd);
        stop_slash_barrage(pPlayer);
        set_member(pItem, m_Weapon_flTimeWeaponIdle, 1.0);

        if(bAutoReload)
        {
            remove_task(TASK_M2_AUTO_RELOAD + pPlayer);
            set_task(1.0, "task_m2_auto_reload", TASK_M2_AUTO_RELOAD + pPlayer);
        }
        return;
    }

    emit_sound(pPlayer, CHAN_WEAPON, szSlashSoundSpawn, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    // One complete 0.25s slash animation for each pair of projectiles.
    if((g_iSlashShot[pPlayer]%2)==0)DrakarSlashAnimation(pPlayer,(g_iSlashShot[pPlayer]/2)%4);
}

public task_m2_auto_reload(iTask)
{
    new pPlayer = iTask - TASK_M2_AUTO_RELOAD;
    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return;

    new pItem = get_member(pPlayer, m_pActiveItem);
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode)
    || get_weapon_clip(pItem) > 0)
        return;

    new iAmmoType = get_weapon_ammo_type(pItem);
    if(get_weapon_ammo(pPlayer, iAmmoType) <= 0)
        return;

    ExecuteHamB(Ham_Weapon_Reload, pItem);
}

stock stop_slash_barrage(pPlayer)
{
    if(pPlayer < 1 || pPlayer > MaxClients)
        return;

    remove_task(TASK_SLASH_BARRAGE + pPlayer);

    new pItem = g_iSlashWeapon[pPlayer];
    if(!is_nullent(pItem) && is_custom_weapon(pItem, iWeaponImpulseCode))
    {
        // M2 consumes the complete skin charge after the barrage finishes or
        // is interrupted, so all barrage animations retain the charged skin.
        set_entvar(pItem, var_iuser2, 0);
        set_entvar(pItem, var_iuser3, 0);
        set_entvar(pItem, var_body, 0);
    }

    g_bSlashCasting[pPlayer] = false;
    g_bM2Held[pPlayer] = false;
    g_iSlashShot[pPlayer] = 0;
    g_iSlashTotal[pPlayer] = 0;
    g_iSlashWeapon[pPlayer] = NULLENT;
    g_iSlashSkinLevel[pPlayer] = 0;
}

stock create_slash_projectile(pPlayer, pItem)
{
    new pEntity = rg_create_entity("info_target");
    if(is_nullent(pEntity))
        return NULLENT;

    new Float:vecAngles[3], Float:vecForward[3], Float:vecRight[3], Float:vecUp[3];
    new Float:vecStart[3], Float:vecEnd[3], Float:vecVelocity[3], Float:vecEye[3];

    get_entvar(pPlayer, var_v_angle, vecAngles);

    // Keep a narrow varied spread centered on the current aim.
    new iSpreadIndex = clamp(g_iSlashShot[pPlayer], 1, g_iSlashTotal[pPlayer]) - 1;
    vecAngles[1] += flSlashCameraYaw
        * g_flSlashYawPattern[iSpreadIndex % sizeof(g_flSlashYawPattern)]
        + random_float(-0.5, 0.5);

    switch(iSpreadIndex % 5)
    {
        case 0: vecAngles[0] -= flSlashCameraPitch;
        case 1: vecAngles[0] += flSlashCameraPitch * 0.55;
        case 2: vecAngles[0] -= flSlashCameraPitch * 0.35;
        case 3: vecAngles[0] += flSlashCameraPitch;
        default: vecAngles[0] += random_float(-1.0, 1.0);
    }

    engfunc(EngFunc_MakeVectors, vecAngles);
    global_get(glb_v_forward, vecForward);
    global_get(glb_v_right, vecRight);
    global_get(glb_v_up, vecUp);

    util_get_eye_position(pPlayer, vecStart);
    xs_vec_copy(vecStart, vecEye);
    vector_add_scaled(vecStart, vecForward, 34.0);
    vector_add_scaled(vecStart, vecRight, random_float(-6.0, 6.0));
    vector_add_scaled(vecStart, vecUp, random_float(-4.0, 4.0));

    vecEnd[0] = vecStart[0] + vecForward[0] * flSlashRange;
    vecEnd[1] = vecStart[1] + vecForward[1] * flSlashRange;
    vecEnd[2] = vecStart[2] + vecForward[2] * flSlashRange;

    new pTrace = create_tr2();
    // Do not spawn beyond a nearby wall or inside solid geometry.
    engfunc(EngFunc_TraceLine, vecEye, vecStart, IGNORE_MONSTERS, pPlayer, pTrace);
    new Float:flMuzzleFraction;
    get_tr2(pTrace, TR_flFraction, flMuzzleFraction);
    if(get_tr2(pTrace, TR_StartSolid) || get_tr2(pTrace, TR_AllSolid) || flMuzzleFraction < 1.0)
    {
        free_tr2(pTrace);
        util_kill_entity(pEntity);
        return NULLENT;
    }
    engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, pTrace);
    if(get_tr2(pTrace, TR_StartSolid) || get_tr2(pTrace, TR_AllSolid))
    {
        free_tr2(pTrace);
        util_kill_entity(pEntity);
        return NULLENT;
    }
    get_tr2(pTrace, TR_vecEndPos, vecEnd);
    free_tr2(pTrace);

    vecVelocity[0] = vecForward[0] * flSlashSpeed;
    vecVelocity[1] = vecForward[1] * flSlashSpeed;
    vecVelocity[2] = vecForward[2] * flSlashSpeed;

    engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
    vecAngles[0] *= -1.0;
    vecAngles[2] = random_float(-180.0, 180.0);

    set_entvar(pEntity,var_dmg,random_float(flSlashDamageMin,flSlashDamageMax));
    set_entvar(pEntity, var_classname, szSlashClassname);
    set_entvar(pEntity, var_owner, pPlayer);
    set_entvar(pEntity, var_dmg_inflictor, pItem);
    set_entvar(pEntity, var_movetype, MOVETYPE_FLY);
    set_entvar(pEntity, var_solid, SOLID_NOT);
    set_entvar(pEntity, var_velocity, vecVelocity);
    set_entvar(pEntity, var_angles, vecAngles);
    set_entvar(pEntity, var_rendermode, kRenderTransAdd);
    set_entvar(pEntity, var_renderamt, 255.0);
    set_entvar(pEntity, var_sequence, 0);
    set_entvar(pEntity, var_animtime, get_gametime());
    set_entvar(pEntity, var_framerate, 1.0);
    set_entvar(pEntity, var_vuser1, vecEnd);
    set_entvar(pEntity, var_iuser1, 0);
    set_entvar(pEntity, var_iuser2, clamp(g_iSlashSkinLevel[pPlayer], 1, iSkinMaxLevel));
    set_entvar(pEntity, var_iuser3, g_iSlashShot[pPlayer] >= g_iSlashTotal[pPlayer]);

    new Float:flDistance = get_distance_f(vecStart, vecEnd);
    set_entvar(pEntity, var_fuser1, get_gametime() + flDistance / flSlashSpeed);

    engfunc(EngFunc_SetModel, pEntity, szSlashModel);
    // The effect model has three valid skin families (engine indices 0..2).
    // At maximum weapon skin charge use its third/strongest visual skin.
    set_entvar(pEntity, var_skin, g_iSlashSkinLevel[pPlayer] >= iSkinMaxLevel ? 1 : 0);
    engfunc(EngFunc_SetOrigin, pEntity, vecStart);
    SetThink(pEntity, "slash_projectile_think");
    set_entvar(pEntity, var_nextthink, get_gametime() + flSlashThinkInterval);
    return pEntity;
}

public slash_projectile_think(pEntity)
{
    if(is_nullent(pEntity))
        return;

    new pOwner = get_entvar(pEntity, var_owner);
    if(!is_user_alive(pOwner) || zh_is_zombie(pOwner))
    {
        util_kill_entity(pEntity);
        return;
    }

    new Float:flNow = get_gametime();
    new Float:flTravelEnd = Float:get_entvar(pEntity, var_fuser1);

    if(flNow < flTravelEnd)
    {
        slash_damage_nearby(pEntity, pOwner);
        if(is_nullent(pEntity) || (get_entvar(pEntity,var_flags) & FL_KILLME)) return;
    }
    else
    {
        new Float:vecZero[3], Float:vecEnd[3];
        get_entvar(pEntity, var_vuser1, vecEnd);
        engfunc(EngFunc_SetOrigin, pEntity, vecEnd);
        set_entvar(pEntity, var_velocity, vecZero);

        new Float:flAmount;
        get_entvar(pEntity, var_renderamt, flAmount);
        flAmount -= flSlashFadeStep;
        if(flAmount <= 0.0)
        {
            util_kill_entity(pEntity);
            return;
        }
        set_entvar(pEntity, var_renderamt, flAmount);
    }

    set_entvar(pEntity, var_nextthink, flNow + flSlashThinkInterval);
}

stock slash_damage_nearby(pEntity, pOwner)
{
    new Float:vecOrigin[3];
    get_entvar(pEntity, var_origin, vecOrigin);

    new iHitMask = get_entvar(pEntity, var_iuser1);
    new pVictim = NULLENT;
    while((pVictim = engfunc(EngFunc_FindEntityInSphere, pVictim, vecOrigin, flSlashHitRadius)) != 0)
    {
        if(!is_user_alive(pVictim) || !zh_is_zombie(pVictim))
            continue;

        new iBit = 1 << (pVictim - 1);
        if(iHitMask & iBit)
            continue;

        iHitMask |= iBit;
        set_entvar(pEntity,var_iuser1,iHitMask);
        set_member(pVictim, m_LastHitGroup, HIT_GENERIC);

        new pInflictor = get_entvar(pEntity, var_dmg_inflictor);
        if(is_nullent(pInflictor))
            pInflictor = pEntity;

        new iSkinLevel = clamp(get_entvar(pEntity, var_iuser2), 1, iSkinMaxLevel);
        new Float:flDamageScale = (iSkinLevel >= iSkinMaxLevel ? 1.15 : 1.0);

        ExecuteHamB(
            Ham_TakeDamage,
            pVictim,
            pInflictor,
            pOwner,
            Float:get_entvar(pEntity,var_dmg) * flDamageScale,
            DMG_SLASH | DMG_NEVERGIB
        );

        if(is_nullent(pEntity)||!is_user_alive(pOwner)||zh_is_zombie(pOwner))return;
        if(is_user_alive(pVictim)&&zh_is_zombie(pVictim))apply_slash_knockback(pEntity, pVictim);
    }

    set_entvar(pEntity, var_iuser1, iHitMask);
}

stock apply_slash_knockback(pEntity, pVictim)
{
    new Float:vecProjectileVelocity[3], Float:vecVictimVelocity[3];
    get_entvar(pEntity, var_velocity, vecProjectileVelocity);
    get_entvar(pVictim, var_velocity, vecVictimVelocity);

    new Float:flLength = floatsqroot(
        vecProjectileVelocity[0] * vecProjectileVelocity[0]
        + vecProjectileVelocity[1] * vecProjectileVelocity[1]
    );

    if(flLength <= 0.0)
        return;

    new bool:bFinalProjectile = bool:get_entvar(pEntity, var_iuser3);
    new Float:flKnockback = bFinalProjectile ? flSlashFinalKnockback : flSlashKnockback;
    new Float:flKnockbackUp = bFinalProjectile ? flSlashFinalKnockbackUp : flSlashKnockbackUp;

    vecVictimVelocity[0] += vecProjectileVelocity[0] / flLength * flKnockback;
    vecVictimVelocity[1] += vecProjectileVelocity[1] / flLength * flKnockback;
    vecVictimVelocity[2] += flKnockbackUp;
    set_entvar(pVictim, var_velocity, vecVictimVelocity);
}

stock vector_add_scaled(Float:vecValue[3], const Float:vecDirection[3], Float:flScale)
{
    vecValue[0] += vecDirection[0] * flScale;
    vecValue[1] += vecDirection[1] * flScale;
    vecValue[2] += vecDirection[2] * flScale;
}

stock remove_all_slash_entities()
{
    new pEntity = NULLENT;
    while((pEntity = rg_find_ent_by_class(pEntity, szSlashClassname)) > 0)
        util_kill_entity(pEntity);
}

// ---------------------------------------------------------------------------
// Reload
// Let the base weapon perform the actual ammo transfer,
// then replace its visual reload animation/timing.
// ---------------------------------------------------------------------------
public ham_weapon_reload_post(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return;

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return;

    new iAmmoType = get_weapon_ammo_type(pItem);

    if(get_weapon_ammo(pPlayer, iAmmoType) <= 0)
        return;

    if(get_weapon_clip(pItem) >= rg_get_iteminfo(pItem, ItemInfo_iMaxClip))
        return;

    rg_set_animation(pPlayer, PLAYER_RELOAD);
    DrakarAnimation(pPlayer, pItem, WeaponAnim_Reload);

    set_member(pPlayer, m_flNextAttack, WeaponAnim_Reload_Time);
    set_member(pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time);
}

// ---------------------------------------------------------------------------
// Weapon idle
// ---------------------------------------------------------------------------
public ham_weapon_weaponidle_pre(pItem)
{
    if(is_nullent(pItem) || !is_custom_weapon(pItem, iWeaponImpulseCode))
        return HAM_IGNORED;

    if(get_member(pItem, m_Weapon_flTimeWeaponIdle) > 0.0)
        return HAM_IGNORED;

    new pPlayer = get_member(pItem, m_pPlayer);

    if(!is_user_alive(pPlayer) || zh_is_zombie(pPlayer))
        return HAM_SUPERCEDE;

    DrakarAnimation(pPlayer, pItem, WeaponAnim_Idle);
    set_member(pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time);

    return HAM_SUPERCEDE;
}

// ---------------------------------------------------------------------------
// BASE bullet firing
// No custom traceline effects, decals, beams, entities, radius damage, etc.
// ---------------------------------------------------------------------------
stock weapon_base_bullet_attack(
    pPlayer,
    pItem,
    iShots,
    iDamage,
    Float:flAccuracy[3]
)
{
    new Float:vecStart[3];
    new Float:vecAiming[3];

    util_get_eye_position(pPlayer, vecStart);
    util_get_vector_aiming(pPlayer, vecAiming);

    new iPlaybackHook = register_forward(FM_PlaybackEvent, "drakar_playbackevent_pre", false);
    new iTraceHook = register_forward(FM_TraceLine, "drakar_traceline_post", true);

    rg_fire_buckshots(
        pItem,
        pPlayer,
        iShots,
        vecStart,
        vecAiming,
        flAccuracy,
        8192.0,
        0,
        iDamage
    );

    unregister_forward(FM_PlaybackEvent, iPlaybackHook, false);
    unregister_forward(FM_TraceLine, iTraceHook, true);
}

public drakar_playbackevent_pre()
{
    return FMRES_SUPERCEDE;
}

public drakar_traceline_post(Float:vecStart[3], Float:vecEnd[3], iFlags, pAttacker, pTrace)
{
    #pragma unused vecStart, pAttacker

    if(iFlags & IGNORE_MONSTERS)
        return FMRES_IGNORED;

    get_tr2(pTrace, TR_vecEndPos, vecEnd);

    new pHit = get_tr2(pTrace, TR_pHit);
    if(pHit > 0 && get_entvar(pHit, var_solid) != SOLID_BSP)
        return FMRES_IGNORED;

    util_te_gunshotdecal(vecEnd, pHit, random_num(41, 45));

    new Float:vecPlaneNormal[3];
    get_tr2(pTrace, TR_vecPlaneNormal, vecPlaneNormal);
    vecPlaneNormal[0] *= random_float(25.0, 30.0);
    vecPlaneNormal[1] *= random_float(25.0, 30.0);
    vecPlaneNormal[2] *= random_float(25.0, 30.0);
    util_te_streak_splash(vecEnd, vecPlaneNormal, 4, random_num(10, 20), 3, 64);

    return FMRES_IGNORED;
}

// ---------------------------------------------------------------------------
// Player cleanup
// ---------------------------------------------------------------------------
stock weapon_player_cleanup(pPlayer)
{
    new ent;
    while((ent=fm_find_ent_by_owner(ent,szSlashClassname,pPlayer))>0)util_kill_entity(ent);
    if(pPlayer >= 1 && pPlayer <= MaxClients)
        remove_task(TASK_M2_AUTO_RELOAD + pPlayer);

    if(!is_user_valid(pPlayer))
        return;

    stop_slash_barrage(pPlayer);
}

// Suppress the predicted stock M249 attacks, leaving custom server animations intact.
public Drakar_UpdateClientData_Post(player, sendweapons, cd)
{
    new target=player;
    if(!is_user_alive(player)) {
        if(pev(player,pev_iuser1)!=OBS_IN_EYE)return;
        target=pev(player,pev_iuser2);
    }
    if(!is_user_alive(target))return;
    new item=get_member(target,m_pActiveItem);
    if(is_nullent(item)||!is_custom_weapon(item,iWeaponImpulseCode))return;
    set_cd(cd,CD_flNextAttack,2.0);
}
public zp_user_infected_pre(id) { weapon_player_cleanup(id); }
public Drakar_RoundEnd() { zh_round_ended(0); }

public DrakarRefill(id,extra){
 if(!is_user_alive(id)||zh_is_zombie(id))return 0;
 new w=util_find_custom_item_by_impulse(id,iWeaponImpulseCode);if(is_nullent(w))return 0;
 new a=get_weapon_ammo_type(w),amount=extra?250:200;
 set_member(id,m_rgAmmo,max(amount,get_weapon_ammo(id,a)),a);return 1;
}

// Model has two animation banks (0..7 and 8..15), not five III body stages.
stock DrakarAnimation(id,item,anim){
 if(!is_user_alive(id)||is_nullent(item)||get_member(id,m_pActiveItem)!=item)return;
 new level=clamp(get_entvar(item,var_iuser2),0,iSkinMaxLevel);
 if(level==iSkinMaxLevel && anim>=0 && anim<=7)anim+=8;
 util_weapon_animation(id,item,anim);
}

public DrakarChargeHUD(){
 for(new id=1;id<=MaxClients;id++){
  if(!is_user_alive(id)||zh_is_zombie(id))continue;
  new item=get_member(id,m_pActiveItem);
  if(is_nullent(item)||!is_custom_weapon(item,iWeaponImpulseCode))continue;
  new level=clamp(get_entvar(item,var_iuser2),0,iSkinMaxLevel);
  new shots=min(iSkinMaxLevel*iSkinShotsPerLevel,level*iSkinShotsPerLevel+get_entvar(item,var_iuser3));
  new bar[21];for(new n;n<20;n++)bar[n]=n<shots?'|':'.';bar[20]=0;
  set_hudmessage(255,level==iSkinMaxLevel?60:200,30,-1.0,0.78,0,0.0,0.6,0.0,0.0,-1);
  ShowSyncHudMsg(id,g_ChargeHUD,"Drakar [%s] %d%%",bar,shots*5);
 }
}
stock DrakarSlashAnimation(id,phase){
 if(!is_user_alive(id)||!g_bSlashCasting[id])return;
 new anim=phase+(g_iSlashSkinLevel[id]>=iSkinMaxLevel?4:0);
 set_entvar(id,var_weaponanim,anim);
 message_begin(MSG_ONE_UNRELIABLE,SVC_WEAPONANIM,_,id);write_byte(anim);write_byte(0);message_end();
}
