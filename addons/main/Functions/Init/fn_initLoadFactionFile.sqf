/*
 * Function: FLO_fnc_initLoadFactionFile
 * Author: Frontline Operations Development Group
 * Description:
 *   Loads one preset faction script during initialization phase 2.
 *
 * Arguments:
 * 0: Faction display name <STRING>
 * 1: Script path <STRING>
 *
 * Returns:
 * Loaded successfully <BOOLEAN>
 */
params ["_factionName", "_filePath"];

if (!fileExists _filePath) exitWith {
    diag_log format ["[FLO_INIT_P2] WARNING: Faction file not found for %1: %2", _factionName, _filePath];
    false
};

try {
    diag_log format ["[FLO_INIT_P2] Loading: %1", _filePath];
    call compileScript [_filePath];
    true
} catch {
    diag_log format ["[FLO_INIT_P2] ERROR loading %1: %2", _filePath, _exception];
    false
}
