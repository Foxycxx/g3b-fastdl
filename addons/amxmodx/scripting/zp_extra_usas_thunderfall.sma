// ============================================================================
//    ██╗   ██╗███████╗ █████╗ ███████╗       ██╗██████╗
//    ██║   ██║██╔════╝██╔══██╗██╔════╝      ███║╚════██╗
//    ██║   ██║███████╗███████║███████╗ █████╗╚██║ █████╔╝
//    ██║   ██║╚════██║██╔══██║╚════██║ ╚════╝ ██║██╔═══╝
//    ╚██████╔╝███████║██║  ██║███████║        ██║███████╗
//     ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝        ╚═╝╚══════╝
// ============================================================================
//  Plugin:    [ZP] Extra Item: Usas-12 Thunderfall
//  Version:   1.0
//  Author:    Kolmi ( divinezavet )
//  Telegram:  t.me/amxxplguins
//  native - zp_give_user_usas_thunderfall
// ============================================================================

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>

#define PLUGIN "[ZP] Extra: Usas-12 Thunderfall"
#define VERSION "1.0"
#define AUTHOR "Kolmi"

// ==========================================
// [ НАСТРОЙКИ EXTRA ITEM ]
// ==========================================
//#define USE_EXTRA_ITEM                          // Закомментируй, чтобы отключить регистрацию в меню ZP
#if defined USE_EXTRA_ITEM
    new const WPN_ITEM_NAME[] = "Usas-12 Thunderfall"   // Название в меню
    const WPN_ITEM_COST       = 0                        // Стоимость (0 = бесплатно)
#endif

// ==========================================
// [ НАСТРОЙКИ ОРУЖИЯ ]
// ==========================================
// --- Базовое оружие ---
#define WEAPON_NAME         "weapon_m249"       // Забейте
#define WEAPON_CSW          CSW_M249            // CSW-индекс базового оружия
#define WEAPON_IMPULSE      81033               // Уникальный ID для идентификации кастомного оружия

// --- Боеприпасы ---
#define WEAPON_AMMO         35                  // Патронов в магазине
#define WEAPON_BPAMMO       245                 // Максимум запасных патронов

// --- Скорострельность и перезарядка ---
const Float: WEAPON_P_RATE  = 0.25;             // Задержка между выстрелами ЛКМ (сек)
const Float: RELOAD_TIME    = 2.5;              // Время перезарядки (сек)
const Float: WEAPON_P_DMG   = 32.0;             // Урон пули ЛКМ

// --- Урон ---
const Float: WEAPON_LIGHTNING_DMG = 100.0;      // Урон пассивной молнии (каждые 5 попаданий)
const Float: WEAPON_RMB_RADIUS    = 250.0;      // Радиус поиска целей для молнии

// --- Цепная молния (ПКМ) ---
const CHAIN_MAX_TARGETS     = 3;                // Макс. кол-во целей цепной молнии
const Float: CHAIN_DURATION = 2.0;              // Общая длительность молнии (сек)
const Float: CHAIN_TICK     = 0.2;              // Интервал тиков урона (сек)
const Float: CHAIN_TICK_DMG = 45.0;            // Урон за один тик
const Float: FX_Z_OFFSET    = 0.0;              // Смещение модели молнии по Z (выше/ниже центра игрока)
const Float: FX_LIFETIME    = 1.25;             // Время жизни пассивной молнии (сек)
const Float: PROJ_LIFETIME  = 5.0;              // Время жизни снаряда ПКМ (сек)

// --- Заряды ПКМ ---
const MAX_CHARGES           = 2;                // Макс. кол-во зарядов ПКМ
const Float: CHARGE_TIME    = 10.0;             // Время восстановления одного заряда (сек)

// --- Скорость снаряда ПКМ ---
const Float: PROJ_SPEED     = 1200.0;           // Скорость полёта снаряда ПКМ

// ==========================================
// [ МОДЕЛИ И СПРАЙТЫ ]
// ==========================================
new const V_MODEL_1[]   = "models/g3bmodel/ZTHEX/usas/v_asusas12.mdl"      // Вьюмодель (без заряда)
new const V_MODEL_2[]   = "models/g3bmodel/ZTHEX/usas/v_asusas12_2.mdl"    // Вьюмодель (с зарядом)
new const P_MODEL[]     = "models/usas/p_asusas12.mdl"      // Модель в руках (3-е лицо)
new const W_MODEL[]     = "models/usas/w_asusas12.mdl"      // Модель на земле

new const MDL_EXP1[]    = "models/usas/ef_asusas12_ball01.mdl"  // Шар молнии (пассивная, ЛКМ)
new const MDL_EXP2[]    = "models/usas/ef_asusas12_Hit02.mdl"   // Взрыв на полу (ПКМ)
new const MDL_EXP3[]    = "models/usas/ef_asusas12_ball02.mdl"  // Шар + молния (ПКМ цепная)

new const SPR_PROJ[]    = "sprites/usas/ef_asusas12_ball01.spr" // Спрайт снаряда ПКМ
new const SPR_MUZZLE[]  = "sprites/usas/muzzleflash435.spr"     // Вспышка дула

// ==========================================
// [ ЗВУКИ ]
// ==========================================
new const SND_SHOOT[]       = "weapons/asusas12-1.wav"      // Выстрел ЛКМ
new const SND_LIGHT_5[]     = "weapons/asusas12_exp1.wav"   // Звук удара молнии
new const SND_SHOOT_RMB[]   = "weapons/asusas12-2.wav"      // Выстрел ПКМ
new const SND_LIGHT_RMB[]   = "weapons/asusas12_exp2.wav"   // Звук взрыва на полу

new const SPR_WPNLIST[]     = "sprites/weapon_asusas12.txt"     // HUD-спрайт оружия

