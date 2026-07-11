/*
 * Function: FLO_fnc_initStartRadarDataLink
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts the GTN radar data link worker during initialization.
 *
 * Arguments: None
 * Returns: None
 */
diag_log "[FLO_INIT_P4] Starting radar data link system...";
[] spawn FLO_fnc_gtnRadarDataLink;
