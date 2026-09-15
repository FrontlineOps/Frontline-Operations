/*
 * Function: FLO_fnc_MissionSave
 * Author: Frontline Operations Development Group
 * Description:
 *   Comprehensive mission save system. Saves all mission state to missionProfileNamespace.
 *   Includes: time, markers, vehicles, objects, crates, virtual groups, objectives,
 *   AI commander state, OPFOR resources, and mission configuration.
 *
 * Arguments: None
 * Returns: <BOOL> - True if save successful
 *
 * Example:
 *   [] call FLO_fnc_MissionSave;
 */

params [["_queuedSequence", -1, [0]]];
if (!isServer) exitWith { false };
if (remoteExecutedOwner > 2) exitWith {
    ["SAVE", 2, "Rejected direct remote save; clients must use the authenticated save request"] call FLO_fnc_log;
    false
};
if (!FLO_MissionReady) exitWith {
    ["SAVE", 2, "Rejected campaign save before mission readiness"] call FLO_fnc_log;
    false
};
private _acquiredSave = false;
isNil {
    private _queued = (FLO_SaveStatus get "phase") == "QUEUED";
    private _ownsQueue = _queued && {_queuedSequence == FLO_SaveSequence};
    if (!FLO_MissionSaveInProgress && {(!_queued && {_queuedSequence == -1}) || {_ownsQueue}}) then {
        // Direct local callers own a new generation; an older worker's completion
        // monitor must never release this transaction's lock.
        if (!_ownsQueue) then { FLO_SaveSequence = FLO_SaveSequence + 1 };
        FLO_MissionSaveInProgress = true;
        FLO_SaveStatus set ["phase", "SAVING"];
        FLO_SaveStatus set ["lastAttemptAt", diag_tickTime];
        _acquiredSave = true;
    };
};
if (!_acquiredSave) exitWith {
    ["SAVE", 2, "Rejected concurrent mission save request"] call FLO_fnc_log;
    false
};

