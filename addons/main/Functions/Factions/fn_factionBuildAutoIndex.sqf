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
 *   HASHMAP with keys blufor, opfor, civilian, byClass
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

{
    private _root = _x;
    if (isClass _root) then {
        for "_i" from 0 to (count _root - 1) do {
            private _facCfg = _root select _i;
            if !(isClass _facCfg) then { continue };

            private _className = configName _facCfg;
            private _classLower = toLower _className;
            if (_classLower in _factionsByLower) then { continue };

            _totalScanned = _totalScanned + 1;

            private _side = if (isNumber (_facCfg >> "side")) then {
                getNumber (_facCfg >> "side")
            } else {
                -1
            };
            if !(_side in [0, 1, 3]) then {
                _droppedBadSide = _droppedBadSide + 1;
                ["FACTIONS", 4, format ["DETAIL drop=%1 reason=badSide side=%2", _className, _side]] call FLO_fnc_log;
                continue;
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

    private _isMan = (configName _vehCfg) isKindOf "Man";
    private _factionMeta = _factionsByLower get _factionLower;
    if (getNumber (_vehCfg >> "side") != (_factionMeta get "side")) then { continue };
    if (_isMan) then {
        if ((_factionMeta get "side") != 3 && {!([configName _vehCfg, _faction] call FLO_fnc_factionClassIsCombatInfantry)}) then { continue };
    };
    private _map = [_vehicleCounts, _unitCounts] select _isMan;

    private _count = 0;
    if (_factionLower in _map) then {
        _count = _map get _factionLower;
    };
    _map set [_factionLower, _count + 1];
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

private _blufor = [];
private _opfor = [];
private _civilian = [];
private _byClass = createHashMap;

{
    private _classLower = _x;
    private _meta = _y;
    private _className = _meta get "class";
    private _side = _meta get "side";

    if (_classLower in _blacklist) then {
        _droppedBlacklist = _droppedBlacklist + 1;
        ["FACTIONS", 4, format ["DETAIL drop=%1 reason=blacklist", _className]] call FLO_fnc_log;
        continue;
    };

    private _unitCount = 0;
    if (_classLower in _unitCounts) then {
        _unitCount = _unitCounts get _classLower;
    };

    if (_unitCount <= 0) then {
        _droppedNoUnits = _droppedNoUnits + 1;
        ["FACTIONS", 4, format ["DETAIL drop=%1 reason=noUnits side=%2", _className, _sideLabels select _side]] call FLO_fnc_log;
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
    ["FACTIONS", 4, format [
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
    switch (_side) do {
        case 0: { _opfor pushBack _entry };
        case 1: { _blufor pushBack _entry };
        case 3: { _civilian pushBack _entry };
    };
} forEach _factionsByLower;

_blufor = [_blufor, [], { _x get "label" }, "ASCEND"] call BIS_fnc_sortBy;
_opfor = [_opfor, [], { _x get "label" }, "ASCEND"] call BIS_fnc_sortBy;
_civilian = [_civilian, [], { _x get "label" }, "ASCEND"] call BIS_fnc_sortBy;

FLO_AutoFactionIndex = createHashMapFromArray [
    ["blufor", _blufor],
    ["opfor", _opfor],
    ["civilian", _civilian],
    ["byClass", _byClass]
];

["FACTIONS", 3, format [
    "Auto faction index: scanned=%1 blufor=%2 opfor=%3 civilian=%4 dropped(badSide)=%5 dropped(noUnits)=%6 dropped(blacklist)=%7 timeMs=%8",
    _totalScanned,
    count _blufor,
    count _opfor,
    count _civilian,
    _droppedBadSide,
    _droppedNoUnits,
    _droppedBlacklist,
    (diag_tickTime - _t0) * 1000
]] call FLO_fnc_log;

FLO_AutoFactionIndex
