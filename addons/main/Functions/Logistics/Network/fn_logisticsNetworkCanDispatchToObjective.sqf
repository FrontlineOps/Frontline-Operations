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

([_net, _objectiveId, _groupType, _inboundCounts, _batchDispatchCounts] call FLO_fnc_logisticsNetworkGetDispatchTargetRejectionReason) == ""
