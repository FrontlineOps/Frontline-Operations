/*
 * Function: FLO_fnc_virtualizationRestorePathState
 * Description:
 *   Restores route provenance after current-version save validation.
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearPathRequest;
_groupData set ["pathSource", _savedData get "pathSource"];
true
