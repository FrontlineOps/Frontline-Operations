/*
 * Function: FLO_fnc_syncObjectiveRuntimeState
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies replicated objective runtime state into the local FLO_Objectives
 *   map on clients.
 *
 * Arguments:
 *   0: Runtime state map <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [["_runtimeState", createHashMap, [createHashMap]]];

if (isNil "FLO_Objectives") exitWith { false };

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _runtime = _runtimeState get _objectiveId;

    _objective set ["captureProgress", _runtime get "captureProgress"];
    _objective set ["captureState", _runtime get "captureState"];
    _objective set ["captureSide", _runtime get "captureSide"];
    _objective set ["captureSecureProgress", _runtime get "captureSecureProgress"];
    _objective set ["captureSecureStartedAt", _runtime get "captureSecureStartedAt"];
    _objective set ["captureStatusChangedAt", _runtime get "captureStatusChangedAt"];
    _objective set ["captureIntegratedAtDateNum", _runtime get "captureIntegratedAtDateNum"];
    _objective set ["campaignIntegrationState", _runtime get "campaignIntegrationState"];
    _objective set ["bluforCount", _runtime get "bluforCount"];
    _objective set ["opforCount", _runtime get "opforCount"];
    _objective set ["contested", _runtime get "contested"];
    _objective set ["underAttack", _runtime get "underAttack"];

    FLO_Objectives set [_objectiveId, _objective];
} forEach (keys _runtimeState);

missionNamespace setVariable ["FLO_ObjectiveRuntimeState", _runtimeState];

true
