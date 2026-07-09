/*
 * Function: FLO_fnc_gtnTaskTypeFromKind
 * Author: Frontline Operations Development Group
 * Description:
 *   Maps GTN player task kind to a BIS task type.
 *
 * Arguments:
 *   0: Task kind <STRING>
 *
 * Return Value:
 *   BIS task type <STRING>
 */

params ["_kind"];

switch (_kind) do {
    case "capture": { "Attack" };
    case "defend": { "Defend" };
    case "destroy": { "Destroy" };
    default { "Attack" };
}
