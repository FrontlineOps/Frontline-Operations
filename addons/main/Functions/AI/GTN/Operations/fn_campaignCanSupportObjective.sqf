/*
 * Function: FLO_fnc_campaignCanSupportObjective
 * Description:
 *   Allows normal commander support for integrated territory or the active
 *   captured operation target during secure/consolidate phases.
 */

params [
    ["_side", sideUnknown, [east]],
    ["_objectiveId", "", [""]]
];

if ([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) exitWith { true };
if (isNil "FLO_CampaignDirector") then {
    throw "FLO_fnc_campaignCanSupportObjective: campaign director is not initialized";
};

private _state = FLO_CampaignDirector call ["_getState", []];
private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";

(_state get "objectiveId") isEqualTo _objectiveId
&& {(_state get "attackerSideKey") isEqualTo _sideKey}
&& {(_state get "phase") in ["SECURE", "CONSOLIDATE"]}
