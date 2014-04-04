/**
 * vim: set ts=4 :
 * =============================================================================
 * Name
 * Description
 *
 * Name (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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
#include <tf2>

#pragma semicolon 1

#define VERSION "1.0.0"

new Handle:g_Cvar_Enabled;

new g_bIntercept = false;

public Plugin:myinfo = {
	name			= "Is Holiday Active",
	author			= "Powerlord",
	description		= "Test for updated TF2 module",
	version			= VERSION,
	url				= ""
};

public OnPluginStart()
{
	CreateConVar("isholidayactive_version", VERSION, "Is Holiday Active version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("isholidayactive_enable", "1", "Enable Is Holiday Active?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	RegAdminCmd("checkholiday", Cmd_CheckHoliday, ADMFLAG_GENERIC, "Check if a holiday is currently running");
}

public Action:Cmd_CheckHoliday(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		ReplyToCommand(client, "Plugin is disabled");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: checkholiday #, where # is 1 through 9");
		g_bIntercept = false;
		return Plugin_Handled;
	}
	
	decl String:arg1[3];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new holiday = StringToInt(arg1);
	if (holiday <= 0 || holiday >= 10)
	{
		ReplyToCommand(client, "Argument %d out of range (1-9)", holiday);
		return Plugin_Handled;
	}
	
	decl String:holidayName[64];
	HolidayToString(TFHoliday:holiday, holidayName, sizeof(holidayName));
	
	g_bIntercept = true;
	new bool:value = TF2_IsHolidayActive(TFHoliday:holiday);
	g_bIntercept = false;
	
	ReplyToCommand(client, "\"%s\" is %s", holidayName, value ? "active" : "not active");
	return Plugin_Handled;
}

public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !g_bIntercept)
	{
		return Plugin_Continue;
	}
	
	decl String:holidayName[64];
	HolidayToString(holiday, holidayName, sizeof(holidayName));
	
	LogToGame("Holiday check for \"%s\" intercepted", holidayName);
	return Plugin_Continue;
}

HolidayToString(TFHoliday:holiday, String:holidayName[], length)
{
	switch (holiday)
	{
		case TFHoliday_Birthday:
		{
			strcopy(holidayName, length, "Birthday");
		}
		
		case TFHoliday_Halloween:
		{
			strcopy(holidayName, length, "Halloween");
		}

		case TFHoliday_Christmas:
		{
			strcopy(holidayName, length, "Christmas");
		}
		
		case TFHoliday_ValentinesDay:
		{
			strcopy(holidayName, length, "Valentine's Day");
		}
				
		case TFHoliday_MeetThePyro:
		{
			strcopy(holidayName, length, "Meet the Pyro");
		}
		
		case TFHoliday_FullMoon:
		{
			strcopy(holidayName, length, "Full Moon");
		}
		
		case TFHoliday_HalloweenOrFullMoon:
		{
			strcopy(holidayName, length, "Halloween or Full Moon");
		}
		
		case TFHoliday_HalloweenOrFullMoonOrValentines:
		{
			strcopy(holidayName, length, "Halloween, Full Moon, or Valentine's Day");
		}
		
		case TFHoliday_AprilFools:
		{
			strcopy(holidayName, length, "April Fools");
		}
		
	}
}
