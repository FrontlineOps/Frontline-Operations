/*
 * Function: FLO_fnc_getObjectivePosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Gets the center position of an objective by its ID.
 *
 * Arguments:
 *   0: Objective ID (STRING)
 *
 * Returns:
 *   ARRAY - Position [x,y,z], or nil if not found
 *
 * Examples:
 *   private _pos = ["virtual_1"] call FLO_fnc_getObjectivePosition;
 */

params [["_objectiveId", ""]];

if (_objectiveId == "" || isNil "FLO_Objectives") exitWith { nil };

private _data = FLO_Objectives getOrDefault [_objectiveId, nil];

if (isNil "_data") exitWith { nil };

_data get "position"

