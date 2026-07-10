/*
 * Function: FLO_fnc_campaignRequestSnapshot
 * Description:
 *   Validates a client snapshot request and returns side-filtered operation
 *   state to that client only.
 */

params [["_player", objNull, [objNull]]];

if (!isServer || {isNull _player}) exitWith {};

private _owner = owner _player;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    diag_log format [
        "[FLO][CAMPAIGN] Rejected operations snapshot owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ];
};

private _now = diag_tickTime;
private _tooSoon = false;
if (_owner in FLO_CampaignSnapshotRequestAt) then {
    private _lastRequestAt = FLO_CampaignSnapshotRequestAt get _owner;
    _tooSoon = (_now - _lastRequestAt) < 1;
};
if (_tooSoon) exitWith {};
FLO_CampaignSnapshotRequestAt set [_owner, _now];

if (isNil "FLO_CampaignDirector") then {
    throw "FLO_fnc_campaignRequestSnapshot: campaign director is not initialized";
};

private _snapshot = [FLO_CampaignDirector, _player] call FLO_fnc_campaignBuildSnapshot;
[_snapshot] remoteExecCall ["FLO_fnc_operationsReceiveSnapshot", _owner];
