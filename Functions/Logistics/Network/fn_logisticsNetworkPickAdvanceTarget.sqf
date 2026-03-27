/*
 * Function: FLO_fnc_logisticsNetworkPickAdvanceTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks the next quiet chain-extension objective. If the previous target is
 *   still a valid advance objective, keep focusing it to establish the node.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Candidate objective IDs <ARRAY>
 *
 * Return Value:
 *   STRING - Selected objective ID or empty string
 */

params ["_net", "_candidates"];

if (count _candidates == 0) exitWith { "" };

private _lastTarget = _net get "_lastReinforcementTarget";
if (_lastTarget in _candidates) exitWith { _lastTarget };

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };

private _bestObjectiveId = "";
private _bestDepth = -1;
private _bestRouteMeters = -1;
private _bestPriority = -1e12;
private _bestFriendlyCount = 1e12;

{
    private _objectiveId = _x;
    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    private _objective = FLO_Objectives get _objectiveId;
    private _depth = _role get "depth";
    private _routeMeters = _role get "routeMeters";
    private _priority = _objective get "priority";
    private _friendlyCount = _objective get _friendlyCountKey;

    if (
        _depth > _bestDepth
        || {
            _depth == _bestDepth
            && {
                _routeMeters > _bestRouteMeters
                || {
                    _routeMeters == _bestRouteMeters
                    && {
                        _priority > _bestPriority
                        || {_priority == _bestPriority && {_friendlyCount < _bestFriendlyCount}}
                    }
                }
            }
        }
    ) then {
        _bestObjectiveId = _objectiveId;
        _bestDepth = _depth;
        _bestRouteMeters = _routeMeters;
        _bestPriority = _priority;
        _bestFriendlyCount = _friendlyCount;
    };
} forEach _candidates;

_bestObjectiveId
