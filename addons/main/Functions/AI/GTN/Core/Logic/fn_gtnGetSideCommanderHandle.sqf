/*
 * Function: FLO_fnc_gtnGetSideCommanderHandle
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Returns the side-specific commander posture handle for EAST or WEST.
 *
 * Arguments:
 *   0: Side or side key <SIDE or STRING>
 *   1: Setting key <STRING>
 *      Supported: difficulty, attackCoverage, defenseCoverage, tempo, forceGrowth, garrison
 *
 * Return Value:
 *   HASHMAP - Requested commander posture handle
 */

params [
    ["_sideRef", sideUnknown],
    ["_setting", "", [""]]
];

private _sideKey = if (_sideRef isEqualType "") then {
    _sideRef
} else {
    ([_sideRef] call FLO_fnc_gtnSideContext) get "sideKey"
};

switch (_setting) do {
    case "difficulty": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestDifficultyHandle };
            case "EAST": { FLO_EastDifficultyHandle };
        };
    };
    case "attackCoverage": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestGTN_AttackCoverageHandle };
            case "EAST": { FLO_EastGTN_AttackCoverageHandle };
        };
    };
    case "defenseCoverage": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestGTN_DefenseCoverageHandle };
            case "EAST": { FLO_EastGTN_DefenseCoverageHandle };
        };
    };
    case "tempo": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestGTN_TempoHandle };
            case "EAST": { FLO_EastGTN_TempoHandle };
        };
    };
    case "forceGrowth": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestGTN_ForceGrowthHandle };
            case "EAST": { FLO_EastGTN_ForceGrowthHandle };
        };
    };
    case "garrison": {
        switch (_sideKey) do {
            case "WEST": { FLO_WestGTN_GarrisonHandle };
            case "EAST": { FLO_EastGTN_GarrisonHandle };
        };
    };
};
