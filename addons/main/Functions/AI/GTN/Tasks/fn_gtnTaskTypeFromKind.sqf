/*
 * Function: FLO_fnc_gtnTaskTypeFromKind
 * Description: Maps a direct commander task kind to a BIS task type.
 */

params ["_kind"];

switch (_kind) do {
    case "capture": { "Attack" };
    case "defend": { "Defend" };
    default { throw format ["Unsupported campaign task kind: %1", _kind]; };
}
