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

// ============================================
// HUMAN SIDE LOCK (first connected EAST/WEST side is authoritative)
// ============================================
if (isNil "FLO_ActivePlayerSide") then {
    FLO_ActivePlayerSide = sideUnknown;
    publicVariable "FLO_ActivePlayerSide";
};

[] spawn {
    while {true} do {
        private _players = allPlayers select { side group _x in [east, west] };

        if (!(FLO_ActivePlayerSide in [east, west]) && {_players isNotEqualTo []}) then {
            FLO_ActivePlayerSide = side group (_players select 0);
            publicVariable "FLO_ActivePlayerSide";
            diag_log format ["[FLO_INIT_P5] Active player side locked to %1", FLO_ActivePlayerSide];
        };

        if (FLO_ActivePlayerSide in [east, west]) then {
            {
                private _pSide = side group _x;
                if (_pSide in [east, west] && {_pSide != FLO_ActivePlayerSide}) then {
                    if !(_x getVariable ["FLO_SideLockWarned", false]) then {
                        ["Mission side is locked to the other faction. You are being moved to spectator."] remoteExec ["hint", owner _x];
                        _x setVariable ["FLO_SideLockWarned", true, false];
                    };

                    if !(_x getVariable ["FLO_SideLockedSpectator", false]) then {
                        [true] remoteExec ["BIS_fnc_EGSpectator", owner _x];
                        _x allowDamage false;
                        _x setCaptive true;
                        _x setVariable ["FLO_SideLockedSpectator", true, false];
                    };
                };
            } forEach _players;
        };

        sleep 5;
    };
};

private _fnc_sideResourcesUninitialized = {
    if (isNil "FLO_SideResources") exitWith { true };
    if (!(FLO_SideResources isEqualType createHashMap)) exitWith { true };
    (keys FLO_SideResources) isEqualTo []
};

