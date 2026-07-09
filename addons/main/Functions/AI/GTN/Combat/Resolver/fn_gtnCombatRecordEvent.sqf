/*
 * Function: FLO_fnc_gtnCombatRecordEvent
 * Author: Frontline Operations Development Group
 * Description:
 *   Records a resolved virtual combat event and updates shared combat history
 *   state for telemetry consumers.
 *
 * Arguments:
 *   0: Zone ID <STRING>
 *   1: Zone name <STRING>
 *   2: Zone position <ARRAY>
 *   3: Winning side <SIDE>
 *   4: Margin <NUMBER>
 *   5: EAST roll <NUMBER>
 *   6: WEST roll <NUMBER>
 *   7: EAST modifier <NUMBER>
 *   8: WEST modifier <NUMBER>
 *   9: EAST count before <NUMBER>
 *   10: EAST count after <NUMBER>
 *   11: WEST count before <NUMBER>
 *   12: WEST count after <NUMBER>
 *   13: EAST group count <NUMBER>
 *   14: WEST group count <NUMBER>
 *
 * Return Value:
 *   Event data <HASHMAP>
 */

params [
    "_zoneId",
    "_zoneName",
    "_zonePos",
    "_winner",
    "_margin",
    "_rollEast",
    "_rollWest",
    "_modEast",
    "_modWest",
    "_eastBefore",
    "_eastAfter",
    "_westBefore",
    "_westAfter",
    "_eastGroupCount",
    "_westGroupCount"
];

private _event = createHashMapFromArray [
    ["time", diag_tickTime],
    ["objectiveId", _zoneId],
    ["objectiveName", _zoneName],
    ["position", _zonePos],
    ["winner", _winner],
    ["margin", _margin],
    ["eastRoll", _rollEast],
    ["westRoll", _rollWest],
    ["eastMod", _modEast],
    ["westMod", _modWest],
    ["eastBefore", _eastBefore],
    ["eastAfter", _eastAfter],
    ["westBefore", _westBefore],
    ["westAfter", _westAfter],
    ["eastGroupCount", _eastGroupCount],
    ["westGroupCount", _westGroupCount]
];

FLO_GTN_CombatEvents pushBack _event;
if ((count FLO_GTN_CombatEvents) > 60) then {
    FLO_GTN_CombatEvents deleteAt 0;
};

FLO_GTN_CombatLastByObjective set [_zoneId, _event];
_event
