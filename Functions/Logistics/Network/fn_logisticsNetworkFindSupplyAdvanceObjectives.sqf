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

private _activeNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
if ((count (keys _activeNodes)) == 0) exitWith { [] };

private _managedSide = _net get "_managedSide";
private _advanceObjectives = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") isNotEqualTo _managedSide) then { continue };

    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if !(_role get "isAdvanceCandidate") then { continue };

    _advanceObjectives pushBack _objectiveId;
} forEach (keys FLO_Objectives);

_advanceObjectives
