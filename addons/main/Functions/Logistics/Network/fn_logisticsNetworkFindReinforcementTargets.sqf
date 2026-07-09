/*
 * Function: FLO_fnc_logisticsNetworkFindReinforcementTargets
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds managed-side objectives that are under enemy pressure using the
 *   maintained objective monitor counts instead of raw world rescans.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   ARRAY - Objective IDs that need reinforcement
 */

params ["_net"];

private _managedSide = _net get "_managedSide";
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
private _managedObjectives = (_net get "_managedObjectiveIds") select {
    ((FLO_Objectives get _x) get _enemyCountKey) > 0
};

_managedObjectives
