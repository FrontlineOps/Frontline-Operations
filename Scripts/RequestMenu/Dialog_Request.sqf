createDialog "supr_RequestsMenu";
waitUntil {dialog};

// Helper function to add items to a list box
FLO_fnc_addListBoxItem = {
    params [
        ["_idc", 2100, [0]],
        ["_className", "", [""]],
        ["_displayName", "", [""]],
        ["_category", "", [""]],
        ["_cost", 0, [0]],
        ["_picture", "", [""]],
        ["_color", [1,1,1,1], [[]]]
    ];
    
    if (_className == "") exitWith {};
    
    // Get display name from config if available, otherwise use provided displayName
    private _configDisplayName = getText (configFile >> "CfgVehicles" >> _className >> "displayName");
    if (_configDisplayName == "") then {
        _configDisplayName = _displayName;
    };
    
    private _txt = format ["%1$ | %2 (%3)", _cost, _configDisplayName, _category];
    private _index = lbAdd [_idc, _txt];            
    lbSetColor [_idc, _index, _color];   
    lbSetData [_idc, _index, _className];             
    lbSetValue [_idc, _index, _cost];             
    lbSetPictureRight [_idc, _index, _picture]; 
    (findDisplay 1599 displayCtrl _idc) lbSetPictureRightColor [_index, _color];
    
    _index
};

// Helper function to check prerequisites and add item
FLO_fnc_addConditionalItem = {
    params [
        ["_condition", true, [true]],
        ["_params", [], [[]]]
    ];
    
    if (_condition) then {
        _params call FLO_fnc_addListBoxItem;
    };
};

// Helper function to add vehicles from a list where each entry can be either a
// classname string or [classname, cost]. The provided default cost is used when
// an entry does not include a custom value.

// INFORMATION
FLO_fnc_updateInformation = {
    private _Money = FLO_MoneyHandle get "value"; 
    private _REPSCORE = FLO_ReputationHandle get "value";  
    private _rep = "Friendly";
    
    if (_REPSCORE < 7) then {
        _rep = "Enemy";
    } else {
        if ((_REPSCORE < 11) && (_REPSCORE > 6)) then {
            _rep = "Neutral";
        };
    };

    private _aggr = "100";
    private _AGGRSCORE = FLO_DifficultyHandle get "value";  
    _aggr = _AGGRSCORE * 6.25;

    ctrlSetText [1000, format["Resources : %1 ", _Money]];
    ctrlSetText [1001, format["Resistance : %1 ",  _rep]];
    ctrlSetText [1002, format["Aggression : %1 %2 ",  _aggr, "%"]];
};

