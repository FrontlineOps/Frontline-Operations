params ["_treasury"];

private _snapshot = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
createHashMapFromArray [
    ["sideKey", _snapshot get "sideKey"],
    ["balance", _snapshot get "balance"],
    ["committed", _snapshot get "committed"],
    ["available", _snapshot get "available"],
    ["lastIncome", _snapshot get "lastIncome"],
    ["incomePerMinute", _snapshot get "incomePerMinute"],
    ["lastUpdate", _snapshot get "lastUpdate"],
    ["commanderSpending", _snapshot get "commanderSpending"]
]
