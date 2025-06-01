/*
 * Function: FLO_fnc_civilianRelations
 * Description: Handles all civilian interaction logic (actions, detain, reputation, etc) for the mission.
 * Arguments:
 *   0: Array of units <ARRAY> - The civilians to apply interaction logic to
 * Returns: Nothing
 * Usage: [units _group] call FLO_fnc_civilianRelations;
 */

params ["_civUnits"];

// --- Utility Functions ---

private _clearUnitHandlers = {
    params ["_units"];
    {
        _x removeAllEventHandlers "Killed";
        removeAllActions _x;
    } forEach _units;
};

private _addDetainActions = {
    params ["_unit"];
    [_unit,[
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Move",
        {(_this select 0) attachTo [player, [0, 0.7, 0]];},
        nil, 0, true, true, "", "true", 3, false, "", ""
    ]] remoteExec ["addAction",0,true];
    [_unit,[
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Stop",
        {detach (_this select 0);},
        nil, 0, true, true, "", "true", 3, false, "", ""
    ]] remoteExec ["addAction",0,true];
    [_unit,[
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Mount",
        {
            detach (_this select 0);
            _vh = nearestObjects [(_this select 0), ['Air', 'Ship', 'LandVehicle'],15] select 0;
            (_this select 0) moveInCargo _vh;
            [_vh,[
                "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>UnMount",
                {
                    _pow = (crew (_this select 0) select {side _x == civilian && captive _x == true && alive _x}) select 0;
                    detach _pow;
                    [_pow] ordergetin false;
                    [_pow] allowGetIn false;
                    unassignvehicle _pow;
                    doGetOut _pow;
                    _pow switchMove 'AmovPercMstpSsurWnonDnon';
                    (_this select 0) removeAction (_this select 2);
                },
                nil, 0, true, true, "", "true", 5, false, "", ""
            ]] remoteExec ["addAction",0,true];
        },
        nil, 0, true, true, "", "count (nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'],15] ) > 0", 5, false, "", ""
    ]] remoteExec ["addAction",0,true];
};

private _setupCivilianActions = {
    params ["_unit"];
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate",
        {
            [(_this select 0)] call FLO_fnc_civilianInvestigate;
            (_this select 0) disableAI "PATH";
            (_this select 0) disableAI "MOVE";
            (_this select 0) setDir (position (_this select 0) getDir position player);
            (_this select 0) removeAction (_this select 2);
            [(_this select 0), (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", (_this select 0)];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\defend_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Offer Help",
        {
            [(_this select 0)] execVM "Scripts\HELP.sqf";
            (_this select 0) disableAI "PATH";
            (_this select 0) disableAI "MOVE";
            (_this select 0) setDir (position (_this select 0) getDir position player);
            (_this select 0) removeAction (_this select 2);
            [(_this select 0), (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", (_this select 0)];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Detain",
        {
            playSound3D [getMissionPath (selectRandom ["Sounds\GoProne_1.ogg", "Sounds\Halt.ogg", "Sounds\Stop.ogg", "Sounds\VehStop_2.ogg"]), player];
            (_this select 0) removeAction (_this select 2);
            (_this select 0) removeAllEventHandlers "FiredNear";
            _chance = selectRandom [0, 1, 2, 3];
            if ((_this select 0) getUnitTrait "engineer" != true) then {
                [(_this select 0), ""] remoteExec ["playMove", (_this select 0)];
                [(_this select 0), "ApanPercMstpSnonWnonDnon_ApanPpneMstpSnonWnonDnon"] remoteExec ["playMove", (_this select 0)];
                (_this select 0) setUnitPos "DOWN";
                (_this select 0) disableAI "PATH";
                (_this select 0) disableAI "MOVE";
                (_this select 0) setCaptive true;
                (_this select 0) setDir ((position (_this select 0) getDir position player) + 180);
                (_this select 0) switchMove 'AmovPercMstpSsurWnonDnon';
                removeAllWeapons (_this select 0);
                removeBackpack (_this select 0);
                removeAllActions (_this select 0);
                [(_this select 0)] call _addDetainActions;
            };
            if (((_this select 0) getUnitTrait "engineer" == true) && (_chance < 2)) then {
                [(_this select 0), ""] remoteExec ["playMove", (_this select 0)];
                [(_this select 0), "ApanPercMstpSnonWnonDnon_ApanPpneMstpSnonWnonDnon"] remoteExec ["playMove", (_this select 0)];
                (_this select 0) disableAI "PATH";
                (_this select 0) disableAI "MOVE";
                (_this select 0) setCaptive true;
                (_this select 0) setDir ((position (_this select 0) getDir position player) + 180);
                (_this select 0) switchMove 'AmovPercMstpSsurWnonDnon';
                removeAllWeapons (_this select 0);
                removeBackpack (_this select 0);
                removeAllActions (_this select 0);
                [(_this select 0)] call _addDetainActions;
            };
            if (((_this select 0) getUnitTrait "engineer" == true) && (_chance > 1)) then {
                [(_this select 0), ""] remoteExec ["playMove", (_this select 0)];
                _WPN = selectRandom ["hgun_PDW2000_Holo_snds_F", "hgun_Rook40_snds_F", "hgun_P07_blk_F", "hgun_P07_khk_F", "hgun_Rook40_F", "hgun_Pistol_heavy_01_snds_F", "hgun_P07_snds_F", "hgun_ACPC2_F"];
                [(_this select 0), _WPN, 4] call BIS_fnc_addWeapon;
                (_this select 0) enableAI "PATH";
                (_this select 0) enableAI "MOVE";
                (_this select 0) enableAI "all";
                _Group = createGroup east;
                [(_this select 0)] join _Group;
                (_this select 0) doTarget player;
                (_this select 0) removeAllEventHandlers "Killed";
            };
        },
        nil, 0, true, true, "", "true", 5, false, "", ""
    ]] remoteExec ["addAction", 0, true];
};

// --- Main Logic ---

private _REPSCORE = FLO_ReputationHandle get "value";

[_civUnits] call _clearUnitHandlers;

{
    _x addEventHandler ["Killed", {
        if (side (_this select 1) == west) then {
            [playerSide, "HQ"] commandChat "WATCH for CIVILIAN CASUALITY Corporal !";
            removeAllActions (_this select 0);
            {(_this select 0) playMove "";} remoteExec ["call", 0];
            [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
            [] execVM "Scripts\Civ_Relations.sqf";
        };
    }];
    [_x] call _setupCivilianActions;
} forEach _civUnits; 