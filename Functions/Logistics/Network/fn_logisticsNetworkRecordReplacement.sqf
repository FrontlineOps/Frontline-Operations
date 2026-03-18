/*
 * Function: FLO_fnc_logisticsNetworkRecordReplacement
 * Author: Frontline Operations Development Group
 * Description:
 *   Updates replacement statistics after a successful reinforcement dispatch.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Group type <STRING>
 *   2: Resource cost <NUMBER>
 *
 * Return Value:
 *   None
 */

params ["_net", "_groupType", "_cost"];

private _stats = _net get "_stats";
_stats set ["totalReplacements", (_stats get "totalReplacements") + 1];
_stats set ["resourcesSpent", (_stats get "resourcesSpent") + _cost];

private _byType = _stats get "byType";
_byType set [_groupType, (_byType getOrDefault [_groupType, 0]) + 1];
_stats set ["byType", _byType];
