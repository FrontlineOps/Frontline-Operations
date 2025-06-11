if (!isServer) exitWith {};

["Mission", 3, "Saving Mission ..."] call FLO_fnc_log;

private _center = [worldSize/2, worldSize/2, 0];
private _data = missionProfileNamespace getVariable ["FLO_MissionData", createHashMap];

//------------------------------------------------------
// Save time
_data set ["time", date];

//------------------------------------------------------
// Clean up any debug spheres or group markers
{
    if (!isNull _x) then { deleteVehicle _x }; 
} forEach (nearestObjects [_center, ["Sign_Sphere10cm_F"], 40000]);
{ deleteMarker _x } forEach (allMapMarkers select {markerType _x isEqualTo "b_unknown" && markerColor _x isEqualTo "Color6_FD_F"});

//------------------------------------------------------
// Save player group compositions as marker text
private _validUnitTypes = [
    F_Diver_Eod, F_Diver_Rfl, F_Diver_TL,
    F_Recon_Eod, F_Recon_Med, F_Recon_Eng, F_Recon_Mg, F_Recon_AT, F_Recon_Mrk,
    F_Recon_Snp, F_Recon_Sct, F_Recon_TL,
    F_Assault_AT, F_Assault_Amm, F_Assault_Mg, F_Assault_SL, F_Assault_TL,
    F_Assault_Eng, F_Assault_Eod, F_Assault_Mrk, F_Assault_Uav, F_Assault_Med,
    F_Officer
];
private _saveGroups = allGroups select {
    if (count units _x > 0) then {
        private _first = units _x select 0;
        if (!isNull _first) then {
            (typeOf _first) in _validUnitTypes && !captive _first && side _first isEqualTo west && alive _first
        } else {false}
    } else {false}
};
{
    private _units = units _x;
    private _types = [];
    { _types pushBack typeOf _x } forEach _units;
    if (isPlayer (_units select 0)) then { _types deleteAt 0 };
    private _m = createMarkerLocal [str (_units select 0), getPos (_units select 0)];
    _m setMarkerTypeLocal "b_unknown";
    _m setMarkerSizeLocal [0.5,0.5];
    _m setMarkerColorLocal "Color6_FD_F";
    _m setMarkerAlphaLocal 0.006;
    _m setMarkerText str _types;
} forEach _saveGroups;

//------------------------------------------------------
// Save battlefield markers
private _markerHash = createHashMap;
{
    private _entry = createHashMapFromArray [
        ["name", _x],
        ["alpha", markerAlpha _x],
        ["brush", markerBrush _x],
        ["color", getMarkerColor _x],
        ["dir", markerDir _x],
        ["pos", getMarkerPos _x],
        ["shape", markerShape _x],
        ["size", getMarkerSize _x],
        ["text", markerText _x],
        ["type", markerType _x]
    ];
    _markerHash set [_x, _entry];
} forEach allMapMarkers;
_data set ["markers", _markerHash];

//------------------------------------------------------
// Save vehicles around FOB markers
private _vehHash = createHashMap;
{
    private _pos = getMarkerPos _x;
    private _near = nearestObjects [_pos, ["Air","Ship","LandVehicle"],250];
    {
        if (alive _x) then {
            private _id = str getPosATL _x + "_Veh";
            _x setVehicleVarName _id;
            private _entry = createHashMapFromArray [
                ["type", typeOf _x],
                ["posATL", getPosATL _x],
                ["fuel", fuel _x],
                ["damage", damage _x],
                ["damages", getAllHitPointsDamage _x],
                ["vectorDirAndUp", [vectorDir _x, vectorUp _x]]
            ];
            _vehHash set [_id, _entry];
        };
    } forEach (_near select {alive _x});
} forEach (allMapMarkers select {markerType _x isEqualTo "b_installation"});
_data set ["vehicles", _vehHash];

//------------------------------------------------------
// Save placed objects
private _objHash = createHashMap;
private _excludeCrates = ["Box_NATO_WpsSpecial_F","Box_NATO_AmmoOrd_F","Box_NATO_Ammo_F","Box_NATO_Wps_F","VirtualReammoBox_small_F"];
private _saveStatics = [];
{
    private _pos = getMarkerPos _x;
    private _objs = nearestObjects [_pos,["Static","Thing","ReammoBox_F"],300];
    _objs = _objs select { alive _x && !(typeOf _x in _excludeCrates) && !(_x getVariable ["FLO_save_crate",false]) };
    _saveStatics append _objs;
} forEach (allMapMarkers select {markerType _x isEqualTo "b_installation"});
{
    private _entry = createHashMapFromArray [
        ["type", typeOf _x],
        ["posASL", getPosASL _x],
        ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
        ["isPlacedEntity", _x getVariable ["IDS_Logistics_isPlacedEntity", false]]
    ];
    private _id = str getPosASL _x + "_Obj";
    _x setVehicleVarName _id;
    _objHash set [_id, _entry];
} forEach (_saveStatics arrayIntersect _saveStatics);
_data set ["objects", _objHash];

