/*
 * Function: FLO_fnc_initObjectiveRuntimeStateEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers the client-side publicVariable event handler that merges the
 *   lightweight objective runtime state into local FLO_Objectives.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_ObjectiveRuntimeStateEventsInit" && {FLO_ObjectiveRuntimeStateEventsInit}) exitWith { true };

"FLO_ObjectiveRuntimeState" addPublicVariableEventHandler {
    params ["_variableName", "_runtimeState"];
    [_runtimeState] call FLO_fnc_syncObjectiveRuntimeState;
};

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_Objectives"
    };

    if (!isNil "FLO_ObjectiveRuntimeState") then {
        [FLO_ObjectiveRuntimeState] call FLO_fnc_syncObjectiveRuntimeState;
    };
};

FLO_ObjectiveRuntimeStateEventsInit = true;

true
