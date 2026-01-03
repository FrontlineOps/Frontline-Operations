/*
 * Function: FLO_fnc_civilianRelations
 * Description: Handles all civilian interaction logic (actions, detain, reputation, etc) for the mission.
 * Arguments:
 *   0: Array of units <ARRAY> - The civilians to apply interaction logic to
 * Returns: Nothing
 * Usage: [units _group] call FLO_fnc_civilianRelations;
 */

params ["_civUnits"];

// --- Helper Functions (Private) ---

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
                
                // Add Unmount Action to Vehicle
                [_vh, [
                    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>UnMount",
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        // Find captive civilian in crew
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

private _fnc_setupCivilianActions = {
    params ["_unit"];
    
    // Investigate Action
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate",
        {
            params ["_target", "_caller", "_actionId"];
            [_target] call FLO_fnc_civilianInvestigate;
            
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
            
            // Sounds
            playSound3D [getMissionPath (selectRandom ["Sounds\GoProne_1.ogg", "Sounds\Halt.ogg", "Sounds\Stop.ogg", "Sounds\VehStop_2.ogg"]), _caller];
            
            _target removeAction _actionId;
            _target removeAllEventHandlers "FiredNear";
            
            // Logic: 0,1,2,3 -> if < 2 (0,1) -> 50%
            private _chance = floor random 4; 
            private _isEngineer = _target getUnitTrait "engineer";
            
            // If NOT engineer, always surrender
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
                
                [_target] call FLO_fnc_civilianAddDetainActions;
            };
            
            // Engineer logic
            if (_isEngineer) then {
                 if (_chance < 2) then {
                    // Surrender (Same as above)
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
                    [_target] call FLO_fnc_civilianAddDetainActions;
                 } else {
                    // Fight back!
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

// --- Main Logic ---

// Clear old
{
    _x removeAllEventHandlers "Killed";
    removeAllActions _x;
} forEach _civUnits;

// Add new
{
    private _unit = _x;
    
    // Killed EH - Penalty
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        if (side _killer == west) then {
            [west, "HQ"] commandChat "WATCH for CIVILIAN CASUALTY!";
            removeAllActions _unit;
            [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
        };
    }];
    
    // Actions
    [_unit] call _fnc_setupCivilianActions;
    
} forEach _civUnits;