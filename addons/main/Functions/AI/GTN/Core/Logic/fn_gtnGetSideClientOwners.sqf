/*
 * Function: FLO_fnc_gtnGetSideClientOwners
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the unique client owner IDs for players currently on one side.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   <ARRAY> of owner IDs
 */

params [["_side", sideUnknown]];

if !(_side in [east, west]) exitWith { [] };

private _owners = [];
{
    if (!isNull _x && {(side group _x) isEqualTo _side}) then {
        _owners pushBackUnique (owner _x);
    };
} forEach ([false] call FLO_fnc_getConnectedHumanPlayers);

_owners
