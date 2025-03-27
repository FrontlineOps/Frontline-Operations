/*
    Function: FLO_fnc_addCratePurchaseActions
    
    Description: Adds crate purchase actions to a FOB or OP object
    
    Parameter(s):
        _object - The FOB or OP object to attach the purchase actions to
        
    Returns:
        None
*/

params ["_object"];

[
    {!isNil "FLO_availableCrates"},
    {
        params ["_object"];
        
        // Main menu action
        [_object, [
            "<img size=2 color='#FFE258' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\box_ca.paa' /><t font='PuristaBold' color='#FFA500'>Equipment Crates",
            {},
            [],
            1.5,
            true,
            true,
            "",
            "true",
            10
        ]] remoteExec ["addAction", 0, true];
        
        // Individual crate options
        {
            _x params ["_id", "_name", "_cost", "_boxType", "_items", "_description"];
            
            [_object, [
                format [" - %1 (%2$)", _name, _cost],
                {
                    params ["_target", "_caller", "_actionId", "_crateInfo"];
                    
                    // Execute purchase on server
                    [_target, _caller, _crateInfo] remoteExec ["FLO_fnc_checkCratePurchase", 2];
                },
                _x,
                1.4,
                false,
                true,
                "",
                "true", 
                10
            ]] remoteExec ["addAction", 0, true];
            
        } forEach FLO_availableCrates;
    },
    [_object]
] call CBA_fnc_waitUntilAndExecute;