// ==========================================
// [ ВНУТРЕННИЕ КОНСТАНТЫ ]
// ==========================================
#define CLASS_PROJ          "usas_proj"          // Classname снаряда ПКМ
#define PROJ_IMPULSE        81034               // Impulse-метка снаряда
#define FX_IMPULSE_LIGHT    81035               // Impulse-метка эффекта молнии (пассивная)
#define FX_IMPULSE_FLOOR    81036               // Impulse-метка взрыва на полу
#define FX_IMPULSE_CHAIN    81037               // Impulse-метка цепной молнии (ПКМ)

#define MUZZLE_CLASSNAME    "ent_usas_sprite"   // Classname спрайта вспышки
#define m_maxFrame          35                  // Оффсет m_maxFrame для env_sprite
#define MUZZLE_TIME         0.04                // Интервал кадров вспышки
#define MIN_FREE_EDICTS     100                 // Минимум свободных энтити для спавна

new g_UsasShot[33];
new g_iszSpriteKey                              // Кэш AllocString для мuzzle flash

#define CustomSprite(%0) (get_entvar(%0, var_impulse) == g_iszSpriteKey)
#define IsCustomWeapon(%0) (get_entvar(%0, var_impulse) == WEAPON_IMPULSE)

// Индексы анимаций вьюмодели
enum {
    ANIM_IDLE = 0,  // Покой
    ANIM_SHOOT1,    // Выстрел ЛКМ
    ANIM_SHOOT2,    // Выстрел ЛКМ (вариант)
    ANIM_SHOOT3,    // Выстрел ПКМ
    ANIM_RELOAD,    // Перезарядка
    ANIM_DRAW       // Доставание
}

// ==========================================
// [ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ]
// ==========================================
new bool:g_bHasUsas[33]         // Игрок владеет оружием
new g_iCharges[33]              // Текущее кол-во зарядов ПКМ
new Float:g_flNextCharge[33]    // Время следующего восстановления заряда
new g_iHits[33]                 // Счётчик попаданий для пассивной молнии
new bool:g_bHasModel2[33]       // Флаг: активна вьюмодель с зарядом

new g_iItemID                   // ID extra item в ZP
new g_msgWeaponList, g_msgAmmoX // Кэш ID сообщений

// ==========================================
// [ ИНИЦИАЛИЗАЦИЯ И ПРЕКЭШ ]
// ==========================================
public plugin_precache() {
    // Модели оружия
    precache_model(V_MODEL_1)
    precache_model(V_MODEL_2)
    precache_model(P_MODEL)
    precache_model(W_MODEL)
    
    // Модели эффектов
    precache_model(MDL_EXP1)
    precache_model(MDL_EXP2)
    precache_model(MDL_EXP3)
    
    // Спрайты
    precache_model(SPR_PROJ)
    precache_model(SPR_MUZZLE)
    
    // Звуки стрельбы и эффектов
    precache_sound(SND_SHOOT)
    precache_sound(SND_LIGHT_5)
    precache_sound(SND_SHOOT_RMB)
    precache_sound(SND_LIGHT_RMB)
    
    // HUD-спрайты
    precache_model("sprites/640hud259.spr")
    precache_model("sprites/640hud7.spr")
    precache_generic(SPR_WPNLIST)
    
    g_iszSpriteKey = engfunc(EngFunc_AllocString, MUZZLE_CLASSNAME)
}

// ==========================================
// [ РЕГИСТРАЦИЯ ХУКОВ ]
// ==========================================
public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
#if defined USE_EXTRA_ITEM
    g_iItemID = zp_register_extra_item(WPN_ITEM_NAME, WPN_ITEM_COST, ZP_TEAM_HUMAN)
#endif

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage_Post", 1)
    RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink_Post", 1)
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "OnAddPlayerItem_Post", 1)
    RegisterHookChain(RG_CWeaponBox_SetModel, "CWeaponBox_SetModel_Pre", 0)
    
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
    
    RegisterHam(Ham_Item_Deploy, WEAPON_NAME, "OnItemDeploy_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME, "OnPrimaryAttack_Pre", 0)
    // Полный перехват ItemPostFrame для кастомной перезарядки (35 патронов вместо 100)
    RegisterHookChain(RG_CBasePlayerWeapon_ItemPostFrame, "OnWeaponItemPostFrame_Pre", 0)
    
    RegisterHam(Ham_Weapon_Reload, WEAPON_NAME, "OnWeaponReload_Pre", 0)
    RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_NAME, "OnWeaponIdle_Pre", 0)
    
    RegisterHam(Ham_Think, "env_sprite", "CSprite_Think_Pre", 0)
    RegisterHam(Ham_Think, "info_target", "OnInfoTargetThink_Pre", 0)
    RegisterHam(Ham_Touch, "info_target", "OnInfoTargetTouch_Pre", 0)
    
    RegisterHam(Ham_Killed,"player","UsasKilled",1,true)
    register_event("HLTV","UsasRound","a","1=0","2=0")
    register_clcmd("weapon_asusas12", "CmdWeaponSelect")
    
    g_msgWeaponList = get_user_msgid("WeaponList")
    g_msgAmmoX = get_user_msgid("AmmoX")
}

// Сброс состояния при дисконнекте
public client_disconnected(id) {
    ResetPlayerState(id)
}

// Сброс состояния при заражении
public zp_user_infected_post(id) {
    if (g_bHasUsas[id]) {
        ResetPlayerState(id)
    }
}

stock ResetPlayerState(id) {
    CleanupOwner(id);g_UsasShot[id]=0;
    g_bHasUsas[id] = false
    g_iCharges[id] = 0
    g_iHits[id] = 0
    g_bHasModel2[id] = false
    g_flNextCharge[id] = 0.0
}

// Нативная функция для выдачи оружия из других плагинов
public plugin_natives() {
    register_native("zp_give_user_usas_thunderfall", "native_give_usas", 1)
    register_native("refill_usas", "UsasRefill")
}