// Populate the UI with available items
if (((typeOf player == "B_G_officer_F") or (typeOf player == F_Officer) or (leader group player == player)) or (isServer) or (player == TheCommander) or ((serverCommandAvailable '#kick') && (serverCommandAvailable '#debug'))) then {
    
    // BIKES
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "BIKE", _price, "\A3\Soft_F\Quadbike_01\Data\UI\Quadbike_01_CA.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Bike_List;
    
    // CARS
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "CAR", _price, "Screens\FOBA\Offroad_01_Base_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Car_List;
    
    // MRAPs
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "MRAP", _price, "Screens\FOBA\car_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_MRAP_List;
    
    // TRUCKS (Normal)
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "TRUCK", _price, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Truck_List;
    
    // TRUCKS (Special - Orange)
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "TRUCK", _price, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [1,0.6,0,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Truck_Special_List;
    
    // TRUCK RESPAWN (Yellow-Green)
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2101, _veh, _veh, "TRUCK RESPAWN", _price, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [0.9,1,0,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Truck_Respawn_List;
    
    // APCs - Only if radar is nearby
    private _hasRadar = count (nearestObjects [position player, ["B_Radar_System_01_F", "I_E_Radar_System_01_F"], 500]) > 0;
    
    if (_hasRadar) then {
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2101, _veh, _veh, "APC", _price, "\A3\armor_f_beta\APC_Tracked_01\Data\UI\APC_Tracked_01_AA_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_APC_List;
        
        // TANKS - Only if radar is nearby
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2101, _veh, _veh, "TANK", _price, "Screens\FOBA\tank_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_Tank_List;
        
        // ARTILLERY - Only if radar is nearby
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2101, _veh, _veh, "ARTILLERY", _price, "Screens\FOBA\tank_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_Artillery_List;
    };
    
    // AIR/SEA SECTION - HELICOPTERS - Only if radar is nearby
    if (_hasRadar) then {
        // Regular helicopters (Blue)
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2102, _veh, _veh, "HELI", _price, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_Heli_List;
        
        // Respawn helicopter (Yellow-Green)
        private _heliRespawn = F_Heli_Respawn_List;
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2102, _veh, _veh, "HELI RESPAWN", _price, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.9,1,0,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach _heliRespawn;
        
        // Gunship helicopters
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2102, _veh, _veh, "HELI GUNSHIP", _price, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_Heli_Gunship_List;
        
        // Regular planes
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2102, _veh, _veh, "PLANE", _price, "Screens\FOBA\plane_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_Plane_List;
    };

    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2102, _veh, _veh, "BOAT", _price, "Screens\FOBA\naval_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Boat_List;
    
    // Radar-dependent UAVs
    if (_hasRadar) then {
        // Custom UAVs
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2103, _veh, _veh, "UAV", _price, "Screens\FOBA\uav_05_icon_ca.paa", [1,1,1,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_UAV_List;
    
    };
    
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2103, _veh, _veh, "UGV", _price, "Screens\FOBA\portrait_UGV_01_CA.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_UGV_List;

    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2103, _veh, _veh, "CONTAINER", _price, "Screens\FOBA\container_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Container_List;


    // Turrets
    {
        private _veh = _x select 0;
        private _price = _x select 1;
        [
            _veh != "",
            [2103, _veh, _veh, "STATIC", _price, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach F_Turret_List;

    
    // ARTILLERY (if available)
    if (F_Art_00 != "") then {
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2103, _veh, _veh, "STATIC", _price, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [[F_Art_00, 35]];
    };

    if (_hasRadar) then {
        // SAM and AAA systems
        {
            private _veh = _x select 0;
            private _price = _x select 1;
            [
                _veh != "",
                [2103, _veh, _veh, "STATIC", _price, "Screens\FOBA\icon_HMG_02_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach F_SAM_List;
    }

    
    // RADAR system
    if (F_RADAR != "") then { 
        [2103, F_RADAR, F_RADAR, "OPERATION CONTROL SYSTEM", 250, "Screens\FOBA\Radar_ca.paa", [0.2,0.6,0.99,1]] call FLO_fnc_addListBoxItem;
    };
};

// Update info displays
[] call FLO_fnc_updateInformation;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Optimized INF_REQUEST function
INF_REQUEST = {
    private _CTRL = 2100;
    private _index = lbCurSel _CTRL;
    private _Name = lbData [_CTRL, _index];
    private _Cost = lbValue [_CTRL, _index];
    private _SQDName = missionNamespace getVariable _Name;

    private _Money = FLO_MoneyHandle get "value";
    
    if (_Money < _Cost) exitWith {
        hint "Not enough Resources";
        closeDialog 0;
    };
    
    FLO_MoneyHandle set ["value", _Money - _Cost];
    
    private _FOBB = nearestObjects [position player, [F_OP_01], 150] select 0;
    private _pos = _FOBB getRelPos [13, 270];
    
    if (_Cost == 3) then {
        // Single unit request
        NEWUNIT = group player createUnit [_SQDName, _pos, [], 0, "FORM"];
        
        // Add comm menu items
        {
            [NEWUNIT, _x, nil, nil, ''] call BIS_fnc_addCommMenuItem;
        } forEach ['MENU_COMMS_SUPPLYDROP', 'MENU_COMMS_UAV_RECON', 'MENU_COMMS_CAS_HELI', 'MENU_COMMS_ARTI'];
        
        NEWUNIT linkItem 'B_UavTerminal';
        NEWUNIT addItem 'optic_Hamr';
    } else {
        // Squad request
        GRPReq = [_pos, west, _SQDName] call BIS_fnc_spawnGroup;
        
        // Process all units in squad
        {
            // Add comm menu items to each unit
            {
                [_x, _x, nil, nil, ''] call BIS_fnc_addCommMenuItem;
            } forEach ['MENU_COMMS_SUPPLYDROP', 'MENU_COMMS_UAV_RECON', 'MENU_COMMS_CAS_HELI', 'MENU_COMMS_ARTI'];
            
            // Enable radio protocol
            _x enableAI 'RADIOPROTOCOL';
        } forEach units GRPReq;
        
        // High command group assignment
        private _headlessClients = entities "HeadlessClient_F";
        private _humanPlayers = allPlayers - _headlessClients;
        hcRemoveAllGroups player;
        {player hcRemoveGroup _x;} forEach (allGroups select {side _x == west});
        private _GRPs = (allGroups select {(side _x == (side player)) && !(((units _x) select 0) in switchableUnits)});
        
        if (count _humanPlayers == 1) then {
            {player hcSetGroup [_x];} forEach _GRPs;
        } else {
            {TheCommander hcSetGroup [_x];} forEach _GRPs;
        };
        
        // Set unit traits based on role
        {
            if ((typeOf _x == F_Assault_Eng) || (typeOf _x == "B_G_engineer_F") || (typeOf _x == F_Recon_Eng) || (typeOf _x == "B_CTRG_soldier_engineer_exp_F")) then {
                _x setUnitTrait ["engineer", true];
                _x setVariable ["ACE_isEngineer", true];
            };
            
            if ((typeOf _x == F_Assault_Eod) || (typeOf _x == F_Recon_Eod) || (typeOf _x == "B_CTRG_soldier_engineer_exp_F") || (typeOf _x == "B_G_Soldier_exp_F")) then {
                _x setUnitTrait ["explosiveSpecialist", true];
                _x setVariable ["ACE_isEOD", true];
            };
            
            if ((typeOf _x == F_Recon_Med) || (typeOf _x == F_Assault_Med) || (typeOf _x == "B_G_medic_F") || (typeOf _x == "B_CTRG_soldier_M_medic_F")) then {
                _x setUnitTrait ["medic", true];
                _x setVariable ["ace_medical_medicclass", 2, true];
            };
        } forEach units GRPReq;
        
        closeDialog 0;
    };
};

// Optimized VEH_REQUEST function
VEH_REQUEST = {
    params ["_CTRL"];
    private _index = lbCurSel _CTRL;
    private _VehName = lbData [_CTRL, _index];
    CostV = lbValue [_CTRL, _index];
    
    private _Money = FLO_MoneyHandle get "value";
    
    if (_Money < CostV) exitWith {
        hint "Not Enough Resources";
        closeDialog 0;
    };
    
    FLO_MoneyHandle set ["value", _Money - CostV];
    
    private _pos = [getPosATL player select 0, getPosATL player select 1, (getPosATL player select 2) + 100];
    CreatedVEH = createVehicle [_VehName, _pos, [], 0, 'NONE'];
    
    // Apply vehicle-specific configurations
    [_VehName, CreatedVEH] call FLO_fnc_configureVehicle;
    
    // Setup placement system
    CursorTracker = true;
    CreatedVEH enableSimulation false;
    CreatedVEH allowDamage false;
    CreatedVEHREF = createVehicle ["Sign_Sphere10cm_F", screenToWorld [0.5, 0.5], [], 0, "NONE"];
    CreatedVEHREF hideObjectGlobal true;
    CreatedVEHREF allowDamage false;
    CreatedVEH attachTo [CreatedVEHREF, [0, 0, 3]];
    
    [] spawn {
        while {CursorTracker} do {
            CreatedVEHREF setVehiclePosition [screenToWorld [0.5, 0.5], [], 0, "CAN_COLLIDE"];
            CreatedVEHREF setDir ((getDirVisual player) + 230);
            sleep 0.3;
        };
    };
    
    // Add action menu items
    private _actionIDs = [];
    
    _actionIDs pushBack (player addAction [
        "<t color='#FF0000'>CANCEL</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            private _actionIDs = _arguments;
            
            detach CreatedVEH;
            CreatedVEH enableSimulation true;
            deleteVehicle CreatedVEH;
            
            // Refund cost
            private _Money = FLO_MoneyHandle get "value";
            FLO_MoneyHandle set ["value", _Money + CostV];
            
            deleteVehicle CreatedVEHREF;
            
            // Remove all actions
            {
                player removeAction _x;
            } forEach _actionIDs;
        },
        _actionIDs,
        1.5,
        true,
        true,
        "",
        "true",
        50
    ]);
    
    _actionIDs pushBack (player addAction [
        "<t color='#FF0000'>PLACE (crew)</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            private _actionIDs = _arguments;
            
            // Place vehicle with crew
            [CreatedVEH, CreatedVEHREF] call FLO_fnc_placeVehicleWithCrew;
            
            // Remove all actions
            {
                player removeAction _x;
            } forEach _actionIDs;
        },
        _actionIDs,
        1.5,
        true,
        true,
        "",
        "true",
        50
    ]);
    
    _actionIDs pushBack (player addAction [
        "<t color='#FF0000'>PLACE</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            private _actionIDs = _arguments;
            
            // Place vehicle without crew
            detach CreatedVEH;
            CreatedVEH setVehiclePosition [getPos CreatedVEHREF, [], 0, "CAN_COLLIDE"];
            CreatedVEH enableSimulation true;
            CursorTracker = false;
            deleteVehicle CreatedVEHREF;
            CreatedVEH enableSimulation true;
            CreatedVEH allowDamage true;
            
            // Remove all actions
            {
                player removeAction _x;
            } forEach _actionIDs;
        },
        _actionIDs,
        1.5,
        true,
        true,
        "",
        "true",
        50
    ]);
    
    closeDialog 0;
};

// Helper function to configure specific vehicle types
FLO_fnc_configureVehicle = {
    params ["_VehName", "_vehicle"];
    
    // Apply Stryker textures
    if ((_VehName == "rhsusf_stryker_m1126_m2_d") or (_VehName == "rhsusf_stryker_m1126_mk19_d") or (_VehName == "rhsusf_stryker_m1134_d")) then {
        [_vehicle, ["Tan", 1]] call BIS_fnc_initVehicle;
    };
    
    // Apply textures to MRZR in woodland environment
    if (((markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ CUP + RHS") or 
         (markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ RHS")) && 
         (_VehName == "rhsusf_mrzr4_d")) then {
        [_vehicle, ["mud_olive", 1]] call BIS_fnc_initVehicle;
    };
    
    // Configure repair slingload container
    if (_VehName == "B_Slingload_01_Repair_F") then {
        [_vehicle, [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
            "Scripts\PObjectives\OPUNPACK.sqf",
            nil,
            0,
            true,
            true,
            "",
            "true",
            40,
            false,
            "",
            ""
        ]] remoteExec ["addAction", 0, true];
    };
    
    // Configure mobile workshop (F_Truck_04)
    _MOBSERName = missionNamespace getVariable "F_Truck_04";
    if (_VehName == _MOBSERName) then {
        if (!isNil "_vehicle" && {!isNull _vehicle}) then {
            [_vehicle, [
                "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode", 
                { [player] call IDS_Logistics_fnc_initBuildCamera; }, 
                nil, 
                1.4, 
                false, 
                true, 
                "", 
                "!IDS_Logistics_isHolding"
            ]] remoteExec ["addAction", 0, true];
        };
    };
    
    // Configure ammo truck (F_Truck_03)
    _MOBSERName = missionNamespace getVariable "F_Truck_03";
    if (_VehName == _MOBSERName) then {
        [_vehicle, [
            "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
            {
                if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true) then {
                    [player, player, true] call ace_arsenal_fnc_openBox;
                } else {
                    ["Open", true] spawn BIS_fnc_arsenal;
                };
            },
            nil,
            1,
            true,
            true,
            "",
            "_this distance _target < 10"
        ]] remoteExec ["addAction", 0, true];
    };
};

// Helper function to place vehicle with crew
FLO_fnc_placeVehicleWithCrew = {
    params ["_vehicle", "_reference"];
    
    detach _vehicle;
    _vehicle setVehiclePosition [getPos _reference, [], 0, "CAN_COLLIDE"];
    _vehicle enableSimulation true;
    CursorTracker = false;
    deleteVehicle _reference;
    _vehicle enableSimulation true;
    _vehicle allowDamage true;
    
    // Create crew
    private _vehicleConfig = (configFile >> "CfgVehicles" >> typeOf _vehicle);
    private _crewType = [west, _vehicleConfig] call BIS_fnc_selectCrew;
    private _crewFull = createVehicleCrew _vehicle;
    private _crewSelCnt = count (units _crewFull) - 1;
    deleteVehicleCrew _vehicle;
    
    private _group = createGroup West;
    for "_x" from 0 to _crewSelCnt do {
        private _unit = _group createUnit [_crewType, [0,0,0], [], 0, "CAN_COLLIDE"];
    };
    
    {_x moveInAny _vehicle} forEach units _group;
    
    // Disable Vcom AI for helicopters
    private _isHeli = false;
    {
        private _heliName = missionNamespace getVariable _x;
        if (typeOf _vehicle == _heliName) exitWith {_isHeli = true};
    } forEach ["F_Heli_01", "F_Heli_02", "F_Heli_03", "F_Heli_04", "F_Heli_05"];
    
    if (_isHeli) then {
        _group setVariable ["Vcm_Disable", true];
    };
    
    // Add to high command
    TheCommander hcSetGroup [_group];
};

   
