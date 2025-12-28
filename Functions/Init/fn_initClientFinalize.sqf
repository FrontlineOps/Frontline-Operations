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

diag_log "[FLO_INIT_CLIENT] Mission initialization complete, setting up client...";

// Wait for mission loaded screen to finish
waitUntil { !isNull player };
waitUntil { player == player };

// Create respawn marker if needed
private _respawnPos = getMarkerPos "respawn_west";
if (_respawnPos isEqualTo [0,0,0]) then {
    if (!isNil "FLO_MissionConfig") then {
        private _startPos = FLO_MissionConfig getOrDefault ["startPosition", getPos player];
        private _respawnMarker = createMarkerLocal ["respawn_west", _startPos];
        _respawnMarker setMarkerTypeLocal "hd_start";
        _respawnMarker setMarkerTextLocal "Respawn";
        diag_log format ["[FLO_INIT_CLIENT] Created respawn marker at %1", _startPos];
    };
};

// Initialize client-side systems
diag_log "[FLO_INIT_CLIENT] Setting up HUD and UI...";

// Load arsenal restrictions if enabled (param 0 = enabled, 1 = disabled)
private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;
if (_restrictedArsenal isEqualTo 0 && {!isNil "FLO_fnc_restrictedArsenal"}) then {
    [] call FLO_fnc_restrictedArsenal;
    diag_log "[FLO_INIT_CLIENT] Restricted arsenal enabled";
} else {
    diag_log "[FLO_INIT_CLIENT] Restricted arsenal disabled by mission parameter";
};

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

// Notify player
private _msg = "<t size='1.2' color='#00ff00'>Mission Initialized</t><br/><t size='0.9'>All systems ready</t>";
[_msg, 0, 0.3, 3, 0] spawn BIS_fnc_dynamicText;

diag_log "[FLO_INIT_CLIENT] Client finalization complete";

