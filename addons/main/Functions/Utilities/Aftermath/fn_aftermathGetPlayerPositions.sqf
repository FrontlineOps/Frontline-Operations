/*
 * Function: FLO_fnc_aftermathGetPlayerPositions
 * Description:
 *   Returns positions of living human players that can observe battlefield
 *   evidence. Headless clients are simulation infrastructure, not observers.
 */

([] call FLO_fnc_getConnectedHumanPlayers) apply {
    getPosATL _x
}
