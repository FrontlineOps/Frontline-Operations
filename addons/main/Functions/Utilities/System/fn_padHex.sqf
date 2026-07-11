/*
 * Function: FLO_fnc_padHex
 * Author: Frontline Operations Development Group
 * Description:
 *   Left-pads hexadecimal text with zeros to a target length.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Target length <NUMBER>
 *
 * Returns:
 * Padded text <STRING>
 */
params ["_str", "_length"];

while {count _str < _length} do {
    _str = "0" + _str;
};

_str
