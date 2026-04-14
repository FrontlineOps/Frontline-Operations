/*
 * Function: FLO_fnc_transportLogMountFailureContext
 * Author: Frontline Operations Development Group
 * Description:
 *   Emits a throttled high-signal snapshot for active transport mount failures
 *   so upstream virtualization/transport lifecycle bugs can be traced from RPT.
 *
 * Arguments:
 *   0: Passenger Group ID <STRING>
 *   1: Passenger Group Data <HASHMAP>
 *   2: Carrier Group ID <STRING>
 *   3: Carrier Group Data <HASHMAP>
 *   4: Failure Reason <STRING>
 *   5: Carrier Vehicles <ARRAY> - Optional
 *
 * Return Value:
 *   BOOL - True when a diagnostic line was emitted
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_passengerData", createHashMap, [createHashMap]],
    ["_transportGroupId", "", [""]],
    ["_transportData", createHashMap, [createHashMap]],
    ["_reason", "", [""]],
    ["_transportVehicles", [], [[]]]
];

if (_passengerGroupId == "" || {_transportGroupId == ""} || {_reason == ""}) exitWith { false };

if (isNil "FLO_TransportMountFailureDiagTimes") then {
    FLO_TransportMountFailureDiagTimes = createHashMap;
};

private _key = format ["%1|%2", _reason, _transportGroupId];
private _now = diag_tickTime;
if (_key in FLO_TransportMountFailureDiagTimes) then {
    private _lastAt = FLO_TransportMountFailureDiagTimes get _key;
    if ((_now - _lastAt) < 30) exitWith { false };
};
FLO_TransportMountFailureDiagTimes set [_key, _now];

private _passengerRealGroup = _passengerData get "realGroup";
private _transportRealGroup = _transportData get "realGroup";
private _passengerRealUnits = if (isNull _passengerRealGroup) then { -1 } else { count units _passengerRealGroup };
private _transportRealUnits = if (isNull _transportRealGroup) then { -1 } else { count units _transportRealGroup };
private _trackedRealVehicles = count (_transportData get "realVehicles");
private _liveVehicles = count _transportVehicles;
private _attachedPassengerCount = count ([_transportData] call FLO_fnc_virtualizationGetTransportPassengers);

["TRANSPORT", 2, format [
    "Mount failure context reason=%1 passenger=%2 active=%3 lock=%4 replacement=%5 attachedTo=%6 mountedIn=%7 realUnits=%8 unitCount=%9 | carrier=%10 type=%11 active=%12 role=%13 lock=%14 replacement=%15 attachedGroups=%16 trackedVehicles=%17 liveVehicles=%18 realUnits=%19 objective=%20 pos=%21",
    _reason,
    _passengerGroupId,
    _passengerData get "isActive",
    _passengerData get "missionLock",
    _passengerData get "replacementState",
    [_passengerData] call FLO_fnc_virtualizationGetTransportAttachment,
    [_passengerData] call FLO_fnc_virtualizationGetMountedTransport,
    _passengerRealUnits,
    _passengerData get "unitCount",
    _transportGroupId,
    _transportData get "groupType",
    _transportData get "isActive",
    _transportData get "transportRole",
    _transportData get "missionLock",
    _transportData get "replacementState",
    _attachedPassengerCount,
    _trackedRealVehicles,
    _liveVehicles,
    _transportRealUnits,
    _transportData get "objective",
    _transportData get "position"
]] call FLO_fnc_log;

true
