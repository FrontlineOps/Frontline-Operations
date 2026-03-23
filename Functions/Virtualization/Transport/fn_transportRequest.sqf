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

if (isNil "FLO_virtualGroups") exitWith { "" };
if (isNil "FLO_TransportPool") exitWith { "" };

private _groups = FLO_virtualGroups get "_groups";
private _infData = _groups getOrDefault [_infantryGroupId, nil];

if (isNil "_infData") exitWith {
    ["TRANSPORT", 2, format["Request failed: infantry group %1 not found", _infantryGroupId]] call FLO_fnc_log;
    ""
};

// Get infantry data
private _currentPos = _infData get "position";
private _unitCount = _infData getOrDefault ["unitCount", 4];
private _side = _infData get "side";

// Check distance threshold
private _distance = _currentPos distance2D _destinationPos;
if (!_forceTransport && _distance < FLO_Transport_MinDistance) exitWith {
    ["TRANSPORT", 4, format["Request skipped: distance %1m < threshold %2m", 
        round _distance, FLO_Transport_MinDistance]] call FLO_fnc_log;
    ""
};

// Try to find transport in pool first
private _transportId = [_unitCount, _currentPos, 3000] call FLO_fnc_transportPoolFind;

// If not found, search for existing vehicle groups
if (_transportId == "") then {
    _transportId = [_unitCount, _currentPos, _side, FLO_Transport_SearchRadius] call FLO_fnc_transportPoolFindExisting;
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

// Get transport data
private _transData = _groups get _transportId;

// Calculate dismount position (100m from destination)
private _dismountPos = _destinationPos getPos [100, _destinationPos getDir _currentPos];

// Set transport waypoints
private _waypoints = [
    [_dismountPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 50]
];
[_transportId, _waypoints, false, true, "TRANSPORT_REQUEST"] call FLO_fnc_updateVirtualGroupWaypoints;

// Configure for dismount
_transData set ["dismountAtWaypoint", 0];
[_transData, "TRANSPORT", "TRANSPORT_REQUEST"] call FLO_fnc_virtualizationSetMissionLock;
[_transData, "TRANSPORT"] call FLO_fnc_virtualizationSetExecutionState;

["TRANSPORT", 3, format["Request: Transport %1 assigned to carry %2 to destination (%3m)", 
    _transportId, _infantryGroupId, round _distance]] call FLO_fnc_log;

_transportId
