params [
    ["_side", sideUnknown, [west]],
    ["_objectiveId", "", [""]],
    ["_branch", "", [""]]
];

if (!isServer) exitWith { false };
if !(_side in [west, east]) then { throw format ["Invalid Development project side %1", _side]; };
if !(_objectiveId in FLO_Objectives) then { throw format ["Cannot develop missing objective %1", _objectiveId]; };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
if ((count _activeObjectiveIds) >= ([_side] call FLO_fnc_objectiveDevelopmentGetProjectCapacity)) exitWith { false };
if (([_sideKey] call FLO_fnc_objectiveDevelopmentGetFundingObjectiveId) != "") exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") isNotEqualTo _side) exitWith { false };
if ((_objective get "campaignIntegrationState") != "INTEGRATED") exitWith { false };
if ((keys (_objective get "developmentProject")) isNotEqualTo []) then {
    throw format ["Objective %1 already owns a Development project", _objectiveId];
};
private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) exitWith { false };

private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _network = FLO_Logistics_Networks get _sideKey;
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
if (([_network, _objectiveId, [], _supplyPerTick] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) == "") exitWith { false };

private _quote = [_side, _objectiveId, _objective, _branch] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
_branch = _quote get "branch";
private _cost = _quote get "treasuryCost";
private _treasury = FLO_SideResources get _sideKey;
private _fundingAmount = [_treasury, _cost] call FLO_fnc_commanderSpendingGetDevelopmentFundingAmount;
if (_fundingAmount <= 0) exitWith { false };

private _targetLevel = _quote get "targetLevel";
private _reservationId = format ["DEVELOPMENT:%1:%2:%3:%4", _sideKey, _objectiveId, _branch, _targetLevel];
if !([
    _treasury,
    _reservationId,
    _fundingAmount,
    "DEVELOPMENT",
    format ["Funding %1 level %2 at %3", _branch, _targetLevel, _objectiveId],
    "COMMANDER",
    _objectiveId
] call FLO_fnc_sideResourcesReserve) exitWith { false };

private _project = createHashMapFromArray [
    ["sideKey", _sideKey],
    ["branch", _branch],
    ["state", "FUNDING"],
    ["targetLevel", _targetLevel],
    ["createdAtDateNum", call FLO_fnc_operationalDateNumber],
    ["startedAtDateNum", 0],
    ["rawTreasuryCost", _quote get "rawTreasuryCost"],
    ["discountApplied", _quote get "discountApplied"],
    ["treasuryCost", _cost],
    ["supplyRequired", _quote get "supplyRequired"],
    ["supplyDelivered", 0],
    ["commanderSupply", 0],
    ["playerSupply", 0],
    ["playerSupplyCap", _quote get "playerSupplyCap"],
    ["sourceObjectiveId", ""],
    ["lastContributorName", ""],
    ["reservationId", _reservationId]
];
_objective set ["developmentProject", _project];
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
FLO_Objectives set [_objectiveId, _objective];

if (_fundingAmount == _cost) exitWith {
    [_objectiveId] call FLO_fnc_objectiveDevelopmentActivateFundedProject
};

private _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
[_side, format [
    "%1 level %2 funding started at %3: %4 of %5 reserved.",
    _branch,
    _targetLevel,
    _objectiveName,
    _fundingAmount,
    _cost
], "info"] call FLO_fnc_objectiveDevelopmentNotifySide;
["ECONOMY", 2, format [
    "%1 started funding %2 level %3 at %4 reserved=%5/%6",
    _sideKey,
    _branch,
    _targetLevel,
    _objectiveId,
    _fundingAmount,
    _cost
]] call FLO_fnc_log;
true
