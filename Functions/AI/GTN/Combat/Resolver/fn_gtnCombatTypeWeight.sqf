/*
 * Function: FLO_fnc_gtnCombatTypeWeight
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the combat weighting used for a virtual group type in attrition
 *   calculations.
 *
 * Arguments:
 *   0: Group type <STRING>
 *
 * Return Value:
 *   Type weight <NUMBER>
 */

params ["_groupType"];

switch (_groupType) do {
    case "infantry": { 1.0 };
    case "motorized": { 1.15 };
    case "mechanized": { 1.35 };
    case "armor": { 1.6 };
    case "artillery": { 0.9 };
    case "helicopter": { 1.25 };
    case "jet": { 1.4 };
    case "air": { 1.3 };
    case "mobile_aa": { 1.1 };
    case "static_aa": { 1.05 };
    default { 1.0 };
}
