/*
 * Function: FLO_fnc_flipObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Changes the owner of a virtual objective and updates its marker color.
 *
 * Arguments:
 *   0: Objective ID <STRING>
 *   1: New owner <SIDE>
 *
 * Returns: <BOOL> Success
 *
 * Example:
 *   ["virtual_1", west] call FLO_fnc_flipObjective;
 */

params ["_objectiveId", "_newOwner"];

if (isNil "FLO_Objectives") exitWith {false};

private _obj = FLO_Objectives get _objectiveId;
if (isNil "_obj") exitWith {false};

_obj set ["owner", _newOwner];
FLO_Objectives set [_objectiveId, _obj];

private _pos = _obj get "position";
private _radius = _obj get "radius";
private _marker = format ["obj_%1", _objectiveId];
if (getMarkerColor _marker == "") then {
    createMarker [_marker, _pos];
    _marker setMarkerShape "ELLIPSE";
    _marker setMarkerSize [_radius, _radius];
};

private _color = switch (_newOwner) do {
    case west: {"colorBLUFOR"};
    case east: {"colorOPFOR"};
    case resistance: {"ColorGUER"};
    default {"ColorBlack"};
};

_marker setMarkerColor _color;
true
