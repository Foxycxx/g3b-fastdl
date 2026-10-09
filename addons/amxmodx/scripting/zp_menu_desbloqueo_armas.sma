native zh_give_drakar(id);
native exhero_special_name(id,name[],len);
native sylphid_give_weapon(id);
native exhero_sylphid_unlocked(id);
native revo_get_user_hero(id);
native exhero_give_firefox(id);
native exhero_give_genocider(id);
native exhero_give_coindart(id);
native exhero_give_lockon(id);

native exhero_give_flail(id);
native exhero_remove_flail(id);
native exhero_give_holy(id);
native exhero_remove_holy(id);
native exhero_give_lance(id);
native exhero_remove_lance(id);
native zp_give_user_halogun(id);
native exhero_special_menu(id);
native exhero_special_loadout(id, doubled);
native exhero_special_double(id);
native zp_give_user_voidpistol(id);
native zp_give_user_y21s4janusd(id);
#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <fakemeta>
#include <fakemeta_util>
#include <amxmisc>
#include <zombieplague>
#include <byu_money>
native give_buffm4(id);

native exhero_give_eclipse(id);
#include <9_balrog7>
#include <lunar_cannon>
native give_buffak(id);

#include <nata>
#include <twin_shadow_axes>
native zp_remove_user_twin_shadow_axes(id);
#include <whipsword>

#include <16_skull9>

#include <17_zbgrnade>
#include <18_ds>
#include <19_bb>
#include <20_sprint>
#include <21_tank>
#include <22_banshee>
#include <23_venom>
#include <24_pc>
#include <25_speed>
#include <26_deimos>
#include <27_sting>
#include <28_kostum>
#include <27_stamper>
native give_weapon_guitar(id);
native zp_give_user_usas_thunderfall(id);

#include <refol>
#include <star_taylor>
#include <cannon>

// Rail Cannon retired
#define PLUGIN "UnlockMod"
#define VERSION "2.0"
#define AUTHOR "m4m3ts"
#define RESTORE_HEALTH_TIME 3
#define RESTORE_HEALTH_DMG_LV1 200
#define RESTORE_HEALTH_DMG_LV2 500
#define ZB_LV2_HEALTH 8000
#define ZB_LV2_ARMOR 500
#define ZB_LV3_HEALTH 14000
#define ZB_LV3_ARMOR 1000
#define MIN_HEALTH_ZOMBIE 3000
#define MIN_ARMOR_ZOMBIE 100

#define TASK_NOL 2085
#define STOK_AEOLISS 3
#define STOK_PETROLL 2
#define STOK_JANUSS3 2
#define STOK_BL11 3
#define STOK_BRICKP 2
#define STOK_BALROGG5 3
#define STOK_TH11 3
#define STOK_BDDRIPP 2

const PDATA_SAFE = 2
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds

enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

new const g_szPrefix[] = "^3[^4Zombie The ExHero^3]"

new const g_PrimaryNames[][] = {
								"M4A1",
								"AK47",
								"Famas",
								"P90",
								"XM1014",
								"M4A1 Dark Knight",
								"M1887-XMAS",
								"Slot libre (Janus-7 removida)",
								"Balrog-XI Blue",
								"Aeolis",
								"Arbalest (Halo Gun)",
								"Slot libre",
								"Skull-4",
								"AK47 Paladin",
								"Plasma Gun",
								"PowerSaw",
								"Mecha Dino MK-4",
								"Black Dragon Cannon",
								"Lunar Cannon",
								"Janus-11",
								"Petrolboomer",
								"Ancient Keeper",
								"Rail Cannon",
								"Brick Peace V2",
								"Thanatos-11",
								"Blood Dripper", "X-TRACKER", "FireFox", "Genocider VI", "Lightning AR-1", "Drakar II", "USAS-12 Thunderfall"
								}

new const g_SecondaryNames[][] = {
								"USP",
								"Beretta 92G Elite II",
								"Glock",
								"Deagle",
								"Balrog-I",
								"Skull-1",
								"Star Taylor",
								"Slot retirado",
								"Void Avenger",
								"Sha Wujing Dual Handgun", "Sylphid", "Coin Dart", "Eclipse Shifter"
								}

new const g_MeleeNames[][] = {
								"Nata Knife",
								"Twin Shadow Axes",
								"Balrog-IX",
								"Slot libre",
								"Skull-9",
								"Dragon Sword",
								"Whip Sword", "Tyrant Mace", "Holy Sword Divine Order", "Lance Scarlet" }
								

new bool:g_PriceUnlocked[33][21];
new const g_PriceGroup[]={0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,0,0,0};
new const g_PriceIndex[]={0,1,2,3,4,26,27,28,0,1,2,3,10,11,0,7,8,9,29,30,31};
new const g_PriceValue[]={0,0,0,0,0,26000,29000,32000,0,0,0,0,0,23000,0,24000,30000,28000,0,18000,22000};

new iWeapprim[ 33 ]
new iWeapsec[ 33 ]
new iWeapmelee[ 33 ]

new menu1, timer, writelogs
new g_iMaxClients, g_heal, g_Ham_Bot, stok_th11, stok_bddripp, stok_brick, stok_aeolis, stok_petrol, stok_bl11, stok_janus3, stok_balrog5
new p_mg3, p_gatling, p_antdtr, p_th11, p_bddripp, p_m32, p_sting, p_janus9, p_brickp, p_ammo, p_petrol, p_janus3, p_bl9, p_plasma, p_pwrsaw, p_wujing, p_jns11, p_bl5, p_ruyi, p_pwrsaw2, p_awpz, p_drgnswrd, p_dinfi2, p_sk4, p_janus7, p_blrg3, p_dinfi, p_lightsaber,p_zbgr, p_incrshp, p_jump, p_grav, p_dmg_multiplier, p_dam, p_hmgrnd, p_nghtvsion, p_deadly, p_bloody, p_sprint, p_vodo, p_light, p_deimos, p_banshe, p_stamper
new jml_sk5, jml_m1887, jml_jns7, jml_aeolis, jml_spear, jml_thunder, jml_bl7, jml_bow, jml_plasma, jml_saw, jml_jns5, jml_bl5, jml_jns11, jml_petrol, jml_jns3
new jml_bl1, jml_sk1, jml_dinfi, jml_jns1, jml_shuwjg
new jml_jns9, jml_bl9, jml_lghtsaber, jml_sk9, jml_drgnswrd, jml_ruyi
new jml_smoke, jml_venom, jml_lusty, jml_deimos, jml_banshee, jml_sting, jml_stamper
new jml_jump, jml_30prsen, jml_x2grnd, jml_nghtvsn, jml_deadly, jml_bloody, jml_sprint, jml_ammo
new jml_grenadezb, jml_healthzb
new mg3unlocked[33]
new gatlingunlocked[33]
new antidtrunlocked[33]
new m32unlocked[33]
new awpzunlocked[33]
new blrg7unlocked[33]
new blrg3unlocked[33]
new dinfiunlocked[33]
new dinfiunlocked2[33]
new lghsberunlocked[33]
new zbgrnadeunlocked[33]
new incrshpunlocked[33]
new bool:g_LoadoutConfirmed[33];
new zbcanbuys[33]
new jumpunlocked[33]
new havegravity[33]
new damunlocked[33]
new dam[33]
new grnadehmunlocked[33]
new nghtvisionunlocked[33]
new deadlyunlocked[33]
new bloodyunlocked[33]
new sprintunlocked[33]
new vodounlocked[33]
new lightunlocked[33]
new deimosunlocked[33]
new bansheunlocked[33]
new stamperunlocked[33]
new g_restore_health[33]
new g_start_health[33]
new g_star_armor[33]
new g_level[33]
new g_zombie_die[33]
new zombiedeath2[33]
new g_zombie_class[33]
new g_ZB_class[33]
new dapet_kostum[33]
new stingunlocked[33]
new plasmaunlocked[33]
new pwrsawunlocked[33]
new pwrsawunlocked2[33]
new drgnswrdunlocked[33]
new jns7unlocked[33]
new jns9unlocked[33]
new ammounlocked[33]
new can_choose[33]
new first_zombi[33]
new bl9unlocked[33]
new cyunlocked[33]
new cannonunlocked[33]
new sk4unlocked[33]
new ruyiunlocked[33]
new wujingunlocked[33]
new janus11unlocked[33]
new petrolunlocked[33]
new janus3unlocked[33]
new railunlocked[33]
new brickunlocked[33]
new th11unlocked[33]
new bddrippunlocked[33]

new KillCount[33]

new const sound_cash[] = "zombie_plague/cash.wav"
new const health_sound_male[] = "zm/zombie_heal.wav"
new const health_sound_female[] = "zombie_plague/zombi_heal_female.wav"
new const zombie_evolution_male[] = "zombie_plague/zombi_evolution.wav"
new const zombie_evolution_female[] = "zombie_plague/zombi_evolution_female.wav"

new const zombie_infect[][] =
{
	"ZombieDarkness/vox/z4_zombi_coming_2.wav",
	"ZombieDarkness/vox/z4_zombi_coming_1_tw.wav",
	"ZombieDarkness/vox/z4_zombi_coming_2_tw.wav",
	"ZombieDarkness/vox/z4_zombi_coming_2.wav"
}

new const zombie_jerit_male[][] =
{
	"ZombieDarkness/z4human_death_male.wav",
	"ZombieDarkness/z4human_death_male.wav"
}

new const zombie_jerit_female[][] =
{
	"ZombieDarkness/z4human_death_female.wav",
	"ZombieDarkness/z4human_death_female.wav"
}

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE) 

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_sg552", "weapon_knife" }

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("unlock_version", "m4m3ts", FCVAR_SERVER|FCVAR_SPONLY)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_SetClientKeyValue, "SetClientKeyValue")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	// Shop multiplier is applied once, in fw_takedamage.
	register_clcmd("buy", "OpenPendingLoadout");
	register_clcmd("client_buy_open", "OpenVguiLoadout");
	register_clcmd("buyequip", "OpenPendingLoadout");
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
		
	p_mg3 = register_cvar("unlock_sk5", "16000")
	p_gatling = register_cvar("unlock_balrog11", "14000")
	p_antdtr = register_cvar("unlock_aeolis", "14000")
	p_m32 = register_cvar("unlock_eclipse", "25000")
	p_sk4 = register_cvar("unlock_sk4", "7500")
	p_awpz = register_cvar("unlock_halogun", "28000")
	p_blrg3 = register_cvar("unlock_cbow", "22000")
	p_dinfi = register_cvar("unlock_dinfi", "13000")
	p_lightsaber = register_cvar("unlock_sk9", "12000")
	p_zbgr = register_cvar("unlock_zbgr", "5000")
	p_incrshp = register_cvar("unlock_incrshp", "4000")
	p_jump = register_cvar("unlock_jump", "1500")
	p_grav = register_cvar("gravity", "0.75")
	p_dam = register_cvar("unlock_dam", "3000")
	p_dmg_multiplier = register_cvar("dmg_multiplier", "1.3")
	p_hmgrnd = register_cvar("unlock_grnade", "3500")
	p_nghtvsion = register_cvar("unlock_nghtvsion", "1000")
	p_deadly = register_cvar("unlock_deadly", "8500")
	p_bloody = register_cvar("unlock_bloody", "4500")
	p_sprint = register_cvar("unlock_sprint", "3000")
	p_vodo = register_cvar("unlock_venom", "6000")
	p_light = register_cvar("unlock_light", "2500")
	p_deimos = register_cvar("unlock_deimos", "2000")
	p_banshe = register_cvar("unlock_banshe", "13000")
	p_stamper = register_cvar("unlock_sting", "7000")
	p_sting = register_cvar("unlock_stamper", "4500")
	p_plasma = register_cvar("unlock_plasma", "13000")
	p_pwrsaw = register_cvar("unlock_pwrsaw", "16000")
	p_drgnswrd = register_cvar("unlock_drgnswrd", "11000")
	p_pwrsaw2 = register_cvar("unlock_janus5", "26000")
	p_dinfi2 = register_cvar("unlock_janus1", "24000")
	p_janus7 = register_cvar("unlock_janus7_removed", "999999") // Janus-7 removida
	p_janus9 = register_cvar("unlock_janus9", "20000")
	p_ammo = register_cvar("unlock_ammo", "5000")
	p_bl9 = register_cvar("unlock_bl9", "4000")
	p_wujing = register_cvar("unlock_wujing", "4500")
	p_bl5 = register_cvar("unlock_bl5", "30000")
	p_ruyi = register_cvar("unlock_ruyi", "25000")
	p_jns11 = register_cvar("unlock_janus11", "8000")
	p_petrol = register_cvar("unlock_petrol", "10000")
	p_janus3 = register_cvar("unlock_janus3", "11000")
	p_brickp = register_cvar("unlock_brickpeace", "9000")
	p_th11 = register_cvar("unlock_th11", "9000")
	p_bddripp = register_cvar("unlock_bddripp", "14000")
	g_iMaxClients = get_maxplayers( )
}

