#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "Emotion"
#define VERSION "2.5"
#define AUTHOR "m4m3ts"

#define MAX_EMOTION 6
#define BUTTON_HOLDTIME 0.5
#define USE_TYPE 3

#define TASK_EMOTION 1962
#define TASK_HOLDTIME 1963

new const v_model_man[] = "models/g3bmodel/ZTHEX/m4m3ts/v_emotion_man_m4m3ts.mdl"
new const v_model_girl[] = "models/g3bmodel/ZTHEX/m4m3ts/v_emotion_girl_m4m3ts.mdl"

new const g_ModelNames[][] = {
								"Raven",
								"Henry",
								"Carlito",
								"Gerrard",
								"Alice [Metal Arena]",
								"Yuri [Soccer]",
								"Michaela"
								}

new Float:Emotion_Time_Man[8] = 
{
	4.6,
	7.0,
	4.4,
	3.7,
	8.3,
	8.3,
	4.3,
	10.7
}

new Float:Emotion_Time_Girl[8] = 
{
	5.3,
	5.7,
	5.7,
	7.2,
	6.7,
	2.8,
	3.9,
	7.0
}

new g_InDoingEmo[33], g_OldWeapon[33], character[33]
new g_MaxPlayers, g_HoldingButton[33], g_UseType, Float:Vector, special[33], seq_number[33], hero[33]
new g_msgCurWeapon

const GRENADE_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("DeathMsg", "Event_DeathMsg", "a")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
		
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	
	g_UseType = USE_TYPE
	if(g_UseType == 1) register_clcmd("cheer", "Open_EmoMenu")
	if(g_UseType == 3) register_impulse(201, "Open_EmoMenu")
	
	g_MaxPlayers = get_maxplayers()
	g_msgCurWeapon = get_user_msgid("CurWeapon")
}

public plugin_precache()
{
    precache_generic("sound/weapons/man_angry.wav");
    precache_generic("sound/weapons/man_boxxing.wav");
    precache_generic("sound/weapons/man_dance.wav");
    precache_generic("sound/weapons/man_hi.wav");
    precache_generic("sound/weapons/man_joy.wav");
    precache_generic("sound/weapons/man_procoke.wav");
    precache_generic("sound/weapons/man_provoke2.wav");
    precache_generic("sound/weapons/man_special.wav");
    precache_generic("sound/weapons/woman_angry.wav");
    precache_generic("sound/weapons/woman_dance.wav");
    precache_generic("sound/weapons/woman_giveup.wav");
    precache_generic("sound/weapons/woman_hi.wav");
    precache_generic("sound/weapons/woman_joy.wav");
    precache_generic("sound/weapons/woman_procoke.wav");
    precache_generic("sound/weapons/woman_provoke2.wav");
    precache_generic("sound/weapons/woman_special.wav");

	engfunc(EngFunc_PrecacheModel, v_model_man)
	engfunc(EngFunc_PrecacheModel, v_model_girl)
}

public plugin_natives()
{
	register_native("Doing_Emo", "native_Doing_Emo", 1)
}

public native_Doing_Emo(id)
{
	return g_InDoingEmo[id];
}

public Event_NewRound()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		Reset_Var(i)
	}
}

public Event_DeathMsg()
{
	static Victim; Victim = read_data(2)
	if(g_InDoingEmo[Victim]) Do_Reset_Emotion(Victim)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	if(g_InDoingEmo[id] && get_user_weapon(id) != CSW_KNIFE) Do_Reset_Emotion(id)
}

public fw_PlayerSpawn_Post(id)
{
	if(g_UseType == 1)
		client_printc(id, "!g[Emociones]!n Presiona !g[T]!n para usar las !tEmociones!n")
	else if(g_UseType == 2)
		client_printc(id, "!g[Emociones]!n Manten presionada !g[T]!n para usar las !tEmociones!n")
	else if(g_UseType == 3)
		client_printc(id, "!g[Emociones]!n Presiona !g[T]!n para usar las !tEmociones!n")
}

public Reset_Var(id)
{
	if(!is_user_connected(id))
		return
		
	if(task_exists(id+TASK_EMOTION)) remove_task(id+TASK_EMOTION)	
				
	g_InDoingEmo[id] = 0
	g_HoldingButton[id] = 0
}

