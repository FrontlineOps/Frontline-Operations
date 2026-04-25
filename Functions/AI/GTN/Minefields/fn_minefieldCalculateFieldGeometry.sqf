/*
 * Function: FLO_fnc_minefieldCalculateFieldGeometry
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the outward field-center and geometry for one tracked minefield
 *   from its anchor, facing, and live/planned mine positions.
 *
 * Arguments:
 * 0: Anchor position <ARRAY>
 * 1: Facing direction <SCALAR>
 * 2: Mine positions <ARRAY>
 *
 * Return Value:
 * HASHMAP
 */

params [
    ["_anchorPos", [0, 0, 0]],
    ["_facingDir", 0],
    ["_minePositions", []]
];

if ((count _anchorPos) < 2) exitWith { createHashMap };
if ((count _minePositions) == 0) exitWith { createHashMap };

private _maxForwardDepth = 0;
private _maxLateralSpread = 0;
{
    if ((count _x) < 2) then { continue };

    private _distance = _anchorPos distance2D _x;
    private _dirToPos = [_anchorPos, _x] call BIS_fnc_dirTo;
    private _angleDelta = ((_dirToPos - _facingDir + 540) % 360) - 180;
    private _forwardDepth = (_distance * cos _angleDelta) max 0;
    private _lateralSpread = abs (_distance * sin _angleDelta);
    if (_forwardDepth > _maxForwardDepth) then {
        _maxForwardDepth = _forwardDepth;
    };
    if (_lateralSpread > _maxLateralSpread) then {
        _maxLateralSpread = _lateralSpread;
    };
} forEach _minePositions;

private _depthPadding = ((FLO_MinefieldConfig get "rowSpacingMin") * 0.75) max 8;
private _frontagePadding = ((FLO_MinefieldConfig get "laneSpacingMin") * 0.75) max 8;
private _maxDepth = _maxForwardDepth + _depthPadding;
private _depthHalfWidth = (_maxDepth * 0.5) max ((FLO_MinefieldConfig get "rowSpacingMin") * 0.75);
private _frontageHalfWidth = (_maxLateralSpread + _frontagePadding) max ((FLO_MinefieldConfig get "laneSpacingMin") * 0.75);
private _fieldCenterPos = _anchorPos getPos [_depthHalfWidth, _facingDir];
_fieldCenterPos set [2, 0];

createHashMapFromArray [
    ["fieldCenterPos", _fieldCenterPos],
    ["depthHalfWidth", _depthHalfWidth],
    ["frontageHalfWidth", _frontageHalfWidth],
    ["maxDepth", _maxDepth]
]
