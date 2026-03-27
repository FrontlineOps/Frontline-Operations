/*
 * Function: FLO_fnc_gtnPublishCommanderIntel
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes the maintained GTN commander intel picture to clients as a
 *   player-facing common operating picture.
 *
 * Arguments:
 *   0: GTN commander <HASHMAPOBJECT>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [["_gtnCommander", nil]];

private _metrics = createHashMapFromArray [
    ["published", false],
    ["groupCount", 0],
    ["concentrationCount", 0],
    ["friendlyGroupCount", 0],
    ["supportMarkerCount", 0]
];

if (!isServer || {isNil "_gtnCommander"}) exitWith { _metrics };

private _worldState = _gtnCommander get "_worldState";
private _sideKey = _gtnCommander get "_sideKey";
private _picture = [_worldState] call FLO_fnc_gtnBuildCommanderIntelPicture;
private _groupMarkers = _picture get "enemyGroups";
private _concentrationMarkers = _picture get "enemyConcentrations";
private _friendlyGroupMarkers = _picture get "friendlyGroups";
private _supportMarkers = _picture get "supportMarkers";

_gtnCommander set ["_lastCommanderIntelPicture", _picture];

_metrics set ["published", true];
_metrics set ["groupCount", count _groupMarkers];
_metrics set ["concentrationCount", count _concentrationMarkers];
_metrics set ["friendlyGroupCount", count _friendlyGroupMarkers];
_metrics set ["supportMarkerCount", count _supportMarkers];

[_sideKey, _groupMarkers, _concentrationMarkers, _friendlyGroupMarkers, _supportMarkers] remoteExecCall ["FLO_fnc_gtnSyncCommanderIntelMarkers", 0, false];

_metrics
