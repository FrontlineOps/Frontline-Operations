/*
 * Function: FLO_fnc_sideResourcesSpendResources
 * Author: Frontline Operations Development Group
 * Description:
 *   Spends resources, applies efficiency wear, and republishes the shared
 *   snapshot on success.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Base amount <NUMBER>
 *   2: Spending type <STRING>
 *
 * Return Value:
 *   Success <BOOL>
 *
 * Example:
 *   [_resourceObj, 12, "reinforcement"] call FLO_fnc_sideResourcesSpendResources;
 */

params ["_resourceObj", "_amount", "_type"];

private _costData = [_resourceObj, _amount, _type] call FLO_fnc_sideResourcesCalculateCost;
_costData params ["_cost", "_threshold", "_efficiencyLoss", "_efficiency"];
private _efficiencyFloor = _resourceObj get "EFFICIENCY_FLOOR";
private _efficiencyRecovery = _resourceObj get "EFFICIENCY_RECOVERY";

private _current = _resourceObj get "_resources";
if !(_current isEqualType 0) then {
    throw format ["[SIDE_RES] Invalid resource total before spending %1: %2", _type, _current];
};
if (_current < _threshold) exitWith { false };
if (_current < _cost) exitWith { false };

private _newTotal = _current - _cost;
_resourceObj set ["_resources", _newTotal];
_resourceObj set ["_lastUpdate", time];

private _efficiencies = _resourceObj get "_efficiencies";
private _newEfficiency = (_efficiency - _efficiencyLoss) max _efficiencyFloor;
_efficiencies set [_type, _newEfficiency];

if (_newTotal > (_threshold * 2)) then {
    {
        private _currentEfficiency = _efficiencies get _x;
        _efficiencies set [_x, (_currentEfficiency + _efficiencyRecovery) min 1.0];
    } forEach (keys (_resourceObj get "SPENDING_TYPES"));
};

[] call FLO_fnc_sideResourcesPublishState;

true
