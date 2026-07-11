/*
 * Function: FLO_fnc_factionDialogBuildGarrisonHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the GTN garrison tuning handle from a setup dialog selection.
 *
 * Arguments:
 * 0: Selection label <STRING>
 *
 * Returns:
 * Garrison config handle <HASHMAP>
 */
params ["_selection"];

switch (_selection) do {
    case "Light _ 1 Rear / 2 Front": {
        createHashMapFromArray [
            ["name", _selection],
            ["rearBaseGroups", 1],
            ["frontlineBaseGroups", 2],
            ["priorityBonusGroups", 0],
            ["hotBonusGroups", 1]
        ]
    };
    case "Standard _ 1 Rear / 3 Front": {
        createHashMapFromArray [
            ["name", _selection],
            ["rearBaseGroups", 1],
            ["frontlineBaseGroups", 3],
            ["priorityBonusGroups", 0],
            ["hotBonusGroups", 1]
        ]
    };
    case "Heavy _ 2 Rear / 3 Front": {
        createHashMapFromArray [
            ["name", _selection],
            ["rearBaseGroups", 2],
            ["frontlineBaseGroups", 3],
            ["priorityBonusGroups", 0],
            ["hotBonusGroups", 1]
        ]
    };
    case "Fortified _ 2 Rear / 4 Front": {
        createHashMapFromArray [
            ["name", _selection],
            ["rearBaseGroups", 2],
            ["frontlineBaseGroups", 4],
            ["priorityBonusGroups", 0],
            ["hotBonusGroups", 2]
        ]
    };
}
