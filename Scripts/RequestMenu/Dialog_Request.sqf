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

// INFORMATION
FLO_fnc_updateInformation = {
    private _Money = markerText "Money_Handle";

    private _mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
    private _mrkr = _mrkrs select 0;
    private _REPSCORE = parseNumber (markerText _mrkr);  
    private _rep = "Friendly";
    
    if (_REPSCORE < 7) then {
        _rep = "Enemy";
    } else {
        if ((_REPSCORE < 11) && (_REPSCORE > 6)) then {
            _rep = "Neutral";
        };
    };

    private _aggr = "100";
    _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
    _mrkr = _mrkrs select 0;
    private _AGGRSCORE = parseNumber (markerText _mrkr);  
    _aggr = _AGGRSCORE * 6.25;

    ctrlSetText [1000, format["Resources : %1 ", _Money]];
    ctrlSetText [1001, format["Resistance : %1 ",  _rep]];
    ctrlSetText [1002, format["Aggression : %1 %2 ",  _aggr, "%"]];
};

// Populate the UI with available items
if (((typeOf player == "B_G_officer_F") or (typeOf player == F_Officer) or (leader group player == player)) or (isServer) or (player == TheCommander) or ((serverCommandAvailable '#kick') && (serverCommandAvailable '#debug'))) then {
    
    // BIKES
    {
        [
            _x != "",
            [2101, _x, _x, "BIKE", 5, "\A3\Soft_F\Quadbike_01\Data\UI\Quadbike_01_CA.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_Bike_01];
    
    // CARS
    {
        [
            _x != "",
            [2101, _x, _x, "CAR", 35, "Screens\FOBA\Offroad_01_Base_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_Car_01, F_Car_02, F_Car_03, F_Car_04, F_Car_05, F_Car_06];
    
    // MRAPs
    {
        [
            _x != "",
            [2101, _x, _x, "MRAP", 55, "Screens\FOBA\car_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_MRAP_01, F_MRAP_02, F_MRAP_03, F_MRAP_04, F_MRAP_05, F_MRAP_06];
    
    // TRUCKS (Normal)
    {
        [
            _x != "",
            [2101, _x, _x, "TRUCK", 65, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_Truck_01, F_Truck_02, F_Truck_06];
    
    // TRUCKS (Special - Orange)
    {
        [
            _x != "",
            [2101, _x, _x, "TRUCK", 65, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [1,0.6,0,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_Truck_03, F_Truck_04];
    
    // TRUCK RESPAWN (Yellow-Green)
    [
        F_Truck_05 != "",
        [2101, F_Truck_05, F_Truck_05, "TRUCK RESPAWN", 65, "\a3\soft_f_gamma\Truck_01\Data\UI\Truck_01_Ammo_CA.paa", [0.9,1,0,1]]
    ] call FLO_fnc_addConditionalItem;
    
    // APCs - Only if radar is nearby
    private _hasRadar = count (nearestObjects [position player, ["B_Radar_System_01_F", "I_E_Radar_System_01_F"], 500]) > 0;
    
    if (_hasRadar) then {
        {
            [
                _x != "",
                [2101, _x, _x, "APC", 75, "\A3\armor_f_beta\APC_Tracked_01\Data\UI\APC_Tracked_01_AA_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_APC_01, F_APC_02, F_APC_03, F_APC_04, F_APC_05, F_APC_06];
        
        // TANKS - Only if radar is nearby
        {
            [
                _x != "",
                [2101, _x, _x, "TANK", 95, "Screens\FOBA\tank_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_TNK_01, F_TNK_02, F_TNK_03, F_TNK_04];
        
        // ARTILLERY - Only if radar is nearby
        {
            [
                _x != "",
                [2101, _x, _x, "ARTILLERY", 95, "Screens\FOBA\tank_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_Art_01, F_Art_02];
    };
    
    // AIR/SEA SECTION - HELICOPTERS - Only if radar is nearby
    if (_hasRadar) then {
        // Regular helicopters (Blue)
        {
            [
                _x != "",
                [2102, _x, _x, "HELI", 55, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_Heli_01, F_Heli_02, F_Heli_03, F_Heli_05];
        
        // Respawn helicopter (Yellow-Green)
        [
            F_Heli_04 != "",
            [2102, F_Heli_04, F_Heli_04, "HELI RESPAWN", 55, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.9,1,0,1]]
        ] call FLO_fnc_addConditionalItem;
        
        // Gunship helicopters
        {
            [
                _x != "",
                [2102, _x, _x, "HELI GUNSHIP", 80, "\A3\Air_F_Beta\Heli_Transport_01\Data\UI\Heli_Transport_01_base_CA.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_Heli_06_G, F_Heli_07_G];
        
        // Regular planes
        {
            [
                _x != "",
                [2102, _x, _x, "PLANE", 95, "Screens\FOBA\plane_ca.paa", [0.2,0.6,0.99,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_Plane_01_CAS, F_Plane_02_CAS, F_Plane_03, F_Plane_04, F_Plane_05, F_Plane_06];
        
        // USAF DLC Aircraft (if available)
        if (isClass (configfile >> "CfgVehicles" >> "USAF_A10")) then {
            [2102, "USAF_A10", "USAF_A10", "PLANE", 95, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_F22")) then {
            [2102, "USAF_F22", "USAF_F22", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_F22_Heavy")) then {
            [2102, "USAF_F22_Heavy", "USAF_F22_Heavy", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_F35A_STEALTH")) then {
            [2102, "USAF_F35A_STEALTH", "USAF_F35A_STEALTH", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_F35A")) then {
            [2102, "USAF_F35A", "USAF_F35A", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_AC130U")) then {
            [2102, "USAF_AC130U", "USAF_AC130U", "PLANE", 250, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_C130J")) then {
            [2102, "USAF_C130J", "USAF_C130J", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_C130J_Cargo")) then {
            [2102, "USAF_C130J_Cargo", "USAF_C130J_Cargo", "PLANE", 100, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "usaf_kc135")) then {
            [2102, "usaf_kc135", "usaf_kc135", "PLANE", 250, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_C17")) then {
            [2102, "USAF_C17", "USAF_C17", "PLANE", 500, "Screens\FOBA\plane_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
    };
    
    // BOATS (always available)
    [2102, "B_Boat_Transport_01_F", "B_Boat_Transport_01_F", "BOAT", 25, "Screens\FOBA\naval_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    [
        F_ABT_01 != "",
        [2102, F_ABT_01, F_ABT_01, "BOAT", 55, "Screens\FOBA\naval_ca.paa", [1,1,1,1]]
    ] call FLO_fnc_addConditionalItem;
    
    [2102, "B_SDV_01_F", "B_SDV_01_F", "BOAT", 55, "Screens\FOBA\naval_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    // SUPPLIES SECTION
    
    // UAVs
    [2103, "B_UAV_01_F", "B_UAV_01_F", "UAV", 35, "Screens\FOBA\uav_05_icon_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    // Western Sahara UAV (if DLC present)
    if (isClass (configfile >> "CfgFactionClasses" >> "BLU_NATO_lxWS")) then {
        [2103, "B_UAV_02_lxWS", "B_UAV_02_lxWS", "UAV", 35, "Screens\FOBA\uav_05_icon_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    };
    
    // Radar-dependent UAVs
    if (_hasRadar) then {
        // USAF DLC UAVs
        if (isClass (configfile >> "CfgVehicles" >> "USAF_RQ4A")) then {
            [2103, "USAF_RQ4A", "USAF_RQ4A", "UAV", 100, "Screens\FOBA\uav_05_icon_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        if (isClass (configfile >> "CfgVehicles" >> "USAF_MQ9")) then {
            [2103, "USAF_MQ9", "USAF_MQ9", "UAV", 120, "Screens\FOBA\uav_05_icon_ca.paa", [0,1,0,1]] call FLO_fnc_addListBoxItem;
        };
        
        // Custom UAVs
        {
            [
                _x != "",
                [2103, _x, _x, "UAV", 80, "Screens\FOBA\uav_05_icon_ca.paa", [1,1,1,1]]
            ] call FLO_fnc_addConditionalItem;
        } forEach [F_UAV_01, F_UAV_02, F_UAV_03];
    };
    
    // UGVs
    [2103, "B_UGV_02_Demining_F", "B_UGV_02_Demining_F", "UGV", 35, "Screens\FOBA\portrait_UGV_01_CA.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    [
        F_UGV_01 != "",
        [2103, F_UGV_01, F_UGV_01, "UGV", 55, "Screens\FOBA\portrait_UGV_01_CA.paa", [1,1,1,1]]
    ] call FLO_fnc_addConditionalItem;
    
    // CONTAINERS
    [2103, "B_Slingload_01_Medevac_F", "B_Slingload_01_Medevac_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Ammo_F", "B_Slingload_01_Ammo_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Repair_F", "B_Slingload_01_Repair_F", "CONTAINER", 100, "Screens\FOBA\container_ca.paa", [1,0.6,0,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Fuel_F", "B_Slingload_01_Fuel_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    // STATIC WEAPONS
    [2103, "B_W_Static_Designator_01_F", "B_W_Static_Designator_01_F", "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_HMG_01_A_F", "B_HMG_01_A_F", "STATIC", 45, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_GMG_01_A_F", "B_GMG_01_A_F", "STATIC", 45, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
    // Turrets
    {
        [
            _x != "",
            [2103, _x, _x, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]]
        ] call FLO_fnc_addConditionalItem;
    } forEach [F_turret_01, F_turret_02, F_turret_03];
    
    // ARTILLERY (if available)
    if (F_Art_00 != "") then { 
        [2103, F_Art_00, F_Art_00, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    };
    
    // SAM systems (only if radar is nearby)
    if (_hasRadar) then {
        // SAM and AAA systems
        [2103, "B_SAM_System_01_F", "B_SAM_System_01_F", "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [0.2,0.6,0.99,1]] call FLO_fnc_addListBoxItem;
        [2103, "B_SAM_System_02_F", "B_SAM_System_02_F", "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [0.2,0.6,0.99,1]] call FLO_fnc_addListBoxItem;
        [2103, "B_SAM_System_03_F", "B_SAM_System_03_F", "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [0.2,0.6,0.99,1]] call FLO_fnc_addListBoxItem;
        [2103, "B_AAA_System_01_F", "B_AAA_System_01_F", "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [0.2,0.6,0.99,1]] call FLO_fnc_addListBoxItem;
    };
    
    // SUPPLIES
    [2103, "B_CargoNet_01_ammo_F", "B_CargoNet_01_ammo_F", "SUPPLIES", 35, "Screens\FOBA\box_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "Box_NATO_AmmoVeh_F", "Box_NATO_AmmoVeh_F", "SUPPLIES", 35, "Screens\FOBA\box_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    
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

    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    private _mrkr = _mrkrs select 0;
    private _Money = parseNumber (markerText _mrkr);
    
    if (_Money < _Cost) exitWith {
        hint "Not enough Resources";
        closeDialog 0;
    };
    
    _mrkr setMarkerText str (_Money - _Cost);
    
    private _FOBB = nearestObjects [position player, [F_OP_01], 150] select 0;
    private _pos = _FOBB getRelPos [13, 270];
    
    if (_Cost == 3) then {
        // Single unit request
        NEWUNIT = group player createUnit [_SQDName, _pos, [], 0, "FORM"];
        publicVariable "NEWUNIT";
        
        // Add comm menu items
        {
            [NEWUNIT, _x, nil, nil, ''] call BIS_fnc_addCommMenuItem;
        } forEach ['MENU_COMMS_SUPPLYDROP', 'MENU_COMMS_UAV_RECON', 'MENU_COMMS_CAS_HELI', 'MENU_COMMS_ARTI'];
        
        NEWUNIT linkItem 'B_UavTerminal';
        NEWUNIT addItem 'optic_Hamr';
    } else {
        // Squad request
        GRPReq = [_pos, west, _SQDName] call BIS_fnc_spawnGroup;
        publicVariable "GRPReq";
        
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
    
    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    private _mrkr = _mrkrs select 0;
    private _Money = parseNumber (markerText _mrkr);
    
    if (_Money < CostV) exitWith {
        hint "Not Enough Resources";
        closeDialog 0;
    };
    
    _mrkr setMarkerText str (_Money - CostV);
    
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
    Ind01 = [player,
        "<t color='#FF0000'>CANCEL</t>",
        'Screens\FOBA\iconRepairAt_ca.paa',
        'Screens\FOBA\iconRepairAt_ca.paa',
        'true',
        'true',
        {},
        {},
        {
            detach CreatedVEH;
            CreatedVEH enableSimulation true;
            deleteVehicle CreatedVEH;
            
            // Refund cost
            _mrkrs = allMapMarkers select {markerColor _x == 'Color2_FD_F'};
            _mrkr = _mrkrs select 0;
            _Money = parseNumber (markerText _mrkr);
            _mrkr setMarkerText str (_Money + CostV);
            
            deleteVehicle CreatedVEHREF;
            player removeAction Ind01;
            player removeAction Ind02;
            player removeAction Ind03;
        },
        {},
        [],
        3,
        0,
        false,
        false
    ] call BIS_fnc_holdActionAdd;
    
    Ind02 = [player,
        "<t color='#FF0000'>PLACE (crew)</t>",
        'Screens\FOBA\iconRepairAt_ca.paa',
        'Screens\FOBA\iconRepairAt_ca.paa',
        'true',
        'true',
        {},
        {},
        {
            // Place vehicle with crew
            [CreatedVEH, CreatedVEHREF] call FLO_fnc_placeVehicleWithCrew;
            
            // Cleanup
            player removeAction Ind01;
            player removeAction Ind02;
            player removeAction Ind03;
        },
        {},
        [],
        3,
        0,
        false,
        false
    ] call BIS_fnc_holdActionAdd;
    
    Ind03 = [player,
        "<t color='#FF0000'>PLACE</t>",
        'Screens\FOBA\iconRepairAt_ca.paa',
        'Screens\FOBA\iconRepairAt_ca.paa',
        'true',
        'true',
        {},
        {},
        {
            // Place vehicle without crew
            detach CreatedVEH;
            CreatedVEH setVehiclePosition [getPos CreatedVEHREF, [], 0, "CAN_COLLIDE"];
            CreatedVEH enableSimulation true;
            CursorTracker = false;
            deleteVehicle CreatedVEHREF;
            CreatedVEH enableSimulation true;
            CreatedVEH allowDamage true;
            
            // Cleanup
            player removeAction Ind01;
            player removeAction Ind02;
            player removeAction Ind03;
        },
        {},
        [],
        3,
        0,
        false,
        false
    ] call BIS_fnc_holdActionAdd;
    
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
    
    // Configure ammo cargo container
    if (_VehName == "B_CargoNet_01_ammo_F") then {
        // Add various ammo and equipment
        _vehicle addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 20];
        _vehicle addMagazineCargoGlobal ["APERSBoundingMine_Range_Mag", 7];
        _vehicle addMagazineCargoGlobal ["APERSMine_Range_Mag", 7];
        _vehicle addMagazineCargoGlobal ["ClaymoreDirectionalMine_Remote_Mag", 7];
        _vehicle addMagazineCargoGlobal ["SLAMDirectionalMine_Wire_Mag", 7];
        _vehicle addMagazineCargoGlobal ["B_IR_Grenade", 7];
        _vehicle addMagazineCargoGlobal ["SmokeShell", 7];
        _vehicle addMagazineCargoGlobal ["HandGrenade", 7];
        
        // Add backpacks
        {
            _vehicle addBackpackCargoGlobal [_x, 2];
        } forEach [
            "B_UAV_01_backpack_F",
            "B_Static_Designator_01_weapon_F",
            "B_W_Static_Designator_01_weapon_F",
            "B_UGV_02_Demining_backpack_F",
            "B_Patrol_Respawn_bag_F"
        ];
        
        // Add weapons and ammo
        {
            _vehicle addWeaponCargoGlobal [_x, 5];
        } forEach [
            "launch_B_Titan_tna_F",
            "launch_B_Titan_F",
            "launch_B_Titan_short_F",
            "launch_I_Titan_short_F",
            "launch_NLAW_F"
        ];
        
        {
            _vehicle addMagazineCargoGlobal [_x, 15];
        } forEach [
            "NLAW_F",
            "MRAWS_HEAT_F",
            "Titan_AT",
            "Titan_AA",
            "Titan_AP"
        ];
        
        // Add Arsenal and Rearm actions
        [_vehicle, "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true) then {
                    [player, player, true] call ace_arsenal_fnc_openBox;
                } else {
                    ["Open", true] spawn BIS_fnc_arsenal;
                };
            },
            {},
            [],
            1,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
        
        [_vehicle, "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Infantry",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                [(_this select 0)] execVM "Scripts\REARM.sqf";
            },
            {},
            [],
            1,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
    };
    
    // Configure mobile workshop (F_Truck_04)
    _MOBSERName = missionNamespace getVariable "F_Truck_04";
    if (_VehName == _MOBSERName) then {
        if (!isNil "_vehicle" && {!isNull _vehicle}) then {
            [[_vehicle, -1, west, "LIGHT"], "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"] remoteExec ["execVM", 0, true];
        };
        
        [_vehicle, "<img size=2 color='#f37c00' image='\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa'/><t font='PuristaBold' color='#f37c00'>REPAIR Vehicles",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                [(_this select 0)] execVM "Scripts\REPAIRVEH.sqf";
            },
            {},
            [],
            10,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
    };
    
    // Configure ammo truck (F_Truck_03)
    _MOBSERName = missionNamespace getVariable "F_Truck_03";
    if (_VehName == _MOBSERName) then {
        [_vehicle, "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true) then {
                    [player, player, true] call ace_arsenal_fnc_openBox;
                } else {
                    ["Open", true] spawn BIS_fnc_arsenal;
                };
            },
            {},
            [],
            1,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
        
        [_vehicle, "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Infantry",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                [(_this select 0)] execVM "Scripts\REARM.sqf";
            },
            {},
            [],
            5,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
        
        [_vehicle, "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Vehicles",
            "Screens\FOBA\mg_ca.paa",
            "Screens\FOBA\mg_ca.paa",
            "_this distance _target < 10",
            "_caller distance _target < 10",
            {},
            {},
            {
                [(_this select 0)] execVM "Scripts\REARMVEH.sqf";
            },
            {},
            [],
            10,
            1,
            false,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
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

   
