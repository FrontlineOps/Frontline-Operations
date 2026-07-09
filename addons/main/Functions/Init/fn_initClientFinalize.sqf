/*
 * Function: FLO_fnc_initClientFinalize
 * Author: Frontline Operations Development Group
 * Description:
 *   Called on clients when mission initialization is complete.
 *   Sets up client-side systems and UI.
 *
 * Arguments:
 *   0: String - Event name ("FLO_INIT_COMPLETE")
 *   1: Array - Event params (empty)
 *
 * Returns: Nothing
 */

params [["_event", ""], ["_params", []]];

if (isServer && !hasInterface) exitWith {
    // Dedicated server, no client setup needed
};

if (missionNamespace getVariable ["FLO_ClientFinalizeDone", false]) exitWith {};

diag_log "[FLO_INIT_CLIENT] Mission initialization complete, setting up client...";

// Wait for mission loaded screen to finish
waitUntil { !isNull player };
waitUntil { player == player };

FLO_ClientFinalizeDone = true;

[] call FLO_fnc_applyMissionConfigLocally;

// Create respawn marker if needed
private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", side player];
private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
private _respawnMarkerName = format ["respawn_%1", _respawnKey];
private _respawnPos = getMarkerPos _respawnMarkerName;
if (_respawnPos isEqualTo [0,0,0]) then {
    if (!isNil "FLO_MissionConfig") then {
        private _startPos = FLO_MissionConfig getOrDefault ["startPosition", getPos player];
        private _respawnMarker = createMarkerLocal [_respawnMarkerName, _startPos];
        _respawnMarker setMarkerTypeLocal "hd_start";
        _respawnMarker setMarkerTextLocal "Respawn";
        diag_log format ["[FLO_INIT_CLIENT] Created respawn marker at %1", _startPos];
    };
};

private _baseRespawnPos = getMarkerPos _respawnMarkerName;
if (_baseRespawnPos isEqualTo [0,0,0] && {!isNil "FLO_MissionConfig"}) then {
    _baseRespawnPos = FLO_MissionConfig get "startPosition";
};

