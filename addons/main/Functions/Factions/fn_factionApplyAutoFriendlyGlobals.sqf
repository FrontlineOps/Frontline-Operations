/*
 * Function: FLO_fnc_factionApplyAutoFriendlyGlobals
 * Description:
 *   Applies a current WEST faction catalog to the documented friendly F_*
 *   mission variables used by thin mission shells and custom BLUFOR fallback
 *   paths. This is a current catalog bridge; it does not create save-format
 *   compatibility or legacy schema migration.
 */

params [["_catalog", createHashMap, [createHashMap]]];

private _requiredFields = [
    "groundInfantryUnits",
    "groundSpecOpsUnits",
    "officers",
    "groundMotorized",
    "groundMechanized",
    "groundArmor",
    "groundTransport",
    "groundArtillery",
    "airHeli",
    "airJet",
    "airTransport",
    "airDrone",
    "groundDrone",
    "staticAA",
    "boat",
    "logisticsConstruction",
    "logisticsAmmo",
    "logisticsRespawn",
    "containers",
    "radar"
];

{
    if !(_x in _catalog) then {
        throw format ["Friendly auto catalog is missing %1", _x];
    };
    if !((_catalog get _x) isEqualType []) then {
        throw format ["Friendly auto catalog field %1 must be an array", _x];
    };
} forEach _requiredFields;

private _infantry = +(_catalog get "groundInfantryUnits");
if (_infantry isEqualTo []) then {
    throw "Friendly auto catalog has no infantry units";
};

private _specOps = +(_catalog get "groundSpecOpsUnits");
if (_specOps isEqualTo []) then {
    _specOps = +_infantry;
};

private _officers = +(_catalog get "officers");
if (_officers isEqualTo []) then {
    _officers = [_infantry select 0];
};

private _pick = {
    params ["_pool", "_index"];
    _pool select (_index mod (count _pool))
};

missionNamespace setVariable ["F_Officer", _officers select 0];
missionNamespace setVariable ["F_Assault_Eng", [_infantry, 0] call _pick];
missionNamespace setVariable ["F_Assault_TL", [_infantry, 1] call _pick];
missionNamespace setVariable ["F_Assault_SL", [_infantry, 2] call _pick];
missionNamespace setVariable ["F_Assault_Eod", [_infantry, 3] call _pick];
missionNamespace setVariable ["F_Assault_Mrk", [_infantry, 4] call _pick];
missionNamespace setVariable ["F_Assault_AT", [_infantry, 5] call _pick];
missionNamespace setVariable ["F_Assault_Amm", [_infantry, 6] call _pick];
missionNamespace setVariable ["F_Assault_Mg", [_infantry, 7] call _pick];
missionNamespace setVariable ["F_Assault_Med", [_infantry, 8] call _pick];
missionNamespace setVariable ["F_Assault_Uav", [_infantry, 9] call _pick];

missionNamespace setVariable ["F_Recon_Snp", [_specOps, 0] call _pick];
missionNamespace setVariable ["F_Recon_Sct", [_specOps, 1] call _pick];
missionNamespace setVariable ["F_Recon_TL", [_specOps, 2] call _pick];
missionNamespace setVariable ["F_Recon_Mrk", [_specOps, 3] call _pick];
missionNamespace setVariable ["F_Recon_AT", [_specOps, 4] call _pick];
missionNamespace setVariable ["F_Recon_Mg", [_specOps, 5] call _pick];
missionNamespace setVariable ["F_Recon_Eod", [_specOps, 6] call _pick];
missionNamespace setVariable ["F_Recon_Med", [_specOps, 7] call _pick];
missionNamespace setVariable ["F_Recon_Eng", [_specOps, 8] call _pick];

missionNamespace setVariable ["F_Diver_TL", [_specOps, 9] call _pick];
missionNamespace setVariable ["F_Diver_Rfl", [_specOps, 10] call _pick];
missionNamespace setVariable ["F_Diver_Eod", [_specOps, 11] call _pick];

missionNamespace setVariable ["F_ASSLT_ENG", [F_Assault_Eng, F_Assault_AT, F_Assault_Eod]];
missionNamespace setVariable ["F_ASSLT_TEAM", [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm]];
missionNamespace setVariable ["F_ASSLT_SQD", [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Uav]];
missionNamespace setVariable ["F_SNP_TEAM", [F_Recon_Snp, F_Recon_Sct]];
missionNamespace setVariable ["F_RCN_TEAM", [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg]];
missionNamespace setVariable ["F_RCN_SQD", [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk]];
missionNamespace setVariable ["F_DVR_TEAM", [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl, F_Diver_Eod]];
missionNamespace setVariable ["F_OFFICER_TEAM", [F_Officer, F_Assault_Amm]];

missionNamespace setVariable ["F_Car_List", +(_catalog get "groundMotorized")];
missionNamespace setVariable ["F_MRAP_List", []];
missionNamespace setVariable ["F_Truck_List", +(_catalog get "groundTransport")];
missionNamespace setVariable ["F_Truck_Construction_List", +(_catalog get "logisticsConstruction")];
missionNamespace setVariable ["F_Truck_Ammo_List", +(_catalog get "logisticsAmmo")];
missionNamespace setVariable ["F_Truck_Respawn_List", +(_catalog get "logisticsRespawn")];
missionNamespace setVariable ["F_APC_List", +(_catalog get "groundMechanized")];
missionNamespace setVariable ["F_Tank_List", +(_catalog get "groundArmor")];
missionNamespace setVariable ["F_Artillery_List", +(_catalog get "groundArtillery")];
missionNamespace setVariable ["F_Heli_List", +(_catalog get "airTransport")];
missionNamespace setVariable ["F_Heli_Respawn_List", +(_catalog get "logisticsRespawn")];
missionNamespace setVariable ["F_Heli_Gunship_List", +(_catalog get "airHeli")];
missionNamespace setVariable ["F_Plane_List", +(_catalog get "airJet")];
missionNamespace setVariable ["F_Boat_List", +(_catalog get "boat")];
missionNamespace setVariable ["F_UAV_List", +(_catalog get "airDrone")];
missionNamespace setVariable ["F_UGV_List", +(_catalog get "groundDrone")];
missionNamespace setVariable ["F_Container_List", +(_catalog get "containers")];
missionNamespace setVariable ["F_Turret_List", []];
missionNamespace setVariable ["F_SAM_List", +(_catalog get "staticAA")];

private _radar = _catalog get "radar";
missionNamespace setVariable ["FLO_FactionRadar", if (_radar isEqualTo []) then { "" } else { _radar select 0 }];

["FACTIONS", 3, format [
    "Applied friendly auto catalog globals infantry=%1 specOps=%2 vehicles=%3",
    count _infantry,
    count _specOps,
    count ((_catalog get "groundMotorized") + (_catalog get "groundMechanized") + (_catalog get "groundArmor"))
]] call FLO_fnc_log;

true
