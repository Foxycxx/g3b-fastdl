// ============================================================================
//    ███████╗██╗   ██╗██╗     ██████╗ ██╗  ██╗██╗██████╗ 
//    ██╔════╝╚██╗ ██╔╝██║     ██╔══██╗██║  ██║██║██╔══██╗
//    ███████╗ ╚████╔╝ ██║     ██████╔╝███████║██║██║  ██║
//    ╚════██║  ╚██╔╝  ██║     ██╔═══╝ ██╔══██║██║██║  ██║
//    ███████║   ██║   ███████╗██║     ██║  ██║██║██████╔╝
//    ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═════╝ 
// ============================================================================
//  Plugin:    [ZP] Extra Item: Sylphid
//  Version:   3.1 (ReAPI)
//  Author:    Kolmi ( divinezavet )
//  Telegram:  t.me/amxxplguins
// 
//  - Так называемый "трамплин" работает только на людей, не работает на зомби.
//  - Нету идей по поводу эффекта выстрела птицы, которая атакует в радиусе,
//    поэтому это может выглядить не очень, будто урон наносится из ниоткуда.
//
//  - Натив для выдачи - sylphid_give_weapon(id)
//  - Если хит спрайт слишком большой/долгий, регулируйте в CreateHitSprites
//  , там подписаны настройки.
// ============================================================================

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>

// ============================================================================
// [ НАСТРОЙКА EXTRA ITEM | ЗАКОММЕНТИРУЙТЕ ЧТОБЫ УБРАТЬ ИЗ МАГАЗИНА ]
// ============================================================================
//#define USE_EXTRA_ITEM         // <-- Закомментируйте эту строку, чтобы убрать из магазина ZP
#if defined USE_EXTRA_ITEM
new const ITEM_NAME[] = "Sylphid"  // Название в магазине
const ITEM_COST = 30                      // Цена в магазине
#endif

// ============================================================================
// [ ОСНОВНЫЕ НАСТРОЙКИ ОРУЖИЯ | WEAPON SETTINGS ]
// ============================================================================
const Float: WEAPON_DAMAGE          = 32.0      // Урон от пули пистолета
const Float: WEAPON_RATE            = 0.15      // Скорострельность (секунды между выстрелами)
const Float: WEAPON_RELOAD_TIME     = 2.0       // Время перезарядки (секунды)
const WEAPON_CLIP                   = 50        // Размер обоймы
const WEAPON_BPAMMO                 = 200       // Запас патронов

const Float: MAX_GAUGE              = 100.0     // Максимум шкалы энергии
const Float: JUMP_COST              = 40.0      // Стоимость Soaring Jump (ПКМ)
const Float: JUMP_POWER             = 600.0     // Сила подброса вверх при прыжке
const Float: GALE_COST              = 50.0      // Стоимость Gale Blast (зажатие ПКМ)
const Float: GAUGE_REGEN_RATE       = 3.0       // Скорость регенерации шкалы (%/сек)

const Float: PROJ_SPEED             = 1000.0    // Скорость снаряда Gale Blast
const Float: FIELD_LAUNCH_POWER     = 800.0     // Сила подброса трамплина
const Float: FIELD_RADIUS           = 120.0     // Радиус трамплина
const Float: FIELD_LIFETIME         = 5.0       // Время жизни трамплина (секунды)

const Float: BIRD_THINK_RATE        = 0.1       // Частота обновления логики птицы (секунды)
const Float: BIRD_ATTACK_RAD_NORM   = 300.0     // Радиус атаки птицы (обычный)
const Float: BIRD_ATTACK_RAD_FAST   = 600.0     // Радиус атаки птицы (при стрельбе)
const Float: BIRD_ATTACK_RATE_NORM  = 0.5       // Интервал атаки птицы (обычный)
const Float: BIRD_ATTACK_RATE_FAST  = 0.2       // Интервал атаки птицы (при стрельбе)
const Float: BIRD_ATTACK_DMG_NORM   = 10.0      // Урон птицы (обычный)
const Float: BIRD_ATTACK_DMG_FAST   = 20.0      // Урон птицы (при стрельбе)

// ============================================================================
// [ ПУТИ К ФАЙЛАМ | RESOURCE PATHS ]
// ============================================================================
new const V_MODEL[]         = "models/g3bmodel/ZTHEX/zpt/v_jumpspirit.mdl"      // Модель от первого лица
new const P_MODEL[]         = "models/zpt/p_jumpspirit.mdl"      // Модель от третьего лица
new const W_MODEL[]         = "models/zpt/w_jumpspirit.mdl"      // Модель на земле
new const BIRD_MODEL[]      = "models/zpt/ef_jumpspirit_summon.mdl"  // Модель духа (птицы)
new const PROJ_MODEL[]      = "models/zpt/ef_jumpspirit_projectile.mdl" // Модель снаряда
new const FIELD_MODEL[]     = "models/zpt/ef_jumpspirit_field.mdl"   // Модель трамплина

new const SPR_WEAPONLIST[]  = "sprites/weapon_jumpspirit.txt"    // Файл описания худа
new const SPR_MUZZLEFLASH[] = "sprites/muzzleflash372.spr"       // Спрайт вспышки выстрела
new const SPR_HIT[]         = "sprites/zpt/ef_jumpspirit_hit.spr" // Спрайт попадания

new const SND_SHOOT[]       = "weapons/jumpspirit-1.wav"         // Звук выстрела
new const SND_JUMP_SOAR[]   = "weapons/jumpspirit_jump2.wav"     // Звук прыжка (Soaring Jump)
new const SND_READY[]       = "weapons/jumpspirit_ready.wav"     // Звук начала зарядки ПКМ
new const SND_SPIN[]        = "weapons/jumpspirit_spin.wav"      // Звук кручения при удержании
new const SND_SHOOT_B[]     = "weapons/jumpspirit-2-1.wav"       // Звук выстрела Gale Blast
new const SND_JUMP_FIELD[]  = "weapons/jumpspirit_jump1.wav"     // Звук подброса трамплином

