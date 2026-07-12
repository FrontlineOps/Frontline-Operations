params [["_requester", objNull, [objNull]]];

if (!isServer) then { throw "Tactical Support snapshot requests are server-owned"; };
if (isNull _requester || {!isPlayer _requester}) exitWith { false };

private _owner = owner _requester;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    diag_log format [
        "[FLO][Support] Rejected snapshot owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ];
    false
};

private _now = diag_tickTime;
if (_owner in FLO_SupportSnapshotRequestAt && {(_now - (FLO_SupportSnapshotRequestAt get _owner)) < 1}) exitWith { false };
FLO_SupportSnapshotRequestAt set [_owner, _now];
diag_log format ["[FLO][Support] Snapshot request accepted owner=%1", _owner];

private _startedAt = diag_tickTime;
private _snapshot = [_requester] call FLO_fnc_supportBuildSnapshot;
private _elapsed = diag_tickTime - _startedAt;
if (_elapsed > 0.01) then {
    diag_log format [
        "[FLO][PERF] Support snapshot side=%1 time=%2ms assets=%3",
        _snapshot get "sideKey",
        round (_elapsed * 100000) / 100,
        count (_snapshot get "assets")
    ];
};

[_snapshot] remoteExecCall ["FLO_fnc_supportReceiveSnapshot", _owner];
true