public plugin_precache()
{
	precache_sound(sound_cash)
		
	for(new i = 0; i < sizeof(zombie_infect); i++)
		precache_sound(zombie_infect[i])
	for(new i = 0; i < sizeof(zombie_jerit_male); i++)
		precache_sound(zombie_jerit_male[i])
	for(new i = 0; i < sizeof(zombie_jerit_female); i++)
		precache_sound(zombie_jerit_female[i])
	
	precache_sound(zombie_evolution_male)
	precache_sound(zombie_evolution_female)
	precache_sound(health_sound_male)
	precache_sound(health_sound_female)
	g_heal = precache_model("sprites/zm/cso_heal.spr")
	stok_aeolis = STOK_AEOLISS
	stok_petrol = STOK_PETROLL
	stok_janus3 = STOK_JANUSS3
	stok_balrog5 = STOK_BALROGG5
	stok_bl11 = STOK_BL11
	stok_brick = STOK_BRICKP
	stok_th11 = STOK_TH11
	stok_bddripp = STOK_BDDRIPP
	
	set_task(15.0, "write_log", _, _, _, "b")
	
	jml_sk5 = 0
	jml_m1887 = 0
	jml_jns7 = 0
	jml_aeolis = 0
	jml_spear = 0
	jml_thunder = 0
	jml_bl7 = 0
	jml_bow = 0
	jml_plasma = 0
	jml_saw = 0
	jml_jns5 = 0
	jml_bl5 = 0
	jml_jns11 = 0
	jml_petrol = 0
	jml_jns3 = 0
	
	jml_bl1 = 0
	jml_sk1 = 0
	jml_dinfi = 0
	jml_jns1 = 0
	jml_shuwjg = 0
	
	jml_jns9 = 0
	jml_bl9 = 0
	jml_lghtsaber = 0
	jml_sk9 = 0
	jml_drgnswrd = 0
	jml_ruyi = 0
	
	jml_smoke = 0
	jml_venom = 0
	jml_lusty = 0
	jml_deimos = 0
	jml_banshee = 0
	jml_sting = 0
	jml_stamper = 0
	
	jml_jump = 0
	jml_30prsen = 0
	jml_x2grnd = 0
	jml_nghtvsn = 0
	jml_deadly = 0
	jml_bloody = 0
	jml_sprint = 0
	jml_ammo = 0
	
	jml_grenadezb = 0
	jml_healthzb = 0
	
	writelogs = 1
}

public plugin_natives()
{
 register_native("exhero_shop_jump_gravity","NativeShopJumpGravity");
	register_native("revo_get_user_start_health", "native_get_user_start_health", 1)
	register_native("destroy_menu", "native_destroy_menu", 1)
	register_native("zth_get_zombie_class", "native_zth_get_zombie_class", 1)
	register_native("guns_menu", "native_guns_menu", 1)
}

public native_get_user_start_health(id)
{
	return g_start_health[id];
}

public native_destroy_menu(id)
{
	destroy_menu(id)
}

public native_zth_get_zombie_class(id)
{
	return g_zombie_class[id];
}

public native_guns_menu(id)
{
	gunsmenu(id)
}

public client_connect(id)
{
 for(new n=0;n<sizeof g_PriceValue;n++)g_PriceUnlocked[id][n]=false;
    g_LoadoutConfirmed[id]=false;
	mg3unlocked[id] = false
	gatlingunlocked[id] = false
	antidtrunlocked[id] = false
	m32unlocked[id] = false
	dinfiunlocked[id] = false
	dinfiunlocked2[id] = false
	lghsberunlocked[id] = false
	awpzunlocked[id] = false
	blrg7unlocked[id] = false
	blrg3unlocked[id] = false
	zbgrnadeunlocked[id] = false
	incrshpunlocked[id] = false
	zbcanbuys[id] = true
	jumpunlocked[id] = false
	havegravity[id] = false
	damunlocked[id] = false
	dam[id] = false
	grnadehmunlocked[id] = false
	deadlyunlocked[id] = false
	bloodyunlocked[id] = false
	sprintunlocked[id] = false
	vodounlocked[id] = false
	lightunlocked[id] = false
	deimosunlocked[id] = false
	bansheunlocked[id] = false
	stamperunlocked[id] = false
	nghtvisionunlocked[id] = false
	dapet_kostum[id] = false
	stingunlocked[id] = false
	plasmaunlocked[id] = false
	pwrsawunlocked[id] = false
	pwrsawunlocked2[id] = false
	drgnswrdunlocked[id] = false
	awpzunlocked[id] = false
	jns7unlocked[id] = false
	jns9unlocked[id] = false
	ammounlocked[id] = false
	can_choose[id] = 1
	bl9unlocked[id] = false
	cyunlocked[id] = false
	cannonunlocked[id] = false
	sk4unlocked[id] = false
	ruyiunlocked[id] = false
	wujingunlocked[id] = false
	janus11unlocked[id] = false
	petrolunlocked[id] = false
	janus3unlocked[id] = false
	railunlocked[id] = false
	brickunlocked[id] = false
	th11unlocked[id] = false
	bddrippunlocked[id] = false
	
	iWeapprim[ id ] = 0
	iWeapsec[ id ] = 0
	iWeapmelee[ id ] = 0
	
	if(is_user_bot(id)) g_ZB_class[id] = random_num(1,8)
	else g_ZB_class[id] = 1
	
	reset_value(id)
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Item_Deploy, id, "fw_Item_Deploy_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_takedamage")
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	// Do not apply the shop multiplier again in TraceAttack.
}

public ResetKills(id)
{
	new players[32] , inum
	get_players(players, inum)
	for(new a = 0; a < inum; ++a)
		KillCount[a] = 0
}

public zp_round_started(id)
{
	client_cmd(0, "spk ^"%s^"", zombie_infect[random( sizeof(zombie_infect))])
	
	static total
	total = total_player()
	
	if (total >= 8 && total <= 20)
	{
		set_task(0.2, "make_zombie", id)
	}
	
	if (total >= 21 && total <= 25)
	{
		set_task(0.2, "make_zombie", id)
		set_task(0.3, "make_zombie2", id)
	}
	
	if (total >= 26)
	{
		set_task(0.2, "make_zombie", id)
		set_task(0.3, "make_zombie2", id)
		set_task(0.4, "make_zombie3", id)
	}
}

public reset_value(id)
{
	zombiedeath2[id] = false
	g_restore_health[id] = 0
	g_zombie_die[id] = 0
	g_level[id] = 0
	g_start_health[id] = 0
	g_star_armor[id] = 0
}

public reset_value_zombie(id)
{
	tank_reset_value_player(id)
	sting_reset_value(id)
	venom_reset_value(id)
	stamper_reset_value(id)
	banchee_reset_value_player(id)
	deimos_reset_value_player(id)
	speed_reset_value(id)
	pc_reset_value_player(id)
}

public fw_CmdStart(id, uc_handle, seed)
{			
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}

	// restore health
	zombie_restore_health(id)

	return FMRES_IGNORED
}

zombie_restore_health(id)
{
	if (!zp_get_user_zombie(id)) return;
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	
	if (!velocity[0] && !velocity[1] && !velocity[2])
	{
		if (!g_restore_health[id]) g_restore_health[id] = get_systime()
	}
	else g_restore_health[id] = 0
	
	if (g_restore_health[id])
	{
		new rh_time = get_systime() - g_restore_health[id]
		if (rh_time == RESTORE_HEALTH_TIME+1 && get_user_health(id) < g_start_health[id])
		{
			// get health add
			new health_add
			if (g_level[id]==1) health_add = RESTORE_HEALTH_DMG_LV1
			else health_add = RESTORE_HEALTH_DMG_LV2
			
			// get health new
			new health_new = get_user_health(id)+health_add
			health_new = min(health_new, g_start_health[id])
			
			// set health
			set_user_health(id, health_new)
			g_restore_health[id] += 1
			
			if(g_zombie_class[id] == 1 || g_zombie_class[id] == 3 || g_zombie_class[id] == 5)
			{
				client_cmd(id, "spk ^"%s^"", health_sound_male)
			}
			else client_cmd(id, "spk ^"%s^"", health_sound_female)
			
			new origin[3] 
			get_user_origin(id,origin) 

			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_SPRITE) 
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]+=30) 
			write_short(g_heal) 
			write_byte(8) 
			write_byte(255) 
			message_end() 
		}
	}
}

public countdown(id)
{
	if( timer > 0)
	{
		client_print(id, print_center, "El menu de zombis se cerrara en %i segundos", timer)
		timer-- 
		set_task(1.0, "countdown", id)
	}		
}

