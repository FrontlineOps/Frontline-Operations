/* Builds deterministic source-facing entry and assault routes for one wave. */
params [
    "_director",
    ["_objectiveId", "", [""]],
    "_objective",
    ["_approachSourcePos", [], [[]]],
    ["_groupIds", [], [[]]],
    "_groups"
];

if (_groupIds isEqualTo []) exitWith { createHashMap };
if (count _approachSourcePos < 2) then {
    throw "Assault approach lanes require a source-front anchor";
};

private _objectiveCenter = +(_objective get "position");
private _targetPos = [_objectiveId, _objective] call FLO_fnc_campaignResolveAssaultLandAnchor;
if (_targetPos isEqualTo []) then {
    ["CAMPAIGN", 1, format [
        "Assault lane construction received objective %1 without a valid land anchor",
        _objectiveId
    ]] call FLO_fnc_log;
    throw format ["No ground-assault anchor for objective %1", _objectiveId];
};
private _targetRadius = _objective get "radius";
if (_targetRadius <= 0) then {
    throw format ["Assault approach lanes require a positive objective radius at %1", _targetPos];
};
if ((_approachSourcePos distance2D _targetPos) < 1) then {
    throw format ["Assault approach source overlaps target at %1", _targetPos];
};

private _config = _director get "_config";
private _laneCount = ((_config get "assaultApproachLaneCount") min (count _groupIds)) max 1;
private _laneSpacing = (_config get "assaultApproachLaneSpacingMeters") min (_targetRadius * 0.25);
private _rankSpacing = (_config get "assaultApproachRankSpacingMeters") min (_targetRadius * 0.12);
private _entryDepth = _targetRadius * (_config get "assaultApproachEntryDepthFraction");
private _assaultDepth = _targetRadius * (_config get "assaultApproachAssaultDepthFraction");
if (_entryDepth <= _assaultDepth) then {
    throw format ["Assault approach depth is inverted: entry=%1 assault=%2", _entryDepth, _assaultDepth];
};

private _approachDirection = _approachSourcePos getDir _targetPos;
private _sourceDirection = _targetPos getDir _approachSourcePos;
private _forwardVector = [sin _approachDirection, cos _approachDirection, 0];
private _rightVector = [cos _approachDirection, -(sin _approachDirection), 0];
private _entryBase = _targetPos getPos [_entryDepth - _assaultDepth, _sourceDirection];
private _assaultBase = +_targetPos;

private _rankedGroups = _groupIds apply {
    private _groupData = _groups get _x;
    private _groupPos = _groupData get "position";
    private _sourceOffset = _groupPos vectorDiff _approachSourcePos;
    [_sourceOffset vectorDotProduct _rightVector, _groupPos distance2D _targetPos, _x]
};
_rankedGroups sort true;

private _lanes = [];
for "_laneIndex" from 0 to (_laneCount - 1) do {
    _lanes pushBack [];
};
{
    private _laneIndex = floor ((_forEachIndex * _laneCount) / (count _rankedGroups));
    private _lane = _lanes select _laneIndex;
    _lane pushBack [_x select 1, _x select 2];
    _lanes set [_laneIndex, _lane];
} forEach _rankedGroups;

private _routes = createHashMap;
private _landSearchRadius = _targetRadius;
private _correctedEntryCount = 0;
private _compressedAssaultCount = 0;
{
    private _lane = _x;
    _lane sort true;
    private _lateralOffset = (_forEachIndex - ((_laneCount - 1) * 0.5)) * _laneSpacing;
    private _lateralVector = _rightVector vectorMultiply _lateralOffset;
    private _laneSize = count _lane;

    {
        private _groupId = _x select 1;
        private _forwardOffset = (((_laneSize - 1) * 0.5) - _forEachIndex) * _rankSpacing;
        private _rankVector = _forwardVector vectorMultiply _forwardOffset;
        private _entryPos = (_entryBase vectorAdd _lateralVector) vectorAdd _rankVector;
        private _assaultPos = (_assaultBase vectorAdd _lateralVector) vectorAdd _rankVector;
        _entryPos set [2, 0];
        _assaultPos set [2, 0];

        if (surfaceIsWater _entryPos) then {
            _entryPos = [_entryPos, _landSearchRadius] call FLO_fnc_getSafeLandPos;
            _correctedEntryCount = _correctedEntryCount + 1;
        };
        if (surfaceIsWater _entryPos) then {
            _entryPos = +_targetPos;
        };
        if (surfaceIsWater _assaultPos || {(_assaultPos distance2D _objectiveCenter) > _targetRadius}) then {
            _assaultPos = +_targetPos;
            _compressedAssaultCount = _compressedAssaultCount + 1;
        };

        _routes set [_groupId, [_entryPos, _assaultPos]];
    } forEach _lane;
} forEach _lanes;

["CAMPAIGN", 3, format [
    "Assault lanes built objective=%1 groups=%2 lanes=%3 anchorOffset=%4m correctedEntries=%5 compressedAssaults=%6",
    _objectiveId,
    count _groupIds,
    _laneCount,
    round (_targetPos distance2D _objectiveCenter),
    _correctedEntryCount,
    _compressedAssaultCount
]] call FLO_fnc_log;

_routes
