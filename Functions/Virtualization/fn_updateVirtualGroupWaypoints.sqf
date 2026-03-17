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
if (_effectiveUsePathfinding && {count _sanitizedWaypoints > 0}) then {
    if (isNil "FLO_PF_HybridRouting") then {
        FLO_PF_HybridRouting = true;
    };
    if (FLO_PF_HybridRouting) then {
        if (isNil "FLO_PF_HybridPlayerBubble") then {
            FLO_PF_HybridPlayerBubble = 1500;
        };
        if (isNil "FLO_PF_HybridForcePathSources") then {
            FLO_PF_HybridForcePathSources = [
                "SIDEMISSION_HVT_CONVOY",
                "SIDEMISSION_CONVOY_INTERDICT",
                "OBJECTIVE_LINK",
                "SYNC_COMPAT",
                "LOGI_REINF",
                "LOGI_STATIC_AA"
            ];
        };

        private _forcePath = _sourceTag in FLO_PF_HybridForcePathSources;
        if (!_forcePath) then {
            private _isGroundGroup = !(_groupType in ["helicopter", "air", "jet", "boat", "naval", "submarine"]);
            if (_isGroundGroup) then {
                private _targetPos = (_sanitizedWaypoints select 0) select 0;
                private _nearPlayers = false;
                {
                    private _playerPos = getPosATL _x;
                    if (_currentPos distance2D _playerPos <= FLO_PF_HybridPlayerBubble || {_targetPos distance2D _playerPos <= FLO_PF_HybridPlayerBubble}) exitWith {
                        _nearPlayers = true;
                    };
                } forEach allPlayers;
                if (!_nearPlayers) then {
                    _effectiveUsePathfinding = false;
                };
            } else {
                _effectiveUsePathfinding = false;
            };
        };
    };
};

