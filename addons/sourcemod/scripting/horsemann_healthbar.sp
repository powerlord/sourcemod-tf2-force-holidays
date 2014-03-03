#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Require TF2 module to make it fail when loading any non-TF2 (or TF2 Beta) game
#include <tf2>

#pragma semicolon 1

#define VERSION "1.4"

#define RESOURCE 				"monster_resource"
#define RESOURCE_PROP			"m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX			255.0
#define HORSEMANN 				"headless_hatman"
#define HEALTH_MAP				"m_iHealth"
#define MAXHEALTH_MAP			"m_iMaxHealth"

public Plugin:myinfo = 
{
	name = "Horsemann Health Bar",
	author = "Powerlord",
	description = "Give the Horseless Headless Horsemann the Monoculus health bar",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188543"
}

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new g_HealthBar = -1;

public OnPluginStart()
{
	CreateConVar("horsemann_healthbar_version", VERSION, "Horsemann Healthbar Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_PLUGIN);
	g_Cvar_Enabled = CreateConVar("horsemann_healthbar_enabled", "1", "Enabled Horsemann Healthbar?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
}

public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarBool(convar))
	{
		SetHealthBar(0.0);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, RESOURCE))
	{
		g_HealthBar = EntIndexToEntRef(entity);
	}
	else
	if (StrEqual(classname, HORSEMANN))
	{
		SDKHook(entity, SDKHook_SpawnPost, HorsemannSpawned);
		SDKHook(entity, SDKHook_OnTakeDamagePost, HorsemannDamaged);
	}
}

public OnEntityDestroyed(entity)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new String:classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrEqual(classname, HORSEMANN))
	{
		SetHealthBar(0.0);
	}
}

public HorsemannSpawned(entity)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	SetHealthBar(100.0);
}

public HorsemannDamaged(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if (!GetConVarBool(g_Cvar_Enabled) || victim < 0 || !IsValidEntity(victim))
	{
		return;
	}
	
	new health = GetEntProp(victim, Prop_Data, HEALTH_MAP);
	new maxHealth = GetEntProp(victim, Prop_Data, MAXHEALTH_MAP);
	
	new Float:newPercent = float(health) / float(maxHealth) * 100.0;
	SetHealthBar(newPercent);
	
}

SetHealthBar(Float:percent)
{
	new healthBar = EntRefToEntIndex(g_HealthBar);
	if (healthBar == -1 || !IsValidEntity(healthBar))
	{
		return;
	}
	// In practice, the multiplier is 2.55
	new Float:value = percent * (HEALTHBAR_MAX / 100.0);

	SetEntProp(healthBar, Prop_Send, RESOURCE_PROP, RoundToNearest(value));
}
