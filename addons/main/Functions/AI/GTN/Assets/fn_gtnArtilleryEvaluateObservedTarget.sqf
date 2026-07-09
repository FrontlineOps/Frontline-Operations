/*
 * Function: FLO_fnc_gtnArtilleryEvaluateObservedTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the best artillery target solution currently observed by a real AI
 *   spotter group using knowsAbout-based target knowledge and danger-close
 *   safety checks.
 *
 * Arguments:
 * 0: Artillery Manager <HASHMAP>
 * 1: Spotter Group Data <HASHMAP>
 *
 * Return Value:
 * Array - [] when no safe target exists, otherwise
 *   [targetPos, targetKey, rounds, accuracy, enemyCount, vehicleCount, armorCount]
 *
 * Example:
 * private _solution = [FLO_GTNArtilleryManager, _groupData] call FLO_fnc_gtnArtilleryEvaluateObservedTarget;
 */

params ["_manager", "_spotterData"];

private _realGroup = _spotterData get "realGroup";
if (isNull _realGroup) exitWith { [] };

private _leader = leader _realGroup;
if (isNull _leader || {!alive _leader}) exitWith { [] };

private _requestSide = _spotterData get "side";
if !(_requestSide in [east, west]) exitWith { [] };

private _enemySide = if (_requestSide isEqualTo east) then { west } else { east };
private _senseRadius = _manager get "observedFireSenseRadius";
private _bestSolution = [];
private _bestScore = -1e12;

{
    _x params ["_reportedPos", "_type", "_side", "_cost", "_obj", "_acc"];

    if (_side != _enemySide) then { continue };
    if (isNull _obj || {!alive _obj}) then { continue };

    private _knowledge = _leader knowsAbout _obj;
    if (_knowledge < 1) then { continue };

    private _anchorEntity = vehicle _obj;
    if (!alive _anchorEntity || {_anchorEntity isKindOf "Air"}) then { continue };

    private _enemyGroup = group _obj;
    private _anchorPos = getPosATL _anchorEntity;
    private _sampleEntities = [];
    private _vehicleCount = 0;
    private _armorCount = 0;

    {
        if (!alive _x) then { continue };

        private _entity = vehicle _x;
        if (!alive _entity || {_entity isKindOf "Air"}) then { continue };
        if ((getPosATL _entity) distance2D _anchorPos > 150) then { continue };
        if (_entity in _sampleEntities) then { continue };

        _sampleEntities pushBack _entity;

        if (_entity != _x) then {
            _vehicleCount = _vehicleCount + 1;
        };

        if (
            _entity isKindOf "Tank" ||
            {_entity isKindOf "Tracked_APC_F"} ||
            {_entity isKindOf "Wheeled_APC_F"}
        ) then {
            _armorCount = _armorCount + 1;
        };
    } forEach units _enemyGroup;

    if (_sampleEntities isEqualTo []) then {
        _sampleEntities pushBack _anchorEntity;

        if (_anchorEntity != _obj) then {
            _vehicleCount = 1;
        };

        if (
            _anchorEntity isKindOf "Tank" ||
            {_anchorEntity isKindOf "Tracked_APC_F"} ||
            {_anchorEntity isKindOf "Wheeled_APC_F"}
        ) then {
            _armorCount = 1;
        };
    };

    private _targetPos = [0, 0, 0];
    {
        _targetPos = _targetPos vectorAdd (getPosATL _x);
    } forEach _sampleEntities;
    _targetPos = _targetPos vectorMultiply (1 / count _sampleEntities);

    private _dangerCloseRadius = _manager get "observedFireDangerCloseRadius";
    if (_vehicleCount > 0) then {
        _dangerCloseRadius = _dangerCloseRadius + 25;
    };

    if !(_manager call ["_isObservedImpactSafe", [_targetPos, _requestSide, _dangerCloseRadius]]) then {
        continue;
    };

    private _targetKey = _manager call ["_buildObservedTargetKey", [_requestSide, _enemyGroup, _targetPos]];
    if (_manager call ["_isObservedTargetOnCooldown", [_targetKey]]) then { continue };

    private _enemyCount = count _sampleEntities;
    private _rounds = 4;
    if (_enemyCount >= 3) then { _rounds = 6; };
    if (_enemyCount >= 6 || {_armorCount > 0}) then { _rounds = 8; };

    private _accuracy = 100;
    if (_vehicleCount > 0) then { _accuracy = 70; };
    if (_armorCount > 0) then { _accuracy = 55; };

    private _dist = _leader distance2D _targetPos;
    private _score = (_knowledge * 200)
        + (_cost * 25)
        + (_enemyCount * 15)
        + (_vehicleCount * 40)
        + (_armorCount * 80)
        - (_dist * 0.08);

    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestSolution = [_targetPos, _targetKey, _rounds, _accuracy, _enemyCount, _vehicleCount, _armorCount];
    };
} forEach (_leader nearTargets _senseRadius);

_bestSolution
