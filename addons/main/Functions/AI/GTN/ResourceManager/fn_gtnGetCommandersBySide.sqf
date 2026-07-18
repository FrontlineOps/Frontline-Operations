/*
 * Function: FLO_fnc_gtnGetCommandersBySide
 * Description:
 *   Returns the live server-local commander map without publishing it through
 *   missionNamespace serialization.
 */

private _commanders = uiNamespace getVariable "FLO_GTN_CommandersBySideLive";
if (isNil "_commanders") exitWith { createHashMap };

_commanders
