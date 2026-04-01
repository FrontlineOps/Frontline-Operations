/*
 * Function: FLO_fnc_logisticsNetworkPickAdvanceTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks the next quiet chain-extension objective while avoiding repeated
 *   fixation on the same branch when other forward-extension candidates exist.
 *   A branch needs a meaningful depth lead before raw depth overrides branch
 *   balancing, so one sector cannot snowball because it got one hop ahead.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Candidate objective IDs <ARRAY>
 *   2: Inbound requested-objective counts <HASHMAP> - Default empty map
 *   3: Recent dispatch counts <HASHMAP> - Default empty map
 *   4: Batch requested-objective counts <HASHMAP> - Default empty map
 *
 * Return Value:
 *   STRING - Selected objective ID or empty string
 */

params [
    "_net",
    "_candidates",
    ["_inboundCounts", createHashMap],
    ["_recentDispatchCounts", createHashMap],
    ["_batchDispatchCounts", createHashMap],
    ["_branchInboundCounts", createHashMap],
    ["_branchRecentCounts", createHashMap],
    ["_branchBatchCounts", createHashMap]
];

if (count _candidates == 0) exitWith { "" };

private _lastTarget = _net get "_lastReinforcementTarget";
private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };

private _bestObjectiveId = "";
private _bestDepth = -1;
private _bestDepthBand = -1;
private _bestBranchRecent = 1e12;
private _bestBranchInbound = 1e12;
private _bestBranchBatch = 1e12;
private _bestRecent = 1e12;
private _bestInbound = 1e12;
private _bestBatch = 1e12;
private _bestDeliveryCount = 1e12;
private _bestRouteMeters = -1;
private _bestPriority = -1e12;
private _bestFriendlyCount = 1e12;
private _bestIsLast = true;

{
    private _objectiveId = _x;
    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    private _objective = FLO_Objectives get _objectiveId;
    private _branchObjectiveId = [_net, _objectiveId] call FLO_fnc_logisticsNetworkGetObjectiveSupplyBranch;
    private _depth = _role get "depth";
    private _depthBand = floor (_depth / 2);
    private _branchRecentCount = _branchRecentCounts getOrDefault [_branchObjectiveId, 0];
    private _branchInboundCount = _branchInboundCounts getOrDefault [_branchObjectiveId, 0];
    private _branchBatchCount = _branchBatchCounts getOrDefault [_branchObjectiveId, 0];
    private _recentCount = _recentDispatchCounts getOrDefault [_objectiveId, 0];
    private _inboundCount = _inboundCounts getOrDefault [_objectiveId, 0];
    private _batchCount = _batchDispatchCounts getOrDefault [_objectiveId, 0];
    private _deliveryCount = _role get "deliveryCount";
    private _routeMeters = _role get "routeMeters";
    private _priority = _objective get "priority";
    private _friendlyCount = _objective get _friendlyCountKey;
    private _isLastTarget = _objectiveId isEqualTo _lastTarget;

    if (
        _depthBand > _bestDepthBand
        || {
        _depthBand == _bestDepthBand
        && {
            _branchRecentCount < _bestBranchRecent
            || {
                _branchRecentCount == _bestBranchRecent
                && {
                    _branchInboundCount < _bestBranchInbound
                    || {
                        _branchInboundCount == _bestBranchInbound
                        && {
                            _branchBatchCount < _bestBranchBatch
                            || {
                                _branchBatchCount == _bestBranchBatch
                                && {
                                    _recentCount < _bestRecent
                                    || {
                                        _recentCount == _bestRecent
                                        && {
                                            _depth > _bestDepth
                                            || {
                                                _depth == _bestDepth
                                                && {
                                                    _inboundCount < _bestInbound
                                                    || {
                                                        _inboundCount == _bestInbound
                                                        && {
                                                            _batchCount < _bestBatch
                                                            || {
                                                                _batchCount == _bestBatch
                                                                && {
                                                                    _deliveryCount < _bestDeliveryCount
                                                                    || {
                                                                        _deliveryCount == _bestDeliveryCount
                                                                        && {
                                                                            _routeMeters > _bestRouteMeters
                                                                            || {
                                                                                _routeMeters == _bestRouteMeters
                                                                                && {
                                                                                    _priority > _bestPriority
                                                                                    || {
                                                                                        _priority == _bestPriority
                                                                                        && {
                                                                                            _friendlyCount < _bestFriendlyCount
                                                                                            || {
                                                                                                _friendlyCount == _bestFriendlyCount
                                                                                                && {!_isLastTarget && {_bestIsLast}}
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    ) then {
        _bestObjectiveId = _objectiveId;
        _bestDepth = _depth;
        _bestDepthBand = _depthBand;
        _bestBranchRecent = _branchRecentCount;
        _bestBranchInbound = _branchInboundCount;
        _bestBranchBatch = _branchBatchCount;
        _bestRecent = _recentCount;
        _bestInbound = _inboundCount;
        _bestBatch = _batchCount;
        _bestDeliveryCount = _deliveryCount;
        _bestRouteMeters = _routeMeters;
        _bestPriority = _priority;
        _bestFriendlyCount = _friendlyCount;
        _bestIsLast = _isLastTarget;
    };
} forEach _candidates;

_bestObjectiveId
