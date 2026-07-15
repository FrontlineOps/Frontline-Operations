/*
 * Function: FLO_fnc_initPhase2_Factions
 * Description:
 *   Loads native faction selections, validates their exact current inputs,
 *   and publishes one canonical runtime catalog.
 */
if (!isServer) exitWith { false };

["FACTIONS", 3, "Loading native faction definitions"] call FLO_fnc_log;

if (isNil "FLO_BluforHandle" || {isNil "FLO_OpforHandle"} || {isNil "FLO_CivilianHandle"}) then {
    throw "Faction handles were not committed during Phase 1";
};

F_Init = false;
publicVariable "F_Init";

private _westCatalog = [FLO_BluforHandle, "blufor"] call FLO_fnc_initLoadFactionSelection;
private _eastCatalog = [FLO_OpforHandle, "opfor"] call FLO_fnc_initLoadFactionSelection;
private _civilianCatalog = [FLO_CivilianHandle, "civilian"] call FLO_fnc_initLoadFactionSelection;

if ((keys _westCatalog) isEqualTo []) then {
    throw format ["BLUFOR faction %1 produced an empty catalog", FLO_BluforHandle get "name"];
};
if ((keys _eastCatalog) isEqualTo []) then {
    throw format ["OPFOR faction %1 produced an empty catalog", FLO_OpforHandle get "name"];
};
if ((keys _civilianCatalog) isEqualTo []) then {
    throw format ["Civilian faction %1 produced an empty catalog", FLO_CivilianHandle get "name"];
};

if (([FLO_BluforHandle] call FLO_fnc_factionHandleSource) in ["auto", "auto_multi"]) then {
    FLO_FactionFobType = "Land_Cargo_HQ_V3_F";
    FLO_FactionFobTerminalType = "Land_TripodScreen_01_large_sand_F";
    FLO_FactionCopType = "Land_Cargo_House_V3_F";
    FLO_FactionCopTerminalType = "Land_TripodScreen_01_dual_v2_sand_F";
};

{
    private _variableName = _x;
    if (isNil _variableName) then {
        throw format ["Faction base asset %1 was not defined", _variableName];
    };

    private _value = missionNamespace getVariable _variableName;
    if !(_value isEqualType "" && {_value != ""}) then {
        throw format ["Faction base asset %1 must be non-empty text", _variableName];
    };
} forEach [
    "FLO_FactionFobType",
    "FLO_FactionFobTerminalType",
    "FLO_FactionCopType",
    "FLO_FactionCopTerminalType"
];

[_westCatalog, FLO_WestFactionTuningHandle, "BLUFOR"] call FLO_fnc_factionApplyTuningOverrides;
[_eastCatalog, FLO_EastFactionTuningHandle, "OPFOR"] call FLO_fnc_factionApplyTuningOverrides;

private _militarySideFields = [
    "officers",
    "groundInfantryGroups",
    "groundInfantryUnits",
    "groundSpecOpsGroups",
    "groundSpecOpsUnits",
    "groundMotorized",
    "groundMechanized",
    "groundArmor",
    "groundTransport",
    "groundArtillery",
    "airHeli",
    "airJet",
    "airTransport",
    "airDrone",
    "groundDrone",
    "mobileAA",
    "staticAA",
    "boat",
    "logisticsConstruction",
    "logisticsAmmo",
    "logisticsRespawn",
    "containers",
    "radar"
];

[_westCatalog, 1, "BLUFOR", _militarySideFields] call FLO_fnc_factionValidateCatalogSide;
[_eastCatalog, 0, "OPFOR", _militarySideFields] call FLO_fnc_factionValidateCatalogSide;
[_civilianCatalog, 3, "CIVILIAN", ["men", "vehicles"]] call FLO_fnc_factionValidateCatalogSide;

FLO_MissionSides = [east, west];
publicVariable "FLO_MissionSides";

if !(FLO_ActivePlayerSide in FLO_MissionSides) then {
    throw format ["Player side was not committed during Phase 1: %1", FLO_ActivePlayerSide];
};

FLO_FactionCatalog = createHashMapFromArray [
    ["EAST", _eastCatalog],
    ["WEST", _westCatalog],
    ["CIVILIAN", _civilianCatalog]
];
publicVariable "FLO_FactionCatalog";

{
    publicVariable _x;
} forEach [
    "FLO_FactionFobType",
    "FLO_FactionFobTerminalType",
    "FLO_FactionCopType",
    "FLO_FactionCopTerminalType"
];

F_Init = true;
publicVariable "F_Init";

["FACTIONS", 3, format [
    "Committed native campaign factions: BLUFOR=%1; OPFOR=%2; CIVILIAN=%3",
    FLO_BluforHandle get "name",
    FLO_OpforHandle get "name",
    FLO_CivilianHandle get "name"
]] call FLO_fnc_log;

true
