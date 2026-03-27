/*
 * Function: FLO_fnc_logisticsNetworkPickPressureTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks the most pressured owned objective from the current battlefield
 *   target set using explicit priority order instead of blended scoring.
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
    ["_batchDispatchCounts", createHashMap]
];

if (count _candidates == 0) exitWith { "" };

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
private _enemyCountKey = if (_managedSide isEqualTo east) then { "bluforCount" } else { "opforCount" };
private _lastTarget = _net get "_lastReinforcementTarget";

private _bestObjectiveId = "";
private _bestPressure = -1;
private _bestPriority = -1e12;
private _bestInbound = 1e12;
private _bestBatch = 1e12;
private _bestRecent = 1e12;
private _bestIsLast = true;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _friendlyCount = _objective get _friendlyCountKey;
    private _enemyCount = _objective get _enemyCountKey;
    private _pressure = ((_enemyCount * 2) - _friendlyCount) max 0;
    private _priority = _objective get "priority";
    private _inboundCount = _inboundCounts getOrDefault [_objectiveId, 0];
    private _batchCount = _batchDispatchCounts getOrDefault [_objectiveId, 0];
    private _recentCount = _recentDispatchCounts getOrDefault [_objectiveId, 0];
    private _isLastTarget = _objectiveId isEqualTo _lastTarget;

    if (
        _pressure > _bestPressure
        || {
            _pressure == _bestPressure
            && {
                _priority > _bestPriority
                || {
                    _priority == _bestPriority
                    && {
                        _inboundCount < _bestInbound
                        || {
                            _inboundCount == _bestInbound
                            && {
                                _batchCount < _bestBatch
                                || {
                                    _batchCount == _bestBatch
                                    && {
                                        _recentCount < _bestRecent
                                        || {
                                            _recentCount == _bestRecent
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
    ) then {
        _bestObjectiveId = _objectiveId;
        _bestPressure = _pressure;
        _bestPriority = _priority;
        _bestInbound = _inboundCount;
        _bestBatch = _batchCount;
        _bestRecent = _recentCount;
        _bestIsLast = _isLastTarget;
    };
} forEach _candidates;

_bestObjectiveId