public Open_EmoMenu2(id)
{
	id -= TASK_HOLDTIME
	Open_EmoMenu(id)
}

public Open_EmoMenu(id)
{
	if(!is_user_alive(id))
		return
	if(g_InDoingEmo[id])
		return
	if(zp_get_user_zombie(id))
		return
	
	hero[id] = 0
	
	get_model_special(id)
	get_model_name(id)
	
	new title[64];
	if(hero[id]) formatex(title, 63, "\yPersonaje: Heroe")
	else formatex(title, 63, "\yPersonaje: %s", g_ModelNames[character[id]])
	new menu = menu_create(title, "MenuHandle_Emo")  
	if(special[id])
	{
		menu_additem( menu, "Saludo", "1" )
		menu_additem( menu, "Provocar", "2" )
		menu_additem( menu, "Feliz", "3")
		menu_additem( menu, "Enojado", "4")
		menu_additem( menu, "Baile", "5" )
		if(character[id] <= 3) menu_additem( menu, "Fisicoculturista", "6" )
		else menu_additem( menu, "Beso", "6" )
		menu_additem( menu, "Provocacion especial", "7" )
		if(character[id] <= 3) menu_additem( menu, "Boxeo^n", "8" )
		else menu_additem( menu, "Rendirse^n", "8" )
	}
	else
	{
		menu_additem( menu, "Saludo", "1" )
		menu_additem( menu, "Provocar", "2" )
		menu_additem( menu, "Feliz", "3")
		menu_additem( menu, "Enojado", "4")
		menu_additem( menu, "Baile", "5" )
		menu_additem( menu, "Fisicoculturista^n", "6" )
	}
	
	menu_additem( menu, "Salir", "MENU_EXIT" )
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return 
}

public MenuHandle_Emo(id, menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return
	}
	
	if(!is_user_alive(id))
		return
	if(g_InDoingEmo[id])
		return
	
	if(special[id])
	{
			switch(item) {
			case 0:{
				Do_Set_Emotion(id, 1)
			}
			case 1:{
				Do_Set_Emotion(id, 2)
			}
			case 2:{
				Do_Set_Emotion(id, 3)
			}
			case 3:{
				Do_Set_Emotion(id, 4)
			}
			case 4:{
				Do_Set_Emotion(id, 5)
			}
			case 5:{
				Do_Set_Emotion(id, 6)
			}
			case 6:{
				Do_Set_Emotion(id, 7)
			}
			case 7:{
				Do_Set_Emotion(id, 8)
			}
		}
	}
	else
	{
			switch(item) {
			case 0:{
				Do_Set_Emotion(id, 1)
			}
			case 1:{
				Do_Set_Emotion(id, 2)
			}
			case 2:{
				Do_Set_Emotion(id, 3)
			}
			case 3:{
				Do_Set_Emotion(id, 4)
			}
			case 4:{
				Do_Set_Emotion(id, 5)
				if(character[id] == 2) set_pev(id, pev_framerate, 1.2)
			}
			case 5:{
				Do_Set_Emotion(id, 6)
				if(character[id] == 2) set_pev(id, pev_framerate, 1.2)
			}
		}
	}

	return
}



public Do_Set_Emotion(id, EmoId)
{
	// Set Hand Emotion
	g_InDoingEmo[id] = 1
	g_OldWeapon[id] = get_user_weapon(id)
	seq_number[id] = entity_get_int(id,EV_INT_sequence)
	
	static newemoid
	newemoid = EmoId - 1
	
	engclient_cmd(id, "weapon_knife")
	Set_Entity_Anim(id, newemoid)
	set_pev(id, pev_weaponmodel, "")
	if(character[id] <= 3) set_pev(id, pev_viewmodel2, v_model_man)
	else set_pev(id, pev_viewmodel2, v_model_girl)
	
	if(character[id] >= 4 && EmoId == 1) Set_Weapon_Anim(id, random_num(8,9))
	else Set_Weapon_Anim(id, newemoid)
	
	if(character[id] <= 3)
	{
		static KnifeEnt; KnifeEnt = fm_get_user_weapon_entity(id, CSW_KNIFE)
		if(pev_valid(KnifeEnt)) set_pdata_float(KnifeEnt, 48, Emotion_Time_Man[newemoid], 4)
		
		if(task_exists(id+TASK_EMOTION)) remove_task(id+TASK_EMOTION)
		set_task(Emotion_Time_Man[newemoid], "Reset_Emotion", id+TASK_EMOTION)
	}
	else
	{
		static KnifeEnt; KnifeEnt = fm_get_user_weapon_entity(id, CSW_KNIFE)
		if(pev_valid(KnifeEnt)) set_pdata_float(KnifeEnt, 48, Emotion_Time_Girl[newemoid], 4)
		
		if(task_exists(id+TASK_EMOTION)) remove_task(id+TASK_EMOTION)
		set_task(Emotion_Time_Girl[newemoid], "Reset_Emotion", id+TASK_EMOTION)
	}
}

