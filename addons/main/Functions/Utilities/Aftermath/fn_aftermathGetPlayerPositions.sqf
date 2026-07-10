/*
 * Function: FLO_fnc_aftermathGetPlayerPositions
 * Description:
 *   Returns positions of living human players that can observe battlefield
 *   evidence. Headless clients are simulation infrastructure, not observers.
 */

(allPlayers select {
    alive _x && {!(_x isKindOf "HeadlessClient_F")}
}) apply {
    getPosATL _x
}
