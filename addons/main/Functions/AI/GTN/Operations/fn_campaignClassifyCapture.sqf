/* Classifies a capture as operation consolidation or unsupported foothold. */
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
private _matchedOperationId = "";
{
    if ((_y get "objectiveId") == _objectiveId) exitWith {
        _matchedOperationId = _x;
    };
} forEach (_state get "operations");

private _defenderRecapture = false;
private _operationCapture = false;
private _operation = createHashMap;
if (_matchedOperationId != "") then {
    _operation = (_state get "operations") get _matchedOperationId;
    _defenderRecapture = (_operation get "defenderSideKey") == _sideKey
        && {(_operation get "phase") in ["SECURE", "CONSOLIDATE"]};
    _operationCapture = (_operation get "attackerSideKey") == _sideKey
        && {(_operation get "phase") == "ASSAULT"};
};

if (_defenderRecapture) exitWith {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["campaignOperationId", ""];
    _objective set ["campaignCapturedBySideKey", ""];
    _objective set ["campaignBenefitsPending", false];
    _objective set ["captureIntegratedAtDateNum", call FLO_fnc_operationalDateNumber];
    _objective set ["captureState", "integrated"];
    ["CAMPAIGN", 3, format ["Defender restored integrated control of operation target %1", _objectiveId]] call FLO_fnc_log;
    _objective
};

_objective set ["campaignCapturedBySideKey", _sideKey];
_objective set ["campaignBenefitsPending", true];
_objective set ["captureGrowthEligibleAtDateNum", -1];
_objective set ["captureGrowthPending", false];

if (_operationCapture) then {
    private _durations = _config get "phaseDurations";
    private _integrationSeconds = (_durations get "SECURE") + (_durations get "CONSOLIDATE");
    _objective set ["campaignIntegrationState", "CONSOLIDATING"];
    _objective set ["campaignOperationId", _matchedOperationId];
    _objective set [
        "captureIntegratedAtDateNum",
        [call FLO_fnc_operationalDateNumber, _integrationSeconds] call FLO_fnc_dateNumberAddSeconds
    ];
} else {
    _objective set ["campaignIntegrationState", "FOOTHOLD"];
    _objective set ["campaignOperationId", ""];
    _objective set ["captureIntegratedAtDateNum", -1];
};

["CAMPAIGN", 3, format [
    "Objective %1 captured by %2 as %3",
    _objectiveId,
    _sideKey,
    _objective get "campaignIntegrationState"
]] call FLO_fnc_log;
_objective
