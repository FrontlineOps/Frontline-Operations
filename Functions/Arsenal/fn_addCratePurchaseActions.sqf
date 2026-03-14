/*
    Function: FLO_fnc_addCratePurchaseActions
    
    Description: Adds crate purchase actions to a FOB or OP object
    
    Parameter(s):
        _object - The FOB or OP object to attach the purchase actions to
        
    Returns:
        None
*/

params ["_object"];

if (!hasInterface) exitWith {};
if (isNull _object) exitWith {};

if (_object getVariable ["FLO_CrateActionsAdded", false]) exitWith {};

[
    {!isNil "FLO_availableCrates" && {count FLO_availableCrates > 0}},
    {
        params ["_object"];

        if (_object getVariable ["FLO_CrateActionsAdded", false]) exitWith {};
        _object setVariable ["FLO_CrateActionsAdded", true];

        // Main menu action
        _object addAction [
            "<img size=2 color='#FFE258' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\box_ca.paa' /><t font='PuristaBold' color='#FFA500'>Equipment Crates",
            {},
            [],
            1.5,
            true,
            true,
            "",
            "true",
            10
        ];
        
        // Individual crate options
        {
            _x params ["_id", "_name", "_cost", "_boxType", "_items", "_description"];
            
            _object addAction [
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
            ];
            
        } forEach FLO_availableCrates;
    },
    [_object]
] call CBA_fnc_waitUntilAndExecute;
