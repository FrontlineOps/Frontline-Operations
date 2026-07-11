/*
 * Function: FLO_fnc_virtualizationGetRemainingWaypoints
 */

params ["_groupId", "_position", "_allWaypoints", "_currentWpIdx"];

if (_currentWpIdx == 0 && {count _allWaypoints > 1}) then {
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
            ["VIRTUALIZATION", 2, format [
                "WARNING: Group %1 activating with potentially stale waypoints! CurrentIdx: 0, NearestIdx: %2 (Dist: %3m vs First: %4m). Root cause: Virtual waypoints likely not deleting.",
                _groupId, _nearestIdx, round _nearestDist, round _distToFirst
            ]] call FLO_fnc_log;
        };
    };
};

if (_currentWpIdx > 0 && {_currentWpIdx < count _allWaypoints}) then {
    _allWaypoints select [_currentWpIdx, count _allWaypoints - _currentWpIdx]
} else {
    _allWaypoints
}
