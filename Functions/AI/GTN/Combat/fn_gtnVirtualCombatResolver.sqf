/*
 * Function: FLO_fnc_gtnVirtualCombatResolver
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves virtual combat as direct EAST/WEST group-vs-group engagements.
 *   Uses 2d6 + modifiers and applies margin-based attrition.
 *   Publishes combat telemetry as map markers + event history.
 *
 * Arguments:
 *   0: Tick interval in seconds <NUMBER> - Default 30
 *
 * Return Value:
 *   BOOL - true when resolver loop started
 */

if (!isServer) exitWith { false };

params [["_interval", 30, [0]]];
if (_interval < 5) then { _interval = 5 };

if (!isNil "FLO_GTN_VirtualCombatRunning" && {FLO_GTN_VirtualCombatRunning}) exitWith { true };
FLO_GTN_VirtualCombatRunning = true;

if (isNil "FLO_GTN_VirtualSupportCooldowns") then {
    FLO_GTN_VirtualSupportCooldowns = createHashMapFromArray [
        ["EAST_ARTY", 0],
        ["EAST_AIR", 0],
        ["WEST_ARTY", 0],
        ["WEST_AIR", 0]
    ];
};

if (isNil "FLO_GTN_CombatDebugMarkers") then { FLO_GTN_CombatDebugMarkers = createHashMap; };
if (isNil "FLO_GTN_CombatDebugMarkerOrder") then { FLO_GTN_CombatDebugMarkerOrder = []; };
if (isNil "FLO_GTN_CombatEvents") then { FLO_GTN_CombatEvents = []; };
if (isNil "FLO_GTN_CombatLastByObjective") then { FLO_GTN_CombatLastByObjective = createHashMap; };
if (isNil "FLO_GTN_CombatDebugEnabled") then { FLO_GTN_CombatDebugEnabled = true; };

private _combatMarkerTTL = 90;

private _fnc_sideKey = {
    params ["_side"];
    if (_side isEqualTo east) exitWith { "EAST" };
    if (_side isEqualTo west) exitWith { "WEST" };
    "EAST"
};

private _fnc_typeWeight = {
    params ["_groupType"];
    switch (_groupType) do {
        case "infantry": { 1.0 };
        case "motorized": { 1.15 };
        case "mechanized": { 1.35 };
        case "armor": { 1.6 };
        case "artillery": { 0.9 };
        case "helicopter": { 1.25 };
        case "jet": { 1.4 };
        case "air": { 1.3 };
        case "mobile_aa": { 1.1 };
        case "static_aa": { 1.05 };
        default { 1.0 };
    }
};

private _fnc_sidePower = {
    params ["_sideGroups"];

    private _power = 0;
    private _units = 0;
    private _inf = 0;
    private _armor = 0;

    {
        _x params ["_id", "_gData"];
        private _count = _gData get "unitCount";
        if (_count <= 0) then { continue };

        private _type = _gData get "groupType";
        private _weight = [_type] call _fnc_typeWeight;
        _power = _power + (_count * _weight);
        _units = _units + _count;

        if (_type isEqualTo "infantry") then { _inf = _inf + _count };
        if (_type in ["armor", "mechanized"]) then { _armor = _armor + _count };
    } forEach _sideGroups;

    createHashMapFromArray [
        ["power", _power],
        ["units", _units],
        ["infantry", _inf],
        ["armor", _armor]
    ]
};

private _fnc_supportBonus = {
    params ["_side", "_groups"];

    private _sideKey = [_side] call _fnc_sideKey;
    private _now = diag_tickTime;
    private _bonus = 0;
    private _artyBonus = 0;
    private _airBonus = 0;

    private _artyAvailable = false;
    private _airAvailable = false;

    {
        private _groupId = _x;
        private _gData = _groups get _groupId;
        if ((_gData get "side") != _side) then { continue };
        if (_gData get "onMission") then { continue };

        private _groupType = _gData get "groupType";
        if (_groupType isEqualTo "artillery") then { _artyAvailable = true };
        if (_groupType in ["air", "helicopter", "jet"]) then { _airAvailable = true };
    } forEach (keys _groups);

    if (_artyAvailable) then {
        private _artyKey = _sideKey + "_ARTY";
        if (_now >= (FLO_GTN_VirtualSupportCooldowns get _artyKey)) then {
            _artyBonus = 1;
            FLO_GTN_VirtualSupportCooldowns set [_artyKey, _now + 180];
        };
    };

    if (_airAvailable) then {
        private _airKey = _sideKey + "_AIR";
        if (_now >= (FLO_GTN_VirtualSupportCooldowns get _airKey)) then {
            _airBonus = 1;
            FLO_GTN_VirtualSupportCooldowns set [_airKey, _now + 240];
        };
    };

    _bonus = _artyBonus + _airBonus;

    createHashMapFromArray [
        ["total", _bonus],
        ["artillery", _artyBonus],
        ["air", _airBonus]
    ]
};

