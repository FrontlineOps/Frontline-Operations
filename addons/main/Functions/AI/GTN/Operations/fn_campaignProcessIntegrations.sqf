/*
 * Function: FLO_fnc_campaignProcessIntegrations
 * Description:
 *   Integrates unsupported footholds after the hold threshold and either a
 *   maintained supply connection or a registered friendly base.
 */

params ["_director"];

private _config = _director get "_config";
private _minimumHoldSeconds = _config get "footholdMinimumHoldSeconds";
private _now = call FLO_fnc_operationalDateNumber;
private _integratedCount = 0;

FLO_CampaignBases = FLO_CampaignBases select { !isNull _x && {alive _x} };

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "campaignIntegrationState") != "FOOTHOLD") then { continue };

    private _capturedAt = _objective get "capturedAtDateNum";
    if (_capturedAt < 0 || {([_capturedAt, _now] call FLO_fnc_dateNumberDeltaSeconds) < _minimumHoldSeconds}) then { continue };

    private _owner = _objective get "owner";
    if !(_owner in [west, east]) then { continue };

    private _sideKey = ([_owner] call FLO_fnc_gtnSideContext) get "sideKey";
    private _network = FLO_Logistics_Networks get _sideKey;
    [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
    private _routeInfo = _network get "_supplyRouteInfo";
    private _connected = false;
    {
        private _linkedObjective = FLO_Objectives get _x;
        if (
            _x in _routeInfo
            && {(_linkedObjective get "owner") isEqualTo _owner}
            && {[_x] call FLO_fnc_campaignIsObjectiveIntegrated}
        ) exitWith {
            _connected = true;
        };
    } forEach (_objective get "linkedObjectives");

    private _hasBase = false;
    {
        private _baseSide = _x getVariable "FLO_BaseSide";
        if (_baseSide isNotEqualTo _owner) then { continue };
        if ([getPosATL _x, _objective] call FLO_fnc_isPositionInObjective) exitWith {
            _hasBase = true;
        };
    } forEach FLO_CampaignBases;

    if !(_connected || {_hasBase}) then { continue };
    if ([_director, _objectiveId, ["SUPPLY_CONNECTED", "BASE_ESTABLISHED"] select _hasBase] call FLO_fnc_campaignIntegrateObjective) then {
        _integratedCount = _integratedCount + 1;
    };
} forEach (keys FLO_Objectives);

createHashMapFromArray [["integratedCount", _integratedCount]]
