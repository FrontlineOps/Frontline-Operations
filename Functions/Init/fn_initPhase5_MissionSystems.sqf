/*
 * Function: FLO_fnc_initPhase5_MissionSystems
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 5: Start all mission systems (side missions, AI commander, etc.)
 *   This runs AFTER objectives are indexed and virtualization is complete.
 *   Also handles MissionStartup (FOBs, OPs, etc.) and entity restoration from saves.
 *
 * Arguments: None
 * Returns: Boolean - True if systems started successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P5] Starting mission systems...";

// Verify prerequisites
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith {
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

// ============================================
// RESTORE FOBs AND OPs FROM SAVE
// ============================================
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    diag_log "[FLO_INIT_P5] Restoring FOBs and OPs from save...";

    private _savedData = FLO_SavedGameData;

    // Restore FOBs
    if ("fobs" in _savedData) then {
        private _fobArray = _savedData get "fobs";
        private _fobCount = 0;

        {
            private _fobData = _x;

            // Create the FOB building
            private _buildingType = _fobData getOrDefault ["buildingType", ""];
            private _buildingPos = _fobData getOrDefault ["buildingPosASL", []];

            if (_buildingType != "" && count _buildingPos > 0) then {
                private _building = createVehicle [_buildingType, [0,0,0], [], 0, "CAN_COLLIDE"];
                _building setPosASL _buildingPos;
                _building setDir (_fobData getOrDefault ["buildingDir", 0]);
                _building setVectorUp (_fobData getOrDefault ["buildingVectorUp", [0,0,1]]);

                // Store marker name for later initialization
                private _markerName = _fobData getOrDefault ["markerName", ""];
                if (_markerName != "") then {
                    _building setVariable ["fobMarkerName", _markerName, true];
                    _building setVariable ["FLO_FOB_MarkersRestored", true, true];
                };

                // Create the container if saved
                private _containerType = _fobData getOrDefault ["containerType", ""];
                private _containerPos = _fobData getOrDefault ["containerPosASL", []];

                if (_containerType != "" && count _containerPos > 0) then {
                    private _container = createVehicle [_containerType, [0,0,0], [], 0, "CAN_COLLIDE"];
                    _container setPosASL _containerPos;
                    _container setDir (_fobData getOrDefault ["containerDir", 0]);
                    _container setVectorUp (_fobData getOrDefault ["containerVectorUp", [0,0,1]]);
                };

                _fobCount = _fobCount + 1;
                diag_log format ["[FLO_INIT_P5] Restored FOB at %1", _buildingPos];
            };
        } forEach _fobArray;

        diag_log format ["[FLO_INIT_P5] Restored %1 FOBs from save", _fobCount];
    };

    // Restore OPs
    if ("ops" in _savedData) then {
        private _opArray = _savedData get "ops";
        private _opCount = 0;

        {
            private _opData = _x;

            // Create the OP building
            private _buildingType = _opData getOrDefault ["buildingType", ""];
            private _buildingPos = _opData getOrDefault ["buildingPosASL", []];

            if (_buildingType != "" && count _buildingPos > 0) then {
                private _building = createVehicle [_buildingType, [0,0,0], [], 0, "CAN_COLLIDE"];
                _building setPosASL _buildingPos;
                _building setDir (_opData getOrDefault ["buildingDir", 0]);
                _building setVectorUp (_opData getOrDefault ["buildingVectorUp", [0,0,1]]);

                // Store marker name for later initialization
                private _markerName = _opData getOrDefault ["markerName", ""];
                if (_markerName != "") then {
                    _building setVariable ["opMarkerName", _markerName, true];
                    _building setVariable ["FLO_OP_MarkersRestored", true, true];
                };

                // Create the container if saved
                private _containerType = _opData getOrDefault ["containerType", ""];
                private _containerPos = _opData getOrDefault ["containerPosASL", []];

                if (_containerType != "" && count _containerPos > 0) then {
                    private _container = createVehicle [_containerType, [0,0,0], [], 0, "CAN_COLLIDE"];
                    _container setPosASL _containerPos;
                    _container setDir (_opData getOrDefault ["containerDir", 0]);
                    _container setVectorUp (_opData getOrDefault ["containerVectorUp", [0,0,1]]);
                };

                _opCount = _opCount + 1;
                diag_log format ["[FLO_INIT_P5] Restored OP at %1", _buildingPos];
            };
        } forEach _opArray;

        diag_log format ["[FLO_INIT_P5] Restored %1 OPs from save", _opCount];
    };
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

// ============================================
// ENTITY RESTORATION FROM SAVE
// ============================================
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    diag_log "[FLO_INIT_P5] Restoring entities from save...";

    private _savedData = FLO_SavedGameData;

    // Restore markers
    if ("markers" in _savedData) then {
        private _markerHash = _savedData get "markers";
        private _loadedMarkers = 0;

        {
            private _markerName = _x;
            private _attr = _markerHash get _markerName;

            if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                if (getMarkerColor _markerName != "") then { deleteMarker _markerName };

                private _marker = createMarker [_markerName, [0,0,0]];
                _marker setMarkerPos (_attr getOrDefault ["pos", [0,0,0]]);
                _marker setMarkerType (_attr getOrDefault ["type", "mil_dot"]);
                _marker setMarkerBrush (_attr getOrDefault ["brush", "Solid"]);
                _marker setMarkerShape (_attr getOrDefault ["shape", "ICON"]);
                _marker setMarkerSize (_attr getOrDefault ["size", [1,1]]);
                _marker setMarkerText (_attr getOrDefault ["text", ""]);
                _marker setMarkerDir (_attr getOrDefault ["dir", 0]);
                _marker setMarkerColor (_attr getOrDefault ["color", "ColorBlack"]);
                _marker setMarkerAlpha (_attr getOrDefault ["alpha", 1]);

                _loadedMarkers = _loadedMarkers + 1;
            };
        } forEach (keys _markerHash);

        diag_log format ["[FLO_INIT_P5] Restored %1 markers", _loadedMarkers];
    };

    // Restore date/time
    if ("time" in _savedData) then {
        private _date = _savedData get "time";
        if (!isNil "_date" && {_date isEqualType []}) then {
            setDate _date;
            diag_log format ["[FLO_INIT_P5] Restored mission time: %1", _date];
        };
    };

    // Restore vehicles
    if ("vehicles" in _savedData) then {
        private _vehHash = _savedData get "vehicles";
        private _loadedVehicles = 0;

        {
            private _vehId = _x;
            private _attr = _vehHash get _vehId;

            if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                private _type = _attr getOrDefault ["type", ""];

                if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                    private _veh = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];

                    if (!isNull _veh) then {
                        _veh setVectorDirAndUp (_attr getOrDefault ["vectorDirAndUp", [[0,1,0], [0,0,1]]]);
                        _veh setPosATL (_attr getOrDefault ["posATL", [0,0,0]]);
                        _veh setFuel (_attr getOrDefault ["fuel", 1]);
                        _veh setDamage (_attr getOrDefault ["damage", 0]);
                        _veh lock (_attr getOrDefault ["locked", 0]);
                        _veh setVariable ["FLO_SaveID", _vehId, true];

                        // Load hitpoint damages
                        private _damagedHitpoints = _attr getOrDefault ["damagedHitpoints", []];
                        { _x params ["_hp", "_dmg"]; _veh setHitPointDamage [_hp, _dmg]; } forEach _damagedHitpoints;

                        if (_attr getOrDefault ["engineOn", false]) then { _veh engineOn true; };

                        _loadedVehicles = _loadedVehicles + 1;
                    };
                };
            };
        } forEach (keys _vehHash);

        diag_log format ["[FLO_INIT_P5] Restored %1 vehicles", _loadedVehicles];
    };

    // Restore objects
    if ("objects" in _savedData) then {
        private _objHash = _savedData get "objects";
        private _loadedObjects = 0;

        {
            private _objId = _x;
            private _attr = _objHash get _objId;

            if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                private _type = _attr getOrDefault ["type", ""];

                if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                    private _obj = createVehicle [_type, [0,0,0], [], 0, "CAN_COLLIDE"];

                    if (!isNull _obj) then {
                        _obj setVectorDirAndUp (_attr getOrDefault ["vectorDirAndUp", [[0,1,0], [0,0,1]]]);
                        _obj setPosASL (_attr getOrDefault ["posASL", [0,0,0]]);
                        _obj setDamage (_attr getOrDefault ["damage", 0]);
                        _obj setVariable ["IDS_Logistics_isPlacedEntity", _attr getOrDefault ["isPlacedEntity", false], true];
                        _obj setVariable ["FLO_SaveID", _objId, true];

                        _loadedObjects = _loadedObjects + 1;
                    };
                };
            };
        } forEach (keys _objHash);

        diag_log format ["[FLO_INIT_P5] Restored %1 objects", _loadedObjects];
    };

    // Restore supply crates
    if ("crates" in _savedData) then {
        private _crateHash = _savedData get "crates";
        private _loadedCrates = 0;

        {
            private _crateId = _x;
            private _attr = _crateHash get _crateId;

            if (!isNil "_attr" && {_attr isEqualType createHashMap}) then {
                private _type = _attr getOrDefault ["type", ""];

                if (_type != "" && {isClass (configFile >> "CfgVehicles" >> _type)}) then {
                    private _pos = _attr getOrDefault ["posASL", [0,0,0]];
                    private _crate = createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"];

                    if (!isNull _crate) then {
                        [_crate, [[],[],[],[]]] call BIS_fnc_initAmmoBox;
                        _crate setVectorDirAndUp (_attr getOrDefault ["vectorDirAndUp", [[0,1,0], [0,0,1]]]);
                        _crate setPosASL _pos;
                        _crate setDamage (_attr getOrDefault ["damage", 0]);
                        _crate setVariable ["FLO_save_crate", true, true];
                        _crate setVariable ["FLO_SaveID", _crateId, true];

                        // Load items
                        private _items = _attr getOrDefault ["items", []];
                        {
                            _x params ["_itemClass", "_count", ["_itemType", "item"]];
                            switch (_itemType) do {
                                case "weapon": { _crate addWeaponCargoGlobal [_itemClass, _count]; };
                                case "magazine": { _crate addMagazineCargoGlobal [_itemClass, _count]; };
                                case "backpack": { _crate addBackpackCargoGlobal [_itemClass, _count]; };
                                default { _crate addItemCargoGlobal [_itemClass, _count]; };
                            };
                        } forEach _items;

                        [_crate, true, [0,2,0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, true];
                        _loadedCrates = _loadedCrates + 1;
                    };
                };
            };
        } forEach (keys _crateHash);

        diag_log format ["[FLO_INIT_P5] Restored %1 supply crates", _loadedCrates];
    };

    // Restore GTN Resource Manager state
    if ("aiCommander" in _savedData) then {
        if (isNil "FLO_GTN_ResourceManager") then {
            FLO_GTN_ResourceManager = [] call FLO_fnc_gtnResourceManager;
        };

        private _cmd = _savedData get "aiCommander";
        if (!isNil "_cmd" && {_cmd isEqualType createHashMap}) then {
            // Core state
            FLO_GTN_ResourceManager set ["_threatLevel", _cmd getOrDefault ["threatLevel", 0]];
            FLO_GTN_ResourceManager set ["_lastUpdate", _cmd getOrDefault ["lastUpdate", time]];

            // Group tracking
            FLO_GTN_ResourceManager set ["_activeAttackGroups", _cmd getOrDefault ["activeAttackGroups", []]];
            FLO_GTN_ResourceManager set ["_activeDefenseGroups", _cmd getOrDefault ["activeDefenseGroups", []]];
            FLO_GTN_ResourceManager set ["_garrisonedGroups", _cmd getOrDefault ["garrisonedGroups", []]];
            FLO_GTN_ResourceManager set ["_strategicReserve", _cmd getOrDefault ["strategicReserve", []]];

            // GTN state - restore if it was initialized
            private _gtnWasEnabled = _cmd getOrDefault ["gtnEnabled", false];
            if (_gtnWasEnabled && {isNil {FLO_GTN_ResourceManager get "_gtnCommander"}}) then {
                FLO_GTN_ResourceManager call ["_initializeGTN", []];
            };

            diag_log "[FLO_INIT_P5] GTN Resource Manager state restored";
        };
    };

    // Restore IDS Logistics placed entities
    if ("idsLogisticsEntities" in _savedData) then {
        private _idsEntities = _savedData get "idsLogisticsEntities";
        private _loadedIDS = 0;

        // Initialize the array if needed
        if (isNil "IDS_Logistics_PlacedEntities") then { IDS_Logistics_PlacedEntities = []; };

        {
            private _entityData = _x;
            private _className = _entityData getOrDefault ["class", ""];

            if (_className != "" && {isClass (configFile >> "CfgVehicles" >> _className)}) then {
                private _entity = createVehicle [_className, [0,0,0], [], 0, "CAN_COLLIDE"];

                if (!isNull _entity) then {
                    _entity setPosASL (_entityData getOrDefault ["posASL", [0,0,0]]);
                    _entity setDir (_entityData getOrDefault ["direction", 0]);
                    _entity setVectorUp (_entityData getOrDefault ["vectorUp", [0,0,1]]);
                    _entity setDamage (_entityData getOrDefault ["damage", 0]);
                    _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];

                    // Add to placed entities array for tracking
                    IDS_Logistics_PlacedEntities pushBack _entity;
                    _loadedIDS = _loadedIDS + 1;
                };
            };
        } forEach _idsEntities;

        diag_log format ["[FLO_INIT_P5] Restored %1 IDS Logistics entities", _loadedIDS];
    };

    // Trigger load completion event
    ["flo_mission_load_completed", [true, _savedData]] call CBA_fnc_globalEvent;

    diag_log "[FLO_INIT_P5] Entity restoration complete";
};

// ============================================
// OPFOR Resource System
// ============================================
diag_log "[FLO_INIT_P5] Starting OPFOR resource system...";
if (!isNil "FLO_fnc_opforResources") then {
    [] spawn FLO_fnc_opforResources;
    diag_log "[FLO_INIT_P5] OPFOR resources started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_opforResources not found";
};

// ============================================
// Logistics Network
// ============================================
diag_log "[FLO_INIT_P5] Starting logistics network...";
if (!isNil "FLO_fnc_logisticsNetwork") then {
    [] spawn FLO_fnc_logisticsNetwork;
    diag_log "[FLO_INIT_P5] Logistics network started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_logisticsNetwork not found";
};

// ============================================
// GTN Resource Manager
// ============================================
diag_log "[FLO_INIT_P5] Starting GTN Resource Manager...";
if (!isNil "FLO_fnc_gtnResourceManager") then {
    [] spawn FLO_fnc_gtnResourceManager;
    diag_log "[FLO_INIT_P5] GTN Resource Manager started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_gtnResourceManager not found";
};

// ============================================
// Side Mission System
// ============================================
diag_log "[FLO_INIT_P5] Initializing side mission system...";

if (!isNil "FLO_fnc_sideMissionManager") then {
    // Initialize the mission manager (sets up state, registry, template storage)
    ["init"] call FLO_fnc_sideMissionManager;
    diag_log "[FLO_INIT_P5] Side mission manager initialized";

    // Register all templates via the templates init function
    if (!isNil "FLO_fnc_sideMissionTemplatesInit") then {
        private _templatesOk = [] call FLO_fnc_sideMissionTemplatesInit;
        if (_templatesOk) then {
            diag_log "[FLO_INIT_P5] Side mission templates registered successfully";
        } else {
            diag_log "[FLO_INIT_P5] WARNING: Some side mission templates failed to register";
        };
    } else {
        diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_sideMissionTemplatesInit not found";
    };

    // Start the mission manager loop
    ["start"] call FLO_fnc_sideMissionManager;
    diag_log "[FLO_INIT_P5] Side mission manager started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_sideMissionManager not found";
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
// Intel System
// ============================================
diag_log "[FLO_INIT_P5] Starting intel system...";
if (!isNil "FLO_fnc_intelSystem") then {
    [] spawn FLO_fnc_intelSystem;
    diag_log "[FLO_INIT_P5] Intel system started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_intelSystem not found";
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

// ============================================
// Pathfinding System
// ============================================
diag_log "[FLO_INIT_P5] Initializing pathfinding...";
if (!isNil "FLO_fnc_initRoadGraph") then {
    [] spawn FLO_fnc_initRoadGraph;
    diag_log "[FLO_INIT_P5] Road graph initialization started";
};

if (!isNil "FLO_fnc_initPFScheduler") then {
    [] spawn FLO_fnc_initPFScheduler;
    diag_log "[FLO_INIT_P5] Pathfinding scheduler started";
};

diag_log "[FLO_INIT_P5] Mission systems phase complete";
true

