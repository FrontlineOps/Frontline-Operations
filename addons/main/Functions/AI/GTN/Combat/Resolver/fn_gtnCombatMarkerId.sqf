/*
 * Function: FLO_fnc_gtnCombatMarkerId
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts a combat zone identifier into a marker-safe string.
 *
 * Arguments:
 *   0: Zone ID <STRING>
 *
 * Return Value:
 *   Marker ID <STRING>
 */

params ["_zoneId"];

private _raw = toArray (str _zoneId);
private _safe = _raw apply {
    [95, _x] select ((_x >= 48 && _x <= 57) ||
        (_x >= 65 && _x <= 90) ||
        (_x >= 97 && _x <= 122) ||
        (_x == 95))
};

format ["FLO_GTN_COMBAT_%1", toString _safe]
