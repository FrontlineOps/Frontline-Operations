/*
 * Function: FLO_fnc_virtualizationFinalizeReinforcement
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears reinforcement-only mission state once a logistics replacement has
 *   effectively reached its destination.
 *
 * Arguments:
 *   0: Group ID <STRING>
 * Return Value:
 *   BOOL - True when reinforcement flags were cleared
 */

params [["_groupId", "", [""]]];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;

if ((_groupData get "replacementState") != "REINFORCE") exitWith { false };

private _deliveryObjectiveId = _groupData get "reinforcementDeliveryObjective";
if (
    _deliveryObjectiveId != ""
    && {!isNil "FLO_Logistics_Networks"}
    && {FLO_Logistics_Networks isEqualType createHashMap}
) then {
    private _side = _groupData get "side";
    if (_side in [east, west]) then {
        private _sideKey = [_side] call FLO_fnc_sideKey;
        if (_sideKey in FLO_Logistics_Networks) then {
            private _net = FLO_Logistics_Networks get _sideKey;
            [_net, _deliveryObjectiveId] call FLO_fnc_logisticsNetworkRecordDelivery;
        };
    };
};

private _candidate = [_groupData] call FLO_fnc_virtualizationCloneValue;
[_candidate, ""] call FLO_fnc_virtualizationClearReplacementTransit;
_candidate set ["nextProcessAt", 0];
[_candidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
{
    _groupData set [_x, _y];
} forEach _candidate;
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, ["replacementState", "missionLock"]]
] call CBA_fnc_localEvent;

["VIRTUALIZATION", 3, format ["Group %1 reached destination - clearing reinforcement flags", _groupId]] call FLO_fnc_log;

true
