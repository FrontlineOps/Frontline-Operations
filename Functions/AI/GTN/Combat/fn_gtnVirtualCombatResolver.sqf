/*
 * Function: FLO_fnc_gtnVirtualCombatResolver
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves virtual combat as contact zones built from the shared virtualization
 *   spatial index. Combat is treated as an overlay on top of existing commander
 *   orders instead of rewriting task ownership. Zones near players are handed
 *   off to real AI; remote zones stay virtual and use attrition rolls plus
 *   combat telemetry.
 *
 * Arguments:
 *   0: Tick interval in seconds <NUMBER> - Default 20
 *
 * Return Value:
 *   BOOL - true when resolver PFH started
 */

if (!isServer) exitWith { false };

params [["_interval", 20, [0]]];
if (_interval < 5) then { _interval = 5 };

if (!isNil "FLO_GTN_VirtualCombatRunning" && {FLO_GTN_VirtualCombatRunning}) exitWith { true };

FLO_GTN_VirtualCombatRunning = true;
if (isNil "FLO_GTN_VirtualCombatPFH") then { FLO_GTN_VirtualCombatPFH = -1; };
if (isNil "FLO_GTN_VirtualCombatResumeStates") then { FLO_GTN_VirtualCombatResumeStates = createHashMap; };

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
private _engagementMaxDist = 300;
private _perfLogThreshold = 0.05;

