/*
 * Function: FLO_fnc_civilianIntel
 * Author: Frontline Operations Development Group
 * Description:
 *   Provides civilian intel that reveals a nearby enemy group on the map.
 *   Uses FLO_fnc_revealRandomEnemyGroup with a civilian notification string.
 * Arguments: None
 * Returns: Nothing
 */

params [];

sleep 2;
[player, 2000, "STR_FLO_INTEL_CIV"] call FLO_fnc_revealRandomEnemyGroup;
