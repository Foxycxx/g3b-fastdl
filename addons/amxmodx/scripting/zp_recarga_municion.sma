native refill_drakar2(id,extra);
native refill_guitar(id,extra);
native refill_usas(id,extra);
native refill_buffak(id,extra);
native refill_buffm4(id,extra);
native exhero_titan_refill(id, extra);
native refill_dragoncannon_extra(id);
new bool:g_ExtraAmmoMap[33];
native refill_dragoncannon(id);
#include <amxmodx>
#include <cstrike>
#include <zombieplague>
#include <28_kostum>
#include <byu_money>

#include <star_taylor>
// Thunderbolt retired
#include <cannon>
// Rail Cannon retired
#include <hero>
#include <19_bb>
#include <20_sprint>

new const sound_buyammo[] = "items/9mmclip1.wav"

new refill_ammo, g_msgAmmoPickup, kostum, uang, custom, sprint, bloodyblade, cyclone, cannon, rail, jumlah_cyclone, jumlah_cannon, jumlah_rail
new kostum_aktif[33], codebox1[33], codebox2[33], codebox3[33]

new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

public plugin_init()
{
	register_plugin("Ammo Refill / SupplyBox", "1.1-GXB3", "m4m3ts / GXB3")
	
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	
	refill_ammo = zp_register_extra_item("Magazine Set", 1, ZP_TEAM_HUMAN)
	kostum = zp_register_extra_item("Free Costumes", 1, ZP_TEAM_HUMAN)
	uang = zp_register_extra_item("Nemu Duit", 1, ZP_TEAM_HUMAN)
	custom = zp_register_extra_item("Kostum Setiap Round", 1, ZP_TEAM_HUMAN)
	sprint = zp_register_extra_item("Sprint untuk 1 Round", 1, ZP_TEAM_HUMAN)
	bloodyblade = zp_register_extra_item("Bloody Blade untuk 1 Round", 1, ZP_TEAM_HUMAN)
	cyclone = zp_register_extra_item("Magazine Sets", 1, ZP_TEAM_HUMAN) // Star Taylor via SupplyBox
	cannon = zp_register_extra_item("Free Costume", 1, ZP_TEAM_HUMAN)
	rail = -1 // Rail Cannon reward retired
	jumlah_cyclone = 0
	jumlah_cannon = 0
	jumlah_rail = 0
}

public plugin_precache()
{
	precache_sound(sound_buyammo)
	precache_sound("perm1.wav")
	precache_sound("perm2.wav")
}

public plugin_natives()
{
	register_native("revo_get_kostum", "native_revo_get_kostum", 1)
	register_native("refill", "native_refill", 1)
	register_native("refill2", "native_refill2", 1)
	register_native("codebox1", "native_codebox1", 1)
	register_native("jumlah_cyclone", "native_jumlah_cyclone", 1)
	register_native("codebox2", "native_codebox2", 1)
	register_native("jumlah_cannon", "native_jumlah_cannon", 1)
	register_native("codebox3", "native_codebox3", 1)
	register_native("jumlah_rail", "native_jumlah_rail", 1)
}

public native_revo_get_kostum(id)
{
	return kostum_aktif[id];
}

public native_codebox1(id)
{
	return codebox1[id];
}

public native_jumlah_cyclone()
{
	return jumlah_cyclone;
}

public native_codebox2(id)
{
	return codebox2[id];
}

public native_jumlah_cannon()
{
	return jumlah_cannon;
}

public native_codebox3(id)
{
	return codebox3[id];
}

public native_jumlah_rail()
{
	return jumlah_rail;
}

public native_refill(id)
{
	refill(id)
}

public native_refill2(id)
{
	refill2(id)
}

