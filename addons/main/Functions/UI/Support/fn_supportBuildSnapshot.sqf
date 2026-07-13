/* Builds one side-filtered Tactical Support snapshot from authoritative server state. */
params [["_requester", objNull, [objNull]]];

if (!isServer) then { throw "Tactical Support snapshots are server-owned"; };
if (isNull _requester || {!isPlayer _requester}) then { throw "Tactical Support snapshot requires a player"; };

private _side = side group _requester;
if !(_side in [east, west]) then { throw format ["Unsupported Tactical Support side %1", _side]; };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _sideName = ["BLUFOR", "OPFOR"] select (_side isEqualTo east);
private _commander = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_side]];
if (isNil "_commander") then { throw format ["No Tactical Support commander for %1", _sideKey]; };

private _treasury = FLO_SideResources get _sideKey;
private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _artilleryManager = _commander get "_artilleryManager";
private _airManager = call FLO_fnc_gtnAirAssetManager;
private _artilleryMissions = _artilleryManager get "missions";
private _airMissions = _airManager get "missions";
private _artillerySideStatus = [_artilleryManager, _side] call FLO_fnc_gtnArtilleryCanRequestMission;
private _artillerySideReady = _artillerySideStatus select 0;
private _artillerySideSeconds = _artillerySideStatus select 2;

private _assets = [];
private _artillerySequence = 0;
private _airSequence = 0;
private _groupIds = keys _groups;
_groupIds sort true;

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if ((_groupData get "side") isNotEqualTo _side) then { continue };
    if ((_groupData get "unitCount") <= 0) then { continue };

    private _groupType = _groupData get "groupType";
    private _isArtillery = _groupType == "artillery";
    private _isAir = _groupType in ["helicopter", "air", "jet"];
    if (!_isArtillery && {!_isAir}) then { continue };
    if (_isAir && {_groupData get "transportRole"}) then { continue };

    private _supports = [["CAS", "CAP"], ["ARTY"]] select _isArtillery;
    private _kind = switch (_groupType) do {
        case "artillery": { "ARTILLERY" };
        case "helicopter": { "HELICOPTER" };
        case "jet": { "FIGHTER" };
        default { "AIRCRAFT" };
    };

    private _composition = _groupData get "comp";
    private _displayName = _kind;
    if (_composition isNotEqualTo []) then {
        private _vehicleClass = _composition select 0;
        private _vehicleConfig = configFile >> "CfgVehicles" >> _vehicleClass;
        if (isClass _vehicleConfig) then {
            private _configuredName = getText (_vehicleConfig >> "displayName");
            if (_configuredName != "") then { _displayName = _configuredName; };
        };
    };

    private _homeObjectiveId = _groupData get "homeObjective";
    if (_homeObjectiveId == "") then { throw format ["Support asset %1 has no home objective", _groupId]; };
    private _homeObjective = FLO_Objectives get _homeObjectiveId;
    private _homeName = _homeObjective get "name";
    if (_homeName == "") then { _homeName = _homeObjectiveId; };

    private _status = "UNAVAILABLE";
    private _statusDetail = "NOT READY";
    private _available = false;

    if (_isArtillery) then {
        _artillerySequence = _artillerySequence + 1;
        if (_groupId in _artilleryMissions) then {
            _status = "ON MISSION";
            _statusDetail = "FIRE MISSION ACTIVE";
        } else {
            if (!_artillerySideReady) then {
                _status = "NET COOLDOWN";
                _statusDetail = format ["%1 SEC", _artillerySideSeconds];
            } else {
                private _batteryStatus = [_artilleryManager, _side, "", _groupId] call FLO_fnc_gtnArtilleryCanRequestMission;
                private _batteryReady = _batteryStatus select 0;
                private _batterySeconds = _batteryStatus select 2;
                if (!_batteryReady) then {
                    _status = "REARMING";
                    _statusDetail = format ["%1 SEC", _batterySeconds];
                } else {
                    if ([_groupData] call FLO_fnc_gtnSupportAssetCanProvideAbstractSupport) then {
                        _status = "AVAILABLE";
                        _statusDetail = "READY TO FIRE";
                        _available = true;
                    } else {
                        private _missionLock = _groupData get "missionLock";
                        if (_missionLock != "") then {
                            _status = "TASKED";
                            _statusDetail = _missionLock;
                        };
                    };
                };
            };
        };
    } else {
        _airSequence = _airSequence + 1;
        if (_groupId in _airMissions) then {
            private _mission = _airMissions get _groupId;
            _status = "ON MISSION";
            _statusDetail = _mission get "missionType";
        } else {
            if ((_groupData get "replacementState") != "") then {
                _status = "REPLACING";
                _statusDetail = _groupData get "replacementState";
            } else {
                if (_groupData get "isActive") then {
                    _status = "AIRBORNE";
                    _statusDetail = "PHYSICAL SIMULATION";
                } else {
                    if ([_groupData] call FLO_fnc_gtnSupportAssetCanProvideAbstractSupport) then {
                        _status = "AVAILABLE";
                        _statusDetail = "SORTIE READY";
                        _available = true;
                    } else {
                        private _missionLock = _groupData get "missionLock";
                        if (_missionLock != "") then {
                            _status = "TASKED";
                            _statusDetail = _missionLock;
                        };
                    };
                };
            };
        };
    };

    private _sequence = [_airSequence, _artillerySequence] select _isArtillery;
    private _callSign = format [["FLIGHT %1", "BATTERY %1"] select _isArtillery, _sequence];
    _assets pushBack createHashMapFromArray [
        ["id", _groupId],
        ["callSign", _callSign],
        ["displayName", _displayName],
        ["kind", _kind],
        ["location", _homeName],
        ["supports", _supports],
        ["status", _status],
        ["statusDetail", _statusDetail],
        ["available", _available]
    ];
} forEach _groupIds;

private _artilleryTotal = { "ARTY" in (_x get "supports") } count _assets;
private _artilleryReady = { "ARTY" in (_x get "supports") && {_x get "available"} } count _assets;
private _airTotal = { "CAS" in (_x get "supports") } count _assets;
private _airReady = { "CAS" in (_x get "supports") && {_x get "available"} } count _assets;

createHashMapFromArray [
    ["generatedAt", diag_tickTime],
    ["sideKey", _sideKey],
    ["sideName", _sideName],
    ["available", _economy get "available"],
    ["balance", _economy get "balance"],
    ["committed", _economy get "committed"],
    ["assets", _assets],
    ["packages", [
        createHashMapFromArray [
            ["type", "ARTY"],
            ["name", "Field Artillery"],
            ["asset", "6-round fire mission"],
            ["treasury", str (FLO_ArtilleryTreasuryCostPerRound * 6)],
            ["supply", str (FLO_ArtilleryLocalSupplyCostPerRound * 6)],
            ["safety", "250 m danger close"],
            ["ready", _artilleryReady],
            ["total", _artilleryTotal]
        ],
        createHashMapFromArray [
            ["type", "CAS"],
            ["name", "Close Air Support"],
            ["asset", "Helicopter or jet strike"],
            ["treasury", "600-1,000"],
            ["supply", "900-1,500"],
            ["safety", "175 m danger close"],
            ["ready", _airReady],
            ["total", _airTotal]
        ],
        createHashMapFromArray [
            ["type", "CAP"],
            ["name", "Combat Air Patrol"],
            ["asset", "10-minute air patrol"],
            ["treasury", "800"],
            ["supply", "1,200"],
            ["safety", "Area patrol"],
            ["ready", _airReady],
            ["total", _airTotal]
        ]
    ]]
]
