/*
 * Function: FLO_fnc_transportSelectRequestCarrier
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the transport request carrier selection ladder. This keeps
 *   transportRequest focused on committing a selected mission plan while this
 *   function owns carrier precedence and any required reserve activation prep.
 *
 * Arguments:
 *   0: Request candidates <HASHMAP>
 *   1: Passenger activation key <STRING>
 *   2: Allow ground transport <BOOL>
 *   3: Allow air transport <BOOL>
 *   4: Force air transport <BOOL>
 *   5: Request distance <NUMBER>
 *   6: Passenger is active <BOOL>
 *   7: Passenger group ID <STRING>
 *   8: Passenger group data <HASHMAP>
 *
 * Return Value:
 *   ARRAY - [carrier group ID <STRING>, carrier group data <HASHMAP>]
 */

params [
    ["_requestCandidates", createHashMap, [createHashMap]],
    ["_activationKey", "Virtual", [""]],
    ["_allowGroundTransport", true, [true]],
    ["_allowAirTransport", true, [true]],
    ["_forceAirTransport", false, [true]],
    ["_distance", 0, [0]],
    ["_infantryIsActive", false, [true]],
    ["_infantryGroupId", "", [""]],
    ["_infData", createHashMap, [createHashMap]]
];

private _transportId = "";
private _transportData = createHashMap;

// Prefer dedicated reserve carriers first in the passenger's current activation state.
if (_allowGroundTransport) then {
    _transportId = _requestCandidates get format ["groundAvailable%1Dedicated", _activationKey];
    if (_transportId == "") then {
        _transportId = _requestCandidates get format ["groundExisting%1Dedicated", _activationKey];
    };
};

// Active squads can activate a virtual reserve carrier on demand.
if (_allowGroundTransport && {_transportId == ""} && {_infantryIsActive}) then {
    _transportId = _requestCandidates get "groundAvailableVirtualDedicated";
    if (_transportId == "") then {
        _transportId = _requestCandidates get "groundExistingVirtualDedicated";
    };

    if (_transportId != "") then {
        _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
        if !([_transportId, _transportData, _infantryGroupId, _infData] call FLO_fnc_transportPrepareCarrierForPickup) then {
            _transportId = "";
            _transportData = createHashMap;
        };
    };
};

// Fall back to any available ground carrier, including organic combat vehicles.
if (_allowGroundTransport && {_transportId == ""}) then {
    _transportId = _requestCandidates get format ["groundAvailable%1Fallback", _activationKey];
};

if (_allowGroundTransport && {_transportId == ""}) then {
    _transportId = _requestCandidates get format ["groundExisting%1Fallback", _activationKey];
};

// Long-haul fallback: request dedicated airlift if no ground carrier is available.
if (_allowAirTransport && {_transportId == ""} && {(_distance >= FLO_Transport_AirPickupMinDistance) || _forceAirTransport}) then {
    _transportId = _requestCandidates get format ["airAvailable%1Dedicated", _activationKey];
    if (_transportId == "") then {
        _transportId = _requestCandidates get format ["airExisting%1Dedicated", _activationKey];
    };
};

if (_allowAirTransport && {_transportId == ""} && {((_distance >= FLO_Transport_AirPickupMinDistance) || _forceAirTransport)} && {_infantryIsActive}) then {
    _transportId = _requestCandidates get "airAvailableVirtualDedicated";
    if (_transportId == "") then {
        _transportId = _requestCandidates get "airExistingVirtualDedicated";
    };

    if (_transportId != "") then {
        _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
        if !([_transportId, _transportData, _infantryGroupId, _infData] call FLO_fnc_transportPrepareCarrierForPickup) then {
            _transportId = "";
            _transportData = createHashMap;
        };
    };
};

if (_transportId != "" && {(keys _transportData) isEqualTo []}) then {
    _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
};

[_transportId, _transportData]
