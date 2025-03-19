if ((typeOf player == F_Officer) || (typeOf player == "B_G_officer_F")) then {
    // Define cost and check resources
    Cost = 1500;
    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    private _mrkr = _mrkrs select 0;
    private _money = parseNumber (markerText _mrkr);
    
    if (_money >= Cost) then {
        // Deduct cost
        private _newMoney = _money - Cost;
        _mrkr setMarkerText str _newMoney;
        
        // Create FOB container
        private _pos = [getPosATL player select 0, getPosATL player select 1, (getPosATL player select 2) + 1000];
        CreatedVEH = createVehicle ["B_Slingload_01_Cargo_F", _pos, [], 0, "NONE"];
        CreatedVEH allowDamage false;
        
        // Setup placement mode
        CursorTracker = true;
        CreatedVEH enableSimulation false;
        
        // Position tracking script
        [] spawn {
            while {CursorTracker} do {
                CreatedVEH setVehiclePosition [screenToWorld [0.5, 0.5], [], 0, "CAN_COLLIDE"];
                CreatedVEH setDir ((getDirVisual player) + 230);
                sleep 0.3;
            };
        };
        
        // Add cancel action
        Ind01 = [CreatedVEH,
            "<t color='#FF0000'>CANCEL</t>",
            'Screens\FOBA\iconRepairAt_ca.paa',
            'Screens\FOBA\iconRepairAt_ca.paa',
            'true',
            'true',
            {},
            {},
            {
                detach (_this select 0);
                (_this select 0) enableSimulation true;
                deleteVehicle (_this select 0);
                
                // Refund cost
                private _mrkrs = allMapMarkers select {markerColor _x == 'Color2_FD_F'};
                private _mrkr = _mrkrs select 0;
                private _money = parseNumber (markerText _mrkr);
                private _newMoney = _money + Cost;
                _mrkr setMarkerText str _newMoney;
            },
            {},
            [],
            3,
            0,
            false,
            false
        ] call BIS_fnc_holdActionAdd;
        
        // Add place action
        Ind02 = [CreatedVEH,
            "<t color='#FF0000'>PLACE</t>",
            'Screens\FOBA\iconRepairAt_ca.paa',
            'Screens\FOBA\iconRepairAt_ca.paa',
            'true',
            'true',
            {},
            {},
            {
                // Place the FOB container
                detach (_this select 0);
                (_this select 0) enableSimulation true;
                
                // End placement mode
                CursorTracker = false;
                (_this select 0) allowDamage true;
                
                // Remove placement actions
                (_this select 0) removeAction Ind01;
                (_this select 0) removeAction Ind02;
                
                // Add unpack action
                [(_this select 0), [
                    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
                    "Scripts\PObjectives\FOBUNPACK.sqf",
                    nil,
                    0,
                    true,
                    true,
                    "",
                    "player == TheCommander",
                    25,
                    false,
                    "",
                    ""
                ]] remoteExec ["addAction", 0, true];
            },
            {},
            [],
            3,
            0,
            false,
            false
        ] call BIS_fnc_holdActionAdd;

        CreatedVEH setVariable ["IDS_Logistics_isPlacedEntity", true, true];

        [CreatedVEH, [
            "<t font='PuristaBold' color='#FF0000' size='1.15'>Move FOB</t>", 
            { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, 
            nil, 
            1.4, 
            false, 
            true, 
            "", 
            "!IDS_Logistics_isHolding"
        ]] remoteExec ["addAction", 0, true];
    } else {
        hint "Not enough Resources";
    };
} else {
    hint "You are not authorized for this Request Soldier!";
};

closeDialog 0;