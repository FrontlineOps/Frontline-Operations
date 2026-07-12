/*
 * Function: FLO_fnc_gtnVirtualCombatResolver
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves virtual combat as contact zones built from the shared virtualization
 *   spatial index. Combat is treated as an overlay on top of existing commander
 *   orders instead of rewriting task ownership. Zones near players are handed
 *   off to real AI; remote zones use power-led momentum, deterministic
 *   attrition, and combat telemetry.
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

call FLO_fnc_gtnCombatRegisterVirtualizationEvents;

FLO_GTN_VirtualCombatRunning = true;
if (isNil "FLO_GTN_VirtualCombatPFH") then { FLO_GTN_VirtualCombatPFH = -1; };
if (isNil "FLO_GTN_VirtualCombatResumeStates") then { FLO_GTN_VirtualCombatResumeStates = createHashMap; };

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

    if (isNil "FLO_VirtualForceRegistry") exitWith {};

    private _cycleStart = diag_tickTime;
    private _groups = call FLO_fnc_virtualizationGetGroupMap;
    private _groupCount = count _groups;
    private _resumeStates = FLO_GTN_VirtualCombatResumeStates;

    private _phaseStartedAt = diag_tickTime;
    [_groups, _resumeStates] call FLO_fnc_gtnCombatCleanupResumeStates;
    private _resumeCleanupMs = (diag_tickTime - _phaseStartedAt) * 1000;

    if (_groupCount == 0) exitWith {
        call FLO_fnc_gtnCombatCleanupMarkers;
    };

    private _combatState = call FLO_fnc_gtnCombatGetState;
    private _classificationBuiltAtBefore = _combatState get "classificationBuiltAt";
    _phaseStartedAt = diag_tickTime;
    private _classification = [_groups, _engagementMaxDist * 0.5, _engagementMaxDist] call FLO_fnc_gtnCombatGetClassification;
    private _classificationMs = (diag_tickTime - _phaseStartedAt) * 1000;
    private _classificationRebuilt = (_combatState get "classificationBuiltAt") != _classificationBuiltAtBefore;
    private _combatGroups = _classification get "combatGroups";
    private _combatGroupCount = count _combatGroups;
    private _supportAvailability = _classification get "supportAvailability";
    _phaseStartedAt = diag_tickTime;
    private _zones = [_classification] call FLO_fnc_gtnCombatGetZones;
    private _zoneBuildMs = (diag_tickTime - _phaseStartedAt) * 1000;
    private _engagedNow = createHashMap;
    private _activeZoneIds = [];
    private _liveAreaRadius = ["activationDistance"] call FLO_fnc_virtualizationGetConfigValue;

    _phaseStartedAt = diag_tickTime;
    {
        _x params ["_eastRefs", "_westRefs", "_zonePos", "_contactDist"];

        {
            _x params ["_groupId", "_gData"];
            _engagedNow set [_groupId, true];
            [_groupId, _gData, _resumeStates] call FLO_fnc_gtnCombatEnterState;
        } forEach (_eastRefs + _westRefs);

        private _liveArea = [_zonePos, _liveAreaRadius] call FLO_fnc_gtnCombatIsLiveArea;
        if (_liveArea) then {
            private _activationDemand = 0;
            private _activeRefs = [];
            {
                _x params ["_groupId", "_gData"];
                if (_gData get "isActive") then {
                    _activeRefs pushBack _x;
                } else {
                    _activationDemand = _activationDemand + ([_gData, true] call FLO_fnc_virtualizationGetGroupUnitLoad);
                };
            } forEach (_eastRefs + _westRefs);

            if ((_activationDemand + (FLO_VirtUpdate get "activeUnitCount")) <= (["activationUnitCap"] call FLO_fnc_virtualizationGetConfigValue)) then {
                {
                    _x params ["_groupId", "_gData"];
                    if !(_gData get "isActive") then {
                        if !([_groupId] call FLO_fnc_virtualizationTryActivateGroup) then {
                            continue;
                        };
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

            {
                [_x select 1] call FLO_fnc_gtnCombatPrepareRealGroupForCombat;
            } forEach _activeRefs;

            ["GTN_COMBAT", 3, format [
                "Live combat near %1m could not fully hand off: demand=%2 activeUnits=%3 cap=%4 activeGroups=%5 - skipping virtual resolution",
                round _contactDist,
                _activationDemand,
                FLO_VirtUpdate get "activeUnitCount",
                ["activationUnitCap"] call FLO_fnc_virtualizationGetConfigValue,
                count _activeRefs
            ]] call FLO_fnc_log;
            continue;
        };

        private _descriptor = [_zonePos, _eastRefs, _westRefs] call FLO_fnc_gtnCombatResolveZoneDescriptor;
        _descriptor params ["_zoneId", "_zoneName"];
        _activeZoneIds pushBackUnique _zoneId;
        private _outcome = [
            _groups,
            _eastRefs,
            _westRefs,
            _supportAvailability,
            _zoneId
        ] call FLO_fnc_gtnCombatResolveRemoteEngagement;
        private _artillerySide = [
            _zoneId,
            _zonePos,
            _eastRefs,
            _westRefs,
            _supportAvailability,
            _outcome
        ] call FLO_fnc_gtnCombatRequestStalemateArtillery;
        _outcome set ["artilleryRequestedBy", _artillerySide];

        private _event = [
            _zoneId,
            _zoneName,
            _zonePos,
            _outcome,
            count _eastRefs,
            count _westRefs
        ] call FLO_fnc_gtnCombatRecordEvent;

        [_event, _combatMarkerTTL] call FLO_fnc_gtnCombatUpdateMarker;

        ["GTN_COMBAT", 3, format [
            "%1 round %2 at %3m: E power=%4 W power=%5 momentum=%6 winner=%7 decisive=%8 E %9->%10 W %11->%12 artillery=%13",
            _zoneId,
            _outcome get "roundCount",
            round _contactDist,
            round (_outcome get "eastEffectivePower"),
            round (_outcome get "westEffectivePower"),
            round (_outcome get "momentum"),
            _outcome get "winner",
            _outcome get "decisive",
            _outcome get "eastBefore",
            _outcome get "eastAfter",
            _outcome get "westBefore",
            _outcome get "westAfter",
            _artillerySide
        ]] call FLO_fnc_log;
    } forEach _zones;
    private _resolutionMs = (diag_tickTime - _phaseStartedAt) * 1000;

    _phaseStartedAt = diag_tickTime;
    [_activeZoneIds] call FLO_fnc_gtnCombatCleanupEngagementStates;

    {
        private _groupId = _x;
        private _gData = _groups get _groupId;

        if (_engagedNow getOrDefault [_groupId, false]) then { continue };

        [_groupId, _gData, _resumeStates] call FLO_fnc_gtnCombatExitState;
        ["GTN_COMBAT", 3, format ["Group %1 disengaged and resumed %2", _groupId, [_gData] call FLO_fnc_virtualizationGetEffectiveState]] call FLO_fnc_log;
    } forEach (keys _resumeStates);
    private _disengagementMs = (diag_tickTime - _phaseStartedAt) * 1000;

    _phaseStartedAt = diag_tickTime;
    call FLO_fnc_gtnCombatCleanupMarkers;
    private _markerCleanupMs = (diag_tickTime - _phaseStartedAt) * 1000;

    private _dt = diag_tickTime - _cycleStart;
    if (_dt > _perfLogThreshold) then {
        diag_log format [
            "[FLO][PERF] GTN virtual combat zones=%1 combatGroups=%2 totalGroups=%3 total=%4ms | resume=%5 classify=%6 rebuilt=%7 zones=%8 resolve=%9 disengage=%10 markers=%11",
            count _zones,
            _combatGroupCount,
            _groupCount,
            _dt * 1000,
            _resumeCleanupMs,
            _classificationMs,
            _classificationRebuilt,
            _zoneBuildMs,
            _resolutionMs,
            _disengagementMs,
            _markerCleanupMs
        ];
    };
}, _interval, [_combatMarkerTTL, _engagementMaxDist, _perfLogThreshold]] call CBA_fnc_addPerFrameHandler;

FLO_GTN_VirtualCombatPFH = _pfhId;

["GTN_COMBAT", 2, format ["Virtual combat resolver started (%1s interval, PFH)", _interval]] call FLO_fnc_log;

true
