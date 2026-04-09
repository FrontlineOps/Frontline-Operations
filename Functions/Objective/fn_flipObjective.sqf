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

private _captureDateNum = dateToNumber date;

// Update owner
_obj set ["owner", _newOwner];
_obj set ["capturedAtDateNum", _captureDateNum];
_obj set ["capturedFrom", _previousOwner];
_obj set ["captureGrowthEligibleAtDateNum", -1];
_obj set ["captureGrowthPending", false];
FLO_Objectives set [_objectiveId, _obj];

if (!isNil "FLO_SideResources" && {_newOwner in [east, west]}) then {
    private _sideKey = ([_newOwner] call FLO_fnc_gtnSideContext) get "sideKey";
    private _resourceObj = FLO_SideResources get _sideKey;
    private _captureReward = _resourceObj get "OBJECTIVE_CAPTURE_REWARD";
    [_resourceObj, _captureReward, true] call FLO_fnc_sideResourcesAddResources;

    ["SIDE_RES", 3, format [
        "Objective capture reward: %1 gained %2 resources for %3",
        _sideKey,
        _captureReward,
        _objectiveId
    ]] call FLO_fnc_log;

    if (!isNil "FLO_Logistics_Networks" && {_sideKey in FLO_Logistics_Networks}) then {
        private _net = FLO_Logistics_Networks get _sideKey;
        if ((_net get "OBJECTIVE_CAPTURE_FORCE_GROWTH") > 0) then {
            _obj set [
                "captureGrowthEligibleAtDateNum",
                _captureDateNum + ((_net get "OBJECTIVE_CAPTURE_GROWTH_DELAY_SECONDS") / 86400)
            ];
            _obj set ["captureGrowthPending", true];
            FLO_Objectives set [_objectiveId, _obj];

            ["LOGISTICS", 3, format [
                "Queued delayed capture growth: %1 held by %2 until %3",
                _objectiveId,
                _sideKey,
                _obj get "captureGrowthEligibleAtDateNum"
            ]] call FLO_fnc_log;
        };
    };
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
