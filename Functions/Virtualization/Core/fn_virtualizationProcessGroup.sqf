/*
 * Function: FLO_fnc_virtualizationProcessGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes a single virtual group - handles activation, deactivation,
 *   virtual movement, and state management. Called by the main PFH loop.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Activation Distance <NUMBER>
 * 3: Current Time <NUMBER>
 * 4: Group Update Times HashMap <HASHMAP> - For tiered updates
 *
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData, 2000, diag_tickTime, _updateTimes] call FLO_fnc_virtualizationProcessGroup;
 */

params ["_groupId", "_groupData", "_activationDist", "_now", "_groupUpdateTimes"];

// ============================================================================
// EXTRACT STATE - use get for data that must exist
// ============================================================================
private _position = _groupData get "position";
private _isActive = _groupData get "isActive";
private _groupType = _groupData get "groupType";
private _realGroup = _groupData get "realGroup";
private _onMission = _groupData get "onMission";
private _attachedTo = _groupData get "attachedTo";

// ============================================================================
// DISTANCE CHECK & TIERED UPDATE
// ============================================================================
private _nearestDist = [_position] call FLO_VirtUpdate_getNearestPlayerDist;
private _lastGroupUpdate = _groupUpdateTimes getOrDefault [_groupId, 0];

// Determine update interval based on distance
private _updateInterval = if (_nearestDist < 1000) then {
    2  // Near - frequent updates
} else {
    if (_nearestDist < 2500) then {
        5  // Mid range
    } else {
        15  // Far - infrequent updates
    }
};

// Skip if not time for this group's tiered update (unless active or close)
if (!_isActive && _nearestDist > _activationDist) then {
    if (_now - _lastGroupUpdate < _updateInterval) exitWith {};
};
_groupUpdateTimes set [_groupId, _now];

// ============================================================================
// HANDLE ATTACHED GROUPS (Transport passengers)
// ============================================================================
if (_attachedTo != "") exitWith {
    // Attached groups don't process independently
    private _groups = FLO_virtualGroups get "_groups";
    private _transportData = _groups get _attachedTo;
    // Sync position with transport
    private _tPos = _transportData get "position";
    _groupData set ["position", _tPos];
};

// ============================================================================
// VIRTUAL MOVEMENT (Inactive groups)
// ============================================================================
if (!_isActive) then {
    private _waypoints = _groupData get "waypoints";
    private _currentWpIdx = _groupData getOrDefault ["currentWaypointIndex", 0];
    
    if (count _waypoints > 0 && _currentWpIdx < count _waypoints) then {
        private _wp = _waypoints select _currentWpIdx;
        private _wpPos = _wp select 0;
        private _wpType = _wp select 1;
        
        private _virtualSpeed = _groupData getOrDefault ["virtualSpeed", 10];
        private _lastMove = _groupData getOrDefault ["lastMoveTime", _now];
        private _timeDelta = _now - _lastMove;
        private _distToWp = _position distance2D _wpPos;

        // Get completion radius from waypoint data (index 6), default 20m
        // Waypoint format: [position, type, behavior, speed, formation, combat mode, completion radius]
        private _completionRadius = _wp param [6, 20];

        if (_wpType in ["MOVE", "LOITER", "SAD", "DESTROY", "SENTRY", "CYCLE", "GUARD"] && _distToWp > _completionRadius) then {
            // Calculate movement
            private _moveDistance = (_virtualSpeed * _timeDelta) min _distToWp;
            private _dir = _position getDir _wpPos;
            private _newPos = _position getPos [_moveDistance, _dir];

            _groupData set ["position", _newPos];
            _groupData set ["lastMoveTime", _now];
            _groupData set ["state", "moving"];
        } else {
            if (_distToWp <= _completionRadius) then {
                // Waypoint reached - advance
                [_groupId, _groupData, _currentWpIdx, _waypoints] call FLO_fnc_virtualizationAdvanceWaypoint;
            };
        };
    } else {
        // No waypoints - assign patrol waypoints for idle groups
        if ((_groupData get "state" == "idle") &&
            !(_groupData getOrDefault ["autoPatrol", false]) &&
            !(_groupData getOrDefault ["state", ""] == "planning")) then {

            // Generate patrol waypoints around current position or objective
            private _patrolCenter = _position;
            private _objective = _groupData get "objective";
            if (_objective != "" && !isNil "FLO_Objectives") then {
                private _objData = FLO_Objectives get _objective;
                if (!isNil "_objData") then {
                    _patrolCenter = _objData get "position";
                };
            };

            // Fall back to group position if no objective position
            if (isNil "_patrolCenter") then {
                _patrolCenter = _position;
            };

            // Generate patrol (patrolCenter is always valid since it came from get)
                // Base patrol range by group type (min/max distance from center)
                private _rangeConfig = switch (_groupType) do {
                    case "infantry": { [100, 400] };
                    case "motorized": { [300, 800] };
                    case "mechanized": { [250, 600] };
                    case "armor": { [200, 500] };
                    default { [100, 400] };
                };
                _rangeConfig params ["_minDist", "_maxDist"];

                // Offset patrol center randomly so groups don't all orbit the same point
                private _centerOffset = _minDist + random (_maxDist - _minDist);
                private _centerDir = random 360;
                private _offsetCenter = _patrolCenter getPos [_centerOffset * 0.5, _centerDir];

                // Random number of waypoints (4-8)
                private _wpCount = 4 + floor random 5;

                // Random starting angle so patrols don't align
                private _startAngle = random 360;

                // Generate waypoints spread around the offset center
                private _patrolWaypoints = [];
                for "_i" from 0 to (_wpCount - 1) do {
                    // Spread waypoints around full 360 degrees with randomization
                    private _baseAngle = _startAngle + (_i * (360 / _wpCount));
                    private _angle = _baseAngle + (random 60 - 30);  // +/- 30 degree variance

                    // Random distance within range for each waypoint
                    private _dist = _minDist + random (_maxDist - _minDist);
                    private _wpPos = _offsetCenter getPos [_dist, _angle];

                    // Ensure position is on land
                    if (!surfaceIsWater _wpPos) then {
                        _patrolWaypoints pushBack [_wpPos, "MOVE", "AWARE", "LIMITED", "STAG COLUMN", "YELLOW", 15];
                    };
                };

            // Store patrol config and apply waypoints (NO CYCLE - virtual system loops naturally)
            if (count _patrolWaypoints > 0) then {
                // Apply waypoints without CYCLE - virtual advancement handles looping
                [_groupId, _patrolWaypoints] call FLO_fnc_updateVirtualGroupWaypoints;

                // Store patrol config for use when activating
                _groupData set ["patrolConfig", [_offsetCenter, (_minDist + _maxDist) / 2, count _patrolWaypoints, "AWARE", "LIMITED"]];
                _groupData set ["autoPatrol", true];
                _groupData set ["state", "moving"];

                ["VIRTUALIZATION", 4, format["Assigned auto-patrol to idle group %1 (%2 waypoints, range %3-%4m)", _groupId, count _patrolWaypoints, _minDist, _maxDist]] call FLO_fnc_log;
            };
        };
    };
};

