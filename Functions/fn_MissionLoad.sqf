if (!isServer) exitWith {};

MissionLoadedLitterally = 0;
publicVariable "MissionLoadedLitterally";

private _center = [worldSize/2, worldSize/2, 0];
private _data = missionProfileNamespace getVariable ["FLO_MissionData", createHashMap];

// Handle fresh start parameter
FreshStartVal = "FreshStart" call BIS_fnc_getParamValue;
if (FreshStartVal isEqualTo 1) then {
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;
    MissionLoadedLitterally = true; publicVariable "MissionLoadedLitterally";
    return;
};

//------------------------------------------------------
// Load date
private _date = _data get "time";
if (!isNil "_date") then { setDate _date; };

//------------------------------------------------------
// Load markers
private _markerHash = _data getOrDefault ["markers", createHashMap];
{
    private _attr = _markerHash get _x;
    private _m = createMarkerLocal [_x, [0,0,0]];
    _m setMarkerPosLocal (_attr get "pos");
    _m setMarkerTypeLocal (_attr get "type");
    _m setMarkerBrushLocal (_attr get "brush");
    _m setMarkerShapeLocal "ICON";
    _m setMarkerSizeLocal (_attr get "size");
    _m setMarkerTextLocal (_attr get "text");
    _m setMarkerDirLocal (_attr get "dir");
    _m setMarkerColorLocal (_attr get "color");
    _m setMarkerAlpha (_attr get "alpha");
} forEach (keys _markerHash);

//------------------------------------------------------
// Load objects
private _objHash = _data getOrDefault ["objects", createHashMap];
{
    private _attr = _objHash get _x;
    private _obj = createVehicle [_attr get "type", [0,0,0], [], 0, "CAN_COLLIDE"];
    _obj setVectorDirAndUp (_attr get "vectorDirAndUp");
    _obj setPosASL (_attr get "posASL");
    _obj setVariable ["IDS_Logistics_isPlacedEntity", _attr get "isPlacedEntity", true];
} forEach (keys _objHash);

