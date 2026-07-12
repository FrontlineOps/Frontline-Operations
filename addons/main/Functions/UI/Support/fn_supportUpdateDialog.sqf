if (!hasInterface || {!FLO_SupportBrowserReady}) exitWith { false };

private _control = uiNamespace getVariable ["FLO_SupportControl", controlNull];
if (isNull _control) exitWith { false };

private _side = side group player;
private _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
private _sideName = ["BLUFOR", "OPFOR"] select (_side isEqualTo east);
private _economy = FLO_SideResourceState get _sideKey;
private _hasTarget = FLO_SupportTargetPosition isNotEqualTo [];
private _targetGrid = ["------", mapGridPosition FLO_SupportTargetPosition] select _hasTarget;
private _targetPosition = [[], +FLO_SupportTargetPosition] select _hasTarget;
private _artilleryTreasury = FLO_ArtilleryTreasuryCostPerRound * 6;
private _artillerySupply = FLO_ArtilleryLocalSupplyCostPerRound * 6;

private _snapshot = createHashMapFromArray [
    ["sideName", _sideName],
    ["selectedType", FLO_SupportSelectedType],
    ["hasTarget", _hasTarget],
    ["targetGrid", _targetGrid],
    ["targetPosition", _targetPosition],
    ["available", _economy get "available"],
    ["balance", _economy get "balance"],
    ["committed", _economy get "committed"],
    ["packages", [
        createHashMapFromArray [
            ["type", "ARTY"],
            ["name", "Field Artillery"],
            ["asset", "6-round fire mission"],
            ["treasury", str _artilleryTreasury],
            ["supply", str _artillerySupply],
            ["safety", "250 m danger close"]
        ],
        createHashMapFromArray [
            ["type", "CAS"],
            ["name", "Close Air Support"],
            ["asset", "Helicopter or jet strike"],
            ["treasury", "600-1,000"],
            ["supply", "900-1,500"],
            ["safety", "175 m danger close"]
        ],
        createHashMapFromArray [
            ["type", "CAP"],
            ["name", "Combat Air Patrol"],
            ["asset", "10-minute air patrol"],
            ["treasury", "800"],
            ["supply", "1,200"],
            ["safety", "Area patrol"]
        ]
    ]]
];

private _script = format [
    "if (window.FLOSupport) { window.FLOSupport.applySnapshot(%1); }",
    toJSON _snapshot
];
[_control, ["ExecJS", _script]] call FLO_fnc_supportWebAction;
true
