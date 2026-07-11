/*
 * Function: FLO_fnc_virtualizationCreateArchetype
 * Description:
 *   Creates one immutable-by-convention virtual-group archetype descriptor.
 */

params [
    ["_spawnKind", "", [""]],
    ["_compositionPreemptsSpawn", false, [true]],
    ["_assetStrength", false, [true]],
    ["_loadMode", "PERSONNEL", [""]],
    ["_fallbackCrewPerAsset", 1, [0]],
    ["_baseSpeedMps", 6.5, [0]],
    ["_terrainFactor", 1, [0]],
    ["_autoPatrol", false, [true]],
    ["_countMode", "FACTION", [""]],
    ["_initialGroundComposition", false, [true]]
];

createHashMapFromArray [
    ["spawnKind", _spawnKind],
    ["compositionPreemptsSpawn", _compositionPreemptsSpawn],
    ["assetStrength", _assetStrength],
    ["loadMode", _loadMode],
    ["fallbackCrewPerAsset", _fallbackCrewPerAsset],
    ["baseSpeedMps", _baseSpeedMps],
    ["terrainFactor", _terrainFactor],
    ["autoPatrol", _autoPatrol],
    ["countMode", _countMode],
    ["initialGroundComposition", _initialGroundComposition]
]
