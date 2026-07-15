/*
 * Function: FLO_fnc_flipObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Changes the owner of an objective and updates its marker color.
 *   Uses centralized config for marker colors.
 *
 * Arguments:
 *   0: Objective ID (STRING)
 *   1: New owner (SIDE)
 *
 * Returns: BOOL - Success
 *
 * Example:
 *   ["virtual_1", west] call FLO_fnc_flipObjective;
 */

params [
    ["_objectiveId", ""],
    ["_newOwner", civilian]
];

// Validate inputs
if (_objectiveId == "") exitWith { false };
if (isNil "FLO_Objectives") exitWith { false };

private _obj = FLO_Objectives get _objectiveId;
if (isNil "_obj") exitWith { false };

// Store previous owner for event
private _previousOwner = _obj get "owner";
if (_previousOwner isEqualTo _newOwner) exitWith { false };

private _captureDateNum = call FLO_fnc_operationalDateNumber;

_obj = [_objectiveId, _obj, _previousOwner, _newOwner] call FLO_fnc_objectiveDevelopmentHandleCapture;

// Update owner
_obj set ["owner", _newOwner];
_obj set ["capturedAtDateNum", _captureDateNum];
_obj set ["capturedFrom", _previousOwner];
_obj set ["captureGrowthEligibleAtDateNum", -1];
_obj set ["captureGrowthPending", false];
_obj set ["captureProgress", 0];
_obj set ["captureState", "integrating"];
_obj set ["captureSide", sideUnknown];
_obj set ["captureSecureStartedAt", -1];
_obj set ["captureSecureProgress", 0];
_obj set ["captureStatusChangedAt", diag_tickTime];
_obj = [_objectiveId, _obj, _newOwner] call FLO_fnc_campaignClassifyCapture;
FLO_Objectives set [_objectiveId, _obj];

if (!isNil "FLO_Logistics_Networks") then {
    {
        private _sideKey = _x;
        if !(_sideKey in FLO_Logistics_Networks) then { continue };
        [FLO_Logistics_Networks get _sideKey] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
    } forEach ["EAST", "WEST"];
};

// Update marker using centralized function
[_objectiveId, _obj] call FLO_fnc_createObjectiveMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// Broadcast change
publicVariable "FLO_Objectives";
["FLO_Objective_Flipped", [_objectiveId, _previousOwner, _newOwner]] call CBA_fnc_localEvent;

// Log the flip
["OBJECTIVE", 3, format ["Objective %1 flipped from %2 to %3", _objectiveId, _previousOwner, _newOwner]] call FLO_fnc_log;

true
