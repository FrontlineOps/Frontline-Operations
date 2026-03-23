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
private _previousOwner = _obj getOrDefault ["owner", east];
if (_previousOwner isEqualTo _newOwner) exitWith { false };

// Update owner
_obj set ["owner", _newOwner];
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
        private _forceGrowth = [_net, _objectiveId] call FLO_fnc_logisticsNetworkApplyObjectiveCaptureGrowth;

        if (_forceGrowth > 0 && {!isNil "FLO_GTN_ResourceManager"}) then {
            private _cmdr = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_newOwner]];
            if (!isNil "_cmdr") then {
                private _baselineTotalGroups = _cmdr get "_forceBaselineTotalGroups";
                if (_baselineTotalGroups > 0) then {
                    _cmdr set ["_forceBaselineTotalGroups", _baselineTotalGroups + _forceGrowth];
                };
            };
        };
    };
};

// Update marker using centralized function
[_objectiveId, _obj] call FLO_fnc_createObjectiveMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// Broadcast change
publicVariable "FLO_Objectives";

// Log the flip
["OBJECTIVE", 3, format ["Objective %1 flipped from %2 to %3", _objectiveId, _previousOwner, _newOwner]] call FLO_fnc_log;

true
