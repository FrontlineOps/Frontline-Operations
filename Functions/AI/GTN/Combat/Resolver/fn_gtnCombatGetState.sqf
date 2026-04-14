/*
 * Function: FLO_fnc_gtnCombatGetState
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the shared virtual combat state/cache map, creating it on first use.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Combat state <HASHMAP>
 */

if (isNil "FLO_GTN_CombatState") then {
    FLO_GTN_CombatState = createHashMap;
    FLO_GTN_CombatState set ["classification", createHashMap];
    FLO_GTN_CombatState set ["classificationDirty", true];
    FLO_GTN_CombatState set ["classificationSoftDirty", false];
    FLO_GTN_CombatState set ["classificationSeedCellSize", -1];
    FLO_GTN_CombatState set ["classificationEngagementDist", -1];
    FLO_GTN_CombatState set ["classificationBuiltAt", -1];
    FLO_GTN_CombatState set ["classificationMinRefreshSec", 30];
    FLO_GTN_CombatState set ["zones", []];
    FLO_GTN_CombatState set ["zonesBuiltAt", -1];
    FLO_GTN_CombatState set ["zonesClassificationBuiltAt", -1];
    FLO_GTN_CombatState set ["zonesSeedCellSize", -1];
    FLO_GTN_CombatState set ["zonesEngagementDist", -1];
    FLO_GTN_CombatState set ["objectiveContextCache", createHashMap];
    FLO_GTN_CombatState set ["objectiveContextCellSize", 250];
};

FLO_GTN_CombatState
