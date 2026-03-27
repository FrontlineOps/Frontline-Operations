/*
 * Function: FLO_fnc_transportRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Request transport for an infantry group to a destination.
 *   Main entry point for the transport system.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Destination Position <ARRAY>
 *   2: Force transport (skip distance check) <BOOLEAN> - Optional
 *
 * Return Value:
 *   Transport Group ID or "" if unavailable <STRING>
 *
 * Example:
 *   ["vgroup_123", [5000, 5000, 0]] call FLO_fnc_transportRequest;
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_destinationPos", [0,0,0], [[]]],
    ["_forceTransport", false, [false]]
];

if (_infantryGroupId == "") exitWith { "" };
if (_destinationPos isEqualTo [0,0,0]) exitWith { "" };

private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;

private _currentPos = _infData get "position";
private _unitCount = _infData get "unitCount";
private _side = _infData get "side";
private _infantryIsActive = _infData get "isActive";
private _requiredActivation = if (_infantryIsActive) then { "ACTIVE" } else { "VIRTUAL" };
private _groundCarrierTypes = ["motorized", "mechanized"];
private _airCarrierTypes = ["helicopter"];

// Check distance threshold
private _distance = _currentPos distance2D _destinationPos;
if (!_forceTransport && _distance < FLO_Transport_MinDistance) exitWith {
    ["TRANSPORT", 4, format["Request skipped: distance %1m < threshold %2m", 
        round _distance, FLO_Transport_MinDistance]] call FLO_fnc_log;
    ""
};

private _transportId = "";
private _transportData = createHashMap;
private _hasTransportData = false;

// Prefer dedicated reserve carriers first in the passenger's current activation state.
if (_infantryIsActive) then {
    _transportId = [
        _unitCount,
        _currentPos,
        3000,
        "ACTIVE",
        _groundCarrierTypes,
        true
    ] call FLO_fnc_transportPoolFind;

    if (_transportId == "") then {
        _transportId = [
            _unitCount,
            _currentPos,
            _side,
            FLO_Transport_SearchRadius,
            "ACTIVE",
            _groundCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFindExisting;
    };
} else {
    _transportId = [
        _unitCount,
        _currentPos,
        3000,
        "VIRTUAL",
        _groundCarrierTypes,
        true
    ] call FLO_fnc_transportPoolFind;

    if (_transportId == "") then {
        _transportId = [
            _unitCount,
            _currentPos,
            _side,
            FLO_Transport_SearchRadius,
            "VIRTUAL",
            _groundCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFindExisting;
    };
};

// Active squads can activate a virtual reserve carrier on demand.
if (_transportId == "" && {_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        3000,
        "VIRTUAL",
        _groundCarrierTypes,
        true
    ] call FLO_fnc_transportPoolFind;

    if (_transportId == "") then {
        _transportId = [
            _unitCount,
            _currentPos,
            _side,
            FLO_Transport_SearchRadius,
            "VIRTUAL",
            _groundCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFindExisting;
    };

    if (_transportId != "") then {
        _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
        _hasTransportData = true;
        if !([_transportId, _transportData, _infantryGroupId, _infData] call FLO_fnc_transportPrepareCarrierForPickup) then {
            _transportId = "";
            _transportData = createHashMap;
            _hasTransportData = false;
        };
    };
};

// Fall back to any available ground carrier, including organic combat vehicles.
if (_transportId == "") then {
    _transportId = [
        _unitCount,
        _currentPos,
        3000,
        _requiredActivation,
        _groundCarrierTypes,
        false
    ] call FLO_fnc_transportPoolFind;
};

if (_transportId == "") then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
        FLO_Transport_SearchRadius,
        _requiredActivation,
        _groundCarrierTypes,
        false
    ] call FLO_fnc_transportPoolFindExisting;
};

// Long-haul fallback: request dedicated airlift if no ground carrier is available.
if (_transportId == "" && {_distance >= FLO_Transport_AirPickupMinDistance}) then {
    if (_infantryIsActive) then {
        _transportId = [
            _unitCount,
            _currentPos,
            FLO_Transport_AirSearchRadius,
            "ACTIVE",
            _airCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFind;

        if (_transportId == "") then {
            _transportId = [
                _unitCount,
                _currentPos,
                _side,
                FLO_Transport_AirSearchRadius,
                "ACTIVE",
                _airCarrierTypes,
                true
            ] call FLO_fnc_transportPoolFindExisting;
        };
    } else {
        _transportId = [
            _unitCount,
            _currentPos,
            FLO_Transport_AirSearchRadius,
            "VIRTUAL",
            _airCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFind;

        if (_transportId == "") then {
            _transportId = [
                _unitCount,
                _currentPos,
                _side,
                FLO_Transport_AirSearchRadius,
                "VIRTUAL",
                _airCarrierTypes,
                true
            ] call FLO_fnc_transportPoolFindExisting;
        };
    };
};

if (_transportId == "" && {_distance >= FLO_Transport_AirPickupMinDistance} && {_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        FLO_Transport_AirSearchRadius,
        "VIRTUAL",
        _airCarrierTypes,
        true
    ] call FLO_fnc_transportPoolFind;

    if (_transportId == "") then {
        _transportId = [
            _unitCount,
            _currentPos,
            _side,
            FLO_Transport_AirSearchRadius,
            "VIRTUAL",
            _airCarrierTypes,
            true
        ] call FLO_fnc_transportPoolFindExisting;
    };

    if (_transportId != "") then {
        _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
        _hasTransportData = true;
        if !([_transportId, _transportData, _infantryGroupId, _infData] call FLO_fnc_transportPrepareCarrierForPickup) then {
            _transportId = "";
            _transportData = createHashMap;
            _hasTransportData = false;
        };
    };
};

// No transport available
if (_transportId == "") exitWith {
    ["TRANSPORT", 3, format["Request: No transport available for %1 - infantry will walk", _infantryGroupId]] call FLO_fnc_log;
    ""
};

// Claim transport
[_transportId, _infantryGroupId] call FLO_fnc_transportPoolClaim;

// Attach infantry to transport
private _attached = [_infantryGroupId, _transportId] call FLO_fnc_transportAttach;
if (!_attached) exitWith {
    [_transportId] call FLO_fnc_transportPoolRelease;
    ["TRANSPORT", 2, format["Request failed: could not attach %1 to %2", _infantryGroupId, _transportId]] call FLO_fnc_log;
    ""
};

if (!_hasTransportData) then {
    _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
};
private _transportType = _transportData get "groupType";

// Calculate dismount position short of the destination
private _dismountPos = _destinationPos getPos [FLO_Transport_DismountDistance, _destinationPos getDir _currentPos];

// Set transport waypoints
private _waypoints = [
    [_dismountPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 50]
];
[_transportId, _waypoints, false, true, "TRANSPORT_REQUEST"] call FLO_fnc_updateVirtualGroupWaypoints;

// Configure for dismount
_transportData set ["dismountAtWaypoint", 0];
[_transportData, "TRANSPORT", "TRANSPORT_REQUEST"] call FLO_fnc_virtualizationSetMissionLock;
[_transportData, "TRANSPORT"] call FLO_fnc_virtualizationSetExecutionState;
_infData set ["postDismountWaypoint", [_destinationPos, "TRANSPORT_REQUEST"]];

["TRANSPORT", 3, format["Request: Transport %1 (%2) assigned to carry %3 to destination (%4m)",
    _transportId, _transportType, _infantryGroupId, round _distance]] call FLO_fnc_log;

_transportId
