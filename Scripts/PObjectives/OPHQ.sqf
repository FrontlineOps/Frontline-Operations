if ((typeOf player == F_Officer) || (typeOf player == "B_G_officer_F")) then {
    Cost = 100;
    private _money = FLO_MoneyHandle get "value";
    
    if (_money >= Cost) then {
        private _newMoney = _money - Cost;
        FLO_MoneyHandle set ["value", _newMoney];
        [_newMoney] call FLO_fnc_publishMoneyState;

        private _pos = [getPosATL player select 0, getPosATL player select 1, (getPosATL player select 2) + 1000];
        private _createdVEH = createVehicle ["B_Slingload_01_Repair_F", _pos, [], 0, "NONE"];
        _createdVEH allowDamage false;
        
        // Make the variable global
        CreatedVEH = _createdVEH;
        CursorTracker = true;
        
        CreatedVEH enableSimulation false;

        [] spawn {  
            while {CursorTracker} do {  
                CreatedVEH setVehiclePosition [screenToWorld [0.5, 0.5], [], 0, "CAN_COLLIDE"];
                CreatedVEH setDir ((getDirVisual player) + 230);
                sleep 0.3;
            }
        };

        [CreatedVEH, "OP_DEPLOYABLE", [[
            "<t color='#FF0000'>CANCEL</t>",
            {
                params ["_target"];
                detach _target;
                _target enableSimulation true;
                deleteVehicle _target;
                
                private _newMoney = (FLO_MoneyHandle get "value") + Cost;
                FLO_MoneyHandle set ["value", _newMoney];
                [_newMoney] call FLO_fnc_publishMoneyState;
            },
            nil,
            3,
            true,
            true,
            "",
            "true"
        ], [
            "<t color='#FF0000'>PLACE</t>",
            {
                params ["_target"];
                detach _target;
                _target enableSimulation true;
                CursorTracker = false;
                _target allowDamage true;
                
                [_target, "OP_DEPLOYABLE", [[
                    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
                    "Scripts\PObjectives\OPUNPACK.sqf",
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
                ], [
                    "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>",
                    { [player, true] call IDS_Logistics_fnc_initBuildCamera; },
                    nil,
                    1.4,
                    false,
                    true,
                    "",
                    "!IDS_Logistics_isHolding"
                ]]] remoteExec ["FLO_fnc_configureObjectActionsLocal", 0, _target];
            },
            nil,
            3,
            true,
            true,
            "",
            "true"
        ], [
            "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>",
            { [player, true] call IDS_Logistics_fnc_initBuildCamera; },
            nil,
            1.4,
            false,
            true, 
            "", 
            "!IDS_Logistics_isHolding"
        ]]] remoteExec ["FLO_fnc_configureObjectActionsLocal", 0, CreatedVEH];

        CreatedVEH setVariable ["IDS_Logistics_isPlacedEntity", true, true];

    } else {
        hint "Not enough Resources";
    };
} else {
    hint "You are not authorized for this Request Soldier!";
};

closeDialog 0;