private _fnc_applyAttrition = {
    params ["_groupsMap", "_groupRefs", "_lossPct"];

    {
        _x params ["_groupId", "_gData"];

        private _count = _gData get "unitCount";
        if (_count <= 0) then {
            _gData set ["unitCount", 0];
            _groupsMap deleteAt _groupId;
            continue;
        };

        private _loss = ceil (_count * _lossPct * (0.85 + random 0.3));
        if (_loss < 1) then { _loss = 1 };

        private _newCount = _count - _loss;
        if (_newCount <= 0) then {
            _gData set ["unitCount", 0];
            _groupsMap deleteAt _groupId;
        } else {
            _gData set ["unitCount", _newCount];
            _groupsMap set [_groupId, _gData];
        };
    } forEach _groupRefs;
};

private _fnc_markerId = {
    params ["_objId"];
    private _raw = toArray (str _objId);
    private _safe = _raw apply {
        if (
            (_x >= 48 && _x <= 57) ||
            (_x >= 65 && _x <= 90) ||
            (_x >= 97 && _x <= 122) ||
            (_x == 95)
        ) then {
            _x
        } else {
            95
        }
    };

    format ["FLO_GTN_COMBAT_%1", toString _safe]
};

private _fnc_recordCombatEvent = {
    params [
        "_objId",
        "_objName",
        "_objPos",
        "_winner",
        "_margin",
        "_rollEast",
        "_rollWest",
        "_modEast",
        "_modWest",
        "_eastBefore",
        "_eastAfter",
        "_westBefore",
        "_westAfter"
    ];

    private _event = createHashMapFromArray [
        ["time", diag_tickTime],
        ["objectiveId", _objId],
        ["objectiveName", _objName],
        ["position", _objPos],
        ["winner", _winner],
        ["margin", _margin],
        ["eastRoll", _rollEast],
        ["westRoll", _rollWest],
        ["eastMod", _modEast],
        ["westMod", _modWest],
        ["eastBefore", _eastBefore],
        ["eastAfter", _eastAfter],
        ["westBefore", _westBefore],
        ["westAfter", _westAfter]
    ];

    FLO_GTN_CombatEvents pushBack _event;
    if ((count FLO_GTN_CombatEvents) > 60) then {
        FLO_GTN_CombatEvents deleteAt 0;
    };

    FLO_GTN_CombatLastByObjective set [str _objId, _event];
    _event
};

private _fnc_updateCombatMarker = {
    params ["_event", "_fnc_markerId", "_markerTTL"];
    if (!FLO_GTN_CombatDebugEnabled) exitWith {};

    private _objId = _event get "objectiveId";
    private _pos = _event get "position";
    private _winner = _event get "winner";
    if !(_winner in [east, west]) exitWith {};
    private _margin = _event get "margin";
    private _eastAfter = _event get "eastAfter";
    private _westAfter = _event get "westAfter";

    private _id = [_objId] call _fnc_markerId;
    createMarker [_id, _pos];
    _id setMarkerPos _pos;
    _id setMarkerShape "ICON";
    _id setMarkerType "hd_destroy";
    _id setMarkerSize [0.7, 0.7];
    _id setMarkerAlpha 0.85;

    private _winnerLabel = "EAST";
    private _color = "ColorWhite";
    if (_winner isEqualTo east) then {
        _color = "ColorEAST";
    };
    if (_winner isEqualTo west) then {
        _winnerLabel = "WEST";
        _color = "ColorWEST";
    };

    _id setMarkerColor _color;
    _id setMarkerText format [
        "GTN %1 m%2 | E%3 W%4",
        _winnerLabel,
        _margin,
        _eastAfter,
        _westAfter
    ];

    FLO_GTN_CombatDebugMarkers set [_id, diag_tickTime + _markerTTL];

    private _order = FLO_GTN_CombatDebugMarkerOrder;
    private _existingIdx = _order find _id;
    if (_existingIdx >= 0) then {
        _order deleteAt _existingIdx;
    };
    _order pushBack _id;

    FLO_GTN_CombatDebugMarkerOrder = _order;
};

