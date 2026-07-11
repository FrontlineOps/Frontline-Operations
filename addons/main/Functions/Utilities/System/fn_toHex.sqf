/*
 * Function: FLO_fnc_toHex
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts a non-negative integer to uppercase hexadecimal text.
 *
 * Arguments:
 * 0: Number <NUMBER>
 *
 * Returns:
 * Hex text <STRING>
 */
params ["_num"];

private _hex = "";
private _chars = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];

if (_num == 0) exitWith {"0"};

while {_num > 0} do {
    private _remainder = _num mod 16;
    _hex = (_chars select _remainder) + _hex;
    _num = floor(_num / 16);
};

_hex
