/*
 * Function: FLO_fnc_initMissionConfigEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers the client-side publicVariable event handler that applies the
 *   bundled mission configuration locally.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_MissionConfigEventsInit" && {FLO_MissionConfigEventsInit}) exitWith { true };

"FLO_MissionConfig" addPublicVariableEventHandler {
    params ["_variableName", "_config"];

    if (_config isEqualType createHashMap && {count (keys _config) > 0} && {"friendlyHandle" in _config}) then {
        [] call FLO_fnc_applyMissionConfigLocally;
    };
};

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_MissionConfig"
    };

    if (count (keys FLO_MissionConfig) > 0 && {"friendlyHandle" in FLO_MissionConfig}) then {
        [] call FLO_fnc_applyMissionConfigLocally;
    };
};

FLO_MissionConfigEventsInit = true;

true
