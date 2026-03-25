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

private _updateInterval = if (_nearestDist < 1000) then {
    2
} else {
    if (_nearestDist < 2500) then { 5 } else { 15 };
};

if (!_isActive && {_nearestDist > _activationDist}) then {
    if (_lastGroupUpdate < 0) then {
        _lastGroupUpdate = _now - (_updatePhase * _updateInterval);
        _groupUpdateTimes set [_groupId, _lastGroupUpdate];
    };
    if (_now - _lastGroupUpdate < _updateInterval) exitWith {
        _virtStats set ["tierSkipsTotal", (_virtStats get "tierSkipsTotal") + 1];
        _virtStats set ["tierSkipsThisBatch", (_virtStats get "tierSkipsThisBatch") + 1];
        [false, _nearestDist]
    };
};

_groupUpdateTimes set [_groupId, _now];
[true, _nearestDist]
