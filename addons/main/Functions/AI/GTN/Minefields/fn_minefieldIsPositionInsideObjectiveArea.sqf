/*
 * Function: FLO_fnc_minefieldIsPositionInsideObjectiveArea
 * Author: Frontline Operations Development Group
 * Description:
 *   Fast objective-area membership test for minefield placement. Uses the
 *   prebuilt minefield objective area cache so radius and bounds rejection
 *   happen before any polygon evaluation.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Objective ID <STRING> or cached objective area entry <HASHMAP>
 *
 * Return Value:
 * BOOL
 */

params [
    ["_position", [0, 0, 0]],
    ["_objectiveArea", createHashMap]
];

if ((count _position) < 2) exitWith { false };

if (_objectiveArea isEqualType "") then {
    _objectiveArea = FLO_MinefieldObjectiveAreaCache get _objectiveArea;
};

if (!(_objectiveArea isEqualType createHashMap)) exitWith { false };

private _center = _objectiveArea get "center";
if ((_position distance2D _center) > (_objectiveArea get "radius")) exitWith { false };
if !(_objectiveArea get "usePolygon") exitWith { true };

private _xPos = _position select 0;
private _yPos = _position select 1;
if (_xPos < (_objectiveArea get "minX")) exitWith { false };
if (_xPos > (_objectiveArea get "maxX")) exitWith { false };
if (_yPos < (_objectiveArea get "minY")) exitWith { false };
if (_yPos > (_objectiveArea get "maxY")) exitWith { false };

[_xPos, _yPos] inPolygon (_objectiveArea get "polygon")
