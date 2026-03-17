/*
 * Function: FLO_fnc_getObjectivePath
 * Author: Frontline Operations Development Group
 * Description:
 *   Retrieves the cached waypoint array between two objectives generated
 *   by FLO_fnc_buildObjectiveGraph. If the path is stored in reverse,
 *   it is reversed automatically. Generates path on-demand if not cached.
 *
 * Arguments:
 *   0: From objective ID (STRING)
 *   1: To objective ID (STRING)
 *
 * Returns:
 *   ARRAY - Array of positions (may be empty if no link)
 *
 * Examples:
 *   ["virtual_1", "virtual_2"] call FLO_fnc_getObjectivePath;
 */

params [
    ["_from", ""],
    ["_to", ""]
];

// Validate inputs
if (_from == "" || _to == "") exitWith { [] };
if (isNil "FLO_ObjectiveLinks") exitWith { [] };
if (isNil "FLO_Objectives") exitWith { [] };

// Create canonical key (sorted alphabetically)
private _sorted = [_from, _to];
_sorted sort true;
private _key = format ["%1_%2", _sorted select 0, _sorted select 1];

// Get link data
private _link = FLO_ObjectiveLinks get _key;
if (isNil "_link") exitWith { [] };

// Get or generate path
private _path = +(_link getOrDefault ["waypoints", []]);

if (count _path == 0) then {
    // Resolve canonical link direction stored in the link object.
    private _pathFromId = _link getOrDefault ["from", _from];
    private _pathToId = _link getOrDefault ["to", _to];
    private _fromData = FLO_Objectives get _pathFromId;
    private _toData = FLO_Objectives get _pathToId;

    if (isNil "_fromData" || isNil "_toData") exitWith { _path = [] };

    private _fromPos = +(_fromData get "position");
    private _toPos = +(_toData get "position");
    if (count _fromPos > 2) then { _fromPos resize 2; };
    if (count _toPos > 2) then { _toPos resize 2; };

    // Async generation guard: avoid repeated expensive requests for same link.
    private _pending = _link getOrDefault ["pathRequestPending", false];
    private _retryAt = _link getOrDefault ["pathRetryAt", 0];

    if (!_pending && {diag_tickTime >= _retryAt}) then {
        _link set ["pathRequestPending", true];
        _link set ["pathRetryAt", diag_tickTime + 15];
        FLO_ObjectiveLinks set [_key, _link];

        private _cb = {
            params ["_status", "_posArray", "_args"];
            _args params ["_linkKey", "_fallbackPos"];

            private _linkData = FLO_ObjectiveLinks get _linkKey;
            if (isNil "_linkData") exitWith {};

            private _resolved = if (_status && {_posArray isEqualType []} && {count _posArray > 0}) then {
                _posArray
            } else {
                [_fallbackPos]
            };

            _linkData set ["waypoints", _resolved];
            _linkData set ["pathRequestPending", false];
            _linkData set ["pathRetryAt", diag_tickTime + 300];
            FLO_ObjectiveLinks set [_linkKey, _linkData];
        };

        [_fromPos, _toPos, _cb, [_key, _toPos], false, "OBJECTIVE_LINK"] call FLO_fnc_findRoadPath;
    };

    // Immediate non-blocking fallback while async path computes.
    _path = [_toPos];
};

// Reverse if needed (path stored from->to but we want to->from)
private _result = +_path;
if ((_link getOrDefault ["from", ""]) != _from) then { reverse _result };

_result