// ============================================================================
// [ КОНСТАНТЫ И ИДЕНТИФИКАТОРЫ | CONSTANTS & IDS ]
// ============================================================================
const WEAPON_IMPULSE = 8855     // Метка оружия Sylphid (для идентификации через var_impulse)
const PROJ_IMPULSE   = 8866     // Метка снаряда Gale Blast
const FIELD_IMPULSE  = 8877     // Метка трамплина
const BIRD_IMPULSE   = 8888     // Метка птицы-духа
const MUZZLE_IMPULSE = 8899     // Метка маззлфлэш-спрайта
const MAX_FRAME_PDATA= 35       // Оффсет pdata для m_maxFrame спрайта
const Float: MUZZLE_TIME = 0.06 // Интервал кадров маззлфлэша

new const WEAPON_BASE[] = "weapon_p228"  // Базовое оружие (замена P228)
const WEAPON_BASE_ID    = CSW_P228       // ID базового оружия

// Индексы анимаций v_модели
enum {
	ANIM_IDLE = 0,       // #0 — Ожидание
	ANIM_SHOOT,          // #1 — Выстрел
	ANIM_RELOAD,         // #2 — Перезарядка
	ANIM_DRAW,           // #3 — Доставание
	ANIM_JUMP,           // #4 — Прыжок (тап ПКМ)
	ANIM_HOLD_START,     // #5 — Начало зарядки (зажатие ПКМ)
	ANIM_HOLD_LOOP,      // #6 — Цикл удержания (зажатие ПКМ)
	ANIM_SHOOT_B         // #7 — Выстрел Gale Blast (отпускание ПКМ)
}

// Состояния FSM правой кнопки мыши
enum PKMState {
	PKM_NONE = 0,        // Не нажата
	PKM_HOLD_START,      // Нажата, играет hold_start
	PKM_HOLD_LOOP        // Удерживается, играет hold_loop
}

#if defined USE_EXTRA_ITEM
new g_iItemID                                // ID зарегистрированного extra item
#endif
new g_iBirdEnt[MAX_CLIENTS + 1]              // Entity-индекс птицы каждого игрока
new Float:g_flLastTickTime[MAX_CLIENTS + 1]  // Время последнего тика (для дельты регенерации)
new g_iClipBefore[MAX_CLIENTS + 1]           // Патроны до выстрела (для детекции расхода)
new Float:g_flBirdBoostEnd[MAX_CLIENTS + 1]  // Время окончания ускорения птицы

new PKMState:g_iPKMState[MAX_CLIENTS + 1]    // Текущее состояние ПКМ (FSM)
new Float:g_flPKMPressTime[MAX_CLIENTS + 1]  // Время нажатия ПКМ
new Float:g_flPKMHoldLoopTime[MAX_CLIENTS + 1] // Время перехода hold_start -> hold_loop
new Float:g_flNextSpinSound[MAX_CLIENTS + 1] // Следующее воспроизведение звука кручения
new Float:g_flNextSpriteTime[MAX_CLIENTS + 1]// Кулдаун хит-спрайтов (антиспам)

new g_msgWeaponList, g_msgAmmoX               // ID сообщений WeaponList и AmmoX
new bool:g_Shooting[MAX_CLIENTS + 1]
new g_iBirdBeam;
new g_iSprHit                                 // Прекешированный индекс хит-спрайта

// Макрос проверки: является ли оружие Sylphid'ом
#define IsValidSylphid(%0) (!is_nullent(%0) && get_entvar(%0, var_impulse) == WEAPON_IMPULSE)

// ============================================================================
// [ ИНИЦИАЛИЗАЦИЯ | INIT & PRECACHE ]
// ============================================================================
public plugin_precache()
{
 g_iBirdBeam=precache_model("sprites/laserbeam.spr");
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(BIRD_MODEL)
	precache_model(PROJ_MODEL)
	precache_model(FIELD_MODEL)
	
	precache_model("sprites/640hud243.spr")
	precache_model("sprites/640hud224.spr")
	
	precache_generic(SPR_WEAPONLIST)
	precache_model(SPR_MUZZLEFLASH)
	g_iSprHit = precache_model(SPR_HIT)

	precache_sound(SND_SHOOT)
	precache_sound(SND_JUMP_SOAR)
	precache_sound(SND_READY)
	precache_sound(SND_SPIN)
	precache_sound(SND_SHOOT_B)
	precache_sound(SND_JUMP_FIELD)
}

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Sylphid", "3.1", "Kolmi")
	
	// Регистрация Extra Item (только если USE_EXTRA_ITEM определён)
	#if defined USE_EXTRA_ITEM
	g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_HUMAN)
	#endif
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)

	RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink", 1)
	RegisterHookChain(RG_CBasePlayerWeapon_ItemPostFrame, "OnWeaponItemPostFrame_Pre", 0) 
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled", 1)
	RegisterHookChain(RG_CWeaponBox_SetModel, "OnWeaponBoxSetModel_Post", 1)
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "OnAddPlayerItem_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, WEAPON_BASE, "OnWeaponDeploy_Post", 1)
	RegisterHam(Ham_Item_Holster, WEAPON_BASE, "OnWeaponHolster_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE, "OnPrimaryAttack_Pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE, "OnPrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "OnTraceAttack_Pre", 0)
	
	RegisterHam(Ham_Think, "info_target", "OnInfoTargetThink_Pre", 0)
	RegisterHam(Ham_Think, "env_sprite", "OnSpriteThink", 0)
	RegisterHam(Ham_Touch, "info_target", "OnInfoTargetTouch_Pre", 0)
	
	register_clcmd("weapon_jumpspirit", "CmdReplaceWeapon")
	
	g_msgWeaponList = get_user_msgid("WeaponList")
	g_msgAmmoX = get_user_msgid("AmmoX")
}

// Перенаправление команды "weapon_jumpspirit" на базовый P228
public CmdReplaceWeapon(id)
{
	engclient_cmd(id, WEAPON_BASE)
	return PLUGIN_HANDLED
}

// Натив для выдачи оружия из других плагинов: sylphid_give_weapon(id)
public plugin_natives()
{
	register_native("sylphid_give_weapon", "_native_give_weapon")
}

public _native_give_weapon(plugin, params)
{
	new id = get_param(1)
	if (!is_user_alive(id) || zp_get_user_zombie(id)) return 0
	return GiveSylphid(id)
}

