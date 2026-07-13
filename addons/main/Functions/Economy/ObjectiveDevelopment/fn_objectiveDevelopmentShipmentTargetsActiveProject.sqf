params [["_shipment", objNull, [objNull]]];

if (isNull _shipment || {!alive _shipment}) exitWith { false };
private _objectiveId = _shipment getVariable ["FLO_DevelopmentTargetObjectiveId", ""];
if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) exitWith { false };
private _objective = FLO_Objectives get _objectiveId;
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) exitWith { false };
if ((_project get "state") == "FUNDING") exitWith { false };

private _shipmentSide = _shipment getVariable ["FLO_LogisticsSide", sideUnknown];
if !(_shipmentSide in [west, east]) then {
    throw format ["Assigned development shipment %1 has invalid side %2", netId _shipment, _shipmentSide];
};
if ((_project get "sideKey") != ([_shipmentSide] call FLO_fnc_sideKey)) exitWith { false };
private _amount = _shipment getVariable ["FLO_LogisticsThroughput", -1];
if !(_amount isEqualType 0 && {_amount > 0}) then {
    throw format ["Assigned development shipment %1 has invalid amount %2", netId _shipment, _amount];
};

private _playerRemaining = (_project get "playerSupplyCap") - (_project get "playerSupply");
private _projectRemaining = (_project get "supplyRequired") - (_project get "supplyDelivered");
_amount <= _playerRemaining && {_amount <= _projectRemaining}
