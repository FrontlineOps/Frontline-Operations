/*
 * Function: FLO_fnc_minefieldBuildJobCreate
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates one staged minefield build job from a ranked candidate seed.
 *
 * Arguments:
 * 0: Candidate seed <HASHMAP>
 *
 * Return Value:
 * HASHMAP
 */

params [["_seed", createHashMap]];

if (!(_seed isEqualType createHashMap)) exitWith { createHashMap };
if ((keys _seed) isEqualTo []) exitWith { createHashMap };

private _objectiveId = _seed get "objectiveId";
private _resolveState = createHashMapFromArray [
    ["angleOffsets", [0, -15, 15, -30, 30, -45, 45, -60, 60]],
    ["nextIndex", 0],
    ["bestScore", -1],
    ["bestAnchorPos", []],
    ["bestFacingDir", _seed get "baseFacingDir"],
    ["pendingAnchorPos", []],
    ["pendingFacingDir", 0],
    ["pendingSampleIndex", -1],
    ["pendingValidSampleCount", 0],
    ["pendingSampleCount", 0]
];
private _layoutStats = createHashMapFromArray [
    ["attemptedSlots", 0],
    ["acceptedDirectSlots", 0],
    ["acceptedFallbackSlots", 0],
    ["frontageBuildMs", 0],
    ["roadBuildMs", 0],
    ["coverBuildMs", 0],
    ["bypassBuildMs", 0],
    ["frontagePacketCount", 0],
    ["roadPacketCount", 0],
    ["coverPacketCount", 0],
    ["bypassPacketCount", 0],
    ["rejectedNoSafePos", 0],
    ["rejectedWater", 0],
    ["rejectedDefendedObjective", 0],
    ["rejectedForeignObjective", 0],
    ["rejectedSpacing", 0]
];
private _metrics = createHashMapFromArray [
    ["reason", ""],
    ["resolveMs", 0],
    ["packetBuildMs", 0],
    ["layoutMs", 0],
    ["budgetMs", 0],
    ["spawnMs", 0],
    ["commitMs", 0],
    ["totalMs", 0],
    ["packetCount", 0],
    ["plannedMineCount", 0],
    ["affordableMineCount", 0],
    ["placedMineCount", 0],
    ["spentResources", 0],
    ["laneCount", 0],
    ["layerCount", 0],
    ["frontageBuildMs", 0],
    ["roadBuildMs", 0],
    ["coverBuildMs", 0],
    ["bypassBuildMs", 0],
    ["attemptedSlots", 0],
    ["acceptedDirectSlots", 0],
    ["acceptedFallbackSlots", 0],
    ["rejectedNoSafePos", 0],
    ["rejectedWater", 0],
    ["rejectedDefendedObjective", 0],
    ["rejectedForeignObjective", 0],
    ["rejectedSpacing", 0]
];

createHashMapFromArray [
    ["id", [] call FLO_fnc_createUUID],
    ["fieldId", [] call FLO_fnc_createUUID],
    ["objectiveId", _objectiveId],
    ["side", _seed get "side"],
    ["sideKey", _seed get "sideKey"],
    ["threatSignature", _seed get "threatSignature"],
    ["seed", +_seed],
    ["objectiveArea", FLO_MinefieldObjectiveAreaCache get _objectiveId],
    ["blockingObjectiveIds", FLO_MinefieldObjectiveOverlapIndex get _objectiveId],
    ["stage", "resolve"],
    ["startedAt", diag_tickTime],
    ["slices", 0],
    ["resolveState", _resolveState],
    ["context", createHashMap],
    ["packets", []],
    ["packetIndex", 0],
    ["packetState", createHashMap],
    ["laneCount", 0],
    ["spacingIndex", createHashMap],
    ["layoutMineSpecs", []],
    ["layoutStats", _layoutStats],
    ["selectedMineSpecs", []],
    ["spawnIndex", 0],
    ["mineObjects", []],
    ["selectedMinePositions", []],
    ["metrics", _metrics]
]
