/*
 * Function: FLO_fnc_sideResourcesCalculateStartingResources
 * Author: Frontline Operations Development Group
 * Description:
 *   Calculates initial side resources from currently owned objectives.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *
 * Return Value:
 *   Starting resources <NUMBER>
 *
 * Example:
 *   private _start = [_resourceObj] call FLO_fnc_sideResourcesCalculateStartingResources;
 */

params ["_resourceObj"];

private _startingValues = _resourceObj get "STARTING_VALUES";
private _ownerSide = _resourceObj get "_side";
private _total = 0;

{
    private _objectiveData = FLO_Objectives get _x;
    if ((_objectiveData get "owner") != _ownerSide) then { continue };

    _total = _total + (_startingValues get (_objectiveData get "subtype"));
} forEach (keys FLO_Objectives);

_total max 150
