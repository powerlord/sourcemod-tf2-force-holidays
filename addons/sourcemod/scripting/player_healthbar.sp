/**
 * vim: set ts=4 :
 * =============================================================================
 * Player Health Bar
 * Give a Player the Monoculus health bar.
 *
 * Player Health Bar (C)2012-2015 Powerlord (Ross Bemrose).
 * All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#pragma semicolon 1

#define VERSION "1.0.0"

#define RESOURCE 				"monster_resource"
#define RESOURCE_PROP			"m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX			255.0
#define HEALTH_MAP				"m_iHealth"
#define MAXHEALTH_MAP			"m_iMaxHealth"

public Plugin:myinfo = 
{
	name = "Player Health Bar",
	author = "Powerlord",
	description = "Give a player the Monoculus/Merasmus health bar",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=274834"
}

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new g_HealthBar = -1;

new g_PlayerUserId = -1;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "Plugin only works on Team Fortress 2.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("player_healthbar_version", VERSION, "Player Healthbar Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_Enabled = CreateConVar("player_healthbar_enabled", "1", "Enable Player Healthbar?", _, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_UpdateHealth);
	HookEvent("post_inventory_application", Event_UpdateHealth);
	HookEvent("player_healed", Event_UpdateHealth);
	
	RegAdminCmd("healthbar", Cmd_Healthbar, ADMFLAG_GENERIC, "Set a healthbar for a player");
}

public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarBool(convar))
	{
		g_PlayerUserId = -1;
		SetHealthBar(0.0);
	}
}

public Event_UpdateHealth(Handle event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new userid;
	if (StrEqual(name, "player_healed"))
	{
		userid = GetEventInt(event, "patient");
	}
	else
	{
		userid = GetEventInt(event, "userid");
	}
	
	if (userid == g_PlayerUserId)
	{
		UpdatePlayerHealth();
	}
}

public Event_PlayerDeath(Handle event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	
	if (userid == g_PlayerUserId)
	{
		// Always set to 0 in case this is a dead ringer
		SetHealthBar(0.0);
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (condition == TFCond_DeadRingered && GetClientUserId(client) == g_PlayerUserId)
	{
		UpdatePlayerHealth();
	}
}

public OnClientDisconnect(client)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new userid = GetClientUserId(client);
	
	if (userid == g_PlayerUserId)
	{
		SetHealthBar(0.0);
		SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, PlayerDamaged);
		g_PlayerUserId = -1;
	}
}

public Action:Cmd_Healthbar(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: healthbar <target>");
		return Plugin_Handled;
	}
	
	new String:targetString[MAX_NAME_LENGTH];
	GetCmdArg(1, targetString, sizeof(targetString));
	
	new target = FindTarget(client, targetString, false, false);
	
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	new oldPlayer;
	if (g_PlayerUserId != -1 && (oldPlayer = GetClientOfUserId(g_PlayerUserId)) != 0)
	{
		SDKUnhook(oldPlayer, SDKHook_OnTakeDamageAlivePost, PlayerDamaged);
	}
	
	g_PlayerUserId = GetClientUserId(target);
	SDKHook(target, SDKHook_OnTakeDamageAlivePost, PlayerDamaged);
	UpdatePlayerHealth();
	
	ReplyToCommand(client, "Gave healthbar to \"%N\"", target);
	
	return Plugin_Handled;
	
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, RESOURCE))
	{
		g_HealthBar = EntIndexToEntRef(entity);
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == EntRefToEntIndex(g_HealthBar))
	{
		g_HealthBar = INVALID_ENT_REFERENCE;
	}
}

public PlayerDamaged(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damagecustom)
{
	if (!GetConVarBool(g_Cvar_Enabled) || victim < 0 || !IsValidEntity(victim))
	{
		return;
	}
	
	UpdatePlayerHealth();
}

UpdatePlayerHealth()
{
	if (!GetConVarBool(g_Cvar_Enabled) || g_PlayerUserId == -1)
	{
		return;
	}
	
	new player = GetClientOfUserId(g_PlayerUserId);
	if (player == 0)
	{
		g_PlayerUserId = -1;
		return;
	}
	
	new entity = GetPlayerResourceEntity();
	
	new health = GetEntProp(entity, Prop_Send, HEALTH_MAP, _, player);
	new maxHealth = GetEntProp(entity, Prop_Send, MAXHEALTH_MAP, _, player);
	
	new Float:newPercent = float(health) / float(maxHealth) * 100.0;
	SetHealthBar(newPercent);
}

SetHealthBar(Float:percent)
{
	new healthBar = EntRefToEntIndex(g_HealthBar);
	if (healthBar == INVALID_ENT_REFERENCE || !IsValidEntity(healthBar))
	{
		return;
	}
	// In practice, the multiplier is 2.55
	new Float:value = percent * (HEALTHBAR_MAX / 100.0);

	SetEntProp(healthBar, Prop_Send, RESOURCE_PROP, RoundToNearest(value));
}