// Игрок купил Extra Item из меню ZP
#if defined USE_EXTRA_ITEM
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
		GiveSylphid(id)
}
#endif

// ============================================================================
// [ ВЫДАЧА И СОБЫТИЯ ОРУЖИЯ | WEAPON CORE ]
// ============================================================================
GiveSylphid(id)
{
 if(!is_user_alive(id)||zp_get_user_zombie(id))return 0;
	// Сбрасываем все пистолеты игрока и выдаём новый P228
	rg_drop_items_by_slot(id, PISTOL_SLOT)
	
	new pWeapon = rg_give_item(id, WEAPON_BASE, GT_APPEND)
	if (is_nullent(pWeapon)) return 0
	
	set_entvar(pWeapon, var_impulse, WEAPON_IMPULSE) // Метим как Sylphid
	set_entvar(pWeapon, var_fuser1, MAX_GAUGE)       // Шкала на максимум
	
	// Устанавливаем кастомные патроны (50|300 вместо 13|52)
	set_member(pWeapon, m_Weapon_iClip, WEAPON_CLIP)
	new iAmmoIdx = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
	set_member(id, m_rgAmmo, WEAPON_BPAMMO, iAmmoIdx)
	
	g_flLastTickTime[id] = get_gametime()
	g_flBirdBoostEnd[id] = 0.0
	g_flNextSpriteTime[id] = 0.0
	
	// Переключаем на оружие и вызываем Deploy
	rg_switch_weapon(id, pWeapon)
	ExecuteHamB(Ham_Item_Deploy, pWeapon)
	
	SyncWeaponList(id, 1) // Отправляем кастомный WeaponList
 return 1;
}

// Блокируем стандартные анимации P228 на клиенте
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if (!is_user_alive(id)) return FMRES_IGNORED
	new pActive = get_member(id, m_pActiveItem)
	if (IsValidSylphid(pActive))
	{
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

// Кастомная w_модель при выбросе оружия на землю
public OnWeaponBoxSetModel_Post(box, const model[])
{
	if (!is_nullent(box))
	{
		new pWeapon = get_member(box, m_WeaponBox_rgpPlayerItems, 2) // Слот 2 = пистолеты
		if (IsValidSylphid(pWeapon))
		{
			engfunc(EngFunc_SetModel, box, W_MODEL)
			return HC_SUPERCEDE
		}
	}
	return HC_CONTINUE
}

// Синхронизация WeaponList при подборе/получении оружия
public OnAddPlayerItem_Post(id, pWeapon)
{
	if (is_nullent(pWeapon)) return HC_CONTINUE
	if (IsValidSylphid(pWeapon))
		SyncWeaponList(id, 1)  // Кастомный худ
	else if (get_member(pWeapon, m_iId) == WEAPON_BASE_ID)
		SyncWeaponList(id, 0)  // Стандартный P228 худ
		
	return HC_CONTINUE
}

// Доставание оружия — устанавливаем модели, сбрасываем таймеры и создаём птицу
public OnWeaponDeploy_Post(pWeapon)
{
	if (!IsValidSylphid(pWeapon)) return HAM_IGNORED
	
	new id = get_member(pWeapon, m_pPlayer)
	if (is_nullent(id) || !is_user_alive(id)) return HAM_IGNORED
	
	SyncWeaponList(id, 1)
	
	set_entvar(id, var_viewmodel, V_MODEL)
	set_entvar(id, var_weaponmodel, P_MODEL)

	
	SendWeaponAnim(id, ANIM_DRAW)
	
	set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 1.0)
	set_member(pWeapon, m_Weapon_flNextPrimaryAttack, 0.5)
	set_member(pWeapon, m_Weapon_flNextSecondaryAttack, 0.5)
	
	g_iPKMState[id] = PKM_NONE  // Сброс FSM ПКМ (защита от залоченных таймеров)
	g_flLastTickTime[id] = get_gametime()
	g_flBirdBoostEnd[id] = 0.0
	CreateBird(id)
	
	UpdateGaugeHUD(id, pWeapon) 
	return HAM_IGNORED
}

// Убирание оружия — сброс ПКМ-таймеров, удаление птицы, стоп звуков
public OnWeaponHolster_Post(pWeapon)
{
	if (!IsValidSylphid(pWeapon)) return HAM_IGNORED
	
	new id = get_member(pWeapon, m_pPlayer)
	if (is_user_connected(id))
	{
		// Сброс состояния ПКМ и разблокировка таймеров (99.0 -> 0.1)
		if (g_iPKMState[id] != PKM_NONE)
		{
			g_iPKMState[id] = PKM_NONE
			set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 0.1)
			set_member(pWeapon, m_Weapon_flNextPrimaryAttack, 0.1)
			set_member(pWeapon, m_Weapon_flNextSecondaryAttack, 0.1)
		}
		
		RemoveBird(id)
		StopHoldSounds(id)
		set_member(pWeapon, m_Weapon_fInReload, 0) // Отмена перезарядки при свапе
	}
	return HAM_IGNORED
}

public zp_user_infected_post(id, infector)
{
	CleanupSylphid(id)
	StopHoldSounds(id)
}

public OnPlayerKilled(id, attacker, shouldgib)
{
	CleanupSylphid(id)
	StopHoldSounds(id)
}

public client_disconnected(id)
{
	CleanupSylphid(id)
	StopHoldSounds(id)
}

// ============================================================================
// [ СТРЕЛЬБА И ПЕРЕЗАРЯДКА ]
// ============================================================================
public OnPrimaryAttack_Pre(pWeapon)
{
	if (!IsValidSylphid(pWeapon)) return HAM_IGNORED
	new id = get_member(pWeapon, m_pPlayer)
	g_Shooting[id] = true
	g_iClipBefore[id] = get_member(pWeapon, m_Weapon_iClip)
	return HAM_IGNORED
}

