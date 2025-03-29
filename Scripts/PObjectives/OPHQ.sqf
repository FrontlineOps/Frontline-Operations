if ((typeOf player == F_Officer) || (typeOf player == "B_G_officer_F")) then {
    Cost = 100;
    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    private _mrkr = _mrkrs select 0;
    private _money = parseNumber (markerText _mrkr);
    
    if (_money >= Cost) then {
        private _newMoney = _money - Cost; 
        _mrkr setMarkerText str _newMoney;

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

        private _ind01 = [CreatedVEH, [
            "<t color='#FF0000'>CANCEL</t>",
            {
                params ["_target"];
                detach _target;
                _target enableSimulation true;
                deleteVehicle _target;
                
                private _mrkrs = allMapMarkers select {markerColor _x == 'Color2_FD_F'};
                private _mrkr = _mrkrs select 0;
                private _money = parseNumber (markerText _mrkr);
                private _newMoney = _money + Cost;
                _mrkr setMarkerText str _newMoney;
            },
            nil,
            3,
            true,
            true,
            "",
            "true"
        ]] remoteExec ["addAction", 0, true];

        private _ind02 = [CreatedVEH, [
            "<t color='#FF0000'>PLACE</t>",
            {
                params ["_target"];
                detach _target;
                _target enableSimulation true;
                CursorTracker = false;
                _target allowDamage true;
                
                [_target, [
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
                ]] remoteExec ["addAction", 0, true];
            },
            nil,
            3,
            true,
            true,
            "",
            "true"
        ]] remoteExec ["addAction", 0, true];

        // Store action IDs globally for the completion function to access
        Ind01 = _ind01;
        Ind02 = _ind02;

        CreatedVEH setVariable ["IDS_Logistics_isPlacedEntity", true, true];

        [CreatedVEH, [
            "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>", 
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