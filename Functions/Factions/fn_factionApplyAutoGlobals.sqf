/*
 * Function: FLO_fnc_factionApplyAutoGlobals
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies an auto-generated faction selection to the legacy globals that
 *   Phase 2 already consumes when building FLO_FactionCatalog.
 *
 * Arguments:
 *   0: Faction handle <HASHMAP>
 *   1: Role <STRING> - "friendly", "enemy", or "civilian"
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_handle", createHashMap, [createHashMap]],
    ["_role", "", [""]]
];

if !("factionClass" in _handle) exitWith {
    diag_log format ["[FLO][FACTIONS] Auto faction handle missing factionClass for role %1", _role];
    false
};

private _factionClass = _handle get "factionClass";

if (_role isEqualTo "civilian") exitWith {
    private _civCatalog = [_factionClass] call FLO_fnc_factionBuildAutoCivilianCatalog;
    private _men = _civCatalog get "men";
    private _vehicles = _civCatalog get "vehicles";

    if (_men isEqualTo []) exitWith {
        diag_log format ["[FLO][FACTIONS] Auto civilian faction %1 has no spawnable men", _factionClass];
        false
    };

    CivMenArray = _men;
    CivVehArray = _vehicles;

    diag_log format [
        "[FLO][FACTIONS] Applied auto civilian faction %1: men=%2 vehicles=%3",
        _factionClass,
        count CivMenArray,
        count CivVehArray
    ];

    true
};

if !(_role in ["friendly", "enemy"]) exitWith {
    diag_log format ["[FLO][FACTIONS] Unknown auto faction role %1 for %2", _role, _factionClass];
    false
};

private _catalog = [_factionClass] call FLO_fnc_factionBuildAutoMilitaryCatalog;
if ((count keys _catalog) == 0) exitWith {
    diag_log format ["[FLO][FACTIONS] Failed to build auto military catalog for %1", _factionClass];
    false
};

private _units = _catalog get "groundInfantryUnits";
if (_units isEqualTo []) exitWith {
    diag_log format ["[FLO][FACTIONS] Auto military faction %1 has no spawnable infantry units", _factionClass];
    false
};

private _applied = switch (_role) do {
    case "friendly": { [_catalog] call FLO_fnc_factionApplyAutoFriendlyGlobals };
    case "enemy": { [_catalog] call FLO_fnc_factionApplyAutoEnemyGlobals };
};

if (!_applied) exitWith { false };

diag_log format [
    "[FLO][FACTIONS] Applied auto %1 faction %2: units=%3 groups=%4 motorized=%5 mechanized=%6 armor=%7 air=%8",
    _role,
    _factionClass,
    count (_catalog get "groundInfantryUnits"),
    count (_catalog get "groundInfantryGroups"),
    count (_catalog get "groundMotorized"),
    count (_catalog get "groundMechanized"),
    count (_catalog get "groundArmor"),
    count ((_catalog get "airHeli") + (_catalog get "airJet"))
];

true
