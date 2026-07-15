/*
 * Function: FLO_fnc_gtnSubmitPlayerSupportRequestServer
 * Author: Frontline Operations Development Group
 * Description:
 *   Server intake for player-requested commander artillery, CAS, and CAP
 *   missions.
 *
 * Arguments:
 *   0: Requesting player <OBJECT>
 *   1: Support type <STRING>
 *   2: Target position <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith { false };

params [
    ["_requester", objNull, [objNull]],
    ["_supportType", "", [""]],
    ["_targetPos", [0, 0, 0], [[]], [3]]
];

if (isNull _requester) exitWith { false };
if (!isPlayer _requester) exitWith { false };

private _requestSide = side group _requester;
if !(_requestSide in [east, west]) exitWith { false };

if (isNil "FLO_GTN_ResourceManager") exitWith {
    [_requestSide, "HQ", "Negative. Commander support is offline."] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _cmdr = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_requestSide]];
if (isNil "_cmdr") exitWith {
    [_requestSide, "HQ", "Negative. Commander support is offline."] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _type = toUpper _supportType;
private _validation = [_cmdr, _requestSide, _type, _targetPos] call FLO_fnc_gtnValidatePlayerSupportRequest;
if !(_validation get "valid") exitWith {
    [_requestSide, "HQ", format ["Negative. %1", _validation get "reason"]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _config = _cmdr get "_config";
private _requests = _cmdr get "_playerSupportRequests";
private _maxQueuedRequests = _config get "playerSupportMaxQueuedRequests";

if ((count _requests) >= _maxQueuedRequests) exitWith {
    [_requestSide, "HQ", "Negative. Commander support queue is full. Try again shortly."] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _requesterUid = getPlayerUID _requester;
if (_requesterUid == "") then {
    _requesterUid = netId _requester;
};

private _playerCooldowns = _cmdr get "_playerSupportPlayerCooldowns";
private _playerCooldownKey = format ["%1:%2", _requesterUid, _type];
if (_playerCooldownKey in _playerCooldowns) then {
    private _lockedUntil = _playerCooldowns get _playerCooldownKey;
    if (_lockedUntil > diag_tickTime) exitWith {
        [_requestSide, "HQ", format ["Negative. %1 request cooling down for %2 seconds.", _type, ceil (_lockedUntil - diag_tickTime)]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
        false
    };

    _playerCooldowns deleteAt _playerCooldownKey;
};

private _objectiveLocks = _cmdr get "_playerSupportObjectiveLocks";
private _objectiveLockKey = _validation get "cooldownKey";
if (_objectiveLockKey in _objectiveLocks) then {
    private _lockedUntil = _objectiveLocks get _objectiveLockKey;
    if (_lockedUntil > diag_tickTime) exitWith {
        [_requestSide, "HQ", format [
            "Negative. %1 for %2 cooling down for %3 seconds.",
            _type,
            _validation get "targetLabel",
            ceil (_lockedUntil - diag_tickTime)
        ]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
        false
    };

    _objectiveLocks deleteAt _objectiveLockKey;
};

private _hasPendingDuplicate = false;
{
    if (
        (_x get "requesterUid") == _requesterUid
        && {(_x get "type") == _type}
    ) exitWith {
        _hasPendingDuplicate = true;
    };
} forEach _requests;

if (_hasPendingDuplicate) exitWith {
    [_requestSide, "HQ", format ["Negative. Pending %1 request already on file.", _type]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _hasPendingObjectiveDuplicate = false;
{
    if (
        (_x get "type") == _type
        && {(_x get "cooldownKey") == _objectiveLockKey}
    ) exitWith {
        _hasPendingObjectiveDuplicate = true;
    };
} forEach _requests;

if (_hasPendingObjectiveDuplicate) exitWith {
    [_requestSide, "HQ", format ["Negative. Pending %1 request already on file for %2.", _type, _validation get "targetLabel"]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
    false
};

private _request = createHashMapFromArray [
    ["type", _type],
    ["side", _requestSide],
    ["requesterUnit", _requester],
    ["requesterUid", _requesterUid],
    ["cooldownKey", _objectiveLockKey],
    ["targetLabel", _validation get "targetLabel"],
    ["targetPos", +_targetPos],
    ["expiresAt", diag_tickTime + (_config get "playerSupportRequestExpireSeconds")]
];

_requests pushBack _request;
_cmdr set ["_playerSupportRequests", _requests];

[_requestSide, "HQ", format ["HQ copies %1 request for %2. Stand by.", _type, _validation get "targetLabel"]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
["GTN Player Support", 3, format [
    "%1 queued %2 request for %3",
    name _requester,
    _type,
    _validation get "targetLabel"
]] call FLO_fnc_log;

true
