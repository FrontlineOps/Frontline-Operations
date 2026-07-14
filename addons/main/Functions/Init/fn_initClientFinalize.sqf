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

["INIT", 3, "Client finalization started"] call FLO_fnc_log;

// Wait for mission loaded screen to finish
waitUntil { !isNull player };
waitUntil { player == player };

if !([] call FLO_fnc_applyMissionConfigLocally) then {
    private _message = "Client finalization received no authoritative mission config";
    ["INIT", 1, _message] call FLO_fnc_log;
    throw _message;
};
FLO_ClientFinalizeDone = true;

// Create respawn marker if needed
private _activeSide = FLO_ActivePlayerSide;
private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
private _respawnMarkerName = format ["respawn_%1", _respawnKey];
private _respawnPos = getMarkerPos _respawnMarkerName;
if (_respawnPos isEqualTo [0,0,0]) then {
    private _startPos = FLO_MissionConfig get "startPosition";
    private _respawnMarker = createMarkerLocal [_respawnMarkerName, _startPos];
    _respawnMarker setMarkerTypeLocal "hd_start";
    _respawnMarker setMarkerTextLocal "Respawn";
    ["INIT", 3, format ["Created %1 respawn marker at %2", _respawnKey, _startPos]] call FLO_fnc_log;
};

private _baseRespawnPos = getMarkerPos _respawnMarkerName;
if (_baseRespawnPos isEqualTo [0,0,0]) then {
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

        private _activeSide = FLO_ActivePlayerSide;
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
["INIT", 3, "Setting up client HUD and UI"] call FLO_fnc_log;

[] call FLO_fnc_initObjectiveRuntimeStateEvents;

["INIT", 4, "Base supply is handled by the FLO Store"] call FLO_fnc_log;

// Set briefing/notes
private _bluforName = (FLO_MissionConfig get "bluforHandle") get "name";
private _opforName = (FLO_MissionConfig get "opforHandle") get "name";

player createDiaryRecord ["Diary", ["Mission Status",
    format ["<font color='#00ff00'>Mission Active</font><br/><br/>BLUFOR: %1<br/>OPFOR: %2<br/><br/>Objectives indexed: %3",
        _bluforName,
        _opforName,
        count FLO_Objectives
    ]
]];

// Set MarLOCC for backwards compatibility
MarLOCC = 1;

[] spawn {
    if !([] call FLO_fnc_initDeployPlayer) exitWith {};

    uiSleep 0.5;
    titleText ["", "BLACK IN", 2, true, true];
    private _msg = "<t size='1.2' color='#00ff00'>Mission Initialized</t><br/><t size='0.9'>All systems ready</t>";
    [_msg, 0, 0.3, 3, 0] spawn BIS_fnc_dynamicText;
    hintSilent "";
    [{
        FLO_ClientUiReady = true;
        ["FLO_ClientUIReady", []] call CBA_fnc_localEvent;
        ["INIT", 3, "Client deployment and UI readiness complete"] call FLO_fnc_log;
    }, [], 2] call CBA_fnc_waitAndExecute;
};
