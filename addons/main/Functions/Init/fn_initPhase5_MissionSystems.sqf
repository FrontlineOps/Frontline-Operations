/*
 * Function: FLO_fnc_initPhase5_MissionSystems
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 5: Start all active mission systems (AI commander, startup systems, etc.)
 *   This runs AFTER objectives are indexed and virtualization is complete.
 *   Also handles MissionStartup (FOBs, OPs, etc.) and entity restoration from saves.
 *
 * Arguments: None
 * Returns: Boolean - True if systems started successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P5] Starting mission systems...";

// Verify prerequisites
if (isNil "FLO_Objectives" || {FLO_Objectives isEqualTo []}) exitWith {
    FLO_InitError = "Cannot start mission systems - no objectives";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P5] ERROR: %1", FLO_InitError];
    false
};

if (isNil "InitializationOG" || {!InitializationOG}) exitWith {
    FLO_InitError = "Cannot start mission systems - virtualization not complete";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P5] ERROR: %1", FLO_InitError];
    false
};

// The configured campaign side is authoritative for runtime human groups.
if !(FLO_ActivePlayerSide in [east, west]) exitWith {
    FLO_InitError = "Cannot start mission systems without a configured player side";
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

["INIT", 3, format ["Human lobby slots target campaign side %1", [FLO_ActivePlayerSide] call FLO_fnc_sideKey]] call FLO_fnc_log;

// Initialize side resources early so restored/started systems can consume them.
if (([] call FLO_fnc_initSideResourcesUninitialized) && {!isNil "FLO_fnc_sideResources"}) then {
    [] call FLO_fnc_sideResources;
};

// ============================================
// RESTORE FOBs AND OPs FROM SAVE
// ============================================
if (FLO_IsLoadedSave) then {
    diag_log "[FLO_INIT_P5] Restoring FOBs and OPs from save...";

    private _savedData = FLO_SavedGameData;
    private _requiredBaseRecordTypes = [
        ["buildingType", ""],
        ["buildingPosASL", []],
        ["buildingDir", 0],
        ["buildingVectorUp", []],
        ["markerName", ""],
        ["baseSideKey", ""],
        ["baseSaveId", ""],
        ["logisticsNodeId", ""]
    ];
    private _containerRecordTypes = [
        ["containerType", ""],
        ["containerPosASL", []],
        ["containerDir", 0],
        ["containerVectorUp", []]
    ];
    private _requiredBaseRecordFields = _requiredBaseRecordTypes apply { _x # 0 };
    private _containerRecordFields = _containerRecordTypes apply { _x # 0 };

    // Restore FOBs
    private _fobArray = _savedData get "fobs";
    {
        private _fobData = _x;
        if !(_fobData isEqualType createHashMap) then {
            throw format ["Saved FOB %1 has invalid record type %2", _forEachIndex, typeName _fobData];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _fobData) then {
                throw format ["Saved FOB %1 is missing required field %2", _forEachIndex, _field];
            };
            private _value = _fobData get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved FOB %1 field %2 has invalid type %3", _forEachIndex, _field, typeName _value];
            };
        } forEach _requiredBaseRecordTypes;
        private _containerFieldCount = {_x # 0 in _fobData} count _containerRecordTypes;
        if !(_containerFieldCount in [0, count _containerRecordTypes]) then {
            throw format ["Saved FOB %1 has an incomplete container record", _forEachIndex];
        };
        if (_containerFieldCount > 0) then {
            {
                _x params ["_field", "_prototype"];
                private _value = _fobData get _field;
                if !(_value isEqualType _prototype) then {
                    throw format ["Saved FOB %1 field %2 has invalid type %3", _forEachIndex, _field, typeName _value];
                };
            } forEach _containerRecordTypes;
        };
        private _allowedFobFields = +_requiredBaseRecordFields;
        if (_containerFieldCount > 0) then {
            _allowedFobFields append _containerRecordFields;
        };
        private _unexpectedFobFields = (keys _fobData) select {
            !(_x in _allowedFobFields)
        };
        if (_unexpectedFobFields isNotEqualTo []) then {
            throw format [
                "Saved FOB %1 has unexpected fields %2",
                _forEachIndex,
                _unexpectedFobFields
            ];
        };

        private _buildingType = _fobData get "buildingType";
        private _buildingPos = _fobData get "buildingPosASL";
        private _baseSideKey = _fobData get "baseSideKey";
        private _baseSaveId = _fobData get "baseSaveId";
        private _logisticsNodeId = _fobData get "logisticsNodeId";
        if (
            _buildingType == ""
            || {!isClass (configFile >> "CfgVehicles" >> _buildingType)}
            || {(count _buildingPos) < 2}
            || {!(_baseSideKey in ["EAST", "WEST"])}
            || {_baseSaveId == ""}
            || {_logisticsNodeId == ""}
        ) then {
            throw format ["Saved FOB %1 has invalid required values", _forEachIndex];
        };

        private _building = createVehicle [_buildingType, [0,0,0], [], 0, "CAN_COLLIDE"];
        if (isNull _building) then {
            throw format ["Failed to restore saved FOB %1 of type %2", _forEachIndex, _buildingType];
        };
        _building setPosASL _buildingPos;
        _building setDir (_fobData get "buildingDir");
        _building setVectorUp (_fobData get "buildingVectorUp");
        _building setVariable ["FLO_BaseSide", [_baseSideKey] call FLO_fnc_campaignSideFromKey, true];
        _building setVariable ["FLO_BaseType", "FOB", true];
        _building setVariable ["FLO_BaseSaveId", _baseSaveId, true];
        _building setVariable ["FLO_LogisticsNodeId", _logisticsNodeId, true];

        private _markerName = _fobData get "markerName";
        if (_markerName != "") then {
            _building setVariable ["fobMarkerName", _markerName, true];
            _building setVariable ["FLO_FOB_MarkersRestored", true, true];
        };

        if (_containerFieldCount > 0) then {
            private _containerType = _fobData get "containerType";
            if (_containerType == "" || {!isClass (configFile >> "CfgVehicles" >> _containerType)}) then {
                throw format ["Saved FOB %1 has invalid container type %2", _forEachIndex, _containerType];
            };
            private _container = createVehicle [_containerType, [0,0,0], [], 0, "CAN_COLLIDE"];
            if (isNull _container) then {
                throw format ["Failed to restore saved FOB %1 container type %2", _forEachIndex, _containerType];
            };
            _container setPosASL (_fobData get "containerPosASL");
            _container setDir (_fobData get "containerDir");
            _container setVectorUp (_fobData get "containerVectorUp");
        };
    } forEach _fobArray;

    ["INIT", 3, format ["Restored %1 FOBs from current save", count _fobArray]] call FLO_fnc_log;

    // Restore OPs
    private _opArray = _savedData get "ops";
    {
        private _opData = _x;
        if !(_opData isEqualType createHashMap) then {
            throw format ["Saved OP %1 has invalid record type %2", _forEachIndex, typeName _opData];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _opData) then {
                throw format ["Saved OP %1 is missing required field %2", _forEachIndex, _field];
            };
            private _value = _opData get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved OP %1 field %2 has invalid type %3", _forEachIndex, _field, typeName _value];
            };
        } forEach _requiredBaseRecordTypes;
        private _containerFieldCount = {_x # 0 in _opData} count _containerRecordTypes;
        if !(_containerFieldCount in [0, count _containerRecordTypes]) then {
            throw format ["Saved OP %1 has an incomplete container record", _forEachIndex];
        };
        if (_containerFieldCount > 0) then {
            {
                _x params ["_field", "_prototype"];
                private _value = _opData get _field;
                if !(_value isEqualType _prototype) then {
                    throw format ["Saved OP %1 field %2 has invalid type %3", _forEachIndex, _field, typeName _value];
                };
            } forEach _containerRecordTypes;
        };
        private _allowedOpFields = +_requiredBaseRecordFields;
        if (_containerFieldCount > 0) then {
            _allowedOpFields append _containerRecordFields;
        };
        private _unexpectedOpFields = (keys _opData) select {
            !(_x in _allowedOpFields)
        };
        if (_unexpectedOpFields isNotEqualTo []) then {
            throw format [
                "Saved OP %1 has unexpected fields %2",
                _forEachIndex,
                _unexpectedOpFields
            ];
        };

        private _buildingType = _opData get "buildingType";
        private _buildingPos = _opData get "buildingPosASL";
        private _baseSideKey = _opData get "baseSideKey";
        private _baseSaveId = _opData get "baseSaveId";
        private _logisticsNodeId = _opData get "logisticsNodeId";
        if (
            _buildingType == ""
            || {!isClass (configFile >> "CfgVehicles" >> _buildingType)}
            || {(count _buildingPos) < 2}
            || {!(_baseSideKey in ["EAST", "WEST"])}
            || {_baseSaveId == ""}
            || {_logisticsNodeId == ""}
        ) then {
            throw format ["Saved OP %1 has invalid required values", _forEachIndex];
        };

        private _building = createVehicle [_buildingType, [0,0,0], [], 0, "CAN_COLLIDE"];
        if (isNull _building) then {
            throw format ["Failed to restore saved OP %1 of type %2", _forEachIndex, _buildingType];
        };
        _building setPosASL _buildingPos;
        _building setDir (_opData get "buildingDir");
        _building setVectorUp (_opData get "buildingVectorUp");
        _building setVariable ["FLO_BaseSide", [_baseSideKey] call FLO_fnc_campaignSideFromKey, true];
        _building setVariable ["FLO_BaseType", "COP", true];
        _building setVariable ["FLO_BaseSaveId", _baseSaveId, true];
        _building setVariable ["FLO_LogisticsNodeId", _logisticsNodeId, true];

        private _markerName = _opData get "markerName";
        if (_markerName != "") then {
            _building setVariable ["opMarkerName", _markerName, true];
            _building setVariable ["FLO_OP_MarkersRestored", true, true];
        };

        if (_containerFieldCount > 0) then {
            private _containerType = _opData get "containerType";
            if (_containerType == "" || {!isClass (configFile >> "CfgVehicles" >> _containerType)}) then {
                throw format ["Saved OP %1 has invalid container type %2", _forEachIndex, _containerType];
            };
            private _container = createVehicle [_containerType, [0,0,0], [], 0, "CAN_COLLIDE"];
            if (isNull _container) then {
                throw format ["Failed to restore saved OP %1 container type %2", _forEachIndex, _containerType];
            };
            _container setPosASL (_opData get "containerPosASL");
            _container setDir (_opData get "containerDir");
            _container setVectorUp (_opData get "containerVectorUp");
        };
    } forEach _opArray;

    ["INIT", 3, format ["Restored %1 OPs from current save", count _opArray]] call FLO_fnc_log;
};

// ============================================
// MISSION STARTUP (FOBs, OPs, Actions)
// ============================================
// This runs AFTER factions are loaded and FOBs/OPs are restored
diag_log "[FLO_INIT_P5] Running MissionStartup...";
if (!isNil "FLO_fnc_MissionStartup") then {
    [] call FLO_fnc_MissionStartup;
    diag_log "[FLO_INIT_P5] MissionStartup complete";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_MissionStartup not found";
};

[] call FLO_fnc_baseDeployInitializeState;
diag_log "[FLO_INIT_P5] Base deployment state initialized";

// ============================================
// ENTITY RESTORATION FROM SAVE
// ============================================
if (FLO_IsLoadedSave) then {
    diag_log "[FLO_INIT_P5] Restoring entities from save...";

    private _savedData = FLO_SavedGameData;
    private _combatMarkerPrefix = "FLO_GTN_COMBAT_";
    private _staleCombatMarkers = allMapMarkers select { _x find _combatMarkerPrefix == 0 };
    {
        deleteMarker _x;
    } forEach _staleCombatMarkers;
    FLO_GTN_CombatDebugMarkers = createHashMap;
    FLO_GTN_CombatDebugMarkerOrder = [];
    if (_staleCombatMarkers isNotEqualTo []) then {
        diag_log format ["[FLO_INIT_P5] Cleared %1 stale combat debug markers before marker restore", count _staleCombatMarkers];
    };

    // Restore markers
    private _markerHash = _savedData get "markers";
    private _requiredMarkerTypes = [
        ["pos", []], ["type", ""], ["brush", ""], ["shape", ""],
        ["size", []], ["text", ""], ["dir", 0], ["color", ""], ["alpha", 0]
    ];
    private _requiredMarkerFields = _requiredMarkerTypes apply { _x # 0 };
    private _loadedMarkers = 0;
    {
        private _markerName = _x;
        private _attr = _markerHash get _markerName;
        if !(_markerName isEqualType "" && {_markerName != ""}) then {
            throw format ["Current save has invalid marker key %1", _markerName];
        };
        if !(_attr isEqualType createHashMap) then {
            throw format ["Saved marker %1 has invalid record type %2", _markerName, typeName _attr];
        };
        private _unexpectedMarkerFields = (keys _attr) select {
            !(_x in _requiredMarkerFields)
        };
        if (_unexpectedMarkerFields isNotEqualTo []) then {
            throw format [
                "Saved marker %1 has unexpected fields %2",
                _markerName,
                _unexpectedMarkerFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _attr) then {
                throw format ["Saved marker %1 is missing required field %2", _markerName, _field];
            };
            private _value = _attr get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved marker %1 field %2 has invalid type %3", _markerName, _field, typeName _value];
            };
        } forEach _requiredMarkerTypes;

        if ((_markerName find _combatMarkerPrefix) != 0) then {
            if (getMarkerColor _markerName != "") then { deleteMarker _markerName };
            private _marker = createMarker [_markerName, [0,0,0]];
            _marker setMarkerPosLocal (_attr get "pos");
            _marker setMarkerTypeLocal (_attr get "type");
            _marker setMarkerBrushLocal (_attr get "brush");
            _marker setMarkerShapeLocal (_attr get "shape");
            _marker setMarkerSizeLocal (_attr get "size");
            _marker setMarkerTextLocal (_attr get "text");
            _marker setMarkerDirLocal (_attr get "dir");
            _marker setMarkerColorLocal (_attr get "color");
            _marker setMarkerAlpha (_attr get "alpha");
            _loadedMarkers = _loadedMarkers + 1;
        };
    } forEach (keys _markerHash);
    ["INIT", 3, format ["Restored %1 markers from current save", _loadedMarkers]] call FLO_fnc_log;

    // Restore date/time
    private _date = _savedData get "time";
    if (count _date != 5 || {{!(_x isEqualType 0)} count _date > 0}) then {
        throw format ["Current save has malformed mission time %1", _date];
    };
    setDate _date;
    ["INIT", 3, format ["Restored mission time %1", _date]] call FLO_fnc_log;

    call FLO_fnc_operationalClockReset;

    private _trackedCrewTypes = createHashMap;
    private _playerCatalog = FLO_FactionCatalog get ([FLO_ActivePlayerSide] call FLO_fnc_sideKey);
    {
        _trackedCrewTypes set [_x, true];
    } forEach ((_playerCatalog get "staticAA") + (_playerCatalog get "radar"));

    // Restore vehicles
    private _vehHash = _savedData get "vehicles";
    private _requiredVehicleTypes = [
        ["type", ""], ["posATL", []], ["fuel", 0], ["damage", 0],
        ["damagedHitpoints", []], ["vectorDirAndUp", []], ["locked", 0],
        ["engineOn", true], ["hadAICrew", true], ["storeVehicle", true],
        ["mobileRespawnVehicle", true], ["supportVehicleRoles", []]
    ];
    private _requiredVehicleFields = _requiredVehicleTypes apply { _x # 0 };
    private _loadedVehicles = 0;
    {
        private _vehId = _x;
        private _attr = _vehHash get _vehId;
        if !(_vehId isEqualType "" && {_vehId != ""}) then {
            throw format ["Current save has invalid vehicle key %1", _vehId];
        };
        if !(_attr isEqualType createHashMap) then {
            throw format ["Saved vehicle %1 has invalid record type %2", _vehId, typeName _attr];
        };
        private _unexpectedVehicleFields = (keys _attr) select {
            !(_x in _requiredVehicleFields)
        };
        if (_unexpectedVehicleFields isNotEqualTo []) then {
            throw format [
                "Saved vehicle %1 has unexpected fields %2",
                _vehId,
                _unexpectedVehicleFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _attr) then {
                throw format ["Saved vehicle %1 is missing required field %2", _vehId, _field];
            };
            private _value = _attr get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved vehicle %1 field %2 has invalid type %3", _vehId, _field, typeName _value];
            };
        } forEach _requiredVehicleTypes;

        private _type = _attr get "type";
        private _posATL = _attr get "posATL";
        private _vectorDirAndUp = _attr get "vectorDirAndUp";
        if (
            _type == ""
            || {!isClass (configFile >> "CfgVehicles" >> _type)}
            || {(count _posATL) < 2}
            || {count _vectorDirAndUp != 2}
            || {{!(_x isEqualType []) || {count _x != 3}} count _vectorDirAndUp > 0}
        ) then {
            throw format ["Saved vehicle %1 has invalid spatial or class state", _vehId];
        };
        private _damagedHitpoints = _attr get "damagedHitpoints";
        {
            if !(
                _x isEqualType []
                && {count _x == 2}
                && {(_x # 0) isEqualType ""}
                && {(_x # 1) isEqualType 0}
            ) then {
                throw format ["Saved vehicle %1 has malformed hitpoint record %2", _vehId, _x];
            };
        } forEach _damagedHitpoints;

        private _veh = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];
        if (isNull _veh) then {
            throw format ["Failed to restore saved vehicle %1 of type %2", _vehId, _type];
        };
        _veh setVectorDirAndUp _vectorDirAndUp;
        _veh setPosATL _posATL;
        _veh setFuel (_attr get "fuel");
        _veh setDamage (_attr get "damage");
        _veh lock (_attr get "locked");
        _veh setVariable ["FLO_SaveID", _vehId, true];
        if (_attr get "storeVehicle") then {
            _veh setVariable ["FLO_StoreVehicle", true, true];
        };
        if (_attr get "mobileRespawnVehicle") then {
            _veh setVariable ["FLO_MobileRespawnVehicle", true, true];
        };
        private _supportVehicleRoles = _attr get "supportVehicleRoles";
        if (_supportVehicleRoles isNotEqualTo []) then {
            _veh setVariable ["FLO_SupportVehicleRoles", _supportVehicleRoles, true];
        };
        { _x params ["_hp", "_dmg"]; _veh setHitPointDamage [_hp, _dmg]; } forEach _damagedHitpoints;
        if (_attr get "engineOn") then { _veh engineOn true; };
        [_veh, _type, _attr, _trackedCrewTypes] call FLO_fnc_initRestoreTrackedCrew;
        _loadedVehicles = _loadedVehicles + 1;
    } forEach (keys _vehHash);
    ["INIT", 3, format ["Restored %1 vehicles from current save", _loadedVehicles]] call FLO_fnc_log;

    // Restore objects
    private _objHash = _savedData get "objects";
    private _requiredObjectTypes = [
        ["type", ""], ["posASL", []], ["vectorDirAndUp", []],
        ["damage", 0], ["hadAICrew", true]
    ];
    private _requiredObjectFields = _requiredObjectTypes apply { _x # 0 };
    private _loadedObjects = 0;
    {
        private _objId = _x;
        private _attr = _objHash get _objId;
        if !(_objId isEqualType "" && {_objId != ""}) then {
            throw format ["Current save has invalid object key %1", _objId];
        };
        if !(_attr isEqualType createHashMap) then {
            throw format ["Saved object %1 has invalid record type %2", _objId, typeName _attr];
        };
        private _unexpectedObjectFields = (keys _attr) select {
            !(_x in _requiredObjectFields)
        };
        if (_unexpectedObjectFields isNotEqualTo []) then {
            throw format [
                "Saved object %1 has unexpected fields %2",
                _objId,
                _unexpectedObjectFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _attr) then {
                throw format ["Saved object %1 is missing required field %2", _objId, _field];
            };
            private _value = _attr get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved object %1 field %2 has invalid type %3", _objId, _field, typeName _value];
            };
        } forEach _requiredObjectTypes;

        private _type = _attr get "type";
        private _posASL = _attr get "posASL";
        private _vectorDirAndUp = _attr get "vectorDirAndUp";
        if (
            _type == ""
            || {!isClass (configFile >> "CfgVehicles" >> _type)}
            || {(count _posASL) < 2}
            || {count _vectorDirAndUp != 2}
            || {{!(_x isEqualType []) || {count _x != 3}} count _vectorDirAndUp > 0}
        ) then {
            throw format ["Saved object %1 has invalid spatial or class state", _objId];
        };

        private _obj = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];
        if (isNull _obj) then {
            throw format ["Failed to restore saved object %1 of type %2", _objId, _type];
        };
        _obj setVectorDirAndUp _vectorDirAndUp;
        _obj setPosASL _posASL;
        _obj setDamage (_attr get "damage");
        _obj setVariable ["FLO_SaveID", _objId, true];
        [_obj, _type, _attr, _trackedCrewTypes] call FLO_fnc_initRestoreTrackedCrew;
        _loadedObjects = _loadedObjects + 1;
    } forEach (keys _objHash);
    ["INIT", 3, format ["Restored %1 objects from current save", _loadedObjects]] call FLO_fnc_log;

    // Restore supply crates
    private _crateHash = _savedData get "crates";
    private _requiredCrateTypes = [
        ["type", ""], ["posASL", []], ["vectorDirAndUp", []],
        ["items", []], ["damage", 0], ["locked", 0]
    ];
    private _shipmentRecordTypes = [
        ["logisticsShipment", true], ["logisticsDelivered", true],
        ["logisticsSideKey", ""], ["logisticsOriginNodeId", ""],
        ["logisticsThroughput", 0], ["logisticsContributorUID", ""],
        ["logisticsContributorName", ""], ["developmentTargetObjectiveId", ""]
    ];
    private _requiredCrateFields = _requiredCrateTypes apply { _x # 0 };
    private _shipmentRecordFields = _shipmentRecordTypes apply { _x # 0 };
    private _loadedCrates = 0;
    {
        private _crateId = _x;
        private _attr = _crateHash get _crateId;
        if !(_crateId isEqualType "" && {_crateId != ""}) then {
            throw format ["Current save has invalid crate key %1", _crateId];
        };
        if !(_attr isEqualType createHashMap) then {
            throw format ["Saved crate %1 has invalid record type %2", _crateId, typeName _attr];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _attr) then {
                throw format ["Saved crate %1 is missing required field %2", _crateId, _field];
            };
            private _value = _attr get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved crate %1 field %2 has invalid type %3", _crateId, _field, typeName _value];
            };
        } forEach _requiredCrateTypes;
        private _shipmentFieldCount = {_x # 0 in _attr} count _shipmentRecordTypes;
        if !(_shipmentFieldCount in [0, count _shipmentRecordTypes]) then {
            throw format ["Saved crate %1 has an incomplete logistics-shipment record", _crateId];
        };
        if (_shipmentFieldCount > 0) then {
            {
                _x params ["_field", "_prototype"];
                private _value = _attr get _field;
                if !(_value isEqualType _prototype) then {
                    throw format ["Saved shipment %1 field %2 has invalid type %3", _crateId, _field, typeName _value];
                };
            } forEach _shipmentRecordTypes;
            if !(_attr get "logisticsShipment") then {
                throw format ["Saved crate %1 has a false logistics-shipment discriminator", _crateId];
            };
            if !((_attr get "logisticsSideKey") in ["EAST", "WEST"]) then {
                throw format ["Saved shipment %1 has invalid side key", _crateId];
            };
            if ((_attr get "logisticsOriginNodeId") == "" || {(_attr get "logisticsThroughput") <= 0}) then {
                throw format ["Saved logistics shipment %1 has invalid origin or throughput", _crateId];
            };
        };
        private _allowedCrateFields = +_requiredCrateFields;
        if (_shipmentFieldCount > 0) then {
            _allowedCrateFields append _shipmentRecordFields;
        };
        private _unexpectedCrateFields = (keys _attr) select {
            !(_x in _allowedCrateFields)
        };
        if (_unexpectedCrateFields isNotEqualTo []) then {
            throw format [
                "Saved crate %1 has unexpected fields %2",
                _crateId,
                _unexpectedCrateFields
            ];
        };

        private _type = _attr get "type";
        private _pos = _attr get "posASL";
        private _vectorDirAndUp = _attr get "vectorDirAndUp";
        if (
            _type == ""
            || {!isClass (configFile >> "CfgVehicles" >> _type)}
            || {(count _pos) < 2}
            || {count _vectorDirAndUp != 2}
            || {{!(_x isEqualType []) || {count _x != 3}} count _vectorDirAndUp > 0}
        ) then {
            throw format ["Saved crate %1 has invalid spatial or class state", _crateId];
        };
        private _items = _attr get "items";
        {
            if !(
                _x isEqualType []
                && {count _x == 3}
                && {(_x # 0) isEqualType ""}
                && {(_x # 1) isEqualType 0}
                && {(_x # 1) > 0}
                && {(_x # 2) in ["weapon", "magazine", "item", "backpack"]}
            ) then {
                throw format ["Saved crate %1 has malformed cargo record %2", _crateId, _x];
            };
        } forEach _items;

        private _crate = createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"];
        if (isNull _crate) then {
            throw format ["Failed to restore saved crate %1 of type %2", _crateId, _type];
        };
        [_crate, false, [[], [], [], []]] call BIS_fnc_initAmmoBox;
        _crate setVectorDirAndUp _vectorDirAndUp;
        _crate setPosASL _pos;
        _crate setDamage (_attr get "damage");
        _crate lock (_attr get "locked");
        _crate setVariable ["FLO_save_crate", true, true];
        _crate setVariable ["FLO_SaveID", _crateId, true];
        if (_shipmentFieldCount > 0) then {
            private _shipmentSideKey = _attr get "logisticsSideKey";
            _crate setVariable ["FLO_LogisticsShipment", true, true];
            _crate setVariable ["FLO_LogisticsDelivered", _attr get "logisticsDelivered", true];
            _crate setVariable ["FLO_LogisticsSide", [_shipmentSideKey] call FLO_fnc_campaignSideFromKey, true];
            _crate setVariable ["FLO_LogisticsOriginNodeId", _attr get "logisticsOriginNodeId", true];
            _crate setVariable ["FLO_LogisticsThroughput", _attr get "logisticsThroughput", true];
            _crate setVariable ["FLO_LogisticsContributorUID", _attr get "logisticsContributorUID", true];
            _crate setVariable ["FLO_LogisticsContributorName", _attr get "logisticsContributorName", true];
            _crate setVariable ["FLO_DevelopmentTargetObjectiveId", _attr get "developmentTargetObjectiveId", true];
        };
        {
            _x params ["_itemClass", "_count", "_itemType"];
            switch (_itemType) do {
                case "weapon": { _crate addWeaponCargoGlobal [_itemClass, _count]; };
                case "magazine": { _crate addMagazineCargoGlobal [_itemClass, _count]; };
                case "backpack": { _crate addBackpackCargoGlobal [_itemClass, _count]; };
                case "item": { _crate addItemCargoGlobal [_itemClass, _count]; };
            };
        } forEach _items;
        [_crate, true, [0,2,0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, _crate];
        _loadedCrates = _loadedCrates + 1;
    } forEach (keys _crateHash);
    ["INIT", 3, format ["Restored %1 supply crates from current save", _loadedCrates]] call FLO_fnc_log;

    // Restore the current dual-commander state.
    if (isNil "FLO_GTN_ResourceManager") then {
        FLO_GTN_ResourceManager = [] call FLO_fnc_gtnResourceManager;
    };

    private _cmd = _savedData get "aiCommanders";
    private _commanderKeys = keys _cmd;
    private _unexpectedCommanderKeys = _commanderKeys select {!(_x in ["EAST", "WEST"])};
    if (count _commanderKeys != 2 || {_unexpectedCommanderKeys isNotEqualTo []}) then {
        throw format ["Current save has invalid commander keys %1", _commanderKeys];
    };
    private _eastState = _cmd get "EAST";
    private _westState = _cmd get "WEST";
    {
        _x params ["_sideKey", "_state"];
        if !(_state isEqualType createHashMap) then {
            throw format ["Saved %1 commander state has invalid type %2", _sideKey, typeName _state];
        };
        if (count (keys _state) != 1 || {!("gtnEnabled" in _state)}) then {
            throw format ["Saved %1 commander state has invalid fields %2", _sideKey, keys _state];
        };
        if !((_state get "gtnEnabled") isEqualType true) then {
            throw format ["Saved %1 commander gtnEnabled has invalid type", _sideKey];
        };
    } forEach [["EAST", _eastState], ["WEST", _westState]];
    private _gtnWasEnabled = (_eastState get "gtnEnabled") || (_westState get "gtnEnabled");

    if (_gtnWasEnabled) then {
        FLO_GTN_ResourceManager call ["_initializeGTN", []];
    };

    ["INIT", 3, "Dual GTN state restored"] call FLO_fnc_log;

    // Restore IDS Logistics placed entities
    if !(IDS_Logistics_PlacedEntities isEqualType []) then {
        throw format ["IDS Logistics runtime registry has invalid type %1", typeName IDS_Logistics_PlacedEntities];
    };
    private _idsEntities = _savedData get "idsLogisticsEntities";
    private _requiredIdsTypes = [
        ["class", ""], ["posASL", []], ["direction", 0], ["vectorUp", []], ["damage", 0]
    ];
    private _requiredIdsFields = _requiredIdsTypes apply { _x # 0 };
    private _loadedIDS = 0;
    {
        private _entityData = _x;
        if !(_entityData isEqualType createHashMap) then {
            throw format ["Saved IDS entity %1 has invalid record type %2", _forEachIndex, typeName _entityData];
        };
        private _unexpectedIdsFields = (keys _entityData) select {
            !(_x in _requiredIdsFields)
        };
        if (_unexpectedIdsFields isNotEqualTo []) then {
            throw format [
                "Saved IDS entity %1 has unexpected fields %2",
                _forEachIndex,
                _unexpectedIdsFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _entityData) then {
                throw format ["Saved IDS entity %1 is missing required field %2", _forEachIndex, _field];
            };
            private _value = _entityData get _field;
            if !(_value isEqualType _prototype) then {
                throw format ["Saved IDS entity %1 field %2 has invalid type %3", _forEachIndex, _field, typeName _value];
            };
        } forEach _requiredIdsTypes;

        private _className = _entityData get "class";
        if (_className == "" || {!isClass (configFile >> "CfgVehicles" >> _className)}) then {
            throw format ["Saved IDS entity %1 has invalid class %2", _forEachIndex, _className];
        };
        private _entity = createVehicle [_className, [0,0,0], [], 0, "CAN_COLLIDE"];
        if (isNull _entity) then {
            throw format ["Failed to restore saved IDS entity %1 of type %2", _forEachIndex, _className];
        };
        _entity setPosASL (_entityData get "posASL");
        _entity setDir (_entityData get "direction");
        _entity setVectorUp (_entityData get "vectorUp");
        _entity setDamage (_entityData get "damage");
        _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];
        IDS_Logistics_PlacedEntities pushBack _entity;
        _loadedIDS = _loadedIDS + 1;
    } forEach _idsEntities;
    ["INIT", 3, format ["Restored %1 IDS Logistics entities from current save", _loadedIDS]] call FLO_fnc_log;

    // Trigger load completion event
    ["flo_mission_load_completed", [true, _savedData]] call CBA_fnc_globalEvent;

    ["INIT", 3, "Current-version entity restoration complete"] call FLO_fnc_log;
};

// ============================================
// Side Resource System
// ============================================
diag_log "[FLO_INIT_P5] Starting side resource system...";
if (!isNil "FLO_fnc_sideResources") then {
    if ([] call FLO_fnc_initSideResourcesUninitialized) then {
        [] call FLO_fnc_sideResources;
    };
    diag_log "[FLO_INIT_P5] Side resources started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_sideResources not found";
};

// ============================================
// Logistics Network
// ============================================
diag_log "[FLO_INIT_P5] Starting logistics network...";
if (!isNil "FLO_fnc_logisticsNetwork") then {
    [] call FLO_fnc_logisticsNetwork;
    diag_log "[FLO_INIT_P5] Logistics network started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_logisticsNetwork not found";
};

[] call FLO_fnc_sideResourcesStartMainLoop;

[] call FLO_fnc_objectiveDevelopmentStart;
diag_log "[FLO_INIT_P5] Objective development started";

if (!FLO_IsLoadedSave) then {
    private _missionSides = missionNamespace getVariable ["FLO_MissionSides", [east, west]];
    {
        [_x] call FLO_fnc_initializeTransportReserveGroups;
    } forEach _missionSides;
    diag_log "[FLO_INIT_P5] Transport reserve carriers seeded from staging objectives";
};

// ============================================
// GTN Resource Manager
// ============================================
if (isNil "FLO_GTN_CombatEvents") then {
    FLO_GTN_CombatEvents = [];
};
if (isNil "FLO_GTN_CombatLastByObjective") then {
    FLO_GTN_CombatLastByObjective = createHashMap;
};

diag_log "[FLO_INIT_P5] Starting GTN Resource Manager...";
if (!isNil "FLO_fnc_gtnResourceManager") then {
    if (isNil "FLO_GTN_ResourceManager") then {
        FLO_GTN_ResourceManager = [] call FLO_fnc_gtnResourceManager;
    } else {
        FLO_GTN_ResourceManager call ["_initializeGTN", []];
    };
    diag_log "[FLO_INIT_P5] GTN Resource Manager started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnResourceManager not found";
};

// ============================================
// GTN Minefield System
// ============================================
diag_log "[FLO_INIT_P5] Initializing GTN minefield system...";
if (!isNil "FLO_fnc_gtnMinefieldSystemInit") then {
    [] call FLO_fnc_gtnMinefieldSystemInit;
    diag_log "[FLO_INIT_P5] GTN minefield system initialized";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnMinefieldSystemInit not found";
};

// ============================================
// GTN Virtual Combat Resolver
// ============================================
diag_log "[FLO_INIT_P5] Starting GTN virtual combat resolver...";
if (!isNil "FLO_fnc_gtnVirtualCombatResolver") then {
    [] spawn FLO_fnc_gtnVirtualCombatResolver;
    diag_log "[FLO_INIT_P5] GTN virtual combat resolver started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnVirtualCombatResolver not found";
};

// ============================================
// GTN Player Task Bridge
// ============================================
diag_log "[FLO_INIT_P5] Evaluating GTN player task bridge...";
if (!isNil "FLO_fnc_gtnPlayerTaskBridge" && {FLO_GTN_EnablePlayerTaskBridge}) then {
    [] spawn FLO_fnc_gtnPlayerTaskBridge;
    diag_log "[FLO_INIT_P5] GTN player task bridge started (enabled)";
} else {
    if (!FLO_GTN_EnablePlayerTaskBridge) then {
        diag_log "[FLO_INIT_P5] GTN player task bridge disabled (FLO_GTN_EnablePlayerTaskBridge=false)";
    } else {
        diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnPlayerTaskBridge not found";
    };
};

// ============================================
// GTN Player Support Events
// ============================================
diag_log "[FLO_INIT_P5] Registering GTN player support events...";
if (!isNil "FLO_fnc_gtnRegisterPlayerSupportEvents") then {
    [] call FLO_fnc_gtnRegisterPlayerSupportEvents;
    diag_log "[FLO_INIT_P5] GTN player support events registered";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnRegisterPlayerSupportEvents not found";
};

// ============================================
// GTN Commander Visual Debug
// ============================================
diag_log "[FLO_INIT_P5] Evaluating GTN commander visual debug...";
if (!isNil "FLO_fnc_gtnCommanderVisualDebug" && {FLO_GTN_CommanderDebugEnabled}) then {
    [] spawn FLO_fnc_gtnCommanderVisualDebug;
    diag_log "[FLO_INIT_P5] GTN commander visual debug started";
} else {
    if (!FLO_GTN_CommanderDebugEnabled) then {
        diag_log "[FLO_INIT_P5] GTN commander visual debug disabled (FLO_GTN_CommanderDebugEnabled=false)";
    } else {
        diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnCommanderVisualDebug not found";
    };
};

// ============================================
// Aftermath Cleanup
// ============================================
diag_log "[FLO_INIT_P5] Starting aftermath cleanup...";
if (!isNil "FLO_fnc_aftermathCleanupManager") then {
    ["start"] call FLO_fnc_aftermathCleanupManager;
    diag_log "[FLO_INIT_P5] Aftermath cleanup started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_aftermathCleanupManager not found";
};

// ============================================
// Abandoned Vehicle Cleanup
// ============================================
diag_log "[FLO_INIT_P5] Starting abandoned vehicle cleanup...";
if (!isNil "FLO_fnc_vehicleCleanupManager") then {
    ["start"] call FLO_fnc_vehicleCleanupManager;
    diag_log "[FLO_INIT_P5] Abandoned vehicle cleanup started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_vehicleCleanupManager not found";
};

// ============================================
// Civilian System (Config + Manager)
// ============================================
diag_log "[FLO_INIT_P5] Initializing civilian system...";
if (!isNil "FLO_fnc_civilianConfig") then {
    [] call FLO_fnc_civilianConfig;
    diag_log "[FLO_INIT_P5] Civilian config loaded";
};
if (!isNil "FLO_fnc_civilianManager") then {
    [] call FLO_fnc_civilianManager;
    diag_log "[FLO_INIT_P5] Civilian manager initialized";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_civilianManager not found";
};

// ============================================
// Civilian Mission System
// ============================================
diag_log "[FLO_INIT_P5] Initializing civilian mission system...";
if (!isNil "FLO_fnc_civilianMissionManager") then {
    ["INIT"] call FLO_fnc_civilianMissionManager;
    diag_log "[FLO_INIT_P5] Civilian mission manager initialized";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_civilianMissionManager not found";
};

// ============================================
// Config Cache (if not already initialized)
// ============================================
if (isNil "FLO_ConfigCache") then {
    diag_log "[FLO_INIT_P5] Initializing config cache...";
    if (!isNil "FLO_fnc_objectiveConfig") then {
        ["init"] call FLO_fnc_objectiveConfig;
        diag_log "[FLO_INIT_P5] Config cache initialized";
    };
};

if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_fnc_virtualizationResumeSavedRoutes"}) then {
    private _resumedRoutes = [] call FLO_fnc_virtualizationResumeSavedRoutes;
    if (_resumedRoutes > 0) then {
        diag_log format ["[FLO_INIT_P5] Reissued %1 saved virtual routes after load", _resumedRoutes];
    };
};

diag_log "[FLO_INIT_P5] Starting virtualization PFH...";
if (!isNil "FLO_fnc_virtualizationUpdatePFH") then {
    ["start"] call FLO_fnc_virtualizationUpdatePFH;
    diag_log "[FLO_INIT_P5] Virtualization PFH started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_virtualizationUpdatePFH not found";
};

diag_log "[FLO_INIT_P5] Mission systems phase complete";
true
