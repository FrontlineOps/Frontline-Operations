/* Returns one required operation record from the campaign registry. */
params [
    "_director",
    ["_operationId", "", [""]]
];

if (_operationId == "") then {
    throw "FLO_fnc_campaignGetOperation: operation ID is empty";
};

private _operations = (_director get "_state") get "operations";
if !(_operationId in _operations) then {
    throw format ["FLO_fnc_campaignGetOperation: unknown operation %1", _operationId];
};

_operations get _operationId
