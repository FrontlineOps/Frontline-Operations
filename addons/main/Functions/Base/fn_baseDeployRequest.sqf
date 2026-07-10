params ["_player", ["_baseType", "FOB", [""]]];

if (!isServer || {isNull _player}) exitWith {};
private _owner = owner _player;
if (remoteExecutedOwner > 2 && {_owner != remoteExecutedOwner}) exitWith {
    ["BASE", 1, format ["Rejected deploy request from owner %1 for player owner %2", remoteExecutedOwner, _owner]] call FLO_fnc_log;
};

private _type = toUpper _baseType;
if !(_type in ["FOB", "COP"]) exitWith {
    [false, format ["Unknown base type %1.", _baseType]] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _isAdmin = (admin _owner) > 0;
private _isOfficer = (typeOf _player == F_Officer) || {typeOf _player == "B_G_officer_F"};
private _hasAuthority = _isAdmin || {_isOfficer || {leader group _player isEqualTo _player}};
if (!_hasAuthority) exitWith {
    [false, "FOB/COP deployment requires admin, officer, or squad leader authority."] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _side = side group _player;
if !(_side in [west, east]) then { throw format ["Base deploy requester has unsupported side %1", _side]; };
private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _treasury = FLO_SideResources get _sideKey;
private _cost = [_side, _type] call FLO_fnc_baseDeployGetCost;
private _firstFOBFree = _type == "FOB" && {_cost == 0};

FLO_BaseDeploySequence = FLO_BaseDeploySequence + 1;
private _reservationId = format ["BASE:%1:%2:%3", _sideKey, _owner, FLO_BaseDeploySequence];
private _reserved = _firstFOBFree || {
    _treasury call ["reserve", [_reservationId, _cost, "CONSTRUCTION", format ["%1 deployment", _type], name _player, mapGridPosition _player]]
};
if (!_reserved) exitWith {
    private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
    [false, format ["Not enough available resources. %1 costs %2; available %3.", _type, _cost, _economy get "available"]] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _deployment = [_player, _type] call FLO_fnc_storeDeployBase;
if !(_deployment get "success") exitWith {
    if (!_firstFOBFree) then {
        _treasury call ["releaseReservation", [_reservationId, "Base deployment failed validation"]];
    };
    [false, _deployment get "message"] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

if (_firstFOBFree) then {
    [_side] call FLO_fnc_baseDeployClaimFirstFOB;
} else {
    if !(_treasury call ["commitReservation", [_reservationId, _cost, format ["Deployed %1", _type]]]) then {
        throw format ["Failed to commit guaranteed base reservation %1", _reservationId];
    };
};

private _message = _deployment get "message";
if (_firstFOBFree) then { _message = _message + " First FOB deployment was free."; };
[true, _message] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
