/*
 * Function: FLO_fnc_gtnPlayerTaskTitle
 * Description: Builds the title for a direct commander BIS task.
 */

params ["_kind", "_objectiveId"];

private _name = [_objectiveId] call FLO_fnc_campaignObjectiveName;
switch (_kind) do {
    case "capture": { format ["Capture %1", _name] };
    case "defend": { format ["Defend %1", _name] };
    default { throw format ["Unsupported campaign task kind: %1", _kind]; };
}
