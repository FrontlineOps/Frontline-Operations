/* Resolves one virtual aircraft route against maintained enemy AA groups. */
params [
    ["_airGroupId", "", [""]],
    ["_routeStart", [0, 0, 0], [[]]],
    ["_routeEnd", [0, 0, 0], [[]]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if !(_airGroupId in _groups) exitWith { createHashMapFromArray [["status", "DESTROYED"], ["aaGroupId", ""], ["losses", 0]] };

private _airData = _groups get _airGroupId;
if !((_airData get "groupType") in ["helicopter", "air", "jet"]) then {
    throw format ["Air-defense resolver received non-air group %1", _airGroupId];
};

private _state = call FLO_fnc_gtnAirDefenseGetState;
private _airSide = _airData get "side";
private _enemySide = [east, west] select (_airSide isEqualTo east);
private _candidates = [];

{
    private _aaId = _x;
    private _aaData = _y;
    private _aaType = _aaData get "groupType";
    if !(_aaType in ["static_aa", "mobile_aa"]) then { continue };
    if ((_aaData get "side") isNotEqualTo _enemySide) then { continue };
    if ((_aaData get "unitCount") <= 0) then { continue };
    if ((_aaData get "replacementState") != "") then { continue };

    private _engagementRange = [_state get "mobileEngagementRange", _state get "staticEngagementRange"] select (_aaType == "static_aa");
    private _routeDistance = [(_aaData get "position"), _routeStart, _routeEnd] call FLO_fnc_gtnAirDistancePointToSegment2D;
    if (_routeDistance > _engagementRange) then { continue };

    private _pairKey = format ["%1:%2", _aaId, _airGroupId];
    private _pairReadyAt = _state get "pairReadyAt";
    private _aaReadyAt = _state get "aaReadyAt";
    if (_aaId in _aaReadyAt && {diag_tickTime < (_aaReadyAt get _aaId)}) then { continue };
    if (_pairKey in _pairReadyAt && {diag_tickTime < (_pairReadyAt get _pairKey)}) then { continue };
    private _priority = parseNumber (_aaType != "static_aa");
    _candidates pushBack [_priority, _routeDistance, _aaId, _aaData, _pairKey];
} forEach _groups;

if (_candidates isEqualTo []) exitWith { createHashMapFromArray [["status", "CLEAR"], ["aaGroupId", ""], ["losses", 0]] };
_candidates sort true;
(_candidates select 0) params ["_priority", "_distance", "_aaId", "_aaData", "_pairKey"];

if (_aaData get "isActive") exitWith {
    private _aaPos = _aaData get "position";
    private _spawnPos = _aaPos getPos [1200, _aaPos getDir _routeEnd];
    _spawnPos set [2, 500];
    [_airGroupId, _spawnPos] call FLO_fnc_virtualizationUpdateGroupPosition;
    [_airGroupId, createHashMapFromArray [["forceVirtual", false], ["noWaypoints", false]]] call FLO_fnc_virtualizationPatchGroup;
    if ([_airGroupId] call FLO_fnc_virtualizationForceActivateGroup) then {
        private _realGroup = _airData get "realGroup";
        private _aircraft = objNull;
        if (!isNull _realGroup) then {
            private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
            if (_vehicles isNotEqualTo []) then { _aircraft = _vehicles select 0; };
        };
        if (!isNull _aircraft) then { [_aircraft, _airSide] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft; };
        createHashMapFromArray [["status", "PHYSICAL"], ["aaGroupId", _aaId], ["losses", 0]]
    } else {
        createHashMapFromArray [["status", "ABORTED"], ["aaGroupId", _aaId], ["losses", 0]]
    }
};

(_state get "pairReadyAt") set [_pairKey, diag_tickTime + (_state get "pairCooldownSeconds")];
(_state get "aaReadyAt") set [_aaId, diag_tickTime + (_state get "aaCooldownSeconds")];
private _airType = _airData get "groupType";
private _requestedLoss = parseNumber !(((_aaData get "groupType") == "mobile_aa") && {_airType == "jet"});
private _appliedLoss = 0;
if (_requestedLoss > 0) then {
    _appliedLoss = [_airGroupId, _requestedLoss] call FLO_fnc_gtnCombatApplyGroupLoss;
};

private _status = "ABORTED";
if !(_airGroupId in (call FLO_fnc_virtualizationGetGroupMap)) then { _status = "DESTROYED"; };
["GTN Air Defense", 2, format ["%1 %2 engaged virtual aircraft %3: %4 losses=%5", _enemySide, _aaId, _airGroupId, _status, _appliedLoss]] call FLO_fnc_log;
["FLO_GTN_VirtualAirDefenseEngagement", [_aaId, _airGroupId, _status, _appliedLoss]] call CBA_fnc_localEvent;

createHashMapFromArray [["status", _status], ["aaGroupId", _aaId], ["losses", _appliedLoss]]
