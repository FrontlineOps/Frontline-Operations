/*
 * Function: FLO_fnc_campaignSideFromKey
 * Description:
 *   Resolves a persisted campaign side key to an engine side value.
 */

params [["_sideKey", "", [""]]];

switch (toUpper _sideKey) do {
    case "WEST": { west };
    case "EAST": { east };
    default {
        throw format ["FLO_fnc_campaignSideFromKey: unsupported side key '%1'", _sideKey];
    };
}
