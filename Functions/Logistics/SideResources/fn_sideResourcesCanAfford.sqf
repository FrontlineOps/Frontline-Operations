/*
 * Function: FLO_fnc_sideResourcesCanAfford
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether the side resource object can afford a spending request.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Base amount <NUMBER>
 *   2: Spending type <STRING>
 *
 * Return Value:
 *   Can afford <BOOL>
 *
 * Example:
 *   [_resourceObj, 12, "reinforcement"] call FLO_fnc_sideResourcesCanAfford;
 */

params ["_resourceObj", "_amount", "_type"];

private _costData = [_resourceObj, _amount, _type] call FLO_fnc_sideResourcesCalculateCost;
_costData params ["_cost", "_threshold"];

private _current = _resourceObj get "_resources";
if (_current < _threshold) exitWith { false };

_current >= _cost
