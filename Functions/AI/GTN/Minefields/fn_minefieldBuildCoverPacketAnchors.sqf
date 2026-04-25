/*
 * Function: FLO_fnc_minefieldBuildCoverPacketAnchors
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a focused set of terrain-cover packet anchors along the hostile
 *   frontage instead of sweeping one huge terrain-object radius.
 *
 * Arguments:
 * 0: Frontline placement context <HASHMAP>
 *
 * Return Value:
 * ARRAY of candidate HASHMAPs
 */

params [
    ["_context", createHashMap]
];

if !(_context isEqualType createHashMap) exitWith { [] };
if ((count (keys _context)) == 0) exitWith { [] };

private _objectiveId = _context get "objectiveId";
private _objectivePos = _context get "objectivePos";
private _objectiveRadius = _context get "objectiveRadius";
private _objectiveArea = _context get "objectiveArea";
private _anchorPos = _context get "anchorPos";
private _facingDir = _context get "facingDir";
private _frontageHalfWidth = _context get "frontageHalfWidth";
private _rowSpacing = _context get "rowSpacing";
private _enemyLinkCount = _context get "enemyLinkCount";
private _edgeBuffer = FLO_MinefieldConfig get "objectiveEdgeBuffer";
private _searchRadius = FLO_MinefieldConfig get "coverPacketSearchRadius";
private _terrainTypes = FLO_MinefieldConfig get "coverPacketTerrainTypes";
private _blockingObjectiveIds = _context get "blockingObjectiveIds";

private _sampleCount = (3 + ((_enemyLinkCount - 1) min 2)) max 3;
if (_frontageHalfWidth >= 95) then {
    _sampleCount = (_sampleCount + 1) min 5;
};

private _sampleOffsets = [];
if (_sampleCount <= 1) then {
    _sampleOffsets pushBack 0;
} else {
    private _usableFrontageHalfWidth = _frontageHalfWidth * 0.7;
    for "_i" from 0 to (_sampleCount - 1) do {
        _sampleOffsets pushBack (linearConversion [0, _sampleCount - 1, _i, -_usableFrontageHalfWidth, _usableFrontageHalfWidth, true]);
    };
};

private _coverCandidates = [];
private _seenPositions = [];

{
    private _samplePos = _anchorPos getPos [
        abs _x,
        _facingDir + (if (_x >= 0) then { 90 } else { 270 })
    ];
    _samplePos = _samplePos getPos [(_rowSpacing * 0.35) max 6, _facingDir];
    _samplePos set [2, 0];

    {
        private _coverPos = getPosATL _x;
        _coverPos set [2, 0];

        if ((_objectivePos distance2D _coverPos) <= (_objectiveRadius + _edgeBuffer)) then { continue };
        if ([_coverPos, _objectiveArea] call FLO_fnc_minefieldIsPositionInsideObjectiveArea) then { continue };
        if (([_coverPos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") then { continue };

        private _duplicate = false;
        {
            if ((_coverPos distance2D _x) < 16) exitWith {
                _duplicate = true;
            };
        } forEach _seenPositions;
        if (_duplicate) then { continue };

        private _dirToCover = [_objectivePos, _coverPos] call BIS_fnc_dirTo;
        private _angleDelta = abs (((_dirToCover - _facingDir + 540) % 360) - 180);
        if (_angleDelta > 85) then { continue };

        private _ringDistance = _objectivePos distance2D _coverPos;
        private _distanceScore = abs (_ringDistance - (_objectiveRadius + (_rowSpacing * 1.2)));
        private _sampleDistance = _samplePos distance2D _coverPos;

        _coverCandidates pushBack (createHashMapFromArray [
            ["pos", _coverPos],
            ["score", (135 - _distanceScore) - (_angleDelta * 0.55) - (_sampleDistance * 0.6)]
        ]);
        _seenPositions pushBack _coverPos;
    } forEach (nearestTerrainObjects [_samplePos, _terrainTypes, _searchRadius, false]);
} forEach _sampleOffsets;

_coverCandidates
