/*
 * Function: FLO_fnc_MissionSave
 * Author: Frontline Operations Development Group
 * Description: Mission save system
 *
 * Returns: <BOOL> - Success status
 */

if (!isServer) exitWith {false};

["SAVE", 3, "Starting mission save operation..."] call FLO_fnc_log;

// ============================================================================
// INITIALIZATION AND VALIDATION
// ============================================================================

private _saveStartTime = diag_tickTime;
private _center = [worldSize/2, worldSize/2, 0];
private _data = missionProfileNamespace getVariable ["FLO_MissionData", createHashMap];

// Validation function
private _fnc_validateSaveData = {
    params ["_data"];

    private _requiredKeys = ["time", "markers", "vehicles", "objects"];
    private _isValid = true;

    {
        if (!(_x in _data)) then {
            ["SAVE", 1, format["Missing required key: %1", _x]] call FLO_fnc_log;
            _isValid = false;
        };
    } forEach _requiredKeys;

    _isValid
};

// Progress tracking
private _totalModules = 12;
private _completedModules = 0;

private _fnc_updateProgress = {
    params ["_moduleName"];
    _completedModules = _completedModules + 1;
    ["SAVE", 3, format["Completed %1 (%2/%3)", _moduleName, _completedModules, _totalModules]] call FLO_fnc_log;
};

// ============================================================================
// CORE DATA SAVE
// ============================================================================