public write_log()
{
	new secondsLeft = get_timeleft()
	
	if (secondsLeft < 40 && writelogs == 1) 
	{
		static mapname[64]
		get_mapname(mapname, sizeof(mapname))
		
		static logdata2[100],logdata3[100],logdata4[100],logdata5[100]
		static logdata6[100], logdata7[100],logdata8[100],logdata9[100],logdata10[100]
		static logdata11[100], logdata12[100],logdata13[100],logdata14[100],logdata15[100]
		static logdata16[100], logdata17[100],logdata18[100],logdata19[100],logdata20[100]
		static logdata21[100], logdata22[100],logdata23[100],logdata24[100],logdata25[100]
		static logdata26[100], logdata27[100],logdata28[100],logdata29[100],logdata30[100]
		static logdata31[100], logdata32[100],logdata33[100],logdata34[100],logdata35[100]
		static logdata36[100], logdata37[100],logdata38[100],logdata39[100],logdata40[100]
		static logdata41[100], logdata42[100],logdata43[100],logdata44[100]
		static logdata45[100], logdata46[100],logdata47[100],logdata48[100],logdata49[100]
		static logdata50[100], logdata51[100], logdata52[100], logdata53[100]
		formatex(logdata2, charsmax(logdata2), "=============================== %s ===============================", mapname)
		formatex(logdata3, charsmax(logdata3), "------------------PRIMARY--------------------")
		formatex(logdata4, charsmax(logdata4), "%s = %d", g_PrimaryNames[ 5 ], jml_sk5)
		formatex(logdata5, charsmax(logdata5), "%s = %d", g_PrimaryNames[ 6 ], jml_m1887)
		formatex(logdata6, charsmax(logdata6), "%s = %d", g_PrimaryNames[ 7 ], jml_jns7)
		formatex(logdata7, charsmax(logdata7), "%s = %d", g_PrimaryNames[ 9 ], jml_aeolis)
		formatex(logdata8, charsmax(logdata8), "%s = %d", g_PrimaryNames[ 10 ], jml_spear)
		formatex(logdata9, charsmax(logdata9), "%s = %d", g_PrimaryNames[ 11 ], jml_thunder)
		formatex(logdata10, charsmax(logdata10), "%s = %d", g_PrimaryNames[ 12 ], jml_bl7)
		formatex(logdata11, charsmax(logdata11), "%s = %d", g_PrimaryNames[ 13 ], jml_bow)
		formatex(logdata12, charsmax(logdata12), "%s = %d", g_PrimaryNames[ 14 ], jml_plasma)
		formatex(logdata13, charsmax(logdata13), "%s = %d", g_PrimaryNames[ 15 ], jml_saw)
		formatex(logdata14, charsmax(logdata14), "%s = %d", g_PrimaryNames[ 16 ], jml_jns5)
		formatex(logdata15, charsmax(logdata15), "%s = %d", g_PrimaryNames[ 17 ], (jumlah_cannon() >= 1 ? 1 : jumlah_cannon()))
		formatex(logdata16, charsmax(logdata16), "%s = %d", g_PrimaryNames[ 18 ], jml_bl5)
		formatex(logdata17, charsmax(logdata17), "%s = %d", g_PrimaryNames[ 19 ], jml_jns11)
		formatex(logdata18, charsmax(logdata18), "%s = %d", g_PrimaryNames[ 20 ], jml_petrol)
		formatex(logdata19, charsmax(logdata19), "%s = %d", g_PrimaryNames[ 21 ], jml_jns3)
		formatex(logdata42, charsmax(logdata42), "%s = %d", g_PrimaryNames[ 22 ], jumlah_rail() >= 2 ? 2 : jumlah_rail())
		formatex(logdata39, charsmax(logdata39), "------------------SECONDARY--------------------")
		formatex(logdata20, charsmax(logdata20), "%s = %d", g_SecondaryNames[ 4 ], jml_bl1)
		formatex(logdata21, charsmax(logdata21), "%s = %d", g_SecondaryNames[ 5 ], jml_sk1)
		formatex(logdata22, charsmax(logdata22), "%s = %d", g_SecondaryNames[ 6 ], (jumlah_cyclone() >= 4 ? 4 : jumlah_cyclone()))
		formatex(logdata23, charsmax(logdata23), "%s = %d", g_SecondaryNames[ 7 ], jml_dinfi)
		formatex(logdata24, charsmax(logdata24), "%s = %d", g_SecondaryNames[ 8 ], jml_jns1)
		formatex(logdata25, charsmax(logdata25), "%s = %d", g_SecondaryNames[ 9 ], jml_shuwjg)
		formatex(logdata40, charsmax(logdata40), "------------------MELEE--------------------")
		formatex(logdata26, charsmax(logdata26), "%s = %d", g_MeleeNames[ 1 ], jml_jns9)
		formatex(logdata27, charsmax(logdata27), "%s = %d", g_MeleeNames[ 2 ], jml_bl9)
		formatex(logdata28, charsmax(logdata28), "%s = %d", g_MeleeNames[ 3 ], jml_lghtsaber)
		formatex(logdata29, charsmax(logdata29), "%s = %d", g_MeleeNames[ 4 ], jml_sk9)
		formatex(logdata30, charsmax(logdata30), "%s = %d", g_MeleeNames[ 5 ], jml_drgnswrd)
		formatex(logdata31, charsmax(logdata31), "%s = %d", g_MeleeNames[ 6 ], jml_ruyi)
		formatex(logdata41, charsmax(logdata41), "------------------ZOMBIE--------------------")
		formatex(logdata32, charsmax(logdata32), "Zombi del humo = %d", jml_smoke)
		formatex(logdata33, charsmax(logdata33), "Guardian venenoso = %d", jml_venom)
		formatex(logdata34, charsmax(logdata34), "Rosa sigilosa Zombie = %d", jml_lusty)
		formatex(logdata35, charsmax(logdata35), "Deimos (Desarme) = %d", jml_deimos)
		formatex(logdata36, charsmax(logdata36), "Banshee (Bruja) = %d", jml_banshee)
		formatex(logdata37, charsmax(logdata37), "Dedo punzante = %d", jml_sting)
		formatex(logdata38, charsmax(logdata38), "Sepulturero = %d", jml_stamper)
		formatex(logdata51, charsmax(logdata51), "------------------ITEM--------------------")
		formatex(logdata43, charsmax(logdata43), "Jump Higher = %d", jml_jump)
		formatex(logdata44, charsmax(logdata44), "+30% Damage = %d", jml_30prsen)
		formatex(logdata45, charsmax(logdata45), "x2 Grenade = %d", jml_x2grnd)
		formatex(logdata46, charsmax(logdata46), "Nightvision = %d", jml_nghtvsn)
		formatex(logdata47, charsmax(logdata47), "Deadly Shot = %d", jml_deadly)
		formatex(logdata48, charsmax(logdata48), "Bloody Blade = %d", jml_bloody)
		formatex(logdata49, charsmax(logdata49), "Sprint = %d", jml_sprint)
		formatex(logdata50, charsmax(logdata50), "Extra Ammo = %d", jml_ammo)
		formatex(logdata52, charsmax(logdata52), "Granada zombi = %d", jml_grenadezb)
		formatex(logdata53, charsmax(logdata53), "Increase HP = %d", jml_healthzb)

		log_to_file("m4m3ts_Weapon_Stats.log", logdata2)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata3)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata4)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata5)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata6)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata7)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata8)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata9)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata10)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata11)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata12)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata13)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata14)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata15)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata16)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata17)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata18)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata19)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata42)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata39)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata20)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata21)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata22)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata23)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata24)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata25)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata40)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata26)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata27)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata28)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata29)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata30)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata31)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata41)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata32)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata33)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata34)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata35)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata36)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata37)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata38)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata51)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata43)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata44)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata45)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata46)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata47)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata48)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata49)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata50)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata52)
		log_to_file("m4m3ts_Weapon_Stats.log", logdata53)
		
		writelogs = 0
	}
}

public zp_user_infected_post(id, infector, nemesis)
{
		remove_task(id)
		
		if(g_ZB_class[id] == 1)
		{
			reset_value_zombie(id)
			give_tank(id)
			g_zombie_class[id] = 1
		}
		if(g_ZB_class[id] == 2)
		{
			reset_value_zombie(id)
			give_pc(id)
			g_zombie_class[id] = 1
		}
		if(g_ZB_class[id] == 3)
		{
			reset_value_zombie(id)
			give_venom(id)
			g_zombie_class[id] = 5
		}
		if(g_ZB_class[id] == 4)
		{
			reset_value_zombie(id)
			give_speed(id)
			g_zombie_class[id] = 2
		}
		if(g_ZB_class[id] == 5)
		{
			reset_value_zombie(id)
			give_deimos(id)
			g_zombie_class[id] = 1
		}
		if(g_ZB_class[id] == 6)
		{
			reset_value_zombie(id)
			give_banchee(id)
			g_zombie_class[id] = 4
		}
		if(g_ZB_class[id] == 7)
		{
			reset_value_zombie(id)
			give_sting(id)
			g_zombie_class[id] = 0
		}
		if(g_ZB_class[id] == 8)
		{
			reset_value_zombie(id)
			give_stamper(id)
			g_zombie_class[id] = 3
		}
		
		evolution(id, infector)
		UpdateHealthZombie(id, infector)
		havegravity[id] = false
		sound_zombie(id)
		set_task(0.2, "zombie_menu", id)
		set_task(6.0, "destroy_menu", id)
		zbcanbuys[id] = true
		if(zbgrnadeunlocked[id]) give_zb(id)
		engclient_cmd(id, "weapon_knife")
		
		timer = 5
		set_task(0.2, "countdown", id)
}

public make_zombie(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
	set_task(0.5,"first_zb_health", id)
}

public make_zombie2(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
	set_task(0.5,"first_zb_health", id)
}

public make_zombie3(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
	set_task(0.5,"first_zb_health", id)
}

public first_zb_health(id)
{
	set_user_health(id, ZB_LV2_HEALTH)
	g_start_health[id] = ZB_LV2_HEALTH
}

public sound_zombie(id)
{
	if(zp_get_user_first_zombie(id) || first_zombi[id]) return;

	else if(!g_zombie_die[id])
	{
		client_cmd(0, "spk ^"%s^"", zombie_infect[random( sizeof(zombie_infect))])
		
		if(g_zombie_class[id] == 1 || g_zombie_class[id] == 3 || g_zombie_class[id] == 5)
		{
			PlayEmitSound(id, zombie_jerit_male[random( sizeof(zombie_jerit_male))])
		}

		if(g_zombie_class[id] == 0 || g_zombie_class[id] == 2 || g_zombie_class[id] == 4)
		{
			PlayEmitSound(id, zombie_jerit_female[random( sizeof(zombie_jerit_female))])
		}
	}
}

UpdateHealthZombie(id, infector)
{
	if(!zp_get_user_zombie(id)) return;
		
	new health, armor, healthX
	if(g_zombie_die[id])
	{
		health = g_start_health[id]
		if(incrshpunlocked[id]) health = health + 4000
		else health = health + 2000
		
		g_start_health[id] = health
		g_star_armor[id] = armor
		
		health = max(MIN_HEALTH_ZOMBIE, health)
		armor = max(MIN_ARMOR_ZOMBIE, armor)
		
		g_start_health[id] = health
		
		set_user_health(id, health)
		set_user_armor(id, armor)
	}
	else
	{
		if(zp_get_user_first_zombie(id) || first_zombi[id])
		{
			set_user_health(id, ZB_LV2_HEALTH)
			g_start_health[id] = ZB_LV2_HEALTH
			set_user_armor(id, ZB_LV2_ARMOR)
			g_level[id] = 2
			KillCount[id] = 3
		}
		else
		{
			if(incrshpunlocked[id]) g_start_health[id] = get_user_health(infector) + 3000
			else g_start_health[id] = get_user_health(infector)*4/5
			
			g_star_armor[id] = get_user_armor(infector)*4/5
			
			health = g_start_health[id]
			armor = g_star_armor[id]
			
			health = max(MIN_HEALTH_ZOMBIE, health)
			armor = max(MIN_ARMOR_ZOMBIE, armor)
			
			g_start_health[id] = health
			
			set_user_health(id, health)
			set_user_armor(id, armor)
			
			if(incrshpunlocked[infector])
			{
				g_start_health[infector] = get_user_health(infector) + 2000
				healthX = g_start_health[infector]
				set_user_health(infector, healthX)
			}
		}
	}
}

public evolution(id, infector)
{
	if(!is_user_alive(infector))
		return
		
	if(!g_level[id]) g_level[id] = 1
	KillCount[infector]++
	if(KillCount[infector] == 3 && !zombiedeath2[id])
	{
		g_level[infector] = 2
		if(get_user_health(infector) < ZB_LV2_HEALTH)
		{
			set_user_health(infector, ZB_LV2_HEALTH)
			g_start_health[infector] = ZB_LV2_HEALTH
			set_user_armor(infector, ZB_LV2_ARMOR)
		}
		g_zombie_die[infector] = 0
		client_printc(infector, "!gHas evolucionado a zombi originario!")
		
		if(g_zombie_class[infector] == 1 || g_zombie_class[infector] == 3 || g_zombie_class[infector] == 5) client_cmd(0, "spk ^"%s^"", zombie_evolution_male)
		else client_cmd(0, "spk ^"%s^"", zombie_evolution_female)
		
	}
	else if(KillCount[infector] == 6 && !zombiedeath2[id])
	{
		g_level[infector] = 3
		if(get_user_health(infector) < ZB_LV3_HEALTH)
		{
			set_user_health(infector, ZB_LV3_HEALTH)
			g_start_health[infector] = ZB_LV3_HEALTH
			set_user_armor(infector, ZB_LV3_ARMOR)
		}
		g_zombie_die[infector] = 0
		client_printc(infector, "!gHas evolucionado a superzombi!")
		
		if(g_zombie_class[infector] == 1 || g_zombie_class[infector] == 3 || g_zombie_class[infector] == 5) client_cmd(0, "spk ^"%s^"", zombie_evolution_male)
		else client_cmd(0, "spk ^"%s^"", zombie_evolution_female)
	}
}

