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

if ( ((typeOf player == "B_G_officer_F") or (typeOf player == F_Officer) or (leader group player == player)) or (isServer) or (player == TheCommander) or ((serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) ) then {

    // CONTAINERS
    [2103, "B_Slingload_01_Medevac_F", "B_Slingload_01_Medevac_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Ammo_F", "B_Slingload_01_Ammo_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Repair_F", "B_Slingload_01_Repair_F", "CONTAINER", 100, "Screens\FOBA\container_ca.paa", [1,0.6,0,1]] call FLO_fnc_addListBoxItem;
    [2103, "B_Slingload_01_Fuel_F", "B_Slingload_01_Fuel_F", "CONTAINER", 35, "Screens\FOBA\container_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;

    // STATIC WEAPONS
    [2103, F_turret_01, F_turret_01, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, F_turret_02, F_turret_02, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    [2103, F_turret_03, F_turret_03, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;

    // ARTILLERY (if available)
    if (F_Art_00 != "") then { 
        [2103, F_Art_00, F_Art_00, "STATIC", 35, "Screens\FOBA\icon_HMG_02_ca.paa", [1,1,1,1]] call FLO_fnc_addListBoxItem;
    };
};

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

    ctrlSetText [1000, format["Resources : %1", _Money]];
    ctrlSetText [1001, format["Resistance : %1", _rep]];
    ctrlSetText [1002, format["Aggression : %1 %2", _aggr, "%"]];
};

// Call the function to update information displays
[] call FLO_fnc_updateInformation;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

INF_REQUEST = {
    private _CTRL = 2100;
    private _index = lbCurSel _CTRL;
    private _Name = lbData [_CTRL, _index];
    private _Cost = lbValue [_CTRL, _index];
    private _SQDName = missionNamespace getVariable _Name;
    
    // Get current resources
    private _Money = FLO_MoneyHandle get "value";
    
    // Check if enough resources are available
    if (_Money < _Cost) exitWith {
        hint "Not enough Resources";
        closeDialog 0;
    };
    
    // Deduct the cost
    FLO_MoneyHandle set ["value", _Money - _Cost];
    
    // Find spawn position
    private _FOBB = nearestObjects [position player, [F_OP_01], 150] select 0;
    private _pos = _FOBB getRelPos [13, 270];
    
    if (_Cost == 3) then {
        // Single unit request
        [_SQDName, _pos] call FLO_fnc_spawnSingleUnit;
    } else {
        // Squad request
        [_SQDName, _pos] call FLO_fnc_spawnSquad;
        closeDialog 0;
    };
};

// Helper function to spawn a single unit
FLO_fnc_spawnSingleUnit = {
    params ["_unitType", "_spawnPos"];
    
    // Create the unit
    NEWUNIT = group player createUnit [_unitType, _spawnPos, [], 0, "FORM"];
    
    // Add comm menu items
    {
        [NEWUNIT, _x, nil, nil, ''] call BIS_fnc_addCommMenuItem;
    } forEach ['MENU_COMMS_SUPPLYDROP', 'MENU_COMMS_UAV_RECON', 'MENU_COMMS_CAS_HELI', 'MENU_COMMS_ARTI'];
    
    // Add equipment
    NEWUNIT linkItem 'B_UavTerminal';
    NEWUNIT addItem 'optic_Hamr';
};

// Helper function to spawn a squad
FLO_fnc_spawnSquad = {
    params ["_squadComp", "_spawnPos"];
    
    // Create the squad
    GRPReq = [_spawnPos, west, _squadComp] call BIS_fnc_spawnGroup;
    
    // Process all units in the group
    {
        // Add comm menu items
        {
            [_x, _x, nil, nil, ''] call BIS_fnc_addCommMenuItem;
        } forEach ['MENU_COMMS_SUPPLYDROP', 'MENU_COMMS_UAV_RECON', 'MENU_COMMS_CAS_HELI', 'MENU_COMMS_ARTI'];
        
        // Enable radio protocol for AI communication
        _x enableAI 'RADIOPROTOCOL';
    } forEach units GRPReq;
    
    // High command integration
    [GRPReq] call FLO_fnc_assignToHighCommand;
    
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
};

// Helper function to assign groups to high command
FLO_fnc_assignToHighCommand = {
    params ["_group"];
    
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
};

// Optimized VEH_REQUEST function
VEH_REQUEST = {
    params ["_CTRL"];
    private _index = lbCurSel _CTRL;
    private _VehName = lbData [_CTRL, _index];
    CostV = lbValue [_CTRL, _index];
    
    // Check resources
    private _Money = FLO_MoneyHandle get "value";
    
    if (_Money < CostV) exitWith {
        hint "Not Enough Resources";
        closeDialog 0;
    };
    
    // Deduct cost
    FLO_MoneyHandle set ["value", _Money - CostV];
    
    // Create vehicle
    private _pos = [getPosATL player select 0, getPosATL player select 1, (getPosATL player select 2) + 100];
    CreatedVEH = createVehicle [_VehName, _pos, [], 0, 'NONE'];
    
    // Apply vehicle-specific configurations
    [CreatedVEH, _VehName] call FLO_fnc_configureVehicle;
    
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
    params ["_vehicle", "_VehName"];
    
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
    private _MOBSERName = missionNamespace getVariable "F_Truck_04";
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