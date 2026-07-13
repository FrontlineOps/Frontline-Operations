/*
 * Function: FLO_fnc_vehicleMarket
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages the vehicle sales economy.
 *   Handles pricing calculations based on vehicle type, variants, damage, and faction demand.
 */

params ["_vehicle", ["_action", "calc_price"], ["_requester", objNull, [objNull]]];

if (isNil "_vehicle" || isNull _vehicle) exitWith { 0 };

// === PRICE CALCULATION ===
if (_action == "calc_price") exitWith {
    private _type = typeOf _vehicle;
    private _cfgArg = configFile >> "CfgVehicles" >> _type;
    
    // =================================================================================
    // HEURISTIC PRICING ALGORITHM (Physical Value)
    // =================================================================================
    
    // 1. PHYSICAL PROPERTIES
    private _mass = getMass _vehicle;
    private _maxSpeed = getNumber (_cfgArg >> "maxSpeed");
    private _armor = getNumber (_cfgArg >> "armor");
    private _seats = getNumber (_cfgArg >> "transportSoldier") + count (fullCrew [_vehicle, "", true]);

    // Formula Components
    private _valMass = _mass / 500;       // 8500/500 = 17
    private _valArmor = _armor * 0.1;     // 200*0.1 = 20
    private _valSpeed = _maxSpeed * 0.1;  // 100*0.1 = 10
    private _valSeats = _seats * 2;       // 4*2 = 8
    
    private _scrapValue = _valMass + _valArmor + _valSpeed + _valSeats; 
    
    // Minimum Floor
    if (_scrapValue < 25) then { _scrapValue = 25; }; 
    
    // DAMAGE PENALTY
    private _damage = damage _vehicle;
    private _maxPenalty = 0.5; // Max 50% reduction for totally wrecked
    private _dmgFactor = 1 - (_damage * _maxPenalty);
    
    _scrapValue = _scrapValue * _dmgFactor;
    
    // UNIVERSAL CAPABILITY MULTIPLIERS
    // Analyzes the physical and technological capabilities of the vehicle based on Config
    private _capabilityMultiplier = 1.0;
    
    // Advanced sensor suite
    // Presence of "SensorsManagerComponent" implies modern fire control
    if (isClass (_cfgArg >> "Components" >> "SensorsManagerComponent")) then {
        _capabilityMultiplier = _capabilityMultiplier + 0.30; 
    };
    
    // Thermal Imaging (TI)
    // Check if Thermals are NOT disabled. 0 = Enabled, 1 = Disabled.
    // Also check for TIEquipment implies it has it.
    private _hasTI = getNumber (_cfgArg >> "disableTIEquipment") == 0;
    if (_hasTI) then {
        _capabilityMultiplier = _capabilityMultiplier + 0.20;
    };
    
    // Commander Optics (Hunter-Killer Capability)
    // Presence of a Commander Turret (usually index 0 in Turrets class)
    if (isClass (_cfgArg >> "Turrets" >> "CommanderOptics") || isClass (_cfgArg >> "Turrets" >> "M2_Turret")) then {
        _capabilityMultiplier = _capabilityMultiplier + 0.15;
    };
    
    _scrapValue = _scrapValue * _capabilityMultiplier;

    // CAPTURE BONUS (Market Demand)
    // High demand for foreign tech (OPFOR/INDEP)
    private _side = getNumber (_cfgArg >> "side");
    private _demandMultiplier = 1.0;
    
    if (_side == 0) then { _demandMultiplier = 1.5; }; // OPFOR (East) -> +50%
    if (_side == 2) then { _demandMultiplier = 1.25; }; // INDEP -> +25%
    
    _scrapValue = _scrapValue * _demandMultiplier;
    
    // =================================================================================
    // FACTION PRICE CAP
    // =================================================================================
    // To prevent economic exploits, we cap the sell price at the original buy price
    // if the vehicle is available in the player's faction menu.
    
    // Collect all faction lists
    private _factionPriceLists = [
        missionNamespace getVariable ["F_Bike_List", []],
        missionNamespace getVariable ["F_Car_List", []],
        missionNamespace getVariable ["F_MRAP_List", []],
        missionNamespace getVariable ["F_Truck_List", []],
        missionNamespace getVariable ["F_Truck_Construction_List", []],
        missionNamespace getVariable ["F_Truck_Ammo_List", []],
        missionNamespace getVariable ["F_Truck_Respawn_List", []],
        missionNamespace getVariable ["F_APC_List", []],
        missionNamespace getVariable ["F_Tank_List", []],
        missionNamespace getVariable ["F_Artillery_List", []],
        missionNamespace getVariable ["F_Heli_List", []],
        missionNamespace getVariable ["F_Heli_Respawn_List", []],
        missionNamespace getVariable ["F_Heli_Gunship_List", []],
        missionNamespace getVariable ["F_Plane_List", []],
        missionNamespace getVariable ["F_Boat_List", []],
        missionNamespace getVariable ["F_UAV_List", []],
        missionNamespace getVariable ["F_UGV_List", []],
        missionNamespace getVariable ["F_Container_List", []],
        missionNamespace getVariable ["F_Turret_List", []],
        missionNamespace getVariable ["F_SAM_List", []]
    ];

    private _buyPrice = -1;

    // Search for vehicle in lists
    {
        private _list = _x;
        {
            _x params ["_class", "_price"];
            if (_class == _type) exitWith {
                _buyPrice = _price;
            };
        } forEach _list;
        
        if (_buyPrice > -1) exitWith {};
    } forEach _factionPriceLists;

    // Apply Cap if vehicle is purchasable
    if (_buyPrice > -1) then {
        // If calculated value exceeds buy price, cap it
        if (_scrapValue > _buyPrice) then {
            _scrapValue = _buyPrice;
            ["MARKET", 3, format ["Price capped for %1: Calc $%2 -> Cap $%3", _type, _scrapValue, _buyPrice]] call FLO_fnc_log;
        };
    };

    // Round to nearest 5
    round(_scrapValue / 5) * 5
};

