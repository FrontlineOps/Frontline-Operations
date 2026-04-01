/*
 * Function: FLO_fnc_shouldOpenFactionDialog
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns true only when the mission setup dialog is still valid to open.
 *   Once configuration has already been submitted or initialization is
 *   underway/completed, reconnecting commanders must not see setup again.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   BOOL - True when the faction dialog may be opened
 */

private _isLoadedSave = missionNamespace getVariable ["FLO_IsLoadedSave", false];
if (_isLoadedSave) exitWith { false };

private _missionConfigReady = !isNil "FLO_MissionConfig"
    && {FLO_MissionConfig isEqualType createHashMap}
    && {count (keys FLO_MissionConfig) > 0};
if (_missionConfigReady) exitWith { false };

private _initPhase = missionNamespace getVariable ["FLO_InitPhase", 0];
if (_initPhase >= 1) exitWith { false };

missionNamespace getVariable ["FLO_MissionReady", false] isEqualTo false
