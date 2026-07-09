params ["_player", ["_baseType", "FOB", [""]]];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _owner = owner _player;

if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    diag_log format [
        "[FLO][Base] Rejected deploy request from owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ];
};

private _type = toUpper _baseType;
private _isAdmin = (admin _owner) > 0;
private _isOfficer = (typeOf _player == F_Officer) || {typeOf _player == "B_G_officer_F"};
private _hasAuthority = _isAdmin || {_isOfficer || {leader group _player isEqualTo _player}};

if (!_hasAuthority) exitWith {
    [false, "FOB/COP deployment requires admin, officer, or squad leader authority."] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _cost = [FLO_BaseFOBDeployCost, FLO_BaseCOPDeployCost] select (_type isEqualTo "COP");
private _money = FLO_MoneyHandle get "value";

if (_money < _cost) exitWith {
    [false, format ["Not enough resources. %1 costs %2.", _type, _cost]] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _deploy = [_player, _type] call FLO_fnc_storeDeployBase;

if !(_deploy get "success") exitWith {
    [false, _deploy get "message"] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
};

private _newMoney = _money - _cost;
FLO_MoneyHandle set ["value", _newMoney];
[_newMoney] call FLO_fnc_publishMoneyState;

[true, _deploy get "message"] remoteExecCall ["FLO_fnc_baseDeployReceiveResult", _owner];
