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
if (_groupIds isEqualTo [] || {isNil "FLO_virtualGroups"}) exitWith { [] };

private _groups = FLO_virtualGroups get "_groups";
private _protesters = [];

{
    if !(_x in _groups) then { continue };

    private _groupData = _groups get _x;
    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then { continue };

    _groupData set ["protestRestoreAlwaysActive", _groupData get "alwaysActive"];
    _groupData set ["alwaysActive", true];
    _groupData set ["civilianRoutineState", "protest"];
    _groupData set ["civilianRoutineUntil", _expiresAt];

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
