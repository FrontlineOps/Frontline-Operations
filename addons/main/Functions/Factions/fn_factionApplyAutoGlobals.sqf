/*
 * Function: FLO_fnc_factionApplyAutoGlobals
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies an auto-generated faction selection to the legacy globals that
 *   Phase 2 already consumes when building FLO_FactionCatalog.
 *
 * Arguments:
 *   0: Faction handle <HASHMAP>
 *   1: Role <STRING> - "blufor", "opfor", or "civilian"
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_handle", createHashMap, [createHashMap]],
    ["_role", "", [""]]
];

private _source = if ("source" in _handle) then { _handle get "source" } else { "auto" };
private _factionClasses = if ("factionClasses" in _handle) then {
    +(_handle get "factionClasses")
} else {
    if ("factionClass" in _handle) then { [_handle get "factionClass"] } else { [] }
};
_factionClasses = _factionClasses select { _x isEqualType "" && {_x != ""} };
_factionClasses = _factionClasses arrayIntersect _factionClasses;

if (_factionClasses isEqualTo []) exitWith {
    ["FACTIONS", 2, format ["Auto faction handle missing faction class data for role %1", _role]] call FLO_fnc_log;
    false
};

private _factionClass = _factionClasses select 0;
private _factionLabel = if (count _factionClasses > 1) then {
    _factionClasses joinString " + "
} else {
    _factionClass
};

if (_role isEqualTo "civilian") exitWith {
    private _civCatalog = if (_source isEqualTo "auto_multi" || {count _factionClasses > 1}) then {
        [_factionClasses] call FLO_fnc_factionBuildMergedAutoCivilianCatalog
    } else {
        [_factionClass] call FLO_fnc_factionBuildAutoCivilianCatalog
    };
    private _men = _civCatalog get "men";
    private _vehicles = _civCatalog get "vehicles";

    if (_men isEqualTo []) exitWith {
        ["FACTIONS", 2, format ["Auto civilian faction %1 has no spawnable men", _factionLabel]] call FLO_fnc_log;
        false
    };

    CivMenArray = _men;
    CivVehArray = _vehicles;

    ["FACTIONS", 3, format [
        "Applied auto civilian faction %1: men=%2 vehicles=%3",
        _factionLabel,
        count CivMenArray,
        count CivVehArray
    ]] call FLO_fnc_log;

    true
};

if !(_role in ["blufor", "opfor"]) exitWith {
    ["FACTIONS", 2, format ["Unknown auto faction role %1 for %2", _role, _factionClass]] call FLO_fnc_log;
    false
};

private _catalog = if (_source isEqualTo "auto_multi" || {count _factionClasses > 1}) then {
    [_factionClasses] call FLO_fnc_factionBuildMergedAutoMilitaryCatalog
} else {
    [_factionClass] call FLO_fnc_factionBuildAutoMilitaryCatalog
};
if ((keys _catalog) isEqualTo []) exitWith {
    ["FACTIONS", 2, format ["Failed to build auto military catalog for %1", _factionLabel]] call FLO_fnc_log;
    false
};

private _units = _catalog get "groundInfantryUnits";
if (_units isEqualTo []) exitWith {
    ["FACTIONS", 2, format ["Auto military faction %1 has no spawnable infantry units", _factionClass]] call FLO_fnc_log;
    false
};

private _applied = switch (_role) do {
    case "blufor": { [_catalog] call FLO_fnc_factionApplyAutoBluforGlobals };
    case "opfor": { [_catalog] call FLO_fnc_factionApplyAutoOpforGlobals };
};

if (!_applied) exitWith { false };

["FACTIONS", 3, format [
    "Applied auto %1 faction %2: units=%3 groups=%4 motorized=%5 mechanized=%6 armor=%7 air=%8",
    _role,
    _factionLabel,
    count (_catalog get "groundInfantryUnits"),
    count (_catalog get "groundInfantryGroups"),
    count (_catalog get "groundMotorized"),
    count (_catalog get "groundMechanized"),
    count (_catalog get "groundArmor"),
    count ((_catalog get "airHeli") + (_catalog get "airJet"))
]] call FLO_fnc_log;

true
