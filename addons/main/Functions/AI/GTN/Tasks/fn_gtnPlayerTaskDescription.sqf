/*
 * Function: FLO_fnc_gtnPlayerTaskDescription
 * Description: Builds the description for a direct commander BIS task.
 */

params ["_kind", "_objectiveId"];

private _name = [_objectiveId] call FLO_fnc_campaignObjectiveName;
switch (_kind) do {
    case "capture": { format ["Main effort: seize %1 and hold it for consolidation.", _name] };
    case "defend": { format ["Enemy main effort: prevent the capture of %1.", _name] };
    default { throw format ["Unsupported campaign task kind: %1", _kind]; };
}
