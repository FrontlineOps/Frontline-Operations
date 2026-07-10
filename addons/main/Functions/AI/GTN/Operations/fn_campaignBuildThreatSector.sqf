/*
 * Function: FLO_fnc_campaignBuildThreatSector
 * Description:
 *   Builds a coarse defender-facing approach ellipse from the operation's
 *   integrated attack sources without exposing the exact target.
 */

params ["_director"];

private _state = _director get "_state";
private _objectiveId = _state get "objectiveId";
private _sourceObjectiveIds = _state get "sourceObjectiveIds";

if (_objectiveId == "") then {
    throw "FLO_fnc_campaignBuildThreatSector: active operation has no objective";
};
if (_sourceObjectiveIds isEqualTo []) then {
    throw "FLO_fnc_campaignBuildThreatSector: active operation has no attack sources";
};

private _target = FLO_Objectives get _objectiveId;
private _targetPosition = _target get "position";
private _sourceCenter = [0, 0, 0];

{
    private _source = FLO_Objectives get _x;
    _sourceCenter = _sourceCenter vectorAdd (_source get "position");
} forEach _sourceObjectiveIds;

_sourceCenter = _sourceCenter vectorMultiply (1 / count _sourceObjectiveIds);
private _approachVector = _targetPosition vectorDiff _sourceCenter;
private _approachDistance = _sourceCenter distance2D _targetPosition;
private _sectorPosition = _sourceCenter vectorAdd (_approachVector vectorMultiply 0.65);
private _longAxis = ((_approachDistance * 0.42) max 1500) min 3500;
private _shortAxis = (((_target get "radius") * 2.5) max 900) min 1800;

createHashMapFromArray [
    ["visible", true],
    ["position", _sectorPosition],
    ["longAxis", _longAxis],
    ["shortAxis", _shortAxis],
    ["direction", _sourceCenter getDir _targetPosition],
    ["grid", mapGridPosition _sectorPosition],
    ["label", "THREATENED APPROACH"]
]
