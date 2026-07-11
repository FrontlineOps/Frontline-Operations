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
_groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;
if !([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) exitWith { false };

private _attachedIds = +([_groupData] call FLO_fnc_virtualizationGetTransportPassengers);
if (_attachedIds isEqualTo []) exitWith {
    if ((_groupData get "dismountAtWaypoint") >= 0 || {(_groupData get "transportInsertMode") != ""}) then {
        ["TRANSPORT", 2, format [
            "Carrier %1 had stale dismount state with no attached passengers - clearing",
            _groupId
        ]] call FLO_fnc_log;
        [_groupId] call FLO_fnc_transportClearInsertState;
    };
    false
};

private _carrierVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x };
private _liveCarrierVehicles = _carrierVehicles select { alive _x };

{
    private _attachedData = [_x] call FLO_fnc_virtualizationFindGroupSnapshot;
    if (isNil "_attachedData") then {
        ["TRANSPORT", 2, format [
            "Carrier %1 had stale attached passenger %2 - removing from manifest",
            _groupId,
            _x
        ]] call FLO_fnc_log;
        [_groupId, _x] call FLO_fnc_virtualizationPruneTransportPassenger;
        continue;
    };
    [_x, _attachedData, _groupId, _carrierVehicles, _groupData] call FLO_fnc_transportSyncActivePassengerGroup;
} forEach _attachedIds;

_groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;
if (([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) isEqualTo []) exitWith {
    if ((_groupData get "dismountAtWaypoint") >= 0 || {(_groupData get "transportInsertMode") != ""}) then {
        ["TRANSPORT", 2, format [
            "Carrier %1 has no surviving attached passengers after manifest cleanup - clearing dismount state",
            _groupId
        ]] call FLO_fnc_log;
        [_groupId] call FLO_fnc_transportClearInsertState;
    };
    true
};

if (_liveCarrierVehicles isEqualTo []) exitWith { true };

private _dismountIdx = _groupData get "dismountAtWaypoint";
if (_dismountIdx < 0) exitWith { true };

private _waypoints = _groupData get "waypoints";
if (_dismountIdx >= count _waypoints) exitWith {
    ["TRANSPORT", 2, format [
        "Carrier %1 had invalid dismount waypoint index %2 - clearing dismount state",
        _groupId,
        _dismountIdx
    ]] call FLO_fnc_log;
    [_groupId] call FLO_fnc_transportClearInsertState;
    true
};

private _leader = leader _realGroup;
if (isNull _leader || {!alive _leader}) exitWith { true };

private _carrierPos = getPosATL _leader;
private _insertMode = _groupData get "transportInsertMode";

if (_groupData get "transportUnloadCommandIssued") exitWith {
    private _remainingMountedUnits = [_groupData, _carrierVehicles] call FLO_fnc_transportCountMountedActivePassengers;
    if (_remainingMountedUnits == 0) then {
        ["TRANSPORT", 3, format [
            "Active carrier %1 completed live %2 unload - finalizing transport detach",
            _groupId,
            [_insertMode, "GROUND"] select (_insertMode == "")
        ]] call FLO_fnc_log;
        [_groupId, true] call FLO_fnc_transportDismount;
        true
    } else {
        [_groupId, _groupData, _carrierVehicles] call FLO_fnc_transportIssueActiveDismount;

        private _unloadIssuedAt = _groupData get "transportUnloadIssuedAt";
        if (_unloadIssuedAt >= 0 && {(diag_tickTime - _unloadIssuedAt) >= FLO_Transport_ActiveUnloadTimeout}) then {
            ["TRANSPORT", 2, format [
                "Active carrier %1 live unload stalled with %2 mounted units - forcing detach fallback",
                _groupId,
                _remainingMountedUnits
            ]] call FLO_fnc_log;
            [_groupId, true] call FLO_fnc_transportDismount;
        };
        true
    }
};

private _dismountWp = _waypoints select _dismountIdx;
private _dismountPos = _dismountWp select 0;
private _completionRadius = (_dismountWp param [6, 50]) max 35;
private _unloadTriggeredByThreat = [_groupData, _carrierPos] call FLO_fnc_transportShouldThreatDismount;
private _atDismountWaypoint = (_carrierPos distance2D _dismountPos) <= _completionRadius;

if (!_unloadTriggeredByThreat && {!_atDismountWaypoint}) exitWith { true };

if (_insertMode == "AIR_DROP") exitWith {
    private _carrierVehicle = vehicle _leader;
    private _carrierAltitude = getPosATL _carrierVehicle select 2;
    private _carrierSpeed = vectorMagnitude (velocity _carrierVehicle);

    if (_carrierAltitude < FLO_Transport_AirDropReleaseAltitudeMin || {_carrierSpeed < FLO_Transport_AirDropReleaseSpeedMin}) exitWith {
        true
    };

    ["TRANSPORT", 3, format [
        "Active carrier %1 reached AIR_DROP release conditions (%2) - unloading passengers",
        _groupId,
        ["WAYPOINT", "THREAT"] select (_unloadTriggeredByThreat)
    ]] call FLO_fnc_log;
    [_groupId, true] call FLO_fnc_transportDismount;
    true
};

if (_insertMode == "AIR_LAND") then {
    private _carrierVehicle = vehicle _leader;
    private _carrierAltitude = getPosATL _carrierVehicle select 2;
    private _carrierSpeed = vectorMagnitude (velocity _carrierVehicle);

    if !(_groupData get "transportLandCommandIssued") exitWith {
        {
            _x flyInHeight FLO_Transport_AirLandAltitude;
            _x land "GET OUT";
        } forEach _liveCarrierVehicles;
        [_groupId, createHashMapFromArray [
            ["transportLandCommandIssued", true]
        ]] call FLO_fnc_virtualizationPatchGroup;

        ["TRANSPORT", 3, format [
            "Active carrier %1 reached landing insert zone - issuing GET OUT landing",
            _groupId
        ]] call FLO_fnc_log;

        true
    };

    if (!(isTouchingGround _carrierVehicle) && {_carrierAltitude > FLO_Transport_AirLandUnloadAltitudeMax}) exitWith { true };
    if (_carrierSpeed > FLO_Transport_AirLandUnloadSpeedMax) exitWith { true };

    [_groupId, _groupData, _carrierVehicles] call FLO_fnc_transportIssueActiveDismount;
    true
} else {
    private _maxCarrierSpeed = 0;

    {
        private _driver = driver _x;
        if (!isNull _driver) then {
            doStop _driver;
        };
        _x forceSpeed 0;

        private _carrierSpeed = vectorMagnitude (velocity _x);
        if (_carrierSpeed > _maxCarrierSpeed) then {
            _maxCarrierSpeed = _carrierSpeed;
        };
    } forEach _liveCarrierVehicles;

    if (_maxCarrierSpeed > FLO_Transport_GroundUnloadSpeedMax) exitWith { true };

    [_groupId, _groupData, _carrierVehicles] call FLO_fnc_transportIssueActiveDismount;
    true
};
