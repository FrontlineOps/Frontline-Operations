params [["_objective", createHashMap, [createHashMap]]];

private _tier = [_objective get "developmentLevel"] call FLO_fnc_objectiveDevelopmentGetTier;
_tier get "incomeMultiplier"