// Выдача оружия игроку
public native_give_usas(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return false
    
    rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT)  // Дропнуть текущее основное оружие
    
    new pWeapon = rg_give_custom_item(id, WEAPON_NAME,GT_APPEND,WEAPON_IMPULSE)
    if (!is_nullent(pWeapon)) {
        set_entvar(pWeapon, var_impulse, WEAPON_IMPULSE)   // Пометить как кастомное
        set_member(pWeapon, m_Weapon_iClip, WEAPON_AMMO)   // Установить патроны в обойме
        
        // Принудительная синхронизация запаса патронов с HUD
        new iAmmoIdx = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
        set_member(id, m_rgAmmo, WEAPON_BPAMMO, iAmmoIdx)
        
        message_begin(MSG_ONE, g_msgAmmoX, .player = id)
        write_byte(iAmmoIdx)
        write_byte(WEAPON_BPAMMO)
        message_end()
        
        g_iCharges[id] = 0
        g_iHits[id] = 0
        g_bHasUsas[id] = true
        g_flNextCharge[id] = get_gametime() + CHARGE_TIME
        
        rg_switch_weapon(id, pWeapon)
        ExecuteHamB(Ham_Item_Deploy,pWeapon)
        
        return true
    }
    return false
}

public zp_extra_item_selected(id, itemid) {
    if (itemid == g_iItemID) {
        native_give_usas(id)
    }
}

public CmdWeaponSelect(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id) || !g_bHasUsas[id]) return PLUGIN_HANDLED
    engclient_cmd(id, WEAPON_NAME)
    return PLUGIN_HANDLED
}

// ==========================================
// [ СОСТОЯНИЕ ОРУЖИЯ ]
// ==========================================
public OnAddPlayerItem_Post(id, pWeapon) {
    if (is_nullent(pWeapon)) return HC_CONTINUE
    
    if (IsCustomWeapon(pWeapon)) {
        g_bHasUsas[id] = true
        SendWeaponList(id, "weapon_asusas12", 3, 250, 28, MAX_CHARGES, 0, 4, WEAPON_CSW, 0)
    }
    // Не перезаписывать кастомный WeaponList стандартным
    return HC_CONTINUE
}

public CWeaponBox_SetModel_Pre(ent, const model[]) {
    if (is_nullent(ent)) return HC_CONTINUE
    
    for (new i = 0; i < 6; i++) {
        new pItem = get_member(ent, m_WeaponBox_rgpPlayerItems, i)
        if (!is_nullent(pItem) && IsCustomWeapon(pItem)) {
            new iOwner = get_entvar(ent, var_owner)
            if (iOwner >= 1 && iOwner <= MaxClients) g_bHasUsas[iOwner] = false
            
            SetHookChainArg(2, ATYPE_STRING, W_MODEL)
            return HC_CONTINUE
        }
    }
    return HC_CONTINUE
}

public OnItemDeploy_Post(pWeapon) {
    if (!IsCustomWeapon(pWeapon)) return HAM_IGNORED
    
    new id = get_member(pWeapon, m_pPlayer)
    if (!ValidOwner(id,pWeapon)) return HAM_IGNORED
    
    set_entvar(id, var_weaponmodel, P_MODEL)    // P-модель (3-е лицо)
    set_entvar(pWeapon, var_body, 0)                  // Фикс бага зеркальной руки
    
    if (g_iCharges[id] > 0) {
        g_bHasModel2[id] = true
        set_entvar(id, var_viewmodel, V_MODEL_2)
    } else {
        g_bHasModel2[id] = false
        set_entvar(id, var_viewmodel, V_MODEL_1)
    }
    
    SendWeaponAnim(id, ANIM_DRAW)
    UpdateHUDAmmo2(id, g_iCharges[id])
    SendWeaponList(id, "weapon_asusas12", 3, 250, 28, MAX_CHARGES, 0, 4, WEAPON_CSW, 0)
    
    return HAM_IGNORED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle) {
    if (!is_user_alive(id)) return FMRES_IGNORED
    new pActive = get_member(id, m_pActiveItem)
    if (!is_nullent(pActive) && IsCustomWeapon(pActive)) {
        set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
    }
    return FMRES_IGNORED
}

// ==========================================
// [ СТРЕЛЬБА ]
// ==========================================
// Полный SUPERCEDE — движковый PrimaryAttack M249 не вызывается.
// Пуля летит через TraceLine + TakeDamage (DMG_BULLET для совместимости с молнией).
public OnPrimaryAttack_Pre(pWeapon) {
    if (!IsCustomWeapon(pWeapon)) return HAM_IGNORED
    
    new id = get_member(pWeapon, m_pPlayer)
    if (!ValidOwner(id,pWeapon)) return HAM_SUPERCEDE
    if (get_member(pWeapon, m_Weapon_flNextPrimaryAttack) > 0.0) return HAM_SUPERCEDE
    
    new iClip = get_member(pWeapon, m_Weapon_iClip)
    if (iClip <= 0) return HAM_SUPERCEDE
    
    // Списание патрона
    set_member(pWeapon, m_Weapon_iClip, iClip - 1)
    
    // Hitscan: TraceLine от глаз игрока
    new Float:vOrigin[3], Float:vAngles[3], Float:vForward[3], Float:vRight[3], Float:vUp[3], Float:vViewOfs[3]
    get_entvar(id, var_origin, vOrigin)
    get_entvar(id, var_v_angle, vAngles)
    get_entvar(id, var_view_ofs, vViewOfs)
    
    angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward)
    angle_vector(vAngles, ANGLEVECTOR_RIGHT, vRight)
    angle_vector(vAngles, ANGLEVECTOR_UP, vUp)
    
    vOrigin[0] += vViewOfs[0]
    vOrigin[1] += vViewOfs[1]
    vOrigin[2] += vViewOfs[2]
    
    // Небольшой разброс
    new Float:flSpX = random_float(-0.03, 0.03)
    new Float:flSpY = random_float(-0.03, 0.03)
    
    new Float:vEnd[3]
    vEnd[0] = vOrigin[0] + (vForward[0] + vRight[0] * flSpX + vUp[0] * flSpY) * 8192.0
    vEnd[1] = vOrigin[1] + (vForward[1] + vRight[1] * flSpX + vUp[1] * flSpY) * 8192.0
    vEnd[2] = vOrigin[2] + (vForward[2] + vRight[2] * flSpX + vUp[2] * flSpY) * 8192.0
    
    engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, id, 0)
    
    new iHit = get_tr2(0, TR_pHit)
    if (iHit >= 1 && iHit <= MaxClients && is_user_alive(iHit) && zp_get_user_zombie(iHit)) {
        g_UsasShot[id]=pWeapon;
        ExecuteHamB(Ham_TakeDamage, iHit, id, id, WEAPON_P_DMG, DMG_BULLET | DMG_NEVERGIB)
        g_UsasShot[id]=0
    }
    
    // Тайминги
    set_member(pWeapon, m_Weapon_flNextPrimaryAttack, WEAPON_P_RATE)
    set_member(pWeapon, m_Weapon_flNextSecondaryAttack, WEAPON_P_RATE)
    set_member(pWeapon, m_Weapon_flTimeWeaponIdle, WEAPON_P_RATE + 1.5)
    
    // Эффекты
    SendWeaponAnim(id, random(2) ? ANIM_SHOOT1 : ANIM_SHOOT2)
    emit_sound(id, CHAN_WEAPON, SND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    Weapon_MuzzleFlash(id, SPR_MUZZLE, 0.06, 255.0, 1)
    
    new Float:vPunch[3]
    vPunch[0] = random_float(-1.5, -0.5)
    set_entvar(id, var_punchangle, vPunch)
    
    return HAM_SUPERCEDE
}

