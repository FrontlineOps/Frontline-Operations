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
private _usesUnitFallback = _groupUnits isEqualTo [];
private _rejectedInfantry = [];
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
private _rejectedRadarAssets = [];

{
    private _vehCfg = _x;
    if ((toLower (getText (_vehCfg >> "faction"))) != _factionLower) then { continue };
    if (getNumber (_vehCfg >> "scope") < 2) then { continue };

    private _className = configName _vehCfg;

    if (_className isKindOf "CAManBase") then {
        if (_usesUnitFallback) then {
            if ([_className, _factionClass] call FLO_fnc_factionClassIsCombatInfantry) then {
                _units pushBackUnique _className;
            } else {
                _rejectedInfantry pushBackUnique _className;
            };
        };
        continue;
    };

    {
        private _pool = _vehiclePools get _x;
        _pool pushBackUnique _className;
        _vehiclePools set [_x, _pool];
    } forEach ([_className] call FLO_fnc_factionClassifyVehicle);

    private _hasRadarConfig = getNumber (_vehCfg >> "radarType") > 0 || {getNumber (_vehCfg >> "reportRemoteTargets") > 0};
    private _isDedicatedRadarAsset = (
        (_className isKindOf "LandVehicle") ||
        {_className isKindOf "StaticWeapon"}
    ) && {
        ((toLower _className) find "radar") >= 0 ||
        {((toLower (getText (_vehCfg >> "displayName"))) find "radar") >= 0}
    };

    if (_isDedicatedRadarAsset && {_hasRadarConfig}) then {
        private _radarPool = _vehiclePools get "radar";
        _radarPool pushBackUnique _className;
        _vehiclePools set ["radar", _radarPool];
    } else {
        if (_hasRadarConfig) then {
            _rejectedRadarAssets pushBackUnique _className;
        };
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

_units = _units arrayIntersect _units;

["FACTIONS", 4, format [
    "DETAIL catalog=%1 units=%2 infantryGroups=%3 specOpsGroups=%4 unitFallback=%5 rejectedInfantry=%6 motorized=%7 mechanized=%8 armor=%9 mobileAA=%10 staticAA=%11 radar=%12 airJet=%13 rejectedRadar=%14",
    _factionClass,
    count _units,
    count _infantryGroups,
    count _specOpsGroups,
    _usesUnitFallback,
    count _rejectedInfantry,
    _vehiclePools get "groundMotorized",
    _vehiclePools get "groundMechanized",
    _vehiclePools get "groundArmor",
    _vehiclePools get "mobileAA",
    _vehiclePools get "staticAA",
    _vehiclePools get "radar",
    _vehiclePools get "airJet",
    _rejectedRadarAssets
]] call FLO_fnc_log;

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

private _compositionDefaults = ["BLUFOR", "AUTO_STANDARD"] call FLO_fnc_factionGetCompositionDefaults;

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
    ["transportReserveGroundCount", _compositionDefaults get "transportReserveGroundCount"],
    ["groundArtillery", _vehiclePools get "groundArtillery"],
    ["airHeli", _vehiclePools get "airHeli"],
    ["airJet", _vehiclePools get "airJet"],
    ["airTransport", _vehiclePools get "airTransport"],
    ["transportReserveAirCount", _compositionDefaults get "transportReserveAirCount"],
    ["airDrone", _vehiclePools get "airDrone"],
    ["groundDrone", _vehiclePools get "groundDrone"],
    ["mobileAA", _vehiclePools get "mobileAA"],
    ["staticAA", _vehiclePools get "staticAA"],
    ["boat", _vehiclePools get "boat"],
    ["radar", _vehiclePools get "radar"],
    ["objectiveGroups", _compositionDefaults get "objectiveGroups"],
    ["objectiveGroupTypeCaps", _compositionDefaults get "objectiveGroupTypeCaps"],
    ["groupCounts", _compositionDefaults get "groupCounts"]
]
