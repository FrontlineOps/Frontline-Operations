params ["_className"];

private _price = -1;
private _lists = [
    "F_Bike_List",
    "F_Car_List",
    "F_MRAP_List",
    "F_Truck_List",
    "F_Truck_Construction_List",
    "F_Truck_Ammo_List",
    "F_Truck_Respawn_List",
    "F_APC_List",
    "F_Tank_List",
    "F_Artillery_List",
    "F_Heli_List",
    "F_Heli_Respawn_List",
    "F_Heli_Gunship_List",
    "F_Plane_List",
    "F_Boat_List",
    "F_UAV_List",
    "F_UGV_List",
    "F_Turret_List",
    "F_SAM_List"
];

{
    if (!isNil _x) then {
        {
            if (((count _x) >= 2) && {(_x select 0) isEqualTo _className}) exitWith {
                _price = _x select 1;
            };
        } forEach (missionNamespace getVariable _x);
    };
    if (_price > -1) exitWith {};
} forEach _lists;

_price
