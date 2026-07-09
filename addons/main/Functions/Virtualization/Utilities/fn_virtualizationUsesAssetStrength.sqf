/*
 * Function: FLO_fnc_virtualizationUsesAssetStrength
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a virtual group type should derive its virtual strength
 *   from surviving vehicle assets instead of surviving crew.
 *
 * Arguments:
 * 0: Group Type <STRING>
 *
 * Return Value:
 * Boolean - True when the group's strength is asset-based
 */

params ["_groupType"];

_groupType in [
    "motorized",
    "mechanized",
    "armor",
    "helicopter",
    "jet",
    "air",
    "artillery",
    "mobile_aa",
    "static_aa",
    "civilianVehicle",
    "civ_car"
]
