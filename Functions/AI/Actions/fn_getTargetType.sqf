/* ----------------------------------------------------------------------------
Function: FLO_fnc_getTargetType

Description:
    A function to determine the type of unit/vehicle for appropriate AI behavior.
    Categorizes units into different types (MAN, CAR, ARMOR, etc.) to determine
    how they should behave in different tactical situations.

Parameters:
    - Target (Object) - The unit or vehicle to categorize

Returns:
    String - The category of the target ("MAN", "CAR", "ARMOR", "MECH", "HELI", "PLANE", "SHIP", "MORTAR", "AAA", "ART", etc.)

Example:
    (begin example)
    private _type = [vehicle player] call FLO_fnc_getTargetType;
    (end)

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params ["_target"];

// Default type
private _type = "MAN";

// Determine vehicle type
if (_target isKindOf "Man") then {
    _type = "MAN";
} else {
    if (_target isKindOf "Air") then {
        if (_target isKindOf "Helicopter") then {
            _type = "HELI";
        } else {
            if (_target isKindOf "UAV") then {
                _type = "UAV";
            } else {
                _type = "PLANE";
            };
        };
    } else {
        if (_target isKindOf "Ship") then {
            _type = "SHIP";
        } else {
            if (_target isKindOf "StaticMortar") then {
                _type = "MORTAR";
            } else {
                if (_target isKindOf "StaticWeapon") then {
                    private _className = typeOf _target;
                    if (_className find "AA" > -1) then {
                        _type = "AAA";
                    } else {
                        if (_className find "artillery" > -1 || _className find "Artillery" > -1) then {
                            _type = "ART";
                        } else {
                            _type = "STATIC";
                        };
                    };
                } else {
                    if (_target isKindOf "Tank") then {
                        if (_target isKindOf "Wheeled_APC") then {
                            _type = "MECH";
                        } else {
                            _type = "ARMOR";
                        };
                    } else {
                        if (_target isKindOf "Car") then {
                            _type = "CAR";
                        };
                    };
                };
            };
        };
    };
};

_type 