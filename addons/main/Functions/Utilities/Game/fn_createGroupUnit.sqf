/*
 * Function: FLO_fnc_createGroupUnit
 * Description:
 *   Creates a unit in a local group and explicitly commits the unit to the
 *   group's side. Arma's modern group createUnit syntax otherwise preserves
 *   the classname's configured side when it differs from the group side.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_unitType", "", [""]],
    ["_position", [0, 0, 0], [[]]],
    ["_markers", [], [[]]],
    ["_placement", 0, [0]],
    ["_special", "NONE", [""]],
    ["_context", "", [""]]
];

private _contextSuffix = if (_context == "") then { "" } else { format [" context=%1", _context] };

if (isNull _group) exitWith {
    ["SPAWN", 1, format ["Cannot create unit %1 in a null group%2", _unitType, _contextSuffix]] call FLO_fnc_log;
    objNull
};

private _unitCfg = configFile >> "CfgVehicles" >> _unitType;
if !(isClass _unitCfg && {_unitType isKindOf "Man"}) exitWith {
    ["SPAWN", 1, format ["Cannot create invalid unit class %1%2", _unitType, _contextSuffix]] call FLO_fnc_log;
    objNull
};

private _expectedSide = side _group;
private _unit = _group createUnit [_unitType, _position, _markers, _placement, _special];
if (isNull _unit) exitWith {
    ["SPAWN", 1, format ["Engine failed to create unit %1 for side %2%3", _unitType, _expectedSide, _contextSuffix]] call FLO_fnc_log;
    objNull
};

if ((group _unit) isNotEqualTo _group || {(side _unit) isNotEqualTo _expectedSide}) then {
    [_unit] joinSilent _group;
};

if ((group _unit) isNotEqualTo _group || {(side _unit) isNotEqualTo _expectedSide}) exitWith {
    ["SPAWN", 1, format [
        "Unit side commit failed for %1: expected=%2 actualUnit=%3 actualGroup=%4%5",
        _unitType,
        _expectedSide,
        side _unit,
        side group _unit,
        _contextSuffix
    ]] call FLO_fnc_log;
    deleteVehicle _unit;
    objNull
};

_unit
