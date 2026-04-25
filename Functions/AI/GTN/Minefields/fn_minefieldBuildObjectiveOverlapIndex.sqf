/*
 * Function: FLO_fnc_minefieldBuildObjectiveOverlapIndex
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a conservative static overlap index so minefield placement only
 *   checks nearby objectives that could realistically intersect a frontage or
 *   layered obstacle field.
 *
 * Arguments: None
 *
 * Return Value:
 * HASHMAP
 */

if (isNil "FLO_Objectives") exitWith { createHashMap };

private _index = createHashMap;
private _objectiveIds = keys FLO_Objectives;
private _maxFrontageHalfWidth = FLO_MinefieldConfig get "frontageWidthMax";
private _maxFieldDepth = (((FLO_MinefieldConfig get "layerCountMax") - 1) * (FLO_MinefieldConfig get "rowSpacingMax")) + ((FLO_MinefieldConfig get "rowSpacingMax") * 1.25);
private _overlapPadding = _maxFrontageHalfWidth + _maxFieldDepth + 25;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _center = _objective get "position";
    private _radius = ((_objective get "radius") max 35);
    private _blockingObjectiveIds = [];

    {
        private _otherObjectiveId = _x;
        if (_otherObjectiveId == _objectiveId) then { continue };

        private _otherObjective = FLO_Objectives get _otherObjectiveId;
        private _otherCenter = _otherObjective get "position";
        private _otherRadius = ((_otherObjective get "radius") max 35);
        private _maxRelevantDistance = _radius + _otherRadius + _overlapPadding;

        if ((_center distance2D _otherCenter) <= _maxRelevantDistance) then {
            _blockingObjectiveIds pushBack _otherObjectiveId;
        };
    } forEach _objectiveIds;

    _index set [_objectiveId, _blockingObjectiveIds];
} forEach _objectiveIds;

_index