public Reset_Emotion(id)
{
	id -= TASK_EMOTION
	
	if(!is_user_connected(id))
		return
	if(!g_InDoingEmo[id])
		return
		
	Do_Reset_Emotion(id)
}

public Do_Reset_Emotion(id)
{
	if(!is_user_connected(id))
		return
	if(!g_InDoingEmo[id])
		return
		
	if(task_exists(id+TASK_EMOTION)) remove_task(id+TASK_EMOTION)
	g_InDoingEmo[id] = 0
	if(is_user_alive(id))
	{
		if(g_OldWeapon[id] == CSW_KNIFE)
		{
			reset_user_knife(id)
		}
		else if(g_OldWeapon[id] == CSW_P228 || g_OldWeapon[id] == CSW_ELITE || g_OldWeapon[id] == CSW_FIVESEVEN || g_OldWeapon[id] == CSW_USP || g_OldWeapon[id] == CSW_GLOCK18 || g_OldWeapon[id] == CSW_DEAGLE)
		{
			draw_weapons(id, 2)
		}
		else if(g_OldWeapon[id] == CSW_HEGRENADE || g_OldWeapon[id] == CSW_SMOKEGRENADE || g_OldWeapon[id] == CSW_FLASHBANG)
		{
			draw_weapons(id, 3)
		}
		else
		{
			draw_weapons(id, 1)
		}
	}
	
	anims_2(id, seq_number[id])
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return

	
	if(!g_InDoingEmo[id] && g_UseType == 2)
	{
		static UseButton, UseOldButton
		UseButton = (get_uc(uc_handle, UC_Buttons) & IN_RELOAD)
		UseOldButton = (pev(id, pev_oldbuttons) & IN_RELOAD)
		
		if(UseButton)
		{
			if(!UseOldButton && !g_InDoingEmo[id])
			{
				g_HoldingButton[id] = 1
				set_task(BUTTON_HOLDTIME, "Open_EmoMenu2", id+TASK_HOLDTIME)
			}
		} else {
			if(UseOldButton && g_HoldingButton[id])
			{
				if(task_exists(id+TASK_HOLDTIME)) 
				{
					remove_task(id+TASK_HOLDTIME)
					g_HoldingButton[id] = 0
				}
			}
		}
	}
		
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	
	if((CurButton & IN_ATTACK) || (CurButton & IN_ATTACK2) || (CurButton & IN_JUMP))
	{
		Do_Reset_Emotion(id)
		return
	}
	
	static Float:Velocity[3]
	pev(id, pev_velocity, Velocity); Vector = vector_length(Velocity)
	
	if(Vector != 0.0)
	{
		Do_Reset_Emotion(id)
		return
	}
}

public reset_user_knife(id)
{
	// Latest version support
	ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(FM_NULLENT, "weapon_knife", id)) // v4.3 Support
	
	// Updating Model
	engclient_cmd(id, "weapon_knife")
	emessage_begin(MSG_ONE, g_msgCurWeapon, _, id)
	ewrite_byte(1) // active
	ewrite_byte(CSW_KNIFE) // weapon
	ewrite_byte(0) // clip
	emessage_end()
}

stock Set_Entity_Anim(id, Anim)
{
	if(!pev_valid(id))
		return
		
	switch(Anim)
	{
		case 0:	anims(id, "emotion01")
		case 1: anims(id, "emotion04")
		case 2: anims(id, "emotion02")
		case 3: anims(id, "emotion03")
		case 4: anims(id, "emotion05")
		case 5: anims(id, "emotion06")
		case 6: anims(id, "emotion07")
		case 7: anims(id, "emotion08")
	}	
}

