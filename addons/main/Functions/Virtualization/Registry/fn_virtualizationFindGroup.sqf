/*
 * Function: FLO_fnc_virtualizationFindGroup
 * Description:
 *   Optional lookup for paths where group removal is an expected outcome.
 */

params [["_groupId", "", [""]]];

if (_groupId == "") exitWith { nil };
(call FLO_fnc_virtualizationGetGroupMap) get _groupId
