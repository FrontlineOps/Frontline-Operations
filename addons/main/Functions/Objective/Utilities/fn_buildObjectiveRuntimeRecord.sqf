/*
 * Function: FLO_fnc_buildObjectiveRuntimeRecord
 * Description:
 *   Builds the authoritative replicated runtime record for one objective.
 */

params ["_objective"];

createHashMapFromArray [
    ["captureProgress", _objective get "captureProgress"],
    ["captureState", _objective get "captureState"],
    ["captureSide", _objective get "captureSide"],
    ["captureSecureProgress", _objective get "captureSecureProgress"],
    ["captureSecureStartedAt", _objective get "captureSecureStartedAt"],
    ["captureStatusChangedAt", _objective get "captureStatusChangedAt"],
    ["captureIntegratedAtDateNum", _objective get "captureIntegratedAtDateNum"],
    ["campaignIntegrationState", _objective get "campaignIntegrationState"],
    ["bluforCount", _objective get "bluforCount"],
    ["opforCount", _objective get "opforCount"],
    ["contested", _objective get "contested"],
    ["underAttack", _objective get "underAttack"]
]
