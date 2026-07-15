/*
 * Function: FLO_fnc_factionUnitIsOfficer
 * Description:
 *   Checks officer authority against the native catalog for the unit's side.
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith { false };

private _side = side group _unit;
if !(_side in [west, east]) exitWith { false };

private _catalog = FLO_FactionCatalog get ([_side] call FLO_fnc_sideKey);
(typeOf _unit) in (_catalog get "officers")
