/*
 * Function: FLO_fnc_virtualizationGetSpawnPools
 */

params ["_side"];

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _catalog = FLO_FactionCatalog get _sideKey;

createHashMapFromArray [
    ["sideKey", _sideKey],
    ["catalog", _catalog],
    ["units", _catalog get "groundInfantryUnits"],
    ["groundInfantryGroups", _catalog get "groundInfantryGroups"],
    ["groundInfantryUnits", _catalog get "groundInfantryUnits"],
    ["groundSpecOpsGroups", _catalog get "groundSpecOpsGroups"],
    ["groundSpecOpsUnits", _catalog get "groundSpecOpsUnits"],
    ["groundLight", _catalog get "groundMotorized"],
    ["groundHeavy", _catalog get "groundHeavy"],
    ["groundMotorized", _catalog get "groundMotorized"],
    ["groundMechanized", _catalog get "groundMechanized"],
    ["groundArmor", _catalog get "groundArmor"],
    ["groundTransport", _catalog get "groundTransport"],
    ["groundArtillery", _catalog get "groundArtillery"],
    ["airHeli", _catalog get "airHeli"],
    ["airJet", _catalog get "airJet"],
    ["airTransport", _catalog get "airTransport"],
    ["mobileAA", _catalog get "mobileAA"],
    ["staticAA", _catalog get "staticAA"],
    ["radar", _catalog get "radar"]
]
