/*
 * Function: FLO_fnc_logisticsNetworkPickRearTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks a quiet rear fallback objective when neither real pressure nor a
 *   valid chain-extension target exists.
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

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };

private _bestObjectiveId = "";
private _bestActiveNode = true;
private _bestDepth = -1;
private _bestPriority = -1e12;
private _bestFriendlyCount = 1e12;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    private _isActiveNode = _role get "isActiveNode";
    private _depth = _role get "depth";
    private _priority = _objective get "priority";
    private _friendlyCount = _objective get _friendlyCountKey;

    if (
        (!_isActiveNode && {_bestActiveNode})
        || {
            _isActiveNode isEqualTo _bestActiveNode
            && {
                _depth > _bestDepth
                || {
                    _depth == _bestDepth
                    && {
                        _priority > _bestPriority
                        || {_priority == _bestPriority && {_friendlyCount < _bestFriendlyCount}}
                    }
                }
            }
        }
    ) then {
        _bestObjectiveId = _objectiveId;
        _bestActiveNode = _isActiveNode;
        _bestDepth = _depth;
        _bestPriority = _priority;
        _bestFriendlyCount = _friendlyCount;
    };
} forEach _candidates;

_bestObjectiveId
