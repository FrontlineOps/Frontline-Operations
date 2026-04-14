/*
 * Function: FLO_fnc_gtnFlushAlertQueue
 * Author: Frontline Operations Development Group
 * Description:
 *   Flushes a short-lived per-side alert publish queue to targeted clients.
 *
 * Arguments:
 *   0: Side key <STRING>
 *
 * Return Value:
 *   BOOL
 */

params [["_sideKey", "", [""]]];

if (!isServer || {_sideKey == ""}) exitWith { false };
if (isNil "FLO_GTN_PendingAlertPublishes") exitWith { false };
if (isNil "FLO_GTN_AlertBatchScheduled") exitWith { false };

private _queuedBySide = FLO_GTN_PendingAlertPublishes;
private _scheduledBySide = FLO_GTN_AlertBatchScheduled;

if !(_sideKey in _queuedBySide) exitWith { false };

private _records = +(_queuedBySide get _sideKey);
_queuedBySide set [_sideKey, []];
_scheduledBySide set [_sideKey, false];

if (count _records == 0) exitWith { false };

private _targetSide = if (_sideKey == "EAST") then { east } else { west };
private _targetOwners = [_targetSide] call FLO_fnc_gtnGetSideClientOwners;
if (count _targetOwners == 0) exitWith { false };

[_records] remoteExecCall ["FLO_fnc_gtnSyncAlertBatch", _targetOwners, false];

["alertFlushes", 1] call FLO_fnc_netDebugRecord;
["alertMarkers", count _records] call FLO_fnc_netDebugRecord;
["alertTargets", count _targetOwners] call FLO_fnc_netDebugRecord;

true
