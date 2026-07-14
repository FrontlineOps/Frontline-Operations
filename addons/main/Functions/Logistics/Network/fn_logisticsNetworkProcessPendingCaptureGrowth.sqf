/*
 * Function: FLO_fnc_logisticsNetworkProcessPendingCaptureGrowth
 * Author: Frontline Operations Development Group
 * Description:
 *   Pays out delayed objective capture growth only after a captured objective
 *   has remained secure long enough to be considered consolidated into the
 *   side's active supply picture.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params ["_net"];

private _metrics = createHashMapFromArray [
    ["pendingObjectives", 0],
    ["eligibleObjectives", 0],
    ["appliedObjectives", 0],
    ["appliedGroups", 0]
];

if ((_net get "OBJECTIVE_CAPTURE_FORCE_GROWTH") <= 0) exitWith { _metrics };

private _nowDateNum = call FLO_fnc_operationalDateNumber;
private _managedSide = _net get "_managedSide";
private _managedObjectiveIds = _net get "_managedObjectiveIds";

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;

    if !(_objective get "captureGrowthPending") then { continue };
    _metrics set ["pendingObjectives", (_metrics get "pendingObjectives") + 1];

    if ((_objective get "owner") != _managedSide) then { continue };
    private _growthRemaining = [
        _nowDateNum,
        _objective get "captureGrowthEligibleAtDateNum"
    ] call FLO_fnc_dateNumberDeltaSeconds;
    if (_growthRemaining > 0) then { continue };
    if ((_objective get "contested") || (_objective get "underAttack")) then { continue };

    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if ((_role get "depth") < 0) then { continue };

    _metrics set ["eligibleObjectives", (_metrics get "eligibleObjectives") + 1];

    private _appliedGrowth = [_net, _objectiveId] call FLO_fnc_logisticsNetworkApplyObjectiveCaptureGrowth;
    _objective set ["captureGrowthPending", false];
    _objective set ["captureGrowthEligibleAtDateNum", -1];
    FLO_Objectives set [_objectiveId, _objective];

    if (_appliedGrowth <= 0) then { continue };

    _metrics set ["appliedObjectives", (_metrics get "appliedObjectives") + 1];
    _metrics set ["appliedGroups", (_metrics get "appliedGroups") + _appliedGrowth];

    if (!isNil "FLO_GTN_ResourceManager") then {
        private _cmdr = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_managedSide]];
        if (!isNil "_cmdr") then {
            private _baselineTotalGroups = _cmdr get "_forceBaselineTotalGroups";
            if (_baselineTotalGroups > 0) then {
                _cmdr set ["_forceBaselineTotalGroups", _baselineTotalGroups + _appliedGrowth];
            };
        };
    };
} forEach _managedObjectiveIds;

if ((_metrics get "appliedObjectives") > 0) then {
    publicVariable "FLO_Objectives";

    ["LOGISTICS", 3, format [
        "Delayed capture growth applied: %1 objectives, %2 groups",
        _metrics get "appliedObjectives",
        _metrics get "appliedGroups"
    ]] call FLO_fnc_log;
};

_metrics
