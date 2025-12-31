if ((typeOf player == F_Officer) || (typeOf player == "B_G_officer_F")) then {
    // Define cost and check resources
    Cost = 1500;
    private _money = FLO_MoneyHandle get "value";
    
    if (_money >= Cost) then {
        // Deduct cost
        private _newMoney = _money - Cost;
        FLO_MoneyHandle set ["value", _newMoney];
        publicVariable "FLO_MoneyHandle";

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
        [CreatedVEH, [
            "<t color='#FF0000'>CANCEL</t>",
            {
                params ["_target"];
                detach _target;
                _target enableSimulation true;
                deleteVehicle _target;
                
                // Refund cost
                private _newMoney = (FLO_MoneyHandle get "value") + Cost;
                FLO_MoneyHandle set ["value", _newMoney];
                publicVariable "FLO_MoneyHandle";
            },
            nil,
            3,
            true,
            true,
            "",
            "true"
        ]] remoteExec ["addAction", 0, true];
        
        // Add place action
        [CreatedVEH, [
            "<t color='#FF0000'>PLACE</t>",
            {
                params ["_target"];
                // Place the FOB container
                detach _target;
                _target enableSimulation true;
                
                // End placement mode
                CursorTracker = false;
                _target allowDamage true;
                
                // Add unpack action
                [_target, [
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
            nil,
            3,
            true,
            true,
            "",
            "true"
        ]] remoteExec ["addAction", 0, true];

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