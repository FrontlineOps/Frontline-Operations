/*
 * Function: FLO_fnc_MissionLoad
 * Author: Frontline Operations Development Group
 * Description: Mission load system
 *
 * Returns: <BOOL> - Success status
 */

if (!isServer) exitWith {false};

// ============================================================================
// INITIALIZATION AND VALIDATION
// ============================================================================

private _loadStartTime = diag_tickTime;
MissionLoadedLitterally = false;
publicVariable "MissionLoadedLitterally";

["LOAD", 3, "Starting mission load operation..."] call FLO_fnc_log;

private _center = [worldSize/2, worldSize/2, 0];
private _data = missionProfileNamespace getVariable ["FLO_MissionData", createHashMap];

// Load function
private _fnc_safeLoad = {
    params ["_data", "_key", "_default"];

    if (isNil "_data" || !(_data isEqualType createHashMap)) exitWith {_default};

    if (_key in _data) then {
        _data get _key
    } else {
        _default
    }
};

// Progress tracking
private _totalModules = 11;
private _completedModules = 0;

private _fnc_updateProgress = {
    params ["_moduleName"];
    _completedModules = _completedModules + 1;
    ["LOAD", 3, format["Completed %1 (%2/%3)", _moduleName, _completedModules, _totalModules]] call FLO_fnc_log;
};

