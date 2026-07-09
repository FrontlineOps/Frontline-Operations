/*
 * Function: FLO_fnc_initMissionConfigEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the bundled mission configuration locally once the server has
 *   published a complete setup payload.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_MissionConfigEventsInit" && {FLO_MissionConfigEventsInit}) exitWith { true };

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_MissionConfig"
        && {FLO_MissionConfig isEqualType createHashMap}
        && {(keys FLO_MissionConfig) isNotEqualTo []}
        && {"friendlyHandle" in FLO_MissionConfig}
    };

    [] call FLO_fnc_applyMissionConfigLocally;
};

FLO_MissionConfigEventsInit = true;

true
