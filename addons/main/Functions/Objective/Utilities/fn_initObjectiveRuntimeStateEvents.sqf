/*
 * Function: FLO_fnc_initObjectiveRuntimeStateEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the initial lightweight objective runtime state locally.
 *   Subsequent server changes are pushed directly by
 *   FLO_fnc_publishObjectiveRuntimeState.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_ObjectiveRuntimeStateEventsInit" && {FLO_ObjectiveRuntimeStateEventsInit}) exitWith { true };

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_Objectives"
        && {!isNil "FLO_ObjectiveRuntimeState"}
    };

    [FLO_ObjectiveRuntimeState] call FLO_fnc_syncObjectiveRuntimeState;
};

FLO_ObjectiveRuntimeStateEventsInit = true;

true
