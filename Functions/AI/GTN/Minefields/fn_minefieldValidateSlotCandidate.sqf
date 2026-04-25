/*
 * Function: FLO_fnc_minefieldValidateSlotCandidate
 * Author: Frontline Operations Development Group
 * Description:
 *   Validates one candidate mine slot position against water and objective
 *   overlap rules and returns the adjusted accepted position when valid.
 *
 * Arguments:
 * 0: Placement context <HASHMAP>
 * 1: Candidate position <ARRAY>
 *
 * Return Value:
 * ARRAY - [<STRING reason>, <ARRAY adjustedPos>]
 */

params [
    ["_context", createHashMap],
    ["_candidatePos", [0, 0, 0]]
];

if !(_context isEqualType createHashMap) exitWith { ["invalid", []] };
if ((count _candidatePos) < 2) exitWith { ["invalid", []] };

private _center = _context get "objectivePos";
private _radius = _context get "objectiveRadius";
private _facingDir = _context get "facingDir";
private _objectiveArea = _context get "objectiveArea";
private _edgeBuffer = FLO_MinefieldConfig get "objectiveEdgeBuffer";
private _ignoredObjectiveIds = [_context get "objectiveId"];
private _blockingObjectiveIds = _context get "blockingObjectiveIds";
private _pos = +_candidatePos;
_pos set [2, 0];

if (surfaceIsWater _pos) exitWith { ["water", []] };

if ((_pos distance2D _center) < (_radius + _edgeBuffer)) then {
    private _pushDistance = (_radius + _edgeBuffer) - (_pos distance2D _center);
    _pos = _pos getPos [_pushDistance, _facingDir];
    _pos set [2, 0];
};

if (surfaceIsWater _pos) exitWith { ["water", []] };
if ([_pos, _objectiveArea] call FLO_fnc_minefieldIsPositionInsideObjectiveArea) exitWith { ["defended", []] };
if (([_pos, _ignoredObjectiveIds, _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") exitWith { ["foreign", []] };

["", _pos]
