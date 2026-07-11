/*
 * Function: FLO_fnc_virtualizationSetAADeployState
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical AA deployment state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Deployment state <STRING>
 * 2: Target position <ARRAY>
 * 3: Target objective <STRING>
 * 4: Strategic AA flag <BOOL>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_state", ["_targetPos", []], ["_objectiveId", ""], ["_isStrategicAA", false]];

_groupData set ["aaDeployState", _state];
_groupData set ["aaDeployTargetPos", _targetPos];
_groupData set ["aaDeployTargetObjective", _objectiveId];
_groupData set ["isStrategicAA", _isStrategicAA];

true
