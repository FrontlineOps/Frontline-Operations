/* Routes one authoritative notification to its current recipients. */
params [
    ["_message", "", ["", []]],
    ["_type", "info", [""]],
    ["_playMusic", false, [true]],
    ["_targetFilter", objNull]
];

if (!isServer) exitWith {
    [_message, _type, _playMusic, _targetFilter] remoteExecCall ["FLO_fnc_sendNotification", 2, false];
};

private _requestOwner = remoteExecutedOwner;
private _nowTick = diag_tickTime;
if (
    _requestOwner > 2
    && {_requestOwner in FLO_NotificationClientRequestAt}
    && {(_nowTick - (FLO_NotificationClientRequestAt get _requestOwner)) < 0.5}
) exitWith {};
if (_requestOwner > 2) then {
    FLO_NotificationClientRequestAt set [_requestOwner, _nowTick];
    _targetFilter = _requestOwner;
};

if ((count FLO_NotificationDedup) > 256) then {
    private _recentDedup = createHashMap;
    {
        if ((_nowTick - _y) < 30) then { _recentDedup set [_x, _y]; };
    } forEach FLO_NotificationDedup;
    FLO_NotificationDedup = _recentDedup;
};

private _dedupeKey = format ["%1|%2|%3|%4", str _message, _type, _playMusic, str _targetFilter];
private _lastTick = if (_dedupeKey in FLO_NotificationDedup) then {
    FLO_NotificationDedup get _dedupeKey
} else {
    -999
};
if ((_nowTick - _lastTick) < 0.5) exitWith {};
FLO_NotificationDedup set [_dedupeKey, _nowTick];

private _target = _targetFilter;
if (_target isEqualTo objNull) then {
    _target = FLO_ActivePlayerSide;
    if !(_target in [east, west]) then { _target = 0; };
};

[_message, _type, _playMusic] remoteExecCall ["FLO_fnc_displayNotification", _target, false];
