/*
 * Function: FLO_fnc_sideResourcesAddResources
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds resources to a side resource object and optionally republishes the
 *   lightweight shared snapshot.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Amount <NUMBER>
 *   2: Publish snapshot <BOOL>
 *
 * Return Value:
 *   Updated resource total <NUMBER>
 *
 * Example:
 *   [_resourceObj, 20] call FLO_fnc_sideResourcesAddResources;
 */

params ["_resourceObj", "_amount", ["_publish", true]];

private _newTotal = (_resourceObj get "_resources") + _amount;
_resourceObj set ["_resources", _newTotal];
_resourceObj set ["_lastUpdate", time];

if (_publish) then {
    [] call FLO_fnc_sideResourcesPublishState;
};

_newTotal
