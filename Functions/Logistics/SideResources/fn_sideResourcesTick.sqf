/*
 * Function: FLO_fnc_sideResourcesTick
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes one full side-resource generation update across all managed sides.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Success <BOOL>
 *
 * Example:
 *   [] call FLO_fnc_sideResourcesTick;
 */

if (isNil "FLO_SideResources") exitWith { false };
if (isNil "FLO_Objectives") exitWith { false };

private _objectiveIds = keys FLO_Objectives;
if (count _objectiveIds == 0) exitWith { false };

private _t0 = diag_tickTime;
private _stateChanged = false;

{
    private _resourceObj = FLO_SideResources get _x;
    private _side = _resourceObj get "_side";
    private _generated = 0;
    private _ownedCount = 0;
    private _defendedCount = 0;
    private _contestedCount = 0;
    private _overrunCount = 0;

    {
        private _objectiveData = FLO_Objectives get _x;
        if ((_objectiveData get "owner") != _side) then { continue };

        _ownedCount = _ownedCount + 1;

        private _incomeData = [_resourceObj, _objectiveData] call FLO_fnc_sideResourcesCalculateObjectiveIncome;
        _incomeData params ["_income", "_status"];

        _generated = _generated + _income;

        switch (_status) do {
            case "DEFENDED": { _defendedCount = _defendedCount + 1; };
            case "CONTESTED": { _contestedCount = _contestedCount + 1; };
            case "OVERRUN": { _overrunCount = _overrunCount + 1; };
        };
    } forEach _objectiveIds;

    private _roundedIncome = round _generated;
    if (_roundedIncome > 0) then {
        [_resourceObj, _roundedIncome, false] call FLO_fnc_sideResourcesAddResources;
        _stateChanged = true;
    };

    ["SIDE_RES", 3, format [
        "%1 gen +%2 from %3 objectives (defended %4, contested %5, overrun %6) | Total %7",
        _resourceObj get "_sideKey",
        _roundedIncome,
        _ownedCount,
        _defendedCount,
        _contestedCount,
        _overrunCount,
        _resourceObj get "_resources"
    ]] call FLO_fnc_log;
} forEach (keys FLO_SideResources);

if (_stateChanged) then {
    [] call FLO_fnc_sideResourcesPublishState;
};

private _dt = diag_tickTime - _t0;
if (_dt > 0.01) then {
    diag_log format [
        "[FLO][PERF] Side resource tick processed %1 objectives in %2 ms",
        count _objectiveIds,
        _dt * 1000
    ];
};

true
