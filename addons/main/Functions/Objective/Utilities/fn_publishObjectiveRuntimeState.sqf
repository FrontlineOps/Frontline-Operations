/*
 * Function: FLO_fnc_publishObjectiveRuntimeState
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes lightweight objective runtime state for JIP and pushes an
 *   immediate client sync without using publicVariable event handlers.
 *
 * Arguments:
 *   0: Optional runtime state <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith { false };

private _runtimeState = if (_this isNotEqualTo []) then {
    _this param [0, createHashMap, [createHashMap]]
} else {
    FLO_ObjectiveRuntimeState
};

FLO_ObjectiveRuntimeState = _runtimeState;
publicVariable "FLO_ObjectiveRuntimeState";
[_runtimeState] remoteExecCall ["FLO_fnc_syncObjectiveRuntimeState", -2];

true
