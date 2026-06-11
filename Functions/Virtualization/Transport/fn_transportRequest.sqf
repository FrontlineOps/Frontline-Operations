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
private _activationKey = if (_infantryIsActive) then { "Active" } else { "Virtual" };
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
private _requestCandidates = [
    _unitCount,
    _currentPos,
    _side,
    _groundCarrierTypes,
    _airCarrierTypes
] call FLO_fnc_transportFindRequestCandidates;

private _carrierSelection = [
    _requestCandidates,
    _activationKey,
    _allowGroundTransport,
    _allowAirTransport,
    _forceAirTransport,
    _distance,
    _infantryIsActive,
    _infantryGroupId,
    _infData
] call FLO_fnc_transportSelectRequestCarrier;
_carrierSelection params ["_selectedTransportId", "_selectedTransportData"];
_transportId = _selectedTransportId;
_transportData = _selectedTransportData;

// No transport available
if (_transportId == "") exitWith {
    ["TRANSPORT", 3, format["Request: No transport available for %1 - infantry will walk", _infantryGroupId]] call FLO_fnc_log;
    ""
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

if !([
    _infantryGroupId,
    _infData,
    _transportId,
    _transportData,
    _missionPlan,
    _destinationPos,
    _distance
] call FLO_fnc_transportCommitMissionPlan) exitWith { "" };

_transportId
