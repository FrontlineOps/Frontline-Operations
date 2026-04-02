/*
 * Function: FLO_fnc_logisticsNetworkFindSupplyAdvanceObjectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds owned objectives that sit one hop beyond the currently active
 *   supply chain and are therefore valid next-step supply-node targets.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   ARRAY - Objective IDs
 */

params ["_net"];

private _activeNodes = _net get "_activeSupplyNodes";
if ((count (keys _activeNodes)) == 0) exitWith { [] };

private _advanceObjectives = [];

{
    private _role = [_net, _x] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if !(_role get "isAdvanceCandidate") then { continue };

    _advanceObjectives pushBack _x;
} forEach (_net get "_managedObjectiveIds");

_advanceObjectives
