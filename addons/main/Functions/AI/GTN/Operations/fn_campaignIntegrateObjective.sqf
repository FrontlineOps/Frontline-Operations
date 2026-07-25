/* Converts a held foothold into secured territory and publishes its benefits. */
params [
    ["_objectiveId", "", [""]],
    ["_reason", "", [""]]
];

private _objective = FLO_Objectives get _objectiveId;
private _wasIntegrated = (_objective get "campaignIntegrationState") == "INTEGRATED";
private _benefitsWerePending = _objective get "campaignBenefitsPending";
if (_wasIntegrated && {!_benefitsWerePending}) exitWith { true };

private _owner = _objective get "owner";
if !(_owner in [west, east]) then {
    throw format ["Cannot integrate objective %1 for unsupported owner %2", _objectiveId, _owner];
};
private _sideKey = ([_owner] call FLO_fnc_gtnSideContext) get "sideKey";
if ((_objective get "campaignCapturedBySideKey") != _sideKey) exitWith {
    _objective set ["campaignBenefitsPending", false];
    FLO_Objectives set [_objectiveId, _objective];
    false
};

if (!_wasIntegrated) then {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["captureIntegratedAtDateNum", call FLO_fnc_operationalDateNumber];
    _objective set ["captureState", "integrated"];
    FLO_Objectives set [_objectiveId, _objective];
};
if (_benefitsWerePending) then { [_objectiveId] call FLO_fnc_campaignApplyCaptureBenefits };

if (!isNil "FLO_GTN_ResourceManager") then {
    { FLO_GTN_ResourceManager call ["_markCommanderDirty", [_x, "OBJECTIVE_INTEGRATED", [_objectiveId, _owner]]]; } forEach [west, east];
};
{
    private _network = FLO_Logistics_Networks get _x;
    [_network] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
} forEach ["EAST", "WEST"];

FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;
publicVariable "FLO_Objectives";

["CAMPAIGN", 3, format ["Objective %1 integrated (%2)", _objectiveId, _reason]] call FLO_fnc_log;
true
