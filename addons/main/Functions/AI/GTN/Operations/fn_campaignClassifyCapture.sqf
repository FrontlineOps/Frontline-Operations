/* Classifies every military capture as a foothold pending ordinary integration. */
params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_newOwner", sideUnknown, [east]]
];

if !(_newOwner in [west, east]) exitWith {
    _objective set ["campaignIntegrationState", "INTEGRATED"];
    _objective set ["campaignCapturedBySideKey", ""];
    _objective set ["campaignBenefitsPending", false];
    _objective set ["captureIntegratedAtDateNum", call FLO_fnc_operationalDateNumber];
    _objective set ["captureState", "integrated"];
    _objective
};

private _sideKey = ([_newOwner] call FLO_fnc_gtnSideContext) get "sideKey";
_objective set ["campaignCapturedBySideKey", _sideKey];
_objective set ["campaignBenefitsPending", true];
_objective set ["campaignIntegrationState", "FOOTHOLD"];
_objective set ["captureIntegratedAtDateNum", -1];
_objective set ["captureGrowthEligibleAtDateNum", -1];
_objective set ["captureGrowthPending", false];

["CAMPAIGN", 3, format ["Objective %1 captured by %2 as FOOTHOLD", _objectiveId, _sideKey]] call FLO_fnc_log;
_objective