// ============================================================================
// ACTIVATION / DEACTIVATION
// ============================================================================
if (_nearestDist <= _activationDist && !_isActive) then {
    // ACTIVATE - player is close
    ["VIRTUALIZATION", 3, format["Activating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
    [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
    
} else {
    if (_nearestDist > _activationDist && _isActive) then {
        // DEACTIVATE - player moved away
        private _alwaysActive = _groupData getOrDefault ["alwaysActive", false];
        if (_onMission || _alwaysActive) then {
            // Skip deactivation for groups on mission OR always-active (Static AA)
        } else {
            ["VIRTUALIZATION", 3, format["Deactivating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
            [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
        };
    };
};

// ============================================================================
// UPDATE ACTIVE GROUP POSITION
// ============================================================================
if (_isActive && !isNull _realGroup) then {
    private _leader = leader _realGroup;
    if (!isNull _leader && alive _leader) then {
        private _realPos = getPosATL _leader;
        if ([_realPos] call FLO_VirtUpdate_isValidPos) then {
            _groupData set ["position", _realPos];
        };

        // Check if active group has no waypoints and needs patrol
        private _realWaypoints = waypoints _realGroup;
        private _state = _groupData get "state";
        private _hasAutoPatrol = _groupData getOrDefault ["autoPatrol", false];

        if (count _realWaypoints <= 1 && !_hasAutoPatrol && _state == "idle") then {
            // Active group is idle with no waypoints - assign randomized patrol
            private _patrolCenter = _realPos;

            // Base patrol range by group type (min/max distance from center)
            private _rangeConfig = switch (_groupType) do {
                case "infantry": { [100, 400] };
                case "motorized": { [300, 800] };
                case "mechanized": { [250, 600] };
                case "armor": { [200, 500] };
                default { [100, 400] };
            };
            _rangeConfig params ["_minDist", "_maxDist"];

            // Offset patrol center randomly so groups don't all orbit the same point
            private _centerOffset = _minDist + random (_maxDist - _minDist);
            private _centerDir = random 360;
            private _offsetCenter = _patrolCenter getPos [_centerOffset * 0.5, _centerDir];

            // Random number of waypoints (4-8)
            private _numWps = 4 + floor random 5;
            private _startAngle = random 360;

            // Use taskPatrol for active groups - avoids CYCLE waypoint bugs
            private _patrolRadius = (_minDist + _maxDist) / 2;
            [_realGroup, _offsetCenter, _patrolRadius, _numWps, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;

            // Store config in groupData for virtualization
            _groupData set ["patrolConfig", [_offsetCenter, _patrolRadius, _numWps, "AWARE", "LIMITED"]];
            _groupData set ["autoPatrol", true];
            _groupData set ["state", "moving"];

            ["VIRTUALIZATION", 4, format["Assigned taskPatrol to active group %1 (%2 waypoints, radius %3m)", _groupId, _numWps, _patrolRadius]] call FLO_fnc_log;
        };
    };

    // Check for eliminated group
    private _lastChange = _groupData getOrDefault ["lastStateChangeTime", 0];
    if (_now - _lastChange > 5) then {
        if ({alive _x} count units _realGroup == 0) then {
            ["VIRTUALIZATION", 3, format["Group %1 eliminated - removing", _groupId]] call FLO_fnc_log;
            ["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;
            [FLO_virtualGroups, _groupId] call (FLO_virtualGroups get "_removeGroup");
        };
    };
};

