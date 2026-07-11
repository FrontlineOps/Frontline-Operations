/*
 * Function: FLO_fnc_campaignObjectiveName
 * Description:
 *   Returns a stable player-facing objective name.
 */

params [["_objectiveId", "", [""]]];

private _objective = FLO_Objectives get _objectiveId;
private _name = _objective get "name";
if (_name == "") then { _name = _objectiveId; };
_name
