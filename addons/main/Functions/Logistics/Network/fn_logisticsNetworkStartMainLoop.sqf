/*
 * Function: FLO_fnc_logisticsNetworkStartMainLoop
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts the logistics network worker once mission systems required by the
 *   network are initialized, then runs periodic checks through a CBA PFH.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   None
 */

params ["_net"];

if (_net get "_loopStarted") exitWith {};
_net set ["_loopStarted", true];

[
    {
        params ["_net"];
        !isNil "FLO_virtualGroups" &&
        {!isNil "FLO_Objectives"} &&
        {(keys FLO_Objectives) isNotEqualTo []} &&
        {!isNil "InitializationOG"} &&
        {InitializationOG} &&
        {!isNil "FLO_SideResources"}
    },
    {
        params ["_net"];

        [
            {
                params ["_net"];

                [_net] call FLO_fnc_logisticsNetworkRefreshManagedSide;
                ["LOGISTICS", 3, format ["Logistics side context resolved: %1", _net get "_managedSideKey"]] call FLO_fnc_log;

                if (isNil {_net get "_initialComposition"}) then {
                    private _comp = [_net] call FLO_fnc_logisticsNetworkGetComposition;
                    _net set ["_initialComposition", _comp];
                    ["LOGISTICS", 3, format ["Captured initial composition: %1", _comp]] call FLO_fnc_log;
                };

                if ((_net get "_loopPfhId") >= 0) exitWith {};

                private _interval = _net get "CHECK_INTERVAL";
                private _pfhId = [{
                    params ["_args", "_pfhId"];
                    _args params ["_net"];

                    if (isNil "FLO_Logistics_Networks") exitWith {
                        [_pfhId] call CBA_fnc_removePerFrameHandler;
                        _net set ["_loopPfhId", -1];
                        _net set ["_loopStarted", false];
                    };

                    if (_net get "_enabled") then {
                        private _t0 = diag_tickTime;
                        [_net] call FLO_fnc_logisticsNetworkCheckAndReplace;
                        private _dt = diag_tickTime - _t0;

                        if (_dt > 0.01) then {
                            private _perf = _net get "_lastPerf";
                            if (isNil "_perf") then {
                                _perf = createHashMap;
                            };
                            diag_log format [
                                "[FLO][PERF] Logistics network %1 processed queue=%2 in %3 ms | refresh=%4 compose=%5 reserve=%6 reconcile=%7 targets=%8 dispatch=%9 | dispatchDetail=tgt=%10 delivery=%11 spawn=%12 spend=%13 create=%14 book=%15 | createDetail=group=%16 transit=%17 organic=%18 wp=%19 | reserveNeedG=%20 reserveNeedA=%21 reserveCreateG=%22 reserveCreateA=%23 | collapse=%24 advance=%25 needed=%26 batch=%27 attempted=%28 created=%29 status=%30 | failPool=%31 failFunds=%32 failTarget=%33 failSat=%34 failDelivery=%35 failSpawn=%36 failSpend=%37 failCreate=%38 | res=%39->%40",
                                _net get "_managedSideKey",
                                count (_net get "_reinforcementQueue"),
                                _dt * 1000,
                                _perf getOrDefault ["refreshMs", 0],
                                _perf getOrDefault ["compositionMs", 0],
                                _perf getOrDefault ["reserveMs", 0],
                                _perf getOrDefault ["reconcileMs", 0],
                                _perf getOrDefault ["targetMs", 0],
                                _perf getOrDefault ["dispatchMs", 0],
                                _perf getOrDefault ["dispatchTargetPickMs", 0],
                                _perf getOrDefault ["dispatchDeliveryPickMs", 0],
                                _perf getOrDefault ["dispatchSpawnMs", 0],
                                _perf getOrDefault ["dispatchSpendMs", 0],
                                _perf getOrDefault ["dispatchCreateMs", 0],
                                _perf getOrDefault ["dispatchBookkeepingMs", 0],
                                _perf getOrDefault ["dispatchCreateGroupMs", 0],
                                _perf getOrDefault ["dispatchCreateTransitMs", 0],
                                _perf getOrDefault ["dispatchCreateOrganicMs", 0],
                                _perf getOrDefault ["dispatchCreateWaypointMs", 0],
                                _perf getOrDefault ["reserveGroundMissing", 0],
                                _perf getOrDefault ["reserveAirMissing", 0],
                                _perf getOrDefault ["reserveGroundCreated", 0],
                                _perf getOrDefault ["reserveAirCreated", 0],
                                _perf getOrDefault ["collapseTargetCount", 0],
                                _perf getOrDefault ["advanceTargetCount", 0],
                                _perf getOrDefault ["neededCount", 0],
                                _perf getOrDefault ["batchSize", 0],
                                _perf getOrDefault ["attempted", 0],
                                _perf getOrDefault ["created", 0],
                                _perf getOrDefault ["status", "UNKNOWN"],
                                _perf getOrDefault ["failNoTargetPool", 0],
                                _perf getOrDefault ["failCantAfford", 0],
                                _perf getOrDefault ["failNoTargetObj", 0],
                                _perf getOrDefault ["failSaturatedTarget", 0],
                                _perf getOrDefault ["failNoDeliveryObjective", 0],
                                _perf getOrDefault ["failNoSpawnPos", 0],
                                _perf getOrDefault ["failSpendResources", 0],
                                _perf getOrDefault ["failCreateReplacement", 0],
                                _perf getOrDefault ["resourcesBefore", 0],
                                _perf getOrDefault ["resourcesAfter", 0]
                            ];
                        };
                    };
                }, _interval, [_net]] call CBA_fnc_addPerFrameHandler;

                _net set ["_loopPfhId", _pfhId];
                ["LOGISTICS", 3, format ["Started logistics check loop (%1s, PFH)", _interval]] call FLO_fnc_log;
            },
            [_net],
            10
        ] call CBA_fnc_waitAndExecute;
    },
    [_net]
] call CBA_fnc_waitUntilAndExecute;
