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
 *   3: Resolved engagement outcome <HASHMAP>
 *   4: EAST group count <NUMBER>
 *   5: WEST group count <NUMBER>
 *
 * Return Value:
 *   Event data <HASHMAP>
 */

params [
    "_zoneId",
    "_zoneName",
    "_zonePos",
    "_outcome",
    "_eastGroupCount",
    "_westGroupCount"
];

private _event = createHashMapFromArray [
    ["time", diag_tickTime],
    ["objectiveId", _zoneId],
    ["objectiveName", _zoneName],
    ["position", _zonePos],
    ["winner", _outcome get "winner"],
    ["decisive", _outcome get "decisive"],
    ["margin", _outcome get "margin"],
    ["friction", _outcome get "friction"],
    ["momentum", _outcome get "momentum"],
    ["roundCount", _outcome get "roundCount"],
    ["effectiveRatio", _outcome get "effectiveRatio"],
    ["eastPower", _outcome get "eastPower"],
    ["westPower", _outcome get "westPower"],
    ["eastEffectivePower", _outcome get "eastEffectivePower"],
    ["westEffectivePower", _outcome get "westEffectivePower"],
    ["eastSupport", _outcome get "eastSupport"],
    ["westSupport", _outcome get "westSupport"],
    ["artilleryRequestedBy", _outcome get "artilleryRequestedBy"],
    ["eastBefore", _outcome get "eastBefore"],
    ["eastAfter", _outcome get "eastAfter"],
    ["westBefore", _outcome get "westBefore"],
    ["westAfter", _outcome get "westAfter"],
    ["eastGroupCount", _eastGroupCount],
    ["westGroupCount", _westGroupCount]
];

FLO_GTN_CombatEvents pushBack _event;
if ((count FLO_GTN_CombatEvents) > 60) then {
    FLO_GTN_CombatEvents deleteAt 0;
};

FLO_GTN_CombatLastByObjective set [_zoneId, _event];
_event
