/*
 * Function: FLO_fnc_campaignClassifyCapture
 * Description:
 *   Marks a newly captured objective as an operation consolidation or an
 *   unsupported foothold. Capture benefits remain pending.
 */

params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_newOwner", sideUnknown, [east]]
];

if !(_newOwner in [west, east]) exitWith {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["campaignOperationId", ""];
    _objective set ["campaignCapturedBySideKey", ""];
    _objective set ["campaignBenefitsPending", false];
    _objective
};

if (isNil "FLO_CampaignDirector") then {
    throw "FLO_fnc_campaignClassifyCapture: campaign director is not initialized";
};

private _state = FLO_CampaignDirector call ["_getState", []];
private _config = FLO_CampaignDirector call ["_getConfig", []];
private _sideKey = ([_newOwner] call FLO_fnc_gtnSideContext) get "sideKey";
private _defenderRecapture = (_state get "objectiveId") isEqualTo _objectiveId
    && {(_state get "defenderSideKey") isEqualTo _sideKey}
    && {(_state get "phase") in ["SECURE", "CONSOLIDATE"]};

if (_defenderRecapture) exitWith {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["campaignOperationId", ""];
    _objective set ["campaignCapturedBySideKey", ""];
    _objective set ["campaignBenefitsPending", false];
    _objective set ["captureIntegratedAtDateNum", dateToNumber date];
    _objective set ["captureState", "integrated"];

    ["CAMPAIGN", 2, format ["Defender restored integrated control of operation target %1", _objectiveId]] call FLO_fnc_log;
    _objective
};

private _operationCapture = (_state get "objectiveId") isEqualTo _objectiveId
    && {(_state get "attackerSideKey") isEqualTo _sideKey}
    && {(_state get "phase") in ["PREPARE", "ASSAULT"]};

_objective set ["campaignCapturedBySideKey", _sideKey];
_objective set ["campaignBenefitsPending", true];
_objective set ["captureGrowthEligibleAtDateNum", -1];
_objective set ["captureGrowthPending", false];

if (_operationCapture) then {
    private _durations = _config get "phaseDurations";
    private _integrationSeconds = (_durations get "SECURE") + (_durations get "CONSOLIDATE");
    _objective set ["campaignIntegrationState", "CONSOLIDATING"];
    _objective set ["campaignOperationId", _state get "operationId"];
    _objective set [
        "captureIntegratedAtDateNum",
        [dateToNumber date, _integrationSeconds] call FLO_fnc_dateNumberAddSeconds
    ];
} else {
    _objective set ["campaignIntegrationState", "FOOTHOLD"];
    _objective set ["campaignOperationId", ""];
    _objective set ["captureIntegratedAtDateNum", -1];
};

["CAMPAIGN", 2, format [
    "Objective %1 captured by %2 as %3",
    _objectiveId,
    _sideKey,
    _objective get "campaignIntegrationState"
]] call FLO_fnc_log;

_objective
