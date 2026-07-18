/*
 * Function: FLO_fnc_gtnGetResourceManager
 * Description:
 *   Returns the live server-local GTN resource manager. The live manager is
 *   deliberately kept outside missionNamespace so Arma save serialization does
 *   not walk the cyclic commander/executor/planner graph.
 */

private _manager = uiNamespace getVariable "FLO_GTN_ResourceManagerLive";
if (isNil "_manager") exitWith { nil };

_manager
