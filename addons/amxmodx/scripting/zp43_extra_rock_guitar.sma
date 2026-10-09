#include <amxmodx>
#include <reapi>
#include <exhero_model_sounds>
new gGuitarShot[33];
#include < amxmodx >
#include < fun >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >

#define WEAPON_BITSUM ((1<<CSW_GALIL))

new const VERSION[] = "1.1";

#define ITEM_NAME "Lightning AR-1"
#define ITEM_COST 35

new const V_GUITAR_MDL[64] = "models/g3bmodel/ZTHEX/v_guitar.mdl";
new const P_GUITAR_MDL[64] = "models/p_guitar.mdl";
new const W_GUITAR_MDL[64] = "models/w_guitar.mdl";
new const OLD_W_MDL[64] = "models/w_galil.mdl";

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const GUITAR_SOUNDS[][] = {"weapons/gt_clipin.wav", "weapons/gt_clipon.wav", "weapons/gt_clipout.wav", "weapons/gt_draw.wav"}

new const ZOOM_SOUND[] = "weapons/zoom.wav";
new const SHOT_SOUND[] = "weapons/gt.wav";

new g_itemid , g_has_guitar[33] , g_hamczbots , g_clip_ammo[33] , g_has_zoom[33] , blood_spr[2] , cvar_rockguitar_damage_x , cvar_rockguitar_clip , cvar_rockguitar_bpammo , cvar_rockguitar_shotspd , cvar_rockguitar_oneround , cvar_botquota;

public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP] Extra Item: Rock Guitar", VERSION, "CrazY");

	// Extra Item Register
	// Purchased through the loadout menu.

	// Cvars Register
	cvar_rockguitar_damage_x = register_cvar("zp_rockguitar_damage_x", "1.25");
	cvar_rockguitar_clip = register_cvar("zp_rockguitar_clip", "40");
	cvar_rockguitar_bpammo = register_cvar("zp_rockguitar_bpammo", "200");
	cvar_rockguitar_shotspd = register_cvar("zp_rockguitar_shot_speed", "0.11");
	cvar_rockguitar_oneround = register_cvar("zp_rockguitar_oneround", "0");

	// Cvar Pointer
	cvar_botquota = get_cvar_pointer("bot_quota");

	// Events
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1");
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0");

	// Forwards
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");

	// Hams
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_TraceAttack,"player","GuitarTrace",0,true);
    RegisterHam(Ham_Item_Deploy,"weapon_galil","GuitarDeploy",1);
    RegisterHam(Ham_Item_Holster,"weapon_galil","GuitarHolster",1);
}

public plugin_precache()
{
    precache_generic("sound/weapons/gt_clipin.wav");
    precache_generic("sound/weapons/gt_clipon.wav");
    precache_generic("sound/weapons/gt_clipout.wav");
    precache_generic("sound/weapons/gt_draw.wav");

	// Models
	precache_model(V_GUITAR_MDL);

    precache_generic("sprites/weapon_guitar.txt");
    precache_model("sprites/640hud38.spr");
    precache_model("sprites/640hud7.spr");
	precache_model(P_GUITAR_MDL);
	precache_model(W_GUITAR_MDL);
	precache_model(OLD_W_MDL);

	// Blood Sprites
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");

	// Sounds
	for(new i = 0; i < sizeof GUITAR_SOUNDS; i++) precache_sound(GUITAR_SOUNDS[i]);
	precache_sound(ZOOM_SOUND);
	precache_sound(SHOT_SOUND);
}

public client_putinserver(id)
{
	g_has_guitar[id] = false;

	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id);
	}
}

public client_disconnect(id)
{
	g_has_guitar[id] = false;
}

public client_connect(id)
{
	g_has_guitar[id] = false;
}

public zp_user_humanized_post(id, human)
{
	if(get_pcvar_num(cvar_rockguitar_oneround))
		g_has_guitar[id] = false;
}

