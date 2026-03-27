/*
 * Function: FLO_fnc_virtualizationNormalizePosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Canonicalizes a position into the virtualization 3D array form.
 *   Accepts either 2D or 3D position arrays.
 *
 * Arguments:
 *   0: Position <ARRAY>
 *
 * Return Value:
 *   ARRAY - Normalized 3D position
 */

params [["_position", [], [[]]]];

if ((count _position) < 2) exitWith { _position };
if ((count _position) >= 3) exitWith { _position };

[
    _position select 0,
    _position select 1,
    0
]
