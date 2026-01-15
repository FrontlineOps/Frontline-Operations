/*
 * Function: FLO_fnc_militaryIntel
 * Author: Frontline Operations Development Group
 * Description:
 *  Handles military intelligence events. This version delegates the
 *  actual mission logic to the new side mission framework.
 * Arguments: None
 * Returns: Nothing
 * Usage: [] call FLO_fnc_militaryIntel;
 */

params [];

sleep 2;

private _missions = [
    "pilotRescue",
    "squadRescue",
    "convoyInterdiction",
    "customConvoy",
    "patrolSweep",
    "sabotageTech",
    "powRescue",
    "intelGather"
];

private _pick = selectRandom _missions;
[_pick] call FLO_fnc_startSideMission;
