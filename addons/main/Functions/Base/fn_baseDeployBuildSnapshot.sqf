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
private _factionName = if (_sideKey isEqualTo "EAST") then { "OPFOR" } else { markerText "Friendly_Handle" };
if (_factionName isEqualTo "") then {
    _factionName = _sideName;
};

private _pos = getPosATL player;

createHashMapFromArray [
    ["sideKey", _sideKey],
    ["sideName", _sideName],
    ["grid", mapGridPosition player],
    ["alive", alive player],
    ["onWater", surfaceIsWater _pos],
    ["insideMatchOperationSector", false],
    ["matchOperationSectorName", ""],
    ["matchOperationSectorRadius", 0],
    ["hasAuthority", _hasAuthority],
    ["playerIsCommander", _hasAuthority],
    ["factionName", _factionName],
    ["commanderName", "Field Authority"],
    ["balance", FLO_MoneyHandle get "value"],
    ["tickets", 0],
    ["ticketPacks", []],
    ["income", 0],
    ["cellIncome", 0],
    ["objectiveIncome", 0],
    ["fobCost", FLO_BaseFOBDeployCost],
    ["fobRadius", FLO_BaseFOBBuildRadius],
    ["fobMinDistance", FLO_BaseFOBMinDistance],
    ["copCost", FLO_BaseCOPDeployCost],
    ["copRadius", FLO_BaseCOPBuildRadius],
    ["copMinDistance", FLO_BaseCOPMinDistance],
    ["copMaxPerSide", FLO_BaseCOPMaxPerSide],
    ["copEnemyDisableRadius", FLO_BaseCOPEnemyDisableRadius],
    ["keybind", "Ctrl+Shift+D"]
]
