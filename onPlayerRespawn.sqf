OLDGRP = group player;

removeAllActions player;

player setDamage 0;
[true] remoteExec ["showHud", player];
player stop false;
player enableAI "all";
[player, false] remoteExec ["setCaptive", 0, false];
["GetOutMan"] remoteExec ["removeAllEventHandlers", player, false];

if ((typeOf player == F_Diver_Eod) || (typeOf player == F_Diver_Rfl) || 
    (typeOf player == F_Diver_TL) || (typeOf player == "B_T_Diver_F")) then {
    [player] call EtV_Actions;
};

private _headlessClients = entities "HeadlessClient_F";
private _humanPlayers = allPlayers - _headlessClients;
hcRemoveAllGroups player;
{player hcRemoveGroup _x;} forEach (allGroups select {side _x == west});
private _GRPs = (allGroups select {(side _x == (side player)) && !(((units _x) select 0) in switchableUnits)});

if (count _humanPlayers == 1) then {
    {player hcSetGroup [_x];} forEach _GRPs;
} else {
    {TheCommander hcSetGroup [_x];} forEach _GRPs;
};

player addAction [
    "<t color='#7CC2FF'>" + localize "STR_KPPLM_ACTIONOPEN" + "</t>",
    {[] call KPPLM_fnc_openDialog;},
    nil,
    -803,
    true,
    true,
    "",
    "true",
    5,
    false,
    "",
    ""
];

(_this select 1) setPos [0,0,0];
deleteVehicle (_this select 1);

BIS_DeathBlur ppEffectAdjust [0.0];
BIS_DeathBlur ppEffectCommit 0.0;

sleep 1;

if ((serverCommandAvailable "#kick") && (serverCommandAvailable "#debug")) then {
    {unassignCurator ZEUS;} remoteExec ["call", 2];
    
    ZEUSNetworkId = clientOwner;
    publicVariable "ZEUSNetworkId";
    
    {
        private _ZEUSPLYOBJ = allPlayers select {owner _x == ZEUSNetworkId};
        (_ZEUSPLYOBJ select 0) assignCurator ZEUS;
    } remoteExec ["call", 2];
};

ShowHUD [true, true, true, true, true, true, true, true, true, true];

BIS_DeathBlur ppEffectAdjust [0.0];
BIS_DeathBlur ppEffectCommit 0.0;