// === SELL TRANSACTION ===
if (_action == "sell") exitWith {
    if (!isServer) exitWith {
        [_vehicle, "sell", player] remoteExecCall ["FLO_fnc_vehicleMarket", 2];
        true
    };
    if (isNull _requester || {(_requester distance2D _vehicle) > 15}) exitWith { false };
    if (remoteExecutedOwner > 2 && {owner _requester != remoteExecutedOwner}) exitWith { false };

    private _price = [_vehicle, "calc_price"] call FLO_fnc_vehicleMarket;
    private _side = side group _requester;
    private _sideKey = [_side] call FLO_fnc_sideKey;
    private _treasury = FLO_SideResources get _sideKey;
    private _newBalance = [
        _treasury,
        _price,
        "SALVAGE",
        format ["Scrapped %1", typeOf _vehicle],
        name _requester,
        netId _vehicle,
        true
    ] call FLO_fnc_sideResourcesAddResources;
    
    // Notification
    private _name = getText (configOf _vehicle >> "displayName");
    [format ["Sold %1 for %2 resources.", _name, _price], "success", false, owner _requester] call FLO_fnc_sendNotification;
    
    // Cleanup
    deleteVehicle _vehicle;
    
    ["MARKET", 3, format ["Sold %1 for %2. New side balance: %3", _name, _price, _newBalance]] call FLO_fnc_log;
    true
};

// === ACTION CONFIRMATION ===
if (_action == "open_menu") exitWith {
    private _price = [_vehicle, "calc_price"] call FLO_fnc_vehicleMarket;
    private _name = getText (configOf _vehicle >> "displayName");
    
    // TODO: Use a nicer dialog, but for now BIS_fnc_guiMessage is robust
    private _result = [
        format ["Scrap %1 for $%2?", _name, _price],
        "Vehicle Scrapyard",
        "SELL",
        "CANCEL"
    ] call BIS_fnc_guiMessage;
    
    if (_result) then {
        [_vehicle, "sell", player] call FLO_fnc_vehicleMarket;
    };
};
