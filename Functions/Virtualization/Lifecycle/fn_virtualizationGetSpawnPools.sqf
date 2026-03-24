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
    ["units", _catalog get "units"],
    ["groundLight", _catalog get "groundLight"],
    ["groundHeavy", _catalog get "groundHeavy"],
    ["groundArtillery", _catalog get "groundArtillery"],
    ["airHeli", _catalog get "airHeli"],
    ["airJet", _catalog get "airJet"],
    ["mobileAA", _catalog get "mobileAA"],
    ["staticAA", _catalog get "staticAA"],
    ["radar", _catalog get "radar"]
]
