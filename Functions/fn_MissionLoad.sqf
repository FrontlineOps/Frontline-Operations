if (!isServer) exitWith {};

private _Centerposition = [worldSize / 2, worldsize / 2, 0];

MissionLoadedLitterally = 0 ; 
publicVariable "MissionLoadedLitterally";

private _missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";
private _MarkerTimeName = _missionTag + "_Time";
private _structureMarkerName = _missionTag + "_StructureMarkers";
private _missionStructureTypes = _missionTag + "_StructureTypes";
private _CrateDataName = _missionTag + "_Crates";

FreshStartVal = "FreshStart" call BIS_fnc_getParamValue;
if (FreshStartVal isEqualTo 1) then {
    
	profileNamespace setVariable [_MarkerTimeName, nil];
	profileNamespace setVariable [_MarkerDataName, nil];
	profileNamespace setVariable [_VehicleDataName, nil];
	profileNamespace setVariable [_ObjectDataName, nil];
    profileNamespace setVariable [_missionStructureTypes, nil];
    profileNamespace setVariable [_structureMarkerName, nil];
    profileNamespace setVariable [_CrateDataName, nil];
};	

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _date = profileNamespace getVariable _MarkerTimeName;
if (!isNil "_date") then { setDate _date; };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _GetVariableMark = profileNamespace getVariable _MarkerDataName;