public client_connect(id)
{
    g_ExtraAmmoMap[id] = false;
	kostum_aktif[id] = false
	codebox1[id] = 0
	codebox2[id] = 0
	codebox3[id] = 0
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == refill_ammo) refill(id)
	if(itemid == kostum) give_costumes(id)
	if(itemid == bloodyblade) give_bb(id)
	if(itemid == cyclone)
	{
		if(!revo_get_user_hero(id) && jumlah_cyclone <= 3)
		{
			if(!codebox1[id])
			{
				give_sfpistol(id)
				set_task(0.1, "set", id)
				client_cmd( id, "spk sound/perm2.wav")
				jumlah_cyclone ++
				engclient_cmd(id, "weapon_p228")
			}
			else refill(id)
		}
		else if(revo_get_user_hero(id) && jumlah_cyclone <= 3)
		{
			if(!codebox1[id])
			{
				set_task(0.1, "set", id)
				client_cmd( id, "spk sound/perm2.wav")
				jumlah_cyclone ++
			}
			else refill(id)
		}

		else
		{
			refill(id)
			jumlah_cyclone ++
		}
		
	}
	
	if(itemid == cannon)
	{
		if(!revo_get_user_hero(id) && jumlah_cannon <= 0)
		{
			if(!codebox2[id])
			{
				get_dragoncannon(id)
				set_task(0.1, "set2", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_cannon ++
			}
			else give_costumes(id)
		}
		else if(revo_get_user_hero(id) && jumlah_cannon <= 0)
		{
			if(!codebox2[id])
			{
				set_task(0.1, "set2", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_cannon ++
			}
			else give_costumes(id)
		}
		else
		{
			give_costumes(id)
			jumlah_cannon ++
		}
		
	}
	
	if(itemid == rail)
	{
		if(!revo_get_user_hero(id) && jumlah_rail <= 1)
		{
			if(!codebox3[id])
			{
				{} // retired
				set_task(0.1, "set3", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_rail ++
			}
			else give_costumes(id)
		}
		else if(revo_get_user_hero(id) && jumlah_rail <= 1)
		{
			if(!codebox3[id])
			{
				set_task(0.1, "set3", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_rail ++
			}
			else give_costumes(id)
		}
		else
		{
			give_costumes(id)
			jumlah_rail ++
		}
		
	}
	
	if(itemid == sprint) give_sprint(id)
	if(itemid == uang)
	{
		zp_cs_set_user_money(id, zp_cs_get_user_money(id) + 4000)
		refill(id)
	}
	if(itemid == custom)
	{
		kostum_aktif[id] = true
	}
}

public set(id) codebox1[id] = 1
public set2(id) codebox2[id] = 1
public set3(id) codebox3[id] = 1

public refill(id)
{
    if(!is_user_alive(id) || zp_get_user_zombie(id)) return;
    new weapons[32], count; get_user_weapons(id,weapons,count);
    for(new i=0;i<count;i++)
    {
        new wid=weapons[i];
        if(wid==CSW_M249 && refill_usas(id,g_ExtraAmmoMap[id]))continue;
        if(wid==CSW_M249 && refill_drakar2(id,g_ExtraAmmoMap[id]))continue;
        if(wid==CSW_GALIL && refill_guitar(id,g_ExtraAmmoMap[id]))continue;
        if(wid==CSW_AK47 && refill_buffak(id,g_ExtraAmmoMap[id]))continue;
        if(wid==CSW_M4A1 && refill_buffm4(id,g_ExtraAmmoMap[id]))continue;
        // Titan's TMP base uses its own ammo index and grenade slot.
        if(wid==CSW_TMP && exhero_titan_refill(id,g_ExtraAmmoMap[id])) continue;
        new amount=g_ExtraAmmoMap[id]?get_ammo_buywpn2(wid):get_ammo_buywpn(wid);
        if(amount<=2) continue;
        new current=cs_get_user_bpammo(id,wid);
        if(current<amount) {cs_set_user_bpammo(id,wid,amount);show_hud_ammo(id,wid);}
    }

    if(g_ExtraAmmoMap[id]) refill_dragoncannon_extra(id);
    else refill_dragoncannon(id);
}
public refill2(id)
{
    if(!is_user_connected(id)) return;
    g_ExtraAmmoMap[id]=true;
    refill(id);
}

get_ammo_buywpn(wpn)
{
	new ammo = 1
	if (wpn == CSW_USP || wpn == CSW_GLOCK18)
	{
		ammo = 200
	}
	else if (wpn == CSW_FIVESEVEN)
	{
		ammo = 5
	}
	else if (wpn == CSW_P228)
	{
		ammo = 60
	}
	else if (wpn == CSW_ELITE)
	{
		ammo = 200
	}
	else if (wpn == CSW_DEAGLE)
	{
		ammo = 200
	}
	else if (wpn == CSW_M3 || wpn == CSW_XM1014)
	{
		ammo = 64
	}
	else if (wpn == CSW_MAC10 || wpn == CSW_MP5NAVY || wpn == CSW_TMP)
	{
		ammo = 200
	}
	else if (wpn == CSW_UMP45)
	{
		ammo = 20
	}
	else if (wpn == CSW_P90)
	{
		ammo = 200
	}
	else if (wpn == CSW_AUG || wpn == CSW_FAMAS || wpn == CSW_GALIL || wpn == CSW_M4A1 || wpn == CSW_SG552 || wpn == CSW_AK47 || wpn == CSW_SCOUT || wpn == CSW_SG550)
	{
		ammo = 200
	}
	else if (wpn == CSW_G3SG1)
	{
		ammo = 240
	}
	else if (wpn == CSW_GALIL)
	{
		ammo = 200
	}
	else if (wpn == CSW_M249)
	{
		ammo = 200
	}
	else if (wpn == CSW_AWP)
	{
		ammo = 25
	}
	else if (wpn == CSW_HEGRENADE || wpn == CSW_SMOKEGRENADE || wpn == CSW_FLASHBANG)
	{
		ammo = 1
	}
	return ammo;
}

get_ammo_buywpn2(wpn)
{
	new ammo = 1
	if (wpn == CSW_USP || wpn == CSW_GLOCK18)
	{
		ammo = 300
	}
	else if (wpn == CSW_FIVESEVEN)
	{
		ammo = 5
	}
	else if (wpn == CSW_P228)
	{
		ammo = 250
	}
	else if (wpn == CSW_ELITE)
	{
		ammo = 300
	}
	else if (wpn == CSW_DEAGLE)
	{
		ammo = 250
	}
	else if (wpn == CSW_XM1014)
	{
		ammo = 80
	}
	else if (wpn == CSW_M3)
	{
		ammo = 120
	}
	else if (wpn == CSW_MAC10 || wpn == CSW_MP5NAVY || wpn == CSW_TMP)
	{
		ammo = 300
	}
	else if (wpn == CSW_UMP45)
	{
		ammo = 25
	}
	else if (wpn == CSW_P90)
	{
		ammo = 250
	}
	else if (wpn == CSW_AUG || wpn == CSW_FAMAS || wpn == CSW_GALIL || wpn == CSW_M4A1 || wpn == CSW_SG552 || wpn == CSW_AK47 || wpn == CSW_SCOUT || wpn == CSW_SG550)
	{
		ammo = 300
	}
	else if (wpn == CSW_G3SG1)
	{
		ammo = 250
	}
	else if (wpn == CSW_M249)
	{
		ammo = 250
	}
	else if (wpn == CSW_AWP)
	{
		ammo = 35
	}

	return ammo;
}

show_hud_ammo(id, weapon)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
	write_byte(AMMOID[weapon]) // ammo id
	write_byte(15) // ammo amount
	message_end()
	
	PlayEmitSound(id, CHAN_ITEM, sound_buyammo)
}

PlayEmitSound(id, type, const sound[])
{
	emit_sound(id, type, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
