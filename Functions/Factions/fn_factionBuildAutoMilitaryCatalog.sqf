/*
 * Function: FLO_fnc_factionBuildAutoMilitaryCatalog
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a FLO military faction catalog from loaded config data.
 *
 * Arguments:
 *   0: Faction classname <STRING>
 *
 * Return Value:
 *   HASHMAP matching a side entry in FLO_FactionCatalog
 */

params [["_factionClass", "", [""]]];

private _empty = createHashMap;
if (_factionClass == "") exitWith { _empty };

private _groups = [_factionClass] call FLO_fnc_factionGetGroupConfigs;
private _infantryGroups = _groups get "infantryGroups";
private _specOpsGroups = _groups get "specOpsGroups";
private _groupUnits = _groups get "infantryUnits";

private _units = +_groupUnits;
private _vehiclePools = createHashMapFromArray [
    ["groundMotorized", []],
    ["groundMechanized", []],
    ["groundArmor", []],
    ["groundTransport", []],
    ["groundArtillery", []],
    ["airHeli", []],
    ["airJet", []],
    ["airTransport", []],
    ["airDrone", []],
    ["groundDrone", []],
    ["mobileAA", []],
    ["staticAA", []],
    ["boat", []],
    ["radar", []]
];

private _factionLower = toLower _factionClass;

{
    private _vehCfg = _x;
    if ((toLower (getText (_vehCfg >> "faction"))) != _factionLower) then { continue };
    if (getNumber (_vehCfg >> "scope") < 2) then { continue };

    private _className = configName _vehCfg;

    if (_className isKindOf "Man") then {
        _units pushBackUnique _className;
        continue;
    };

    {
        private _pool = _vehiclePools get _x;
        _pool pushBackUnique _className;
        _vehiclePools set [_x, _pool];
    } forEach ([_className] call FLO_fnc_factionClassifyVehicle);

    if (getNumber (_vehCfg >> "radarType") > 0 || {getNumber (_vehCfg >> "reportRemoteTargets") > 0}) then {
        private _radarPool = _vehiclePools get "radar";
        _radarPool pushBackUnique _className;
        _vehiclePools set ["radar", _radarPool];
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

_units = _units arrayIntersect _units;

private _specOpsUnits = [];
if (_specOpsGroups isNotEqualTo []) then {
    private _specPools = [_specOpsGroups] call FLO_fnc_initFactionSplitMixedInfantryPool;
    _specOpsUnits = _specPools select 1;
};

private _officers = [];
private _officer = [_units, "officer"] call FLO_fnc_factionPickUnitByRole;
if (_officer != "") then {
    _officers pushBack _officer;
};

private _objectiveGroups = [];
private _addTemplate = {
    params ["_subtype", "_infantryCount"];

    private _groupsForSubtype = [["infantry", _infantryCount]];

    if ((_vehiclePools get "groundMotorized") isNotEqualTo []) then {
        _groupsForSubtype pushBack ["motorized", if (_subtype in ["capital", "city", "local"]) then { 1 } else { 0 }];
    };
    if ((_vehiclePools get "groundMechanized") isNotEqualTo [] && {_subtype in ["capital", "city", "local"]}) then {
        _groupsForSubtype pushBack ["mechanized", 1];
    };
    if ((_vehiclePools get "groundArmor") isNotEqualTo [] && {_subtype in ["capital", "local"]}) then {
        _groupsForSubtype pushBack ["armor", 1];
    };
    if (((_vehiclePools get "airHeli") + (_vehiclePools get "airJet")) isNotEqualTo [] && {_subtype in ["capital", "city"]}) then {
        _groupsForSubtype pushBack ["air", 1];
    };
    if ((_vehiclePools get "groundArtillery") isNotEqualTo [] && {_subtype in ["capital", "city"]}) then {
        _groupsForSubtype pushBack ["artillery", 1];
    };
    if ((_vehiclePools get "staticAA") isNotEqualTo [] && {_subtype in ["capital", "city"]}) then {
        _groupsForSubtype pushBack ["static_aa", 1];
    };
    if ((_vehiclePools get "mobileAA") isNotEqualTo [] && {_subtype in ["capital", "city", "local"]}) then {
        _groupsForSubtype pushBack ["mobile_aa", 1];
    };

    _groupsForSubtype = _groupsForSubtype select { (_x select 1) > 0 };
    _objectiveGroups pushBack [_subtype, _groupsForSubtype];
};

["capital", 10] call _addTemplate;
["city", 6] call _addTemplate;
["village", 3] call _addTemplate;
["local", 5] call _addTemplate;
["marine", 3] call _addTemplate;
["cluster", 2] call _addTemplate;

private _objectiveCaps = [];
if ((_vehiclePools get "groundArtillery") isNotEqualTo []) then {
    _objectiveCaps pushBack ["artillery", 5];
};
if ((_vehiclePools get "staticAA") isNotEqualTo []) then {
    _objectiveCaps pushBack ["static_aa", 4];
};
if ((_vehiclePools get "mobileAA") isNotEqualTo []) then {
    _objectiveCaps pushBack ["mobile_aa", 12];
};

createHashMapFromArray [
    ["source", "auto"],
    ["factionClass", _factionClass],
    ["groups", _infantryGroups],
    ["units", _units],
    ["officers", _officers],
    ["groundInfantryGroups", _infantryGroups],
    ["groundInfantryUnits", _units],
    ["groundSpecOpsGroups", _specOpsGroups],
    ["groundSpecOpsUnits", _specOpsUnits],
    ["groundMotorized", _vehiclePools get "groundMotorized"],
    ["groundMechanized", _vehiclePools get "groundMechanized"],
    ["groundArmor", _vehiclePools get "groundArmor"],
    ["groundTransport", _vehiclePools get "groundTransport"],
    ["transportReserveGroundCount", if ((_vehiclePools get "groundTransport") isEqualTo []) then { 0 } else { 10 }],
    ["groundArtillery", _vehiclePools get "groundArtillery"],
    ["airHeli", _vehiclePools get "airHeli"],
    ["airJet", _vehiclePools get "airJet"],
    ["airTransport", _vehiclePools get "airTransport"],
    ["transportReserveAirCount", if ((_vehiclePools get "airTransport") isEqualTo []) then { 0 } else { 4 }],
    ["airDrone", _vehiclePools get "airDrone"],
    ["groundDrone", _vehiclePools get "groundDrone"],
    ["mobileAA", _vehiclePools get "mobileAA"],
    ["staticAA", _vehiclePools get "staticAA"],
    ["boat", _vehiclePools get "boat"],
    ["radar", _vehiclePools get "radar"],
    ["objectiveGroups", _objectiveGroups],
    ["objectiveGroupTypeCaps", _objectiveCaps],
    ["groupCounts", [
        ["infantry", 8],
        ["motorized", 1],
        ["mechanized", 1],
        ["armor", 1],
        ["helicopter", 1],
        ["jet", 1],
        ["air", 1],
        ["artillery", 1],
        ["mobile_aa", 1],
        ["static_aa", 1]
    ]]
]