[_respawnMarkerName, _baseRespawnPos] spawn {
    params ["_markerName", "_basePos"];

    waitUntil {
        sleep 0.5;
        !isNil "FLO_Objectives"
    };

    while {true} do {
        if (_basePos isEqualTo [0,0,0]) then {
            sleep 5;
            continue;
        };

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", side player];
        if !(_activeSide in [east, west]) then {
            sleep 5;
            continue;
        };

        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        private _owner = sideUnknown;

        {
            private _objData = FLO_Objectives get _x;
            if ([_basePos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
                _owner = _objData get "owner";
            };
        } forEach (keys FLO_Objectives);

        if (_owner isEqualType "") then {
            private _ownerKey = toUpper _owner;
            if (_ownerKey isEqualTo "EAST") then { _owner = east; };
            if (_ownerKey isEqualTo "WEST") then { _owner = west; };
        };

        if (_owner isEqualTo _enemySide) then {
            if (_markerName in allMapMarkers) then {
                deleteMarker _markerName;
            };
        } else {
            if !(_markerName in allMapMarkers) then {
                private _m = createMarkerLocal [_markerName, _basePos];
                _m setMarkerTypeLocal "hd_start";
                _m setMarkerTextLocal "Respawn";
            };
        };

        sleep 5;
    };
};

// Initialize client-side systems
diag_log "[FLO_INIT_CLIENT] Setting up HUD and UI...";

[] call FLO_fnc_initObjectiveRuntimeStateEvents;
[] call FLO_fnc_gtnRefreshCommanderSupplyToggleAction;
[] call FLO_fnc_gtnRefreshPlayerSupportActions;
if (!FLO_GTN_CommanderSupplyRespawnHandlerAdded) then {
    addMissionEventHandler ["EntityRespawned", {
        params ["_newUnit", "_oldUnit"];

        if (_newUnit isEqualTo player) then {
            if (FLO_GTN_CommanderSupplyToggleActionId >= 0 && {!isNull FLO_GTN_CommanderSupplyToggleActionOwner}) then {
                FLO_GTN_CommanderSupplyToggleActionOwner removeAction FLO_GTN_CommanderSupplyToggleActionId;
            };
            FLO_GTN_CommanderSupplyToggleActionId = -1;
            FLO_GTN_CommanderSupplyToggleActionOwner = objNull;
            if (!isNull FLO_GTN_PlayerSupportActionOwner) then {
                {
                    FLO_GTN_PlayerSupportActionOwner removeAction _x;
                } forEach FLO_GTN_PlayerSupportActionIds;
            };
            {
                player removeAction _x;
            } forEach FLO_GTN_PlayerSupportActionIds;
            FLO_GTN_PlayerSupportActionIds = [];
            FLO_GTN_PlayerSupportActionOwner = objNull;
            if (FLO_GTN_PlayerSupportMapClickEhId >= 0) then {
                removeMissionEventHandler ["MapSingleClick", FLO_GTN_PlayerSupportMapClickEhId];
                FLO_GTN_PlayerSupportMapClickEhId = -1;
            };
            FLO_GTN_PlayerSupportPendingType = "";
            FLO_GTN_PlayerSupportCancelWatcherRunning = false;
            [] call FLO_fnc_gtnRefreshCommanderSupplyToggleAction;
            [] call FLO_fnc_gtnRefreshPlayerSupportActions;
        };
    }];
    FLO_GTN_CommanderSupplyRespawnHandlerAdded = true;
};

diag_log "[FLO_INIT_CLIENT] Base supply is handled by the FLO Store.";

// Set briefing/notes
if (!isNil "FLO_MissionConfig") then {
    private _friendlyName = (FLO_MissionConfig getOrDefault ["friendlyHandle", createHashMap]) getOrDefault ["name", "Unknown"];
    private _enemyName = (FLO_MissionConfig getOrDefault ["enemyHandle", createHashMap]) getOrDefault ["name", "Unknown"];
    
    player createDiaryRecord ["Diary", ["Mission Status", 
        format ["<font color='#00ff00'>Mission Active</font><br/><br/>Friendly Forces: %1<br/>Enemy Forces: %2<br/><br/>Objectives indexed: %3",
            _friendlyName,
            _enemyName,
            count (missionNamespace getVariable ["FLO_Objectives", []])
        ]
    ]];
};

// Set MarLOCC for backwards compatibility
MarLOCC = 1;

private _respawnRequired = missionNamespace getVariable ["FLO_InitRespawnRequired", false];
private _respawnDone = missionNamespace getVariable ["FLO_InitRespawnDone", false];
if (_respawnRequired && {!_respawnDone}) then {
    missionNamespace setVariable ["FLO_InitRespawnDone", true, false];
    [_respawnMarkerName] spawn {
        params ["_markerName"];

        titleText ["Deploying...", "BLACK FADED", 0.1, true, true];
        waitUntil {
            sleep 0.1;
            !isNull player && {player == player} && {_markerName in allMapMarkers}
        };

        diag_log "[FLO_INIT_CLIENT] Forcing one-time init respawn";
        forceRespawn player;

        waitUntil {
            sleep 0.1;
            !isNull player && {player == player} && {alive player}
        };

        uiSleep 0.5;
        titleText ["", "BLACK IN", 2, true, true];
        private _msg = "<t size='1.2' color='#00ff00'>Mission Initialized</t><br/><t size='0.9'>All systems ready</t>";
        [_msg, 0, 0.3, 3, 0] spawn BIS_fnc_dynamicText;
        hintSilent "";
    };
} else {
    titleText ["", "BLACK IN", 2, true, true];
    private _msg = "<t size='1.2' color='#00ff00'>Mission Initialized</t><br/><t size='0.9'>All systems ready</t>";
    [_msg, 0, 0.3, 3, 0] spawn BIS_fnc_dynamicText;
};

diag_log "[FLO_INIT_CLIENT] Client finalization complete";
