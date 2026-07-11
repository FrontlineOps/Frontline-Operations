/*
 * Function: FLO_fnc_buildObjectiveRuntimeState
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the lightweight replicated objective runtime state map used for
 *   hot client-side objective updates without rebroadcasting full objective
 *   definitions.
 *
 * Arguments: None
 *
 * Return Value:
 *   HASHMAP - objectiveId -> runtime state
 */

if (isNil "FLO_Objectives") exitWith { createHashMap };

private _runtimeState = createHashMap;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;

    _runtimeState set [_objectiveId, [_objective] call FLO_fnc_buildObjectiveRuntimeRecord];
} forEach (keys FLO_Objectives);

_runtimeState
