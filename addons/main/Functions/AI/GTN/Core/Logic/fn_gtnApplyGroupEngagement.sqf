/*
 * Function: FLO_fnc_gtnApplyGroupEngagement
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies a temporary engagement route overlay for a GTN group while
 *   preserving its strategic commander order.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group data <HASHMAP>
 * 2: Target selection <HASHMAP>
 * 3: Commander config <HASHMAP>
 *
 * Return Value:
 * BOOL - True when engagement route was applied
 */

params ["_groupId", "_groupData", "_target", "_config"];

private _targetPos = _target get "targetPos";
if ((count _targetPos) < 2) exitWith { false };

private _order = _groupData get "commanderOrder";
private _sourceTag = format ["GTN_ENGAGE_%1", _order];
private _behavior = ["AWARE", "COMBAT"] select (_order == "ATTACK");
private _speed = ["NORMAL", "FULL"] select (_order == "ATTACK");
private _formation = ["COLUMN", "WEDGE"] select (_order == "ATTACK");
private _combatMode = ["YELLOW", "RED"] select (_order == "ATTACK");
private _completionRadius = [45, 55] select (_order == "ATTACK");

[
    _groupId,
    [[_targetPos, "MOVE", _behavior, _speed, _formation, _combatMode, _completionRadius]],
    false,
    true,
    _sourceTag
] call FLO_fnc_updateVirtualGroupWaypoints;

[
    _groupData,
    _target get "targetGroupId",
    _targetPos,
    _target get "targetObjective",
    _target get "reason",
    diag_tickTime + (_config get "engagementDurationSeconds"),
    _target get "leashMeters"
] call FLO_fnc_virtualizationSetEngagementState;

true
