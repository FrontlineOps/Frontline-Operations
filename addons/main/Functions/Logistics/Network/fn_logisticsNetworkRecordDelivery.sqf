/* Records reinforcement arrival without changing explicit node topology. */
params ["_network", ["_deliveryObjectiveId", "", [""]]];

if (_deliveryObjectiveId == "") exitWith { false };
private _stats = _network get "_stats";
_stats set ["reinforcementDeliveries", (_stats get "reinforcementDeliveries") + 1];
true
