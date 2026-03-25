/*
 * Function: FLO_fnc_gtnAlertCivilianReport
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a civilian-origin suspicious activity report as an uncertain
 *   local alert instead of revealing exact enemy forces.
 *
 * Arguments:
 *   0: Report source object or position <OBJECT|ARRAY>
 *   1: Reporting side <SIDE>
 *   2: Search radius <NUMBER>
 *
 * Return Value:
 *   HASHMAP - Published alert data
 */

params [
    ["_source", [0, 0, 0], [objNull, []]],
    ["_reportingSide", sideUnknown],
    ["_radius", 600, [0]]
];

if (!isServer) exitWith {
    [_source, _reportingSide, _radius] remoteExecCall ["FLO_fnc_gtnAlertCivilianReport", 2, false];
    createHashMap
};

if !(_reportingSide in [east, west]) exitWith { createHashMap };
if (_source isEqualType objNull && {isNull _source}) exitWith { createHashMap };

private _sourcePos = if (_source isEqualType objNull) then { getPosATL _source } else { _source };
private _reportPos = _sourcePos getPos [80 + random 120, random 360];
private _grid = mapGridPosition _reportPos;
private _message = format ["Civilian report: suspicious activity near grid %1", _grid];

[_reportingSide, "CIVILIAN_REPORT", _reportPos, _radius, 120, _message] call FLO_fnc_gtnPublishAlert
