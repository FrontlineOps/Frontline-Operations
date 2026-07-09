/*
 * Function: FLO_fnc_factionBuildAutoIndex
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the runtime list of config-compatible factions for mission setup.
 *
 * Arguments:
 *   0: Force rebuild <BOOL> (optional)
 *
 * Return Value:
 *   HASHMAP with keys military, civilian, byClass
 */

params [["_force", false, [false]]];

if (!_force && {!isNil "FLO_AutoFactionIndex"}) exitWith {
    FLO_AutoFactionIndex
};

private _t0 = diag_tickTime;
private _sideLabels = ["OPFOR", "BLUFOR", "INDFOR", "CIVILIAN"];
private _factionsByLower = createHashMap;
private _unitCounts = createHashMap;
private _vehicleCounts = createHashMap;
private _groupCounts = createHashMap;
private _totalScanned = 0;
private _droppedBadSide = 0;
private _droppedNoUnits = 0;
private _droppedBlacklist = 0;

private _blacklist = createHashMapFromArray [
    ["virtual_f", true],
    ["interactive_f", true]
];

private _registerFaction = {
    params ["_facCfg"];

    private _className = configName _facCfg;
    private _classLower = toLower _className;
    if (_classLower in _factionsByLower) exitWith {};

    _totalScanned = _totalScanned + 1;

    private _side = getNumber (_facCfg >> "side");
    if !(isNumber (_facCfg >> "side")) then {
        _side = -1;
    };

    if !(_side in [0, 1, 2, 3]) exitWith {
        _droppedBadSide = _droppedBadSide + 1;
        ["FACTIONS", 2, format ["DETAIL drop=%1 reason=badSide side=%2", _className, _side]] call FLO_fnc_log;
    };

    private _displayName = getText (_facCfg >> "displayName");
    if (_displayName == "") then {
        _displayName = _className;
    };

    _factionsByLower set [_classLower, createHashMapFromArray [
        ["class", _className],
        ["displayName", _displayName],
        ["side", _side]
    ]];
};

{
    private _root = _x;
    if (isClass _root) then {
        for "_i" from 0 to (count _root - 1) do {
            private _facCfg = _root select _i;
            if (isClass _facCfg) then {
                [_facCfg] call _registerFaction;
            };
        };
    };
} forEach [
    missionConfigFile >> "CfgFactionClasses",
    configFile >> "CfgFactionClasses"
];

{
    private _sideName = _x;
    private _root = configFile >> "CfgGroups" >> _sideName;
    if (isClass _root) then {
        for "_i" from 0 to (count _root - 1) do {
            private _facGroups = _root select _i;
            if (isClass _facGroups && {_facGroups isNotEqualTo []}) then {
                private _classLower = toLower (configName _facGroups);
                private _count = 0;
                if (_classLower in _groupCounts) then {
                    _count = _groupCounts get _classLower;
                };
                _groupCounts set [_classLower, _count + count _facGroups];
            };
        };
    };
} forEach ["East", "West", "Indep", "Civilian"];

{
    private _vehCfg = _x;
    private _faction = getText (_vehCfg >> "faction");
    if (_faction == "") then { continue };

    private _factionLower = toLower _faction;
    if !(_factionLower in _factionsByLower) then { continue };
    if (getNumber (_vehCfg >> "scope") < 2) then { continue };

    private _map = [_vehicleCounts, _unitCounts] select ((configName _vehCfg) isKindOf "Man");

    private _count = 0;
    if (_factionLower in _map) then {
        _count = _map get _factionLower;
    };
    _map set [_factionLower, _count + 1];
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

private _military = [];
private _civilian = [];
private _byClass = createHashMap;

{
    private _classLower = _x;
    private _meta = _y;
    private _className = _meta get "class";
    private _side = _meta get "side";

    if (_classLower in _blacklist) then {
        _droppedBlacklist = _droppedBlacklist + 1;
        ["FACTIONS", 2, format ["DETAIL drop=%1 reason=blacklist", _className]] call FLO_fnc_log;
        continue;
    };

    private _unitCount = 0;
    if (_classLower in _unitCounts) then {
        _unitCount = _unitCounts get _classLower;
    };

    if (_unitCount <= 0) then {
        _droppedNoUnits = _droppedNoUnits + 1;
        ["FACTIONS", 2, format ["DETAIL drop=%1 reason=noUnits side=%2", _className, _sideLabels select _side]] call FLO_fnc_log;
        continue;
    };

    private _vehicleCount = 0;
    if (_classLower in _vehicleCounts) then {
        _vehicleCount = _vehicleCounts get _classLower;
    };

    private _cfgGroupCount = 0;
    if (_classLower in _groupCounts) then {
        _cfgGroupCount = _groupCounts get _classLower;
    };

    private _displayName = _meta get "displayName";
    private _sideLabel = _sideLabels select _side;
    private _compat = ["CfgVehicles", "CfgGroups"] select (_cfgGroupCount > 0);
    private _label = format ["[AUTO] %1 - %2 (%3)", _sideLabel, _displayName, _className];
    ["FACTIONS", 2, format [
        "DETAIL keep=%1 side=%2 compatibility=%3 units=%4 vehicles=%5 cfgGroups=%6",
        _className,
        _sideLabel,
        _compat,
        _unitCount,
        _vehicleCount,
        _cfgGroupCount
    ]] call FLO_fnc_log;
    private _entry = createHashMapFromArray [
        ["label", _label],
        ["class", _className],
        ["displayName", _displayName],
        ["side", _side],
        ["sideLabel", _sideLabel],
        ["compatibility", _compat],
        ["unitCount", _unitCount],
        ["vehicleCount", _vehicleCount],
        ["cfgGroupCount", _cfgGroupCount]
    ];

    _byClass set [_className, _entry];
    if (_side == 3) then {
        _civilian pushBack _entry;
    } else {
        _military pushBack _entry;
    };
} forEach _factionsByLower;

_military = [_military, [], { _x get "label" }, "ASCEND"] call BIS_fnc_sortBy;
_civilian = [_civilian, [], { _x get "label" }, "ASCEND"] call BIS_fnc_sortBy;

FLO_AutoFactionIndex = createHashMapFromArray [
    ["military", _military],
    ["civilian", _civilian],
    ["byClass", _byClass]
];

["FACTIONS", 2, format [
    "Auto faction index: scanned=%1 military=%2 civilian=%3 dropped(badSide)=%4 dropped(noUnits)=%5 dropped(blacklist)=%6 timeMs=%7",
    _totalScanned,
    count _military,
    count _civilian,
    _droppedBadSide,
    _droppedNoUnits,
    _droppedBlacklist,
    (diag_tickTime - _t0) * 1000
]] call FLO_fnc_log;

FLO_AutoFactionIndex
