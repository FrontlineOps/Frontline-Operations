/*
 * Function: FLO_fnc_updateVirtualGroupWaypoints
 * Author: Frontline Operations Development Group
 * Description:
 * Updates the waypoints for a virtual group. If the group is active, updates its real waypoints.
 * If inactive, stores the waypoints for virtual movement processing.
 * Now supports pathfinding integration for road-based movement.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Waypoints <ARRAY> - Array of waypoint data in format:
 *   Each waypoint is an array: [position, type, behavior, speed, formation, combat mode, completion radius]
 * 2: (Optional) Use Road Pathfinding <BOOLEAN> - Whether to use road pathfinding (Default: false)
 * 3: (Optional) Allow Trails <BOOLEAN> - Whether to allow trails for pathfinding (Default: false)
 * 4: (Optional) Request Source <STRING> - Source tag for pathfinding telemetry (Default: "")
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 20]]] call FLO_fnc_updateVirtualGroupWaypoints;
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 20]], true] call FLO_fnc_updateVirtualGroupWaypoints;
 */

params [
    "_groupId",
    "_waypoints",
    ["_usePathfinding", false, [true]],
    ["_allowTrails", true, [true]],
    ["_requestSource", "", [""]]
];

// Get the group data
private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
// Clear any automatic patrol flag when updating waypoints
_groupData set ["autoPatrol", false];

// Get the current position of the group
private _currentPos = _groupData get "position";

// Get the group type to check if it's a boat/naval group
private _groupType = _groupData get "groupType";
private _isNavalGroup = _groupType in ["boat", "naval", "submarine"];

// Handle water waypoints for non-naval groups
private _sanitizedWaypoints = [];
{
    if !(_x isEqualType [] && {count _x >= 7}) then { continue };
    private _wpPos = _x select 0;
    if !(_wpPos isEqualType [] && {count _wpPos >= 2}) then { continue };

    if (!_isNavalGroup && {surfaceIsWater _wpPos}) then {
        // Find safe land position for non-naval group
        private _safePos = [_wpPos, 500] call FLO_fnc_getSafeLandPos;
        private _newWp = +_x;
        _newWp set [0, _safePos];
        _sanitizedWaypoints pushBack _newWp;
    } else {
        _sanitizedWaypoints pushBack _x;
    };
} forEach _waypoints;

private _sourceTag = if (_requestSource != "") then { _requestSource } else { "VG_GENERIC" };
private _effectiveUsePathfinding = _usePathfinding;

