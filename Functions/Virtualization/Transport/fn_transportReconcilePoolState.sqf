/*
 * Function: FLO_fnc_transportReconcilePoolState
 * Author: Frontline Operations Development Group
 * Description:
 *   Reconciles the transport pool against canonical virtual group state.
 *   Dedicated reserve carriers may stay in the available pool; organic fallback
 *   combat vehicles are only temporary active carriers and must not become
 *   persistent reserve entries after a pickup.
 *
 * Arguments:
 *   0: Virtual group records <HASHMAP>
 *
 * Return Value:
 *   NUMBER - Repairs applied
 */

params [["_groups", createHashMap, [createHashMap]]];

if (isNil "FLO_TransportPool") then {
    throw "[TRANSPORT] Cannot reconcile transport pool before FLO_TransportPool is initialized";
};

private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";
private _repairs = 0;

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if (isNil "_groupData") then {
        _available deleteAt _groupId;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile removed missing available carrier %1",
            _groupId
        ]] call FLO_fnc_log;
        continue;
    };

    if !(_groupData get "transportRole") then {
        _available deleteAt _groupId;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile removed non-dedicated available carrier %1",
            _groupId
        ]] call FLO_fnc_log;
        continue;
    };

    if (
        ([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != ""
        || {([_groupData] call FLO_fnc_virtualizationGetMountedTransport) != ""}
        || {count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) > 0}
        || {(_groupData get "missionLock") == "TRANSPORT"}
    ) then {
        _available deleteAt _groupId;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile removed busy available carrier %1",
            _groupId
        ]] call FLO_fnc_log;
    };
} forEach (keys _available);

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if (isNil "_groupData") then {
        _active deleteAt _groupId;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile removed missing active carrier %1",
            _groupId
        ]] call FLO_fnc_log;
        continue;
    };

    private _hasPassengers = count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) > 0;
    private _lockedForTransport = (_groupData get "missionLock") == "TRANSPORT";
    if (_hasPassengers && {_lockedForTransport}) then {
        continue;
    };

    if (_hasPassengers) then {
        _active deleteAt _groupId;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile removed non-transport active carrier %1 with passenger manifest",
            _groupId
        ]] call FLO_fnc_log;
        continue;
    };

    if (_lockedForTransport) then {
        [_groupData] call FLO_fnc_transportClearInsertState;
        ["TRANSPORT", 2, format [
            "Pool reconcile cleared stale transport lock on passengerless active carrier %1",
            _groupId
        ]] call FLO_fnc_log;
    };

    _active deleteAt _groupId;
    _repairs = _repairs + 1;

    if (_groupData get "transportRole") then {
        _available set [_groupId, [
            [_groupData] call FLO_fnc_transportGetGroupCapacity,
            _groupData get "position",
            _groupData get "groupType",
            true,
            _groupData get "side"
        ]];
        ["TRANSPORT", 2, format [
            "Pool reconcile returned idle dedicated carrier %1 to availability",
            _groupId
        ]] call FLO_fnc_log;
    } else {
        ["TRANSPORT", 2, format [
            "Pool reconcile removed idle organic fallback carrier %1 from active pool",
            _groupId
        ]] call FLO_fnc_log;
    };
} forEach (keys _active);

{
    private _groupId = _x;
    private _groupData = _y;

    if (_groupId in _available || {_groupId in _active}) then { continue };
    if !([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) then { continue };

    private _passengerIds = [_groupData] call FLO_fnc_virtualizationGetTransportPassengers;
    private _missionLock = _groupData get "missionLock";
    private _lockedForTransport = _missionLock == "TRANSPORT";
    if (_missionLock != "" && {!_lockedForTransport}) then { continue };

    if ((count _passengerIds) > 0) then {
        if (_lockedForTransport) then {
            _active set [_groupId, [
                [_groupData] call FLO_fnc_transportGetGroupCapacity,
                _passengerIds select 0,
                _groupData get "groupType",
                _groupData get "transportRole",
                _groupData get "side"
            ]];
            _repairs = _repairs + 1;
            ["TRANSPORT", 2, format [
                "Pool reconcile restored active transport carrier %1 with %2 passengers",
                _groupId,
                count _passengerIds
            ]] call FLO_fnc_log;
        };
        continue;
    };

    if (_lockedForTransport) then {
        [_groupData] call FLO_fnc_transportClearInsertState;
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile cleared stale transport lock on unpooled carrier %1",
            _groupId
        ]] call FLO_fnc_log;
    };

    if (_groupData get "transportRole") then {
        _available set [_groupId, [
            [_groupData] call FLO_fnc_transportGetGroupCapacity,
            _groupData get "position",
            _groupData get "groupType",
            true,
            _groupData get "side"
        ]];
        _repairs = _repairs + 1;
        ["TRANSPORT", 2, format [
            "Pool reconcile restored dedicated reserve carrier %1 to availability",
            _groupId
        ]] call FLO_fnc_log;
    };
} forEach _groups;

_repairs
