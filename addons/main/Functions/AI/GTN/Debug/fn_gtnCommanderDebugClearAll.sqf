/*
 * Function: FLO_fnc_gtnCommanderDebugClearAll
 * Author: Frontline Operations Development Group
 * Description:
 *   Deletes all GTN commander visual debug markers.
 *
 * Arguments: None
 * Returns: None
 */
{
    deleteMarker _x;
} forEach (keys FLO_GTN_CommanderDebugMarkers);

FLO_GTN_CommanderDebugMarkers = createHashMap;
