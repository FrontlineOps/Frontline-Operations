/*
 * Function: FLO_fnc_factionHandleSource
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the required source from a current faction handle.
 *
 * Arguments:
 * 0: Faction handle <HASHMAP>
 *
 * Returns:
 * Source <STRING>
 */
params [["_handle", createHashMap, [createHashMap]]];

private _source = _handle get "source";
if !(_source isEqualType "" && {_source in ["custom", "auto", "auto_multi"]}) then {
    throw format ["Faction handle has invalid source %1", _source];
};

_source