if (!isNil "_GetVariableMark") then {
    private _allMarkNames = keys _GetVariableMark;
    
    {
        private _markerName = _x;
        private _markerAttributes = _GetVariableMark get _markerName;
        
        private _marker = createMarkerLocal [_markerName, [0,0,0]];
        _marker setMarkerPosLocal (_markerAttributes get "pos");
        _marker setMarkerTypeLocal (_markerAttributes get "type");
        _marker setMarkerBrushLocal (_markerAttributes get "brush");
        _marker setMarkerShapeLocal "ICON"; // Using fixed ICON instead of _markerAttributes get "shape"
        _marker setMarkerSizeLocal (_markerAttributes get "size");
        _marker setMarkerTextLocal (_markerAttributes get "text");
        _marker setMarkerDirLocal (_markerAttributes get "dir");
        _marker setMarkerColorLocal (_markerAttributes get "color");
        _marker setMarkerAlpha (_markerAttributes get "alpha");
    } forEach _allMarkNames;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _GetVariableStatic = profileNamespace getVariable _ObjectDataName;

if (!isNil "_GetVariableStatic") then {
    private _allObjectNames = keys _GetVariableStatic;
    
    {
        if (alive _x) then {
            private _objectAttributes = _GetVariableStatic get _x;
            private _posASL = _objectAttributes get "posASL";
            private _type = _objectAttributes get "type";
            private _dirAndUp = _objectAttributes get "vectorDirAndUp";
            private _isPlacedEntity = _objectAttributes get "isPlacedEntity";
        
            private _newObject = createVehicle [_type, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"];
            _newObject setVectorDirAndUp _dirAndUp;
            _newObject setPosASL _posASL;
            _newObject setVariable ["IDS_Logistics_isPlacedEntity", _isPlacedEntity, true];
        };
    } forEach _allObjectNames;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _GetVariableVeh = profileNamespace getVariable _VehicleDataName;
private _allVehNames = keys _GetVariableVeh;

{
    private _VehAtts = _GetVariableVeh get _x;
    private _posATL = _VehAtts get "posATL";
    private _Type = _VehAtts get "type";
    private _DirUp = _VehAtts get "vectorDirAndUp";
    private _fuel = _VehAtts get "fuel";
    private _damage = _VehAtts get "damage";
    private _damages = _VehAtts get "damages";

    private _NewVeh = createVehicle [_Type, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"];
    _NewVeh setVectorDirAndUp _DirUp;
    _NewVeh setPosATL _posATL;
    _NewVeh setFuel _fuel;
    _NewVeh setDamage _damage;
    
    {
        private _key = _x;
        private _value = (_damages # 2) # _forEachIndex;
        _NewVeh setHitPointDamage [_key, _value];
    } forEach (_damages # 0);

    // private _vehicleConfig = configFile >> "CfgVehicles" >> typeOf _NewVeh;
    // private _crewType = [west, _vehicleConfig] call BIS_fnc_selectCrew;
    // private _CrewFull = createVehicleCrew _NewVeh;
    // private _CrewSelCnt = count (units _CrewFull) - 1; 
    // deleteVehicleCrew _NewVeh;
    
    // private _Group = createGroup West;
    // for "_i" from 0 to _CrewSelCnt do { 
    //     private _unit = _Group createUnit [_crewType, [0,0,0], [], 0, "CAN_COLLIDE"]; 
    // };
    
    // {_x moveInAny _NewVeh} forEach units _Group;
} forEach _allVehNames;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Load garrison sizes and initialize garrisons for saved objectives
private _garrisonLoadResult = FLO_Garrison_Manager call ["loadGarrisonSizes", []]; 
if (_garrisonLoadResult) then {
    [[west,"HQ"], "Garrison states loaded successfully..."] remoteExec ["sideChat", 0];
} else {
    [[west,"HQ"], "No saved garrison states found"] remoteExec ["sideChat", 0];
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Load structure types from saved mission data
private _structureTypes = profileNamespace getVariable _missionStructureTypes;
private _fobTypeClass = _structureTypes select 0;
private _opTypeClass = _structureTypes select 1;
["Mission", 3, format["Loaded structure types: FOB = %1, OP = %2", _fobTypeClass, _opTypeClass]] call FLO_fnc_log;

// Load FOB and OP marker references
private _structureMarkerHash = profileNamespace getVariable [_structureMarkerName, createHashMap];

if (count _structureMarkerHash > 0 && count _structureTypes > 0) then {
    // Process FOB buildings
    private _fobBuildings = nearestObjects [_Centerposition, [_fobTypeClass, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            private _markerData = _structureMarkerHash getOrDefault [_objectPosString, []];
            
            if (count _markerData > 0) then {
                private _markerName = _markerData#0;
                private _type = _markerData#1;
                
                if (_type isEqualTo "FOB") then {
                    // Store marker name but DON'T mark as initialized
                    _x setVariable ["fobMarkerName", _markerName, true];
                    // Use a different variable to indicate markers were restored
                    _x setVariable ["FLO_FOB_MarkersRestored", true, true];
                    ["Mission", 3, format["Restored FOB marker reference %1 for building at %2", _markerName, _objectPos]] call FLO_fnc_log;
                    
                    // Re-initialize the FOB but tell it to preserve the marker
                    [_x, true] call FLO_fnc_initializeFOB;
                };
            };
        };
    } forEach _fobBuildings;
    
    // Process OP buildings
    private _opBuildings = nearestObjects [_Centerposition, [_opTypeClass], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            private _markerData = _structureMarkerHash getOrDefault [_objectPosString, []];
            
            if (count _markerData > 0) then {
                private _markerName = _markerData#0;
                private _type = _markerData#1;
                
                if (_type isEqualTo "OP") then {
                    // Store marker name but DON'T mark as initialized
                    _x setVariable ["opMarkerName", _markerName, true];
                    // Use a different variable to indicate markers were restored
                    _x setVariable ["FLO_OP_MarkersRestored", true, true];
                    ["Mission", 3, format["Restored OP marker reference %1 for building at %2", _markerName, _objectPos]] call FLO_fnc_log;
                    
                    // Re-initialize the OP but tell it to preserve the marker
                    [_x, true] call FLO_fnc_initializeOP;
                };
            };
        };
    } forEach _opBuildings;
    
    [[west,"HQ"], format["Restored %1 FOB/OP marker references", count _structureMarkerHash]] remoteExec ["sideChat", 0];
} else {
    ["Mission", 2, "No FOB/OP marker references found to restore"] call FLO_fnc_log;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Load supply crates
private _GetVariableCrates = profileNamespace getVariable [_CrateDataName, createHashMap];

if (count _GetVariableCrates > 0) then {
    private _allCrateNames = keys _GetVariableCrates;
    
    {
        private _crateAtts = _GetVariableCrates get _x;
        private _posASL = _crateAtts get "posASL";
        private _type = _crateAtts get "type";
        private _dirUp = _crateAtts get "vectorDirAndUp";
        private _items = _crateAtts get "items";
        
        // Create the crate at final position directly
        private _newCrate = createVehicle [_type, _posASL, [], 0, "CAN_COLLIDE"];
        
        // IMPORTANT: Clear cargo BEFORE setting position to prevent default items
        clearWeaponCargoGlobal _newCrate;
        clearMagazineCargoGlobal _newCrate;
        clearItemCargoGlobal _newCrate;
        clearBackpackCargoGlobal _newCrate;
        
        // Verify cargo is actually cleared
        private _initialWeapons = weaponCargo _newCrate;
        private _initialMags = magazineCargo _newCrate;
        private _initialItems = itemCargo _newCrate;
        private _initialBags = backpackCargo _newCrate;
        
        if ((count _initialWeapons + count _initialMags + count _initialItems + count _initialBags) > 0) then {
            ["Mission", 2, format["Warning: Crate %1 not properly cleared, attempting force clear", _type]] call FLO_fnc_log;
            [_newCrate, [[], [], [], []]] call bis_fnc_initAmmoBox;
        };
        
        _newCrate setVectorDirAndUp _dirUp;
        _newCrate setPosASL _posASL;
        
        // Mark for saving system
        _newCrate setVariable ["FLO_save_crate", true, true];
        _newCrate setVariable ["FLO_crate_items", _items, true];
        
        // Add items to the crate
        if (!isNil "_items" && {count _items > 0}) then {
            {
                _x params ["_item", "_count"];
                
                if (!isNil "_item" && {_count > 0}) then {
                    if (isClass (configFile >> "CfgWeapons" >> _item)) then {
                        _newCrate addWeaponCargoGlobal [_item, _count];
                        ["Mission", 3, format["Added weapon %1 x%2 to crate", _item, _count]] call FLO_fnc_log;
                    } else {
                        if (isClass (configFile >> "CfgMagazines" >> _item)) then {
                            _newCrate addMagazineCargoGlobal [_item, _count];
                            ["Mission", 3, format["Added magazine %1 x%2 to crate", _item, _count]] call FLO_fnc_log;
                        } else {
                            if (isClass (configFile >> "CfgVehicles" >> _item)) then {
                                _newCrate addBackpackCargoGlobal [_item, _count];
                                ["Mission", 3, format["Added backpack %1 x%2 to crate", _item, _count]] call FLO_fnc_log;
                            } else {
                                _newCrate addItemCargoGlobal [_item, _count];
                                ["Mission", 3, format["Added item %1 x%2 to crate", _item, _count]] call FLO_fnc_log;
                            };
                        };
                    };
                };
            } forEach _items;
            
            // Verify items were actually added
            private _finalWeapons = weaponCargo _newCrate;
            private _finalMags = magazineCargo _newCrate;
            private _finalItems = itemCargo _newCrate;
            private _finalBags = backpackCargo _newCrate;
            
            ["Mission", 3, format["Crate contents after loading - Weapons: %1, Magazines: %2, Items: %3, Backpacks: %4", 
                count _finalWeapons, 
                count _finalMags, 
                count _finalItems, 
                count _finalBags
            ]] call FLO_fnc_log;
        };
        
        // Make draggable with ACE
        [_newCrate, true, [0, 2, 0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, true];
        
        ["Mission", 3, format["Loaded crate %1 at position %2", _type, _posASL]] call FLO_fnc_log;
    } forEach _allCrateNames;
    
    ["Mission", 3, format["Loaded %1 supply crates", count _allCrateNames]] call FLO_fnc_log;
} else {
    ["Mission", 2, "No saved supply crates found"] call FLO_fnc_log;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

MissionLoadedLitterally = true;
publicVariable "MissionLoadedLitterally";