public fw_PlayerKilled(id)
{	
	if(zp_get_user_last_human(id) || zp_get_user_last_zombie(id))
	return
	
	g_zombie_die[id] ++
	zombiedeath2[id] = true
	first_zombi[id] = 0
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && dam[attacker])
	{
		new Float: xdmg = get_pcvar_float(p_dmg_multiplier)
		damage *= xdmg
		SetHamParamFloat(4, damage)
	}
	else if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker))
	{
		g_restore_health[victim] = 0
	}
}


public fw_PlayerTraceAttack(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && dam[attacker])
	{
		new Float: xdmg = get_pcvar_float(p_dmg_multiplier)
		Damage *= xdmg
		SetHamParamFloat(3, Damage)
	}
	else if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker))
	{
		g_restore_health[victim] = 0
	}
}

public fw_Spawn_Post(id)
{
    if(is_user_alive(id))g_LoadoutConfirmed[id]=false;
	if (is_user_alive(id) && !zp_get_user_zombie(id)) 
	{
	reset_value(id)
	reset_value_zombie(id)
	ResetKills(id)
	remove_task(id)
	strip_user_weapons(id)
	fm_give_item( id, "weapon_knife" )
	fm_give_item(id, "weapon_usp")
	cs_set_user_bpammo( id, CSW_USP, 200 )
	set_task(0.3, "DisplayMenu", id)
	zbcanbuys[id] = true
	if(get_user_flags(id) & ADMIN_LEVEL_E)
	{
		pwrsawunlocked2[id] = true
		drgnswrdunlocked[id] = true
		stamperunlocked[id] = true
	}
	if(codebox1(id)) cyunlocked[id] = true
	if(codebox2(id)) cannonunlocked[id] = true
	if(codebox3(id)) railunlocked[id] = true
	can_choose[id] = 1
	first_zombi[id] = 0
	remove_task(id+TASK_NOL)
	set_task(30.0, "choose_nol", id+TASK_NOL)
	if(revo_get_kostum(id)) dapet_kostum[id] = true
	
	if(jumpunlocked[id])
	{
		set_user_gravity(id, get_pcvar_float(p_grav))
	}
	if(damunlocked[id])
	{
		dam[id] = true
	}
	if(nghtvisionunlocked[id])
	{
		cs_set_user_nvg(id, 1)
	}
	
	if(deadlyunlocked[id])
	{
		give_ds(id)
	}
	
	if(bloodyunlocked[id])
	{
		give_bb(id)
	}
	
	if(sprintunlocked[id])
	{
		give_sprint(id)
	}
	
	}
}

public destroy_menu(id) show_menu(id, 0, "^n", 1);

public choose_nol(id)
{
	id -= TASK_NOL
	
	if(!is_user_alive(id))
		return
	
	can_choose[id] = 0
}

public OpenVguiLoadout(id){
    if(!is_user_connected(id))return PLUGIN_HANDLED;
    new msg=get_user_msgid("BuyClose");
    if(msg){message_begin(MSG_ONE,msg,_,id);message_end();}
    return OpenPendingLoadout(id);
}
public OpenPendingLoadout(id){
    if(!is_user_alive(id) || zp_get_user_zombie(id) || revo_get_user_hero(id))return PLUGIN_HANDLED;
    if(!g_LoadoutConfirmed[id])DisplayMenu(id);
    else client_print(id,print_center,"Ya confirmaste tu equipo esta vida.");
    return PLUGIN_HANDLED;
}
public ReturnToLoadout(id){OpenPendingLoadout(id);}
public DisplayMenu( id )
{
    if (!is_user_alive(id) || zp_get_user_zombie(id) || g_LoadoutConfirmed[id]) return;
    
    new menu = menu_create( "\yWeapon Menu:", "MenuHandler" );
    
    new szItem[ 64 ];
    
    formatex( szItem, charsmax( szItem ), "Primary weapon \d[ \y%s \d]", g_PrimaryNames[ iWeapprim[ id ] ] );
    menu_additem( menu, szItem, "0" );
    
    formatex( szItem, charsmax( szItem ), "Secondary weapon \d[ \y%s \d]", g_SecondaryNames[ iWeapsec[ id ] ] );
    menu_additem( menu, szItem, "1" );
    
    formatex( szItem, charsmax( szItem ), "Melee weapon \d[ \y%s \d]^n", g_MeleeNames[ iWeapmelee[ id ] ] );
    menu_additem( menu, szItem, "2" );
    
    menu_additem( menu, "Confirmar equipo", "3" );
    new grenadeName[32];exhero_special_name(id,grenadeName,charsmax(grenadeName));
    formatex(szItem,charsmax(szItem),"Granada \d[ \y%s \d]",grenadeName);
    menu_additem(menu,szItem,"4");
    
    
    menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER );
    
    menu_display( id, menu );
}

public MenuHandler( id, menu, item )
{
    menu_destroy(menu);
    if(item<0 || !is_user_alive(id) || zp_get_user_zombie(id) || g_LoadoutConfirmed[id])return;
    switch( item )
    {
        case 0:
        {
			gunsmenu( id )
        }
        case 1:
        {
			pistolmenu( id )
        }
        case 2:
        {
			knifemenu( id )
        }
        case 4: { exhero_special_menu(id); }
        case 3:
        {    
			giveweapons(id)
        }
        
    }
}

public give_prims( id, number )
{
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return;
    if(number==31){zp_give_user_usas_thunderfall(id);return;}
    if (number == 30) { zh_give_drakar(id); return; }
    if (number == 29) { give_weapon_guitar(id); return; }
    if (number == 27) { exhero_give_firefox(id); return; }
    if (number == 28) { exhero_give_genocider(id); return; }
    if (number == 26) { exhero_give_lockon(id); return; }
    if (number == 11 || number == 8 || number == 12 || number == 19 || number == 21) number = 0;
    if (number == 6 || number == 7 || number == 9 || number == 14 || number == 15 || number == 20 || number == 23 || number == 24 || number == 25) number = 0;

    switch( number )
    {
        case 0:
        {
            fm_give_item(id, "weapon_m4a1")
            cs_set_user_bpammo( id, CSW_M4A1, 200 )
        }
        case 1:
        {
            fm_give_item(id, "weapon_ak47")
            cs_set_user_bpammo( id, CSW_AK47, 200 )
        }
        case 2:
        {
            fm_give_item(id, "weapon_famas")
            cs_set_user_bpammo( id, CSW_FAMAS, 200 )
        }
        case 3:
        {
            fm_give_item(id, "weapon_p90")
            cs_set_user_bpammo( id, CSW_P90, 200 )
        }
        case 4:
        {
            fm_give_item(id, "weapon_xm1014")
            cs_set_user_bpammo( id, CSW_XM1014, 64 )
        }
        case 5:
        {
            give_buffm4(id)
        }
        case 6:
        {
            /* retired weapon */
        }
        case 7:
        {
            fm_give_item(id, "weapon_m4a1") // Janus-7 removida
        }
        case 8:
        {
            give_nata(id)
        }
        case 9:
        {
            /* retired weapon */
        }
        case 10:
        {
            zp_give_user_halogun(id)
        }
        case 11:
        {
            fm_give_item(id, "weapon_m4a1")
        }
        case 12:
        {
            give_nata(id)
        }
        case 13:
        {
            give_buffak(id)
        }
        case 14:
        {
            /* retired weapon */
        }
        case 15:
        {
            /* retired weapon */
        }
        case 16:
        {
            zp_give_user_y21s4janusd(id)
        }
        case 17:
        {
            get_dragoncannon(id)
        }
        case 18:
        {
            zp_give_user_lunar_cannon(id)
        }
        case 19:
        {
            give_nata(id)
        }
        case 20:
        {
            /* retired weapon */
        }
        case 21:
        {
            give_nata(id)
        }
        case 22:
        {
            fm_give_item(id, "weapon_ak47")
        }
        case 23:
        {
            /* retired weapon */
        }
        case 24:
        {
            fm_give_item(id, "weapon_m4a1") // slot desactivado
        }
        case 25:
        {
            fm_give_item(id, "weapon_m4a1") // slot desactivado
        }
    }
}

public give_sec( id, number )
{
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return;
    if (number == 12) { exhero_give_eclipse(id); return; }
    if (number == 10) { if(exhero_sylphid_unlocked(id)){sylphid_give_weapon(id);return;} number=0; }
    if (number == 11) { exhero_give_coindart(id); return; }
    if (number == 7 || number == 4 || number == 5 || number == 9) number = 0;

    switch( number )
    {
        case 0:
        {
			fm_give_item(id, "weapon_usp")
			cs_set_user_bpammo( id, CSW_USP, 200 )
        }
		case 1:
        {
			fm_give_item(id, "weapon_elite")
			cs_set_user_bpammo( id, CSW_ELITE, 300 )
        }
		case 2:
        {
			fm_give_item(id, "weapon_glock18")
			cs_set_user_bpammo( id, CSW_GLOCK18, 300 )
        }
		case 3:
        {
			fm_give_item(id, "weapon_deagle")
			cs_set_user_bpammo( id, CSW_DEAGLE, 40 )
        }
		case 4:
        {
			/* retired weapon */
        }
		case 5:
        {
			/* retired weapon */
        }
		case 6:
        {
			zp_give_user_star_taylor(id)
        }
		case 7:
        {
			fm_give_item(id,"weapon_usp")
        }
		case 8:
        {
			zp_give_user_voidpistol(id)
        }
		case 9:
        {
			fm_give_item(id, "weapon_deagle") // slot desactivado
        }
	}
}

public give_melee( id, number )
{
    if (id < 1 || id > 32 || !is_user_alive(id)) return;
    if (number == 2 || number == 3 || number == 4 || number == 5) number = 0;
    exhero_remove_flail(id);
    exhero_remove_holy(id);
    exhero_remove_lance(id);
    zp_remove_user_whipsword(id);
    zp_remove_user_twin_shadow_axes(id);
    if (callfunc_begin("remove_katana", "cuchillo_nata.amxx") == 1) { callfunc_push_int(id); callfunc_end(); }
    if (number == 7) { exhero_give_flail(id); return; }
    if (number == 8) { exhero_give_holy(id); return; }
    if (number == 9) { exhero_give_lance(id); return; }
    if (number != 1) zp_remove_user_twin_shadow_axes(id);

    switch( number )
    {
        case 0:
        {
            give_nata(id)
        }
        case 1:
        {
            zp_give_user_twin_shadow_axes(id)
        }
        case 2:
        {
            give_nata(id)
        }
        case 3:
        {
            give_nata(id) // Lightsaber desactivado
        }
        case 4:
        {
            /* retired weapon */
        }
        case 5:
        {
            give_nata(id)
        }
        case 6:
        {
            zp_give_user_whipsword(id) // Whip Sword reemplaza Ruyi
        }
    }
}

