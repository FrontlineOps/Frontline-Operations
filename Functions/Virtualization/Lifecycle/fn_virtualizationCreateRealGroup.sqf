/*
 * Function: FLO_fnc_virtualizationCreateRealGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates a real Arma group for virtual activation and returns grpNull when
 *   the engine refuses the group. Callers must stop before spawning vehicles.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: Virtual group ID <STRING>
 * 2: Virtual group type <STRING>
 *
 * Return Value:
 * GROUP
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_groupId", "", [""]],
    ["_groupType", "", [""]]
];

private _realGroup = createGroup [_side, true];
if (isNull _realGroup) then {
    ["VIRTUALIZATION", 1, format [
        "Engine refused createGroup for %1 (%2) on side %3 - activation deferred without spawning vehicles",
        _groupId,
        _groupType,
        _side
    ]] call FLO_fnc_log;
};

_realGroup
