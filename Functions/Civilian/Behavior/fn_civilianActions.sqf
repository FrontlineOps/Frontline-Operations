/*
 * Function: FLO_fnc_civilianActions
 * Author: Frontline Operations Development Group
 * Description:
 *   Unified civilian interaction handler. Merges logic from:
 *   - fn_civilianRelations (actions setup)
 *   - fn_civilianInvestigate (intel interaction)
 *   - fn_civilianAddDetainActions (detain actions)
 *
 * Arguments:
 *   0: Array of civilian units <ARRAY>
 *
 * Returns: Nothing
 */

params ["_civUnits"];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Detain actions (for captured civilians)
private _fnc_addDetainActions = {
    params ["_unit"];
    
    // Move Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Move",
        {(_this select 0) attachTo [player, [0, 0.7, 0]];},
        nil, 0, true, true, "", "true", 3, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Stop Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Stop",
        {detach (_this select 0);},
        nil, 0, true, true, "", "true", 3, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Mount Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Mount",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            detach _target;
            private _nearVehicles = nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15];
            
            if (count _nearVehicles > 0) then {
                private _vh = _nearVehicles select 0;
                _target moveInCargo _vh;
                
                // Add Unmount Action
                [_vh, [
                    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>UnMount",
                    {
                        params ["_target", "_caller", "_actionId"];
                        private _pows = crew _target select {side _x == civilian && captive _x && alive _x};
                        if (count _pows > 0) then {
                            private _pow = _pows select 0;
                            detach _pow;
                            unassignVehicle _pow;
                            moveOut _pow;
                            _pow switchMove 'AmovPercMstpSsurWnonDnon';
                            _target removeAction _actionId;
                        };
                    },
                    nil, 0, true, true, "", "true", 5, false, "", ""
                ]] remoteExec ["addAction", 0, true];
            };
        },
        nil, 0, true, true, "", "count (nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15]) > 0", 5, false, "", ""
    ]] remoteExec ["addAction", 0, true];
};

// Investigate action handler
private _fnc_investigate = {
    params ["_civilian", "_caller"];
    
    // Hostile Engineer Check
    private _isEngineer = _civilian getUnitTrait "engineer";
    if (_isEngineer && (random 1 > 0.33)) exitWith {
        private _complMessage = selectRandom [
            "DEATH TO OUTSIDERS, DEATH TO OUTSIDERS !!!",
            "Walk Away Bastards. . .You Just Bring Chaos and Destruction !!!",
            "You will Pay for what you have done to our Country, I dont tell you shit !!!",
            "May GOD Save us from Your Wicked chains you Devils, May GOD Dawn you all !!!",
            "Your Men Caused my Innocent brothers and sisters Suffer and Die, FUCK YOU ALL !!!"
        ];
        ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
    };

    // Resource Check
    private _money = FLO_MoneyHandle getOrDefault ["value", 0];
    if (_money < 5) exitWith {
        hint "Not enough Resources (Required: 5)";
    };

    // Get intel chance from Civilian Manager
    private _chance = 0.3;
    if (!isNil "FLO_CivilianManager") then {
        private _nearestObj = "";
        private _nearestDist = 99999;
        if (!isNil "FLO_Objectives") then {
            {
                private _objPos = [_x] call FLO_fnc_getObjectivePosition;
                private _dist = _civilian distance2D _objPos;
                if (_dist < _nearestDist) then {
                    _nearestDist = _dist;
                    _nearestObj = _x;
                };
            } forEach (keys FLO_Objectives);
        };
        _chance = FLO_CivilianManager call ["getIntelChance", [_nearestObj]];
    };

    // Attempt Interaction
    if (random 1 < _chance) then {
        FLO_MoneyHandle set ["value", _money - 5];
        publicVariable "FLO_MoneyHandle";
        
        private _reportSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_reportSide in [east, west]) then { _reportSide = west; };
        [_civilian, _reportSide] call FLO_fnc_gtnAlertCivilianReport;
        
        private _okLines = [
            "Sure, Let me Show you the way!",
            "We appericiate your Efforts for our Homeland, let me Help you!",
            "Yes, Come, I know Some !"
        ];
        ["Civilian", selectRandom _okLines] remoteExec ["BIS_fnc_showSubtitle"];
    } else {
        private _refuseLines = [
            "We Dont talk to Strangers!",
            "I don't know much about this Region!",
            "Sorry but I dont Trust you Outsiders!",
            "Maybe that Man there can Help you, He has been with the Army years ago !"
        ];
        ["Civilian", selectRandom _refuseLines] remoteExec ["BIS_fnc_showSubtitle"];
    };
};

