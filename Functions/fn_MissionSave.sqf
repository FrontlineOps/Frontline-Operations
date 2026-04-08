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

if (!isServer) exitWith { false };

private _saveStartTime = diag_tickTime;
private _saveVersion = 19;

["SAVE", 3, "Starting mission save..."] call FLO_fnc_log;

// Create fresh save data
private _data = createHashMap;
_data set ["saveVersion", _saveVersion];
_data set ["saveTimestamp", systemTimeUTC];
_data set ["time", date];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

private _fnc_getCompressedDamage = {
    params ["_vehicle"];
    private _result = [];
    private _allDamage = getAllHitPointsDamage _vehicle;
    if (count _allDamage >= 3) then {
        private _names = _allDamage # 0;
        private _values = _allDamage # 2;
        { if ((_values # _forEachIndex) > 0.01) then { _result pushBack [_x, _values # _forEachIndex]; }; } forEach _names;
    };
    _result
};

private _fnc_getAllCargo = {
    params ["_container"];
    private _items = [];
    (getWeaponCargo _container) params [["_wC", []], ["_wN", []]];
    { _items pushBack [_x, _wN # _forEachIndex, "weapon"]; } forEach _wC;
    (getMagazineCargo _container) params [["_mC", []], ["_mN", []]];
    { _items pushBack [_x, _mN # _forEachIndex, "magazine"]; } forEach _mC;
    (getItemCargo _container) params [["_iC", []], ["_iN", []]];
    { _items pushBack [_x, _iN # _forEachIndex, "item"]; } forEach _iC;
    (getBackpackCargo _container) params [["_bC", []], ["_bN", []]];
    { _items pushBack [_x, _bN # _forEachIndex, "backpack"]; } forEach _bC;
    _items select { (_x # 1) > 0 }
};

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
    _cfg set ["friendlyHandle", FLO_FriendlyHandle];
    _cfg set ["enemyHandle", FLO_EnemyHandle];
    _cfg set ["civilianHandle", FLO_CivilianHandle];
    _cfg set ["moneyHandle", FLO_MoneyHandle];
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
    _cfg set ["objectiveSizeThreshold", FLO_ObjectiveSizeThreshold];
    _cfg set ["virtualizationDistance", FLO_VirtualizationDistance];
    _cfg set ["virtualizationUnitCap", FLO_VirtualizationUnitCap];
    _cfg set ["startingTerritoryWestRatio", FLO_StartingTerritoryWestRatio];
    _cfg set ["enemyPrec", EnemyPrec];
    if (!isNil "F_HQ_01") then { _cfg set ["fobType", F_HQ_01]; };
    if (!isNil "F_HQ_C_01") then { _cfg set ["fobContainerType", F_HQ_C_01]; };
    if (!isNil "F_OP_01") then { _cfg set ["opType", F_OP_01]; };
    if (!isNil "F_OP_C_01") then { _cfg set ["opContainerType", F_OP_C_01]; };
    _data set ["config", _cfg];
    ["SAVE", 3, format ["Config: %1 items", count keys _cfg]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Config failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: MARKERS
// ============================================================================

try {
    private _markerHash = createHashMap;
    private _exclude = createHashMapFromArray [["b_unknown", true], ["Empty", true], ["mil_dot", true], ["hd_start", true]];
    private _combatMarkerPrefix = "FLO_GTN_COMBAT_";
    private _markers = allMapMarkers select {
        !(_exclude getOrDefault [markerType _x, false])
        && {markerAlpha _x > 0.01}
        && {_x find _combatMarkerPrefix != 0}
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
} catch { ["SAVE", 1, format ["Markers failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: VEHICLES (around installations)
// ============================================================================

try {
    private _vehHash = createHashMap;
    private _savedIds = createHashMap;
    {
        private _nearVehs = (getMarkerPos _x) nearEntities [["Air", "Ship", "LandVehicle"], _saveRadius];
        {
            private _veh = _x;
            if (alive _veh && { count (crew _veh select { isPlayer _x }) == 0 }) then {
                private _existingId = _veh getVariable ["FLO_SaveID", ""];
                if (_existingId == "" || !(_savedIds getOrDefault [_existingId, false])) then {
                    private _id = if (_existingId != "") then { _existingId } else { [] call FLO_fnc_createUUID };
                    _veh setVariable ["FLO_SaveID", _id, true];
                    _savedIds set [_id, true];
                    private _hadAICrew = ({ alive _x && {!isPlayer _x} } count (crew _veh)) > 0;
                    _vehHash set [_id, createHashMapFromArray [
                        ["type", typeOf _veh], ["posATL", getPosATL _veh], ["fuel", fuel _veh],
                        ["damage", damage _veh], ["damagedHitpoints", [_veh] call _fnc_getCompressedDamage],
                        ["vectorDirAndUp", [vectorDir _veh, vectorUp _veh]], ["locked", locked _veh], ["engineOn", isEngineOn _veh],
                        ["hadAICrew", _hadAICrew]
                    ]];
                };
            };
        } forEach _nearVehs;
    } forEach _installationMarkers;
    _data set ["vehicles", _vehHash];
    ["SAVE", 3, format ["Vehicles: %1", count _vehHash]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Vehicles failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: OBJECTS (around installations)
// ============================================================================

try {
    private _objHash = createHashMap;
    private _savedObjIds = createHashMap;

    // Exclude crates that are handled elsewhere
    private _excludeCrates = createHashMapFromArray [
        ["Box_NATO_WpsSpecial_F", true], ["Box_NATO_AmmoOrd_F", true],
        ["Box_NATO_Ammo_F", true], ["Box_NATO_Wps_F", true], ["VirtualReammoBox_small_F", true]
    ];

    // Exclude FOB/OP container types - they are saved as part of FOB/OP data
    private _excludeContainers = createHashMap;
    if (!isNil "F_HQ_C_01") then { _excludeContainers set [F_HQ_C_01, true]; };
    if (!isNil "F_OP_C_01") then { _excludeContainers set [F_OP_C_01, true]; };
    // Also exclude common fallback container types
    _excludeContainers set ["Land_TripodScreen_01_large_sand_F", true];
    _excludeContainers set ["Land_Cargo20_military_green_F", true];
    _excludeContainers set ["Land_Cargo10_military_green_F", true];

    {
        private _nearObjs = (getMarkerPos _x) nearEntities [["Static", "Thing", "ReammoBox_F"], _saveRadius];
        {
            private _obj = _x;
            private _objType = typeOf _obj;

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
    ["SAVE", 3, format ["Objects: %1", count _objHash]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Objects failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: SUPPLY CRATES
// ============================================================================

try {
    private _crateHash = createHashMap;
    private _saveCrates = (entities "ReammoBox_F") select { alive _x && { _x getVariable ["FLO_save_crate", false] } };
    {
        private _id = [] call FLO_fnc_createUUID;
        _x setVariable ["FLO_SaveID", _id, true];
        private _items = [_x] call _fnc_getAllCargo;
        _x setVariable ["FLO_crate_items", _items, true];
        _crateHash set [_id, createHashMapFromArray [
            ["type", typeOf _x], ["posASL", getPosASL _x],
            ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
            ["items", _items], ["damage", damage _x], ["locked", locked _x]
        ]];
    } forEach _saveCrates;
    _data set ["crates", _crateHash];
    ["SAVE", 3, format ["Crates: %1", count _crateHash]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Crates failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: STRUCTURES (FOBs, OPs)
// ============================================================================

try {
    private _fobArray = [];
    private _opArray = [];
    private _fobType = if (!isNil "F_HQ_01") then { F_HQ_01 } else { "" };
    private _fobContainerType = if (!isNil "F_HQ_C_01") then { F_HQ_C_01 } else { "" };
    private _opType = if (!isNil "F_OP_01") then { F_OP_01 } else { "" };
    private _opContainerType = if (!isNil "F_OP_C_01") then { F_OP_C_01 } else { "" };

    // Find and save FOBs with their containers
    if (_fobType != "") then {
        private _allFobContainers = if (_fobContainerType != "") then { allMissionObjects _fobContainerType } else { [] };
        {
            if (!isNull _x && alive _x && { _x getVariable ["FLO_FOB_Initialized", false] }) then {
                private _building = _x;
                private _marker = _building getVariable ["fobMarkerName", ""];

                // Find the container that's near this FOB
                private _nearContainer = objNull;
                {
                    if (_x distance _building < 20) exitWith { _nearContainer = _x; };
                } forEach _allFobContainers;

                // Save full FOB data
                private _fobData = createHashMapFromArray [
                    ["buildingType", typeOf _building],
                    ["buildingPosASL", getPosASL _building],
                    ["buildingDir", getDir _building],
                    ["buildingVectorUp", vectorUp _building],
                    ["markerName", _marker]
                ];

                // Add container data if found
                if (!isNull _nearContainer) then {
                    _fobData set ["containerType", typeOf _nearContainer];
                    _fobData set ["containerPosASL", getPosASL _nearContainer];
                    _fobData set ["containerDir", getDir _nearContainer];
                    _fobData set ["containerVectorUp", vectorUp _nearContainer];
                };

                _fobArray pushBack _fobData;
            };
        } forEach (allMissionObjects _fobType);
    };

    // Find and save OPs with their containers
    if (_opType != "") then {
        private _allOpContainers = if (_opContainerType != "") then { allMissionObjects _opContainerType } else { [] };
        {
            if (!isNull _x && alive _x && { _x getVariable ["FLO_OP_Initialized", false] }) then {
                private _building = _x;
                private _marker = _building getVariable ["opMarkerName", ""];

                // Find the container that's near this OP
                private _nearContainer = objNull;
                {
                    if (_x distance _building < 15) exitWith { _nearContainer = _x; };
                } forEach _allOpContainers;

                // Save full OP data
                private _opData = createHashMapFromArray [
                    ["buildingType", typeOf _building],
                    ["buildingPosASL", getPosASL _building],
                    ["buildingDir", getDir _building],
                    ["buildingVectorUp", vectorUp _building],
                    ["markerName", _marker]
                ];

                // Add container data if found
                if (!isNull _nearContainer) then {
                    _opData set ["containerType", typeOf _nearContainer];
                    _opData set ["containerPosASL", getPosASL _nearContainer];
                    _opData set ["containerDir", getDir _nearContainer];
                    _opData set ["containerVectorUp", vectorUp _nearContainer];
                };

                _opArray pushBack _opData;
            };
        } forEach (allMissionObjects _opType);
    };

    _data set ["fobs", _fobArray];
    _data set ["ops", _opArray];
    _data set ["structureTypes", [_fobType, _fobContainerType, _opType, _opContainerType]];
    ["SAVE", 3, format ["Structures: %1 FOBs, %2 OPs", count _fobArray, count _opArray]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Structures failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: PLAYER STATES
// ============================================================================

try {
    private _playerHash = createHashMap;
    if (!isNil "FLO_PersistentPlayerStates") then {
        {
            _playerHash set [_x, FLO_PersistentPlayerStates get _x];
        } forEach (keys FLO_PersistentPlayerStates);
    };
    private _playerVehicleHash = createHashMap;
    if (!isNil "FLO_PersistentPlayerVehicles") then {
        {
            _playerVehicleHash set [_x, FLO_PersistentPlayerVehicles get _x];
        } forEach (keys FLO_PersistentPlayerVehicles);
    };

    {
        private _uid = getPlayerUID _x;
        if (_uid != "") then {
            private _playerState = [_x] call FLO_fnc_buildSavedPlayerState;
            _playerHash set [_uid, _playerState];

            private _vehicleSaveId = _playerState get "vehicleSaveId";
            if (_vehicleSaveId != "") then {
                if !(_vehicleSaveId in _playerVehicleHash) then {
                    _playerVehicleHash set [_vehicleSaveId, [vehicle _x] call FLO_fnc_buildSavedPlayerVehicleState];
                };
            };
        };
    } forEach allPlayers;

    _data set ["players", _playerHash];
    _data set ["playerVehicles", _playerVehicleHash];
    ["SAVE", 3, format ["Players: %1 states, %2 player vehicles", count (keys _playerHash), count (keys _playerVehicleHash)]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Player states failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: SIDE RESOURCES
// ============================================================================

try {
    if (!isNil "FLO_SideResources") then {
        private _sideResData = createHashMap;
        {
            private _obj = FLO_SideResources get _x;
            if (!isNil "_obj") then {
                _sideResData set [_x, _obj call ["serialize", []]];
            };
        } forEach (keys FLO_SideResources);
        _data set ["sideResources", _sideResData];
        ["SAVE", 3, format ["Side resources saved for %1 sides", count (keys _sideResData)]] call FLO_fnc_log;
    };
} catch { ["SAVE", 1, format ["Resources failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: LOGISTICS NETWORK
// ============================================================================

try {
    if (!isNil "FLO_Logistics_Networks" && {FLO_Logistics_Networks isEqualType createHashMap} && {count (keys FLO_Logistics_Networks) > 0}) then {
        private _bySide = createHashMap;
        {
            private _obj = FLO_Logistics_Networks get _x;
            if (!isNil "_obj") then {
                _bySide set [_x, _obj call ["serialize", []]];
            };
        } forEach (keys FLO_Logistics_Networks);
        _data set ["logisticsNetworkBySide", _bySide];
        ["SAVE", 3, format ["Logistics: saved %1 side contexts", count (keys _bySide)]] call FLO_fnc_log;
    };
} catch { ["SAVE", 1, format ["Logistics failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: VIRTUAL GROUPS
// ============================================================================

try {
    private _vgHash = createHashMap;
    if (!isNil "FLO_virtualGroups") then {
        private _groups = FLO_virtualGroups get "_groups";
        if (!isNil "_groups" && { _groups isEqualType createHashMap }) then {
            {
                private _gData = _y;
                if (!isNil "_gData" && { _gData isEqualType createHashMap }) then {
                    _vgHash set [_x, [_gData] call FLO_fnc_virtualizationSerializeGroup];
                };
            } forEach _groups;
        };
    };
    _data set ["virtualGroups", _vgHash];
    ["SAVE", 3, format ["Virtual Groups: %1", count _vgHash]] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Virtual Groups failed: %1", _exception]] call FLO_fnc_log; _data set ["virtualGroups", createHashMap]; };

// ============================================================================
// SAVE: OBJECTIVES AND AI COMMANDERS
// ============================================================================

try {
    if (!isNil "FLO_Objectives") then { _data set ["objectives", FLO_Objectives]; };
    if (!isNil "FLO_GTN_ResourceManager") then {
        private _allCommanders = FLO_GTN_ResourceManager call ["_getAllCommanders", []];
        private _eastEnabled = !isNil {_allCommanders getOrDefault ["EAST", nil]};
        private _westEnabled = !isNil {_allCommanders getOrDefault ["WEST", nil]};
        private _aiCommanders = createHashMapFromArray [
            ["EAST", createHashMapFromArray [["gtnEnabled", _eastEnabled]]],
            ["WEST", createHashMapFromArray [["gtnEnabled", _westEnabled]]]
        ];
        _data set ["aiCommanders", _aiCommanders];
    };
    ["SAVE", 3, "Objectives and dual GTN state saved"] call FLO_fnc_log;
} catch { ["SAVE", 1, format ["Objectives/GTN failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// SAVE: IDS LOGISTICS PLACED ENTITIES
// ============================================================================

try {
    if (!isNil "IDS_Logistics_PlacedEntities" && {count IDS_Logistics_PlacedEntities > 0}) then {
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
    };
} catch { ["SAVE", 1, format ["IDS Logistics failed: %1", _exception]] call FLO_fnc_log; };

// ============================================================================
// FINALIZATION
// ============================================================================

private _requiredKeys = ["time", "markers", "vehicles", "objects"];
private _isValid = true;
{ if (!(_x in _data)) then { _isValid = false; ["SAVE", 1, format ["Missing key: %1", _x]] call FLO_fnc_log; }; } forEach _requiredKeys;

if (_isValid) then {
    try {
        missionProfileNamespace setVariable ["FLO_MissionData", _data];
        saveMissionProfileNamespace;
        private _saveTime = diag_tickTime - _saveStartTime;
        ["SAVE", 3, format ["Save complete in %1s", round (_saveTime * 100) / 100]] call FLO_fnc_log;
        ["flo_mission_save_completed", [true, _data]] call CBA_fnc_globalEvent;
        true
    } catch {
        ["SAVE", 1, format ["Write failed: %1", _exception]] call FLO_fnc_log;
        false
    };
} else {
    ["SAVE", 1, "Validation failed"] call FLO_fnc_log;
    false
};
