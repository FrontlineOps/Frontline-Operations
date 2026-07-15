params [["_player", objNull, [objNull]]];

if (!isServer || {isNull _player}) exitWith { false };

private _owner = owner _player;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    ["UI", 2, format [
        "Rejected Development snapshot owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ]] call FLO_fnc_log;
    false
};

private _now = diag_tickTime;
if (_owner in FLO_DevelopmentSnapshotRequestAt && {(_now - (FLO_DevelopmentSnapshotRequestAt get _owner)) < 1}) exitWith { false };
FLO_DevelopmentSnapshotRequestAt set [_owner, _now];

private _startedAt = diag_tickTime;
private _snapshot = [_player] call FLO_fnc_objectiveDevelopmentBuildUiSnapshot;
private _elapsed = diag_tickTime - _startedAt;
if (_elapsed > 0.01) then {
    ["PERF", 4, format [
        "Development snapshot side=%1 time=%2ms objectives=%3 projects=%4",
        _snapshot get "sideKey",
        round (_elapsed * 100000) / 100,
        count (_snapshot get "objectives"),
        _snapshot get "activeCount"
    ]] call FLO_fnc_log;
};
[_snapshot] remoteExecCall ["FLO_fnc_developmentReceiveSnapshot", _owner];
true
