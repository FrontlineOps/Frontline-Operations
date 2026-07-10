/*
 * Function: FLO_fnc_campaignIntegrateObjective
 * Description:
 *   Converts a held campaign capture into strategic territory and publishes
 *   the resulting objective state.
 */

params ["_director", "_objectiveId", ["_reason", "", [""]]];

private _objective = FLO_Objectives get _objectiveId;
private _wasIntegrated = (_objective get "campaignIntegrationState") == "INTEGRATED";
private _benefitsWerePending = _objective get "campaignBenefitsPending";
if (_wasIntegrated && {!_benefitsWerePending}) exitWith { true };

private _owner = _objective get "owner";
private _sideKey = ([_owner] call FLO_fnc_gtnSideContext) get "sideKey";
if ((_objective get "campaignCapturedBySideKey") != _sideKey) exitWith {
    _objective set ["campaignBenefitsPending", false];
    FLO_Objectives set [_objectiveId, _objective];
    false
};

if (!_wasIntegrated) then {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["captureIntegratedAtDateNum", dateToNumber date];
    _objective set ["captureState", "integrated"];
    FLO_Objectives set [_objectiveId, _objective];
};

if (_benefitsWerePending) then {
    [_objectiveId] call FLO_fnc_campaignApplyCaptureBenefits;
};

[_director, _objectiveId] call FLO_fnc_campaignClearObjectiveOpportunities;

private _manager = _director get "_resourceManager";
{
    _manager call ["_markCommanderDirty", [_x, "OBJECTIVE_INTEGRATED", [_objectiveId, _owner]]];
} forEach [west, east];

{
    private _network = FLO_Logistics_Networks get _x;
    [_network] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
} forEach ["EAST", "WEST"];

if (_reason == "OPERATION_COMPLETE") then {
    [_director, "Operation consolidation complete"] call FLO_fnc_campaignReleaseOperationBudget;
    private _ownerNetwork = FLO_Logistics_Networks get _sideKey;
    [_ownerNetwork, true] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
    [_ownerNetwork, _objectiveId, (_director get "_state") get "operationId"] call FLO_fnc_logisticsNetworkEstablishForwardDepot;
};

FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;
publicVariable "FLO_Objectives";

["CAMPAIGN", 2, format ["Objective %1 integrated (%2)", _objectiveId, _reason]] call FLO_fnc_log;
true
