/*
 * Function: FLO_fnc_logisticsNetworkBuildTargetPicture
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the current maneuver and rear-target picture in one pass over the
 *   managed side's owned objectives so dispatch does not rescan them several
 *   times in the same tick.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Minimum player distance for rear targets <NUMBER> - Default 3000
 *
 * Return Value:
 *   HASHMAP - Target picture
 */

params ["_net", ["_minPlayerDistance", 3000]];

private _managedObjectiveIds = _net get "_managedObjectiveIds";
private _managedSide = _net get "_managedSide";
private _friendlyCountKey = ["bluforCount", "opforCount"] select (_managedSide isEqualTo east);
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
private _collapseRatio = _net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO";
private _players = [] call FLO_fnc_getConnectedHumanPlayers;
private _hasPlayers = _players isNotEqualTo [];

private _pressureTargets = [];
private _rearTargets = [];
private _maneuverTargets = [];
private _collapseTargetCount = 0;
private _frontlinePressureTargetCount = 0;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _objectivePos = _objective get "position";

    private _isRear = true;
    if (_hasPlayers) then {
        {
            if (_x distance2D _objectivePos < _minPlayerDistance) exitWith {
                _isRear = false;
            };
        } forEach _players;
    };

    if (_isRear) then {
        _rearTargets pushBack _objectiveId;
    };

    private _enemyCount = _objective get _enemyCountKey;
    if (_enemyCount > 0) then {
        _pressureTargets pushBack _objectiveId;
        _maneuverTargets pushBack _objectiveId;

        if (_objective get "contested") then {
            private _friendlyCount = _objective get _friendlyCountKey;
            if ((_friendlyCount / _enemyCount) < _collapseRatio) then {
                _collapseTargetCount = _collapseTargetCount + 1;
                continue;
            };
        };

        private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
        if (
            (_role get "isActiveNode")
            || {(_role get "activeLinkedObjectives") isNotEqualTo []}
        ) then {
            _frontlinePressureTargetCount = _frontlinePressureTargetCount + 1;
        };

        continue;
    };

} forEach _managedObjectiveIds;

private _targetPicture = createHashMapFromArray [
    ["pressureTargets", _pressureTargets],
    ["rearTargets", _rearTargets],
    ["maneuverTargets", _maneuverTargets],
    ["collapseTargetCount", _collapseTargetCount],
    ["frontlinePressureTargetCount", _frontlinePressureTargetCount]
];

_net set ["_targetPicture", _targetPicture];

_targetPicture
