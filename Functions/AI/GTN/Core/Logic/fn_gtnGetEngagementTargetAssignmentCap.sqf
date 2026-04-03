/*
 * Function: FLO_fnc_gtnGetEngagementTargetAssignmentCap
 * Author: Frontline Operations Development Group
 * Description:
 *   Derives a soft assignment cap for one opportunistic engagement target so
 *   multiple groups spread across multiple known contacts instead of all
 *   dogpiling the same best-scoring target.
 *
 * Arguments:
 * 0: Target data <HASHMAP>
 * 1: Commander config <HASHMAP>
 *
 * Return Value:
 * ARRAY - [targetLoad, maxGroups, maxLoad]
 */

params ["_targetData", "_config"];

private _targetLoad = [_targetData] call FLO_fnc_gtnEstimateEngagementTargetLoad;
private _maxGroups = ((ceil (_targetLoad / (_config get "engagementTargetAssignmentDivisor"))) max 1) min (_config get "engagementTargetMaxGroups");
private _maxLoad = ceil ((_targetLoad max 4) * (_config get "engagementTargetLoadMultiplier"));

[_targetLoad, _maxGroups, _maxLoad]
