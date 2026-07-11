/*
 * Function: FLO_fnc_gtnCombatCleanupResumeStates
 * Author: Frontline Operations Development Group
 * Description:
 *   Drops saved post-combat resume states for groups that no longer exist.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *   1: Resume states map <HASHMAP>
 *
 * Return Value:
 *   None
 */

params ["_groups", "_resumeStates"];

{
    if (isNil { _groups get _x }) then {
        _resumeStates deleteAt _x;
    };
} forEach (keys _resumeStates);