// ==========================================
// [ ПЕРЕЗАРЯДКА (через RG_ItemPostFrame) ]
// ==========================================
public OnWeaponItemPostFrame_Pre(pWeapon) {
    if (!IsCustomWeapon(pWeapon)) return HC_CONTINUE
    
    new id = get_member(pWeapon, m_pPlayer)
    if (!ValidOwner(id,pWeapon)) return HC_CONTINUE
    
    new iButton   = get_entvar(id, var_button)
    new iClip     = get_member(pWeapon, m_Weapon_iClip)
    new iAmmoIdx  = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
    new iBPAmmo   = get_member(id, m_rgAmmo, iAmmoIdx)
    
    // Начало перезарядки: R нажата, или пустой магазин при стрельбе
    if (((iButton & IN_RELOAD) || (iClip == 0 && (iButton & IN_ATTACK))) && !get_member(pWeapon, m_Weapon_fInReload)) {
        if (iClip < WEAPON_AMMO && iBPAmmo > 0) {
            set_member(pWeapon, m_Weapon_fInReload, 1)
            SendWeaponAnim(id, ANIM_RELOAD)
            set_member(id, m_flNextAttack, RELOAD_TIME)
            set_member(pWeapon, m_Weapon_flTimeWeaponIdle, RELOAD_TIME + 0.5)
            set_member(pWeapon, m_Weapon_flNextPrimaryAttack, RELOAD_TIME)
            set_member(pWeapon, m_Weapon_flNextSecondaryAttack, RELOAD_TIME)
            return HC_SUPERCEDE
        } else if (iButton & IN_RELOAD) {
            // Нельзя перезарядиться — убираем кнопку, чтобы движок не обработал
            set_entvar(id, var_button, iButton & ~IN_RELOAD)
        }
    }
    
    // Завершение перезарядки по таймеру
    if (get_member(pWeapon, m_Weapon_fInReload)) {
        new Float:flNext = get_member(id, m_flNextAttack)
        if (flNext <= 0.0) {
            iClip    = get_member(pWeapon, m_Weapon_iClip)
            iAmmoIdx = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
            iBPAmmo  = get_member(id, m_rgAmmo, iAmmoIdx)
            
            new iAdd = WEAPON_AMMO - iClip
            if (iAdd > iBPAmmo) iAdd = iBPAmmo
            
            set_member(pWeapon, m_Weapon_iClip, iClip + iAdd)
            
            // Списание запаса патронов и обновление HUD
            set_member(id, m_rgAmmo, iBPAmmo - iAdd, iAmmoIdx)
            
            message_begin(MSG_ONE, g_msgAmmoX, .player = id)
            write_byte(iAmmoIdx)
            write_byte(iBPAmmo - iAdd)
            message_end()
            set_member(pWeapon, m_Weapon_fInReload, 0)
            return HC_SUPERCEDE
        }
        return HC_SUPERCEDE // Блокируем движковую перезарядку во время нашего таймера
    }
    return HC_CONTINUE
}

public OnWeaponReload_Pre(pWeapon) {
    if (!IsCustomWeapon(pWeapon)) return HAM_IGNORED
    return HAM_SUPERCEDE // Блокируем стандартную перезарядку M249
}

public OnWeaponIdle_Pre(pWeapon) {
    if (!IsCustomWeapon(pWeapon)) return HAM_IGNORED
    if (get_member(pWeapon, m_Weapon_flTimeWeaponIdle) > 0.0) return HAM_IGNORED
    
    new id = get_member(pWeapon, m_pPlayer)
    if (!ValidOwner(id,pWeapon)) return HAM_IGNORED
    
    SendWeaponAnim(id, ANIM_IDLE)
    set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 3.0)
    return HAM_SUPERCEDE
}

