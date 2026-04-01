/*
 * Function: FLO_fnc_virtualizationApplyTieredUpdateWindow
 */

params ["_groupId", "_groupData", "_activationDist", "_now", "_groupUpdateTimes", "_virtStats"];

private _position = _groupData get "position";
private _isActive = _groupData get "isActive";
private _nearestDist = [_position] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;
private _lastGroupUpdate = _groupUpdateTimes getOrDefault [_groupId, -1];

private _updatePhase = _groupData get "updatePhase";
if (_updatePhase < 0) then {
    private _seed = 0;
    { _seed = (_seed + _x) mod 997; } forEach toArray _groupId;
    _updatePhase = _seed / 997;
    _groupData set ["updatePhase", _updatePhase];
};

if (!_isActive && {_nearestDist > _activationDist}) then {
    private _profile = [_groupData, _nearestDist, _activationDist] call FLO_fnc_virtualizationResolveInactiveUpdateProfile;
    _profile params ["_fullUpdateInterval", "_movementUpdateInterval", "_speedMultiplier"];

    if (_lastGroupUpdate < 0) then {
        _lastGroupUpdate = _now - (_updatePhase * _fullUpdateInterval);
        _groupUpdateTimes set [_groupId, _lastGroupUpdate];
    };

    private _fullUpdateDue = (_now - _lastGroupUpdate) >= _fullUpdateInterval;
    if (_fullUpdateDue) exitWith {
        _groupUpdateTimes set [_groupId, _now];
        [true, _nearestDist, true, _speedMultiplier]
    };

    if (_movementUpdateInterval < _fullUpdateInterval) then {
        private _lastMove = _groupData get "lastMoveTime";
        if (_lastMove < 0) then {
            _lastMove = _now - (_updatePhase * _movementUpdateInterval);
            _groupData set ["lastMoveTime", _lastMove];
        };

        if (_now - _lastMove >= _movementUpdateInterval) exitWith {
            [true, _nearestDist, false, _speedMultiplier]
        };
    };

    _virtStats set ["tierSkipsTotal", (_virtStats get "tierSkipsTotal") + 1];
    _virtStats set ["tierSkipsThisBatch", (_virtStats get "tierSkipsThisBatch") + 1];
    [false, _nearestDist, false, 1]
};

_groupUpdateTimes set [_groupId, _now];
[true, _nearestDist, true, 1]
