/*
 * Function: FLO_fnc_campaignApplyCaptureBenefits
 * Description:
 *   Pays one integrated capture reward and queues existing delayed force
 *   growth exactly once.
 */

params [["_objectiveId", "", [""]]];

private _objective = FLO_Objectives get _objectiveId;
if !(_objective get "campaignBenefitsPending") exitWith { false };
if ((_objective get "campaignIntegrationState") != "INTEGRATED") then {
    throw format ["Cannot apply benefits to non-integrated objective %1", _objectiveId];
};

private _owner = _objective get "owner";
private _sideKey = ([_owner] call FLO_fnc_gtnSideContext) get "sideKey";
private _treasury = FLO_SideResources get _sideKey;
private _captureReward = _treasury get "OBJECTIVE_CAPTURE_REWARD";
private _network = FLO_Logistics_Networks get _sideKey;
private _forceGrowth = _network get "OBJECTIVE_CAPTURE_FORCE_GROWTH";
private _growthDelaySeconds = _network get "OBJECTIVE_CAPTURE_GROWTH_DELAY_SECONDS";

[
    _treasury,
    _captureReward,
    "CAPTURE",
    format ["Secured objective %1", _objectiveId],
    "CAMPAIGN",
    _objectiveId,
    true
] call FLO_fnc_sideResourcesAddResources;

if (_forceGrowth > 0) then {
    _objective set [
        "captureGrowthEligibleAtDateNum",
        [call FLO_fnc_operationalDateNumber, _growthDelaySeconds] call FLO_fnc_dateNumberAddSeconds
    ];
    _objective set ["captureGrowthPending", true];
};

_objective set ["campaignBenefitsPending", false];
FLO_Objectives set [_objectiveId, _objective];

["CAMPAIGN", 3, format [
    "Integrated capture benefits applied: %1 gained %2 for %3",
    _sideKey,
    _captureReward,
    _objectiveId
]] call FLO_fnc_log;

true