private _saveResult = false;
private _saveException = "";
try {
_saveResult = call {

["SAVE", 3, "Starting mission save..."] call FLO_fnc_log;

// Create fresh save data
private _data = createHashMap;
_data set ["time", call FLO_fnc_operationalDate];

// ============================================================================
// PRE-SAVE CLEANUP
// ============================================================================

{ deleteVehicle _x } forEach (allMissionObjects "Sign_Sphere10cm_F");
{ deleteMarker _x } forEach (allMapMarkers select { markerType _x == "b_unknown" && markerColor _x == "Color6_FD_F" });

// Cache installation positions
private _installationMarkers = allMapMarkers select { markerType _x == "b_installation" };
private _saveRadius = 300;

// ============================================================================
// SAVE: CONFIGURATION
// ============================================================================

try {
    private _cfg = createHashMap;
    _cfg set ["bluforHandle", FLO_BluforHandle];
    _cfg set ["opforHandle", FLO_OpforHandle];
    _cfg set ["civilianHandle", FLO_CivilianHandle];
    _cfg set ["playerSideKey", [FLO_ActivePlayerSide] call FLO_fnc_sideKey];
    _cfg set ["startingResources", FLO_MissionConfig get "startingResources"];
    _cfg set ["reputationHandle", FLO_ReputationHandle];
    _cfg set ["westDifficultyHandle", FLO_WestDifficultyHandle];
    _cfg set ["eastDifficultyHandle", FLO_EastDifficultyHandle];
    _cfg set ["westGTNAttackCoverageHandle", FLO_WestGTN_AttackCoverageHandle];
    _cfg set ["eastGTNAttackCoverageHandle", FLO_EastGTN_AttackCoverageHandle];
    _cfg set ["westGTNDefenseCoverageHandle", FLO_WestGTN_DefenseCoverageHandle];
    _cfg set ["eastGTNDefenseCoverageHandle", FLO_EastGTN_DefenseCoverageHandle];
    _cfg set ["westGTNTempoHandle", FLO_WestGTN_TempoHandle];
    _cfg set ["eastGTNTempoHandle", FLO_EastGTN_TempoHandle];
    _cfg set ["westGTNForceGrowthHandle", FLO_WestGTN_ForceGrowthHandle];
    _cfg set ["eastGTNForceGrowthHandle", FLO_EastGTN_ForceGrowthHandle];
    _cfg set ["westGTNGarrisonHandle", FLO_WestGTN_GarrisonHandle];
    _cfg set ["eastGTNGarrisonHandle", FLO_EastGTN_GarrisonHandle];
    _cfg set ["westFactionTuningHandle", FLO_WestFactionTuningHandle];
    _cfg set ["eastFactionTuningHandle", FLO_EastFactionTuningHandle];
    _cfg set ["objectiveSizeThreshold", FLO_ObjectiveSizeThreshold];
    _cfg set ["virtualizationDistance", FLO_VirtualizationDistance];
    _cfg set ["virtualizationUnitCap", FLO_VirtualizationUnitCap];
    _cfg set ["startingTerritoryWestRatio", FLO_StartingTerritoryWestRatio];
    _cfg set ["startPosition", FLO_MissionConfig get "startPosition"];
    _data set ["config", _cfg];
    ["SAVE", 3, format ["Config: %1 items", count keys _cfg]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Config failed: %1", _exception]; };

// ============================================================================
// SAVE: MARKERS
// ============================================================================

try {
    private _markerHash = createHashMap;
    private _exclude = createHashMapFromArray [["b_unknown", true], ["Empty", true], ["mil_dot", true], ["hd_start", true]];
    private _combatMarkerPrefix = "FLO_GTN_COMBAT_";
    private _minefieldMarkerPrefix = "FLO_MINEFIELD_";
    private _markers = allMapMarkers select {
        !(_exclude getOrDefault [markerType _x, false])
        && {markerAlpha _x > 0.01}
        && {_x find _combatMarkerPrefix != 0}
        && {_x find _minefieldMarkerPrefix != 0}
    };
    {
        _markerHash set [_x, createHashMapFromArray [
            ["alpha", markerAlpha _x], ["brush", markerBrush _x], ["color", getMarkerColor _x],
            ["dir", markerDir _x], ["pos", getMarkerPos _x], ["shape", markerShape _x],
            ["size", getMarkerSize _x], ["text", markerText _x], ["type", markerType _x]
        ]];
    } forEach _markers;
    _data set ["markers", _markerHash];
    ["SAVE", 3, format ["Markers: %1", count _markers]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Markers failed: %1", _exception]; };

// ============================================================================
// SAVE: VEHICLES (around installations)
// ============================================================================

private _campaignState = [_installationMarkers, _saveRadius] call FLO_fnc_saveCaptureCampaignState;
_data set ["vehicles", _campaignState get "vehicles"];

// ============================================================================
// SAVE: OBJECTS (around installations)
// ============================================================================

try {
    private _objHash = createHashMap;
    private _savedObjIds = createHashMap;
    private _skippedWeaponHolders = 0;

    // Exclude crates that are handled elsewhere
    private _excludeCrates = createHashMapFromArray [
        ["Box_NATO_WpsSpecial_F", true], ["Box_NATO_AmmoOrd_F", true],
        ["Box_NATO_Ammo_F", true], ["Box_NATO_Wps_F", true], ["VirtualReammoBox_small_F", true]
    ];

    // Exclude FOB/OP container types - they are saved as part of FOB/OP data
    private _excludeContainers = createHashMap;
    _excludeContainers set [FLO_FactionFobTerminalType, true];
    _excludeContainers set [FLO_FactionCopTerminalType, true];
    // Also exclude common fallback container types
    _excludeContainers set ["Land_TripodScreen_01_large_sand_F", true];
    _excludeContainers set ["Land_Cargo20_military_green_F", true];
    _excludeContainers set ["Land_Cargo10_military_green_F", true];

    {
        private _nearObjs = (getMarkerPos _x) nearEntities [["Static", "Thing", "ReammoBox_F"], _saveRadius];
        {
            private _obj = _x;
            private _objType = typeOf _obj;

            // This snapshot owns structures, not temporary dropped inventory.
            if ([_objType] call FLO_fnc_saveIsWeaponHolderClass) then {
                _skippedWeaponHolders = _skippedWeaponHolders + 1;
                continue;
            };

            // Skip if: not alive, in exclusion lists, marked as crate, temp object, or IDS placed entity
            if (alive _obj &&
                { !(_excludeCrates getOrDefault [_objType, false]) } &&
                { !(_excludeContainers getOrDefault [_objType, false]) } &&
                { !(_obj getVariable ["FLO_save_crate", false]) } &&
                { !(_obj getVariable ["FLO_temp_object", false]) } &&
                { !(_obj getVariable ["IDS_Logistics_isPlacedEntity", false]) }) then {

                private _existingId = _obj getVariable ["FLO_SaveID", ""];
                if (_existingId == "" || !(_savedObjIds getOrDefault [_existingId, false])) then {
                    private _id = if (_existingId != "") then { _existingId } else { [] call FLO_fnc_createUUID };
                    _obj setVariable ["FLO_SaveID", _id, true];
                    _savedObjIds set [_id, true];
                    private _hadAICrew = ({ alive _x && {!isPlayer _x} } count (crew _obj)) > 0;
                    _objHash set [_id, createHashMapFromArray [
                        ["type", _objType], ["posASL", getPosASL _obj],
                        ["vectorDirAndUp", [vectorDir _obj, vectorUp _obj]],
                        ["damage", damage _obj], ["hadAICrew", _hadAICrew]
                    ]];
                };
            };
        } forEach _nearObjs;
    } forEach _installationMarkers;
    _data set ["objects", _objHash];
    ["SAVE", 3, format ["Objects: %1; excluded weapon-holder candidates: %2", count _objHash, _skippedWeaponHolders]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Objects failed: %1", _exception]; };

// ============================================================================
// SAVE: SUPPLY CRATES
// ============================================================================

_data set ["crates", _campaignState get "crates"];

// ============================================================================
// SAVE: COMMANDER MINEFIELDS
// ============================================================================

try {
    private _minefieldArray = [];

    if (!isNil "FLO_Minefields" && {FLO_Minefields isEqualType createHashMap}) then {
        {
            private _serialized = [_y] call FLO_fnc_minefieldSerializeField;
            if ((keys _serialized) isNotEqualTo []) then {
                [_serialized, count _minefieldArray] call FLO_fnc_minefieldValidateSavedField;
                _minefieldArray pushBack _serialized;
            };
        } forEach FLO_Minefields;
    };

    _data set ["minefields", _minefieldArray];

    if !(FLO_MinefieldObjectiveCooldowns isEqualType createHashMap) then {
        throw format [
            "Minefield objective cooldowns have invalid type %1",
            typeName FLO_MinefieldObjectiveCooldowns
        ];
    };
    _data set ["minefieldObjectiveCooldowns", FLO_MinefieldObjectiveCooldowns];

    ["SAVE", 3, format ["Commander minefields: %1", count _minefieldArray]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Commander minefields failed: %1", _exception]; };

// ============================================================================
// SAVE: STRUCTURES (FOBs, OPs)
// ============================================================================

_data set ["fobs", _campaignState get "fobs"];
_data set ["ops", _campaignState get "ops"];

// ============================================================================
// SAVE: BASE DEPLOYMENT STATE
// ============================================================================

try {
    _data set ["baseDeploymentState", _campaignState get "baseDeploymentState"];
    ["SAVE", 3, "Base deployment state saved"] call FLO_fnc_log;
} catch { throw format ["[SAVE] Base deployment state failed: %1", _exception]; };

// ============================================================================
// SAVE: SIDE RESOURCES
// ============================================================================

try {
    private _sideResData = _campaignState get "sideResources";
        _data set ["sideResources", _sideResData];
        ["SAVE", 3, format ["Side resources saved for %1 sides", count (keys _sideResData)]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Resources failed: %1", _exception]; };

// ============================================================================
// SAVE: LOGISTICS NETWORK
// ============================================================================

try {
    private _bySide = _campaignState get "logisticsNetworkBySide";
        _data set ["logisticsNetworkBySide", _bySide];
        ["SAVE", 3, format ["Logistics: saved %1 side contexts", count (keys _bySide)]] call FLO_fnc_log;
} catch { throw format ["[SAVE] Logistics failed: %1", _exception]; };

// ============================================================================
// SAVE: VIRTUAL GROUPS
// ============================================================================

try {
    private _vgHash = [_campaignState get "virtualGroups", _campaignState get "capturedAtTick"] call FLO_fnc_virtualizationSerializeRegistry;
    _data set ["virtualGroups", _vgHash];
    ["SAVE", 3, format ["Virtual Groups: %1", count _vgHash]] call FLO_fnc_log;
} catch {
    throw format ["[SAVE] Virtual Groups failed: %1", _exception];
};

// ============================================================================
// SAVE: OBJECTIVES AND AI COMMANDERS
// ============================================================================

try {
    _data set ["objectives", _campaignState get "objectives"];
    _data set ["aiCommanders", _campaignState get "aiCommanders"];
    ["SAVE", 3, "Objectives and dual GTN state saved"] call FLO_fnc_log;
} catch { throw format ["[SAVE] Objectives/GTN failed: %1", _exception]; };

// ============================================================================
// SAVE: IDS LOGISTICS PLACED ENTITIES
// ============================================================================

try {
    if !(IDS_Logistics_PlacedEntities isEqualType []) then {
        throw format [
            "IDS Logistics registry has invalid type %1",
            typeName IDS_Logistics_PlacedEntities
        ];
    };
    private _idsEntities = [];
    {
        if (!isNull _x && alive _x) then {
            _idsEntities pushBack createHashMapFromArray [
                ["class", typeOf _x],
                ["posASL", getPosASL _x],
                ["direction", getDir _x],
                ["vectorUp", vectorUp _x],
                ["damage", damage _x]
            ];
        };
    } forEach IDS_Logistics_PlacedEntities;
    _data set ["idsLogisticsEntities", _idsEntities];
    ["SAVE", 3, format ["IDS Logistics: %1 placed entities", count _idsEntities]] call FLO_fnc_log;
} catch { throw format ["[SAVE] IDS Logistics failed: %1", _exception]; };

// ============================================================================
// FINALIZATION
// ============================================================================

[_data] call FLO_fnc_saveValidateCampaignRoot;
if !([_data] call FLO_fnc_saveCommitCampaignData) exitWith { false };
true

};
} catch {
    _saveException = _exception;
};

if (_saveException != "") then {
    _saveResult = false;
};
if (isNil "_saveResult") then { _saveResult = false; _saveException = "Save returned no transaction outcome" };
if !(_saveResult isEqualType true) then { _saveResult = false; _saveException = "Save returned an invalid transaction outcome" };
if (_saveException == "" && {!_saveResult}) then { _saveException = "Campaign validation or disk write rejected; see preceding SAVE error" };
[_saveResult, _saveException] call FLO_fnc_saveFinish
