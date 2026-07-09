/*
 * Function: FLO_fnc_gtnSubmitPlayerSupportRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side wrapper for player-requested commander artillery, CAS, and
 *   CAP missions. Sends the request to the server through a CBA server event.
 *
 * Arguments:
 *   0: Support type <STRING>
 *   1: Target position <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_supportType", "", [""]],
    ["_targetPos", [0, 0, 0], [[]], [3]]
];

if (!hasInterface) exitWith { false };
if (isNull player) exitWith { false };

["FLO_GTN_PlayerSupportRequest", [player, _supportType, _targetPos]] call CBA_fnc_serverEvent;
true