public give_itemsss(id)
{
	if(!exhero_special_loadout(id, grnadehmunlocked[id]))
	{
		fm_give_item(id, "weapon_hegrenade")
		if(grnadehmunlocked[id])zp_force_buy_extra_item(id, zp_get_extra_item_id("HE Grenade"), 1)
	}
						
	if(ammounlocked[id])
	{
		refill2(id)
	}
	
	if(dapet_kostum[id]) give_costumes(id)

}

public giveweapons(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id) || g_LoadoutConfirmed[id]){
		return 1;
	}
	
 new total;
 for(new n=0;n<sizeof g_PriceValue;n++)if(!g_PriceUnlocked[id][n]&&PriceSelected(id,n))total+=g_PriceValue[n];
 if(zp_cs_get_user_money(id)<total){client_print(id,print_center,"Necesitas $%d para desbloquear el equipo seleccionado.",total);DisplayMenu(id);return 1;}
 for(new n=0;n<sizeof g_PriceValue;n++)if(PriceSelected(id,n))BuyPricedItem(id,g_PriceGroup[n],g_PriceIndex[n]);
	g_LoadoutConfirmed[id]=true;
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	give_melee( id, iWeapmelee[ id ] )
	give_sec( id, iWeapsec[ id ] )
	give_prims( id, iWeapprim[ id ] )
	give_itemsss(id)
        
	client_print_color(id, print_team_red, "%s ^1Primary Weapon : ^3'^4%s^3' ^4| ^1Secondary Weapon : ^3'^4%s^3' ^3| ^1Melee Weapon : ^3'^4%s^3' ^3", g_szPrefix, g_PrimaryNames[iWeapprim[id]], g_SecondaryNames[iWeapsec[id]], g_MeleeNames[iWeapmelee[id]]);
	return 0;
    
}

public fw_Item_Deploy_Post(weapon_ent)
{
	if (pev_valid(weapon_ent) != 2) return;

	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	if (owner < 1 || owner > 32 || !is_user_alive(owner)) return;
	if (get_pdata_cbase(owner, 373, 5) != weapon_ent) return;
		
	replace_weapon_models(owner)
}

replace_weapon_models(id)
{
	if (id < 1 || id > 32 || !is_user_alive(id)) return;

	set_pev(id, pev_viewmodel2, "")
	set_pev(id, pev_weaponmodel2, "")
}

public fw_SetModel(iEnt,const szModel[])
{
	static iLen
	iLen = strlen(szModel)	
	if (iLen < 14) return FMRES_IGNORED
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'a' && szModel[10] == 'w') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'g' && szModel[10] == '3') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'c') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'm' && szModel[10] == '2') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'g' && szModel[13] == '2') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'a' && szModel[10] == 'u') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'g' && szModel[13] == '0')
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'm' && szModel[10] == '3') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'm' && szModel[10] == 'a' && szModel[11] == 'c') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'u' && szModel[10] == 'm' && szModel[13] == '5') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'f' && szModel[10] == 'i' && szModel[17] == 'n') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'p' && szModel[10] == '2' && szModel[11] == '2') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'm' && szModel[10] == 'p' && szModel[11] == '5') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 't' && szModel[10] == 'm' && szModel[11] == 'p') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 'g' && szModel[10] == 'a' && szModel[13] == 'l') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'p' && szModel[8] == 'l' && szModel[9] == 'a' && szModel[10] == 'y' && szModel[12] == 'r' && szModel[13] == '/') 
	{
		return FMRES_SUPERCEDE
	}
	
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'm' && szModel[11] == 'o' && szModel[12] == 'k') 
	{
		return FMRES_SUPERCEDE
	}
		
	return FMRES_IGNORED
}

public SetClientKeyValue( id, const infobuffer[], const key[])
{
	if (equal( key, "model" ) )  
	{
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public gunsmenu(id) 
{
	
		menu1 = menu_create("\wPrimary Weapons\r:", "gunsmenu_Handle")

		new temp[101];
		
		AddPricedItem(id,menu1,"M4A1",0,1)
		AddPricedItem(id,menu1,"AK47",1,2)
		AddPricedItem(id,menu1,"Famas",2,3)
		AddPricedItem(id,menu1,"P90",3,4)
		AddPricedItem(id,menu1,"XM1014",4,5)
		AddPricedItem(id,menu1,"Lightning AR-1",18,30)
        AddPricedItem(id,menu1,"USAS-12 Thunderfall",20,32)
		
		if(!mg3unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_mg3)) formatex(temp,100, "\yM4A1 Dark Knight\w(\r$%i\w)",get_pcvar_num(p_mg3))
			else formatex(temp,100, "\yM4A1 Dark Knight\w(\r$%i\w)",get_pcvar_num(p_mg3))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "\wM4A1 Dark Knight" , "6", 0)
		}
		
// retired: 		menu_additem(menu1, "M1887-XMAS", "7", 0)
		
		if(!jns7unlocked[id])
		{
// retired: 			menu_additem(menu1, temp,"8",0)
		}
		else
		{
		}
		
		if(!gatlingunlocked[id])
		{
			if(stok_bl11 >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_gatling)) formatex(temp,100, "\yBalrog-XI Blue\w(\r$%i\w) Stock: %i",get_pcvar_num(p_gatling), stok_bl11)
				else formatex(temp,100, "\dBalrog-XI Blue\w(\r$%i\w) Stock: %i",get_pcvar_num(p_gatling), stok_bl11)
			}
			else formatex(temp,100, "\dBalrog-XI Blue\w(\r$%i\w) AGOTADO",get_pcvar_num(p_gatling))
			
			{} // Retired
		}
		else
		{
			{} // Retired
		}
		
		if(!antidtrunlocked[id])
		{
			if(stok_aeolis >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_antdtr)) formatex(temp,100, "\yAeolis\w(\r$%i\w) Stock: %i",get_pcvar_num(p_antdtr), stok_aeolis)
				else formatex(temp,100, "\dAeolis\w(\r$%i\w) Stock: %i",get_pcvar_num(p_antdtr), stok_aeolis)
			}
			else formatex(temp,100, "\dAeolis\w(\r$%i\w) AGOTADO",get_pcvar_num(p_antdtr))
			
// retired: 			menu_additem(menu1, temp,"10",0)
		}
		else
		{
// retired: 			menu_additem(menu1, "Aeolis" , "10", 0)
		}
		
		if(!awpzunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_awpz)) formatex(temp,100, "\yArbalest (Halo Gun)\w(\r$%i\w)",get_pcvar_num(p_awpz))
			else formatex(temp,100, "\yArbalest (Halo Gun)\w(\r$%i\w)",get_pcvar_num(p_awpz))
			menu_additem(menu1, temp,"11",0)
		}
		else
		{
			menu_additem(menu1, "\wArbalest (Halo Gun)" , "11", 0)
		}
		
		if(!blrg7unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_sk4)) formatex(temp,100, "\ySkull-4\w(\r$%i\w)",get_pcvar_num(p_sk4))
			else formatex(temp,100, "\dSkull-4\w(\r$%i\w)",get_pcvar_num(p_sk4))
			{} // Retired
		}
		else
		{
			{} // Retired
		}
		
		if(!blrg3unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_blrg3)) formatex(temp,100, "\yAK47 Paladin\w(\r$%i\w)",get_pcvar_num(p_blrg3))
			else formatex(temp,100, "\yAK47 Paladin\w(\r$%i\w)",get_pcvar_num(p_blrg3))
			menu_additem(menu1, temp,"14",0)
		}
		else
		{
			menu_additem(menu1, "\wAK47 Paladin" , "14", 0)
		}
		
		if(!plasmaunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_plasma)) formatex(temp,100, "\yPlasma Gun\w(\r$%i\w)",get_pcvar_num(p_plasma))
			else formatex(temp,100, "\dPlasma Gun\w(\r$%i\w)",get_pcvar_num(p_plasma))
// retired: 			menu_additem(menu1, temp,"15",0)
		}
		else
		{
// retired: 			menu_additem(menu1, "Plasma Gun" , "15", 0)
		}
		
		if(!pwrsawunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_pwrsaw)) formatex(temp,100, "\yPowerSaw\w(\r$%i\w)",get_pcvar_num(p_pwrsaw))
			else formatex(temp,100, "\dPowerSaw\w(\r$%i\w)",get_pcvar_num(p_pwrsaw))
// retired: 			menu_additem(menu1, temp,"16",0)
		}
		else
		{
// retired: 			menu_additem(menu1, "PowerSaw" , "16", 0)
		}
		
		if(!pwrsawunlocked2[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_pwrsaw2)) formatex(temp,100, "\yMecha Dino MK-4\w(\r$%i\w)",get_pcvar_num(p_pwrsaw2))
			else formatex(temp,100, "\yMecha Dino MK-4\w(\r$%i\w)",get_pcvar_num(p_pwrsaw2))
			menu_additem(menu1, temp,"17",0)
		}
		else
		{
			menu_additem(menu1, "\wMecha Dino MK-4" , "17", 0)
		}
		
		if(!cannonunlocked[id])
		{
			if(jumlah_cannon() <= 1) formatex(temp,100, "\dBlack Dragon Cannon\w(\rCode Box\w) %i/1 Max 1 Players", jumlah_cannon())
			else formatex(temp,100, "\dBlack Dragon Cannon\w(\rCode Box\w) 1/1 Max 1 Players")
			menu_additem(menu1, temp,"18",0)
		}
		else
		{
			menu_additem(menu1, "Black Dragon Cannon [Permanent]" , "18", 0)
		}
		
		if(!sk4unlocked[id])
		{
			if(stok_balrog5 >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_bl5)) formatex(temp,100, "\yLunar Cannon\w(\r$%i\w) Stock: %i",get_pcvar_num(p_bl5), stok_balrog5)
				else formatex(temp,100, "\yLunar Cannon\w(\r$%i\w) Stock: %i",get_pcvar_num(p_bl5), stok_balrog5)
			}
			else formatex(temp,100, "\yLunar Cannon\w(\r$%i\w) AGOTADO",get_pcvar_num(p_bl5))
			
			menu_additem(menu1, temp,"19",0)
		}
		else
		{
			menu_additem(menu1, "\wLunar Cannon" , "19", 0)
		}
		
		if(!janus11unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_jns11)) formatex(temp,100, "\yJanus-11\w(\r$%i\w)",get_pcvar_num(p_jns11))
			else formatex(temp,100, "\dJanus-11\w(\r$%i\w)",get_pcvar_num(p_jns11))
			{} // Retired
		}
		else
		{
			{} // Retired
		}
		
		if(!petrolunlocked[id])
		{
			if(stok_petrol >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_petrol)) formatex(temp,100, "\yPetrolboomer\w(\r$%i\w) Stock: %i",get_pcvar_num(p_petrol), stok_petrol)
				else formatex(temp,100, "\dPetrolboomer\w(\r$%i\w) Stock: %i",get_pcvar_num(p_petrol), stok_petrol)
			}
			else formatex(temp,100, "\dPetrolboomer\w(\r$%i\w) AGOTADO",get_pcvar_num(p_petrol))
			
// retired: 			menu_additem(menu1, temp,"21",0)
		}
		else
		{
// retired: 			menu_additem(menu1, "Petrolboomer" , "21", 0)
		}
		
		if(!janus3unlocked[id])
		{
			if(stok_janus3 >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_janus3)) formatex(temp,100, "\yAncient Keeper\w(\r$%i\w) Stock: %i",get_pcvar_num(p_janus3), stok_janus3)
				else formatex(temp,100, "\dAncient Keeper\w(\r$%i\w) Stock: %i",get_pcvar_num(p_janus3), stok_janus3)
			}
			else formatex(temp,100, "\dAncient Keeper\w(\r$%i\w) AGOTADO",get_pcvar_num(p_janus3))
			
			{} // Retired
		}
		else
		{
			{} // Retired
		}
		
		if(!railunlocked[id])
		{
{} // Retired weapon
		}
		else
		{
{} // Retired weapon
		}
		
		if(!brickunlocked[id])
		{
			if(stok_brick >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_brickp)) formatex(temp,100, "\yBrick Peace V2\w(\r$%i\w) Stock: %i", get_pcvar_num(p_brickp), stok_brick)
				else formatex(temp,100, "\dBrick Peace V2\w(\r$%i\w) Stock: %i", get_pcvar_num(p_brickp), stok_brick)
			}
			else formatex(temp,100, "\dBrick Peace V2\w(\r$%i\w) AGOTADO", get_pcvar_num(p_brickp))
			
