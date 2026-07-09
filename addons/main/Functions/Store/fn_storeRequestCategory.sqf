params ["_player", "_baseNetId", "_category"];

if (!isServer) exitWith {};

private _access = [_player, _baseNetId] call FLO_fnc_storeValidateAccess;
private _owner = _access get "owner";

if !(_access get "success") exitWith {
    [_owner, "store::category", createHashMapFromArray [
        ["success", false],
        ["message", _access get "message"],
        ["category", _category],
        ["items", []]
    ]] call FLO_fnc_storeSendResponse;
};

[_owner, "store::category", [_access, _category] call FLO_fnc_storeBuildCategoryPayload] call FLO_fnc_storeSendResponse;
