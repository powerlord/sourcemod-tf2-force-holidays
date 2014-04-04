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
#if defined _tfforceholidays_included_
  #endinput
#endif
#define _tfforceholidays_included_

// This wil be required based on the REQUIRE_PLUGIN setting at the time
#include <tf2>

// Plugin 2.0 series

/**
 * Call to check if a holiday is active.
 * This can be overridden by other plugins using the TF2_OnIsHolidayActive callback
 *
 * @param holiday		Holiday being checked.
 * @return				True if holiday is active, false if it isn't
 */
native bool:TF2_IsHolidayActive(TFHoliday:holiday);

public SharedPlugin:__pl_pluginname = 
{
	name = "tfforceholidays",
	file = "tfforceholidays.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tfforceholidays_SetNTVOptional()
{
	MarkNativeAsOptional("FunctionWithArg");
	MarkNativeAsOptional("FunctionWithoutArg");
	MarkNativeAsOptional("RegisterCallback");
	MarkNativeAsOptional("UnregisterCallback");
}
#endif
