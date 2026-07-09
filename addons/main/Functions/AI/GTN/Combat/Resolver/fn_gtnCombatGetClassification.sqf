/*
 * Function: FLO_fnc_gtnCombatGetClassification
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the cached virtual combat classification, rebuilding it when the
 *   cache is dirty, the routing geometry changes, or the bounded cache age
 *   expires.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *   1: Seed cell size <NUMBER>
 *   2: Engagement distance <NUMBER>
 *
 * Return Value:
 *   Classification data <HASHMAP>
 */

params ["_groups", ["_seedCellSize", 150, [0]], ["_engagementDist", 300, [0]]];

private _state = call FLO_fnc_gtnCombatGetState;
private _classification = _state get "classification";
private _builtAt = _state get "classificationBuiltAt";
private _minRefreshSec = _state get "classificationMinRefreshSec";
private _ageExpired = _builtAt < 0 || {(diag_tickTime - _builtAt) >= _minRefreshSec};

if (
    (_state get "classificationDirty")
    || {_seedCellSize != (_state get "classificationSeedCellSize")}
    || {_engagementDist != (_state get "classificationEngagementDist")}
    || {_classification isEqualTo []}
    || {_ageExpired}
) then {
    _classification = [_groups, _seedCellSize, _engagementDist] call FLO_fnc_gtnCombatClassifyGroups;
    _state set ["classification", _classification];
    _state set ["classificationDirty", false];
    _state set ["classificationSoftDirty", false];
    _state set ["classificationSeedCellSize", _seedCellSize];
    _state set ["classificationEngagementDist", _engagementDist];
    _state set ["classificationBuiltAt", diag_tickTime];
};

_classification