// Setup civilian actions
private _fnc_setupCivilianActions = {
    params ["_unit"];
    
    // Investigate Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate",
        {
            params ["_target", "_caller", "_actionId"];
            [_target, _caller] call FLO_fnc_civilianInvestigateAction;
            
            _target disableAI "PATH";
            _target disableAI "MOVE";
            _target setDir (_target getDir _caller);
            _target removeAction _actionId;
            [_target, (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", _target];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Offer Help Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\defend_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Offer Help",
        {
            params ["_target", "_caller", "_actionId"];
            [_target] call FLO_fnc_civilianRequestMission;
            
            _target disableAI "PATH";
            _target disableAI "MOVE";
            _target setDir (_target getDir _caller);
            _target removeAction _actionId;
            [_target, (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", _target];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Detain Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Detain",
        {
            params ["_target", "_caller", "_actionId"];
            
            playSound3D [getMissionPath (selectRandom ["Sounds\GoProne_1.ogg", "Sounds\Halt.ogg", "Sounds\Stop.ogg", "Sounds\VehStop_2.ogg"]), _caller];
            
            _target removeAction _actionId;
            _target removeAllEventHandlers "FiredNear";
            
            private _chance = floor random 4;
            private _isEngineer = _target getUnitTrait "engineer";
            
            // Non-engineers always surrender
            if (!_isEngineer) then {
                [_target, ""] remoteExec ["playMove", _target];
                [_target, "ApanPercMstpSnonWnonDnon_ApanPpneMstpSnonWnonDnon"] remoteExec ["playMove", _target];
                _target setUnitPos "DOWN";
                _target disableAI "PATH";
                _target disableAI "MOVE";
                _target setCaptive true;
                _target setDir ((_target getDir _caller) + 180);
                _target switchMove 'AmovPercMstpSsurWnonDnon';
                removeAllWeapons _target;
                removeBackpack _target;
                removeAllActions _target;
                
                [_target] call FLO_fnc_civilianDetainActions;
            };
            
            // Engineers may fight back
            if (_isEngineer) then {
                if (_chance < 2) then {
                    [_target, ""] remoteExec ["playMove", _target];
                    [_target, "ApanPercMstpSnonWnonDnon_ApanPpneMstpSnonWnonDnon"] remoteExec ["playMove", _target];
                    _target disableAI "PATH";
                    _target disableAI "MOVE";
                    _target setCaptive true;
                    _target setDir ((_target getDir _caller) + 180);
                    _target switchMove 'AmovPercMstpSsurWnonDnon';
                    removeAllWeapons _target;
                    removeBackpack _target;
                    removeAllActions _target;
                    [_target] call FLO_fnc_civilianDetainActions;
                } else {
                    [_target, ""] remoteExec ["playMove", _target];
                    private _wpn = selectRandom ["hgun_PDW2000_Holo_snds_F", "hgun_Rook40_snds_F", "hgun_P07_blk_F", "hgun_P07_khk_F", "hgun_Rook40_F"];
                    [_target, _wpn, 4] call BIS_fnc_addWeapon;
                    _target enableAI "all";
                    _target removeAllEventHandlers "Killed";
                    
                    private _grp = createGroup [east, true];
                    [_target] join _grp;
                    _target doTarget _caller;
                    _target doFire _caller;
                };
            };
        },
        nil, 0, true, true, "", "true", 5, false, "", ""
    ]] remoteExec ["addAction", 0, true];
};

// ============================================================================
// MAIN LOGIC
// ============================================================================

// Clear old handlers
{
    _x removeAllEventHandlers "Killed";
    removeAllActions _x;
} forEach _civUnits;

// Apply new logic
{
    private _unit = _x;
    
    // Check for flee behavior from Civilian Manager
    private _shouldFlee = false;
    if (!isNil "FLO_CivilianManager") then {
        _shouldFlee = FLO_CivilianManager call ["shouldFlee", [getPosATL _unit]];
    };
    
    if (_shouldFlee) then {
        // Flee from players
        _unit setBehaviour "CARELESS";
        _unit setSpeedMode "FULL";
        private _fleeDir = (getPosATL _unit) getDir (getPos player);
        private _fleePos = (getPosATL _unit) getPos [100 + random 50, _fleeDir + 180];
        _unit doMove _fleePos;
    } else {
        // Normal behavior
        _unit addEventHandler ["Killed", {
            params ["_unit", "_killer"];
            if (side _killer == west) then {
                [west, "HQ"] commandChat "WATCH for CIVILIAN CASUALTY!";
                removeAllActions _unit;
                [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
            };
        }];
        
        [_unit] call _fnc_setupCivilianActions;
    };
    
} forEach _civUnits;
