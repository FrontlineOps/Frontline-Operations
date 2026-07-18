/*
 * Function: FLO_fnc_gtnGetCommanderBySide
 * Description:
 *   Resolves one live server-local GTN commander by Arma side.
 */

params [["_side", sideUnknown, [sideUnknown]]];

private _manager = call FLO_fnc_gtnGetResourceManager;
if (isNil "_manager") exitWith { nil };

_manager call ["_getCommanderBySide", [_side]]
