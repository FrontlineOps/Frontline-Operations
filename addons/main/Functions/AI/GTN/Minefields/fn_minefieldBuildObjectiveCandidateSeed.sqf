/*
 * Function: FLO_fnc_minefieldBuildObjectiveCandidateSeed
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the cheap, anchor-free candidate seed for one owned objective.
 *   This lets GTN rank potential minefield sectors without paying the full
 *   anchor-resolution cost for every objective on the frontier.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Side <SIDE>
 * 2: GTN Commander <HASHMAPOBJECT>
 *
 * Return Value:
 * HASHMAP
 */

params [
    ["_objectiveId", ""],
    ["_side", sideUnknown],
    ["_cmdr", nil]
];

if (_objectiveId == "" || {!(_side in [east, west])}) exitWith { createHashMap };
if (isNil "_cmdr") exitWith { createHashMap };

private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") != _side) exitWith { createHashMap };
if ((_cmdr get "_ownSide") != _side) exitWith { createHashMap };

private _enemySide = _cmdr get "_enemySide";
private _sideKey = _cmdr get "_sideKey";
private _config = _cmdr get "_config";
private _worldState = _cmdr get "_worldState";
private _center = _objective get "position";
private _radius = ((_objective get "radius") max 35);
private _linkedObjectives = _objective get "linkedObjectives";
private _subtype = _objective get "subtype";
private _priority = _objective get "priority";
private _enemyCount = _objective get "enemyCount";
private _underAttack = _objective get "underAttack";
private _contested = _objective get "contested";

private _enemyLinkedObjectives = [];
private _enemyLinkedObjectivePositions = [];
private _nearestEnemyDistance = 1e10;
private _primaryEnemyObjectiveId = "";
private _primaryEnemyPos = [];

{
    private _linkedObjective = FLO_Objectives get _x;
    if ((_linkedObjective get "owner") != _enemySide) then { continue };

    private _routeInfo = _worldState call ["_getObjectiveLinkRouteInfo", [_objectiveId, _x]];
    if (_routeInfo get "crossesWater") then { continue };

    _enemyLinkedObjectives pushBack _x;
    private _linkedPos = _linkedObjective get "position";
    _enemyLinkedObjectivePositions pushBack _linkedPos;
    private _linkedDistance = _center distance2D _linkedPos;
    if (_linkedDistance < _nearestEnemyDistance) then {
        _nearestEnemyDistance = _linkedDistance;
        _primaryEnemyObjectiveId = _x;
        _primaryEnemyPos = _linkedPos;
    };
} forEach _linkedObjectives;

if (_enemyLinkedObjectives isEqualTo []) exitWith { createHashMap };
if (_primaryEnemyObjectiveId == "") exitWith { createHashMap };

private _baseFacingDir = [_center, _primaryEnemyPos] call BIS_fnc_dirTo;
private _enemyLinkCount = count _enemyLinkedObjectives;
private _baseFrontageHalfWidth = (
    ((_radius * (FLO_MinefieldConfig get "frontageWidthScale")) max (FLO_MinefieldConfig get "frontageWidthMin"))
    min
    (FLO_MinefieldConfig get "frontageWidthMax")
);
private _frontlineSpreadHalfWidth = 0;
{
    private _distance = _center distance2D _x;
    private _dirToEnemy = [_center, _x] call BIS_fnc_dirTo;
    private _angleDelta = ((_dirToEnemy - _baseFacingDir + 540) % 360) - 180;
    private _lateralSpread = abs ((_distance max 1) * sin _angleDelta);
    if (_lateralSpread > _frontlineSpreadHalfWidth) then {
        _frontlineSpreadHalfWidth = _lateralSpread;
    };
} forEach _enemyLinkedObjectivePositions;

private _frontageHalfWidth = _baseFrontageHalfWidth
    max ((_frontlineSpreadHalfWidth * (FLO_MinefieldConfig get "frontageSpreadScale")) + (FLO_MinefieldConfig get "frontageLinkPadding"))
    max (_baseFrontageHalfWidth + ((_enemyLinkCount - 1) * (FLO_MinefieldConfig get "frontageLinkBonus")));
_frontageHalfWidth = _frontageHalfWidth min (FLO_MinefieldConfig get "frontageWidthMax");

private _rowSpacing = (
    ((_radius * (FLO_MinefieldConfig get "rowSpacingScale")) max (FLO_MinefieldConfig get "rowSpacingMin"))
    min
    (FLO_MinefieldConfig get "rowSpacingMax")
);
private _laneSpacing = (
    ((_rowSpacing * (FLO_MinefieldConfig get "laneSpacingScale")) max (FLO_MinefieldConfig get "laneSpacingMin"))
    min
    (FLO_MinefieldConfig get "laneSpacingMax")
);
private _baseLayerCount = switch (_subtype) do {
    case "capital": { 5 };
    case "city": { 4 };
    case "local": { 4 };
    case "marine": { 4 };
    case "village": { 3 };
    default { 3 };
};
private _extraLayerCount = (floor ((_frontageHalfWidth - _baseFrontageHalfWidth) / (_laneSpacing max 1))) max 0;
_extraLayerCount = _extraLayerCount + ((_enemyLinkCount - 1) min 3);
if (_underAttack) then {
    _extraLayerCount = _extraLayerCount + 1;
};
if (_contested) then {
    _extraLayerCount = _extraLayerCount + 1;
};

private _layerCount = (_baseLayerCount + _extraLayerCount)
    max (FLO_MinefieldConfig get "layerCountMin")
    min (FLO_MinefieldConfig get "layerCountMax");
private _fieldDepth = ((_layerCount - 1) * _rowSpacing) + (_rowSpacing * 1.25);

private _score = _priority;
_score = _score + (_enemyLinkCount * 10);
_score = _score + (_enemyCount * 4);
if (_underAttack) then {
    _score = _score + 40;
};
if (_contested) then {
    _score = _score + 25;
};

private _subtypeScore = switch (_subtype) do {
    case "capital": { 35 };
    case "city": { 25 };
    case "local": { 18 };
    case "marine": { 18 };
    case "village": { 10 };
    default { 12 };
};
_score = _score + _subtypeScore;

private _signatureParts = +_enemyLinkedObjectives;
_signatureParts sort true;

createHashMapFromArray [
    ["objectiveId", _objectiveId],
    ["side", _side],
    ["sideKey", _sideKey],
    ["objectivePos", _center],
    ["objectiveRadius", _radius],
    ["subtype", _subtype],
    ["baseFacingDir", _baseFacingDir],
    ["frontageHalfWidth", _frontageHalfWidth],
    ["enemyLinkCount", _enemyLinkCount],
    ["enemyLinkedObjectives", _enemyLinkedObjectives],
    ["frontlineSpreadHalfWidth", _frontlineSpreadHalfWidth],
    ["rowSpacing", _rowSpacing],
    ["laneSpacing", _laneSpacing],
    ["layerCount", _layerCount],
    ["fieldDepth", _fieldDepth],
    ["allowAT", _subtype in ["capital", "city", "local", "marine"]],
    ["primaryEnemyObjectiveId", _primaryEnemyObjectiveId],
    ["threatSignature", format ["%1|%2|%3", _sideKey, _objectiveId, _signatureParts joinString ","]],
    ["score", _score]
]
