sleep 5;

// --- Utility Functions ---

// Remove all event handlers and actions from units of a given array and side
private _clearUnitHandlers = {
    params ["_side", "_unitArray"];
    {
        {
            _x removeAllEventHandlers "Killed";
            removeAllActions _x;
        } forEach (allUnits select {captive _x == false && (typeOf _x) in _unitArray && side _x == _side});
    } remoteExec ["call", 0];
};

// Add ARREST, Move, Stop, Mount actions for detained civilians
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

// Add actions and event handlers to civilians
private _setupCivilianActions = {
    params ["_unit"];
    // Investigate
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate",
        {
            [(_this select 0)] execVM "Scripts\\INVEST.sqf";
            (_this select 0) disableAI "PATH";
            (_this select 0) disableAI "MOVE";
            (_this select 0) setDir (position (_this select 0) getDir position player);
            (_this select 0) removeAction (_this select 2);
            [(_this select 0), (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", (_this select 0)];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Offer Help
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\defend_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Offer Help",
        {
            [(_this select 0)] execVM "Scripts\\HELP.sqf";
            (_this select 0) disableAI "PATH";
            (_this select 0) disableAI "MOVE";
            (_this select 0) setDir (position (_this select 0) getDir position player);
            (_this select 0) removeAction (_this select 2);
            [(_this select 0), (selectRandom ["Acts_CivilIdle_2", "Acts_CivilIdle_1"])] remoteExec ["playMove", (_this select 0)];
        },
        nil, 1.5, true, true, "", "alive _target", 4, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    // Detain
    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Detain",
        {
            playSound3D [getMissionPath (selectRandom ["Sounds\\GoProne_1.ogg", "Sounds\\Halt.ogg", "Sounds\\Stop.ogg", "Sounds\\VehStop_2.ogg"]), player];
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

// Get reputation score from marker
private _mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
private _mrkr = _mrkrs select 0;
private _REPSCORE = parseNumber (markerText _mrkr);

// Clear all civilian event handlers and actions
[civilian, CivMenArray] call _clearUnitHandlers;

// Add event handlers and actions to all civilians
{
    // Add killed event handler
    _x addEventHandler ["Killed", {
        if (side (_this select 1) == west) then {
            [playerSide, "HQ"] commandChat "WATCH for CIVILIAN CASUALITY Corporal !";
            removeAllActions (_this select 0);
            {(_this select 0) playMove "";} remoteExec ["call", 0];
            [] execVM "Scripts\\ReputationMinus.sqf";
            [] execVM "Scripts\\Civ_Relations.sqf";
        };
    }];
    // Add actions
    [_x] call _setupCivilianActions;
} forEach (allUnits select {captive _x == false && (typeOf _x) in CivMenArray});

// --- Remains Collector Logic ---
{
    removeFromRemainsCollector [_x];
} forEach (allUnits select {side _x != west});
{
    removeFromRemainsCollector [_x];
} forEach (vehicles select {side (driver  _x) != west});

sleep 3;

{
    addToRemainsCollector [_x];
} forEach (allUnits select {side _x != west});
{
    addToRemainsCollector [_x];
} forEach (vehicles select {side (driver  _x) != west});