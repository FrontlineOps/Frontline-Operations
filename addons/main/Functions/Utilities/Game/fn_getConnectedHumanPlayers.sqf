/* Returns connected human player entities, excluding headless clients. */
params [["_aliveOnly", true, [true]]];

allPlayers select {
    isPlayer _x
    && {!(_x isKindOf "HeadlessClient_F")}
    && {getPlayerUID _x != ""}
    && {!_aliveOnly || {alive _x}}
}
