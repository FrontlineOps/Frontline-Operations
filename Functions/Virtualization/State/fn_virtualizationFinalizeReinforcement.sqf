/*
 * Function: FLO_fnc_virtualizationFinalizeReinforcement
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears reinforcement-only mission state once a logistics replacement has
 *   effectively reached its destination.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when reinforcement flags were cleared
 */

params ["_groupId", "_groupData"];

if ((_groupData get "replacementState") != "REINFORCE") exitWith { false };

private _deliveryObjectiveId = _groupData get "reinforcementDeliveryObjective";
if (
    _deliveryObjectiveId != ""
    && {!isNil "FLO_Logistics_Networks"}
    && {FLO_Logistics_Networks isEqualType createHashMap}
) then {
    private _sideContext = [(_groupData get "side")] call FLO_fnc_gtnSideContext;
    private _sideKey = _sideContext get "sideKey";
    if (_sideKey in FLO_Logistics_Networks) then {
        private _net = FLO_Logistics_Networks get _sideKey;
        [_net, _deliveryObjectiveId] call FLO_fnc_logisticsNetworkRecordDelivery;
    };
};

[_groupData, ""] call FLO_fnc_virtualizationClearReplacementTransit;

["VIRTUALIZATION", 3, format ["Group %1 reached destination - clearing reinforcement flags", _groupId]] call FLO_fnc_log;

true
