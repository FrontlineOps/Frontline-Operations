/*
 * Function: FLO_fnc_monitorObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Continuously checks unit presence at objectives and flips ownership
 *   when one side holds dominance for a period of time.
 *   Updates FLO_Objectives which is publicVariable'd for client UI sync.
 *   Fires CBA target events to clients when they enter/leave objectives.
 *
 * Arguments: None
 *
 * Returns: Nothing (runs indefinitely)
 *
 * Example:
 *   [] spawn FLO_fnc_monitorObjectiveDominance;
 */

if (!isServer) exitWith {};

["OBJECTIVEMONITOR", 2, "MonitorObjectiveDominance started"] call FLO_fnc_log;

// Wait for objectives to be initialized
waitUntil { !isNil "FLO_Objectives" };
["OBJECTIVEMONITOR", 3, "FLO_Objectives initialized"] call FLO_fnc_log;

// Get config values
private _captureTime = ["get", "captureTime"] call FLO_fnc_objectiveConfig;

// 0.5s is reasonable for capture logic; clients poll faster for UI
private _updateInterval = 0.5;

// Track time for progress calculation
private _lastTickTime = diag_tickTime;

// Track which objective each player is in (for CBA event firing)
// HashMap: playerUID -> objectiveId (or "" if not in any)
FLO_PlayerObjectiveStates = createHashMap;

while {true} do {
    private _currentTime = diag_tickTime;
    private _deltaTime = _currentTime - _lastTickTime;
    _lastTickTime = _currentTime;

    // Safety check
    if (isNil "FLO_Objectives") then {
        ["OBJECTIVEMONITOR", 2, "FLO_Objectives undefined, waiting..."] call FLO_fnc_log;
        waitUntil { !isNil "FLO_Objectives" };
    };

    private _dataChanged = false;

    {
        private _id = _x;
        private _data = FLO_Objectives get _id;
        if (isNil "_data") then { continue };

        private _pos = _data get "position";
        private _owner = _data getOrDefault ["owner", east];
        private _progress = _data getOrDefault ["captureProgress", 0];

        // Count units in objective using centralized check
        private _bluforCount = 0;
        private _opforCount = 0;

        {
            if (alive _x) then {
                private _unitPos = getPos _x;
                if ([_unitPos, _data] call FLO_fnc_isPositionInObjective) then {
                    switch (side _x) do {
                        case west: { _bluforCount = _bluforCount + 1 };
                        case east: { _opforCount = _opforCount + 1 };
                    };
                };
            };
        } forEach allUnits;

        // Include virtual groups
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups getOrDefault ["_groups", createHashMap];
            {
                private _gData = _y;
                if (isNil "_gData") then { continue };

                private _gSide = _gData getOrDefault ["side", east];
                private _isActive = _gData getOrDefault ["isActive", false];

                if (_gSide isEqualTo east && {!_isActive}) then {
                    private _gPos = _gData get "position";
                    if ([_gPos, _data] call FLO_fnc_isPositionInObjective) then {
                        _opforCount = _opforCount + (_gData getOrDefault ["unitCount", 0]);
                    };
                };
            } forEach _groups;
        };

        // Update capture progress (scaled by deltaTime for frame-rate independence)
        private _progressRate = 1; // 1 unit of progress per second
        if (_bluforCount > _opforCount && {_bluforCount > 0}) then {
            _progress = (_progress + (_deltaTime * _progressRate)) min _captureTime;
        } else {
            if (_opforCount > _bluforCount && {_opforCount > 0}) then {
                _progress = (_progress - (_deltaTime * _progressRate)) max (-_captureTime);
            } else {
                // Decay towards neutral
                if (_progress > 0) then { _progress = (_progress - (_deltaTime * _progressRate)) max 0 };
                if (_progress < 0) then { _progress = (_progress + (_deltaTime * _progressRate)) min 0 };
            };
        };

        // Check for capture
        if (_progress >= _captureTime && {_owner != west}) then {
            [_id, west] call FLO_fnc_flipObjective;
            _progress = 0;
            [0.20, "increase"] call FLO_fnc_adjustAggression;
        } else {
            if (_progress <= -_captureTime && {_owner != east}) then {
                [_id, east] call FLO_fnc_flipObjective;
                _progress = 0;
                [-0.10, "decrease"] call FLO_fnc_adjustAggression;
            };
        };

        // Store progress and counts
        _data set ["captureProgress", _progress];
        _data set ["bluforCount", _bluforCount];
        _data set ["opforCount", _opforCount];
        _data set ["captureTime", _captureTime];
        FLO_Objectives set [_id, _data];
        _dataChanged = true;

    } forEach (keys FLO_Objectives);

    // Sync to clients once per tick (not per objective!)
    if (_dataChanged) then {
        publicVariable "FLO_Objectives";
    };

    // =========================================================================
    // PLAYER OBJECTIVE TRACKING - Fire CBA events to clients
    // =========================================================================
    {
        if (!alive _x) then { continue };
        if (isNull _x) then { continue };

        private _player = _x;
        private _uid = getPlayerUID _player;
        if (_uid == "") then { continue };

        private _playerPos = getPosATL _player;
        private _currentObjId = "";
        private _currentObjData = createHashMap;

        // Find which objective this player is in
        {
            private _objData = FLO_Objectives get _x;
            if (!isNil "_objData") then {
                if ([_playerPos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
                    _currentObjId = _x;
                    _currentObjData = _objData;
                };
            };
        } forEach (keys FLO_Objectives);

        // Get previous state
        private _previousObjId = FLO_PlayerObjectiveStates getOrDefault [_uid, ""];

        // State change detection
        if (_currentObjId != _previousObjId) then {
            // Get owner ID for CBA_fnc_ownerEvent - more reliable on dedicated servers
            private _ownerId = owner _player;

            if (_currentObjId != "") then {
                // Player entered an objective - fire SHOW event
                private _objName = _currentObjData getOrDefault ["name", _currentObjId];
                ["FLO_CaptureUI_Show", [_objName, _currentObjId], _ownerId] call CBA_fnc_ownerEvent;
                ["OBJECTIVEMONITOR", 4, format["CaptureUI_Show fired to %1 (owner %2) for %3", name _player, _ownerId, _objName]] call FLO_fnc_log;
            } else {
                // Player left all objectives - fire HIDE event
                ["FLO_CaptureUI_Hide", [], _ownerId] call CBA_fnc_ownerEvent;
                ["OBJECTIVEMONITOR", 4, format["CaptureUI_Hide fired to %1 (owner %2)", name _player, _ownerId]] call FLO_fnc_log;
            };

            // Update state
            FLO_PlayerObjectiveStates set [_uid, _currentObjId];
        };

        // If player is in an objective, send update data
        if (_currentObjId != "") then {
            private _bluforCount = _currentObjData getOrDefault ["bluforCount", 0];
            private _opforCount = _currentObjData getOrDefault ["opforCount", 0];
            private _totalCount = _bluforCount + _opforCount;
            private _ratio = if (_totalCount > 0) then { _bluforCount / _totalCount } else { 0.5 };

            ["FLO_CaptureUI_Update", [_ratio, _bluforCount, _opforCount], owner _player] call CBA_fnc_ownerEvent;
        };

    } forEach allPlayers;

    sleep _updateInterval;
};
