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
 *   2: Force transport (skip distance check) <BOOLEAN> or request spec <HASHMAP> - Optional
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
    ["_transportRequest", false]
];

if (_infantryGroupId == "") exitWith { "" };
if (_destinationPos isEqualTo [0,0,0]) exitWith { "" };

private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;
private _forceTransport = false;
private _requestSpec = createHashMap;

if (_transportRequest isEqualType true) then {
    _forceTransport = _transportRequest;
} else {
    if !(_transportRequest isEqualType createHashMap) then {
        throw format [
            "[TRANSPORT] Invalid request payload type for %1: %2",
            _infantryGroupId,
            typeName _transportRequest
        ];
    };
    _requestSpec = _transportRequest;
    if ("forceTransport" in _requestSpec) then {
        _forceTransport = _requestSpec get "forceTransport";
    };
};

private _forcedMode = if ("forceMode" in _requestSpec) then {
    toUpper (_requestSpec get "forceMode")
} else {
    ""
};
private _allowGroundTransport = !(_forcedMode in ["AIR_LAND", "AIR_DROP"]);
private _allowAirTransport = _forcedMode != "GROUND";
private _forceAirTransport = _forcedMode in ["AIR_LAND", "AIR_DROP"];

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
if (_allowGroundTransport && {_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
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
};
if (_allowGroundTransport && {!_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
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
if (_allowGroundTransport && {_transportId == ""} && {_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
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
if (_allowGroundTransport && {_transportId == ""}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
        3000,
        _requiredActivation,
        _groundCarrierTypes,
        false
    ] call FLO_fnc_transportPoolFind;
};

if (_allowGroundTransport && {_transportId == ""}) then {
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
if (_allowAirTransport && {_transportId == ""} && {(_distance >= FLO_Transport_AirPickupMinDistance) || _forceAirTransport}) then {
    if (_infantryIsActive) then {
        _transportId = [
            _unitCount,
            _currentPos,
            _side,
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
            _side,
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

if (_allowAirTransport && {_transportId == ""} && {((_distance >= FLO_Transport_AirPickupMinDistance) || _forceAirTransport)} && {_infantryIsActive}) then {
    _transportId = [
        _unitCount,
        _currentPos,
        _side,
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

if (!_hasTransportData) then {
    _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
    _hasTransportData = true;
};

private _missionPlan = [
    _infantryGroupId,
    _infData,
    _transportId,
    _transportData,
    _destinationPos,
    _requestSpec
] call FLO_fnc_transportBuildMissionPlan;
if (count (keys _missionPlan) == 0) exitWith {
    ["TRANSPORT", 2, format [
        "Request failed: could not build mission plan for passenger %1 using carrier %2",
        _infantryGroupId,
        _transportId
    ]] call FLO_fnc_log;
    ""
};

private _insertMode = _missionPlan get "mode";
private _insertPos = _missionPlan get "insertPos";
private _completionRadius = _missionPlan get "completionRadius";
private _orderTag = _missionPlan get "orderTag";

// Claim transport
[_transportId, _infantryGroupId] call FLO_fnc_transportPoolClaim;

// Attach infantry to transport
private _attached = [_infantryGroupId, _transportId] call FLO_fnc_transportAttach;
if (!_attached) exitWith {
    [_transportId] call FLO_fnc_transportPoolRelease;
    ["TRANSPORT", 2, format["Request failed: could not attach %1 to %2", _infantryGroupId, _transportId]] call FLO_fnc_log;
    ""
};

private _transportType = _transportData get "groupType";

// Set transport waypoints
private _waypoints = [
    [_insertPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", _completionRadius]
];
[_transportId, _waypoints, false, true, _orderTag] call FLO_fnc_updateVirtualGroupWaypoints;

// Configure for dismount
_transportData set ["dismountAtWaypoint", 0];
_transportData set ["transportInsertMode", _insertMode];
_transportData set ["transportInsertPos", _insertPos];
_transportData set ["transportLandCommandIssued", false];
[_transportData, "TRANSPORT", _insertMode] call FLO_fnc_virtualizationSetMissionLock;
[_transportData, "TRANSPORT"] call FLO_fnc_virtualizationSetExecutionState;
[_infData, "TRANSPORT", _insertMode] call FLO_fnc_virtualizationSetMissionLock;
_infData set ["postDismountWaypoint", [_destinationPos, _orderTag]];

["TRANSPORT", 3, format["Request: Transport %1 (%2) assigned to carry %3 via %4 to destination (%5m)",
    _transportId, _transportType, _infantryGroupId, _insertMode, round _distance]] call FLO_fnc_log;

_transportId