// retired: 			menu_additem(menu1, temp,"24",0)
		}
		else
		{
// retired: 			menu_additem(menu1, "Brick Peace V2" , "24", 0)
		}
		// Slot 25 libre: Thanatos-11 desactivada.
		// Slot 26 libre: Guillotine/Blood Dripper desactivada.

		
		AddPricedItem(id,menu1,"X-TRACKER",5,27)
		AddPricedItem(id,menu1,"FireFox",6,28)
		AddPricedItem(id,menu1,"Genocider VI",7,29)
		AddPricedItem(id,menu1,"Drakar II",19,31)
		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
	
		if (is_user_alive(id) && !zp_get_user_zombie(id)) 
		{
			menu_display(id, menu1, 0)
		}
	
		return PLUGIN_HANDLED
}

public gunsmenu_Handle(id, menu1, item)
{
	if (item < 0) { menu_destroy(menu1); return PLUGIN_HANDLED; }

	if (zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
 if(!is_user_alive(id)||g_LoadoutConfirmed[id]){menu_destroy(menu1);return PLUGIN_HANDLED;}
 if(!BuyPricedItem(id,0,key-1)){menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;}
	if(key==32){iWeapprim[id]=31;menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;}
	if (key == 31) {iWeapprim[id]=30;menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;}
	if (key == 30) { iWeapprim[id]=29;menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED; }
	if (key == 29) { iWeapprim[id] = 28; menu_destroy(menu1); DisplayMenu(id); return PLUGIN_HANDLED; }
	if (key == 28) { iWeapprim[id] = 27; menu_destroy(menu1); DisplayMenu(id); return PLUGIN_HANDLED; }
	if (key == 27) { iWeapprim[id] = 26; menu_destroy(menu1); DisplayMenu(id); return PLUGIN_HANDLED; }
	if (key == 12 || key == 23 || key == 9 || key == 13 || key == 20 || key == 22 || key == 7 || key == 8 || key == 10 || key == 15 || key == 16 || key == 21 || key == 24 || key == 25 || key == 26) { menu_destroy(menu1); return PLUGIN_HANDLED; }
	
	switch(key)
	{
		case 1:
		{
			iWeapprim[ id ] = 0
			DisplayMenu( id )
		}
		case 2:
		{
			iWeapprim[ id ] = 1
			DisplayMenu( id )
		}
		
		case 3:
		{		
			iWeapprim[ id ] = 2
			DisplayMenu( id )
		}

		case 4:
		{
			iWeapprim[ id ] = 3
			DisplayMenu( id )
		}
		
		case 5:
		{
			iWeapprim[ id ] = 4
			DisplayMenu( id )
		}

		case 6:
		{
				if(!mg3unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_mg3))
					{
						gunsmenu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_mg3))
						mg3unlocked[id] = true
						iWeapprim[ id ] = 5
						jml_sk5 ++
						DisplayMenu( id )
					}
				}
				else
				{
					iWeapprim[ id ] = 5
					DisplayMenu( id )
				}
		}
		case 7:
		{
						iWeapprim[ id ] = 6
						jml_m1887 ++
						DisplayMenu( id )
		}
		case 8:
		{
				if(!jns7unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_janus7))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 7
						jml_jns7 ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_janus7))
						jns7unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 7
					DisplayMenu(id)
				}
		}
		case 9:
		{
			if(!gatlingunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_gatling) || stok_bl11 <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 8
						stok_bl11 --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_gatling))
						gatlingunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 8
					DisplayMenu(id)
				}
		}
		case 10:
		{
			if(!antidtrunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_antdtr) || stok_aeolis <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 9
						jml_aeolis ++
						stok_aeolis --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_antdtr))
						antidtrunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 9
					DisplayMenu(id)
				}
		}
		case 11:
		{
			if(!awpzunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_awpz))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 10
						jml_spear ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_awpz))
						awpzunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 10
					DisplayMenu(id)
				}
		}
		case 12:
		{
			if(!m32unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_m32))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 11
						jml_thunder ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_m32))
						m32unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 11
					DisplayMenu(id)
				}
		}
		case 13:
		{
			if(!blrg7unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sk4))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 12
						jml_bl7 ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sk4))
						blrg7unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 12
					DisplayMenu(id)
				}
		}
		case 14:
		{
			if(!blrg3unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_blrg3))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 13
						jml_bow ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_blrg3))
						blrg3unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 13
					DisplayMenu(id)
				}
		}
		case 15:
		{
				if(!plasmaunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_plasma))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 14
						jml_plasma ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_plasma))
						plasmaunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 14
					DisplayMenu(id)
				}
		}
		case 16:
		{
			if(!pwrsawunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_pwrsaw))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 15
						jml_saw ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_pwrsaw))
						pwrsawunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 15
					DisplayMenu(id)
				}	
		}
		case 17:
		{
			if(!pwrsawunlocked2[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_pwrsaw2))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 16
						jml_jns5 ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_pwrsaw2))
						pwrsawunlocked2[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 16
					DisplayMenu(id)
				}
		}
		case 18:
		{
			if(!cannonunlocked[id])
				{
					gunsmenu(id)
					if(jumlah_cannon() >= 1) client_print(id, print_center, "El cupo ya esta lleno. Intentalo en el proximo mapa.")
					else client_print(id, print_center, "Cari Supply Box!, sebelum ada 1 player yang mendapatkannya !")
				}
				else
				{
					iWeapprim[ id ] = 17
					DisplayMenu(id)
				}
		}
		case 19:
		{
			if(!sk4unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_bl5) || stok_balrog5 <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 18
						jml_bl5 ++
						stok_balrog5 --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bl5))
						sk4unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 18
					DisplayMenu(id)
				}
		}
		case 20:
		{
			if(!janus11unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_jns11))
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 19
						jml_jns11 ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_jns11))
						janus11unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 19
					DisplayMenu(id)
				}
		}
		case 21:
		{
			if(!petrolunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_petrol) || stok_petrol <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 20
						jml_petrol ++
						stok_petrol --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_petrol))
						petrolunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 20
					DisplayMenu(id)
				}
		}
		case 22:
		{
			if(!janus3unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_janus3) || stok_janus3 <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 21
						jml_jns3 ++
						stok_janus3 --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_janus3))
						janus3unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 21
					DisplayMenu(id)
				}
		}
		case 23:
		{
			if(!railunlocked[id])
				{
					gunsmenu(id)
					client_print(id, print_center, "Cari Supply Box untuk mendapatkan Special Weapon ini !")
				}
				else
				{
					iWeapprim[ id ] = 22
					DisplayMenu(id)
				}
		}
		case 24:
		{
			if(!brickunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_brickp) || stok_brick <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 23
						stok_brick --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_brickp))
						brickunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 23
					DisplayMenu(id)
				}
		}
		case 25:
		{
			if(!th11unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_th11) || stok_th11 <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 24
						stok_th11 --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_th11))
						th11unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 24
					DisplayMenu(id)
				}
		}
		case 26:
		{
			if(!bddrippunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_bddripp) || stok_bddripp <= 0)
					{
						gunsmenu(id)
					}
					else
					{
						iWeapprim[ id ] = 25
						stok_bddripp --
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bddripp))
						bddrippunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 25
					DisplayMenu(id)
				}
		}
	}
	return PLUGIN_HANDLED;
}

public pistolmenu(id) 
{
	
		menu1 = menu_create("\wSecondary Weapons\r:", "pistolmenu_Handle")

		new temp[101];
		
		AddPricedItem(id,menu1,"USP",8,1)
		AddPricedItem(id,menu1,"Beretta 92G Elite II",9,2)
		AddPricedItem(id,menu1,"Glock",10,3)
		AddPricedItem(id,menu1,"Deagle",11,4)
// retired: 		menu_additem(menu1, "Balrog-I", "5", 0)
// retired: 		menu_additem(menu1, "Skull-1", "6", 0)
		
		if(!cyunlocked[id])
		{
			if(jumlah_cyclone() <= 4) formatex(temp,100, "\dStar Taylor\w(\rSupply Box\w) %i/4 - Max. 4 jugadores", jumlah_cyclone())
			else formatex(temp,100, "\dStar Taylor\w(\rSupply Box\w) 4/4 - Max. 4 jugadores")
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Star Taylor [Permanente]" , "7", 0)
		}
		
		if(!dinfiunlocked2[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_dinfi2)) formatex(temp,100, "\yVoid Avenger\w(\r$%i\w)",get_pcvar_num(p_dinfi2))
			else formatex(temp,100, "\yVoid Avenger\w(\r$%i\w)",get_pcvar_num(p_dinfi2))
			menu_additem(menu1, temp,"9",0)
		}
		else
		{
			menu_additem(menu1, "\wVoid Avenger" , "9", 0)
		}
		// Slot secundario 10 libre: Sha Wujing desactivada.

						
		menu_additem(menu1,exhero_sylphid_unlocked(id)?"\wSylphid":"\dSylphid \w(\rSupply Box\w)","11",0)
		AddPricedItem(id,menu1,"Coin Dart",13,12)
		if(!m32unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_m32)) formatex(temp,100, "\yEclipse Shifter\w(\r$%i\w)",get_pcvar_num(p_m32))
			else formatex(temp,100, "\yEclipse Shifter\w(\r$%i\w)",get_pcvar_num(p_m32))
			menu_additem(menu1, temp, "13", 0)
		}
		else
		{
			menu_additem(menu1, "\wEclipse Shifter", "13", 0)
		}		
				

		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
		
		if (is_user_alive(id) && !zp_get_user_zombie(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public pistolmenu_Handle(id, menu1, item)
{
	if (item < 0) { menu_destroy(menu1); return PLUGIN_HANDLED; }

	if (zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
		
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
 if(!is_user_alive(id)||g_LoadoutConfirmed[id]){menu_destroy(menu1);return PLUGIN_HANDLED;}
 if(key==11){menu_destroy(menu1);if(exhero_sylphid_unlocked(id)){iWeapsec[id]=10;DisplayMenu(id);}else{client_print(id,print_center,"Sylphid se desbloquea en Supply Box.");pistolmenu(id);}return PLUGIN_HANDLED;}
 if(!BuyPricedItem(id,1,key-1)){menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;}
	if(key == 13) {
	    if(!m32unlocked[id]) {
	        if(zp_cs_get_user_money(id)<get_pcvar_num(p_m32)){menu_destroy(menu1);pistolmenu(id);return PLUGIN_HANDLED;}
	        zp_cs_set_user_money(id,zp_cs_get_user_money(id)-get_pcvar_num(p_m32));
	        m32unlocked[id]=true; PlayEmitSound(id,sound_cash);
	    }
	    iWeapsec[id]=12;menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;
	}
	if (key == 12) { iWeapsec[id] = 11; menu_destroy(menu1); DisplayMenu(id); return PLUGIN_HANDLED; }
	
	if (key == 8 || key == 5 || key == 6 || key == 10) { menu_destroy(menu1); return PLUGIN_HANDLED; }
	
	switch(key)
	{	
		case 1:
		{
						iWeapsec[ id ] = 0
						DisplayMenu(id)
		}
		case 2:
		{
						iWeapsec[ id ] = 1
						DisplayMenu(id)
		}
		case 3:
		{
						iWeapsec[ id ] = 2
						DisplayMenu(id)
		}
		case 4:
		{
						iWeapsec[ id ] = 3
						DisplayMenu(id)
		}
		case 5:
		{
						iWeapsec[ id ] = 4
						jml_bl1 ++
						DisplayMenu(id)
		}
		case 6:
		{
						iWeapsec[ id ] = 5
						jml_sk1 ++
						DisplayMenu(id)
		}
		case 7:
		{
				if(!cyunlocked[id])
				{
					pistolmenu(id)
					if(jumlah_cyclone() >= 4) client_print(id, print_chat, "El cupo ya esta lleno. Intentalo en el proximo mapa.")
					else client_print(id, print_chat, "Busca una Supply Box antes de que 4 jugadores consigan esta arma!")
				}
				else
				{
					iWeapsec[ id ] = 6
					DisplayMenu(id)
				}
		}
		case 8:
		{
				if(!dinfiunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_dinfi))
					{
						pistolmenu(id)
					}
					else
					{
						iWeapsec[ id ] = 7
						jml_dinfi ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_dinfi))
						dinfiunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapsec[ id ] = 7
					DisplayMenu(id)
				}
		}
		case 9:
		{
				if(!dinfiunlocked2[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_dinfi2))
					{
						pistolmenu(id)
					}
					else
					{
						iWeapsec[ id ] = 8
						jml_jns1 ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_dinfi2))
                        dinfiunlocked2[id] = true
										DisplayMenu(id)
					}
				}
				else
				{
					iWeapsec[ id ] = 8
					DisplayMenu(id)
				}
		}
		case 10:
		{
				if(!wujingunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_wujing))
					{
						pistolmenu(id)
					}
					else
					{
						iWeapsec[ id ] = 9
						jml_shuwjg ++
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_wujing))
						wujingunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapsec[ id ] = 9
					DisplayMenu(id)
				}
		}
		}
	return PLUGIN_HANDLED;
}

