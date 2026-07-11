/*
 * Function: FLO_fnc_factionCompactNumericText
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes whitespace from numeric setup text.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Returns:
 * Compact text <STRING>
 */
params ["_value"];

toString ((toArray _value) select {!(_x in [9, 10, 13, 32])})
