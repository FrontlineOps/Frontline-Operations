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

    _runtimeState set [_objectiveId, createHashMapFromArray [
        ["captureProgress", _objective get "captureProgress"],
        ["captureState", _objective get "captureState"],
        ["captureSide", _objective get "captureSide"],
        ["captureSecureProgress", _objective get "captureSecureProgress"],
        ["captureSecureStartedAt", _objective get "captureSecureStartedAt"],
        ["captureStatusChangedAt", _objective get "captureStatusChangedAt"],
        ["captureIntegratedAtDateNum", _objective get "captureIntegratedAtDateNum"],
        ["bluforCount", _objective get "bluforCount"],
        ["opforCount", _objective get "opforCount"],
        ["contested", _objective get "contested"],
        ["underAttack", _objective get "underAttack"]
    ]];
} forEach (keys FLO_Objectives);

_runtimeState