private _fnc_cleanupCombatMarkers = {
    if (!FLO_GTN_CombatDebugEnabled) exitWith {
        {
            deleteMarker _x;
        } forEach (keys FLO_GTN_CombatDebugMarkers);
        FLO_GTN_CombatDebugMarkers = createHashMap;
        FLO_GTN_CombatDebugMarkerOrder = [];
    };

    private _now = diag_tickTime;
    private _expired = [];
    {
        private _markerId = _x;
        private _expiresAt = FLO_GTN_CombatDebugMarkers get _markerId;
        if (_expiresAt <= _now) then {
            _expired pushBack _markerId;
        };
    } forEach (keys FLO_GTN_CombatDebugMarkers);

    private _order = FLO_GTN_CombatDebugMarkerOrder;
    {
        deleteMarker _x;
        FLO_GTN_CombatDebugMarkers deleteAt _x;
        private _idx = _order find _x;
        if (_idx >= 0) then {
            _order deleteAt _idx;
        };
    } forEach _expired;

    FLO_GTN_CombatDebugMarkerOrder = _order;
};

[ _interval, _fnc_sideKey, _fnc_typeWeight, _fnc_sidePower, _fnc_supportBonus, _fnc_applyAttrition, _fnc_markerId, _fnc_recordCombatEvent, _fnc_updateCombatMarker, _fnc_cleanupCombatMarkers, _combatMarkerTTL ] spawn {
    params [
        "_interval",
        "_fnc_sideKey",
        "_fnc_typeWeight",
        "_fnc_sidePower",
        "_fnc_supportBonus",
        "_fnc_applyAttrition",
        "_fnc_markerId",
        "_fnc_recordCombatEvent",
        "_fnc_updateCombatMarker",
        "_fnc_cleanupCombatMarkers",
        "_combatMarkerTTL"
    ];

    waitUntil {
        sleep 0.5;
        !isNil "FLO_virtualGroups"
    };

    while {FLO_GTN_VirtualCombatRunning} do {
        private _groups = FLO_virtualGroups get "_groups";
        if (count _groups == 0) then {
            sleep _interval;
            continue;
        };

        private _eventsChanged = false;
        private _eastPool = [];
        private _westPool = [];

        {
            private _groupId = _x;
            private _gData = _groups get _groupId;
            if (_gData get "isActive") then { continue };

            private _side = _gData get "side";
            if (_side isEqualTo east) then { _eastPool pushBack [_groupId, _gData]; };
            if (_side isEqualTo west) then { _westPool pushBack [_groupId, _gData]; };
        } forEach (keys _groups);

        if ((count _eastPool) == 0 || {(count _westPool) == 0}) then {
            [] call _fnc_cleanupCombatMarkers;
            sleep _interval;
            continue;
        };

        private _engagementMaxDist = 400;
        private _usedWest = createHashMap;
        private _engagements = [];

        {
            _x params ["_eastId", "_eastData"];
            private _eastPos = _eastData get "position";
            private _bestWest = [];
            private _bestDist = 1000000000;

            {
                _x params ["_westId", "_westData"];
                if (_usedWest getOrDefault [_westId, false]) then { continue };

                private _westPos = _westData get "position";
                private _dist = _eastPos distance2D _westPos;
                if (_dist < _bestDist) then {
                    _bestDist = _dist;
                    _bestWest = [_westId, _westData, _westPos];
                };
            } forEach _westPool;

            if ((count _bestWest) > 0 && {_bestDist <= _engagementMaxDist}) then {
                _usedWest set [_bestWest select 0, true];
                _engagements pushBack [
                    _eastId,
                    _eastData,
                    _eastPos,
                    _bestWest select 0,
                    _bestWest select 1,
                    _bestWest select 2,
                    _bestDist
                ];
            };
        } forEach _eastPool;

        {
            _x params ["_eastId", "_eastData", "_eastPos", "_westId", "_westData", "_westPos", "_engageDist"];

            private _eastRefs = [[_eastId, _eastData]];
            private _westRefs = [[_westId, _westData]];

            private _eastStats = [_eastRefs] call _fnc_sidePower;
            private _westStats = [_westRefs] call _fnc_sidePower;

            private _eastBefore = _eastStats get "units";
            private _westBefore = _westStats get "units";
            private _eastPower = _eastStats get "power";
            private _westPower = _westStats get "power";
            if (_eastPower <= 0 || {_westPower <= 0}) then { continue };

            private _ratioEW = _eastPower / (_westPower max 1);
            private _ratioWE = _westPower / (_eastPower max 1);
            private _ratioModEast = round (((( _ratioEW - 1) * 2) max -2) min 2);
            private _ratioModWest = round (((( _ratioWE - 1) * 2) max -2) min 2);

            private _armorInfEast = if ((_eastStats get "armor") > 0 && {(_westStats get "infantry") > 0}) then { 1 } else { 0 };
            private _armorInfWest = if ((_westStats get "armor") > 0 && {(_eastStats get "infantry") > 0}) then { 1 } else { 0 };

            private _infOverEast = if ((_westStats get "armor") > 0 && {(_eastStats get "infantry") >= ((_westStats get "armor") * 4)}) then { 1 } else { 0 };
            private _infOverWest = if ((_eastStats get "armor") > 0 && {(_westStats get "infantry") >= ((_eastStats get "armor") * 4)}) then { 1 } else { 0 };

            private _supportEast = [east, _groups] call _fnc_supportBonus;
            private _supportWest = [west, _groups] call _fnc_supportBonus;

            private _modEast = _ratioModEast + _armorInfEast + _infOverEast + (_supportEast get "total");
            private _modWest = _ratioModWest + _armorInfWest + _infOverWest + (_supportWest get "total");

            if (_modEast > 4) then { _modEast = 4 };
            if (_modEast < -4) then { _modEast = -4 };
            if (_modWest > 4) then { _modWest = 4 };
            if (_modWest < -4) then { _modWest = -4 };

            private _rollEast = (1 + floor random 6) + (1 + floor random 6) + _modEast;
            private _rollWest = (1 + floor random 6) + (1 + floor random 6) + _modWest;

            private _winner = sideUnknown;
            private _margin = 0;
            private _eastAfter = _eastBefore;
            private _westAfter = _westBefore;

            if (_rollEast != _rollWest) then {
                _winner = if (_rollEast > _rollWest) then { east } else { west };
                _margin = abs (_rollEast - _rollWest);

                private _lossPct = ((0.06 * _margin) max 0.05) min 0.35;
                private _winnerLossPct = ((0.02 * _margin) max 0.01) min 0.12;

                if (_winner isEqualTo east) then {
                    [_groups, _westRefs, _lossPct] call _fnc_applyAttrition;
                    [_groups, _eastRefs, _winnerLossPct] call _fnc_applyAttrition;
                } else {
                    [_groups, _eastRefs, _lossPct] call _fnc_applyAttrition;
                    [_groups, _westRefs, _winnerLossPct] call _fnc_applyAttrition;
                };

                private _eastAfterStats = [_eastRefs] call _fnc_sidePower;
                private _westAfterStats = [_westRefs] call _fnc_sidePower;
                _eastAfter = _eastAfterStats get "units";
                _westAfter = _westAfterStats get "units";
            };

            private _engagementId = format ["%1_vs_%2", _eastId, _westId];
            private _engagementName = format ["%1 vs %2", _eastId, _westId];
            private _eventPos = [
                ((_eastPos select 0) + (_westPos select 0)) * 0.5,
                ((_eastPos select 1) + (_westPos select 1)) * 0.5,
                0
            ];

            private _event = [
                _engagementId,
                _engagementName,
                _eventPos,
                _winner,
                _margin,
                _rollEast,
                _rollWest,
                _modEast,
                _modWest,
                _eastBefore,
                _eastAfter,
                _westBefore,
                _westAfter
            ] call _fnc_recordCombatEvent;
            _eventsChanged = true;

            [_event, _fnc_markerId, _combatMarkerTTL] call _fnc_updateCombatMarker;

            ["GTN_COMBAT", 3, format["%1 resolved at %2m: EAST %3 (mod %4) WEST %5 (mod %6) winner=%7 margin=%8 E %9->%10 W %11->%12",
                _engagementId,
                round _engageDist,
                _rollEast,
                _modEast,
                _rollWest,
                _modWest,
                _winner,
                _margin,
                _eastBefore,
                _eastAfter,
                _westBefore,
                _westAfter
            ]] call FLO_fnc_log;
        } forEach _engagements;

        [] call _fnc_cleanupCombatMarkers;
        if (_eventsChanged) then {
            publicVariable "FLO_GTN_CombatEvents";
            publicVariable "FLO_GTN_CombatLastByObjective";
        };

        sleep _interval;
    };
};

["GTN_COMBAT", 2, format["Virtual combat resolver started (%1s interval)", _interval]] call FLO_fnc_log;

true
