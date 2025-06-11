/*
 * Function: FLO_fnc_registerSideMission
 * Author: Frontline Operations Development Group
 * Description:
 *  Registers a side mission so it can be started by name.
 *  Missions are stored in the global hash map FLO_registeredSideMissions.
 * Arguments:
 * 0: Mission name (STRING) - unique identifier
 * 1: Mission function (CODE) - code executed when mission starts
 * 2: Optional mission data (ANY)
 * Returns: Nothing
 */

params ["_name", "_fnc", ["_data", []]];

if (isNil "FLO_registeredSideMissions") then {
    FLO_registeredSideMissions = createHashMap;
};

FLO_registeredSideMissions set [_name, [_fnc, _data]];
