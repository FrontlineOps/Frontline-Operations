params ["_player", "_baseNetId", "_cart"];

if (!isServer) exitWith {};

private _access = [_player, _baseNetId] call FLO_fnc_storeValidateAccess;
private _owner = _access get "owner";

if !(_access get "success") exitWith {
    [_owner, "store::checkout", createHashMapFromArray [
        ["success", false],
        ["message", _access get "message"]
    ]] call FLO_fnc_storeSendResponse;
};

private _payload = [_access, _cart] call FLO_fnc_storeCheckout;

if (_payload get "success") then {
    [_owner, "store::hydrate", [_access] call FLO_fnc_storeBuildHydratePayload] call FLO_fnc_storeSendResponse;
};

[_owner, "store::checkout", _payload] call FLO_fnc_storeSendResponse;
