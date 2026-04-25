/*
 * Function: FLO_fnc_gtnMinefieldSystemInit
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes the GTN-owned minefield registry, save restore, and objective
 *   flip cleanup hooks. Placement itself is executed by each side's commander.
 *
 * Arguments: None
 *
 * Return Value:
 * BOOL
 */

if (!isServer) exitWith { false };
if (missionNamespace getVariable ["FLO_GTNMinefieldSystemStarted", false]) exitWith { true };

FLO_MinefieldConfig = createHashMapFromArray [
    ["buildResolveAngleBatch", 1],
    ["buildResolveSampleBatch", 4],
    ["buildLayoutSlotBatch", 4],
    ["buildSliceBudgetMs", 4],
    ["buildSpawnBatchSize", 12],
    ["clearCooldownSeconds", 1800],
    ["coverPacketMaxCount", 2],
    ["coverPacketSearchRadius", 18],
    ["coverPacketTerrainTypes", ["TREE", "SMALL TREE", "BUSH", "FOREST BORDER", "FOREST TRIANGLE", "ROCK", "ROCKS"]],
    ["depthJitterMax", 6],
    ["frontageLinkBonus", 14],
    ["frontageLinkPadding", 20],
    ["frontageSpreadScale", 1.15],
    ["frontageWidthMax", 220],
    ["frontageWidthMin", 55],
    ["frontageWidthScale", 1.2],
    ["laneSpacingMax", 22],
    ["laneSpacingMin", 12],
    ["laneSpacingScale", 0.9],
    ["layerCountMax", 9],
    ["layerCountMin", 3],
    ["markerAlpha", 0.35],
    ["minSpacing", 12],
    ["objectiveEdgeBuffer", 12],
    ["resourceCostPerMine", 1],
    ["resourceSpendType", "fortification"],
    ["rowSpacingMax", 28],
    ["rowSpacingMin", 16],
    ["rowSpacingScale", 0.16],
    ["slotSafeResolveRadius", 10],
    ["slotLateralJitterMax", 9]
];

FLO_Minefields = createHashMap;
FLO_MinefieldObjectiveIndex = createHashMap;
FLO_MinefieldObjectiveCooldowns = createHashMap;
FLO_MinefieldObjectiveAreaCache = [] call FLO_fnc_minefieldBuildObjectiveAreaCache;
FLO_MinefieldObjectiveOverlapIndex = [] call FLO_fnc_minefieldBuildObjectiveOverlapIndex;
FLO_MinefieldObjectiveContextCache = createHashMap;
FLO_MinefieldBuild = createHashMapFromArray [
    ["jobs", createHashMap],
    ["objectiveIndex", createHashMap],
    ["pfhId", -1],
    ["queue", []],
    ["sliceBudgetMs", FLO_MinefieldConfig get "buildSliceBudgetMs"]
];

{
    if (_x find "FLO_MINEFIELD_DEBUG_" == 0) then {
        deleteMarker _x;
    };
} forEach allMapMarkers;

if (!isNil "FLO_SavedGameData" && {!isNil "FLO_IsLoadedSave"} && {FLO_IsLoadedSave}) then {
    if ("minefieldObjectiveCooldowns" in FLO_SavedGameData && {(FLO_SavedGameData get "minefieldObjectiveCooldowns") isEqualType createHashMap}) then {
        FLO_MinefieldObjectiveCooldowns = FLO_SavedGameData get "minefieldObjectiveCooldowns";
    };

    if ("minefields" in FLO_SavedGameData) then {
        private _restored = [FLO_SavedGameData get "minefields"] call FLO_fnc_minefieldRestoreSavedFields;
        ["MINEFIELD", 3, format ["Restored %1 GTN-controlled minefields", _restored]] call FLO_fnc_log;
    };
};

["FLO_Objective_Flipped", {
    params ["_objectiveId"];
    [_objectiveId, "FLIPPED"] call FLO_fnc_minefieldDeleteObjectiveFields;
    FLO_MinefieldObjectiveCooldowns deleteAt _objectiveId;
}] call CBA_fnc_addEventHandler;

private _pfhId = [FLO_fnc_minefieldBuildQueueRun, 0, []] call CBA_fnc_addPerFrameHandler;
(FLO_MinefieldBuild) set ["pfhId", _pfhId];

missionNamespace setVariable ["FLO_GTNMinefieldSystemStarted", true];
["MINEFIELD", 3, "GTN minefield system initialized"] call FLO_fnc_log;

true
