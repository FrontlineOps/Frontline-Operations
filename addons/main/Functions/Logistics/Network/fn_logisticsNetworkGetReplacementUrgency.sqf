/* Classifies one replacement target using maintained objective and campaign state. */
params ["_network", ["_objectiveId", "", [""]]];

if !(_objectiveId in FLO_Objectives) then {
    throw format ["Cannot classify replacement urgency for missing objective %1", _objectiveId];
};
if ([_network, _objectiveId] call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure) exitWith { "CRITICAL" };

private _objective = FLO_Objectives get _objectiveId;
private _side = _network get "_managedSide";
private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
if ((_objective get _enemyCountKey) > 0) exitWith { "PRESSURED" };

private _operationReservation = [_side, _objectiveId] call FLO_fnc_campaignGetOperationReservation;
if (_operationReservation select 1) exitWith { "OPERATIONAL" };

"ROUTINE"
