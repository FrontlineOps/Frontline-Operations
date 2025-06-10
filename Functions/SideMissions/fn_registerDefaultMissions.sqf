/*
 * Function: FLO_fnc_registerDefaultMissions
 * Author: Frontline Operations Development Group
 * Description:
 *  Registers the default side missions used by the mission.
 * Arguments: None
 * Returns: Nothing
 */

[] call {
    ["pilotRescue", {[] call FLO_fnc_sideMissionPilot}] call FLO_fnc_registerSideMission;
    ["squadRescue", {[] call FLO_fnc_sideMissionSquad}] call FLO_fnc_registerSideMission;
    ["convoyInterdiction", {[] call FLO_fnc_sideMissionConvoy}] call FLO_fnc_registerSideMission;
    ["customConvoy", {[] call FLO_fnc_sideMissionCustomConvoy}] call FLO_fnc_registerSideMission;
    ["patrolSweep", {[] call FLO_fnc_sideMissionPatrol}] call FLO_fnc_registerSideMission;
    ["sabotageTech", {[] call FLO_fnc_sideMissionSabotage}] call FLO_fnc_registerSideMission;
    ["powRescue", {[] call FLO_fnc_sideMissionPOW}] call FLO_fnc_registerSideMission;
    ["intelGather", {[] call FLO_fnc_sideMissionIntel}] call FLO_fnc_registerSideMission;
};
