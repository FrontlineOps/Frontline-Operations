/* Resolves one virtual aircraft route against maintained enemy AA groups. */
params [
    ["_airGroupId", "", [""]],
    ["_routeStart", [0, 0, 0], [[]]],
    ["_routeEnd", [0, 0, 0], [[]]],
    ["_groups", createHashMap, [createHashMap]],
    ["_contactIndex", createHashMap, [createHashMap]]
];

if !(_airGroupId in _groups) exitWith { createHashMapFromArray [["status", "DESTROYED"], ["aaGroupId", ""], ["losses", 0]] };

private _airData = _groups get _airGroupId;
if !((_airData get "groupType") in ["helicopter", "air", "jet"]) then {
    throw format ["Air-defense resolver received non-air group %1", _airGroupId];
};
private _transportCarrier = [_airData] call FLO_fnc_virtualizationIsTransportCarrier;

private _state = call FLO_fnc_gtnAirDefenseGetState;
private _airSide = _airData get "side";
private _enemySide = [east, west] select (_airSide isEqualTo east);
private _enemySideKey = [_enemySide] call FLO_fnc_sideKey;
private _aaGroupIds = (_contactIndex get "aaGroupIdsBySide") get _enemySideKey;
private _candidates = [];

{
    private _aaId = _x;
    private _aaData = _groups get _aaId;
    private _aaType = _aaData get "groupType";

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
} forEach _aaGroupIds;

if (_candidates isEqualTo []) exitWith { createHashMapFromArray [["status", "CLEAR"], ["aaGroupId", ""], ["losses", 0]] };
_candidates sort true;
(_candidates select 0) params ["_priority", "_distance", "_aaId", "_aaData", "_pairKey"];

private _engagementObserved = [
    [_routeStart, _routeEnd],
    _aaData get "position"
] call FLO_fnc_gtnAirDefenseIsObservedEngagement;
private _activeHandoff = [
    _airGroupId,
    _airData,
    _groups,
    _contactIndex,
    _aaId
] call FLO_fnc_gtnAirDefenseHandoffActivatedAircraft;
if ((keys _activeHandoff) isNotEqualTo []) exitWith { _activeHandoff };

if (_engagementObserved && {!_transportCarrier}) exitWith {
    [_airGroupId, _routeStart] call FLO_fnc_virtualizationUpdateGroupPosition;
    [_airGroupId, createHashMapFromArray [["forceVirtual", false], ["noWaypoints", false]]] call FLO_fnc_virtualizationPatchGroup;
    if ([_airGroupId] call FLO_fnc_virtualizationForceActivateGroup) then {
        private _realGroup = _airData get "realGroup";
        private _aircraft = objNull;
        if (!isNull _realGroup) then {
            private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
            if (_vehicles isNotEqualTo []) then { _aircraft = _vehicles select 0; };
        };
        if (!isNull _aircraft) then {
            [_aircraft, _airSide, _groups, _contactIndex, true] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
        };
        if (_aaData get "isActive") then {
            ["GTN Air Defense", 3, format [
                "Observed engagement handed aircraft %1 to physical simulation at %2 against AA %3",
                _airGroupId,
                _routeStart,
                _aaId
            ]] call FLO_fnc_log;
            createHashMapFromArray [["status", "PHYSICAL"], ["aaGroupId", _aaId], ["losses", 0]]
        } else {
            [_airGroupId, false] call FLO_fnc_gtnAirParkCombatGroupOffMap;
            createHashMapFromArray [["status", "ABORTED"], ["aaGroupId", _aaId], ["losses", 0]]
        }
    } else {
        createHashMapFromArray [["status", "ABORTED"], ["aaGroupId", _aaId], ["losses", 0]]
    }
};

(_state get "pairReadyAt") set [_pairKey, diag_tickTime + (_state get "pairCooldownSeconds")];
(_state get "aaReadyAt") set [_aaId, diag_tickTime + (_state get "aaCooldownSeconds")];
private _airType = _airData get "groupType";
private _aaType = _aaData get "groupType";
private _exposureByAircraft = _state get "virtualExposureByAircraft";
private _exposureCount = 0;
if (_airGroupId in _exposureByAircraft) then {
    private _exposure = _exposureByAircraft get _airGroupId;
    if ((diag_tickTime - (_exposure select 1)) < (_state get "virtualExposureResetSeconds")) then {
        _exposureCount = _exposure select 0;
    };
};
_exposureCount = _exposureCount + 1;

private _lossThreshold = [
    _state get "mobileLossExposureThreshold",
    _state get "staticLossExposureThreshold"
] select (_aaType == "static_aa");
if (_airType == "jet") then {
    _lossThreshold = _lossThreshold + (_state get "jetExposureThresholdBonus");
};

_activeHandoff = [
    _airGroupId,
    _airData,
    _groups,
    _contactIndex,
    _aaId
] call FLO_fnc_gtnAirDefenseHandoffActivatedAircraft;
if ((keys _activeHandoff) isNotEqualTo []) exitWith { _activeHandoff };

private _requestedLoss = parseNumber (_exposureCount >= _lossThreshold);
private _appliedLoss = 0;
if (_requestedLoss > 0) then {
    _appliedLoss = [_airGroupId, _requestedLoss] call FLO_fnc_gtnCombatApplyGroupLoss;
    if (_appliedLoss > 0) then {
        _exposureByAircraft deleteAt _airGroupId;
    } else {
        _exposureByAircraft set [_airGroupId, [_exposureCount, diag_tickTime]];
    };
} else {
    _exposureByAircraft set [_airGroupId, [_exposureCount, diag_tickTime]];
};

_activeHandoff = [
    _airGroupId,
    _airData,
    _groups,
    _contactIndex,
    _aaId
] call FLO_fnc_gtnAirDefenseHandoffActivatedAircraft;
if ((keys _activeHandoff) isNotEqualTo []) exitWith { _activeHandoff };

private _status = "ABORTED";
if !(_airGroupId in _groups) then { _status = "DESTROYED"; };
["GTN Air Defense", 3, format [
    "%1 %2 engaged virtual aircraft %3: %4 mode=ABSTRACT transport=%5 observed=%6 exposure=%7/%8 losses=%9",
    _enemySide,
    _aaId,
    _airGroupId,
    _status,
    _transportCarrier,
    _engagementObserved,
    _exposureCount,
    _lossThreshold,
    _appliedLoss
]] call FLO_fnc_log;
["FLO_GTN_VirtualAirDefenseEngagement", [_aaId, _airGroupId, _status, _appliedLoss]] call CBA_fnc_localEvent;

createHashMapFromArray [["status", _status], ["aaGroupId", _aaId], ["losses", _appliedLoss]]