//------------------------------------------------------
// Load vehicles
private _vehHash = _data getOrDefault ["vehicles", createHashMap];
{
    private _attr = _vehHash get _x;
    private _veh = createVehicle [_attr get "type", [0,0,0], [], 0, "CAN_COLLIDE"];
    _veh setVectorDirAndUp (_attr get "vectorDirAndUp");
    _veh setPosATL (_attr get "posATL");
    _veh setFuel (_attr get "fuel");
    _veh setDamage (_attr get "damage");
    {
        private _val = (_attr get "damages" # 2) # _forEachIndex;
        _veh setHitPointDamage [_x, _val];
    } forEach ((_attr get "damages") # 0);
} forEach (keys _vehHash);

//------------------------------------------------------
// Restore resource data for logistic system
private _missionTag = missionName; _missionTag = [_missionTag] call BIS_fnc_filterString;
private _resVar = _missionTag + "_Resources";
private _resData = _data getOrDefault ["resources", createHashMap];
profileNamespace setVariable [_resVar, _resData];
private _resourceLoadResult = FLO_OPFOR_Resources call ["loadResources", []];
if (_resourceLoadResult) then {
    [[west,"HQ"], "OPFOR resources state loaded successfully..."] remoteExec ["sideChat", 0];
};

//------------------------------------------------------
// Restore structure markers and initialize FOB/OP
private _structureTypes = _data getOrDefault ["structureTypes", []];
private _fobTypeClass = _structureTypes param [0, objNull];
private _opTypeClass = _structureTypes param [1, objNull];
private _structureMarkerHash = _data getOrDefault ["structureMarkers", createHashMap];
if (count _structureMarkerHash > 0) then {
    private _fobBuildings = nearestObjects [_center, [_fobTypeClass,"Land_Cargo_HQ_V3_F","Land_Cargo_HQ_V1_F"], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _pos = getPosASL _x;
            private _id = format["%1_%2_%3",_pos#0,_pos#1,_pos#2];
            private _markerData = _structureMarkerHash getOrDefault [_id, []];
            if (count _markerData > 0) then {
                private _mn = _markerData#0;
                private _type = _markerData#1;
                if (_type isEqualTo "FOB") then {
                    _x setVariable ["fobMarkerName", _mn, true];
                    _x setVariable ["FLO_FOB_MarkersRestored", true, true];
                    [_x, true] call FLO_fnc_initializeFOB;
                };
            };
        };
    } forEach _fobBuildings;

    private _opBuildings = nearestObjects [_center, [_opTypeClass], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _pos = getPosASL _x;
            private _id = format["%1_%2_%3",_pos#0,_pos#1,_pos#2];
            private _markerData = _structureMarkerHash getOrDefault [_id, []];
            if (count _markerData > 0) then {
                private _mn = _markerData#0;
                private _type = _markerData#1;
                if (_type isEqualTo "OP") then {
                    _x setVariable ["opMarkerName", _mn, true];
                    _x setVariable ["FLO_OP_MarkersRestored", true, true];
                    [_x, true] call FLO_fnc_initializeOP;
                };
            };
        };
    } forEach _opBuildings;
};

//------------------------------------------------------
// Load crates
private _crateHash = _data getOrDefault ["crates", createHashMap];
{
    private _attr = _crateHash get _x;
    private _crate = createVehicle [_attr get "type", _attr get "posASL", [], 0, "CAN_COLLIDE"];
    [_crate, [[],[],[],[]]] call bis_fnc_initAmmoBox;
    _crate setVectorDirAndUp (_attr get "vectorDirAndUp");
    _crate setPosASL (_attr get "posASL");
    _crate setVariable ["FLO_save_crate", true, true];
    _crate setVariable ["FLO_crate_items", _attr get "items", true];
    { _x params ["_i","_c"]; _crate addItemCargoGlobal [_i,_c]; } forEach (_attr get "items");
    [_crate, true, [0,2,0],0] remoteExec ["ace_dragging_fnc_setDraggable",0,true];
} forEach (keys _crateHash);

//------------------------------------------------------
// Load virtual groups
[] spawn {
    waitUntil {!isNil "FLO_OPFOR_Resources"};
    waitUntil {!isNil "F_Init" && {F_Init}};
    private _groupsHash = _data getOrDefault ["virtualGroups", createHashMap];
    if (count _groupsHash > 0) then {
        if (isNil "FLO_virtualGroups") then { [2000] call FLO_fnc_initVirtualization; };
        InitializationOG = true; publicVariable "InitializationOG";
        {
            private _groupData = _y;
            private _newId = [_groupData get "position", _groupData get "groupType", nil, _groupData get "objective", _groupData get "unitCount", _groupData get "side"] call FLO_fnc_createVirtualGroup;
            if (_newId != "") then {
                private _newData = (FLO_virtualGroups get "_groups") get _newId;
                _newData set ["state", _groupData get "state"];
                _newData set ["waypoints", _groupData get "waypoints"];
                _newData set ["currentWaypointIndex", _groupData get "currentWaypointIndex"];
                _newData set ["garrisonPosition", _groupData getOrDefault ["garrisonPosition", []]];
                _newData set ["garrisonObjective", _groupData getOrDefault ["garrisonObjective", ""]];
            };
        } forEach _groupsHash;
    };
};

//------------------------------------------------------
// Restore objectives
if (!isNil (_data get "objectives")) then { FLO_Objectives = _data get "objectives"; publicVariable "FLO_Objectives"; };
//if (!isNil (_data get "virtualObjectives")) then { FLO_VirtualObjectives = _data get "virtualObjectives"; publicVariable "FLO_VirtualObjectives"; };

//------------------------------------------------------
// Restore AI Commander minimal state
if (!isNil (_data get "aiCommander")) then {
    if (isNil "FLO_AI_Commander") then { FLO_AI_Commander = [] call FLO_fnc_aiCommander; };
    private _cmd = _data get "aiCommander";
    FLO_AI_Commander set ["_threatLevel", _cmd get "threatLevel"];
    FLO_AI_Commander set ["_lastUpdate", _cmd get "lastUpdate"];
    FLO_AI_Commander set ["_attackOperations", _cmd get "attackOperations"];
    FLO_AI_Commander set ["_activeAttackGroups", _cmd get "activeAttackGroups"];
    FLO_AI_Commander set ["_activeDefenseGroups", _cmd get "activeDefenseGroups"];
    FLO_AI_Commander set ["_garrisonedGroups", _cmd get "garrisonedGroups"];
};

//------------------------------------------------------
MissionLoadedLitterally = true;
publicVariable "MissionLoadedLitterally";
