params [
    ["_objective", createHashMap, [createHashMap]],
    ["_branch", "", [""]]
];

_branch = toUpper _branch;
if !(_branch in (FLO_ObjectiveDevelopmentConfig get "validBranches")) then {
    throw format ["Invalid Objective Development branch %1", _branch];
};

if (_branch == "REVENUE") exitWith { _objective get "revenueLevel" };
_objective get "developmentLevel"
