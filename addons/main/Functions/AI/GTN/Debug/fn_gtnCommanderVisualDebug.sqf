/*
 * Function: FLO_fnc_gtnCommanderVisualDebug
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-side visual debug for dual GTN commanders.
 *   Draws live markers for commander status, track status, target objectives,
 *   and currently tasked virtual groups.
 *
 * Arguments:
 *   0: Update interval (seconds) <NUMBER> - Default 5
 *
 * Return Value:
 *   BOOL - true when debug loop started
 */

if (!isServer) exitWith { false };

params [["_interval", 5, [0]]];
if (_interval < 1) then { _interval = 1 };

if (!isNil "FLO_GTN_CommanderDebugRunning" && {FLO_GTN_CommanderDebugRunning}) exitWith { true };
FLO_GTN_CommanderDebugRunning = true;

if (isNil "FLO_GTN_CommanderDebugEnabled") then { FLO_GTN_CommanderDebugEnabled = true; };
if (isNil "FLO_GTN_CommanderDebugMarkers") then { FLO_GTN_CommanderDebugMarkers = createHashMap; };

[_interval] spawn {
    params ["_interval"];

    waitUntil {
        sleep 1;
        !isNil "FLO_GTN_ResourceManager" && {!isNil "FLO_VirtualForceRegistry"}
    };

    while {FLO_GTN_CommanderDebugRunning} do {
        if (!FLO_GTN_CommanderDebugEnabled) then {
            [] call FLO_fnc_gtnCommanderDebugClearAll;
            sleep _interval;
            continue;
        };

        if (isNil "FLO_GTN_ResourceManager") then {
            sleep _interval;
            continue;
        };

        private _activeIds = [];
        private _commandersBySide = FLO_GTN_ResourceManager call ["_getAllCommanders", []];
        private _allGroups = call FLO_fnc_virtualizationGetGroupMap;

        {
            private _cmdSideKey = _x;
            private _cmd = _commandersBySide get _cmdSideKey;
            if (isNil "_cmd") then { continue };

            private _ownSide = _cmd get "_ownSide";
            private _enemySide = _cmd get "_enemySide";
            private _ownColor = [_ownSide] call FLO_fnc_gtnCommanderDebugSideColor;
            private _enemyColor = [_enemySide] call FLO_fnc_gtnCommanderDebugSideColor;
            private _enemyLabel = [_enemySide] call FLO_fnc_gtnCommanderDebugSideLabel;

            private _worldState = _cmd get "_worldState";
            private _forces = _worldState call ["_getForces", []];
            private _situation = _worldState call ["_getTacticalSituation", []];
            private _friendlyObjectives = _worldState call ["_getFriendlyObjectives", []];
            private _enemyObjectivesAll = _worldState call ["_getEnemyObjectives", []];
            private _strictFrontlineEnemyObjectives = _worldState call ["_getFrontlineEnemyObjectives", []];
            private _enemyObjectives = _cmd call ["_getAttackFrontlineEnemyObjectives", []];

            private _stats = _cmd get "_stats";
            private _tracks = _cmd get "_tracks";
            private _taskedGroups = _cmd get "_gtnTaskedGroups";

            private _anchorPos = [worldSize * 0.5, worldSize * 0.5, 0];
            private _bestObj = "";
            private _bestPriority = -1;
            {
                private _obj = _friendlyObjectives get _x;
                private _priority = _obj get "priority";
                if (_priority > _bestPriority) then {
                    _bestPriority = _priority;
                    _bestObj = _x;
                };
            } forEach (keys _friendlyObjectives);
            if (_bestObj != "") then {
                _anchorPos = [_bestObj] call FLO_fnc_getObjectivePosition;
            };

            if (_ownSide isEqualTo east) then {
                _anchorPos = _anchorPos vectorAdd [300, 300, 0];
            } else {
                _anchorPos = _anchorPos vectorAdd [-300, -300, 0];
            };

            private _summaryId = format ["FLO_GTN_DBG_%1_SUMMARY", _cmdSideKey];
            _activeIds pushBack _summaryId;
            private _summaryText = format [
                "GTN %1 | cyc:%2 tasked:%3 avail:%4 atk:%5 def:%6 enemyObj:%7 atkFront:%8 strictFront:%9 mom:%10",
                _cmdSideKey,
                _stats get "cyclesRun",
                count _taskedGroups,
                _forces get "availableGroups",
                _forces get "attackingGroups",
                _forces get "defendingGroups",
                count (keys _enemyObjectivesAll),
                count (keys _enemyObjectives),
                count (keys _strictFrontlineEnemyObjectives),
                round (_situation get "momentum")
            ];
            [_summaryId, _anchorPos, "mil_flag", _ownColor, _summaryText, [0.95, 0.95], 1] call FLO_fnc_gtnCommanderDebugUpsertMarker;

            {
                private _track = _x;
                private _trackId = _track get "id";
                private _planner = _track get "planner";
                private _planStatus = if (!isNil "_planner") then { _planner call ["_getPlanStatus", []] } else { "NO_PLAN" };
                private _taskId = "-";

                if (!isNil "_planner") then {
                    private _task = _planner call ["_getCurrentTask", []];
                    if (!isNil "_task") then {
                        _taskId = _task get "taskId";
                    };
                };

                private _trackPos = _anchorPos vectorAdd [0, 70 + (55 * _forEachIndex), 0];
                private _trackMarkerId = format ["FLO_GTN_DBG_%1_TRACK_%2", _cmdSideKey, _trackId];
                _activeIds pushBack _trackMarkerId;
                private _trackText = format [
                    "%1 %2 | goal:%3 | status:%4 | plan:%5 | task:%6 | pool:%7",
                    _cmdSideKey,
                    _trackId,
                    _track get "goal",
                    _track get "status",
                    _planStatus,
                    _taskId,
                    count (_track get "groupPool")
                ];
                [_trackMarkerId, _trackPos, "mil_dot", _ownColor, _trackText, [0.65, 0.65], 0.95] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            } forEach _tracks;

            private _enemyObjectiveRows = [];
            {
                private _objId = _x;
                private _obj = _enemyObjectives get _objId;
                _enemyObjectiveRows pushBack [_objId, _obj get "priority", _obj];
            } forEach (keys _enemyObjectives);
            private _enemyObjectiveRanked = _enemyObjectiveRows apply { [_x select 1, _x] };
            _enemyObjectiveRanked sort false;
            _enemyObjectiveRows = _enemyObjectiveRanked apply { _x select 1 };

            private _maxTargetDebug = (count _enemyObjectiveRows) min 5;
            for "_i" from 0 to (_maxTargetDebug - 1) do {
                private _row = _enemyObjectiveRows select _i;
                _row params ["_objId", "_priority", "_obj"];

                private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
                private _objMarkerId = format ["FLO_GTN_DBG_%1_TARGET_%2", _cmdSideKey, _objId];
                _activeIds pushBack _objMarkerId;

                private _ratio = _obj get "forceRatio";
                private _ratioRounded = round (_ratio * 10) / 10;
                private _globalObj = FLO_Objectives get _objId;
                private _owner = _globalObj get "owner";
                if (_owner isEqualType "") then {
                    private _ownerKey = toUpper _owner;
                    if (_ownerKey isEqualTo "EAST") then { _owner = east; };
                    if (_ownerKey isEqualTo "WEST") then { _owner = west; };
                };
                private _ownerLabel = [_owner] call FLO_fnc_gtnCommanderDebugSideLabel;
                private _wrongOwner = (_owner isNotEqualTo _enemySide);
                private _objType = [["mil_objective", "mil_warning"] select (_obj get "contested"), "mil_unknown"] select (_wrongOwner);
                private _objColor = [_enemyColor, "ColorOrange"] select (_wrongOwner);
                private _objText = format [
                    "%1 TGT %2 | P:%3 F:%4 E:%5 R:%6 OWN:%7%8",
                    _cmdSideKey,
                    _objId,
                    _priority,
                    _obj get "friendlyCount",
                    _obj get "enemyCount",
                    _ratioRounded,
                    _ownerLabel,
                    if (_wrongOwner) then { format [" ! expected %1", _enemyLabel] } else { "" }
                ];

                [_objMarkerId, _objPos, _objType, _objColor, _objText, [0.7, 0.7], 0.85] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            };

            // Reinforcement debug: pressure points, in-flight groups, and inbound targets.
            private _detectRange = 2000;
            private _logNetwork = nil;
            if (!isNil "FLO_Logistics_Networks" && {FLO_Logistics_Networks isEqualType createHashMap}) then {
                _logNetwork = FLO_Logistics_Networks getOrDefault [_cmdSideKey, nil];
            };
            if (!isNil "_logNetwork") then {
                _detectRange = _logNetwork get "BLUFOR_DETECT_RANGE";
            };

            private _reinforcementPointRows = [];
            {
                private _objId = _x;
                private _objData = _friendlyObjectives get _objId;
                private _objPos = _objData get "position";
                private _enemyPressure = { side _x == _enemySide && {_x distance2D _objPos < _detectRange} } count allPlayers;
                if (_enemyPressure > 0) then {
                    _reinforcementPointRows pushBack [_objId, _enemyPressure, _objData get "priority", _objPos];
                };
            } forEach (keys _friendlyObjectives);
            private _reinforcementRanked = _reinforcementPointRows apply { [((_x select 1) * 100 + (_x select 2)), _x] };
            _reinforcementRanked sort false;
            _reinforcementPointRows = _reinforcementRanked apply { _x select 1 };

            private _maxReinfPointDebug = (count _reinforcementPointRows) min 8;
            for "_i" from 0 to (_maxReinfPointDebug - 1) do {
                private _row = _reinforcementPointRows select _i;
                _row params ["_objId", "_enemyPressure", "_priority", "_objPos"];

                private _reinfPointMarkerId = format ["FLO_GTN_DBG_%1_REINF_PT_%2", _cmdSideKey, _objId];
                _activeIds pushBack _reinfPointMarkerId;
                private _reinfPointText = format [
                    "%1 REINF PT %2 | pressure:%3 prio:%4",
                    _cmdSideKey,
                    _objId,
                    _enemyPressure,
                    _priority
                ];
                [_reinfPointMarkerId, _objPos, "mil_marker", _ownColor, _reinfPointText, [0.65, 0.65], 0.75] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            };

            if (!isNil "_logNetwork") then {
                private _lastReinfTarget = _logNetwork get "_lastReinforcementTarget";
                if (_lastReinfTarget != "" && {_lastReinfTarget in FLO_Objectives}) then {
                    private _lastTargetPos = (FLO_Objectives get _lastReinfTarget) get "position";
                    private _lastMarkerId = format ["FLO_GTN_DBG_%1_REINF_LAST", _cmdSideKey];
                    _activeIds pushBack _lastMarkerId;
                    [_lastMarkerId, _lastTargetPos, "mil_objective", _ownColor, format ["%1 LOGI LAST %2", _cmdSideKey, _lastReinfTarget], [0.8, 0.8], 0.9] call FLO_fnc_gtnCommanderDebugUpsertMarker;
                };
            };

            private _reinforcingObjectiveCounts = createHashMap;
            {
                private _groupId = _x;
                private _gData = _allGroups get _groupId;
                if (isNil "_gData") then { continue };
                if ((_gData get "side") != _ownSide) then { continue };

                private _isReinforcing = (_gData get "replacementState") == "REINFORCE";
                private _isAAMoving = (_gData get "replacementState") == "AA_DEPLOY";
                if !(_isReinforcing || _isAAMoving) then { continue };

                private _groupPos = _gData get "position";
                private _groupType = _gData get "groupType";
                private _groupUnits = _gData get "unitCount";
                private _targetObjective = if (_isAAMoving) then {
                    [_gData] call FLO_fnc_virtualizationGetAATargetObjective
                } else {
                    _gData get "homeObjective"
                };

                private _reinfGroupMarkerId = format ["FLO_GTN_DBG_%1_REINF_GROUP_%2", _cmdSideKey, _groupId];
                _activeIds pushBack _reinfGroupMarkerId;
                private _reinfGroupText = format [
                    "%1 REINF %2 u%3 %4 -> %5",
                    _cmdSideKey,
                    _groupId,
                    _groupUnits,
                    _groupType,
                    [_targetObjective, "free"] select (_targetObjective == "")
                ];
                [_reinfGroupMarkerId, _groupPos, ["mil_arrow", "mil_warning"] select (_isAAMoving), _ownColor, _reinfGroupText, [0.55, 0.55], 0.95] call FLO_fnc_gtnCommanderDebugUpsertMarker;

                if (_targetObjective != "" && {_targetObjective in FLO_Objectives}) then {
                    _reinforcingObjectiveCounts set [_targetObjective, (_reinforcingObjectiveCounts getOrDefault [_targetObjective, 0]) + 1];
                } else {
                    if (_isAAMoving) then {
                        private _targetPos = [_gData] call FLO_fnc_virtualizationGetAATargetPos;
                        if (count _targetPos >= 2) then {
                            private _aaTargetMarkerId = format ["FLO_GTN_DBG_%1_REINF_AA_TGT_%2", _cmdSideKey, _groupId];
                            _activeIds pushBack _aaTargetMarkerId;
                            [_aaTargetMarkerId, _targetPos, "mil_dot", _ownColor, format ["%1 AA DEPLOY", _cmdSideKey], [0.5, 0.5], 0.8] call FLO_fnc_gtnCommanderDebugUpsertMarker;
                        };
                    };
                };
            } forEach (keys _allGroups);

            {
                private _objId = _x;
                private _count = _reinforcingObjectiveCounts get _objId;
                private _objPos = (FLO_Objectives get _objId) get "position";
                private _reinfTargetMarkerId = format ["FLO_GTN_DBG_%1_REINF_TGT_%2", _cmdSideKey, _objId];
                _activeIds pushBack _reinfTargetMarkerId;
                [_reinfTargetMarkerId, _objPos, "mil_dot", _ownColor, format ["%1 REINF INBOUND %2 x%3", _cmdSideKey, _objId, _count], [0.6, 0.6], 0.8] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            } forEach (keys _reinforcingObjectiveCounts);

            private _taskedSet = createHashMap;
            { _taskedSet set [_x, true]; } forEach _taskedGroups;

            {
                private _groupId = _x;
                private _gData = _allGroups get _groupId;
                if (isNil "_gData") then { continue };
                if ((_gData get "side") != _ownSide) then { continue };
                if !(_gData get "isActive") then { continue };
                if !(isNil { _taskedSet get _groupId }) then { continue };

                private _mountedIn = _gData get "mountedIn";
                if (_mountedIn == "") then { continue };

                private _groupPos = _gData get "position";
                private _groupState = [_gData] call FLO_fnc_virtualizationGetEffectiveState;
                private _groupUnits = _gData get "unitCount";
                private _groupType = _gData get "groupType";
                private _shortId = if ((count _groupId) > 7) then { _groupId select [7] } else { _groupId };
                private _carrierShortId = if ((count _mountedIn) > 7) then { _mountedIn select [7] } else { _mountedIn };

                private _mountedMarkerId = format ["FLO_GTN_DBG_%1_MOUNTED_%2", _cmdSideKey, _groupId];
                _activeIds pushBack _mountedMarkerId;
                [_mountedMarkerId, _groupPos, "mil_dot", _ownColor, format [
                    "%1 %2 mounted:%3 st:%4 u%5 %6",
                    _cmdSideKey,
                    _shortId,
                    _carrierShortId,
                    _groupState,
                    _groupUnits,
                    _groupType
                ], [0.45, 0.45], 0.55] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            } forEach (keys _allGroups);

            {
                private _groupId = _x;
                private _gData = _allGroups get _groupId;
                if (isNil "_gData") then { continue };

                private _groupPos = _gData get "position";
                private _groupOrder = _gData get "commanderOrder";
                private _groupState = [_gData] call FLO_fnc_virtualizationGetEffectiveState;
                private _groupUnits = _gData get "unitCount";
                private _groupType = _gData get "groupType";
                private _shortId = if ((count _groupId) > 7) then { _groupId select [7] } else { _groupId };
                private _groupMarkerType = switch (_groupOrder) do {
                    case "ATTACK": { "mil_arrow" };
                    case "ASSAULT": { "mil_arrow" };
                    case "DEFEND": { "mil_triangle" };
                    case "RECON": { "mil_marker" };
                    case "RETREAT": { "mil_warning" };
                    default { "mil_dot" };
                };

                private _groupMarkerId = format ["FLO_GTN_DBG_%1_GROUP_%2", _cmdSideKey, _groupId];
                _activeIds pushBack _groupMarkerId;
                private _groupText = format [
                    "%1 %2 ord:%3 st:%4 u%5 %6",
                    _cmdSideKey,
                    _shortId,
                    _groupOrder,
                    _groupState,
                    _groupUnits,
                    _groupType
                ];
                [_groupMarkerId, _groupPos, _groupMarkerType, _ownColor, _groupText, [0.5, 0.5], 0.9] call FLO_fnc_gtnCommanderDebugUpsertMarker;
            } forEach _taskedGroups;
        } forEach (keys _commandersBySide);

        {
            if !(_x in _activeIds) then {
                deleteMarker _x;
                FLO_GTN_CommanderDebugMarkers deleteAt _x;
            };
        } forEach (keys FLO_GTN_CommanderDebugMarkers);

        {
            FLO_GTN_CommanderDebugMarkers set [_x, true];
        } forEach _activeIds;

        sleep _interval;
    };

    [] call FLO_fnc_gtnCommanderDebugClearAll;
};

["GTN_DEBUG", 2, format ["Commander visual debug started (%1s interval)", _interval]] call FLO_fnc_log;

true