public zp_user_infected_post(id)
{
	g_has_guitar[id] = false;
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_bot(id) || !get_pcvar_num(cvar_botquota))
		return;

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");

	g_hamczbots = true;
}

public zp_extra_item_selected(player,itemid) {return;}

public event_CurWeapon(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id)) return PLUGIN_HANDLED;
	
	if (read_data(2) == CSW_GALIL && GuitarOwned(get_member(id,m_pActiveItem),id))
	{
		set_pev(id, pev_viewmodel2, V_GUITAR_MDL);
		set_pev(id, pev_weaponmodel2, P_GUITAR_MDL);
	}
	return PLUGIN_CONTINUE;
}

public event_RoundStart()
{
	if(get_pcvar_num(cvar_rockguitar_oneround))
	{
		for (new i = 1; i <= get_maxplayers(); i++)
			g_has_guitar[i] = false;
	}
}

public event_DeathMsg()
{
	g_has_guitar[read_data(2)] = false;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, OLD_W_MDL)) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_galil", entity);
	
	if(owner>=1 && owner<=32 && pev_valid(wpn)==2 && pev(wpn,pev_impulse)==43555)
	{
		g_has_guitar[owner] = false;
		set_pev(wpn, pev_impulse, 43555);
		engfunc(EngFunc_SetModel, entity, W_GUITAR_MDL);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_GALIL && GuitarOwned(get_member(id,m_pActiveItem),id))
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) &&  get_user_weapon(id) == CSW_GALIL && GuitarOwned(get_member(id,m_pActiveItem),id))
	{
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if(!g_has_zoom[id])
			{
				g_has_zoom[id] = true;
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
				emit_sound(id, CHAN_ITEM, ZOOM_SOUND, 0.20, 2.40, 0, 100);
			}
			else
			{
				g_has_zoom[id] = false;
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
			}
		}

		if (g_has_zoom[id] && (pev(id, pev_button) & IN_RELOAD))
		{
			g_has_zoom[id] = false;
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
		}
	}
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if(GuitarOwned(weapon_entity,id))
	{
		static iClipExtra; iClipExtra = get_pcvar_num(cvar_rockguitar_clip);

		new Float:flNextAttack = get_pdata_float(id, 83, 5);

		new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL);
		new iClip = get_pdata_int(weapon_entity, 51, 4);

		new fInReload = get_pdata_int(weapon_entity, 54, 4);

		if(fInReload && flNextAttack <= 0.0)
		{
			new Clp = min(iClipExtra - iClip, iBpAmmo);
			set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
			cs_set_user_bpammo(id, CSW_GALIL, iBpAmmo-Clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
	    }
    }
}

public fw_AddToPlayer(weapon_entity, id)
{
    if(id<1||id>32)return HAM_IGNORED;
    g_has_guitar[id]=(pev_valid(weapon_entity)==2 && pev(weapon_entity,pev_impulse)==43555);
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43555)
	{
		g_has_guitar[id] = true;
		// Keep custom identity.
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	
	if(GuitarOwned(weapon_entity,id))
	{
		g_clip_ammo[id] = cs_get_weapon_ammo(weapon_entity);gGuitarShot[id]=weapon_entity;
	}
}

public fw_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);

	if (GuitarOwned(weapon_entity,id) && g_clip_ammo[id] > cs_get_weapon_ammo(weapon_entity))
	{
		set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_rockguitar_shotspd), 4);
		emit_sound(id, CHAN_WEAPON, SHOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_PlayWeaponAnimation(id, random_num(3, 5));
		// Engine already sends bullet impact/blood once.
	}

    if(id>=1&&id<=32)gGuitarShot[id]=0;
}

public UnusedDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GALIL && g_has_guitar[attacker])
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_rockguitar_damage_x));
	}
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(0);
	message_end();
}