public OnPrimaryAttack_Post(pWeapon)
{
	if (!IsValidSylphid(pWeapon)) return HAM_IGNORED
	
	new id = get_member(pWeapon, m_pPlayer)
	g_Shooting[id] = false
	if (is_user_alive(id) && get_member(pWeapon, m_Weapon_iClip) < g_iClipBefore[id])
	{
		SendWeaponAnim(id, ANIM_SHOOT)
		emit_sound(id, CHAN_WEAPON, SND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		Weapon_MuzzleFlash(id, SPR_MUZZLEFLASH, 0.1, 255.0, 1)
		
		set_member(pWeapon, m_Weapon_flNextPrimaryAttack, WEAPON_RATE)
		set_member(pWeapon, m_Weapon_flNextSecondaryAttack, WEAPON_RATE)
		set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 1.0)
		
		g_flBirdBoostEnd[id] = get_gametime() + 2.0
		CreateHitSprites(id)
	}
	return HAM_IGNORED
}

// Переопределение урона от пуль пистолета на кастомное значение
public OnTraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], trace, damage_type)
{
 if(!is_user_alive(attacker)||zp_get_user_zombie(attacker)||!g_Shooting[attacker]||!(damage_type&DMG_BULLET))return HAM_IGNORED;
 if(!IsValidSylphid(get_member(attacker,m_pActiveItem)))return HAM_IGNORED;
 if(!zp_get_user_zombie(victim)){SetHamParamFloat(3,0.0);return HAM_SUPERCEDE;}
 SetHamParamFloat(3,WEAPON_DAMAGE);
 return HAM_HANDLED;
}

