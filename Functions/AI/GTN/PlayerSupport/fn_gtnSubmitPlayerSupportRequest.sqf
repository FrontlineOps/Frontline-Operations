/*
 * Function: FLO_fnc_gtnSubmitPlayerSupportRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Client entry point and server intake for player-requested commander
 *   artillery, CAS, and CAP missions.
 *
 * Arguments:
 *   Client call:
 *     0: Support type <STRING>
 *     1: Target position <ARRAY>
 *   Server call:
 *     0: Requesting player <OBJECT>
 *     1: Support type <STRING>
 *     2: Target position <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith {
    params [
        ["_supportType", "", [""]],
        ["_targetPos", [0, 0, 0], [[]], [3]]
    ];

    if (isNull player) exitWith { false };

    [player, _supportType, _targetPos] remoteExecCall ["FLO_fnc_gtnSubmitPlayerSupportRequest", 2, false];
    true
};

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

private _requestSeq = (_cmdr get "_playerSupportRequestSeq") + 1;
_cmdr set ["_playerSupportRequestSeq", _requestSeq];

private _requestId = format ["%1_PSR_%2", _cmdr get "_sideKey", _requestSeq];
private _request = createHashMapFromArray [
    ["id", _requestId],
    ["type", _type],
    ["side", _requestSide],
    ["requesterUnit", _requester],
    ["requesterOwner", owner _requester],
    ["requesterUid", _requesterUid],
    ["requesterName", name _requester],
    ["objectiveId", _validation get "objectiveId"],
    ["targetLabel", _validation get "targetLabel"],
    ["targetPos", +_targetPos],
    ["dispatchPos", +(_validation get "dispatchPos")],
    ["createdAt", diag_tickTime],
    ["expiresAt", diag_tickTime + (_config get "playerSupportRequestExpireSeconds")]
];

_requests pushBack _request;
_cmdr set ["_playerSupportRequests", _requests];

[ _requestSide, "HQ", format ["HQ copies %1 request for %2. Stand by.", _type, _validation get "targetLabel"] ] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
["GTN Player Support", 3, format [
    "%1 queued %2 request %3 for %4",
    name _requester,
    _type,
    _requestId,
    _validation get "targetLabel"
]] call FLO_fnc_log;

true