// Handle fresh start parameter
FreshStartVal = "FreshStart" call BIS_fnc_getParamValue;
if (FreshStartVal isEqualTo 1) then {
    ["LOAD", 3, "Fresh start requested - clearing save data"] call FLO_fnc_log;
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;
    MissionLoadedLitterally = true;
    publicVariable "MissionLoadedLitterally";
    true
} else {

try {

    // ============================================================================
    // CORE DATA LOAD
    // ============================================================================

    // Load date/time
    try {
        private _date = [_data, "time", date] call _fnc_safeLoad;
        if (!isNil "_date" && {_date isEqualType []}) then {
            setDate _date;
            ["LOAD", 3, format["Loaded mission time: %1", _date]] call FLO_fnc_log;
        };
        ["Date/Time"] call _fnc_updateProgress;
    } catch {
        ["LOAD", 1, format["Failed to load date: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // MARKERS
    // ============================================================================

    private _fnc_loadMarkers = {
        try {
            private _markerHash = [_data, "markers", createHashMap] call _fnc_safeLoad;
            private _loadedMarkers = 0;

            {
                private _markerName = _x;
                private _attr = _markerHash get _markerName;

                if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                    // Check if marker already exists and delete it
                    if (getMarkerColor _markerName != "") then {
                        deleteMarker _markerName;
                    };

                    private _marker = createMarker [_markerName, [0,0,0]];
                    _marker setMarkerPos ([_attr, "pos", [0,0,0]] call _fnc_safeLoad);
                    _marker setMarkerType ([_attr, "type", "mil_dot"] call _fnc_safeLoad);
                    _marker setMarkerBrush ([_attr, "brush", "Solid"] call _fnc_safeLoad);
                    _marker setMarkerShape ([_attr, "shape", "ICON"] call _fnc_safeLoad);
                    _marker setMarkerSize ([_attr, "size", [1,1]] call _fnc_safeLoad);
                    _marker setMarkerText ([_attr, "text", ""] call _fnc_safeLoad);
                    _marker setMarkerDir ([_attr, "dir", 0] call _fnc_safeLoad);
                    _marker setMarkerColor ([_attr, "color", "ColorBlack"] call _fnc_safeLoad);
                    _marker setMarkerAlpha ([_attr, "alpha", 1] call _fnc_safeLoad);

                    _loadedMarkers = _loadedMarkers + 1;
                };
            } forEach (keys _markerHash);

            ["LOAD", 3, format["Loaded %1 markers", _loadedMarkers]] call FLO_fnc_log;

        } catch {
            ["LOAD", 1, format["Failed to load markers: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_loadMarkers;
    ["Markers"] call _fnc_updateProgress;

    // ============================================================================
    // OBJECTS
    // ============================================================================

    private _fnc_loadObjects = {
        try {
            private _objHash = [_data, "objects", createHashMap] call _fnc_safeLoad;
            private _loadedObjects = 0;

            {
                private _objId = _x;
                private _attr = _objHash get _objId;

                if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                    private _type = [_attr, "type", ""] call _fnc_safeLoad;

                    if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                        private _obj = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];

                        if (!isNull _obj) then {
                            _obj setVectorDirAndUp ([_attr, "vectorDirAndUp", [[0,1,0], [0,0,1]]] call _fnc_safeLoad);
                            _obj setPosASL ([_attr, "posASL", [0,0,0]] call _fnc_safeLoad);
                            _obj setDamage ([_attr, "damage", 0] call _fnc_safeLoad);
                            _obj setVariable ["IDS_Logistics_isPlacedEntity", [_attr, "isPlacedEntity", false] call _fnc_safeLoad, true];
                            _obj setVariable ["FLO_SaveID", _objId, true];

                            // Load custom variables if they exist
                            private _variables = [_attr, "variables", createHashMap] call _fnc_safeLoad;
                            {
                                _obj setVariable [_x, _y, true];
                            } forEach _variables;

                            _loadedObjects = _loadedObjects + 1;
                        };
                    };
                };
            } forEach (keys _objHash);

            ["LOAD", 3, format["Loaded %1 objects", _loadedObjects]] call FLO_fnc_log;

        } catch {
            ["LOAD", 1, format["Failed to load objects: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_loadObjects;
    ["Objects"] call _fnc_updateProgress;

    // ============================================================================
    // VEHICLES
    // ============================================================================

    private _fnc_loadVehicles = {
        try {
            private _vehHash = [_data, "vehicles", createHashMap] call _fnc_safeLoad;
            private _loadedVehicles = 0;

            {
                private _vehId = _x;
                private _attr = _vehHash get _vehId;

                if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                    private _type = [_attr, "type", ""] call _fnc_safeLoad;

                    if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                        private _veh = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];

                        if (!isNull _veh) then {
                            _veh setVectorDirAndUp ([_attr, "vectorDirAndUp", [[0,1,0], [0,0,1]]] call _fnc_safeLoad);
                            _veh setPosATL ([_attr, "posATL", [0,0,0]] call _fnc_safeLoad);
                            _veh setFuel ([_attr, "fuel", 1] call _fnc_safeLoad);
                            _veh setDamage ([_attr, "damage", 0] call _fnc_safeLoad);
                            _veh lock ([_attr, "locked", 0] call _fnc_safeLoad);
                            _veh setVariable ["FLO_SaveID", _vehId, true];

                            // Load compressed hitpoint damages
                            private _damagedHitpoints = [_attr, "damagedHitpoints", []] call _fnc_safeLoad;
                            {
                                _x params ["_hitpoint", "_damage"];
                                _veh setHitPointDamage [_hitpoint, _damage];
                            } forEach _damagedHitpoints;

                            // Restore engine state
                            private _engineOn = [_attr, "engineOn", false] call _fnc_safeLoad;
                            if (_engineOn) then {
                                _veh engineOn true;
                            };

                            _loadedVehicles = _loadedVehicles + 1;
                        };
                    };
                };
            } forEach (keys _vehHash);

            ["LOAD", 3, format["Loaded %1 vehicles", _loadedVehicles]] call FLO_fnc_log;

        } catch {
            ["LOAD", 1, format["Failed to load vehicles: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_loadVehicles;
    ["Vehicles"] call _fnc_updateProgress;

    // ============================================================================
    // RESOURCES
    // ============================================================================

    try {
        private _missionTag = missionName;
        _missionTag = [_missionTag] call BIS_fnc_filterString;
        private _resVar = _missionTag + "_Resources";
        private _resData = [_data, "resources", createHashMap] call _fnc_safeLoad;
        profileNamespace setVariable [_resVar, _resData];

        if (!isNil "FLO_OPFOR_Resources") then {
            private _resourceLoadResult = FLO_OPFOR_Resources call ["loadResources", []];
            if (_resourceLoadResult) then {
                [[west,"HQ"], "OPFOR resources state loaded successfully..."] remoteExec ["sideChat", 0];
                ["LOAD", 3, "OPFOR resources loaded successfully"] call FLO_fnc_log;
            };
        };
        ["Resources"] call _fnc_updateProgress;
    } catch {
        ["LOAD", 1, format["Failed to load resources: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // STRUCTURE MARKERS AND INITIALIZATION
    // ============================================================================

    private _fnc_loadStructures = {
        try {
            private _structureTypes = [_data, "structureTypes", []] call _fnc_safeLoad;
            private _fobTypeClass = _structureTypes param [0, ""];
            private _opTypeClass = _structureTypes param [1, ""];
            private _structureMarkerHash = [_data, "structureMarkers", createHashMap] call _fnc_safeLoad;

            ["LOAD", 5, format["Structure types: FOB=%1, OP=%2", _fobTypeClass, _opTypeClass]] call FLO_fnc_log;
            ["LOAD", 5, format["Structure markers to load: %1", keys _structureMarkerHash]] call FLO_fnc_log;

            if (count _structureMarkerHash > 0) then {
                private _restoredFOBs = 0;
                private _restoredOPs = 0;

                // Structure search using chunks
                private _fnc_findStructuresInChunks = {
                    params ["_typeClasses"];

                    private _foundStructures = [];

                    // Search in 2km chunks
                    for "_x" from 0 to worldSize step 2000 do {
                        for "_y" from 0 to worldSize step 2000 do {
                            private _chunkPos = [_x, _y, 0];
                            private _structures = _chunkPos nearEntities [_typeClasses, 1500];
                            _foundStructures append _structures;
                        };
                    };

                    // Remove duplicates
                    _foundStructures arrayIntersect _foundStructures
                };

                // Process saved structure data - create missing structures if needed
                {
                    private _structureId = _x;
                    private _markerData = _structureMarkerHash get _structureId;
                    _markerData params ["_markerName", "_type"];

                    // Extract position from ID
                    private _idParts = _structureId splitString "_";
                    if (count _idParts >= 3) then {
                        private _pos = [
                            parseNumber (_idParts select 0),
                            parseNumber (_idParts select 1),
                            parseNumber (_idParts select 2)
                        ];

                        // Check if structure already exists at this position
                        private _existingStructures = _pos nearEntities [["Building"], 15];
                        private _foundExisting = false;

                        {
                            if (typeOf _x in [_fobTypeClass, _opTypeClass, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"]) then {
                                // Found existing structure, restore its data
                                _x setVariable [if (_type isEqualTo "FOB") then {"fobMarkerName"} else {"opMarkerName"}, _markerName, true];
                                _x setVariable [format["FLO_%1_MarkersRestored", _type], true, true];

                                if (_type isEqualTo "FOB") then {
                                    [_x, true] call FLO_fnc_initializeFOB;
                                    _restoredFOBs = _restoredFOBs + 1;
                                } else {
                                    [_x, true] call FLO_fnc_initializeOP;
                                    _restoredOPs = _restoredOPs + 1;
                                };

                                _foundExisting = true;
                                ["LOAD", 5, format["Restored existing %1 structure at %2", _type, _pos]] call FLO_fnc_log;
                            };
                        } forEach _existingStructures;

                        // If no existing structure found, create it
                        if (!_foundExisting) then {
                            private _structureClass = if (_type isEqualTo "FOB") then {_fobTypeClass} else {_opTypeClass};

                            if (_structureClass != "") then {
                                private _newStructure = createVehicle [_structureClass, _pos, [], 0, "CAN_COLLIDE"];

                                if (!isNull _newStructure) then {
                                    _newStructure setPosASL _pos;
                                    _newStructure setVariable [if (_type isEqualTo "FOB") then {"fobMarkerName"} else {"opMarkerName"}, _markerName, true];
                                    _newStructure setVariable [format["FLO_%1_MarkersRestored", _type], true, true];

                                    if (_type isEqualTo "FOB") then {
                                        [_newStructure, true] call FLO_fnc_initializeFOB;
                                        _restoredFOBs = _restoredFOBs + 1;
                                    } else {
                                        [_newStructure, true] call FLO_fnc_initializeOP;
                                        _restoredOPs = _restoredOPs + 1;
                                    };

                                    ["LOAD", 3, format["Created missing %1 structure at %2", _type, _pos]] call FLO_fnc_log;
                                };
                            };
                        };
                    };
                } forEach (keys _structureMarkerHash);

                ["LOAD", 3, format["Restored %1 FOBs and %2 OPs", _restoredFOBs, _restoredOPs]] call FLO_fnc_log;
            };

        } catch {
            ["LOAD", 1, format["Failed to load structures: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_loadStructures;
    ["Structures"] call _fnc_updateProgress;

    // ============================================================================
    // SUPPLY CRATES
    // ============================================================================

    private _fnc_loadCrates = {
        try {
            private _crateHash = [_data, "crates", createHashMap] call _fnc_safeLoad;
            private _loadedCrates = 0;

            {
                private _crateId = _x;
                private _attr = _crateHash get _crateId;

                if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                    private _type = [_attr, "type", ""] call _fnc_safeLoad;

                    if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                        private _pos = [_attr, "posASL", [0,0,0]] call _fnc_safeLoad;
                        private _crate = createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"];

                        if (!isNull _crate) then {
                            // Initialize empty ammo box
                            [_crate, [[],[],[],[]]] call BIS_fnc_initAmmoBox;

                            _crate setVectorDirAndUp ([_attr, "vectorDirAndUp", [[0,1,0], [0,0,1]]] call _fnc_safeLoad);
                            _crate setPosASL _pos;
                            _crate setDamage ([_attr, "damage", 0] call _fnc_safeLoad);
                            _crate lock ([_attr, "locked", 0] call _fnc_safeLoad);
                            _crate setVariable ["FLO_save_crate", true, true];
                            _crate setVariable ["FLO_SaveID", _crateId, true];

                            // Load items
                            private _items = [_attr, "items", []] call _fnc_safeLoad;
                            _crate setVariable ["FLO_crate_items", _items, true];

                            // Add items by type
                            {
                                _x params ["_itemClass", "_count", ["_itemType", "item"]];

                                switch (_itemType) do {
                                    case "weapon": { _crate addWeaponCargoGlobal [_itemClass, _count]; };
                                    case "magazine": { _crate addMagazineCargoGlobal [_itemClass, _count]; };
                                    case "backpack": { _crate addBackpackCargoGlobal [_itemClass, _count]; };
                                    default { _crate addItemCargoGlobal [_itemClass, _count]; };
                                };
                            } forEach _items;

                            // Make draggable with ACE
                            [_crate, true, [0,2,0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, true];

                            _loadedCrates = _loadedCrates + 1;
                        };
                    };
                };
            } forEach (keys _crateHash);

            ["LOAD", 5, format["Loaded %1 supply crates", _loadedCrates]] call FLO_fnc_log;

        } catch {
            ["LOAD", 1, format["Failed to load crates: %1", _exception]] call FLO_fnc_log;
        };
    };

    call _fnc_loadCrates;
    ["Supply Crates"] call _fnc_updateProgress;

    // ============================================================================
    // VIRTUAL GROUPS (ASYNC)
    // ============================================================================

    // Load virtual groups asynchronously
    [{
        !isNil "FLO_OPFOR_Resources" && {!isNil "F_Init" && {F_Init}}
    }, {
        params ["_data"];

        try {
            // Direct access to avoid _fnc_safeLoad issues with Virtual Groups specifically
            private _groupsHash = _data get "virtualGroups";
            if (isNil "_groupsHash") then {
                _groupsHash = createHashMap;
            };

            ["LOAD", 3, format["Virtual groups to load: %1", keys _groupsHash]] call FLO_fnc_log;

            if (count _groupsHash > 0) then {

                ["LOAD", 3, "Virtual groups found, initializing virtualization system"] call FLO_fnc_log;

                // Ensure virtualization is properly initialized
                if (isNil "FLO_virtualGroups") then {
                    [2000] call FLO_fnc_initVirtualization;

                    // Wait a moment for initialization to complete
                    [{!isNil "FLO_virtualGroups"}, {
                        params ["_groupsHash"];

                        InitializationOG = true;
                        publicVariable "InitializationOG";

                        private _loadedGroups = 0;
                        {
                            private _groupData = _y;

                            private _newId = [
                                _groupData get "position",
                                _groupData get "groupType",
                                nil,
                                _groupData get "objective",
                                _groupData get "unitCount",
                                _groupData get "side"
                            ] call FLO_fnc_createVirtualGroup;

                            if (_newId != "") then {
                                private _newData = (FLO_virtualGroups get "_groups") get _newId;
                                if (!isNil "_newData") then {
                                    _newData set ["state", _groupData get "state"];
                                    _newData set ["waypoints", _groupData get "waypoints"];
                                    _newData set ["currentWaypointIndex", _groupData get "currentWaypointIndex"];
                                    _newData set ["garrisonPosition", _groupData getOrDefault ["garrisonPosition", []]];
                                    _newData set ["garrisonObjective", _groupData getOrDefault ["garrisonObjective", ""]];
                                    _loadedGroups = _loadedGroups + 1;
                                };
                            };
                        } forEach _groupsHash;

                        ["LOAD", 3, format["Loaded %1 virtual groups successfully", _loadedGroups]] call FLO_fnc_log;

                        // Ensure the virtualization system is running
                        if (!isNil "FLO_virtualGroups") then {
                            FLO_virtualGroups call ["startSystem", []];
                        };

                    }, [_groupsHash], 1] call CBA_fnc_waitUntilAndExecute;
                } else {
                    // Virtualization already exists, load groups directly
                    InitializationOG = true;
                    publicVariable "InitializationOG";

                    private _loadedGroups = 0;
                    {
                        private _groupData = _y;

                        private _newId = [
                            _groupData get "position",
                            _groupData get "groupType",
                            nil,
                            _groupData get "objective",
                            _groupData get "unitCount",
                            _groupData get "side"
                        ] call FLO_fnc_createVirtualGroup;

                        if (_newId != "") then {
                            private _newData = (FLO_virtualGroups get "_groups") get _newId;
                            if (!isNil "_newData") then {
                                _newData set ["state", _groupData get "state"];
                                _newData set ["waypoints", _groupData get "waypoints"];
                                _newData set ["currentWaypointIndex", _groupData get "currentWaypointIndex"];
                                _newData set ["garrisonPosition", _groupData getOrDefault ["garrisonPosition", []]];
                                _newData set ["garrisonObjective", _groupData getOrDefault ["garrisonObjective", ""]];
                                _loadedGroups = _loadedGroups + 1;
                            };
                        };
                    } forEach _groupsHash;

                    ["LOAD", 3, format["Loaded %1 virtual groups", _loadedGroups]] call FLO_fnc_log;
                };
            } else {
                ["LOAD", 3, "No virtual groups to load"] call FLO_fnc_log;
                // Still set InitializationOG to prevent normal objective group creation
                InitializationOG = true;
                publicVariable "InitializationOG";
            };

        } catch {
            ["LOAD", 1, format["Failed to load virtual groups: %1", _exception]] call FLO_fnc_log;
        };
    }, [_data]] call CBA_fnc_waitUntilAndExecute;

    ["Virtual Groups"] call _fnc_updateProgress;

    // ============================================================================
    // OBJECTIVES
    // ============================================================================

    try {
        if ("objectives" in _data) then {
            FLO_Objectives = _data get "objectives";
            publicVariable "FLO_Objectives";

            private _loadedObjectives = 0;

            // Create markers for all objectives
            {
                private _id = _x;
                private _objData = FLO_Objectives get _id;
                private _pos = [_objData, "position", [0,0,0]] call _fnc_safeLoad;
                private _radius = [_objData, "radius", 100] call _fnc_safeLoad;
                private _owner = [_objData, "owner", east] call _fnc_safeLoad;
                private _markerName = format ["obj_%1", _id];

                // Delete existing marker if it exists
                if (getMarkerColor _markerName != "") then {
                    deleteMarker _markerName;
                };

                // Create new marker
                private _marker = createMarker [_markerName, _pos];
                _marker setMarkerShape "ELLIPSE";
                _marker setMarkerSize [_radius, _radius];

                private _color = switch (_owner) do {
                    case west: {"colorBLUFOR"};
                    case east: {"colorOPFOR"};
                    case resistance: {"ColorGUER"};
                    default {"ColorBlack"};
                };
                _marker setMarkerColor _color;
                _marker setMarkerAlpha 0.3;
                _marker setMarkerBrush "Solid";
                _marker setMarkerText format["%1", _id];

                _loadedObjectives = _loadedObjectives + 1;
            } forEach (keys FLO_Objectives);

            // Build road links between objectives
            [false] spawn FLO_fnc_buildObjectiveGraph;

            // Start monitoring objective dominance
            [] spawn FLO_fnc_monitorObjectiveDominance;

            ["LOAD", 3, format["Loaded %1 objectives", _loadedObjectives]] call FLO_fnc_log;
        };
        ["Objectives"] call _fnc_updateProgress;
    } catch {
        ["LOAD", 1, format["Failed to load objectives: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // AI COMMANDER STATE
    // ============================================================================

    try {
        if ("aiCommander" in _data) then {
            if (isNil "FLO_AI_Commander") then {
                FLO_AI_Commander = [] call FLO_fnc_aiCommander;
            };

            private _cmd = [_data, "aiCommander", createHashMap] call _fnc_safeLoad;
            FLO_AI_Commander set ["_threatLevel", [_cmd, "threatLevel", 0] call _fnc_safeLoad];
            FLO_AI_Commander set ["_lastUpdate", [_cmd, "lastUpdate", time] call _fnc_safeLoad];
            FLO_AI_Commander set ["_attackOperations", [_cmd, "attackOperations", []] call _fnc_safeLoad];
            FLO_AI_Commander set ["_activeAttackGroups", [_cmd, "activeAttackGroups", []] call _fnc_safeLoad];
            FLO_AI_Commander set ["_activeDefenseGroups", [_cmd, "activeDefenseGroups", []] call _fnc_safeLoad];
            FLO_AI_Commander set ["_garrisonedGroups", [_cmd, "garrisonedGroups", []] call _fnc_safeLoad];

            ["LOAD", 3, "AI Commander state restored"] call FLO_fnc_log;
        };
        ["AI Commander"] call _fnc_updateProgress;
    } catch {
        ["LOAD", 1, format["Failed to load AI Commander: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // MISSION VARIABLES
    // ============================================================================

    try {
        // Restore mission setup variables efficiently
        private _missionVars = [
            ["friendlyHandle", "FLO_FriendlyHandle"],
            ["enemyHandle", "FLO_EnemyHandle"],
            ["civilianHandle", "FLO_CivilianHandle"],
            ["moneyHandle", "FLO_MoneyHandle"],
            ["difficultyHandle", "FLO_DifficultyHandle"],
            ["reputationHandle", "FLO_ReputationHandle"],
            ["enemyPrec", "EnemyPrec"]
        ];

        private _loadedVars = 0;
        {
            _x params ["_saveKey", "_varName"];
            if (_saveKey in _data) then {
                private _value = [_data, _saveKey, nil] call _fnc_safeLoad;
                if (!isNil "_value") then {
                    missionNamespace setVariable [_varName, _value];
                    publicVariable _varName;
                    _loadedVars = _loadedVars + 1;
                };
            };
        } forEach _missionVars;

        ["LOAD", 3, format["Loaded %1 mission variables", _loadedVars]] call FLO_fnc_log;
        ["Mission Variables"] call _fnc_updateProgress;
    } catch {
        ["LOAD", 1, format["Failed to load mission variables: %1", _exception]] call FLO_fnc_log;
    };

    // ============================================================================
    // FINALIZATION
    // ============================================================================

    private _loadTime = diag_tickTime - _loadStartTime;
    ["LOAD", 3, format["Mission loaded successfully in %1 seconds (%2/%3 modules)",
        round(_loadTime * 100) / 100, _completedModules, _totalModules]] call FLO_fnc_log;

    // Trigger load completion event
    ["flo_mission_load_completed", [true, _data]] call CBA_fnc_globalEvent;

    MissionLoadedLitterally = true;
    publicVariable "MissionLoadedLitterally";

    true

} catch {
    ["LOAD", 1, format["Critical load error: %1", _exception]] call FLO_fnc_log;
    MissionLoadedLitterally = true;
    publicVariable "MissionLoadedLitterally";
    false
};

};
