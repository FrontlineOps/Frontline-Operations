/*
 * Function: FLO_fnc_campaignIsObjectiveIntegrated
 * Description:
 *   Reports whether an owned objective may participate in strategic supply
 *   and attack-source calculations.
 */

params [["_objectiveId", "", [""]]];

if (_objectiveId == "") then { throw "FLO_fnc_campaignIsObjectiveIntegrated: empty objective id"; };
private _objective = FLO_Objectives get _objectiveId;

(_objective get "campaignIntegrationState") isEqualTo "INTEGRATED"
