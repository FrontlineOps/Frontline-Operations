/*
 * Function: FLO_fnc_gtnBuildAttackReachability
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds an attack reachability map for enemy objectives using shallow
 *   land-connected graph expansion from the target objective back toward
 *   friendly-held source objectives. This lets sparse objective graphs expose
 *   a usable extended frontline without turning GTN into a pure distance scan.
 *
 * Arguments:
 * 0: GTN commander <HASHMAP>
 *
 * Return Value:
 * HASHMAP - objectiveId -> HASHMAP with:
 *   "sourceObjectives" <ARRAY>
 *   "enemyDepth" <NUMBER>
 *   "routeMeters" <NUMBER>
 */

params ["_cmdr"];

private _reachability = createHashMap;
if (isNil "_cmdr") exitWith { _reachability };

private _ws = _cmdr get "_worldState";
private _cfg = _cmdr get "_config";
private _objectives = _ws call ["_getObjectives", []];
private _enemyObjectives = _ws call ["_getEnemyObjectives", []];
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _maxEnemyDepth = (_cfg get "attackExtendedFrontlineEnemyDepth") max 0;
private _maxRouteMeters = (_cfg get "attackExtendedFrontlineMaxRouteMeters") max 0;

{
    private _objectiveId = _x;
    private _sourceObjectives = [];
    private _bestEnemyDepth = 1e12;
    private _bestRouteMeters = 1e12;
    private _visited = createHashMapFromArray [[_objectiveId, 0]];
    private _frontier = [[_objectiveId, 0, 0]];

    while {count _frontier > 0} do {
        private _frontierEntry = _frontier deleteAt 0;
        _frontierEntry params ["_currentObjectiveId", "_enemyDepth", "_routeMeters"];

        private _currentObjective = _objectives get _currentObjectiveId;
        {
            private _linkedObjectiveId = _x;
            if !(_linkedObjectiveId in _objectives) then { continue };

            private _routeInfo = _ws call ["_getObjectiveLinkRouteInfo", [_currentObjectiveId, _linkedObjectiveId]];
            if (_routeInfo get "crossesWater") then { continue };

            private _newRouteMeters = _routeMeters + (_routeInfo get "distance");
            if (_newRouteMeters > _maxRouteMeters) then { continue };

            private _linkedObjective = _objectives get _linkedObjectiveId;
            private _linkedOwner = _linkedObjective get "owner";

            if (_linkedOwner isEqualTo _ownSide) then {
                _sourceObjectives pushBackUnique _linkedObjectiveId;
                if (_enemyDepth < _bestEnemyDepth || {_enemyDepth == _bestEnemyDepth && {_newRouteMeters < _bestRouteMeters}}) then {
                    _bestEnemyDepth = _enemyDepth;
                    _bestRouteMeters = _newRouteMeters;
                };
                continue;
            };

            if !(_linkedOwner isEqualTo _enemySide) then { continue };

            private _newEnemyDepth = _enemyDepth + 1;
            if (_newEnemyDepth > _maxEnemyDepth) then { continue };

            private _bestSeenRoute = _visited getOrDefault [_linkedObjectiveId, 1e12];
            if (_newRouteMeters >= _bestSeenRoute) then { continue };

            _visited set [_linkedObjectiveId, _newRouteMeters];
            _frontier pushBack [_linkedObjectiveId, _newEnemyDepth, _newRouteMeters];
        } forEach (_currentObjective get "linkedObjectives");
    };

    if (count _sourceObjectives > 0) then {
        _reachability set [_objectiveId, createHashMapFromArray [
            ["sourceObjectives", _sourceObjectives],
            ["enemyDepth", _bestEnemyDepth],
            ["routeMeters", _bestRouteMeters]
        ]];
    };
} forEach (keys _enemyObjectives);

_reachability