public knifemenu(id) 
{
	menu1 = menu_create("\wMelee Weapons\r:", "knifemenu_Handle")
	new temp[101]

	AddPricedItem(id,menu1,"Nata Knife",14,1)

	// Twin Shadow Axes reemplaza el slot viejo de Janus-9.
	if(!jns9unlocked[id])
	{
		if(zp_cs_get_user_money(id) >= get_pcvar_num(p_janus9))
			formatex(temp, charsmax(temp), "\yTwin Shadow Axes\w(\r$%i\w)", get_pcvar_num(p_janus9))
		else
			formatex(temp, charsmax(temp), "\yTwin Shadow Axes\w(\r$%i\w)", get_pcvar_num(p_janus9))
		menu_additem(menu1, temp, "2", 0)
	}
	else
		menu_additem(menu1, "\wTwin Shadow Axes", "2", 0)

	if(!bl9unlocked[id])
	{
		if(zp_cs_get_user_money(id) >= get_pcvar_num(p_bl9))
			formatex(temp, charsmax(temp), "\yBalrog-IX\w(\r$%i\w)", get_pcvar_num(p_bl9))
		else
			formatex(temp, charsmax(temp), "\dBalrog-IX\w(\r$%i\w)", get_pcvar_num(p_bl9))
		{} // Retired
	}
	else
		{} // Retired
	// key 4 = Lightsaber, libre/no visible.

	if(!lghsberunlocked[id])
	{
		if(zp_cs_get_user_money(id) >= get_pcvar_num(p_lightsaber))
			formatex(temp, charsmax(temp), "\ySkull-9\w(\r$%i\w)", get_pcvar_num(p_lightsaber))
		else
			formatex(temp, charsmax(temp), "\dSkull-9\w(\r$%i\w)", get_pcvar_num(p_lightsaber))
// retired: 		menu_additem(menu1, temp, "5", 0)
	}
	else
// retired: 		menu_additem(menu1, "Skull-9", "5", 0)

	if(!drgnswrdunlocked[id])
	{
		if(zp_cs_get_user_money(id) >= get_pcvar_num(p_drgnswrd))
			formatex(temp, charsmax(temp), "\yDragon Sword\w(\r$%i\w)", get_pcvar_num(p_drgnswrd))
		else
			formatex(temp, charsmax(temp), "\dDragon Sword\w(\r$%i\w)", get_pcvar_num(p_drgnswrd))
		{} // Retired
	}
	else
		{} // Retired
	// Whip Sword reemplaza el slot viejo de Ruyi (key 7).
	if(!ruyiunlocked[id])
	{
		if(zp_cs_get_user_money(id) >= get_pcvar_num(p_ruyi))
			formatex(temp, charsmax(temp), "\yWhip Sword\w(\r$%i\w)", get_pcvar_num(p_ruyi))
		else
			formatex(temp, charsmax(temp), "\yWhip Sword\w(\r$%i\w)", get_pcvar_num(p_ruyi))
		menu_additem(menu1, temp, "7", 0)
	}
	else
		menu_additem(menu1, "\wWhip Sword", "7", 0)

	AddPricedItem(id,menu1,"Tyrant Mace",15,8)
	AddPricedItem(id,menu1,"Holy Sword Divine Order",16,9)
	AddPricedItem(id,menu1,"Lance Scarlet",17,10)
	menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER)

	if(is_user_alive(id) && !zp_get_user_zombie(id))
		menu_display(id, menu1, 0)

	return PLUGIN_HANDLED
}

public knifemenu_Handle(id, menu1, item)
{
	if (item < 0) { menu_destroy(menu1); return PLUGIN_HANDLED; }

	if(zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}

	new data[6], iName[64], access, callback
	menu_item_getinfo(menu1, item, access, data, charsmax(data), iName, charsmax(iName), callback)
	new key = str_to_num(data)
 if(!is_user_alive(id)||g_LoadoutConfirmed[id]){menu_destroy(menu1);return PLUGIN_HANDLED;}
 if(!BuyPricedItem(id,2,key-1)){menu_destroy(menu1);DisplayMenu(id);return PLUGIN_HANDLED;}
	if (key >= 8 && key <= 10) { iWeapmelee[id] = key - 1; menu_destroy(menu1); DisplayMenu(id); return PLUGIN_HANDLED; }
	if (key == 3 || key == 6 || key == 4 || key == 5) { menu_destroy(menu1); return PLUGIN_HANDLED; }

	switch(key)
	{
		case 1:
		{
			iWeapmelee[id] = 0
			DisplayMenu(id)
		}
		case 2:
		{
			if(!jns9unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_janus9))
					knifemenu(id)
				else
				{
					iWeapmelee[id] = 1
					jml_jns9++
					DisplayMenu(id)
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_janus9))
					jns9unlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[id] = 1
				DisplayMenu(id)
			}
		}
		case 3:
		{
			if(!bl9unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_bl9))
					knifemenu(id)
				else
				{
					iWeapmelee[id] = 2
					jml_bl9++
					DisplayMenu(id)
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bl9))
					bl9unlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[id] = 2
				DisplayMenu(id)
			}
		}
		case 5:
		{
			if(!lghsberunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_lightsaber))
					knifemenu(id)
				else
				{
					iWeapmelee[id] = 4
					jml_sk9++
					DisplayMenu(id)
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_lightsaber))
					lghsberunlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[id] = 4
				DisplayMenu(id)
			}
		}
		case 6:
		{
			if(!drgnswrdunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_drgnswrd))
					knifemenu(id)
				else
				{
					iWeapmelee[id] = 5
					jml_drgnswrd++
					DisplayMenu(id)
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_drgnswrd))
					drgnswrdunlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[id] = 5
				DisplayMenu(id)
			}
		}
		case 7:
		{
			if(!ruyiunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_ruyi))
					knifemenu(id)
				else
				{
					iWeapmelee[id] = 6
					jml_ruyi++
					DisplayMenu(id)
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_ruyi))
					ruyiunlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[id] = 6
				DisplayMenu(id)
			}
		}
	}
	return PLUGIN_HANDLED
}

public clcmd_changeteam(id)
{
	static team
	team = fm_cs_get_user_team(id)
	
	// Unless it's a spectator joining the game
	if (team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;
	
	// Pressing 'M' (chooseteam) ingame should show the main menu instead
	itemmenu(id)
	return PLUGIN_HANDLED;
}


public itemmenu(id)
{
	if(zp_get_user_zombie(id))
	{
	ShowMenuZM(id)
	}

	else
	{
	ShowMenuHM(id)
	}  
	
}

public ShowMenuZM(id)
{
	
		menu1 = menu_create("\wObjetos de zombi\r:", "ShowMenuZM_Handle")

		new temp[101];
		
		if(!zbgrnadeunlocked[id])
		{
			formatex(temp,100, "\dGranada zombi\w(\r$%i\w)",get_pcvar_num(p_zbgr))
			menu_additem(menu1, temp,"1",0)
		}
		else
		{
			menu_additem(menu1, "Granada zombi (Desbloqueado)" , "1", 0)
		}

		if(!incrshpunlocked[id])
		{
			formatex(temp,100, "\dIncrease HP\w(\r$%i\w)",get_pcvar_num(p_incrshp))
			menu_additem(menu1, temp,"2",0)
		}
		else
		{
			menu_additem(menu1, "Increase HP (Desbloqueado)" , "2", 0)
		}

		
		menu_setprop(menu1, MPROP_EXIT, MEXIT_ALL);
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public ShowMenuZM_Handle(id, menu1, item)
{
	if (item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
				if(!zbgrnadeunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_zbgr))
					{
						ShowMenuZM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_zbgr))
						zbgrnadeunlocked[id] = true
						give_zb(id)
						jml_grenadezb ++
					}
				}
				else
				{
						ShowMenuZM(id)
				}
		}
		case 2:
				if(!incrshpunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_incrshp))
					{
						ShowMenuZM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_incrshp))
						incrshpunlocked[id] = true
						jml_healthzb ++
					}
				}
				else
				{
						ShowMenuZM(id)
				}
	}
	return PLUGIN_HANDLED;
}



public ShowMenuHM(id)
{
	
		menu1 = menu_create("\wObjetos de humano\r:", "ShowMenuHM_Handle")

		new temp[101];
		
		if(!jumpunlocked[id])
		{
			formatex(temp,100, "\dJump Higher\w(\r$%i\w)",get_pcvar_num(p_jump))
			menu_additem(menu1, temp,"1",0)
		}
		else
		{
			menu_additem(menu1, "Jump Higher (Desbloqueado)" , "1", 0)
		}
		
		if(!damunlocked[id])
		{
			formatex(temp,100, "\d+30% Damage\w(\r$%i\w)",get_pcvar_num(p_dam))
			menu_additem(menu1, temp,"2",0)
		}
		else
		{
			menu_additem(menu1, "+30% Damage (Desbloqueado)" , "2", 0)
		}
		
		if(!grnadehmunlocked[id])
		{
			formatex(temp,100, "\dx2 Grenade\w(\r$%i\w)",get_pcvar_num(p_hmgrnd))
			menu_additem(menu1, temp,"3",0)
		}
		else
		{
			menu_additem(menu1, "x2 Grenade (Desbloqueado)" , "3", 0)
		}
		
		if(!nghtvisionunlocked[id])
		{
			formatex(temp,100, "\dNightvision\w(\r$%i\w)",get_pcvar_num(p_nghtvsion))
			menu_additem(menu1, temp,"4",0)
		}
		else
		{
			menu_additem(menu1, "Nightvision (Desbloqueado)" , "4", 0)
		}
		
		if(!deadlyunlocked[id])
		{
			formatex(temp,100, "\dDeadly Shot [F]\w(\r$%i\w)",get_pcvar_num(p_deadly))
			menu_additem(menu1, temp,"5",0)
		}
		else
		{
			menu_additem(menu1, "Deadly Shot [F] (Desbloqueado)" , "5", 0)
		}

		if(!bloodyunlocked[id])
		{
			formatex(temp,100, "\dBloody Blade [X]\w(\r$%i\w)",get_pcvar_num(p_bloody))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Bloody Blade [X] (Desbloqueado)" , "6", 0)
		}

		if(!sprintunlocked[id])
		{
			formatex(temp,100, "\dSprint [Z]\w(\r$%i\w)",get_pcvar_num(p_sprint))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Sprint [Z] (Desbloqueado)" , "7", 0)
		}
		
		if(!ammounlocked[id])
		{
			formatex(temp,100, "\dExtra Ammo\w(\r$%i\w)",get_pcvar_num(p_ammo))
			menu_additem(menu1, temp,"8",0)
		}
		else
		{
			menu_additem(menu1, "Extra Ammo (Desbloqueado)" , "8", 0)
		}

		// Supply rewards are selected from the weapon menu.
		menu_setprop(menu1, MPROP_PERPAGE, 7)
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}


