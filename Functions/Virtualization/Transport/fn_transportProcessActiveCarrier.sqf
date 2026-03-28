/*
 * Function: FLO_fnc_transportProcessActiveCarrier
 * Author: Frontline Operations Development Group
 * Description:
 *   Keeps an active carrier's passenger state authoritative in the live world
 *   and triggers real-world dismount when the carrier reaches its configured
 *   unload point.
 *
 * Arguments:
 *   0: Carrier Group ID <STRING>
 *   1: Carrier Group Data <HASHMAP>
 *   2: Real Carrier Group <GROUP>
 *
 * Return Value:
 *   BOOL - True when the carrier was processed
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]]
];

if (_groupId == "") exitWith { false };
if (isNull _realGroup) exitWith { false };
if !([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) exitWith { false };

private _attachedIds = +([_groupData] call FLO_fnc_virtualizationGetTransportPassengers);
if (count _attachedIds == 0) exitWith {
    if ((_groupData get "dismountAtWaypoint") >= 0 || {(_groupData get "transportInsertMode") != ""}) then {
        ["TRANSPORT", 2, format [
            "Carrier %1 had stale dismount state with no attached passengers - clearing",
            _groupId
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_transportClearInsertState;
    };
    false
};

private _transportVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x && {alive _x} };
private _groups = FLO_virtualGroups get "_groups";

{
    private _attachedData = _groups get _x;
    if (isNil "_attachedData") then {
        ["TRANSPORT", 2, format [
            "Carrier %1 had stale attached passenger %2 - removing from manifest",
            _groupId,
            _x
        ]] call FLO_fnc_log;
        [_groupData, _x] call FLO_fnc_virtualizationRemoveTransportPassenger;
        continue;
    };
    [_x, _attachedData, _groupId, _transportVehicles] call FLO_fnc_transportSyncActivePassengerGroup;
} forEach _attachedIds;

if (count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) == 0) exitWith {
    if ((_groupData get "dismountAtWaypoint") >= 0 || {(_groupData get "transportInsertMode") != ""}) then {
        ["TRANSPORT", 2, format [
            "Carrier %1 has no surviving attached passengers after manifest cleanup - clearing dismount state",
            _groupId
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_transportClearInsertState;
    };
    true
};

private _dismountIdx = _groupData get "dismountAtWaypoint";
if (_dismountIdx < 0) exitWith { true };

private _waypoints = _groupData get "waypoints";
if (_dismountIdx >= count _waypoints) exitWith {
    ["TRANSPORT", 2, format [
        "Carrier %1 had invalid dismount waypoint index %2 - clearing dismount state",
        _groupId,
        _dismountIdx
    ]] call FLO_fnc_log;
    [_groupData] call FLO_fnc_transportClearInsertState;
    true
};

private _leader = leader _realGroup;
if (isNull _leader || {!alive _leader}) exitWith { true };

private _carrierPos = getPosATL _leader;
if ([_groupData, _carrierPos] call FLO_fnc_transportShouldThreatDismount) exitWith {
    ["TRANSPORT", 3, format [
        "Active carrier %1 encountered threat conditions - unloading passengers early",
        _groupId
    ]] call FLO_fnc_log;
    [_groupId, true] call FLO_fnc_transportDismount;
    true
};

private _dismountWp = _waypoints select _dismountIdx;
private _dismountPos = _dismountWp select 0;
private _completionRadius = (_dismountWp param [6, 50]) max 35;
private _insertMode = _groupData get "transportInsertMode";

if ((_carrierPos distance2D _dismountPos) > _completionRadius) exitWith { true };

if (_insertMode == "AIR_LAND") then {
    private _carrierVehicle = vehicle _leader;
    private _carrierAltitude = getPosATL _carrierVehicle select 2;
    private _carrierSpeed = vectorMagnitude (velocity _carrierVehicle);

    if !(_groupData get "transportLandCommandIssued") exitWith {
        {
            _x flyInHeight FLO_Transport_AirLandAltitude;
            _x land "GET OUT";
        } forEach _transportVehicles;
        _groupData set ["transportLandCommandIssued", true];

        ["TRANSPORT", 3, format [
            "Active carrier %1 reached landing insert zone - issuing GET OUT landing",
            _groupId
        ]] call FLO_fnc_log;

        true
    };

    if (_carrierAltitude > 10 || {_carrierSpeed > 35}) exitWith { true };
};

["TRANSPORT", 3, format [
    "Active carrier %1 reached %2 waypoint %3 - unloading passengers",
    _groupId,
    if (_insertMode == "") then { "GROUND" } else { _insertMode },
    _dismountIdx
]] call FLO_fnc_log;

[_groupId, true] call FLO_fnc_transportDismount;

true