// PRE-хук на ItemPostFrame — полностью кастомная перезарядка (50 патронов вместо 13)
public OnWeaponItemPostFrame_Pre(pWeapon)
{
	if (!IsValidSylphid(pWeapon)) return HC_CONTINUE
	
	static id; id = get_member(pWeapon, m_pPlayer)
	if (!is_user_alive(id)) return HC_CONTINUE
	
	static iButton; iButton = get_entvar(id, var_button)
	static iClip; iClip = get_member(pWeapon, m_Weapon_iClip)
	static iAmmoIdx; iAmmoIdx = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
	static iBPAmmo; iBPAmmo = get_member(id, m_rgAmmo, iAmmoIdx)
	
	// Начало перезарядки: игрок нажал R или магазин пуст при стрельбе
	if (((iButton & IN_RELOAD) || (iClip == 0 && (iButton & IN_ATTACK))) && !get_member(pWeapon, m_Weapon_fInReload) && get_member(id,m_flNextAttack)<=0.0 && g_iPKMState[id]==PKM_NONE)
	{
		if (iClip < WEAPON_CLIP && iBPAmmo > 0)
		{
			set_member(pWeapon, m_Weapon_fInReload, 1)
			SendWeaponAnim(id, ANIM_RELOAD)
			
			set_member(id, m_flNextAttack, WEAPON_RELOAD_TIME)
			set_member(pWeapon, m_Weapon_flTimeWeaponIdle, WEAPON_RELOAD_TIME + 0.5)
			set_member(pWeapon, m_Weapon_flNextPrimaryAttack, WEAPON_RELOAD_TIME)
			set_member(pWeapon, m_Weapon_flNextSecondaryAttack, WEAPON_RELOAD_TIME)
			return HC_SUPERCEDE // Блокируем ванильную логику перезарядки
		}
		else if (iButton & IN_RELOAD)
		{
			// Не можем начать перезарядку (либо полон, либо нет патронов)
			set_entvar(id, var_button, iButton & ~IN_RELOAD)
		}
	}
	
	// Завершение перезарядки: таймер истёк, заполняем обойму до 50
	if (get_member(pWeapon, m_Weapon_fInReload))
	{
		static Float:flNextAttack; flNextAttack = get_member(id, m_flNextAttack)
		if (flNextAttack <= 0.0)
		{
			iClip = get_member(pWeapon, m_Weapon_iClip)
			iAmmoIdx = get_member(pWeapon, m_Weapon_iPrimaryAmmoType)
			iBPAmmo = get_member(id, m_rgAmmo, iAmmoIdx)
			
			static iNeed; iNeed = WEAPON_CLIP - iClip
			if (iNeed > iBPAmmo) iNeed = iBPAmmo
			
			set_member(pWeapon, m_Weapon_iClip, iClip + iNeed)
			set_member(id, m_rgAmmo, iBPAmmo - iNeed, iAmmoIdx)
			set_member(pWeapon, m_Weapon_fInReload, 0)
			
			return HC_SUPERCEDE // Блокируем движковый лимит в 13 патронов
		}
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE
}

// ============================================================================
// [ МЕХАНИКА ПКМ И ГЕЙДЖА ]
// ============================================================================
public OnPlayerPreThink(id)
{
	if (!is_user_alive(id)) return HC_CONTINUE
	
	new pActive = get_member(id, m_pActiveItem)
	if (IsValidSylphid(pActive))
	{
		new iButton = get_entvar(id, var_button)
		new iOldButtons = get_entvar(id, var_oldbuttons)
		new Float:flGauge = get_entvar(pActive, var_fuser1)
		new Float:flTime = get_gametime()
		
		// Пассивная регенерация шкалы энергии
		new Float:flDelta = flTime - g_flLastTickTime[id]
		
		if (flDelta > 0.0)
		{
			g_flLastTickTime[id] = flTime
			
			if (flGauge < MAX_GAUGE)
			{
				new iOldParam = floatround(flGauge, floatround_floor)
				flGauge += (GAUGE_REGEN_RATE * flDelta)
				
				if (flGauge > MAX_GAUGE) flGauge = MAX_GAUGE
				set_entvar(pActive, var_fuser1, flGauge)
					
				if (floatround(flGauge, floatround_floor) != iOldParam)
					UpdateGaugeHUD(id, pActive)
			}
		}

		// ===================== FSM правой кнопки мыши =====================
		// ПКМ только что нажата — запуск hold_start (только если не жмем перезарядку и не в процессе)
		if ((iButton & IN_ATTACK2) && !(iOldButtons & IN_ATTACK2) && !(iButton & IN_RELOAD) && !get_member(pActive, m_Weapon_fInReload) && get_member(id,m_flNextAttack)<=0.0 && get_member(pActive,m_Weapon_flNextSecondaryAttack)<=0.0)
		{
			if (flGauge >= JUMP_COST) 
			{
				g_iPKMState[id] = PKM_HOLD_START
				g_flPKMPressTime[id] = flTime
				g_flPKMHoldLoopTime[id] = flTime + 0.5 
				
				SendWeaponAnim(id, ANIM_HOLD_START)
				emit_sound(id, CHAN_STATIC, SND_READY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				g_flNextSpinSound[id] = flTime + 0.5 

				set_member(pActive, m_Weapon_flTimeWeaponIdle, 99.0) 
				set_member(pActive, m_Weapon_flNextPrimaryAttack, 99.0) 
				set_member(pActive, m_Weapon_flNextSecondaryAttack, 99.0)
			}
		}
		// ПКМ всё ещё зажата — переход hold_start -> hold_loop + звук кручения
		else if ((iButton & IN_ATTACK2) && g_iPKMState[id] != PKM_NONE)
		{
			if (g_iPKMState[id] == PKM_HOLD_START && flTime >= g_flPKMHoldLoopTime[id])
			{
				g_iPKMState[id] = PKM_HOLD_LOOP
				SendWeaponAnim(id, ANIM_HOLD_LOOP)
			}
			
			if (g_iPKMState[id] == PKM_HOLD_LOOP && flTime >= g_flNextSpinSound[id])
			{
				emit_sound(id, CHAN_WEAPON, SND_SPIN, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				g_flNextSpinSound[id] = flTime + 0.1
			}
			
			// Блокируем стрельбу и idle пока держим ПКМ
			set_member(pActive, m_Weapon_flTimeWeaponIdle, 99.0)
			set_member(pActive, m_Weapon_flNextPrimaryAttack, 99.0)
			set_member(pActive, m_Weapon_flNextSecondaryAttack, 99.0)
		}
		// ПКМ отпущена — определяем тап или зажатие
		else if (!(iButton & IN_ATTACK2) && g_iPKMState[id] != PKM_NONE)
		{
			new Float:flHeldTime = flTime - g_flPKMPressTime[id]
			StopHoldSounds(id)

			// Тап (< 0.3с) → Soaring Jump: подброс вверх, -40% энергии
			if (flHeldTime < 0.3 && flGauge >= JUMP_COST)
			{
				set_entvar(pActive, var_fuser1, flGauge - JUMP_COST)
				UpdateGaugeHUD(id, pActive)
				
				SendWeaponAnim(id, ANIM_JUMP)
				emit_sound(id, CHAN_WEAPON, SND_JUMP_SOAR, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

				set_member(pActive, m_Weapon_flTimeWeaponIdle, 1.5)
				set_member(pActive, m_Weapon_flNextPrimaryAttack, 1.0)
				set_member(pActive, m_Weapon_flNextSecondaryAttack, 1.0)
				
				rg_reset_maxspeed(id)
				
				new Float:velocity[3]
				get_entvar(id, var_velocity, velocity)
				velocity[2] = JUMP_POWER
				set_entvar(id, var_velocity, velocity)
			}
			// Зажатие (>= 0.3с) → Gale Blast: запуск снаряда, -50% энергии
			else if (flGauge >= GALE_COST)
			{
				set_entvar(pActive, var_fuser1, flGauge - GALE_COST)
				UpdateGaugeHUD(id, pActive)
				
				SendWeaponAnim(id, ANIM_SHOOT_B)
				emit_sound(id, CHAN_WEAPON, SND_SHOOT_B, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

				set_member(pActive, m_Weapon_flTimeWeaponIdle, 1.5)
				set_member(pActive, m_Weapon_flNextPrimaryAttack, 1.0)
				set_member(pActive, m_Weapon_flNextSecondaryAttack, 1.0)
				
				LaunchGaleProjectile(id)
			}
			else
			{
				// Не хватает энергии — отмена, возврат в idle
				SendWeaponAnim(id, ANIM_IDLE)
				set_member(pActive, m_Weapon_flTimeWeaponIdle, 1.0)
				set_member(pActive, m_Weapon_flNextPrimaryAttack, 0.5)
				set_member(pActive, m_Weapon_flNextSecondaryAttack, 0.5)
			}
			g_iPKMState[id] = PKM_NONE
		}
	}
	else
	{
		g_iPKMState[id] = PKM_NONE
	}

	return HC_CONTINUE
}

StopHoldSounds(id)
{
 if(!is_user_connected(id))return;
	emit_sound(id, CHAN_STATIC, SND_READY, 0.0, ATTN_NORM, SND_STOP, PITCH_NORM)
	emit_sound(id, CHAN_WEAPON, SND_SPIN, 0.0, ATTN_NORM, SND_STOP, PITCH_NORM)
}

// ============================================================================
// [ ЛОГИКА ДУХА (ПТИЦЫ) ]
// ============================================================================
CreateBird(id)
{
	if (id < 1 || id > MaxClients || !is_user_alive(id) || zp_get_user_zombie(id)) return

	// Si el índice guardado quedó viejo o apunta a otra entidad, lo limpiamos.
	new oldBird = g_iBirdEnt[id]
	if (!is_nullent(oldBird))
	{
		if (get_entvar(oldBird, var_impulse) == BIRD_IMPULSE && get_entvar(oldBird,var_owner)==id && !(get_entvar(oldBird,var_flags)&FL_KILLME))
			return

		g_iBirdEnt[id] = 0
	}

	new ent = rg_create_entity("info_target")
	if (is_nullent(ent)) return

	set_entvar(ent, var_classname, "sylphid_bird")
	set_entvar(ent, var_impulse, BIRD_IMPULSE)
	engfunc(EngFunc_SetModel, ent, BIRD_MODEL)

	// SAFE: no usar MOVETYPE_FOLLOW/aiment. Algunos modelos studio pueden
	// comportarse raro al seguir directamente al jugador. Lo movemos nosotros.
	set_entvar(ent, var_movetype, MOVETYPE_NOCLIP)
	set_entvar(ent, var_aiment, 0)
	set_entvar(ent, var_solid, SOLID_NOT)
	set_entvar(ent, var_owner, id)

	// Forzamos render visible y estado limpio.
	set_entvar(ent, var_effects, 0)
	set_entvar(ent, var_rendermode, kRenderNormal)
	set_entvar(ent, var_renderamt, 255.0)
	set_entvar(ent, var_renderfx, kRenderFxNone)
	set_entvar(ent, var_body, 0)
	set_entvar(ent, var_skin, 0)
	set_entvar(ent, var_sequence, 0)
	set_entvar(ent, var_frame, 0.0)
	set_entvar(ent, var_animtime, get_gametime())
	set_entvar(ent, var_framerate, 1.0)

	UpdateBirdPosition(ent, id)

	g_iBirdEnt[id] = ent
	set_entvar(ent, var_fuser2, get_gametime() + BIRD_ATTACK_RATE_NORM)
	set_entvar(ent, var_nextthink, get_gametime() + BIRD_THINK_RATE)
}

RemoveBird(id)
{
	if (id < 1 || id > MaxClients) return

	new bird = g_iBirdEnt[id]
	g_iBirdEnt[id] = 0

	if (!is_nullent(bird) && get_entvar(bird, var_impulse) == BIRD_IMPULSE && get_entvar(bird,var_owner)==id)
	{
		set_entvar(bird, var_flags, FL_KILLME)
	}
}

UpdateBirdPosition(ent, id)
{
	if (is_nullent(ent) || id < 1 || id > MaxClients || !is_user_alive(id) || zp_get_user_zombie(id)) return

	new Float:flOrigin[3]
	new Float:flAngles[3]
	new Float:vecForward[3]
	new Float:vecRight[3]
	get_entvar(id, var_origin, flOrigin)
	get_entvar(id, var_v_angle, flAngles)

	angle_vector(flAngles, ANGLEVECTOR_FORWARD, vecForward)
	angle_vector(flAngles, ANGLEVECTOR_RIGHT, vecRight)

	// Flota sobre el hombro: un poco atrás, a la derecha y arriba.
	flOrigin[0] += (-vecForward[0] * 18.0) + (vecRight[0] * 14.0)
	flOrigin[1] += (-vecForward[1] * 18.0) + (vecRight[1] * 14.0)
	flOrigin[2] += 58.0

	engfunc(EngFunc_SetOrigin, ent, flOrigin)

	// Solo yaw para que no se incline raro al mirar arriba/abajo.
	flAngles[0] = 0.0
	flAngles[2] = 0.0
	set_entvar(ent, var_angles, flAngles)
}

public OnInfoTargetThink_Pre(ent)
{
	if (is_nullent(ent)) return HAM_IGNORED
	
	static iImpulse; iImpulse = get_entvar(ent, var_impulse)
 if(iImpulse!=BIRD_IMPULSE&&iImpulse!=PROJ_IMPULSE&&iImpulse!=FIELD_IMPULSE)return HAM_IGNORED;
 new ownerId=get_entvar(ent,var_owner);
 if((get_entvar(ent,var_flags)&FL_KILLME)||!is_user_alive(ownerId)||zp_get_user_zombie(ownerId)){set_entvar(ent,var_flags,get_entvar(ent,var_flags)|FL_KILLME);return HAM_SUPERCEDE;}
	
	if (iImpulse == BIRD_IMPULSE)
	{
		BirdThink(ent)
		return HAM_SUPERCEDE
	}
	else if (iImpulse == PROJ_IMPULSE || iImpulse == FIELD_IMPULSE)
	{
		set_entvar(ent, var_flags, FL_KILLME)
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

BirdThink(ent)
{
	if (is_nullent(ent) || get_entvar(ent, var_impulse) != BIRD_IMPULSE) return

	new id = get_entvar(ent, var_owner)
	if (id < 1 || id > MaxClients || !is_user_alive(id) || zp_get_user_zombie(id))
	{
		set_entvar(ent, var_flags, FL_KILLME)
		return
	}

	// Si por cualquier motivo este ya no es el pájaro registrado del jugador,
	// lo eliminamos para evitar entidades huérfanas.
	if (g_iBirdEnt[id] != ent)
	{
		set_entvar(ent, var_flags, FL_KILLME)
		return
	}

	new pActive = get_member(id, m_pActiveItem)
	if (!IsValidSylphid(pActive))
	{
		g_iBirdEnt[id] = 0
		set_entvar(ent, var_flags, FL_KILLME)
		return
	}

	new Float:flTime = get_gametime()

	// Seguimiento manual, sin MOVETYPE_FOLLOW.
	UpdateBirdPosition(ent, id)

	new Float:flAnimTime = get_entvar(ent, var_animtime)
	if (flTime - flAnimTime >= 1.0)
	{
		set_entvar(ent, var_animtime, flTime)
		set_entvar(ent, var_frame, 0.0)
	}

	new bool:bIsShooting = (flTime < g_flBirdBoostEnd[id])
	new Float:flNextAttack = get_entvar(ent, var_fuser2)

	if (flTime >= flNextAttack)
	{
		new Float:flRate = bIsShooting ? BIRD_ATTACK_RATE_FAST : BIRD_ATTACK_RATE_NORM
		new Float:flRadius = bIsShooting ? BIRD_ATTACK_RAD_FAST : BIRD_ATTACK_RAD_NORM
		new Float:flDamage = bIsShooting ? BIRD_ATTACK_DMG_FAST : BIRD_ATTACK_DMG_NORM

		set_entvar(ent, var_fuser2, flTime + flRate)

		new Float:vBirdOrigin[3]
		get_entvar(ent, var_origin, vBirdOrigin)

		new target = FindNearestZombie(id, vBirdOrigin, flRadius)
		if (target >= 1 && target <= MaxClients && is_user_alive(target))
		{
			SylphidBirdShot(ent,target);
			ExecuteHamB(Ham_TakeDamage, target, ent, id, flDamage, DMG_SHOCK)
		}
	}

	set_entvar(ent, var_nextthink, flTime + BIRD_THINK_RATE)
}

FindNearestZombie(id, const Float:vOrigin[3], Float:flMaxDist)
{
	static closest; closest = 0
	static Float:flClosestDist; flClosestDist = flMaxDist
	static ent; ent = -1
	
	// Движок сам отсекает всё, что вне радиуса, мы лишь перебираем то, что рядом
	while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, flMaxDist)) != 0)
	{
		// Нас интересуют только индексы игроков (от 1 до MaxClients)
		if (ent < 1 || ent > MaxClients) 
			continue
			
		// Проверяем, жив ли игрок, не является ли он владельцем птицы и зомби ли он
		if (!is_user_alive(ent) || ent == id || !zp_get_user_zombie(ent)) 
			continue
		
		static Float:flTargetOrigin[3]
		get_entvar(ent, var_origin, flTargetOrigin)
		
		static Float:flDist; flDist = vector_distance(vOrigin, flTargetOrigin)
		if (flDist < flClosestDist)
		{
			flClosestDist = flDist
			closest = ent
		}
	}
	
	return closest
}

// ============================================================================
// [ GALE BLAST И ТРАМПЛИН | PROJECTILE & FIELD ]
// ============================================================================
LaunchGaleProjectile(id)
{
	static Float:plOrigin[3], Float:plAngles[3], Float:vecForward[3]
	get_entvar(id, var_origin, plOrigin)
	get_entvar(id, var_v_angle, plAngles)
	angle_vector(plAngles, ANGLEVECTOR_FORWARD, vecForward)
	
	plOrigin[0] += vecForward[0] * 40.0
	plOrigin[1] += vecForward[1] * 40.0
	plOrigin[2] += 15.0
	
	new ent = rg_create_entity("info_target")
	if (is_nullent(ent)) return
	
	set_entvar(ent, var_classname, "sylphid_proj")
	set_entvar(ent, var_impulse, PROJ_IMPULSE)
	engfunc(EngFunc_SetModel, ent, PROJ_MODEL)
	set_entvar(ent, var_movetype, MOVETYPE_TOSS)
	set_entvar(ent, var_solid, SOLID_BBOX)
	set_entvar(ent, var_owner, id)
	
	engfunc(EngFunc_SetSize, ent, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0})
	engfunc(EngFunc_SetOrigin, ent, plOrigin)
	
	set_entvar(ent, var_rendermode, kRenderTransAdd)
	set_entvar(ent, var_renderamt, 255.0)
	set_entvar(ent, var_sequence, 0)
	set_entvar(ent, var_animtime, get_gametime())
	set_entvar(ent, var_framerate, 1.0)
	
	static Float:velocity[3]
	velocity[0] = vecForward[0] * PROJ_SPEED
	velocity[1] = vecForward[1] * PROJ_SPEED
	velocity[2] = vecForward[2] * PROJ_SPEED + 100.0 
	set_entvar(ent, var_velocity, velocity)
	set_entvar(ent, var_angles, plAngles)
	
	set_entvar(ent, var_nextthink, get_gametime() + 5.0)
}

public OnInfoTargetTouch_Pre(ent, touched)
{
	if (is_nullent(ent)) return HAM_IGNORED
	
	static iImpulse; iImpulse = get_entvar(ent, var_impulse)
 if(iImpulse!=BIRD_IMPULSE&&iImpulse!=PROJ_IMPULSE&&iImpulse!=FIELD_IMPULSE)return HAM_IGNORED;
 new ownerId=get_entvar(ent,var_owner);
 if((get_entvar(ent,var_flags)&FL_KILLME)||!is_user_alive(ownerId)||zp_get_user_zombie(ownerId)){set_entvar(ent,var_flags,get_entvar(ent,var_flags)|FL_KILLME);return HAM_SUPERCEDE;}
	
	if (iImpulse == PROJ_IMPULSE)
	{
		static owner; owner = get_entvar(ent, var_owner)
		if (touched == owner) return HAM_IGNORED
		
		static Float:projOrigin[3]
		get_entvar(ent, var_origin, projOrigin)
		set_entvar(ent,var_solid,SOLID_NOT)
		set_entvar(ent,var_flags,get_entvar(ent,var_flags)|FL_KILLME)
		CreateTrampolineField(projOrigin, owner)
		
		set_entvar(ent, var_flags, FL_KILLME)
		return HAM_SUPERCEDE
	}
	else if (iImpulse == FIELD_IMPULSE)
	{
		if (touched < 1 || touched > MaxClients) return HAM_IGNORED
		if (!is_user_alive(touched) || zp_get_user_zombie(touched)) return HAM_IGNORED
		
		static Float:velocity[3]
		get_entvar(touched, var_velocity, velocity)
		velocity[2] = FIELD_LAUNCH_POWER
		set_entvar(touched, var_velocity, velocity)
		
		emit_sound(touched, CHAN_BODY, SND_JUMP_FIELD, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		set_entvar(ent, var_flags, FL_KILLME)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

CreateTrampolineField(Float:origin[3], owner)
{
	new ent = rg_create_entity("info_target")
	if (is_nullent(ent)) return
	
	set_entvar(ent, var_classname, "sylphid_field")
	set_entvar(ent, var_impulse, FIELD_IMPULSE)
	engfunc(EngFunc_SetModel, ent, FIELD_MODEL)
	set_entvar(ent, var_movetype, MOVETYPE_NONE)
	set_entvar(ent, var_solid, SOLID_TRIGGER)
	set_entvar(ent, var_owner, owner)
	
	engfunc(EngFunc_SetSize, ent, Float:{-FIELD_RADIUS, -FIELD_RADIUS, 0.0}, Float:{FIELD_RADIUS, FIELD_RADIUS, 64.0})
	engfunc(EngFunc_SetOrigin, ent, origin)
	
	set_entvar(ent, var_rendermode, kRenderTransAdd)
	set_entvar(ent, var_renderamt, 255.0)
	set_entvar(ent, var_sequence, 0)
	set_entvar(ent, var_animtime, get_gametime())
	set_entvar(ent, var_framerate, 1.0)
	
	set_entvar(ent, var_nextthink, get_gametime() + FIELD_LIFETIME)
}

// ============================================================================
// [ ВИЗУАЛ И ИНТЕРФЕЙС | HUD & EFFECTS ]
// ============================================================================
CreateHitSprites(id)
{
	static Float:flTime; flTime = get_gametime()
	if (flTime < g_flNextSpriteTime[id]) return;
	g_flNextSpriteTime[id] = flTime + 0.35 
	
	static Float:vecStart[3], Float:vecEnd[3], Float:vecAngles[3], Float:vecForward[3]
	get_entvar(id, var_origin, vecStart)
	
	static Float:viewOfs[3]
	get_entvar(id, var_view_ofs, viewOfs)
	vecStart[0] += viewOfs[0]; vecStart[1] += viewOfs[1]; vecStart[2] += viewOfs[2]
	
	get_entvar(id, var_v_angle, vecAngles)
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward)
	
	vecEnd[0] = vecStart[0] + vecForward[0] * 8192.0
	vecEnd[1] = vecStart[1] + vecForward[1] * 8192.0
	vecEnd[2] = vecStart[2] + vecForward[2] * 8192.0
	
	static tr; tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, id, tr)
	
	static Float:vecHitPos[3]
	get_tr2(tr, TR_vecEndPos, vecHitPos)
	free_tr2(tr)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecHitPos, 0)
	write_byte(TE_SPRITETRAIL)
	write_coord_f(vecHitPos[0]); write_coord_f(vecHitPos[1]); write_coord_f(vecHitPos[2])
	write_coord_f(vecHitPos[0]); write_coord_f(vecHitPos[1]); write_coord_f(vecHitPos[2] + 10.0)
	write_short(g_iSprHit)
	write_byte(3)   // Кол-во спрайтов
	write_byte(3)   // Время жизни в 0.1 сек
	write_byte(1)   // Размер
	write_byte(20)  // Скорость
	write_byte(15)  // Разброс | рандомность
	message_end()
}

SyncWeaponList(id, iState)
{
	message_begin(MSG_ONE, g_msgWeaponList, _, id)
	write_string(iState ? "weapon_jumpspirit" : WEAPON_BASE)
	write_byte(9)
	write_byte(iState ? WEAPON_BPAMMO : 52)
	write_byte(iState ? 14 : -1)
	write_byte(iState ? floatround(MAX_GAUGE) : -1)
	write_byte(1)
	write_byte(3)
	write_byte(WEAPON_BASE_ID)
	write_byte(0)
	message_end()
}

UpdateGaugeHUD(id, pWeapon)
{
	static Float:flGauge; flGauge = get_entvar(pWeapon, var_fuser1)
	message_begin(MSG_ONE, g_msgAmmoX, _, id)
	write_byte(14)
	write_byte(floatround(flGauge, floatround_floor))
	message_end()
}

SendWeaponAnim(id, iAnim)
{
	set_entvar(id, var_weaponanim, iAnim)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(0)
	message_end()
}

Weapon_MuzzleFlash(iPlayer, const szMuzzleSprite[], Float:flScale, Float:flBrightness, iAttachment)
{
	new iSprite = rg_create_entity("env_sprite", false)
	if (is_nullent(iSprite)) return 0
	
	engfunc(EngFunc_SetModel, iSprite, szMuzzleSprite)
	set_entvar(iSprite, var_spawnflags, SF_SPRITE_ONCE)
	set_entvar(iSprite, var_classname, "sylphid_muzzle")
	set_entvar(iSprite, var_impulse, MUZZLE_IMPULSE)
	set_entvar(iSprite, var_owner, iPlayer)
	set_entvar(iSprite, var_aiment, iPlayer)
	set_entvar(iSprite, var_body, iAttachment)
	set_entvar(iSprite, var_rendermode, kRenderTransAdd)
	set_entvar(iSprite, var_renderamt, flBrightness)
	set_entvar(iSprite, var_renderfx, kRenderFxNone)
	set_entvar(iSprite, var_scale, flScale)
	
	ExecuteHamB(Ham_Spawn, iSprite)
	
	set_entvar(iSprite, var_frame, 0.0)
	set_entvar(iSprite, var_nextthink, get_gametime() + MUZZLE_TIME)
	return iSprite
}

public OnSpriteThink(iSprite)
{
	if (is_nullent(iSprite) || get_entvar(iSprite, var_impulse) != MUZZLE_IMPULSE) return HAM_IGNORED
	
	new owner=get_entvar(iSprite,var_owner);
 if((get_entvar(iSprite,var_flags)&FL_KILLME)||!is_user_alive(owner)||zp_get_user_zombie(owner)){set_entvar(iSprite,var_flags,FL_KILLME);return HAM_SUPERCEDE;}
 static Float:flFrame; flFrame = get_entvar(iSprite, var_frame)
	static Float:flMaxFrame; flMaxFrame = get_pdata_float(iSprite, MAX_FRAME_PDATA, 4)
	
	flFrame += 1.0
	if (flFrame - 1.0 < flMaxFrame)
	{
		set_entvar(iSprite, var_frame, flFrame)
		set_entvar(iSprite, var_nextthink, get_gametime() + MUZZLE_TIME)
		return HAM_SUPERCEDE
	}

	set_entvar(iSprite, var_flags, FL_KILLME)
	return HAM_SUPERCEDE
}

CleanupSylphid(id){
 RemoveBird(id);g_iPKMState[id]=PKM_NONE;g_Shooting[id]=false;g_flBirdBoostEnd[id]=0.0;
 new const names[][]={"sylphid_bird","sylphid_proj","sylphid_field","sylphid_muzzle"};
 for(new i;i<sizeof names;i++){new e;while((e=engfunc(EngFunc_FindEntityByString,e,"classname",names[i]))>0)if(get_entvar(e,var_owner)==id){set_entvar(e,var_solid,SOLID_NOT);set_entvar(e,var_flags,get_entvar(e,var_flags)|FL_KILLME);}}
}
public client_putinserver(id){g_iBirdEnt[id]=0;g_iPKMState[id]=PKM_NONE;g_Shooting[id]=false;g_flNextSpriteTime[id]=0.0;}

stock SylphidBirdShot(bird,target){
 if(is_nullent(bird)||!is_user_alive(target))return;
 new Float:start[3],Float:end[3];get_entvar(bird,var_origin,start);get_entvar(target,var_origin,end);end[2]+=16.0;
 engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,start,0);
 write_byte(TE_BEAMPOINTS);
 engfunc(EngFunc_WriteCoord,start[0]);engfunc(EngFunc_WriteCoord,start[1]);engfunc(EngFunc_WriteCoord,start[2]);
 engfunc(EngFunc_WriteCoord,end[0]);engfunc(EngFunc_WriteCoord,end[1]);engfunc(EngFunc_WriteCoord,end[2]);
 write_short(g_iBirdBeam);write_byte(0);write_byte(0);write_byte(2);write_byte(6);write_byte(0);
 write_byte(100);write_byte(220);write_byte(255);write_byte(180);write_byte(0);message_end();
}