stock anims(const iPlayer, const szAnims[])
{
   #define ACT_RANGE_ATTACK1   28
   
   // Linux extra offsets
   #define extra_offset_player   5
   #define extra_offset_animating   4
   
   // CBaseAnimating
   #define m_flFrameRate      36
   #define m_flGroundSpeed      37
   #define m_flLastEventCheck   38
   #define m_fSequenceFinished   39
   #define m_fSequenceLoops   40
   
   // CBaseMonster
   #define m_Activity      73
   #define m_IdealActivity      74
   
   // CBasePlayer
   #define m_flLastAttackTime   220
   
   new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
      
   if ((iAnimDesired = lookup_sequence(iPlayer, szAnims, flFrameRate, bLoops, flGroundSpeed)) == -1)
   {
      iAnimDesired = 0;
   }
   
   new Float: flGametime = get_gametime();

   set_pev(iPlayer, pev_frame, 0.0);
   set_pev(iPlayer, pev_framerate, 1.0);
   set_pev(iPlayer, pev_animtime, flGametime );
   set_pev(iPlayer, pev_sequence, iAnimDesired);
   
   set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
   set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
   
   set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
   set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
   set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
   
   set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
   set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
   set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}

stock anims_2(const iPlayer, const szAnims[])
{
  #define ACT_RANGE_ATTACK1   28
   
   // Linux extra offsets
   #define extra_offset_player   5
   #define extra_offset_animating   4
   
   // CBaseAnimating
   #define m_flFrameRate      36
   #define m_flGroundSpeed      37
   #define m_flLastEventCheck   38
   #define m_fSequenceFinished   39
   #define m_fSequenceLoops   40
   
   // CBaseMonster
   #define m_Activity      73
   #define m_IdealActivity      74
   
   // CBasePlayer
   #define m_flLastAttackTime   220
   
   new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
      
   if ((iAnimDesired = lookup_sequence(iPlayer, szAnims, flFrameRate, bLoops, flGroundSpeed)) == -1)
   {
      iAnimDesired = 0;
   }
   
   new Float: flGametime = get_gametime();

   set_pev(iPlayer, pev_frame, 0.0);
   set_pev(iPlayer, pev_framerate, 1.0);
   set_pev(iPlayer, pev_animtime, flGametime );
   set_pev(iPlayer, pev_sequence, szAnims);
   
   set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
   set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
   
   set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
   set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
   set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
   
   set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
   set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
   set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}  

stock Set_Weapon_Anim(id, Anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, Anim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(Anim)
	write_byte(pev(id, pev_body))
	message_end()
	
	
}

public get_model_special(id)
{
	static currentmodel[32]
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
	if(equal(currentmodel, "komplit_mercenarytr") || equal(currentmodel, "komplit_gerrard") || equal(currentmodel, "komplit_henry") || equal(currentmodel, "komplit_hero")) special[id] = 0
	else special[id] = 1
}

public get_model_name(id)
{
	static currentmodel[32]
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
	if(equal(currentmodel, "komplit_pirategirl")) character[id] = 6
	if(equal(currentmodel, "komplit_pirateboy")) character[id] = 0
	if(equal(currentmodel, "komplit_henry")) character[id] = 1
	if(equal(currentmodel, "komplit_mercenarytr")) character[id] = 2
	if(equal(currentmodel, "komplit_gerrard")) character[id] = 3
	if(equal(currentmodel, "komplit_maalice")) character[id] = 4
	if(equal(currentmodel, "komplit_scyuri")) character[id] = 5
	if(equal(currentmodel, "komplit_hero"))
	{
		hero[id] = 1
		character[id] = 1
	}
}

stock fm_cs_get_user_model(id, model[], len)
{
	get_user_info(id, "model", model, len)
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
		for(new i = 0; i < g_MaxPlayers; i++)
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

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(zp_get_user_zombie(id))
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{	
			return FMRES_SUPERCEDE
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if(sample[17] == 'w')
			{
				return FMRES_SUPERCEDE
			} else {
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			return FMRES_SUPERCEDE;
		}
		if (sample[14] == 'd' && sample[15] == 'e' && sample[16] == 'p') // stab
		{
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED
}

stock draw_weapons(id, drawwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
     
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
          
		if (drawwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, wname)
		}
		
		if (drawwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, wname)
		}
		
		if (drawwhat == 3 && ((1<<weaponid) & GRENADE_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, wname)
		}
	}
}