// ==========================================
// [ МЕХАНИКИ (заряды, ПКМ, пассивная молния) ]
// ==========================================
public OnPlayerPreThink_Post(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id) || !g_bHasUsas[id]) return HC_CONTINUE
    
    new pWeapon = get_member(id, m_pActiveItem)
    if (!is_nullent(pWeapon) && IsCustomWeapon(pWeapon)) {
        
        new iButton = get_entvar(id, var_button)
        new iOldButton = get_entvar(id, var_oldbuttons)
        
        // Пассивное накопление зарядов
        if (g_iCharges[id] < MAX_CHARGES) {
            if (get_gametime() >= g_flNextCharge[id]) {
                g_iCharges[id]++
                g_flNextCharge[id] = get_gametime() + CHARGE_TIME
                UpdateHUDAmmo2(id, g_iCharges[id])
                
                if (g_iCharges[id] == 1 && !g_bHasModel2[id]) {
                    g_bHasModel2[id] = true
                    set_entvar(id, var_viewmodel, V_MODEL_2)
                }
            }
        }
        
        // Вторичная атака (ПКМ) — снаряд молнии
        if ((iButton & IN_ATTACK2) && !(iOldButton & IN_ATTACK2)) {
            if (g_iCharges[id] > 0) {
                if (get_member(pWeapon, m_Weapon_flNextSecondaryAttack) <= 0.0 && get_member(pWeapon, m_Weapon_fInReload) == 0 && get_member(id, m_flNextAttack) <= 0.0) {
                    
                    g_iCharges[id]--
                    UpdateHUDAmmo2(id, g_iCharges[id])
                    
                    if (g_iCharges[id] == 0) {
                        g_bHasModel2[id] = false
                        set_entvar(id, var_viewmodel, V_MODEL_1)
                    }
                    
                    SendWeaponAnim(id, ANIM_SHOOT3)
                    emit_sound(id, CHAN_WEAPON, SND_SHOOT_RMB, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                    Weapon_MuzzleFlash(id, SPR_MUZZLE, 0.08, 255.0, 1)
                    
                    FireProjectile_RMB(id)
                    
                    set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 1.0)
                    set_member(pWeapon, m_Weapon_flNextPrimaryAttack, 1.0)
                    set_member(pWeapon, m_Weapon_flNextSecondaryAttack, 1.0)
                    set_member(id, m_flNextAttack, 1.0)
                    
                    new Float:vPunch[3]
                    vPunch[0] = -5.0
                    set_entvar(id, var_punchangle, vPunch)
                }
            }
        }
    }
    return HC_CONTINUE
}

public OnTakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type) {
    // Только пулевой урон (DMG_BULLET) триггерит молнию, не DMG_GENERIC от гранат/энтити
    if (!(damage_type & DMG_BULLET)) return HC_CONTINUE
    
    if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients) return HC_CONTINUE
    if (!is_user_connected(attacker) || !is_user_connected(victim)) return HC_CONTINUE
    if (attacker == victim || !g_bHasUsas[attacker] || !g_UsasShot[attacker] || !is_user_alive(victim)) return HC_CONTINUE
    
    if (zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker)) {
        new pActive = get_member(attacker, m_pActiveItem)
        if (!is_nullent(pActive) && IsCustomWeapon(pActive)) {
            
            g_iHits[attacker]++
            if (g_iHits[attacker] >= 5) {
                g_iHits[attacker] = 0
                
                SpawnStaticModel(victim, MDL_EXP1, false)
                emit_sound(victim, CHAN_AUTO, SND_LIGHT_5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                
                ExecuteHamB(Ham_TakeDamage, victim, attacker, attacker, WEAPON_LIGHTNING_DMG, DMG_ENERGYBEAM | DMG_NEVERGIB)
            }
        }
    }
    return HC_CONTINUE
}

// ==========================================
// [ СНАРЯД И ЭФФЕКТЫ ]
// ==========================================
// Создание летящего снаряда ПКМ
stock FireProjectile_RMB(id) {
    if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < MIN_FREE_EDICTS) return
    
    new ent = rg_create_entity("info_target")
    if (is_nullent(ent)) return
    
    set_entvar(ent, var_classname, CLASS_PROJ)
    set_entvar(ent, var_impulse, PROJ_IMPULSE)
    engfunc(EngFunc_SetModel, ent, SPR_PROJ)
    
    new Float:vOrigin[3], Float:vAngles[3], Float:vFwd[3], Float:vViewOfs[3]
    get_entvar(id, var_origin, vOrigin)
    get_entvar(id, var_v_angle, vAngles)
    get_entvar(id, var_view_ofs, vViewOfs)
    angle_vector(vAngles, ANGLEVECTOR_FORWARD, vFwd)
    
    vOrigin[0] += vViewOfs[0]
    vOrigin[1] += vViewOfs[1]
    vOrigin[2] += vViewOfs[2]
    set_entvar(ent, var_origin, vOrigin)
    
    set_entvar(ent, var_owner, id)
    set_entvar(ent, var_movetype, MOVETYPE_FLY)
    set_entvar(ent, var_solid, SOLID_BBOX)
    set_entvar(ent, var_mins, Float:{-2.0, -2.0, -2.0})
    set_entvar(ent, var_maxs, Float:{2.0, 2.0, 2.0})
    
    set_entvar(ent, var_rendermode, kRenderTransAdd)
    set_entvar(ent, var_renderamt, 255.0)
    set_entvar(ent, var_scale, 0.75) // Reduced scale
    
    set_entvar(ent, var_frame, 0.0)
    set_entvar(ent, var_fuser1, get_gametime() + PROJ_LIFETIME) // Self-destruct timer
    set_entvar(ent, var_nextthink, get_gametime() + 0.1)
    
    new Float:vVel[3]
    vVel[0] = vFwd[0] * PROJ_SPEED
    vVel[1] = vFwd[1] * PROJ_SPEED
    vVel[2] = vFwd[2] * PROJ_SPEED
    set_entvar(ent, var_velocity, vVel)
    set_entvar(ent, var_angles, vAngles)
}

