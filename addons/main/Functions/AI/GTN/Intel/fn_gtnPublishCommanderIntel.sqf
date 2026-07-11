/*
 * Function: FLO_fnc_gtnPublishCommanderIntel
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes the maintained GTN commander intel picture to clients as a
 *   player-facing common operating picture.
 *
 * Arguments:
 *   0: GTN commander <HASHMAPOBJECT>
 *   1: Target client owners for the commander's side <ARRAY>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [
    ["_gtnCommander", nil],
    ["_targetOwners", [], [[]]]
];

private _metrics = createHashMapFromArray [
    ["published", false],
    ["groupCount", 0],
    ["concentrationCount", 0],
    ["friendlyGroupCount", 0],
    ["supportMarkerCount", 0],
    ["targetCount", count _targetOwners]
];

if (!isServer || {isNil "_gtnCommander"}) exitWith { _metrics };
if (_targetOwners isEqualTo []) exitWith { _metrics };

private _worldState = _gtnCommander get "_worldState";
private _sideKey = _gtnCommander get "_sideKey";
private _picture = [_worldState] call FLO_fnc_gtnBuildCommanderIntelPicture;
private _groupMarkers = _picture get "enemyGroups";
private _concentrationMarkers = _picture get "enemyConcentrations";
private _friendlyGroupMarkers = _picture get "friendlyGroups";
private _supportMarkers = _picture get "supportMarkers";
private _ownerSignatureParts = _targetOwners apply { str _x };
_ownerSignatureParts sort true;
private _ownerSignature = _ownerSignatureParts joinString ",";
private _publishSignature = [
    _sideKey,
    _groupMarkers,
    _concentrationMarkers,
    _friendlyGroupMarkers,
    _supportMarkers
] call FLO_fnc_gtnBuildCommanderIntelPublishSignature;
private _forceRefreshInterval = ((_gtnCommander get "_config") get "intelPublishForceRefreshInterval") max 1;
private _lastPublishedAt = _gtnCommander get "_lastCommanderIntelPublishedAt";
private _signatureChanged = _publishSignature != (_gtnCommander get "_lastCommanderIntelPublishSignature");
private _ownersChanged = _ownerSignature != (_gtnCommander get "_lastCommanderIntelOwnerSignature");
private _refreshDue = _lastPublishedAt < 0 || {diag_tickTime - _lastPublishedAt >= _forceRefreshInterval};

_gtnCommander set ["_lastCommanderIntelPicture", _picture];

_metrics set ["groupCount", count _groupMarkers];
_metrics set ["concentrationCount", count _concentrationMarkers];
_metrics set ["friendlyGroupCount", count _friendlyGroupMarkers];
_metrics set ["supportMarkerCount", count _supportMarkers];
if !(_signatureChanged || {_ownersChanged} || {_refreshDue}) exitWith { _metrics };

_metrics set ["published", true];

[_sideKey, _groupMarkers, _concentrationMarkers, _friendlyGroupMarkers, _supportMarkers] remoteExecCall ["FLO_fnc_gtnSyncCommanderIntelMarkers", _targetOwners, false];

_gtnCommander set ["_lastCommanderIntelPublishSignature", _publishSignature];
_gtnCommander set ["_lastCommanderIntelOwnerSignature", _ownerSignature];
_gtnCommander set ["_lastCommanderIntelPublishedAt", diag_tickTime];

["commanderIntelPublishes", 1] call FLO_fnc_netDebugRecord;
["commanderIntelMarkers", (count _groupMarkers) + (count _concentrationMarkers) + (count _friendlyGroupMarkers) + (count _supportMarkers)] call FLO_fnc_netDebugRecord;
["commanderIntelTargets", count _targetOwners] call FLO_fnc_netDebugRecord;

_metrics
