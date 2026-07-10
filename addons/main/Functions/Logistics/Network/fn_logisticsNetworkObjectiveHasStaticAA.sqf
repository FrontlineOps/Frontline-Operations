/*
 * Function: FLO_fnc_logisticsNetworkObjectiveHasStaticAA
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether the managed side already has a living static AA group
 *   assigned to the specified objective.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   BOOL - True when static AA already exists at the objective
 */

params ["_net", "_objectiveId"];

private _managedSide = _net get "_managedSide";
private _groups = call FLO_fnc_virtualizationGetGroupMap;

(values _groups findIf {
    private _gData = _x;
    ((_gData get "groupType") isEqualTo "static_aa") &&
    {(_gData get "side") isEqualTo _managedSide} &&
    {(_gData get "unitCount") > 0} &&
    {
        private _replacementState = _gData get "replacementState";
        if (_replacementState isEqualTo "AA_DEPLOY") exitWith {
            ((_gData get "reinforcementRequestedObjective") isEqualTo _objectiveId) ||
            {(_gData get "homeObjective") isEqualTo _objectiveId}
        };

        ((_gData get "homeObjective") isEqualTo _objectiveId) &&
        {(_gData get "isActive")}
    }
}) != -1
