if (!isServer) exitWith { false };

private _objectiveIds = keys FLO_Objectives;
private _t0 = diag_tickTime;
private _stateChanged = false;

{
    private _treasury = _y;
    private _side = _treasury get "_side";
    private _network = FLO_Logistics_Networks get _x;
    [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
    private _routeInfo = _network get "_supplyRouteInfo";
    private _generated = 0;
    private _contributing = 0;

    {
        private _objectiveId = _x;
        private _objective = FLO_Objectives get _objectiveId;
        if ((_objective get "owner") isNotEqualTo _side) then { continue };
        if !([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) then { continue };
        if !(_objectiveId in _routeInfo) then { continue };

        private _incomeData = [_treasury, _objective] call FLO_fnc_sideResourcesCalculateObjectiveIncome;
        _generated = _generated + (_incomeData select 0);
        _contributing = _contributing + 1;
    } forEach _objectiveIds;

    private _income = round _generated;
    if ((_treasury get "_lastIncome") != _income) then { _stateChanged = true; };
    _treasury set ["_lastIncome", _income];
    if (_income > 0) then {
        [
            _treasury,
            _income,
            "INCOME",
            format ["Connected territory income from %1 objectives", _contributing],
            "CAMPAIGN",
            "",
            false
        ] call FLO_fnc_sideResourcesAddResources;
        _stateChanged = true;
    };
} forEach FLO_SideResources;

if (_stateChanged) then { [] call FLO_fnc_sideResourcesPublishState; };

private _elapsedMs = (diag_tickTime - _t0) * 1000;
if (_elapsedMs > 10) then {
    diag_log format ["[FLO][PERF] Economy income tick processed %1 objectives in %2 ms", count _objectiveIds, _elapsedMs];
};
true
