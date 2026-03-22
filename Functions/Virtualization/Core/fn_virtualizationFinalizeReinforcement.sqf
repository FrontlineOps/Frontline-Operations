/*
 * Function: FLO_fnc_virtualizationFinalizeReinforcement
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears reinforcement-only mission state once a logistics replacement has
 *   effectively reached its destination.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when reinforcement flags were cleared
 */

params ["_groupId", "_groupData"];

if !(_groupData getOrDefault ["isReinforcing", false]) exitWith { false };

_groupData set ["isReinforcing", false];
_groupData set ["onMission", false];
_groupData set ["currentOrder", ""];
_groupData set ["reinforcementTargetPos", []];
_groupData set ["reinforcementRequestedObjective", ""];
_groupData set ["reinforcementDeliveryObjective", ""];

["VIRTUALIZATION", 3, format ["Group %1 reached destination - clearing reinforcement flags", _groupId]] call FLO_fnc_log;

true
