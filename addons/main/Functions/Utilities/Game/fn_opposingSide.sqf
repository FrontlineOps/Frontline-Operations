/*
 * Function: FLO_fnc_opposingSide
 * Description:
 *   Returns the opposing campaign side for EAST/WEST systems.
 */

params [["_side", sideUnknown, [sideUnknown]]];

if !(_side in [east, west]) then {
    throw format ["FLO_fnc_opposingSide: unsupported campaign side %1", _side];
};

[east, west] select (_side isEqualTo east)
