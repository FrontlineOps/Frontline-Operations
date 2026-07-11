/*
 * Function: FLO_fnc_factionDialogBuildScalarHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a named scalar config handle from a dialog selection and lookup map.
 *
 * Arguments:
 * 0: Selection label <STRING>
 * 1: Value map <HASHMAP>
 *
 * Returns:
 * Config handle <HASHMAP>
 */
params ["_selection", "_map"];

createHashMapFromArray [
    ["value", _map get _selection],
    ["name", _selection]
]
