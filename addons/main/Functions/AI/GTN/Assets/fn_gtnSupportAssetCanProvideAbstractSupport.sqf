/*
 * Function: FLO_fnc_gtnSupportAssetCanProvideAbstractSupport
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a support asset may contribute abstract rear-area support.
 *   Support assets must be free, intact, and anchored to a friendly objective
 *   that is not contested or under attack. Transport helicopters never count
 *   as combat support providers.
 *
 * Arguments:
 *   0: Virtual group data <HASHMAP>
 *
 * Return Value:
 *   Abstract support eligibility <BOOL>
 */

params ["_groupData"];

private _groupType = _groupData get "groupType";
if !([_groupType] call FLO_fnc_gtnCombatIsSupportProvider) exitWith { false };

private _side = _groupData get "side";
if !(_side in [east, west]) exitWith { false };
if ((_groupData get "unitCount") <= 0) exitWith { false };
if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "transportRole") && {_groupType in ["air", "helicopter", "jet"]}) exitWith { false };

private _objectiveId = _groupData get "homeObjective";
if (_objectiveId == "") then {
    _objectiveId = [(_groupData get "position")] call FLO_fnc_getNearestObjective;
};
private _commander = [_side] call FLO_fnc_gtnGetCommanderBySide;
if (isNil "_commander") exitWith { false };

private _worldState = _commander get "_worldState";
private _objectiveState = (_worldState call ["_getObjectives", []]) get _objectiveId;
private _owner = _objectiveState get "owner";

if (_owner isEqualType "") then {
    private _ownerKey = toUpper _owner;
    if (_ownerKey == "EAST") then { _owner = east; };
    if (_ownerKey == "WEST") then { _owner = west; };
};

(_owner isEqualTo _side)
&& {!(_objectiveState get "contested")}
&& {!(_objectiveState get "underAttack")}