stock UTIL_MakeBloodAndBulletHoles(id)
{
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	if(target > 0 && target <= get_maxplayers() && zp_get_user_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3];
		pev(id, pev_origin, fStart);
		
		velocity_by_aim(id, 64, fVel);
		
		fStart[0] = float(aimOrigin[0]);
		fStart[1] = float(aimOrigin[1]);
		fStart[2] = float(aimOrigin[2]);
		fEnd[0] = fStart[0]+fVel[0];
		fEnd[1] = fStart[1]+fVel[1];
		fEnd[2] = fStart[2]+fVel[2];
		
		new res;
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res);
		get_tr2(res, TR_vecEndPos, fRes);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BLOODSPRITE);
		write_coord(floatround(fStart[0]));
		write_coord(floatround(fStart[1]));
		write_coord(floatround(fStart[2]));
		write_short(blood_spr[1]);
		write_short(blood_spr[0]);
		write_byte(70);
		write_byte(random_num(1,2));
		message_end();
		
		
	} 
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_DECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)]);
			write_short(target);
			message_end();
		} 
		else 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_WORLDDECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)]);
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2]);
		write_short(id);
		write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1 )]);
		message_end();
	}
}

stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}

stock GuitarPrintColor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1; vformat(msg,190,input,3);
	replace_all(msg,190,"!g","^4");    // green
	replace_all(msg,190,"!y","^1");    // normal
	replace_all(msg,190,"!t","^3");    // team
        
	if (id) players[0] = id; else get_players(players,count,"ch");
        
	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}
stock bool:GuitarOwned(ent,id){return id>=1&&id<=32&&is_user_alive(id)&&!zp_get_user_zombie(id)&&pev_valid(ent)==2&&pev(ent,pev_impulse)==43555&&get_member(id,m_pActiveItem)==ent;}
public plugin_natives(){register_native("give_weapon_guitar","GuitarGrant");register_native("refill_guitar","GuitarRefill");}
public GuitarGrant(plugin,argc){new id=get_param(1);if(!is_user_alive(id)||zp_get_user_zombie(id))return 0;rg_drop_items_by_slot(id,PRIMARY_WEAPON_SLOT);new w=rg_give_custom_item(id,"weapon_galil",GT_APPEND,43555);if(is_nullent(w))return 0;g_has_guitar[id]=true;cs_set_weapon_ammo(w,40);cs_set_user_bpammo(id,CSW_GALIL,200);rg_switch_weapon(id,w);ExecuteHamB(Ham_Item_Deploy,w);return w;}
public GuitarRefill(plugin,argc){new id=get_param(1);if(!is_user_alive(id)||zp_get_user_zombie(id))return 0;new w=rg_find_weapon_bpack_by_name(id,"weapon_galil");if(is_nullent(w)||pev(w,pev_impulse)!=43555)return 0;cs_set_user_bpammo(id,CSW_GALIL,max(cs_get_user_bpammo(id,CSW_GALIL),get_param(2)?250:200));return 1;}
public GuitarDeploy(w){new id=get_pdata_cbase(w,41,4);if(!GuitarOwned(w,id))return;set_pev(id,pev_viewmodel2,V_GUITAR_MDL);set_pev(id,pev_weaponmodel2,P_GUITAR_MDL);UTIL_PlayWeaponAnimation(id,2);}
public GuitarHolster(w){new id=get_pdata_cbase(w,41,4);if(!is_user_connected(id)||pev(w,pev_impulse)!=43555)return;g_has_zoom[id]=false;gGuitarShot[id]=0;cs_set_user_zoom(id,CS_RESET_ZOOM,0);}
public GuitarTrace(victim,attacker,Float:damage,Float:direction[3],trace,bits){if(attacker<1||attacker>32||!GuitarOwned(gGuitarShot[attacker],attacker)||!zp_get_user_zombie(victim))return HAM_IGNORED;SetHamParamFloat(3,damage*get_pcvar_float(cvar_rockguitar_damage_x));return HAM_HANDLED;}
