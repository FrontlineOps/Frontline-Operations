params [
    ["_network", createHashMap, [createHashMap]],
    ["_objectiveId", "", [""]]
];

if (!isServer) exitWith { 0 };
if !(_objectiveId in FLO_Objectives) then {
    throw format ["Cannot process deliveries for missing development objective %1", _objectiveId];
};

private _side = _network get "_managedSide";
private _sideKey = _network get "_managedSideKey";
private _objective = FLO_Objectives get _objectiveId;
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) then {
    throw format ["Cannot process deliveries for inactive development objective %1", _objectiveId];
};
if ((_project get "sideKey") != _sideKey) then {
    throw format ["Development objective %1 does not belong to logistics network %2", _objectiveId, _sideKey];
};
[_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;

private _shipments = nearestObjects [
    _objective get "position",
    ["CargoNet_01_box_F"],
    _objective get "radius"
] select {
    alive _x
    && {_x getVariable ["FLO_LogisticsShipment", false]}
    && {!(_x getVariable ["FLO_LogisticsDelivered", false])}
    && {(_x getVariable ["FLO_LogisticsSide", sideUnknown]) isEqualTo _side}
    && {(_x getVariable ["FLO_DevelopmentTargetObjectiveId", ""]) == _objectiveId}
    && {[getPosATL _x, _objective] call FLO_fnc_isPositionInObjective}
};

private _accepted = 0;
{
    _objective = FLO_Objectives get _objectiveId;
    _project = _objective get "developmentProject";
    if ((keys _project) isEqualTo []) exitWith {};
    private _amount = _x getVariable ["FLO_LogisticsThroughput", -1];
    if !(_amount isEqualType 0 && {_amount > 0}) then {
        throw format ["Development shipment %1 has invalid amount %2", netId _x, _amount];
    };
    private _playerRemaining = (_project get "playerSupplyCap") - (_project get "playerSupply");
    private _projectRemaining = (_project get "supplyRequired") - (_project get "supplyDelivered");
    if (_amount > (_playerRemaining min _projectRemaining)) then {
        _x setVariable ["FLO_DevelopmentTargetObjectiveId", "", true];
        continue;
    };

    private _contributorName = _x getVariable ["FLO_LogisticsContributorName", "A player"];
    if (_contributorName == "") then { _contributorName = "A player"; };
    _project set ["playerSupply", (_project get "playerSupply") + _amount];
    _project set ["supplyDelivered", (_project get "supplyDelivered") + _amount];
    _project set ["lastContributorName", _contributorName];
    _objective set ["developmentProject", _project];
    [_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;
    FLO_Objectives set [_objectiveId, _objective];

    _x setVariable ["FLO_LogisticsDelivered", true, true];
    deleteVehicle _x;
    _accepted = _accepted + 1;

    private _timeSavedSeconds = round ((_amount / (FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick")) * (FLO_ObjectiveDevelopmentConfig get "tickInterval"));
    [_side, format [
        "%1 delivered %2 project supplies to %3 and saved %4 minutes (%5/%6 player lift).",
        _contributorName,
        round _amount,
        [_objectiveId] call FLO_fnc_campaignObjectiveName,
        round (_timeSavedSeconds / 60),
        round (_project get "playerSupply"),
        _project get "playerSupplyCap"
    ], "success"] call FLO_fnc_objectiveDevelopmentNotifySide;

    if ((_project get "supplyDelivered") >= (_project get "supplyRequired")) then {
        [_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentCompleteProject;
    };
} forEach _shipments;

_accepted
