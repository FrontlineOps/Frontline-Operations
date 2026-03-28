/*
 * Function: FLO_fnc_logisticsNetworkCanDispatchToObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies hard saturation rules to a maneuver reinforcement objective so one
 *   pressured sector cannot absorb every dispatch window indefinitely.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *   2: Group type <STRING> - Default infantry
 *   3: Inbound requested-objective counts <HASHMAP> - Default empty map
 *   4: Batch requested-objective counts <HASHMAP> - Default empty map
 *
 * Return Value:
 *   BOOL - True when dispatch is allowed
 */

params [
    "_net",
    "_objectiveId",
    ["_groupType", "infantry"],
    ["_inboundCounts", createHashMap],
    ["_batchDispatchCounts", createHashMap]
];

if (_objectiveId == "") exitWith { false };
if (_groupType isEqualTo "static_aa") exitWith { true };

private _objective = FLO_Objectives get _objectiveId;
private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
private _enemyCountKey = if (_managedSide isEqualTo east) then { "bluforCount" } else { "opforCount" };

private _friendlyCount = _objective get _friendlyCountKey;
private _enemyCount = _objective get _enemyCountKey;
private _inboundCount = if (_objectiveId in _inboundCounts) then { _inboundCounts get _objectiveId } else { 0 };
private _batchCount = if (_objectiveId in _batchDispatchCounts) then { _batchDispatchCounts get _objectiveId } else { 0 };

if (_enemyCount <= 0) exitWith {
    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if (_role get "isAdvanceCandidate") then {
        private _deliveryCount = _role get "deliveryCount";
        private _minDeliveries = _net get "SUPPLY_NODE_MIN_DELIVERIES";
        private _minActiveFriendlyCount = _net get "SUPPLY_NODE_MIN_ACTIVE_FRIENDLY_COUNT";
        private _canAdvance = true;

        if (_deliveryCount >= _minDeliveries && {_friendlyCount >= _minActiveFriendlyCount}) then {
            _canAdvance = false;
        };
        if (_inboundCount >= (_net get "SUPPLY_ADVANCE_OBJECTIVE_INBOUND_CAP")) then {
            _canAdvance = false;
        };
        if (_batchCount >= (_net get "SUPPLY_ADVANCE_OBJECTIVE_BATCH_CAP")) then {
            _canAdvance = false;
        };

        _canAdvance
    } else {
        true
    };
};

if ((_objective get "contested")) then {
    private _forceRatio = _friendlyCount / _enemyCount;
    if (_forceRatio < (_net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO")) then {
        if (_inboundCount >= (_net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_INBOUND_CAP")) exitWith { false };
    };
};

private _secureRatio = _net get "REINFORCEMENT_OBJECTIVE_SECURE_RATIO";
if (_friendlyCount >= ceil (_enemyCount * _secureRatio)) exitWith { false };

private _pressure = ((_enemyCount * 2) - _friendlyCount) max 0;
private _pressurePerGroup = _net get "REINFORCEMENT_OBJECTIVE_PRESSURE_PER_GROUP";
private _inboundCap = ceil (_pressure / _pressurePerGroup);

private _inboundCapMin = _net get "REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MIN";
private _inboundCapMax = _net get "REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MAX";
if (_inboundCap < _inboundCapMin) then { _inboundCap = _inboundCapMin; };
if (_inboundCap > _inboundCapMax) then { _inboundCap = _inboundCapMax; };

if (_inboundCount >= _inboundCap) exitWith { false };

private _batchCap = _inboundCap min (_net get "REINFORCEMENT_OBJECTIVE_BATCH_CAP_MAX");
if (_batchCount >= _batchCap) exitWith { false };

true