// If no waypoints or using direct assignment (no pathfinding)
if (count _sanitizedWaypoints == 0 || !_effectiveUsePathfinding) then {
    // Clear path request metadata when assigning direct waypoints.
    _groupData set ["pathRequestToken", -1];
    _groupData set ["pathRequestTarget", []];
    _groupData set ["pathRequestTrails", false];
    _groupData set ["pathRequestStartedAt", -1];

    // Store the waypoints and initialize tracking for both virtual and physical movement
    _groupData set ["waypoints", _sanitizedWaypoints];
    _groupData set ["pathRequestSource", _sourceTag];

    // Clear patrol state - Commander is giving new orders, overrides auto-patrol
    _groupData set ["patrolConfig", []];
    _groupData set ["autoPatrol", false];

    // Add or update virtual waypoint data
    if (count _sanitizedWaypoints > 0) then {
        // Set group state to moving
        _groupData set ["state", "moving"];

        // Initialize virtual waypoint tracking
        _groupData set ["currentWaypointIndex", 0];
        _groupData set ["lastMoveTime", diag_tickTime];

        // Calculate speed in meters per second based on waypoint speed setting
        private _wpSpeed = (_sanitizedWaypoints select 0) select 3;
        private _speedMPS = switch (_wpSpeed) do {
            case "LIMITED": { 2 }; // ~7 km/h
            case "NORMAL": { 4 }; // ~14 km/h
            case "FULL": { 8 }; // ~29 km/h
            default { 4 };
        };

        // Adjust speed based on group type
        private _speedMultiplier = switch (_groupType) do {
            case "infantry": { 1.0 };
            case "motorized": { 2.5 };
            case "mechanized": { 2.0 };
            case "armor": { 1.8 };
            case "helicopter";
            case "air": { 6.0 };
            case "jet": { 10.0 };
            default { 1.0 };
        };

        _groupData set ["virtualSpeed", _speedMPS * _speedMultiplier];

        ["VIRTUALIZATION", 3, format["Set up virtual movement for group %1 (Speed: %2 m/s)",
            _groupId, _speedMPS * _speedMultiplier]] call FLO_fnc_log;
    };

    // If the group is active, update its real waypoints too
    if (_groupData get "isActive") then {
        private _realGroup = _groupData get "realGroup";
        if (!isNull _realGroup) then {
            // Clear existing waypoints
            [_realGroup] call CBA_fnc_clearWaypoints;

            // Add new waypoints
            {
                private _wpPos = _x select 0;
                private _wpType = _x select 1;
                private _wpBehavior = _x select 2;
                private _wpSpeed = _x select 3;
                private _wpFormation = _x select 4;
                private _wpMode = _x select 5;
                private _wpCompletionRadius = _x select 6;
                
                private _wp = _realGroup addWaypoint [_wpPos, 0];
                _wp setWaypointType _wpType;
                _wp setWaypointBehaviour _wpBehavior;
                _wp setWaypointSpeed _wpSpeed;
                _wp setWaypointFormation _wpFormation;
                _wp setWaypointCombatMode _wpMode;
                _wp setWaypointCompletionRadius _wpCompletionRadius;
            } forEach _sanitizedWaypoints;
        };
    };
} else {
    // Using pathfinding - we'll need to temporarily store the waypoint settings
    // Store only the first waypoint settings temporarily (we'll apply them to all generated waypoints)
    if (count _sanitizedWaypoints > 0) then {
        private _firstWaypoint = _sanitizedWaypoints select 0;
        private _endPos = _firstWaypoint select 0;
        private _pathStart = +_currentPos;
        private _pathEnd = +_endPos;
        if (count _pathStart > 2) then { _pathStart resize 2; };
        if (count _pathEnd > 2) then { _pathEnd resize 2; };

        // Keep existing request if it's already pending for the same destination + trails mode.
        private _existingToken = _groupData get "pathRequestToken";
        private _existingTarget = _groupData get "pathRequestTarget";
        private _existingTrails = _groupData get "pathRequestTrails";
        private _sameRoutePending = _existingToken >= 0 && {count _existingTarget >= 2} && {_existingTarget distance2D _pathEnd < 25} && {_existingTrails isEqualTo _allowTrails};
        if (_sameRoutePending) exitWith {
            ["VIRTUALIZATION", 4, format["Path request already pending for group %1 to %2", _groupId, _pathEnd]] call FLO_fnc_log;
        };

        // Invalidate previous request only when replacing it with a new route target.
        _groupData set ["pathRequestToken", -1];
        _groupData set ["pathRequestStartedAt", -1];
        private _directBootstrapAllowed = _isNavalGroup || {_groupType in ["helicopter", "air", "jet"]};

        private _wpType = _firstWaypoint select 1;
        private _wpBehavior = _firstWaypoint select 2;
        private _wpSpeed = _firstWaypoint select 3;
        private _wpFormation = _firstWaypoint select 4;
        private _wpMode = _firstWaypoint select 5;
        private _wpCompletionRadius = _firstWaypoint select 6;

        private _speedMPS = switch (_wpSpeed) do {
            case "LIMITED": { 2 };
            case "NORMAL": { 4 };
            case "FULL": { 8 };
            default { 4 };
        };

        private _speedMultiplier = switch (_groupType) do {
            case "infantry": { 1.0 };
            case "motorized": { 2.5 };
            case "mechanized": { 2.0 };
            case "armor": { 1.8 };
            case "helicopter";
            case "air": { 6.0 };
            case "jet": { 10.0 };
            default { 1.0 };
        };

        // Ground groups wait for resolved path. Air/naval can bootstrap directly.
        _groupData set ["waypoints", if (_directBootstrapAllowed) then { [_firstWaypoint] } else { [] }];
        _groupData set ["patrolConfig", []];
        _groupData set ["autoPatrol", false];
        _groupData set ["state", if (_directBootstrapAllowed) then { "moving" } else { "planning" }];
        _groupData set ["currentWaypointIndex", 0];
        _groupData set ["lastMoveTime", diag_tickTime];
        _groupData set ["virtualSpeed", _speedMPS * _speedMultiplier];

        // Keep metadata for debugging/inspection.
        _groupData set ["tempWaypointSettings", _firstWaypoint];
        _groupData set ["tempWaypointCount", if (_directBootstrapAllowed) then { 1 } else { 0 }];

        // If active, apply immediate bootstrap waypoint only when allowed; otherwise hold for route.
        if (_groupData get "isActive") then {
            private _realGroup = _groupData get "realGroup";
            if (!isNull _realGroup) then {
                [_realGroup] call CBA_fnc_clearWaypoints;
                private _bootstrapPos = if (_directBootstrapAllowed) then { _endPos } else { _currentPos };
                private _bootstrapType = if (_directBootstrapAllowed) then { _wpType } else { "HOLD" };
                private _directWp = _realGroup addWaypoint [_bootstrapPos, 0];
                _directWp setWaypointType _bootstrapType;
                _directWp setWaypointBehaviour _wpBehavior;
                _directWp setWaypointSpeed _wpSpeed;
                _directWp setWaypointFormation _wpFormation;
                _directWp setWaypointCombatMode _wpMode;
                _directWp setWaypointCompletionRadius _wpCompletionRadius;
            };
        };

        private _requestToken = floor (diag_tickTime * 1000) + floor random 100000;
        private _requestTime = diag_tickTime;
        _groupData set ["pathRequestToken", _requestToken];
        _groupData set ["pathRequestTarget", _pathEnd];
        _groupData set ["pathRequestTrails", _allowTrails];
        _groupData set ["pathRequestStartedAt", _requestTime];
        _groupData set ["pathRequestSource", _sourceTag];
        
        // Path callback
        private _callbackCode = {
            params ["_resolved", "_posArray", "_args"];
            _args params ["_groupId", "_waypointSettings", "_requestToken"];

            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            if (isNil "_groupData") exitWith {};
            if ((_groupData get "pathRequestToken") != _requestToken) exitWith {};
            
            // Extract waypoint settings
            private _wpType = _waypointSettings select 1;
            private _wpBehavior = _waypointSettings select 2;
            private _wpSpeed = _waypointSettings select 3;
            private _wpFormation = _waypointSettings select 4;
            private _wpMode = _waypointSettings select 5;
            private _wpCompletionRadius = _waypointSettings select 6;
            private _resolvedPositions = +_posArray;
            
            // Create new waypoints array, ensuring positions are on land
            private _newWaypoints = [];
            {
                private _wpPos = _x;
                // Skip water positions for non-naval groups
                if (surfaceIsWater _wpPos) then {
                    _wpPos = [_wpPos, 300] call FLO_fnc_getSafeLandPos;
                };
                _newWaypoints pushBack [_wpPos, _wpType, _wpBehavior, _wpSpeed, _wpFormation, _wpMode, _wpCompletionRadius];
            } forEach _resolvedPositions;

            // Update the virtual group with the resolved road waypoints
            // Store the waypoints
            _groupData set ["waypoints", _newWaypoints];
            _groupData set ["tempWaypointCount", count _newWaypoints];

            // Clear patrol state - Commander is giving new orders
            _groupData set ["patrolConfig", []];
            _groupData set ["autoPatrol", false];

            // Set group state to moving
            _groupData set ["state", "moving"];

            // Initialize virtual waypoint tracking
            _groupData set ["currentWaypointIndex", 0];
            _groupData set ["lastMoveTime", diag_tickTime];
            
            // Calculate speed in meters per second based on waypoint speed setting
            private _speedMPS = switch (_wpSpeed) do {
                case "LIMITED": { 2 }; // ~7 km/h
                case "NORMAL": { 4 }; // ~14 km/h
                case "FULL": { 8 }; // ~29 km/h
                default { 4 };
            };
            
            // Adjust speed based on group type
            private _groupType = _groupData get "groupType";
            private _speedMultiplier = switch (_groupType) do {
                case "infantry": { 1.0 };
                case "motorized": { 2.5 };
                case "mechanized": { 2.0 };
                case "armor": { 1.8 };
                case "helicopter";
                case "air": { 6.0 };
                case "jet": { 10.0 };
                default { 1.0 };
            };
            
            _groupData set ["virtualSpeed", _speedMPS * _speedMultiplier];
            _groupData set ["pathRequestToken", -1];
            _groupData set ["pathRequestTarget", []];
            _groupData set ["pathRequestTrails", false];
            _groupData set ["pathRequestStartedAt", -1];

            ["VIRTUALIZATION", 3, format["Pathfinding resolved for group %1 with %2 waypoints", _groupId, count _newWaypoints]] call FLO_fnc_log;

            // If the group is active, update its real waypoints too
            if (_groupData get "isActive") then {
                private _realGroup = _groupData get "realGroup";
                if (!isNull _realGroup) then {
                    // Clear existing waypoints
                    [_realGroup] call CBA_fnc_clearWaypoints;

                    // Add new waypoints
                    {
                        private _wpPos = _x select 0;

                        private _wp = _realGroup addWaypoint [_wpPos, 0];
                        _wp setWaypointType _wpType;
                        _wp setWaypointBehaviour _wpBehavior;
                        _wp setWaypointSpeed _wpSpeed;
                        _wp setWaypointFormation _wpFormation;
                        _wp setWaypointCombatMode _wpMode;
                        _wp setWaypointCompletionRadius _wpCompletionRadius;
                    } forEach _newWaypoints;
                };
            };
        };
        
        // Start the pathfinding process
        if (!_directBootstrapAllowed) then {
            ["VIRTUALIZATION", 3, format["Starting pathfinding for group %1 from %2 to %3 (holding: waiting for resolved path)", _groupId, _pathStart, _pathEnd]] call FLO_fnc_log;
        } else {
            ["VIRTUALIZATION", 3, format["Starting pathfinding for group %1 from %2 to %3 (direct movement active)", _groupId, _pathStart, _pathEnd]] call FLO_fnc_log;
        };

        private _callbackArgs = [_groupId, _firstWaypoint, _requestToken];
        [_pathStart, _pathEnd, _callbackCode, _callbackArgs, _allowTrails, _sourceTag] call FLO_fnc_findRoadPath;
    };
};

// Log the update
["VIRTUALIZATION", 3, format["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;

// Return success
true