public OnInfoTargetThink_Pre(ent) {
    if (is_nullent(ent)) return HAM_IGNORED
    
    new iImpulse = get_entvar(ent, var_impulse)
    new Float:flTime = get_gametime()
    if((iImpulse==PROJ_IMPULSE || iImpulse==FX_IMPULSE_CHAIN) && (!is_user_alive(get_entvar(ent,var_owner)) || zp_get_user_zombie(get_entvar(ent,var_owner)))){set_entvar(ent,var_flags,FL_KILLME);return HAM_SUPERCEDE;}
    
    // Projectile sprite animation + self-destruct
    if (iImpulse == PROJ_IMPULSE) {
        if (flTime > get_entvar(ent, var_fuser1)) {
            set_entvar(ent, var_flags, FL_KILLME)
            return HAM_SUPERCEDE
        }
        new Float:flFrame = get_entvar(ent, var_frame)
        flFrame += 1.0
        if (flFrame > 15.0) flFrame = 0.0
        set_entvar(ent, var_frame, flFrame)
        set_entvar(ent, var_nextthink, flTime + 0.05)
        return HAM_SUPERCEDE
    }
    
    // FX model tick (пассивная молния + взрыв на полу)
    if (iImpulse == FX_IMPULSE_LIGHT || iImpulse == FX_IMPULSE_FLOOR) {
        if (flTime > get_entvar(ent, var_fuser1)) {
            set_entvar(ent, var_flags, FL_KILLME)
            return HAM_SUPERCEDE
        }
        
        // Следование за игроком (пассивная молния)
        if (iImpulse == FX_IMPULSE_LIGHT) {
            new target = get_entvar(ent, var_owner)
            if (is_user_alive(target)) {
                new Float:vOrigin[3]
                get_entvar(target, var_origin, vOrigin)
                vOrigin[2] += FX_Z_OFFSET
                set_entvar(ent, var_origin, vOrigin)
            } else {
                set_entvar(ent, var_flags, FL_KILLME)
                return HAM_SUPERCEDE
            }
        }
        
        set_entvar(ent, var_nextthink, flTime + 0.05)
        return HAM_SUPERCEDE
    }
    
    // Цепная молния ПКМ — персистентный эффект с тик-уроном
    if (iImpulse == FX_IMPULSE_CHAIN) {
        if (flTime > get_entvar(ent, var_fuser1)) {
            set_entvar(ent, var_flags, FL_KILLME)
            return HAM_SUPERCEDE
        }
        
        new target = get_entvar(ent, var_iuser1)
        new attacker = get_entvar(ent, var_owner)
        
        // Цель умерла — пробуем переключиться досрочно
        if (!is_user_alive(target) || !zp_get_user_zombie(target)) {
            new iChainsLeft = get_entvar(ent, var_iuser2)
            if (iChainsLeft > 0) {
                new Float:vPos[3]
                get_entvar(ent, var_origin, vPos)
                new nextT = FindNextChainTarget(attacker, target, vPos)
                if (nextT > 0) {
                    set_entvar(ent, var_iuser1, nextT)
                    set_entvar(ent, var_iuser2, iChainsLeft - 1)
                    new Float:flRem = Float:get_entvar(ent, var_fuser1) - flTime
                    new iNewChains = iChainsLeft - 1
                    set_entvar(ent, var_fuser3, flTime + flRem / float(iNewChains + 1))
                    target = nextT
                    emit_sound(target, CHAN_AUTO, SND_LIGHT_5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                } else {
                    set_entvar(ent, var_flags, FL_KILLME)
                    return HAM_SUPERCEDE
                }
            } else {
                set_entvar(ent, var_flags, FL_KILLME)
                return HAM_SUPERCEDE
            }
        }
        
        // Следование за текущей целью
        new Float:vOrigin[3]
        get_entvar(target, var_origin, vOrigin)
        vOrigin[2] += FX_Z_OFFSET
        set_entvar(ent, var_origin, vOrigin)
        
        // Тик урона
        if (flTime >= Float:get_entvar(ent, var_fuser2)) {
            if (is_user_connected(attacker)) {
                ExecuteHamB(Ham_TakeDamage, target, ent, attacker, CHAIN_TICK_DMG, DMG_ENERGYBEAM | DMG_NEVERGIB)
                if(is_nullent(ent)||(get_entvar(ent,var_flags)&FL_KILLME))return HAM_SUPERCEDE
                emit_sound(target, CHAN_AUTO, SND_LIGHT_5, 0.4, ATTN_NORM, 0, PITCH_NORM)
            }
            set_entvar(ent, var_fuser2, flTime + CHAIN_TICK)
        }
        
        // Переключение на следующую цель по таймеру
        new iChainsLeft = get_entvar(ent, var_iuser2)
        if (iChainsLeft > 0 && flTime >= Float:get_entvar(ent, var_fuser3)) {
            new nextT = FindNextChainTarget(attacker, target, vOrigin)
            if (nextT > 0) {
                set_entvar(ent, var_iuser1, nextT)
                set_entvar(ent, var_iuser2, iChainsLeft - 1)
                iChainsLeft--
                if (iChainsLeft > 0) {
                    new Float:flRem = Float:get_entvar(ent, var_fuser1) - flTime
                    set_entvar(ent, var_fuser3, flTime + flRem / float(iChainsLeft + 1))
                }
                emit_sound(nextT, CHAN_AUTO, SND_LIGHT_5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                // Перезапуск анимации при смене цели
                set_entvar(ent, var_animtime, flTime)
                set_entvar(ent, var_frame, 0.0)
            }
        }
        
        // Зацикливание анимации модели
        new Float:flAnimTime = Float:get_entvar(ent, var_animtime)
        if (flTime - flAnimTime >= 1.0) {
            set_entvar(ent, var_animtime, flTime)
            set_entvar(ent, var_frame, 0.0)
        }
        
        set_entvar(ent, var_nextthink, flTime + 0.05)
        return HAM_SUPERCEDE
    }
    
    return HAM_IGNORED
}

public OnInfoTargetTouch_Pre(ent, touched) {
    if (is_nullent(ent)) return HAM_IGNORED
    if (get_entvar(ent, var_impulse) != PROJ_IMPULSE) return HAM_IGNORED
    
    new id = get_entvar(ent, var_owner)
    if (touched == id) return HAM_SUPERCEDE
    if((get_entvar(ent,var_flags)&FL_KILLME)||!is_user_alive(id)||zp_get_user_zombie(id))return HAM_SUPERCEDE
    set_entvar(ent,var_solid,SOLID_NOT)
    set_entvar(ent,var_flags,FL_KILLME)
    
    new Float:vOrigin[3]
    get_entvar(ent, var_origin, vOrigin)
    ExplodeRMB(id, vOrigin)
    
    set_entvar(ent, var_flags, FL_KILLME)
    set_entvar(ent, var_nextthink, -1.0)
    return HAM_SUPERCEDE
}

stock ExplodeRMB(id, Float:vOrigin[3]) {
    // Эффект взрыва на полу
    new Float:vTraceEnd[3], Float:vFloor[3]
    vTraceEnd[0] = vOrigin[0]
    
    vTraceEnd[1] = vOrigin[1]
    vTraceEnd[2] = vOrigin[2] - 8192.0
    engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, vFloor)
    vFloor[2] += 5.0
    SpawnStaticModel(0, MDL_EXP2, true, vFloor)
    
    // Подсчёт зомби в радиусе + ближайший таргет
    new bestTarget = 0, Float:bestDist = WEAPON_RMB_RADIUS, numInRadius = 0
    
    for (new t = 1; t <= MaxClients; t++) {
        if (!is_user_alive(t) || !zp_get_user_zombie(t) || t == id) continue
        new Float:tOrigin[3]
        get_entvar(t, var_origin, tOrigin)
        new Float:dist = vector_distance(vOrigin, tOrigin)
        if (dist <= WEAPON_RMB_RADIUS) {
            numInRadius++
            if (dist < bestDist) {
                bestDist = dist
                bestTarget = t
            }
        }
    }
    
    if (bestTarget > 0) {
        new iChains = numInRadius - 1
        if (iChains >= CHAIN_MAX_TARGETS) iChains = CHAIN_MAX_TARGETS - 1
        SpawnChainLightning(id, bestTarget, iChains)
    }
}

// Создание персистентной цепной молнии — одна модель, тикает урон, прыгает по целям
stock SpawnChainLightning(attacker, firstTarget, chainsRemaining) {
    if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < MIN_FREE_EDICTS) return
    
    new ent = rg_create_entity("info_target")
    if (is_nullent(ent)) return
    
    engfunc(EngFunc_SetModel, ent, MDL_EXP3)
    
    set_entvar(ent, var_classname, "usas_chain_fx")
    set_entvar(ent, var_impulse, FX_IMPULSE_CHAIN)
    set_entvar(ent, var_owner, attacker)
    set_entvar(ent, var_iuser1, firstTarget)       // Текущая цель
    set_entvar(ent, var_iuser2, chainsRemaining)   // Оставшиеся прыжки
    
    new Float:flTime = get_gametime()
    new Float:flSegment = CHAIN_DURATION / float(chainsRemaining + 1)
    
    set_entvar(ent, var_fuser1, flTime + CHAIN_DURATION)  // Общий конец
    set_entvar(ent, var_fuser2, flTime + CHAIN_TICK)       // Следующий тик урона
    set_entvar(ent, var_fuser3, flTime + flSegment)        // Время переключения на след. цель
    
    new Float:vOrigin[3]
    get_entvar(firstTarget, var_origin, vOrigin)
    vOrigin[2] += FX_Z_OFFSET
    set_entvar(ent, var_origin, vOrigin)
    
    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP)
    set_entvar(ent, var_solid, SOLID_NOT)
    set_entvar(ent, var_rendermode, kRenderTransAdd)
    set_entvar(ent, var_renderamt, 255.0)
    set_entvar(ent, var_sequence, 0)
    set_entvar(ent, var_animtime, flTime)
    set_entvar(ent, var_framerate, 1.0)
    
    engfunc(EngFunc_SetSize, ent, Float:{-256.0, -256.0, -256.0}, Float:{256.0, 256.0, 256.0})
    
    emit_sound(firstTarget, CHAN_AUTO, SND_LIGHT_5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    set_entvar(ent, var_nextthink, flTime + 0.05)
}