// Initialize side resources early so restored/started systems can consume them.
if ((call _fnc_sideResourcesUninitialized) && {!isNil "FLO_fnc_sideResources"}) then {
    [] call FLO_fnc_sideResources;
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

            if (_buildingType != "" && _buildingPos isNotEqualTo []) then {
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

                if (_containerType != "" && _containerPos isNotEqualTo []) then {
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

            if (_buildingType != "" && _buildingPos isNotEqualTo []) then {
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

                if (_containerType != "" && _containerPos isNotEqualTo []) then {
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
    if ("markers" in _savedData) then {
        private _markerHash = _savedData get "markers";
        private _loadedMarkers = 0;

        {
            private _markerName = _x;
            private _attr = _markerHash get _markerName;

            if ((_markerName find _combatMarkerPrefix) != 0 && {!isNil "_attr" && {_attr isEqualType createHashMap}}) then {
                if (getMarkerColor _markerName != "") then { deleteMarker _markerName };

                private _marker = createMarker [_markerName, [0,0,0]];
                _marker setMarkerPosLocal (_attr getOrDefault ["pos", [0,0,0]]);
                _marker setMarkerTypeLocal (_attr getOrDefault ["type", "mil_dot"]);
                _marker setMarkerBrushLocal (_attr getOrDefault ["brush", "Solid"]);
                _marker setMarkerShapeLocal (_attr getOrDefault ["shape", "ICON"]);
                _marker setMarkerSizeLocal (_attr getOrDefault ["size", [1,1]]);
                _marker setMarkerTextLocal (_attr getOrDefault ["text", ""]);
                _marker setMarkerDirLocal (_attr getOrDefault ["dir", 0]);
                _marker setMarkerColorLocal (_attr getOrDefault ["color", "ColorBlack"]);
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

    private _fnc_extractVehicleClasses = {
        params [["_list", []]];
        private _result = [];
        {
            if (_x isEqualType []) then {
                if (_x isNotEqualTo []) then {
                    private _cls = _x select 0;
                    if (_cls isEqualType "" && {_cls != ""}) then {
                        _result pushBackUnique _cls;
                    };
                };
            } else {
                if (_x isEqualType "" && {_x != ""}) then {
                    _result pushBackUnique _x;
                };
            };
        } forEach _list;
        _result
    };

    private _trackedCrewTypes = createHashMap;
    private _samList = missionNamespace getVariable ["F_SAM_List", []];
    {
        _trackedCrewTypes set [_x, true];
    } forEach ([_samList] call _fnc_extractVehicleClasses);

    if (!isNil "FLO_FactionRadar" && {FLO_FactionRadar isEqualType ""} && {FLO_FactionRadar != ""}) then {
        _trackedCrewTypes set [FLO_FactionRadar, true];
    };

    private _fnc_restoreTrackedCrew = {
        params ["_entity", "_type", "_attr", "_trackedCrewTypes"];
        if !(_type in _trackedCrewTypes) exitWith {};

        private _restoreCrew = if ("hadAICrew" in _attr) then { _attr get "hadAICrew" } else { true };
        if (!_restoreCrew) exitWith {};

        if (getText (configFile >> "CfgVehicles" >> _type >> "crew") != "") then {
            createVehicleCrew _entity;
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
                        private _isStoreVehicle = if ("storeVehicle" in _attr) then {
                            _attr get "storeVehicle"
                        } else {
                            "requestMenuVehicle" in _attr && {_attr get "requestMenuVehicle"}
                        };
                        if (_isStoreVehicle) then {
                            _veh setVariable ["FLO_StoreVehicle", true, true];
                        };
                        if (_attr getOrDefault ["mobileRespawnVehicle", false]) then {
                            _veh setVariable ["FLO_MobileRespawnVehicle", true, true];
                        };
                        private _supportVehicleRoles = _attr getOrDefault ["supportVehicleRoles", []];
                        if (_supportVehicleRoles isNotEqualTo []) then {
                            _veh setVariable ["FLO_SupportVehicleRoles", _supportVehicleRoles, true];
                        };

                        // Load hitpoint damages
                        private _damagedHitpoints = _attr getOrDefault ["damagedHitpoints", []];
                        { _x params ["_hp", "_dmg"]; _veh setHitPointDamage [_hp, _dmg]; } forEach _damagedHitpoints;

                        if (_attr getOrDefault ["engineOn", false]) then { _veh engineOn true; };
                        [_veh, _type, _attr, _trackedCrewTypes] call _fnc_restoreTrackedCrew;

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
                        [_obj, _type, _attr, _trackedCrewTypes] call _fnc_restoreTrackedCrew;

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

                        [_crate, true, [0,2,0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, _crate];
                        _loadedCrates = _loadedCrates + 1;
                    };
                };
            };
        } forEach (keys _crateHash);

        diag_log format ["[FLO_INIT_P5] Restored %1 supply crates", _loadedCrates];
    };

    // Restore GTN state (dual schema only)
    if ("aiCommanders" in _savedData) then {
        if (isNil "FLO_GTN_ResourceManager") then {
            FLO_GTN_ResourceManager = [] call FLO_fnc_gtnResourceManager;
        };

        private _cmd = _savedData get "aiCommanders";
        if (!isNil "_cmd" && {_cmd isEqualType createHashMap}) then {
            private _eastState = _cmd getOrDefault ["EAST", createHashMap];
            private _westState = _cmd getOrDefault ["WEST", createHashMap];
            private _gtnWasEnabled = (_eastState getOrDefault ["gtnEnabled", false]) || (_westState getOrDefault ["gtnEnabled", false]);

            if (_gtnWasEnabled) then {
                FLO_GTN_ResourceManager call ["_initializeGTN", []];
            };

            diag_log "[FLO_INIT_P5] Dual GTN state restored";
        };
    } else {
        if ("aiCommander" in _savedData) then {
            diag_log "[FLO_INIT_P5] Legacy GTN save payload detected (aiCommander) - intentionally ignored";
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
// Side Resource System
// ============================================
diag_log "[FLO_INIT_P5] Starting side resource system...";
if (!isNil "FLO_fnc_sideResources") then {
    if (call _fnc_sideResourcesUninitialized) then {
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

diag_log "[FLO_INIT_P5] Legacy mission content retired";

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

diag_log "[FLO_INIT_P5] Legacy intel reveal system retired";

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
// Routing System
// ============================================
diag_log format ["[FLO_INIT_P5] Routing mode active: %1", FLO_PF_Mode];

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
