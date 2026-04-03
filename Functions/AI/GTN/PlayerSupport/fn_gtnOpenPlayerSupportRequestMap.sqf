/*
 * Function: FLO_fnc_gtnOpenPlayerSupportRequestMap
 * Author: Frontline Operations Development Group
 * Description:
 *   Opens a one-shot map targeting flow for player commander support requests.
 *
 * Arguments:
 *   0: Support type <STRING> - "ARTY", "CAS", "CAP"
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (isNull player) exitWith { false };

params [["_supportType", "", [""]]];

private _type = toUpper _supportType;
if !(_type in ["ARTY", "CAS", "CAP"]) exitWith { false };
if (!alive player) exitWith { false };
if (isNil "FLO_MissionReady" || {!FLO_MissionReady}) exitWith {
    hint "Commander support is not ready yet.";
    false
};

if (FLO_GTN_PlayerSupportMapClickEhId >= 0) exitWith {
    hint "A commander support request is already waiting for a map click.";
    false
};

private _label = switch (_type) do {
    case "ARTY": { "artillery" };
    case "CAS": { "CAS" };
    case "CAP": { "CAP" };
};

FLO_GTN_PlayerSupportPendingType = _type;
FLO_GTN_PlayerSupportMapClickEhId = addMissionEventHandler ["MapSingleClick", {
    params ["_units", "_pos"];

    private _type = FLO_GTN_PlayerSupportPendingType;
    removeMissionEventHandler ["MapSingleClick", FLO_GTN_PlayerSupportMapClickEhId];
    FLO_GTN_PlayerSupportMapClickEhId = -1;
    FLO_GTN_PlayerSupportPendingType = "";

    openMap false;
    [_type, _pos] call FLO_fnc_gtnSubmitPlayerSupportRequest;
    true
}];

if (!FLO_GTN_PlayerSupportCancelWatcherRunning) then {
    FLO_GTN_PlayerSupportCancelWatcherRunning = true;
    [] spawn {
        waitUntil {
            sleep 0.1;
            FLO_GTN_PlayerSupportMapClickEhId < 0 || {!visibleMap}
        };

        if (FLO_GTN_PlayerSupportMapClickEhId >= 0 && {!visibleMap}) then {
            removeMissionEventHandler ["MapSingleClick", FLO_GTN_PlayerSupportMapClickEhId];
            FLO_GTN_PlayerSupportMapClickEhId = -1;
            if (FLO_GTN_PlayerSupportPendingType != "") then {
                hint "Commander support request cancelled.";
            };
            FLO_GTN_PlayerSupportPendingType = "";
        };

        FLO_GTN_PlayerSupportCancelWatcherRunning = false;
    };
};

openMap true;
hint format ["Select a target area for commander %1. Close the map to cancel.", _label];

true
