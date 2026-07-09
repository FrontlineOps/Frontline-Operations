/*
 * Function: FLO_fnc_gtnBuildFriendlyObjectiveOwnershipSignature
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Builds a compact signature for the set of objectives currently owned by one
 *   side. Attack source-objective and reserve-band caches only depend on this
 *   ownership graph, so they should not be invalidated by unrelated combat
 *   pressure changes.
 *
 * Arguments:
 * 0: Objective state map <HASHMAP>
 * 1: Own side <SIDE>
 *
 * Return Value:
 * Signature <STRING>
 */

params ["_objectives", "_ownSide"];

private _friendlyObjectiveIds = [];
{
    private _objective = _objectives get _x;
    if ((_objective get "owner") != _ownSide) then { continue };
    _friendlyObjectiveIds pushBack _x;
} forEach (keys _objectives);

_friendlyObjectiveIds sort true;

format ["%1|%2", count _friendlyObjectiveIds, _friendlyObjectiveIds joinString ","]
