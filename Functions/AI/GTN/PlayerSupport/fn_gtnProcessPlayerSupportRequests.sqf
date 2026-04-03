/*
 * Function: FLO_fnc_gtnProcessPlayerSupportRequests
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes queued player support requests for one GTN commander. Valid
 *   requests wait for assets, then reuse the existing artillery or air
 *   mission systems when approved.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAPOBJECT>
 *
 * Return Value:
 *   HASHMAP - Processing metrics
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["queueCount", 0],
    ["queueCountAfter", 0],
    ["approvedCount", 0],
    ["expiredCount", 0],
    ["rejectedCount", 0],
    ["waitingAssetCount", 0],
    ["lockedCount", 0],
    ["dispatchFailCount", 0],
    ["abandonedCount", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _requests = _cmdr get "_playerSupportRequests";
_metrics set ["queueCount", count _requests];
if ((count _requests) == 0) exitWith { _metrics };

private _config = _cmdr get "_config";
private _now = diag_tickTime;

private _playerCooldowns = _cmdr get "_playerSupportPlayerCooldowns";
private _expiredPlayerCooldowns = [];
{
    if ((_playerCooldowns get _x) <= _now) then {
        _expiredPlayerCooldowns pushBack _x;
    };
} forEach (keys _playerCooldowns);
{ _playerCooldowns deleteAt _x; } forEach _expiredPlayerCooldowns;

private _objectiveLocks = _cmdr get "_playerSupportObjectiveLocks";
private _expiredObjectiveLocks = [];
{
    if ((_objectiveLocks get _x) <= _now) then {
        _expiredObjectiveLocks pushBack _x;
    };
} forEach (keys _objectiveLocks);
{ _objectiveLocks deleteAt _x; } forEach _expiredObjectiveLocks;

private _remainingRequests = [];
private _maxAssignments = _config get "playerSupportMaxAssignmentsPerCycle";
private _assignedThisCycle = 0;

{
    private _request = _x;
    private _requestSide = _request get "side";
    private _type = _request get "type";
    private _targetLabel = _request get "targetLabel";
    private _requesterUnit = _request get "requesterUnit";

    if (isNull _requesterUnit) then {
        _metrics set ["abandonedCount", (_metrics get "abandonedCount") + 1];
        continue;
    };

    if ((_request get "expiresAt") <= _now) then {
        _metrics set ["expiredCount", (_metrics get "expiredCount") + 1];
        [_requestSide, "HQ", format ["Negative. Unable to service %1 for %2. No assets became available.", _type, _targetLabel]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
        continue;
    };

    if (_assignedThisCycle >= _maxAssignments) then {
        _remainingRequests pushBack _request;
        continue;
    };

    private _validation = [_cmdr, _requestSide, _type, _request get "targetPos"] call FLO_fnc_gtnValidatePlayerSupportRequest;

    if !(_validation get "valid") then {
        _metrics set ["rejectedCount", (_metrics get "rejectedCount") + 1];
        [_requestSide, "HQ", format ["Negative. Unable to service %1 for %2. %3", _type, _request get "targetLabel", _validation get "reason"]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
        continue;
    };

    private _objectiveId = _validation get "objectiveId";
    private _objectiveLockKey = _validation get "cooldownKey";
    if (_objectiveLockKey in _objectiveLocks) then {
        private _lockedUntil = _objectiveLocks get _objectiveLockKey;
        if (_lockedUntil > _now) then {
            _metrics set ["lockedCount", (_metrics get "lockedCount") + 1];
            _remainingRequests pushBack _request;
            continue;
        };

        _objectiveLocks deleteAt _objectiveLockKey;
    };

    if !(_validation get "assetAvailable") then {
        _metrics set ["waitingAssetCount", (_metrics get "waitingAssetCount") + 1];
        _remainingRequests pushBack _request;
        continue;
    };

    private _success = false;
    switch (_type) do {
        case "ARTY": {
            _success = (_cmdr get "_artilleryManager") call [
                "_requestFireMission",
                [
                    _validation get "dispatchPos",
                    _config get "playerSupportArtilleryRounds",
                    _config get "playerSupportArtilleryAccuracy",
                    _requestSide,
                    _objectiveId,
                    "PLAYER",
                    true
                ]
            ];
        };

        case "CAS": {
            private _meta = createHashMapFromArray [
                ["playerSupport", true],
                ["targetLabel", _validation get "targetLabel"],
                ["forceLive", true]
            ];
            _success = _cmdr call ["_requestCAS", [_validation get "dispatchPos", "CAS", _meta]];
        };

        case "CAP": {
            private _meta = createHashMapFromArray [
                ["playerSupport", true],
                ["targetLabel", _validation get "targetLabel"],
                ["forceLive", true]
            ];
            _success = _cmdr call ["_requestCAP", [_validation get "dispatchPos", _meta]];
        };
    };

    if (!_success) then {
        _metrics set ["dispatchFailCount", (_metrics get "dispatchFailCount") + 1];
        _remainingRequests pushBack _request;
        continue;
    };

    private _playerCooldownSeconds = switch (_type) do {
        case "ARTY": { _config get "playerSupportPlayerCooldownArtillerySeconds" };
        case "CAS": { _config get "playerSupportPlayerCooldownCASSeconds" };
        case "CAP": { _config get "playerSupportPlayerCooldownCAPSeconds" };
    };

    private _objectiveCooldownSeconds = switch (_type) do {
        case "ARTY": { _config get "playerSupportObjectiveCooldownArtillerySeconds" };
        case "CAS": { _config get "playerSupportObjectiveCooldownCASSeconds" };
        case "CAP": { _config get "playerSupportObjectiveCooldownCAPSeconds" };
    };

    private _playerCooldownKey = format ["%1:%2", _request get "requesterUid", _type];
    _playerCooldowns set [_playerCooldownKey, _now + _playerCooldownSeconds];
    if (_objectiveLockKey != "") then {
        _objectiveLocks set [_objectiveLockKey, _now + _objectiveCooldownSeconds];
    };

    _metrics set ["approvedCount", (_metrics get "approvedCount") + 1];
    _assignedThisCycle = _assignedThisCycle + 1;

    private _approvalText = switch (_type) do {
        case "ARTY": { format ["HQ approves artillery for %1. Battery will engage shortly.", _validation get "targetLabel"] };
        case "CAS": { format ["HQ approves CAS for %1. Strike aircraft inbound.", _validation get "targetLabel"] };
        default { format ["HQ approves CAP over %1. Air cover launching.", _validation get "targetLabel"] };
    };
    [_requestSide, "HQ", _approvalText] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    ["GTN Player Support", 3, format [
        "%1 approved %2 request %3 for %4",
        _cmdr get "_sideKey",
        _type,
        _request get "id",
        _validation get "targetLabel"
    ]] call FLO_fnc_log;
} forEach _requests;

_cmdr set ["_playerSupportRequests", _remainingRequests];
_metrics set ["queueCountAfter", count _remainingRequests];

_metrics