// Поиск следующей цели для цепной молнии (ближайший зомби, кроме текущего)
stock FindNextChainTarget(attacker, currentTarget, Float:vOrigin[3]) {
    new bestTarget = 0, Float:bestDist = WEAPON_RMB_RADIUS
    for (new i = 1; i <= MaxClients; i++) {
        if (!is_user_alive(i) || !zp_get_user_zombie(i)) continue
        if (i == attacker || i == currentTarget) continue
        new Float:tOrigin[3]
        get_entvar(i, var_origin, tOrigin)
        new Float:dist = vector_distance(vOrigin, tOrigin)
        if (dist < bestDist) {
            bestDist = dist
            bestTarget = i
        }
    }
    return bestTarget
}

// Спавн статической модели эффекта (пассивная молния / взрыв на полу)
stock SpawnStaticModel(target = 0, const szModel[], bool:bFloorExplosion = false, Float:vFloorOrigin[3] = {0.0,0.0,0.0}) {
    if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < MIN_FREE_EDICTS) return
    
    new ent = rg_create_entity("info_target")
    if (is_nullent(ent)) return
    
    engfunc(EngFunc_SetModel, ent, szModel)
    new Float:flTime = get_gametime()
    
    if (bFloorExplosion) {
        set_entvar(ent, var_classname, "usas_fx")
        set_entvar(ent, var_impulse, FX_IMPULSE_FLOOR)
        set_entvar(ent, var_origin, vFloorOrigin)
        set_entvar(ent, var_renderamt, 255.0)
        emit_sound(ent, CHAN_AUTO, SND_LIGHT_RMB, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    } else {
        set_entvar(ent, var_classname, "usas_light_fx")
        set_entvar(ent, var_impulse, FX_IMPULSE_LIGHT)
        set_entvar(ent, var_owner, target)
        
        new Float:vOrigin[3]
        get_entvar(target, var_origin, vOrigin)
        vOrigin[2] += FX_Z_OFFSET  // Поднято выше, чтобы покрывать зомби целиком
        
        set_entvar(ent, var_renderamt, 255.0)
        set_entvar(ent, var_origin, vOrigin)
    }
    
    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP)
    set_entvar(ent, var_solid, SOLID_NOT)
    set_entvar(ent, var_rendermode, kRenderTransAdd)
    set_entvar(ent, var_sequence, 0)
    set_entvar(ent, var_animtime, flTime)
    set_entvar(ent, var_framerate, 1.0)
    set_entvar(ent, var_fuser1, flTime + FX_LIFETIME)
    
    engfunc(EngFunc_SetSize, ent, Float:{-256.0, -256.0, -256.0}, Float:{256.0, 256.0, 256.0})
    
    set_entvar(ent, var_nextthink, flTime + 0.05)
}