public ShowMenuHM_Handle(id, menu1, item)
{
    if (item < 0) { menu_destroy(menu1); return PLUGIN_HANDLED; }
    new specialAccess, specialCallback, specialData[16], specialName[64];
    menu_item_getinfo(menu1, item, specialAccess, specialData, charsmax(specialData), specialName, charsmax(specialName), specialCallback);
    if (str_to_num(specialData) == 9)
    {
        menu_destroy(menu1);
        exhero_special_menu(id);
        return PLUGIN_HANDLED;
    }

    if (item == MENU_EXIT || !is_user_alive(id))
    {
        menu_destroy(menu1)
        return PLUGIN_HANDLED
    }
    
    new data[6], iName[64]
    new access, callback
    
    menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
    new key = str_to_num(data)
    
    switch(key)
    {
        case 1:
        {
            if(!jumpunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_jump))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_jump))
                    set_user_gravity(id, get_pcvar_float(p_grav))
                    jumpunlocked[id] = true
                    havegravity[id] = true
                    jml_jump ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        case 2:
        {
            if(!damunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_dam))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_dam))
                    damunlocked[id] = true
                    dam[id] = true
                    jml_30prsen ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        
        case 3:
        {
            if(!grnadehmunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_hmgrnd))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_hmgrnd))
                    grnadehmunlocked[id] = true
                    if(!exhero_special_double(id))zp_force_buy_extra_item( id, zp_get_extra_item_id("HE Grenade"), 1)
                    jml_x2grnd ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        case 4:
        {
            if(!nghtvisionunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_nghtvsion))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_nghtvsion))
                    nghtvisionunlocked[id] = true
                    cs_set_user_nvg(id, 1)
                    jml_nghtvsn ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        case 5:
        {
            if(!deadlyunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_deadly))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_deadly))
                    deadlyunlocked[id] = true
                    give_ds(id)
                    jml_deadly ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }

        case 6:
        {
            if(!bloodyunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_bloody))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bloody))
                    bloodyunlocked[id] = true
                    give_bb(id)
                    jml_bloody ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        case 7:
        {
            if(!sprintunlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_sprint))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sprint))
                    sprintunlocked[id] = true
                    give_sprint(id)
                    jml_sprint ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        case 8:
        {
            if(!ammounlocked[id])
            {
                if(zp_cs_get_user_money(id) < get_pcvar_num(p_ammo))
                {
                    ShowMenuHM(id)
                }
                else
                {
                    PlayEmitSound(id, sound_cash)
                    zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_ammo))
                    ammounlocked[id] = true
                    refill2(id)
                    jml_ammo ++
                }
            }
            else
            {
                ShowMenuHM(id)
            }
        }
        
    }
    return PLUGIN_HANDLED;
}


public zombie_menu(id)
{
	
		menu1 = menu_create("\wClases de zombi\r:", "zombie_Handle")
		
		new temp[101];
		
		menu_additem(menu1, "Zombi comun" , "1", 0)
		menu_additem(menu1, "Zombi del humo" , "2", 0)

		if(!vodounlocked[id])
		{
			formatex(temp,100, "\dGuardian venenoso\w(\r$%i\w)",get_pcvar_num(p_vodo))
			menu_additem(menu1, temp,"3",0)
		}
		else
		{
			menu_additem(menu1, "Guardian venenoso (Desbloqueado)" , "3", 0)
		}
		
		if(!lightunlocked[id])
		{
			formatex(temp,100, "\dRosa sigilosa\w(\r$%i\w)",get_pcvar_num(p_light))
			menu_additem(menu1, temp,"4",0)
		}
		else
		{
			menu_additem(menu1, "Rosa sigilosa (Desbloqueado)" , "4", 0)
		}
		
		if(!deimosunlocked[id])
		{
			formatex(temp,100, "\dDeimos (Desarme)\w(\r$%i\w)",get_pcvar_num(p_deimos))
			menu_additem(menu1, temp,"5",0)
		}
		else
		{
			menu_additem(menu1, "Deimos (Desarme) (Desbloqueado)" , "5", 0)
		}
		
		if(!bansheunlocked[id])
		{
			formatex(temp,100, "\dBanshee (Bruja)\w(\r$%i\w)",get_pcvar_num(p_banshe))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Banshee (Bruja) (Desbloqueado)" , "6", 0)
		}
		
		if(!stamperunlocked[id])
		{
			formatex(temp,100, "\dDedo punzante\w(\r$%i\w)",get_pcvar_num(p_stamper))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Dedo punzante (Desbloqueado)" , "7", 0)
		}
		
		if(!stingunlocked[id])
		{
			formatex(temp,100, "\dSepulturero\w(\r$%i\w)",get_pcvar_num(p_sting))
			menu_additem(menu1, temp,"8",0)
		}
		else
		{
			menu_additem(menu1, "Sepulturero (Desbloqueado)" , "8", 0)
		}

		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
		menu_setprop(menu1, MPROP_PERPAGE, 0)
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public zombie_Handle(id, menu1, item)
{
	if (item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu1)
		remove_task(id)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			if(g_ZB_class[id] == 1)
			{
				menu_destroy(menu1)
				remove_task(id)
			}
			else
			{
				reset_value_zombie(id)
				give_tank(id)
				g_zombie_class[id] = 1
				g_ZB_class[id] = 1
				remove_task(id)
				if(zbgrnadeunlocked[id]) give_zb(id)
				engclient_cmd(id, "weapon_knife")
			}
		}
		case 2:
		{
			if(g_ZB_class[id] == 2)
			{
				menu_destroy(menu1)
				remove_task(id)
			}
			else
			{
				reset_value_zombie(id)
				give_pc(id)
				jml_smoke ++
				g_zombie_class[id] = 1
				g_ZB_class[id] = 2
				remove_task(id)
				if(zbgrnadeunlocked[id]) give_zb(id)
				engclient_cmd(id, "weapon_knife")
			}
		}
		case 3:
		{
				if(!vodounlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_vodo))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_vodo))
						vodounlocked[id] = true
						reset_value_zombie(id)
						give_venom(id)
						jml_venom ++
						g_zombie_class[id] = 5
						g_ZB_class[id] = 3
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 3)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_venom(id)
							g_zombie_class[id] = 5
							g_ZB_class[id] = 3
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 4:
		{
				if(!lightunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_light))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_light))
						lightunlocked[id] = true
						reset_value_zombie(id)
						give_speed(id)
						jml_lusty ++
						g_zombie_class[id] = 2
						g_ZB_class[id] = 4
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 4)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_speed(id)
							g_zombie_class[id] = 2
							g_ZB_class[id] = 4
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 5:
		{
				if(!deimosunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_deimos))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_deimos))
						deimosunlocked[id] = true
						reset_value_zombie(id)
						give_deimos(id)
						jml_deimos ++
						g_zombie_class[id] = 1
						g_ZB_class[id] = 5
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{		
						if(g_ZB_class[id] == 5)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_deimos(id)
							g_zombie_class[id] = 1
							g_ZB_class[id] = 5
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 6:
		{
				if(!bansheunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_banshe))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_banshe))
						bansheunlocked[id] = true
						reset_value_zombie(id)
						give_banchee(id)
						jml_banshee ++
						g_zombie_class[id] = 4
						g_ZB_class[id] = 6
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 6)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_banchee(id)
							g_zombie_class[id] = 4
							g_ZB_class[id] = 6
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 7:
		{
				if(!stamperunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_stamper))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_stamper))
						stamperunlocked[id] = true
						reset_value_zombie(id)
						give_sting(id)
						jml_sting ++
						g_zombie_class[id] = 0
						g_ZB_class[id] = 7
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 7)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_sting(id)
							g_zombie_class[id] = 0
							g_ZB_class[id] = 7
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 8:
		{
			if(!stingunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sting))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sting))
						stingunlocked[id] = true
						reset_value_zombie(id)
						give_stamper(id)
						jml_stamper ++
						g_zombie_class[id] = 3
						g_ZB_class[id] = 8
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 7)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_stamper(id)
							g_zombie_class[id] = 3
							g_ZB_class[id] = 8
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
	}
	return PLUGIN_HANDLED;
}

public m4m3ts_money(id) zp_cs_set_user_money(id, 32000)

gRandomAlive(n)
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id))
			Alive++
		
		if (Alive == n)
			return id;
	}
	
	return -1;
}

gAlive()
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id) && !zp_get_user_zombie(id))
			Alive++
	}
	
	return Alive;
}

total_player()
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id))
			Alive++
	}
	
	return Alive;
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return FM_CS_TEAM_UNASSIGNED;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	 
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		// Divine Titan is backed by TMP but belongs to the grenade slot.
		if (weaponid == CSW_TMP)
		{
			new titan = fm_find_ent_by_owner(-1, "weapon_tmp", id);
			if (pev_valid(titan) && pev(titan, pev_impulse) == 15062022) continue;
		}

		  
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
		
		if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4);
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < g_iMaxClients; i++)
		{
			if(!is_user_connected(i))
				continue
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i)
			write_byte(i)
			write_string(szMsg)
			message_end()
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
}

stock bool:PriceSelected(id,n){return (g_PriceGroup[n]==0?iWeapprim[id]:(g_PriceGroup[n]==1?iWeapsec[id]:iWeapmelee[id]))==g_PriceIndex[n];}
stock AddPricedItem(id,menu,const name[],n,key){new label[96],data[8];num_to_str(key,data,charsmax(data));if(g_PriceValue[n]==0||g_PriceUnlocked[id][n])formatex(label,charsmax(label),"\w%s",name);else formatex(label,charsmax(label),"\y%s \w[\r$%d\w]",name,g_PriceValue[n]);menu_additem(menu,label,data);}
stock bool:BuyPricedItem(id,group,index){
 for(new n=0;n<sizeof g_PriceValue;n++){
  if(g_PriceGroup[n]!=group||g_PriceIndex[n]!=index)continue;
  if(g_PriceValue[n]==0||g_PriceUnlocked[id][n])return true;
  if(zp_cs_get_user_money(id)<g_PriceValue[n]){client_print(id,print_center,"Necesitas $%d para desbloquear esta arma.",g_PriceValue[n]);return false;}
  zp_cs_set_user_money(id,zp_cs_get_user_money(id)-g_PriceValue[n]);g_PriceUnlocked[id][n]=true;PlayEmitSound(id,sound_cash);return true;
 }
 return true;
}

public Float:NativeShopJumpGravity(plugin,argc){new id=get_param(1);if(id<1||id>32||!is_user_connected(id)||zp_get_user_zombie(id)||!jumpunlocked[id])return 0.0;return get_pcvar_float(p_grav);}
