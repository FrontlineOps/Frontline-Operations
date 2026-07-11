/* Builds a coarse defender-facing approach ellipse for one operation. */
params [
    "_director",
    ["_operationId", "", [""]]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _objectiveId = _operation get "objectiveId";
private _sourceObjectiveIds = _operation get "sourceObjectiveIds";
if (_objectiveId == "" || {_sourceObjectiveIds isEqualTo []}) then {
    throw format ["Operation %1 cannot build a threat sector without target and sources", _operationId];
};

private _target = FLO_Objectives get _objectiveId;
private _targetPosition = _target get "position";
private _sourceCenter = [0, 0, 0];
{
    _sourceCenter = _sourceCenter vectorAdd ((FLO_Objectives get _x) get "position");
} forEach _sourceObjectiveIds;

_sourceCenter = _sourceCenter vectorMultiply (1 / count _sourceObjectiveIds);
private _approachVector = _targetPosition vectorDiff _sourceCenter;
private _approachDistance = _sourceCenter distance2D _targetPosition;
private _sectorPosition = _sourceCenter vectorAdd (_approachVector vectorMultiply 0.65);
private _longAxis = ((_approachDistance * 0.42) max 1500) min 3500;
private _shortAxis = (((_target get "radius") * 2.5) max 900) min 1800;

createHashMapFromArray [
    ["operationId", _operationId],
    ["visible", true],
    ["position", _sectorPosition],
    ["longAxis", _longAxis],
    ["shortAxis", _shortAxis],
    ["direction", _sourceCenter getDir _targetPosition],
    ["grid", mapGridPosition _sectorPosition],
    ["label", "THREATENED APPROACH"]
]
