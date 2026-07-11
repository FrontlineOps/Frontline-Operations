params ["_player", "_baseNetId"];

if (!isServer) exitWith {};

private _access = [_player, _baseNetId] call FLO_fnc_storeValidateAccess;
private _owner = _access get "owner";

if !(_access get "success") exitWith {
    [_owner, "store::hydrate", _access] call FLO_fnc_storeSendResponse;
};

[_owner, "store::hydrate", [_access] call FLO_fnc_storeBuildHydratePayload] call FLO_fnc_storeSendResponse;
