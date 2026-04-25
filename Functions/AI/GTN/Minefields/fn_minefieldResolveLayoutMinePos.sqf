/*
 * Function: FLO_fnc_minefieldResolveLayoutMinePos
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves one candidate objective-front mine position and returns an empty
 *   array when the slot should be rejected.
 *
 * Arguments:
 * 0: Frontline placement context <HASHMAP>
 * 1: Mine type <STRING>
 * 2: Depth offset <SCALAR>
 * 3: Lateral offset <SCALAR>
 * 4: Spacing index <HASHMAP>
 * 5: Layout stats <HASHMAP>
 *
 * Return Value:
 * ARRAY - Accepted ATL position, or []
 */

params [
    ["_context", createHashMap],
    ["_mineType", ""],
    ["_depthOffset", 0],
    ["_lateralOffset", 0],
    ["_spacingIndex", createHashMap],
    ["_layoutStats", createHashMap]
];

if !(_context isEqualType createHashMap) exitWith { [] };
if (_mineType == "") exitWith { [] };

private _anchorPos = _context get "anchorPos";
private _facingDir = _context get "facingDir";
private _depthJitterMax = FLO_MinefieldConfig get "depthJitterMax";
private _minSpacing = FLO_MinefieldConfig get "minSpacing";
private _packetRole = _context get "packetRole";
private _safeResolveRadius = FLO_MinefieldConfig get "slotSafeResolveRadius";
private _slotLateralJitterMax = FLO_MinefieldConfig get "slotLateralJitterMax";
private _resolvedDepthOffset = _depthOffset + ((random (_depthJitterMax * 2)) - _depthJitterMax);
private _resolvedLateralOffset = _lateralOffset + ((random (_slotLateralJitterMax * 2)) - _slotLateralJitterMax);

if (_mineType isEqualTo "ATMine") then {
    _resolvedLateralOffset = _lateralOffset + ((random _slotLateralJitterMax) - (_slotLateralJitterMax * 0.5));
};

private _forwardPos = _anchorPos getPos [abs _resolvedDepthOffset, _facingDir + (if (_resolvedDepthOffset >= 0) then { 0 } else { 180 })];
private _candidatePos = _forwardPos getPos [abs _resolvedLateralOffset, _facingDir + (if (_resolvedLateralOffset >= 0) then { 90 } else { 270 })];
_candidatePos set [2, 0];

if (_mineType isEqualTo "ATMine" || {_packetRole isEqualTo "road"}) then {
    private _roads = _candidatePos nearRoads 18;
    if ((count _roads) > 0) then {
        if (_mineType isEqualTo "ATMine") then {
            _candidatePos = getPosATL (_roads select 0);
        };
        _candidatePos set [2, 0];
    };
};

private _validation = [_context, _candidatePos] call FLO_fnc_minefieldValidateSlotCandidate;
private _validationReason = _validation select 0;
private _safePos = _validation select 1;

if (_validationReason != "") then {
    _safePos = [_candidatePos, 0, _safeResolveRadius, 1, 0, 0.35, 0] call BIS_fnc_findSafePos;
    if (_safePos isEqualTo [0, 0, 0]) exitWith {
        _layoutStats set ["rejectedNoSafePos", (_layoutStats get "rejectedNoSafePos") + 1];
        []
    };

    _validation = [_context, _safePos] call FLO_fnc_minefieldValidateSlotCandidate;
    _validationReason = _validation select 0;
    _safePos = _validation select 1;
};

if (_validationReason != "") exitWith {
    switch (_validationReason) do {
        case "water": {
            _layoutStats set ["rejectedWater", (_layoutStats get "rejectedWater") + 1];
        };
        case "defended": {
            _layoutStats set ["rejectedDefendedObjective", (_layoutStats get "rejectedDefendedObjective") + 1];
        };
        case "foreign": {
            _layoutStats set ["rejectedForeignObjective", (_layoutStats get "rejectedForeignObjective") + 1];
        };
        default {
            _layoutStats set ["rejectedNoSafePos", (_layoutStats get "rejectedNoSafePos") + 1];
        };
    };
    
    []
};

if !([_safePos, _spacingIndex, _minSpacing] call FLO_fnc_minefieldCanPlaceWithSpacing) exitWith {
    _layoutStats set ["rejectedSpacing", (_layoutStats get "rejectedSpacing") + 1];
    []
};

if (_validationReason == "") then {
    _layoutStats set ["acceptedDirectSlots", (_layoutStats get "acceptedDirectSlots") + 1];
} else {
    _layoutStats set ["acceptedFallbackSlots", (_layoutStats get "acceptedFallbackSlots") + 1];
};

if ((count _safePos) < 2) exitWith { [] };

_safePos
