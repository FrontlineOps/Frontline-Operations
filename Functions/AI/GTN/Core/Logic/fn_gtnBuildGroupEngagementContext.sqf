/*
 * Function: FLO_fnc_gtnBuildGroupEngagementContext
 * Author: Frontline Operations Development Group
 * Description:
 *   Precomputes reusable engagement-scoring context for one friendly group so
 *   target evaluation does not rebuild the same route or hold geometry for
 *   every candidate target inside the same commander cycle.
 *
 * Arguments:
 * 0: Friendly group data <HASHMAP>
 * 1: Commander config <HASHMAP>
 *
 * Return Value:
 * HASHMAP - Engagement context
 */

params ["_groupData", "_config"];

private _context = createHashMap;
private _order = _groupData get "commanderOrder";
_context set ["order", _order];

switch (_order) do {
    case "ATTACK": {
        private _groupPos = _groupData get "position";
        private _routePoints = [+_groupPos];
        private _waypoints = _groupData get "waypoints";
        private _currentWaypointIndex = (_groupData get "currentWaypointIndex") max 0;

        if (_currentWaypointIndex < count _waypoints) then {
            private _lastWaypointIndex = ((count _waypoints) - 1) min (_currentWaypointIndex + 4);
            for "_i" from _currentWaypointIndex to _lastWaypointIndex do {
                _routePoints pushBack ((_waypoints select _i) select 0);
            };
        };

        if (count _routePoints < 2) then {
            private _orderTargetPos = _groupData get "orderTargetPos";
            if (count _orderTargetPos >= 2) then {
                _routePoints pushBack _orderTargetPos;
            };
        };

        _context set ["groupPos", _groupPos];
        _context set ["searchRadius", _config get "attackEngagementSearchRadius"];
        _context set ["corridorRadius", _config get "attackEngagementCorridorRadius"];
        _context set ["attackObjective", _groupData get "attackObjective"];
        _context set ["routePoints", _routePoints];
    };

    case "DEFEND": {
        private _holdPos = _groupData get "orderTargetPos";
        if (count _holdPos < 2) then {
            _holdPos = _groupData get "position";
        };

        _context set ["objectiveId", _groupData get "defendObjective"];
        _context set ["holdPos", _holdPos];
        _context set ["leashMeters", _config get "defenseEngagementLeashMeters"];
    };

    case "GARRISON": {
        private _holdPos = _groupData get "garrisonPosition";
        if (count _holdPos < 2) then {
            _holdPos = _groupData get "position";
        };

        _context set ["objectiveId", _groupData get "garrisonObjective"];
        _context set ["holdPos", _holdPos];
        _context set ["leashMeters", _config get "garrisonEngagementLeashMeters"];
    };
};

_context
