/*
 * Function: FLO_fnc_logisticsNetworkGetDispatchTargetRejectionReason
 * Description:
 *   Classifies the hard gate that rejects one maneuver reinforcement target.
 *
 * Return Value:
 *   Empty string when dispatch is allowed, otherwise one stable reason code.
 */

params [
    "_net",
    ["_objectiveId", "", [""]],
    ["_groupType", "infantry", [""]],
    ["_inboundCounts", createHashMap, [createHashMap]],
    ["_batchDispatchCounts", createHashMap, [createHashMap]]
];

if (_objectiveId == "") then {
    throw "FLO_fnc_logisticsNetworkGetDispatchTargetRejectionReason: empty objective id";
};

private _objective = FLO_Objectives get _objectiveId;
if !([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) exitWith { "NOT_INTEGRATED" };
if (_groupType == "static_aa") exitWith { "" };

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = ["bluforCount", "opforCount"] select (_managedSide isEqualTo east);
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
private _friendlyCount = _objective get _friendlyCountKey;
private _enemyCount = _objective get _enemyCountKey;
private _inboundCount = if (_objectiveId in _inboundCounts) then { _inboundCounts get _objectiveId } else { 0 };
private _batchCount = if (_objectiveId in _batchDispatchCounts) then { _batchDispatchCounts get _objectiveId } else { 0 };

if (_enemyCount <= 0) exitWith { "" };

if ((_objective get "contested")) then {
    private _forceRatio = _friendlyCount / _enemyCount;
    if (
        _forceRatio < (_net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO")
        && {_inboundCount >= (_net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_INBOUND_CAP")}
    ) exitWith { "COLLAPSE_INBOUND_CAP" };
};

private _secureRatio = _net get "REINFORCEMENT_OBJECTIVE_SECURE_RATIO";
if (_friendlyCount >= ceil (_enemyCount * _secureRatio)) exitWith { "SECURE_RATIO" };

private _pressure = ((_enemyCount * 2) - _friendlyCount) max 0;
private _inboundCap = ceil (_pressure / (_net get "REINFORCEMENT_OBJECTIVE_PRESSURE_PER_GROUP"));
_inboundCap = _inboundCap max (_net get "REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MIN");
_inboundCap = _inboundCap min (_net get "REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MAX");
if (_inboundCount >= _inboundCap) exitWith { "INBOUND_CAP" };

private _batchCap = _inboundCap min (_net get "REINFORCEMENT_OBJECTIVE_BATCH_CAP_MAX");
if (_batchCount >= _batchCap) exitWith { "BATCH_CAP" };

""