// ==========================================
// [ UTILS ]
// ==========================================
stock SendWeaponAnim(id, iAnim) {
    if(!is_user_alive(id)||iAnim<0||iAnim>ANIM_DRAW)return;
    new w=get_member(id,m_pActiveItem);if(is_nullent(w)||!IsCustomWeapon(w))return;
    set_entvar(id, var_weaponanim, iAnim)
    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
    write_byte(iAnim)
    write_byte(0)
    message_end()
}

stock UpdateHUDAmmo2(id, iAmount) {
    message_begin(MSG_ONE, g_msgAmmoX, .player = id)
    write_byte(28) 
    write_byte(iAmount)
    message_end()
}

stock SendWeaponList(id, const wpnName[], pAmmoID, pAmmoMax, sAmmoID, sAmmoMax, slot, number, csw, flags) {
    message_begin(MSG_ONE, g_msgWeaponList, .player = id)
    write_string(wpnName)     
    write_byte(pAmmoID)       
    write_byte(pAmmoMax)      
    write_byte(sAmmoID)       
    write_byte(sAmmoMax)      
    write_byte(slot)          
    write_byte(number)        
    write_byte(csw)           
    write_byte(flags)         
    message_end()
}

stock Weapon_MuzzleFlash(const iPlayer, const szSprite[], const Float:flScale, const Float:flBrightness, const iAttachment) {
    new iSprite = rg_create_entity("env_sprite", false)
    if (is_nullent(iSprite)) return 0
    
    engfunc(EngFunc_SetModel, iSprite, szSprite)
    set_entvar(iSprite, var_spawnflags, SF_SPRITE_ONCE)
    set_entvar(iSprite, var_classname, MUZZLE_CLASSNAME)
    set_entvar(iSprite, var_impulse, g_iszSpriteKey)
    set_entvar(iSprite, var_owner, iPlayer)
    set_entvar(iSprite, var_aiment, iPlayer)
    set_entvar(iSprite, var_body, iAttachment)
    set_entvar(iSprite, var_rendermode, kRenderTransAdd)
    set_entvar(iSprite, var_renderamt, flBrightness)
    set_entvar(iSprite, var_renderfx, kRenderFxNone)
    set_entvar(iSprite, var_scale, flScale)
    
    ExecuteHamB(Ham_Spawn, iSprite)
    // Sprite attachments can produce MOVETYPE_FOLLOW; keep it a free sprite.
    set_entvar(iSprite,var_movetype,MOVETYPE_NONE)
    set_entvar(iSprite,var_aiment,0)
    set_entvar(iSprite,var_skin,0)
    set_entvar(iSprite,var_body,0)
    new Float:pos[3],Float:ofs[3],Float:ang[3],Float:muzzleForward[3]
    get_entvar(iPlayer,var_origin,pos);get_entvar(iPlayer,var_view_ofs,ofs)
    get_entvar(iPlayer,var_v_angle,ang);angle_vector(ang,ANGLEVECTOR_FORWARD,muzzleForward)
    for(new axis;axis<3;axis++)pos[axis]+=ofs[axis]+muzzleForward[axis]*24.0
    engfunc(EngFunc_SetOrigin,iSprite,pos)
    
    set_entvar(iSprite, var_frame, 0.0)
    set_entvar(iSprite, var_nextthink, get_gametime() + MUZZLE_TIME)
    return iSprite
}

public CSprite_Think_Pre(const iSprite) {
    if (!pev_valid(iSprite) || !CustomSprite(iSprite)) return HAM_IGNORED;
    
    new Float:flFrame
    get_entvar(iSprite, var_frame, flFrame)
    flFrame += 1.0
    
    if (flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, 4)) {
        set_entvar(iSprite, var_frame, flFrame)
        set_entvar(iSprite, var_nextthink, get_gametime() + MUZZLE_TIME)
        return HAM_SUPERCEDE;
    }
    
    set_entvar(iSprite, var_flags, FL_KILLME)
    return HAM_SUPERCEDE;
}


stock bool:ValidOwner(id,w){return is_user_alive(id)&&!zp_get_user_zombie(id)&&get_member(id,m_pActiveItem)==w;}
public UsasKilled(id){ResetPlayerState(id);}
public UsasRound(){for(new id=1;id<=MaxClients;id++)ResetPlayerState(id);}
stock CleanupOwner(id){new e=-1;while((e=engfunc(EngFunc_FindEntityByString,e,"classname",CLASS_PROJ))>0)if(get_entvar(e,var_owner)==id)set_entvar(e,var_flags,FL_KILLME);e=-1;while((e=engfunc(EngFunc_FindEntityByString,e,"classname","usas_chain_fx"))>0)if(get_entvar(e,var_owner)==id)set_entvar(e,var_flags,FL_KILLME);}
public UsasRefill(plugin,argc){new id=get_param(1);if(!is_user_alive(id)||zp_get_user_zombie(id))return 0;new w=rg_find_weapon_bpack_by_name(id,WEAPON_NAME);if(is_nullent(w)||!IsCustomWeapon(w))return 0;new idx=get_member(w,m_Weapon_iPrimaryAmmoType);set_member(id,m_rgAmmo,max(get_member(id,m_rgAmmo,idx),get_param(2)?250:WEAPON_BPAMMO),idx);return 1;}
