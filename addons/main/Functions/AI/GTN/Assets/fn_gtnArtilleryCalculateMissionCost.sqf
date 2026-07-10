/*
 * Function: FLO_fnc_gtnArtilleryCalculateMissionCost
 * Description:
 *   Calculates the shared treasury and Local Supplies cost of one artillery
 *   mission from its requested round count.
 *
 * Return Value:
 *   [treasuryCost, localSupplyCost]
 */

params [
    ["_manager", nil],
    ["_rounds", 0, [0]]
];

if (isNil "_manager") then {
    throw "Artillery mission cost requires a manager";
};
if (_rounds <= 0) then {
    throw format ["Artillery mission rounds must be positive, got %1", _rounds];
};

private _treasuryCost = ceil (_rounds * FLO_ArtilleryTreasuryCostPerRound);
private _localSupplyCost = ceil (_rounds * FLO_ArtilleryLocalSupplyCostPerRound);

[_treasuryCost, _localSupplyCost]