// If no waypoints or using direct assignment (no pathfinding)
if (count _sanitizedWaypoints == 0 || !_effectiveUsePathfinding) then {
    // Clear path request metadata when assigning direct waypoints.
    _groupData set ["pathRequestToken", -1];
    _groupData set ["pathRequestTarget", []];
    _groupData set ["pathRequestTrails", false];
    _groupData set ["pathRequestStartedAt", -1];
    _groupData set ["pathLastIssuedTarget", []];
    _groupData set ["pathLastIssuedTrails", false];
    _groupData set ["pathLastIssuedAt", -1];

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

        // Cooldown repeated retries for the same failed route target.
        private _pfQueueDepth = 0;
        if (!isNil "FLO_PF_Scheduler") then {
            _pfQueueDepth = (FLO_PF_Scheduler get "_queueObject") call ["Count"];
        };
        private _failedRetryCooldown = 60;
        if (_pfQueueDepth > 1200) then {
            _failedRetryCooldown = 150;
        } else {
            if (_pfQueueDepth > 800) then {
                _failedRetryCooldown = 100;
            };
        };
        private _lastFailAt = _groupData getOrDefault ["pathLastFailAt", -1];
        private _lastFailTarget = _groupData getOrDefault ["pathLastFailTarget", []];
        private _lastFailTrails = _groupData getOrDefault ["pathLastFailTrails", false];
        if (_lastFailAt > 0 && {count _lastFailTarget >= 2} && {(diag_tickTime - _lastFailAt) < _failedRetryCooldown} && {_lastFailTarget distance2D _pathEnd < 100} && {_lastFailTrails isEqualTo _allowTrails}) exitWith {
            ["VIRTUALIZATION", 4, format["Skipping repeated failed path request for group %1 (cooldown)", _groupId]] call FLO_fnc_log;
        };

        // Suppress repeated same-destination request spam from commander loops.
        private _sameTargetWindow = 20;
        if (_pfQueueDepth > 1200) then {
            _sameTargetWindow = 90;
        } else {
            if (_pfQueueDepth > 800) then {
                _sameTargetWindow = 50;
            };
        };
        private _lastIssuedAt = _groupData getOrDefault ["pathLastIssuedAt", -1];
        private _lastIssuedTarget = _groupData getOrDefault ["pathLastIssuedTarget", []];
        private _lastIssuedTrails = _groupData getOrDefault ["pathLastIssuedTrails", false];
        if (_lastIssuedAt > 0 && {(diag_tickTime - _lastIssuedAt) < _sameTargetWindow} && {count _lastIssuedTarget >= 2} && {_lastIssuedTarget distance2D _pathEnd < 35} && {_lastIssuedTrails isEqualTo _allowTrails}) exitWith {
            ["VIRTUALIZATION", 4, format["Skipping no-op path request for group %1 (same target %2m ago)", _groupId, round (diag_tickTime - _lastIssuedAt)]] call FLO_fnc_log;
        };

        // Keep existing request if it's already pending for the same destination + trails mode.
        private _existingToken = _groupData getOrDefault ["pathRequestToken", -1];
        private _existingTarget = _groupData getOrDefault ["pathRequestTarget", []];
        private _existingTrails = _groupData getOrDefault ["pathRequestTrails", false];
        private _existingStartedAt = _groupData getOrDefault ["pathRequestStartedAt", -1];
        private _replaceCooldown = 20;
        if (_pfQueueDepth > 1200) then {
            _replaceCooldown = 90;
        } else {
            if (_pfQueueDepth > 800) then {
                _replaceCooldown = 45;
            };
        };
        private _sameRoutePending = _existingToken >= 0 && {count _existingTarget >= 2} && {_existingTarget distance2D _pathEnd < 25} && {_existingTrails isEqualTo _allowTrails};
        if (_sameRoutePending) exitWith {
            ["VIRTUALIZATION", 4, format["Path request already pending for group %1 to %2", _groupId, _pathEnd]] call FLO_fnc_log;
        };

        // Avoid request thrash: when a path request is already pending, allow it to finish
        // for a short window before replacing with a new destination.
        if (_existingToken >= 0 && {_existingStartedAt > 0} && {(diag_tickTime - _existingStartedAt) < _replaceCooldown}) exitWith {
            ["VIRTUALIZATION", 4, format["Path request cooldown active for group %1 (age %2s/%3s), keeping pending route", _groupId, round (diag_tickTime - _existingStartedAt), _replaceCooldown]] call FLO_fnc_log;
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
        _groupData set ["pathLastIssuedTarget", _pathEnd];
        _groupData set ["pathLastIssuedTrails", _allowTrails];
        _groupData set ["pathLastIssuedAt", _requestTime];
        
        // Path callback
        private _callbackCode = {
            params ["_status", "_posArray", "_args"];
            _args params ["_groupId", "_waypointSettings", "_requestToken", "_requestPos", "_requestTime", "_directBootstrapAllowed"];

            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            if (isNil "_groupData") exitWith {};
            if ((_groupData get "pathRequestToken") != _requestToken) exitWith {};

            if (!_status) exitWith {
                _groupData set ["pathRequestToken", -1];
                _groupData set ["pathLastFailAt", diag_tickTime];
                _groupData set ["pathLastFailTarget", _groupData getOrDefault ["pathRequestTarget", []]];
                _groupData set ["pathLastFailTrails", _groupData getOrDefault ["pathRequestTrails", false]];
                if (!_directBootstrapAllowed) then {
                    _groupData set ["state", "idle"];
                    ["VIRTUALIZATION", 2, format["Pathfinding failed for group %1; holding (resolved path required)", _groupId]] call FLO_fnc_log;
                } else {
                    ["VIRTUALIZATION", 3, format["Pathfinding failed for group %1, keeping direct route", _groupId]] call FLO_fnc_log;
                };
                _groupData set ["pathRequestTarget", []];
                _groupData set ["pathRequestTrails", false];
                _groupData set ["pathRequestStartedAt", -1];
            };

            // Avoid applying very late paths after the group has already moved far from request origin.
            if ((diag_tickTime - _requestTime) > 30 && {((_groupData get "position") distance2D _requestPos) > 300}) exitWith {
                _groupData set ["pathRequestToken", -1];
                ["VIRTUALIZATION", 3, format["Discarded stale path for group %1", _groupId]] call FLO_fnc_log;
                _groupData set ["pathRequestTarget", []];
                _groupData set ["pathRequestTrails", false];
                _groupData set ["pathRequestStartedAt", -1];
            };
            
            // Extract waypoint settings
            private _wpType = _waypointSettings select 1;
            private _wpBehavior = _waypointSettings select 2;
            private _wpSpeed = _waypointSettings select 3;
            private _wpFormation = _waypointSettings select 4;
            private _wpMode = _waypointSettings select 5;
            private _wpCompletionRadius = _waypointSettings select 6;
            
            // Create new waypoints array, ensuring positions are on land
            private _newWaypoints = [];
            {
                private _wpPos = _x;
                // Skip water positions for non-naval groups
                if (surfaceIsWater _wpPos) then {
                    _wpPos = [_wpPos, 300] call FLO_fnc_getSafeLandPos;
                };
                _newWaypoints pushBack [_wpPos, _wpType, _wpBehavior, _wpSpeed, _wpFormation, _wpMode, _wpCompletionRadius];
            } forEach _posArray;

            private _targetPos = _waypointSettings select 0;
            private _routeDistance = _requestPos distance2D _targetPos;
            private _isReinforcementOrder = (_groupData get "currentOrder") in ["REINFORCE", "AA_DEPLOY"];
            if (!_directBootstrapAllowed && _isReinforcementOrder && {_routeDistance > 1200} && {count _newWaypoints < 2}) exitWith {
                _groupData set ["pathRequestToken", -1];
                _groupData set ["pathRequestTarget", []];
                _groupData set ["pathRequestTrails", false];
                _groupData set ["pathRequestStartedAt", -1];
                _groupData set ["waypoints", []];
                _groupData set ["currentWaypointIndex", 0];
                _groupData set ["state", "planning"];
                ["VIRTUALIZATION", 2, format["Rejected fallback route for reinforcement group %1 (distance=%2m, points=%3)", _groupId, round _routeDistance, count _newWaypoints]] call FLO_fnc_log;
            };

            if (count _newWaypoints == 0) exitWith {
                _groupData set ["pathRequestToken", -1];
                _groupData set ["pathRequestTarget", []];
                _groupData set ["pathRequestTrails", false];
                _groupData set ["pathRequestStartedAt", -1];
            };

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
            _groupData set ["pathLastFailAt", -1];
            _groupData set ["pathLastFailTarget", []];
            _groupData set ["pathLastFailTrails", false];

            ["VIRTUALIZATION", 3, format["Pathfinding completed for group %1 with %2 waypoints", _groupId, count _newWaypoints]] call FLO_fnc_log;

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

        // Stagger path requests through central scheduler dispatch queue.
        if (isNil "FLO_PF_DispatchNextAt") then {
            FLO_PF_DispatchNextAt = diag_tickTime;
        };
        if (isNil "FLO_PF_DispatchGap") then {
            FLO_PF_DispatchGap = 0.1; // ~10 requests/second max
        };

        private _slotTime = FLO_PF_DispatchNextAt max diag_tickTime;
        FLO_PF_DispatchNextAt = _slotTime + FLO_PF_DispatchGap;
        private _callbackArgs = [_groupId, _firstWaypoint, _requestToken, _pathStart, _requestTime, _directBootstrapAllowed];

        if (isNil "FLO_PF_Scheduler") then {
            [_pathStart, _pathEnd, _callbackCode, _callbackArgs, _allowTrails, _sourceTag] call FLO_fnc_findRoadPath;
        } else {
            FLO_PF_Scheduler call ["EnqueueDispatch", [_slotTime, _pathStart, _pathEnd, _callbackCode, _callbackArgs, _allowTrails, _sourceTag]];
        };
    };
};

// Log the update
["VIRTUALIZATION", 3, format["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;

// Return success
true
