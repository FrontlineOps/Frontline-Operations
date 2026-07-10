/*
 * Function: FLO_fnc_civilianProtest
 * Author: Frontline Operations Development Group
 * Description:
 *   Temporarily repurposes active civilian groups in one objective into a
 *   bounded protest event against a nearby player.
 *
 * Arguments:
 * 0: Target player <OBJECT>
 * 1: Civilian group IDs <ARRAY>
 * 2: Objective ID <STRING>
 * 3: Protest expiry tick <NUMBER>
 *
 * Return Value:
 * ARRAY - Protesting civilian units
 */

params [
    ["_targetPlayer", objNull, [objNull]],
    ["_groupIds", [], [[]]],
    ["_objectiveId", "", [""]],
    ["_expiresAt", diag_tickTime + 120, [0]]
];

if (!isServer || {isNull _targetPlayer} || {!alive _targetPlayer} || {_objectiveId == ""}) exitWith { [] };
if (_groupIds isEqualTo [] || {isNil "FLO_VirtualForceRegistry"}) exitWith { [] };

private _protesters = [];

{
    private _groupData = [_x] call FLO_fnc_virtualizationFindGroupSnapshot;
    if (isNil "_groupData") then { continue };
    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then { continue };

    [
        _x,
        createHashMapFromArray [
            ["protestRestoreAlwaysActive", _groupData get "alwaysActive"],
            ["alwaysActive", true],
            ["civilianRoutineState", "protest"],
            ["civilianRoutineUntil", _expiresAt]
        ]
    ] call FLO_fnc_virtualizationPatchGroup;

    {
        if (!alive _x || {captive _x} || {!isNull objectParent _x}) then { continue };

        _x setVariable ["FLO_isProtester", true, true];
        _x setVariable ["FLO_ProtestTarget", _targetPlayer, false];
        _x setVariable ["FLO_ProtestObjective", _objectiveId, false];
        _x setVariable ["FLO_ProtestExpiresAt", _expiresAt, false];

        if !(_x getVariable ["FLO_ProtestWorkerRunning", false]) then {
            _x setVariable ["FLO_ProtestWorkerRunning", true, false];
            [_x] spawn FLO_fnc_civilianRunProtestBehavior;
        };

        [[_x]] call FLO_fnc_civilianActions;
        _protesters pushBack _x;
    } forEach (units _realGroup);
} forEach _groupIds;

if (_protesters isNotEqualTo []) then {
    ["CIVILIAN", 2, format [
        "Assigned %1 active civilians to protest objective %2 near %3",
        count _protesters,
        _objectiveId,
        name _targetPlayer
    ]] call FLO_fnc_log;
};

_protesters
