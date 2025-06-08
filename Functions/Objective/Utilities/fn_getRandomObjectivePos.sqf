/*
 * Function: FLO_fnc_getRandomObjectivePos
 * Author: Azraeelian Angel
 * Description:
 * Gets a random position inside an objective's radius
 *
 * Arguments:
 * 0: Objective ID <STRING>
 *
 * Return Value:
 * Random position <ARRAY>
 *
 * Example:
 * [_objectiveId] call FLO_fnc_getRandomObjectivePos;
 */

params ["_objId"];
if (isNil "FLO_Objectives") exitWith { [0,0,0] };
private _obj = FLO_Objectives get _objId;
if (isNil "_obj") exitWith { [0,0,0] };
private _pos = _obj get "position";
private _radius = _obj getOrDefault ["radius", 50];
private _dir = random 360;
private _dist = random _radius;
_pos getPos [_dist, _dir] 