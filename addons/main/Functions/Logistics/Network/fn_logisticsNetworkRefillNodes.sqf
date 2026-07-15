params ["_network"];

private _now = call FLO_fnc_operationalDateNumber;
private _lastRefill = _network get "_lastNodeRefillAtDateNum";
if (_lastRefill < 0) exitWith {
    _network set ["_lastNodeRefillAtDateNum", _now];
    0
};

private _elapsed = [_lastRefill, _now] call FLO_fnc_dateNumberDeltaSeconds;
private _interval = _network get "NODE_REFILL_INTERVAL";
private _cycles = floor (_elapsed / _interval);
if (_cycles <= 0) exitWith { 0 };

private _restored = 0;
{
    private _node = _y;
    if !((_node get "state") in ["CONNECTED", "STRAINED"]) then { continue };
    private _before = _node get "throughput";
    private _after = (_before + ((_node get "refillAmount") * _cycles)) min (_node get "throughputMax");
    _node set ["throughput", _after];
    _restored = _restored + (_after - _before);
} forEach (_network get "_nodes");

_network set ["_lastNodeRefillAtDateNum", [_lastRefill, _cycles * _interval] call FLO_fnc_dateNumberAddSeconds];
if (_restored > 0) then { [_network, false] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty; };
_restored
