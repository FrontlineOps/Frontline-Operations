/*
 * Function: FLO_fnc_transportClearInsertState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the carrier-side insert execution state used by ground transport,
 *   helicopter landing inserts, and paradrops.
 *
 * Arguments:
 *   0: Carrier Group ID <STRING>
 *
 * Return Value:
 *   BOOL - True when the state was cleared
 */

params [["_groupId", "", [""]]];

if (_groupId == "") exitWith { false };

private _groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;

private _realGroup = _groupData get "realGroup";
if (!isNull _realGroup) then {
    [_realGroup] call FLO_fnc_transportResetActiveCarrierMotion;
};

private _changes = createHashMapFromArray [
    ["dismountAtWaypoint", -1],
    ["transportInsertMode", ""],
    ["transportInsertPos", []],
    ["transportLandCommandIssued", false],
    ["transportUnloadCommandIssued", false],
    ["transportUnloadIssuedAt", -1],
    ["executionState", ""],
    ["missionLock", ""],
    ["missionType", ""]
];
[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;

true
