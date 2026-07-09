/*
 * Function: FLO_fnc_transportClearInsertState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the carrier-side insert execution state used by ground transport,
 *   helicopter landing inserts, and paradrops.
 *
 * Arguments:
 *   0: Carrier Group Data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when the state was cleared
 */

params [["_groupData", createHashMap, [createHashMap]]];

private _realGroup = _groupData get "realGroup";
if (!isNull _realGroup) then {
    [_realGroup] call FLO_fnc_transportResetActiveCarrierMotion;
};

_groupData set ["dismountAtWaypoint", -1];
_groupData set ["transportInsertMode", ""];
_groupData set ["transportInsertPos", []];
_groupData set ["transportLandCommandIssued", false];
_groupData set ["transportUnloadCommandIssued", false];
_groupData set ["transportUnloadIssuedAt", -1];
[_groupData] call FLO_fnc_virtualizationClearExecutionState;
[_groupData] call FLO_fnc_virtualizationClearMissionLock;

true
