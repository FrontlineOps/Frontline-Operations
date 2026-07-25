/* Validates one client request and returns the direct-attack Command Net. */
params [["_player", objNull, [objNull]]];
if (!isServer || {isNull _player}) exitWith {};

private _owner = owner _player;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    ["CAMPAIGN", 2, format ["Rejected Command Net snapshot owner %1 for player owner %2", remoteExecutedOwner, _owner]] call FLO_fnc_log;
};

private _now = diag_tickTime;
private _tooSoon = false;
if (_owner in FLO_CampaignSnapshotRequestAt) then {
    _tooSoon = (_now - (FLO_CampaignSnapshotRequestAt get _owner)) < 1;
};
if (_tooSoon) exitWith {};
FLO_CampaignSnapshotRequestAt set [_owner, _now];

private _startedAt = diag_tickTime;
private _snapshot = [_player] call FLO_fnc_campaignBuildSnapshot;
private _elapsed = diag_tickTime - _startedAt;
if (_elapsed > 0.01) then {
    diag_log format [
        "[FLO][PERF] Command Net snapshot side=%1 time=%2ms objectives=%3 attacks=%4",
        _snapshot get "viewerSide",
        round (_elapsed * 100000) / 100,
        count (_snapshot get "objectives"),
        count (_snapshot get "attacks")
    ];
};
[_snapshot] remoteExecCall ["FLO_fnc_operationsReceiveSnapshot", _owner];
