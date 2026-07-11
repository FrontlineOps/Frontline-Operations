/*
 * Function: FLO_fnc_logisticsNetworkApplyObjectiveCaptureGrowth
 * Author: Frontline Operations Development Group
 * Description:
 *   Expands the logistics replacement ceiling after an owned objective is
 *   captured so the side can eventually replenish above its starting size.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Captured objective ID <STRING>
 *
 * Return Value:
 *   Number of new target groups added to the force pool <NUMBER>
 */

params ["_net", ["_objectiveId", ""]];

private _growthCount = _net get "OBJECTIVE_CAPTURE_FORCE_GROWTH";
if (_growthCount <= 0) exitWith { 0 };

private _initialComposition = _net get "_initialComposition";
private _eligibleTypes = [];

{
    private _groupType = _x;
    if (_groupType in ["civilian", "ambient", "static_aa"]) then { continue };

    private _count = _initialComposition get _groupType;
    if (_count <= 0) then { continue };

    _eligibleTypes pushBack _groupType;
} forEach (keys _initialComposition);

if (_eligibleTypes isEqualTo []) exitWith { 0 };

private _appliedGrowth = 0;

for "_i" from 1 to _growthCount do {
    private _totalWeight = 0;
    {
        _totalWeight = _totalWeight + (_initialComposition get _x);
    } forEach _eligibleTypes;

    if (_totalWeight <= 0) exitWith {};

    private _pick = random _totalWeight;
    private _selectedType = _eligibleTypes select -1;
    private _runningWeight = 0;

    {
        _runningWeight = _runningWeight + (_initialComposition get _x);
        if (_pick < _runningWeight) exitWith {
            _selectedType = _x;
        };
    } forEach _eligibleTypes;

    _initialComposition set [_selectedType, (_initialComposition get _selectedType) + 1];
    _appliedGrowth = _appliedGrowth + 1;
};

if (_appliedGrowth <= 0) exitWith { 0 };

_net set ["_initialComposition", _initialComposition];

private _stats = _net get "_stats";
_stats set ["captureGrowthAppliedGroups", (_stats get "captureGrowthAppliedGroups") + _appliedGrowth];
_stats set ["captureGrowthEvents", (_stats get "captureGrowthEvents") + 1];

["LOGISTICS", 3, format [
    "Objective capture growth: %1 gained %2 target groups for %3",
    _net get "_managedSideKey",
    _appliedGrowth,
    _objectiveId
]] call FLO_fnc_log;

_appliedGrowth
