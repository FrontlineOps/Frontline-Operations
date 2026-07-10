if (!hasInterface) exitWith { createHashMap };

private _side = side group player;
private _sideKey = "";
private _sideName = "UNASSIGNED";

if (_side in [west, east]) then {
    _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
    _sideName = ["BLUFOR", "OPFOR"] select (_side isEqualTo east);
};

private _isAdmin = (serverCommandAvailable "#kick") && {serverCommandAvailable "#debug"};
private _isOfficer = (typeOf player == F_Officer) || {typeOf player == "B_G_officer_F"};
private _hasAuthority = _isAdmin || {_isOfficer || {leader group player isEqualTo player}};
private _authorityRole = "None";
if (leader group player isEqualTo player) then { _authorityRole = "Squad Leader"; };
if (_isOfficer) then { _authorityRole = "Officer"; };
if (_isAdmin) then { _authorityRole = "Server Admin"; };
private _factionName = if (_sideKey isEqualTo "EAST") then { "OPFOR" } else { markerText "Friendly_Handle" };
if (_factionName isEqualTo "") then {
    _factionName = _sideName;
};

private _pos = getPosATL player;
private _fobCost = FLO_BaseFOBDeployCost;
private _firstFOBFree = false;
private _economy = createHashMap;
private _available = 0;
private _totalBalance = 0;
private _committed = 0;
private _lastIncome = 0;
if (_sideKey != "") then {
    _fobCost = [_side, "FOB"] call FLO_fnc_baseDeployGetCost;
    _firstFOBFree = _fobCost == 0;
    _economy = FLO_SideResourceState get _sideKey;
    _available = _economy get "available";
    _totalBalance = _economy get "balance";
    _committed = _economy get "committed";
    _lastIncome = _economy get "incomePerMinute";
};

createHashMapFromArray [
    ["sideKey", _sideKey],
    ["sideName", _sideName],
    ["grid", mapGridPosition player],
    ["alive", alive player],
    ["onWater", surfaceIsWater _pos],
    ["hasAuthority", _hasAuthority],
    ["factionName", _factionName],
    ["authorityRole", _authorityRole],
    ["balance", _available],
    ["totalBalance", _totalBalance],
    ["committed", _committed],
    ["income", _lastIncome],
    ["fobCost", _fobCost],
    ["firstFOBFree", _firstFOBFree],
    ["fobRadius", FLO_BaseFOBBuildRadius],
    ["fobMinDistance", FLO_BaseFOBMinDistance],
    ["copCost", FLO_BaseCOPDeployCost],
    ["copRadius", FLO_BaseCOPBuildRadius],
    ["copMinDistance", FLO_BaseCOPMinDistance],
    ["copMaxPerSide", FLO_BaseCOPMaxPerSide],
    ["copEnemyDisableRadius", FLO_BaseCOPEnemyDisableRadius],
    ["keybind", "Ctrl+Shift+D"]
]
