params [["_requester", objNull, [objNull]]];

if (!isServer) then { throw "Tactical Support snapshot requests are server-owned"; };
if (isNull _requester || {!isPlayer _requester}) exitWith { false };

private _owner = owner _requester;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    ["UI", 2, format [
        "Rejected Tactical Support snapshot owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ]] call FLO_fnc_log;
    false
};

private _now = diag_tickTime;
if (_owner in FLO_SupportSnapshotRequestAt && {(_now - (FLO_SupportSnapshotRequestAt get _owner)) < 1}) exitWith { false };
FLO_SupportSnapshotRequestAt set [_owner, _now];
["UI", 4, format ["Tactical Support snapshot request accepted owner=%1", _owner]] call FLO_fnc_log;

private _startedAt = diag_tickTime;
private _snapshot = [_requester] call FLO_fnc_supportBuildSnapshot;
private _elapsed = diag_tickTime - _startedAt;
if (_elapsed > 0.01) then {
    ["PERF", 4, format [
        "Tactical Support snapshot side=%1 time=%2ms assets=%3",
        _snapshot get "sideKey",
        round (_elapsed * 100000) / 100,
        count (_snapshot get "assets")
    ]] call FLO_fnc_log;
};

[_snapshot] remoteExecCall ["FLO_fnc_supportReceiveSnapshot", _owner];
true
