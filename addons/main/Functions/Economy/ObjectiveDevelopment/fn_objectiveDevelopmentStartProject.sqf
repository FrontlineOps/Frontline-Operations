params [
    ["_side", sideUnknown, [west]],
    ["_objectiveId", "", [""]]
];

if (!isServer) exitWith { false };
if !(_side in [west, east]) then { throw format ["Invalid development project side %1", _side]; };
if !(_objectiveId in FLO_Objectives) then { throw format ["Cannot develop missing objective %1", _objectiveId]; };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
if ((count _activeObjectiveIds) >= (FLO_ObjectiveDevelopmentConfig get "maximumConcurrentProjects")) exitWith { false };
private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") isNotEqualTo _side) exitWith { false };
if ((_objective get "campaignIntegrationState") != "INTEGRATED") exitWith { false };
if ((keys (_objective get "developmentProject")) isNotEqualTo []) then {
    throw format ["Objective %1 already owns a development project", _objectiveId];
};

private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) exitWith { false };

private _level = _objective get "developmentLevel";
private _maxLevel = (FLO_ObjectiveDevelopmentConfig get "maxLevelBySubtype") get (_objective get "subtype");
if (_level >= _maxLevel) exitWith { false };
private _targetLevel = _level + 1;
private _tier = [_targetLevel] call FLO_fnc_objectiveDevelopmentGetTier;
private _cost = _tier get "treasuryCost";
private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _network = FLO_Logistics_Networks get _sideKey;
private _sourceObjectiveId = [_network, _objectiveId, [], _supplyPerTick] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
if (_sourceObjectiveId == "") exitWith { false };

private _treasury = FLO_SideResources get _sideKey;
private _spendingState = [_treasury] call FLO_fnc_commanderSpendingGetState;
if ((_spendingState get "posture") != "SURPLUS") exitWith { false };
private _decision = [
    _treasury,
    _cost,
    "DEVELOPMENT",
    "ROUTINE",
    createHashMapFromArray [
        ["strategic", true],
        ["commitment", false],
        ["reserved", false],
        ["referenceId", _objectiveId]
    ]
] call FLO_fnc_commanderSpendingEvaluate;
if !(_decision get "allowed") exitWith { false };
if !([_treasury, _cost, "DEVELOPMENT", format ["Objective development level %1", _targetLevel], "COMMANDER", _objectiveId, true] call FLO_fnc_sideResourcesSpendResources) exitWith { false };

private _project = createHashMapFromArray [
    ["sideKey", _sideKey],
    ["state", "ACTIVE"],
    ["targetLevel", _targetLevel],
    ["startedAtDateNum", dateToNumber date],
    ["treasuryCost", _cost],
    ["supplyRequired", _tier get "supplyRequired"],
    ["supplyDelivered", 0],
    ["commanderSupply", 0],
    ["playerSupply", 0],
    ["playerSupplyCap", _tier get "playerSupplyCap"],
    ["sourceObjectiveId", _sourceObjectiveId],
    ["lastContributorName", ""]
];
_objective set ["developmentProject", _project];
[_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;
FLO_Objectives set [_objectiveId, _objective];

private _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
[_side, format ["Regional development started at %1: %2.", _objectiveName, _tier get "name"], "info"] call FLO_fnc_objectiveDevelopmentNotifySide;
["ECONOMY", 2, format ["%1 invested %2 in %3 development level %4", _sideKey, _cost, _objectiveId, _targetLevel]] call FLO_fnc_log;
true
