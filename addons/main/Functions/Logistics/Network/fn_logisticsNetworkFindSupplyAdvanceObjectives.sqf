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

if ((_net get "_supplyChainDirty") || {_net get "_objectiveSideIndexDirty"}) then {
    [_net] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
};

private _activeNodes = _net get "_activeSupplyNodes";
if ((keys _activeNodes) isEqualTo []) exitWith { [] };

private _advanceObjectives = [];

{
    private _role = [_net, _x] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if !(_role get "isAdvanceCandidate") then { continue };

    _advanceObjectives pushBack _x;
} forEach (_net get "_managedObjectiveIds");

_advanceObjectives
