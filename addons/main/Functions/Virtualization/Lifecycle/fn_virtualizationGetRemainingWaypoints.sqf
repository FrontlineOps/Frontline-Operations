/*
 * Function: FLO_fnc_virtualizationGetRemainingWaypoints
 */

params [
    "_groupId",
    "_position",
    "_allWaypoints",
    "_currentWpIdx",
    ["_generatedPatrol", false, [false]]
];

if (!_generatedPatrol && {_currentWpIdx == 0} && {count _allWaypoints > 1}) then {
    private _nearestDist = 999999;
    private _nearestIdx = -1;

    {
        private _wPos = _x select 0;
        private _dist = _wPos distance2D _position;
        if (_dist < _nearestDist) then {
            _nearestDist = _dist;
            _nearestIdx = _forEachIndex;
        };
    } forEach _allWaypoints;

    if (_nearestIdx > 0) then {
        private _distToFirst = (_allWaypoints select 0 select 0) distance2D _position;
        if (_nearestDist < 500 && _distToFirst > (_nearestDist + 200)) then {
            ["VIRTUALIZATION", 3, format [
                "Rebased stale activation route for %1 from waypoint 0 to %2 (nearest=%3m first=%4m)",
                _groupId, _nearestIdx, round _nearestDist, round _distToFirst
            ]] call FLO_fnc_log;
            _currentWpIdx = _nearestIdx;
        };
    };
};

if (_currentWpIdx > 0 && {_currentWpIdx < count _allWaypoints}) then {
    _allWaypoints select [_currentWpIdx, count _allWaypoints - _currentWpIdx]
} else {
    _allWaypoints
}