try {
    // Save timestamp
    _data set ["time", date];
    ["Time"] call _fnc_updateProgress;

    // ============================================================================
    // CLEANUP AND CACHING
    // ============================================================================

    private _fnc_performCleanup = {
        try {
            // Clean debug spheres in chunks
            private _searchRadius = 5000;
            private _chunks = [
                [[0, 0, 0], _searchRadius],
                [[worldSize/2, 0, 0], _searchRadius],
                [[worldSize, 0, 0], _searchRadius],
                [[0, worldSize/2, 0], _searchRadius],
                [[worldSize/2, worldSize/2, 0], _searchRadius],
                [[worldSize, worldSize/2, 0], _searchRadius],
                [[0, worldSize, 0], _searchRadius],
                [[worldSize/2, worldSize, 0], _searchRadius],
                [[worldSize, worldSize, 0], _searchRadius]
            ];

            private _debugObjects = [];
            {
                _x params ["_pos", "_radius"];
                _debugObjects append (nearestObjects [_pos, ["Sign_Sphere10cm_F"], _radius]);
            } forEach _chunks;

            // Remove duplicates and clean up
            _debugObjects = _debugObjects arrayIntersect _debugObjects;
            {
                if (!isNull _x) then { deleteVehicle _x };
            } forEach _debugObjects;

            // Clean group markers
            private _groupMarkers = allMapMarkers select {
                markerType _x isEqualTo "b_unknown" && markerColor _x isEqualTo "Color6_FD_F"
            };
            { deleteMarker _x } forEach _groupMarkers;

            ["SAVE", 5, format["Cleaned up %1 debug objects and %2 group markers", count _debugObjects, count _groupMarkers]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Cleanup failed: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_performCleanup;
    ["Cleanup"] call _fnc_updateProgress;

    // ============================================================================
    // CACHED COLLECTIONS
    // ============================================================================

    // Frequently used collections
    private _installationMarkers = allMapMarkers select {markerType _x isEqualTo "b_installation"};
    private _allVehicles = vehicles select {alive _x};
    private _allObjects = entities "Static" + entities "Thing" + entities "ReammoBox_F";

    ["SAVE", 5, format["Cached collections: %1 installations, %2 vehicles, %3 objects",
        count _installationMarkers, count _allVehicles, count _allObjects]] call FLO_fnc_log;

    // ============================================================================
    // PLAYER GROUP COMPOSITIONS
    // ============================================================================

    private _fnc_savePlayerGroups = {
        try {
            private _validUnitTypes = createHashMapFromArray [
                [F_Diver_Eod, true], [F_Diver_Rfl, true], [F_Diver_TL, true],
                [F_Recon_Eod, true], [F_Recon_Med, true], [F_Recon_Eng, true],
                [F_Recon_Mg, true], [F_Recon_AT, true], [F_Recon_Mrk, true],
                [F_Recon_Snp, true], [F_Recon_Sct, true], [F_Recon_TL, true],
                [F_Assault_AT, true], [F_Assault_Amm, true], [F_Assault_Mg, true],
                [F_Assault_SL, true], [F_Assault_TL, true], [F_Assault_Eng, true],
                [F_Assault_Eod, true], [F_Assault_Mrk, true], [F_Assault_Uav, true],
                [F_Assault_Med, true], [F_Officer, true]
            ];

            // Group filtering
            private _saveGroups = allGroups select {
                private _units = units _x;
                if (count _units > 0) then {
                    private _leader = _units select 0;
                    !isNull _leader &&
                    alive _leader &&
                    side _leader isEqualTo west &&
                    !captive _leader &&
                    (_validUnitTypes getOrDefault [typeOf _leader, false])
                } else {
                    false
                }
            };

            // Create group markers
            {
                private _units = units _x;
                private _leader = _units select 0;

                // Collect unit types (excluding player leader)
                private _types = [];
                private _startIndex = if (isPlayer _leader) then {1} else {0};
                for "_i" from _startIndex to (count _units - 1) do {
                    _types pushBack (typeOf (_units select _i));
                };

                // Create marker with unique ID
                private _markerId = format["group_%1_%2", getPlayerUID _leader, time];
                private _marker = createMarkerLocal [_markerId, getPos _leader];
                _marker setMarkerTypeLocal "b_unknown";
                _marker setMarkerSizeLocal [0.5, 0.5];
                _marker setMarkerColorLocal "Color6_FD_F";
                _marker setMarkerAlphaLocal 0.006;
                _marker setMarkerText (str _types);

            } forEach _saveGroups;

            ["SAVE", 5, format["Saved %1 player groups", count _saveGroups]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save player groups: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_savePlayerGroups;
    ["Player Groups"] call _fnc_updateProgress;

    // ============================================================================
    // BATTLEFIELD MARKERS
    // ============================================================================

    private _fnc_saveMarkers = {
        try {
            private _markerHash = createHashMap;
            private _allMarkers = allMapMarkers;

            // Filter out temporary/system markers
            private _excludeMarkerTypes = createHashMapFromArray [
                ["b_unknown", true],  // Temporary group markers
                ["Empty", true],      // Empty markers
                ["mil_dot", true]     // Temporary waypoint markers
            ];

            private _saveableMarkers = _allMarkers select {
                !(_excludeMarkerTypes getOrDefault [markerType _x, false]) &&
                markerAlpha _x > 0.01  // Skip nearly invisible markers
            };

            {
                private _entry = createHashMapFromArray [
                    ["name", _x],
                    ["alpha", markerAlpha _x],
                    ["brush", markerBrush _x],
                    ["color", getMarkerColor _x],
                    ["dir", markerDir _x],
                    ["pos", getMarkerPos _x],
                    ["shape", markerShape _x],
                    ["size", getMarkerSize _x],
                    ["text", markerText _x],
                    ["type", markerType _x]
                ];
                _markerHash set [_x, _entry];
            } forEach _saveableMarkers;

            _data set ["markers", _markerHash];

            ["SAVE", 5, format["Saved %1 markers (filtered from %2 total)",
                count _saveableMarkers, count _allMarkers]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save markers: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_saveMarkers;
    ["Markers"] call _fnc_updateProgress;

    // ============================================================================
    // VEHICLES AROUND INSTALLATIONS
    // ============================================================================

    private _fnc_saveVehicles = {
        try {
            private _vehHash = createHashMap;

            // Damage compression function
            private _fnc_compressVehicleData = {
                params ["_vehicle"];

                // Only store damaged hitpoints
                private _damages = getAllHitPointsDamage _vehicle;
                private _damagedHitpoints = [];

                if (count _damages >= 3) then {
                    private _names = _damages select 0;
                    private _values = _damages select 2;

                    {
                        private _damageValue = _values select _forEachIndex;
                        if (_damageValue > 0.01) then {  // Only store significant damage
                            _damagedHitpoints pushBack [_x, _damageValue];
                        };
                    } forEach _names;
                };

                _damagedHitpoints
            };

            // Process vehicles around each installation
            {
                private _pos = getMarkerPos _x;
                private _nearVehicles = _pos nearEntities [["Air", "Ship", "LandVehicle"], 250];

                {
                    if (alive _x && !isPlayer _x) then {  // Skip player vehicles
                        // Generate unique ID using CBA
                        private _id = [] call CBA_fnc_createUUID;

                        _x setVehicleVarName _id;
                        _x setVariable ["FLO_SaveID", _id, true];

                        private _entry = createHashMapFromArray [
                            ["type", typeOf _x],
                            ["posATL", getPosATL _x],
                            ["fuel", fuel _x],
                            ["damage", damage _x],
                            ["damagedHitpoints", [_x] call _fnc_compressVehicleData],  // Compressed damage data
                            ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
                            ["locked", locked _x],
                            ["engineOn", isEngineOn _x]
                        ];
                        _vehHash set [_id, _entry];
                    };
                } forEach _nearVehicles;

            } forEach _installationMarkers;

            _data set ["vehicles", _vehHash];

            ["SAVE", 5, format["Saved %1 vehicles around installations", count _vehHash]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save vehicles: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_saveVehicles;
    ["Vehicles"] call _fnc_updateProgress;

    // ============================================================================
    // PLACED OBJECTS AND STRUCTURES
    // ============================================================================

    private _fnc_saveObjects = {
        try {
            private _objHash = createHashMap;

            private _excludeCrates = createHashMapFromArray [
                ["Box_NATO_WpsSpecial_F", true],
                ["Box_NATO_AmmoOrd_F", true],
                ["Box_NATO_Ammo_F", true],
                ["Box_NATO_Wps_F", true],
                ["VirtualReammoBox_small_F", true]
            ];

            private _saveStatics = [];

            // Collect objects around installations
            {
                private _pos = getMarkerPos _x;
                private _nearObjects = _pos nearEntities [["Static", "Thing", "ReammoBox_F"], 300];

                // Filter objects
                private _validObjects = _nearObjects select {
                    alive _x &&
                    !(_excludeCrates getOrDefault [typeOf _x, false]) &&
                    !(_x getVariable ["FLO_save_crate", false]) &&
                    !(_x getVariable ["FLO_temp_object", false])  // Skip temporary objects
                };

                _saveStatics append _validObjects;
            } forEach _installationMarkers;

            // Remove duplicates
            _saveStatics = _saveStatics arrayIntersect _saveStatics;

            // Save object data
            {
                // Generate unique ID using CBA
                private _id = [] call CBA_fnc_createUUID;

                _x setVehicleVarName _id;
                _x setVariable ["FLO_SaveID", _id, true];

                private _entry = createHashMapFromArray [
                    ["type", typeOf _x],
                    ["posASL", getPosASL _x],
                    ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
                    ["isPlacedEntity", _x getVariable ["IDS_Logistics_isPlacedEntity", false]],
                    ["damage", damage _x],
                    ["variables", _x getVariable ["FLO_SavedVariables", createHashMap]]  // Custom variables
                ];
                _objHash set [_id, _entry];

            } forEach _saveStatics;

            _data set ["objects", _objHash];

            ["SAVE", 5, format["Saved %1 objects around installations", count _saveStatics]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save objects: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_saveObjects;
    ["Objects"] call _fnc_updateProgress;

    // ============================================================================
    // STRUCTURE MARKERS AND TYPES
    // ============================================================================

    private _fnc_saveStructureMarkers = {
        try {
            private _structureMarkers = createHashMap;
            private _fobTypeClass = if (!isNil "F_HQ_01") then {F_HQ_01} else {""};
            private _opTypeClass = if (!isNil "F_OP_01") then {F_OP_01} else {""};

            // Structure search using allMissionObjects
            private _fnc_findStructuresSimple = {
                params ["_typeClasses", "_structureType", "_variableName", "_markerVariable"];

                // Use allMissionObjects to find all objects of specific types
                private _foundStructures = [];
                {
                    private _objectsOfType = allMissionObjects _x;
                    _foundStructures append _objectsOfType;
                } forEach _typeClasses;

                // Remove duplicates
                _foundStructures = _foundStructures arrayIntersect _foundStructures;

                {
                    if (!isNull _x && {alive _x} && {_x getVariable [_variableName, false]}) then {
                        private _markerName = _x getVariable [_markerVariable, ""];
                        if (_markerName != "") then {
                            private _pos = getPosASL _x;
                            private _id = format["%1_%2_%3", round(_pos#0), round(_pos#1), round(_pos#2)];
                            _structureMarkers set [_id, [_markerName, _structureType]];
                        };
                    };
                } forEach _foundStructures;

                count _foundStructures
            };

            // Save FOB structures
            private _fobCount = 0;
            if (_fobTypeClass != "") then {
                _fobCount = [
                    [_fobTypeClass, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"],
                    "FOB",
                    "FLO_FOB_Initialized",
                    "fobMarkerName"
                ] call _fnc_findStructuresSimple;
            };

            // Save OP structures
            private _opCount = 0;
            if (_opTypeClass != "") then {
                _opCount = [
                    [_opTypeClass],
                    "OP",
                    "FLO_OP_Initialized",
                    "opMarkerName"
                ] call _fnc_findStructuresSimple;
            };

            _data set ["structureMarkers", _structureMarkers];
            _data set ["structureTypes", [_fobTypeClass, _opTypeClass]];

            ["SAVE", 5, format["Saved %1 FOBs and %2 OPs", _fobCount, _opCount]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save structure markers: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_saveStructureMarkers;
    ["Structure Markers"] call _fnc_updateProgress;

    // ============================================================================
    // SUPPLY CRATES
    // ============================================================================

    private _fnc_saveCrates = {
        try {
            private _crateHash = createHashMap;

            // Cargo collection function
            private _fnc_getAllCargo = {
                params ["_container"];
                private _items = [];

                // Batch process all cargo types
                private _cargoTypes = [
                    [getWeaponCargo _container, "weapon"],
                    [getMagazineCargo _container, "magazine"],
                    [getItemCargo _container, "item"],
                    [getBackpackCargo _container, "backpack"]
                ];

                {
                    _x params ["_cargo", "_type"];
                    _cargo params ["_classes", "_counts"];
                    {
                        if (_counts select _forEachIndex > 0) then {  // Only save items with count > 0
                            _items pushBack [_x, _counts select _forEachIndex, _type];
                        };
                    } forEach _classes;
                } forEach _cargoTypes;

                _items
            };

            // Process all supply crates
            private _allCrates = entities "ReammoBox_F";
            private _saveCrates = _allCrates select {
                alive _x && {_x getVariable ["FLO_save_crate", false]}
            };

            {
                private _items = [_x] call _fnc_getAllCargo;
                _x setVariable ["FLO_crate_items", _items, true];

                // Generate unique ID using CBA
                private _id = [] call CBA_fnc_createUUID;

                _x setVehicleVarName _id;
                _x setVariable ["FLO_SaveID", _id, true];

                private _entry = createHashMapFromArray [
                    ["type", typeOf _x],
                    ["posASL", getPosASL _x],
                    ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
                    ["items", _items],
                    ["damage", damage _x],
                    ["locked", locked _x]
                ];
                _crateHash set [_id, _entry];

            } forEach _saveCrates;

            _data set ["crates", _crateHash];

            ["SAVE", 5, format["Saved %1 supply crates", count _saveCrates]] call FLO_fnc_log;

        } catch {
            ["SAVE", 1, format["Failed to save crates: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_saveCrates;
    ["Supply Crates"] call _fnc_updateProgress;

    // ============================================================================
    // REMAINING SYSTEMS
    // ============================================================================

    // Save OPFOR resources
    try {
        private _missionTag = missionName;
        _missionTag = [_missionTag] call BIS_fnc_filterString;
        private _resVar = _missionTag + "_Resources";
        private _resResult = FLO_OPFOR_Resources call ["saveResources", []];
        private _resData = profileNamespace getVariable [_resVar, createHashMap];
        _data set ["resources", _resData];
        ["Resources"] call _fnc_updateProgress;
    } catch {
        ["SAVE", 1, format["Failed to save resources: %1", _exception]] call FLO_fnc_log;
    };

    // Save virtual groups
    try {
        if (!isNil "FLO_virtualGroups") then {

            private _groups = FLO_virtualGroups get "_groups";
            // Validate that _groups is actually a HashMap
            if (!isNil "_groups" && {_groups isEqualType createHashMap}) then {

                // Show what groups exist
                {
                    ["SAVE", 3, format["Group ID: %1, Type: %2", _x, typeName _y]] call FLO_fnc_log;
                } forEach _groups;

                private _vh = createHashMap;

                {
                    private _gData = _y;
                    ["SAVE", 3, format["Processing group %1, data type: %2", _x, typeName _gData]] call FLO_fnc_log;

                    // Validate that group data is a HashMap
                    if (!isNil "_gData" && {_gData isEqualType createHashMap}) then {
                        private _s = createHashMapFromArray [
                            ["position", _gData get "position"],
                            ["groupType", _gData get "groupType"],
                            ["objective", _gData get "objective"],
                            ["unitCount", _gData get "unitCount"],
                            ["side", _gData get "side"],
                            ["state", _gData get "state"],
                            ["waypoints", _gData get "waypoints"],
                            ["currentWaypointIndex", _gData get "currentWaypointIndex"],
                            ["garrisonPosition", _gData getOrDefault ["garrisonPosition", []]],
                            ["garrisonObjective", _gData getOrDefault ["garrisonObjective", ""]]
                        ];
                        _vh set [_x, _s];
                    } else {
                        ["SAVE", 1, format["Skipped invalid group data for %1", _x]] call FLO_fnc_log;
                    };
                } forEach _groups;

                _data set ["virtualGroups", _vh];
                ["SAVE", 3, format["Saved %1 virtual groups", count _vh]] call FLO_fnc_log;
            } else {
                ["SAVE", 1, "FLO_virtualGroups._groups is not a valid HashMap"] call FLO_fnc_log;
                _data set ["virtualGroups", createHashMap]; // Save empty HashMap
            };
        } else {
            ["SAVE", 1, "FLO_virtualGroups does not exist"] call FLO_fnc_log;
            _data set ["virtualGroups", createHashMap]; // Save empty HashMap
        };
        ["Virtual Groups"] call _fnc_updateProgress;
    } catch {
        ["SAVE", 1, format["Failed to save virtual groups: %1", _exception]] call FLO_fnc_log;
        _data set ["virtualGroups", createHashMap]; // Ensure we always save something valid
    };

    // Save objectives and AI Commander
    try {
        if (!isNil "FLO_Objectives") then {_data set ["objectives", FLO_Objectives]};

        if (!isNil "FLO_AI_Commander") then {
            private _cmd = createHashMapFromArray [
                ["threatLevel", FLO_AI_Commander get "_threatLevel"],
                ["lastUpdate", FLO_AI_Commander get "_lastUpdate"],
                ["attackOperations", FLO_AI_Commander get "_attackOperations"],
                ["activeAttackGroups", FLO_AI_Commander get "_activeAttackGroups"],
                ["activeDefenseGroups", FLO_AI_Commander get "_activeDefenseGroups"],
                ["garrisonedGroups", FLO_AI_Commander get "_garrisonedGroups"]
            ];
            _data set ["aiCommander", _cmd];
        };
        ["Objectives & AI"] call _fnc_updateProgress;
    } catch {
        ["SAVE", 1, format["Failed to save objectives/AI: %1", _exception]] call FLO_fnc_log;
    };

    // Save mission variables efficiently
    try {
        private _missionVars = [
            ["friendlyHandle", "FLO_FriendlyHandle"],
            ["enemyHandle", "FLO_EnemyHandle"],
            ["civilianHandle", "FLO_CivilianHandle"],
            ["moneyHandle", "FLO_MoneyHandle"],
            ["difficultyHandle", "FLO_DifficultyHandle"],
            ["reputationHandle", "FLO_ReputationHandle"],
            ["enemyPrec", "EnemyPrec"]
        ];

        {
            _x params ["_saveKey", "_varName"];
            if (!isNil _varName) then {
                _data set [_saveKey, missionNamespace getVariable [_varName, nil]];
            };
        } forEach _missionVars;

        ["Mission Variables"] call _fnc_updateProgress;
    } catch {
        ["SAVE", 1, format["Failed to save mission variables: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // FINALIZATION
    // ============================================================================

    // Validate save data before writing
    if ([_data] call _fnc_validateSaveData) then {
        try {
            missionProfileNamespace setVariable ["FLO_MissionData", _data];
            saveMissionProfileNamespace;

            private _saveTime = diag_tickTime - _saveStartTime;
            ["SAVE", 3, format["Mission saved successfully in %1 seconds (%2/%3 modules)",
                round(_saveTime * 100) / 100, _completedModules, _totalModules]] call FLO_fnc_log;

            // Trigger save completion event
            ["flo_mission_save_completed", [true, _data]] call CBA_fnc_globalEvent;

            true
        } catch {
            ["SAVE", 1, format["Failed to write save data: %1", _exception]] call FLO_fnc_log;
            false
        };
    } else {
        ["SAVE", 1, "Save data validation failed"] call FLO_fnc_log;
        false
    };

} catch {
    ["SAVE", 1, format["Critical save error: %1", _exception]] call FLO_fnc_log;
    false
};
