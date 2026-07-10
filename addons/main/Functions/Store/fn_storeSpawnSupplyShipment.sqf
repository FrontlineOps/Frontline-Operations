params ["_access"];

if (!isServer) exitWith { objNull };
private _base = _access get "base";
private _network = _access get "logisticsNetwork";
private _node = _access get "logisticsNode";
private _origin = getPosATL _base;
private _spawnPosition = _origin findEmptyPosition [4, 20, "CargoNet_01_box_F"];
if (_spawnPosition isEqualTo []) then { _spawnPosition = _base modelToWorld [5, 0, 0]; };

private _shipment = createVehicle ["CargoNet_01_box_F", _spawnPosition, [], 0, "NONE"];
if (isNull _shipment) exitWith { objNull };
[_shipment, [[], [], [], []]] call BIS_fnc_initAmmoBox;
_shipment setVariable ["FLO_LogisticsShipment", true, true];
_shipment setVariable ["FLO_LogisticsDelivered", false, true];
_shipment setVariable ["FLO_LogisticsSide", _access get "side", true];
_shipment setVariable ["FLO_LogisticsOriginNodeId", _node get "id", true];
_shipment setVariable ["FLO_LogisticsThroughput", _network get "SHIPMENT_THROUGHPUT", true];
_shipment setVariable ["FLO_save_crate", true, true];
[_shipment, true, [0, 2, 0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, _shipment];

["STORE", 2, format ["Spawned supply shipment %1 from node %2", netId _shipment, _node get "id"]] call FLO_fnc_log;
_shipment
