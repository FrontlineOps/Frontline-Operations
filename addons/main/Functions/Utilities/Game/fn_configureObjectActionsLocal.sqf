/*
 * Function: FLO_fnc_configureObjectActionsLocal
 * Author: Frontline Operations Development Group
 * Description:
 *   Configures one keyed action set on an object locally and removes any
 *   previously installed action IDs for that same key on this client.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Action key <STRING>
 * 2: Action definitions <ARRAY>
 *
 * Return Value:
 * BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_object", objNull, [objNull]],
    ["_actionKey", "", [""]],
    ["_actions", [], [[]]]
];

if (isNull _object || {_actionKey == ""}) exitWith { false };

private _varName = format ["FLO_LocalActionIds_%1", _actionKey];
private _existingActionIds = _object getVariable [_varName, []];
{
    _object removeAction _x;
} forEach _existingActionIds;

private _newActionIds = [];
{
    _newActionIds pushBack (_object addAction _x);
} forEach _actions;

_object setVariable [_varName, _newActionIds];

true
