params [["_network", createHashMap, [createHashMap]]];

if (!isServer) exitWith { 0 };
private _sideKey = _network get "_managedSideKey";
private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
private _accepted = 0;

{
    _accepted = _accepted + ([_network, _x] call FLO_fnc_objectiveDevelopmentProcessObjectiveDeliveries);
} forEach _activeObjectiveIds;

if (_accepted > 0) then {
    private _stats = _network get "_stats";
    _stats set ["supplyShipments", (_stats get "supplyShipments") + _accepted];
};
_accepted