//------------------------------------------------------
// Save structure marker references and types
private _structureMarkers = createHashMap;
private _fobTypeClass = if (!isNil "F_HQ_01") then {F_HQ_01};
private _opTypeClass = if (!isNil "F_OP_01") then {F_OP_01};
{
    if (!isNil "_x" && {alive _x} && {_x getVariable ["FLO_FOB_Initialized",false]}) then {
        private _mn = _x getVariable ["fobMarkerName",""];
        if (_mn != "") then {
            private _pos = getPosASL _x;
            _structureMarkers set [format["%1_%2_%3",_pos#0,_pos#1,_pos#2],[ _mn, "FOB"]];
        };
    };
} forEach nearestObjects [_center, [_fobTypeClass,"Land_Cargo_HQ_V3_F","Land_Cargo_HQ_V1_F"],40000];
{
    if (!isNil "_x" && {alive _x} && {_x getVariable ["FLO_OP_Initialized",false]}) then {
        private _mn = _x getVariable ["opMarkerName",""];
        if (_mn != "") then {
            private _pos = getPosASL _x;
            _structureMarkers set [format["%1_%2_%3",_pos#0,_pos#1,_pos#2],[ _mn, "OP"]];
        };
    };
} forEach nearestObjects [_center, [_opTypeClass],40000];
_data set ["structureMarkers", _structureMarkers];
_data set ["structureTypes", [_fobTypeClass,_opTypeClass]];

//------------------------------------------------------
// Save supply crates
private _crateHash = createHashMap;
{
    if (alive _x && {_x getVariable ["FLO_save_crate",false]}) then {
        private _items = [];
        private _wp = getWeaponCargo _x; { _items pushBack [_x, _wp#1 select _forEachIndex] } forEach (_wp#0);
        private _mg = getMagazineCargo _x; { _items pushBack [_x, _mg#1 select _forEachIndex] } forEach (_mg#0);
        private _it = getItemCargo _x; { _items pushBack [_x, _it#1 select _forEachIndex] } forEach (_it#0);
        private _bp = getBackpackCargo _x; { _items pushBack [_x, _bp#1 select _forEachIndex] } forEach (_bp#0);
        _x setVariable ["FLO_crate_items", _items, true];
        private _entry = createHashMapFromArray [
            ["type", typeOf _x],
            ["posASL", getPosASL _x],
            ["vectorDirAndUp", [vectorDir _x, vectorUp _x]],
            ["items", _items]
        ];
        private _id = str getPosASL _x + "_Crate";
        _x setVehicleVarName _id;
        _crateHash set [_id, _entry];
    };
} forEach (entities "ReammoBox_F");
_data set ["crates", _crateHash];

//------------------------------------------------------
// Save OPFOR resources
private _missionTag = missionName; _missionTag = [_missionTag] call BIS_fnc_filterString;
private _resVar = _missionTag + "_Resources";
private _resResult = FLO_OPFOR_Resources call ["saveResources", []];
private _resData = profileNamespace getVariable [_resVar, createHashMap];
_data set ["resources", _resData];

//------------------------------------------------------
// Save virtual groups
if (!isNil "FLO_virtualGroups") then {
    private _vh = createHashMap;
    private _groups = FLO_virtualGroups get "_groups";
    {
        private _gData = _y;
        private _s = createHashMapFromArray [
            ["position", _gData get "position"],
            ["groupType", _gData get "groupType"],
            ["objective", _gData get "objective"],
            ["unitCount", _gData get "unitCount"],
            ["side", _gData get "side"],
            ["state", _gData get "state"],
            ["waypoints", _gData get "waypoints"],
            ["currentWaypointIndex", _gData get "currentWaypointIndex"],
            ["garrisonPosition", _gData getOrDefault ["garrisonPosition", []]],
            ["garrisonObjective", _gData getOrDefault ["garrisonObjective",""]]
        ];
        _vh set [_x, _s];
    } forEach _groups;
    _data set ["virtualGroups", _vh];
};

//------------------------------------------------------
// Save objectives if they exist
if (!isNil "FLO_Objectives") then {_data set ["objectives", FLO_Objectives]};
if (!isNil "FLO_VirtualObjectives") then {_data set ["virtualObjectives", FLO_VirtualObjectives]};

//------------------------------------------------------
// Save AI Commander state (minimal)
if (!isNil "FLO_AI_Commander") then {
    private _cmd = createHashMapFromArray [
        ["threatLevel", FLO_AI_Commander get "_threatLevel"],
        ["lastUpdate", FLO_AI_Commander get "_lastUpdate"],
        ["attackOperations", FLO_AI_Commander get "_attackOperations"],
        ["activeAttackGroups", FLO_AI_Commander get "_activeAttackGroups"],
        ["activeDefenseGroups", FLO_AI_Commander get "_activeDefenseGroups"],
        ["garrisonedGroups", FLO_AI_Commander get "_garrisonedGroups"]
    ];
    _data set ["aiCommander", _cmd];
};

//------------------------------------------------------
missionProfileNamespace setVariable ["FLO_MissionData", _data];
saveMissionProfileNamespace;

["Mission",3,"Mission Saved!"] call FLO_fnc_log;
