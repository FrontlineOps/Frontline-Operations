/*
 * Function: FLO_fnc_virtualizationCreateRegistry
 * Description:
 *   Creates the server-owned virtual-force registry and validated runtime
 *   configuration. All mutable collections are allocated per registry.
 */

params [
    ["_activationDistance", 2000, [0]],
    ["_activationUnitCap", 200, [0]]
];

if (_activationDistance <= 0) then {
    throw format ["FLO_fnc_virtualizationCreateRegistry: invalid activation distance %1", _activationDistance];
};
if (_activationUnitCap <= 0) then {
    throw format ["FLO_fnc_virtualizationCreateRegistry: invalid activation unit cap %1", _activationUnitCap];
};

createHashMapFromArray [
    ["groups", createHashMap],
    ["config", createHashMapFromArray [
        ["activationDistance", _activationDistance],
        ["activationUnitCap", _activationUnitCap],
        ["activationResumeCap", ((_activationUnitCap - 20) max 0)],
        ["activationRetryCooldown", 10],
        ["landRouteBlockedRetrySeconds", 30],
        ["movementDeadbandMeters", 8],
        ["positionEventCellSize", 150],
        ["enabled", true]
    ]],
    ["archetypes", call FLO_fnc_virtualizationCreateArchetypeCatalog],
    ["spatial", createHashMap],
    ["revision", 0]
]