private _pfhId = [{
    params ["_args", "_pfhId"];
    _args params ["_combatMarkerTTL", "_engagementMaxDist", "_perfLogThreshold"];

    if (!FLO_GTN_VirtualCombatRunning) exitWith {
        [_pfhId] call CBA_fnc_removePerFrameHandler;
        FLO_GTN_VirtualCombatPFH = -1;
        ["GTN_COMBAT", 3, "Virtual combat resolver stopped"] call FLO_fnc_log;
    };

    if (isNil "FLO_virtualGroups") exitWith {};

    private _cycleStart = diag_tickTime;
    private _groups = FLO_virtualGroups get "_groups";
    private _groupCount = count _groups;
    private _resumeStates = FLO_GTN_VirtualCombatResumeStates;

    [_groups, _resumeStates] call FLO_fnc_gtnCombatCleanupResumeStates;

    if (_groupCount == 0) exitWith {
        call FLO_fnc_gtnCombatCleanupMarkers;
    };

    private _classification = [_groups, _engagementMaxDist * 0.5, _engagementMaxDist] call FLO_fnc_gtnCombatGetClassification;
    private _combatGroups = _classification get "combatGroups";
    private _combatGroupCount = count _combatGroups;
    private _seedIds = _classification get "seedIds";
    private _seedSide = _classification get "seedSide";
    private _opponentSide = _classification get "opponentSide";
    private _seedCellSize = _classification get "seedCellSize";
    private _opponentThreatCells = if (_seedSide isEqualTo east) then { _classification get "westThreatCells" } else { _classification get "eastThreatCells" };
    private _supportAvailability = _classification get "supportAvailability";
    private _zones = [
        _combatGroups,
        _seedIds,
        _seedSide,
        _opponentSide,
        _engagementMaxDist,
        _seedCellSize,
        _opponentThreatCells
    ] call FLO_fnc_gtnCombatCollectEngagementZones;
    private _engagedNow = createHashMap;
    private _eventsChanged = false;
    private _liveAreaRadius = FLO_virtualGroups get "_activationDistance";

    {
        _x params ["_eastRefs", "_westRefs", "_zonePos", "_contactDist"];

        {
            _x params ["_groupId", "_gData"];
            _engagedNow set [_groupId, true];
            [_groupId, _gData, _resumeStates] call FLO_fnc_gtnCombatEnterState;
        } forEach (_eastRefs + _westRefs);

        private _liveArea = [_zonePos, _liveAreaRadius] call FLO_fnc_gtnCombatIsLiveArea;
        if (_liveArea) then {
            {
                _x params ["_groupId", "_gData"];
                if !(_gData get "isActive") then {
                    [_groupId, _gData] call FLO_fnc_activateVirtualGroup;
                };
                [_gData] call FLO_fnc_gtnCombatPrepareRealGroupForCombat;
            } forEach (_eastRefs + _westRefs);

            ["GTN_COMBAT", 3, format [
                "Live combat handoff near %1m for %2 EAST groups vs %3 WEST groups",
                round _contactDist,
                count _eastRefs,
                count _westRefs
            ]] call FLO_fnc_log;
            continue;
        };

        private _eastStats = [_eastRefs] call FLO_fnc_gtnCombatSidePower;
        private _westStats = [_westRefs] call FLO_fnc_gtnCombatSidePower;
        private _eastBefore = _eastStats get "units";
        private _westBefore = _westStats get "units";
        private _eastPower = _eastStats get "power";
        private _westPower = _westStats get "power";

        if (_eastPower <= 0 || {_westPower <= 0}) then { continue };

        private _ratioEW = _eastPower / (_westPower max 1);
        private _ratioWE = _westPower / (_eastPower max 1);
        private _ratioModEast = round ((((_ratioEW - 1) * 2) max -2) min 2);
        private _ratioModWest = round ((((_ratioWE - 1) * 2) max -2) min 2);
        private _armorInfEast = if ((_eastStats get "armor") > 0 && {(_westStats get "infantry") > 0}) then { 1 } else { 0 };
        private _armorInfWest = if ((_westStats get "armor") > 0 && {(_eastStats get "infantry") > 0}) then { 1 } else { 0 };
        private _infOverEast = if ((_westStats get "armor") > 0 && {(_eastStats get "infantry") >= ((_westStats get "armor") * 4)}) then { 1 } else { 0 };
        private _infOverWest = if ((_eastStats get "armor") > 0 && {(_westStats get "infantry") >= ((_eastStats get "armor") * 4)}) then { 1 } else { 0 };
        private _supportEast = [east, _supportAvailability] call FLO_fnc_gtnCombatSupportBonus;
        private _supportWest = [west, _supportAvailability] call FLO_fnc_gtnCombatSupportBonus;
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

            private _loserLossPct = ((0.06 * _margin) max 0.05) min 0.35;
            private _winnerLossPct = ((0.02 * _margin) max 0.01) min 0.12;

            if (_winner isEqualTo east) then {
                [_groups, _westRefs, _loserLossPct] call FLO_fnc_gtnCombatApplyAttrition;
                [_groups, _eastRefs, _winnerLossPct] call FLO_fnc_gtnCombatApplyAttrition;
            } else {
                [_groups, _eastRefs, _loserLossPct] call FLO_fnc_gtnCombatApplyAttrition;
                [_groups, _westRefs, _winnerLossPct] call FLO_fnc_gtnCombatApplyAttrition;
            };

            private _eastAfterStats = [_eastRefs] call FLO_fnc_gtnCombatSidePower;
            private _westAfterStats = [_westRefs] call FLO_fnc_gtnCombatSidePower;
            _eastAfter = _eastAfterStats get "units";
            _westAfter = _westAfterStats get "units";
        };

        private _descriptor = [_zonePos, _eastRefs, _westRefs] call FLO_fnc_gtnCombatResolveZoneDescriptor;
        _descriptor params ["_zoneId", "_zoneName"];

        private _event = [
            _zoneId,
            _zoneName,
            _zonePos,
            _winner,
            _margin,
            _rollEast,
            _rollWest,
            _modEast,
            _modWest,
            _eastBefore,
            _eastAfter,
            _westBefore,
            _westAfter,
            count _eastRefs,
            count _westRefs
        ] call FLO_fnc_gtnCombatRecordEvent;
        _eventsChanged = true;

        [_event, _combatMarkerTTL] call FLO_fnc_gtnCombatUpdateMarker;

        ["GTN_COMBAT", 3, format [
            "%1 resolved at %2m: EAST %3 (mod %4) WEST %5 (mod %6) winner=%7 margin=%8 E %9->%10 W %11->%12",
            _zoneId,
            round _contactDist,
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
    } forEach _zones;

    {
        private _groupId = _x;
        private _gData = _groups get _groupId;

        if !(_gData get "inCombat") then { continue };
        if (_engagedNow getOrDefault [_groupId, false]) then { continue };

        [_groupId, _gData, _resumeStates] call FLO_fnc_gtnCombatExitState;
        ["GTN_COMBAT", 3, format ["Group %1 disengaged and resumed %2", _groupId, [_gData] call FLO_fnc_virtualizationGetEffectiveState]] call FLO_fnc_log;
    } forEach (keys _groups);

    call FLO_fnc_gtnCombatCleanupMarkers;

    if (_eventsChanged) then {
        publicVariable "FLO_GTN_CombatEvents";
        publicVariable "FLO_GTN_CombatLastByObjective";
    };

    private _dt = diag_tickTime - _cycleStart;
    if (_dt > _perfLogThreshold) then {
        diag_log format [
            "[FLO][PERF] GTN virtual combat processed %1 zones across %2 combat groups (%3 total) in %4 ms",
            count _zones,
            _combatGroupCount,
            _groupCount,
            _dt * 1000
        ];
    };
}, _interval, [_combatMarkerTTL, _engagementMaxDist, _perfLogThreshold]] call CBA_fnc_addPerFrameHandler;

FLO_GTN_VirtualCombatPFH = _pfhId;

["GTN_COMBAT", 2, format ["Virtual combat resolver started (%1s interval, PFH)", _interval]] call FLO_fnc_log;

true
