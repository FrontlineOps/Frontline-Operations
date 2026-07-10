params ["_network"];

private _accepted = 0;
private _managedSide = _network get "_managedSide";
private _deliveryRadius = _network get "NODE_DELIVERY_RADIUS";

{
    private _nodeId = _x;
    private _node = _y;
    if ((_node get "type") == "HQ" || {(_node get "state") == "DISABLED"}) then { continue };

    private _shipments = nearestObjects [_node get "position", ["CargoNet_01_box_F"], _deliveryRadius] select {
        alive _x
        && {_x getVariable ["FLO_LogisticsShipment", false]}
        && {!(_x getVariable ["FLO_LogisticsDelivered", false])}
    };
    if (_shipments isEqualTo []) then { continue };

    private _shipment = _shipments select 0;
    private _shipmentSide = _shipment getVariable ["FLO_LogisticsSide", sideUnknown];
    if (_shipmentSide isNotEqualTo _managedSide) then { continue };
    if ((_shipment getVariable ["FLO_LogisticsOriginNodeId", ""]) == _nodeId) then {
        if !(_shipment getVariable ["FLO_LogisticsSameNodeWarned", false]) then {
            _shipment setVariable ["FLO_LogisticsSameNodeWarned", true, true];
            {
                if ((side group _x) isEqualTo _managedSide) then {
                    [
                        "Supply shipments must be delivered to a different logistics node.",
                        "warning",
                        false,
                        owner _x
                    ] call FLO_fnc_sendNotification;
                };
            } forEach allPlayers;
        };
        continue;
    };

    private _throughput = _shipment getVariable ["FLO_LogisticsThroughput", -1];
    if !(_throughput isEqualType 0 && {_throughput > 0}) then {
        throw format ["Invalid logistics shipment throughput at %1: %2", getPosATL _shipment, _throughput];
    };

    _shipment setVariable ["FLO_LogisticsDelivered", true, true];
    [_network, _nodeId, _throughput, "Player supply shipment"] call FLO_fnc_logisticsNetworkRestoreThroughput;
    _node set ["deliveryCount", (_node get "deliveryCount") + 1];
    if ((_node get "state") == "ESTABLISHING" && {(_node get "deliveryCount") >= (_node get "requiredDeliveries")}) then {
        _node set ["establishAtDateNum", dateToNumber date];
    };

    deleteVehicle _shipment;
    _accepted = _accepted + 1;

    {
        if ((side group _x) isEqualTo _managedSide) then {
            [
                format ["Supply delivered to %1. Local supplies %2/%3.", _node get "type", round (_node get "throughput"), _node get "throughputMax"],
                "success",
                false,
                owner _x
            ] call FLO_fnc_sendNotification;
        };
    } forEach allPlayers;
} forEach (_network get "_nodes");

if (_accepted > 0) then {
    [_network, true] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
    [_network] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
};
_accepted
