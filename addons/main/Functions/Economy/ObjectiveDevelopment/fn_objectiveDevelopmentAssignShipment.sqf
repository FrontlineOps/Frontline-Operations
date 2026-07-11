params [
    ["_player", objNull, [objNull]],
    ["_objectiveId", "", [""]]
];

if (!isServer || {isNull _player}) exitWith { false };
private _owner = owner _player;
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    ["ECONOMY", 1, format ["Rejected development shipment assignment owner %1 for player owner %2", remoteExecutedOwner, _owner]] call FLO_fnc_log;
    false
};
if (!alive _player) exitWith {
    ["Development shipment assignment is unavailable while dead.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

private _requestAt = FLO_ObjectiveDevelopmentRuntime get "assignmentRequestAt";
if (_owner in _requestAt && {(diag_tickTime - (_requestAt get _owner)) < 1}) exitWith { false };
_requestAt set [_owner, diag_tickTime];

private _side = side group _player;
if !(_side in [west, east]) exitWith { false };
if !(_objectiveId in FLO_Objectives) exitWith {
    ["The selected development objective no longer exists.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};
private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") isNotEqualTo _side) exitWith {
    ["Only friendly regional development can receive your supplies.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) exitWith {
    ["That objective has no active development project.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};
[_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;

private _radius = FLO_ObjectiveDevelopmentConfig get "assignmentRadius";
private _shipments = nearestObjects [getPosATL _player, ["CargoNet_01_box_F"], _radius] select {
    alive _x
    && {_x getVariable ["FLO_LogisticsShipment", false]}
    && {!(_x getVariable ["FLO_LogisticsDelivered", false])}
    && {(_x getVariable ["FLO_LogisticsSide", sideUnknown]) isEqualTo _side}
};
if (_shipments isEqualTo []) exitWith {
    [format ["No friendly Supply Shipment is within %1 meters.", _radius], "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

private _shipment = _shipments select 0;
private _amount = _shipment getVariable ["FLO_LogisticsThroughput", -1];
if !(_amount isEqualType 0 && {_amount > 0}) then {
    throw format ["Development shipment %1 has invalid amount %2", netId _shipment, _amount];
};
private _assignedSupply = 0;
{
    if (_x isEqualTo _shipment) then { continue };
    if (!alive _x || {!(_x getVariable ["FLO_LogisticsShipment", false])} || {_x getVariable ["FLO_LogisticsDelivered", false]}) then { continue };
    if ((_x getVariable ["FLO_DevelopmentTargetObjectiveId", ""]) != _objectiveId) then { continue };
    private _assignedAmount = _x getVariable ["FLO_LogisticsThroughput", -1];
    if !(_assignedAmount isEqualType 0 && {_assignedAmount > 0}) then {
        throw format ["Assigned development shipment %1 has invalid amount %2", netId _x, _assignedAmount];
    };
    _assignedSupply = _assignedSupply + _assignedAmount;
} forEach (entities "ReammoBox_F");

private _playerRemaining = (_project get "playerSupplyCap") - (_project get "playerSupply") - _assignedSupply;
private _projectRemaining = (_project get "supplyRequired") - (_project get "supplyDelivered") - _assignedSupply;
if (_amount > (_playerRemaining min _projectRemaining)) exitWith {
    ["The project's remaining player contribution capacity cannot accept another shipment.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

_shipment setVariable ["FLO_DevelopmentTargetObjectiveId", _objectiveId, true];
_shipment setVariable ["FLO_LogisticsContributorUID", getPlayerUID _player, true];
_shipment setVariable ["FLO_LogisticsContributorName", name _player, true];
[format ["Shipment assigned to %1 development. Deliver it inside the objective.", [_objectiveId] call FLO_fnc_campaignObjectiveName], "success", false, _owner] call FLO_fnc_sendNotification;
["ECONOMY", 3, format ["%1 assigned shipment %2 to development %3", name _player, netId _shipment, _objectiveId]] call FLO_fnc_log;
true
