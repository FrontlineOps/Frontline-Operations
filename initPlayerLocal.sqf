params ["_player", "_didJIP"];

titleText ["Frontline Operations Group Presents...", "BLACK IN",9999];
5 fadeSound 0;

sleep 1;

StartingLocationDone = false;

// After Mission Loaded
waitUntil {MissionLoadedLitterally};

// Check if the starting location has been set & blufor installations already exist
// if so assume the mission has been loaded from a saved game
private _installationCount = count (allMapMarkers select {markerType _x isEqualTo "b_installation"});
if (count (allMapMarkers select {markerType _x isEqualTo "loc_SafetyZone"}) >= 6 && (_installationCount > 0)) then {
    StartingLocationDone = true; 
    publicVariable "StartingLocationDone";
};

// If starting location has not been set 
// Assume the mission is a fresh start
if (!StartingLocationDone) then {
	// Faction Selection & Starting Location
	if (isNil "TheCommander") then {titleText ["Commander must be assigned to a player at fresh start.\nHave someone return to Lobby and pick Commander.", "BLACK IN",9999]; waitUntil {!isNil "TheCommander"};};

	if (_player isEqualTo TheCommander) then { 
		execVM "Scripts\MissionSetupMenu\Dialog_Faction.sqf"; 
	};
};


// After Faction Selection / Safe Zones
waitUntil {StartingLocationDone};

hintSilent "LOADING . . . "; 

F_Init = false;
execVM "Scripts\Init\init_groups.sqf"; 

enableSaving [false, false];

waitUntil {F_Init};

(findDisplay 46) displayAddEventHandler ["MouseButtonDown", "params ['_displayOrControl', '_button', '_xPos', '_yPos', '_shift', '_ctrl', '_alt'];  if ((_ctrl) && (_button isEqualTo 1) && ((ctrlMapMouseOver (findDisplay 12 displayCtrl 51)) select 0 isEqualTo 'marker')) then {[(ctrlMapMouseOver (findDisplay 12 displayCtrl 51)) select 1] execVM 'Scripts\MarkerIntro.sqf';}"]; 
//(findDisplay 46) displayAddEventHandler ["KeyDown", {params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"]; if ((_ctrl) && (_key isEqualTo 37) && (!dialog)) then {execVM "Scripts\TEAMS.sqf" ;};}];

// ETV Init - Everyone
execVM "Scripts\EtV.sqf";
waitUntil {!isNil "EtVInitialized"};

// Misc
if (isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") isEqualTo true ) then { player addItem "ItemAndroid"; player addItem "ItemcTab"; };

waitUntil {(MarLOCC isEqualTo 1) || (count (allMapMarkers select {markerType _x isEqualTo "b_installation"}) > 0) || (count (allMapMarkers select {markerType _x isEqualTo "b_unknown"}) > 0)};
// Wait until JIP or trigger 1, 2, & 3 is activated
waitUntil {(didJIP) || (TRG1LOCC isEqualTo 1)};
waitUntil {(didJIP) || (TRG2LOCC isEqualTo 1)};
waitUntil {(didJIP) || (TRG3LOCC isEqualTo 1)};

private _RestrictedArsenalVal = "RestrictedArsenal" call BIS_fnc_getParamValue;
if (_RestrictedArsenalVal isEqualTo 0) then {
	[] call FLO_fnc_restrictedArsenal;
};

// Initialize Intel System
[] call FLO_fnc_intelSystem;
diag_log "[FLO] Intelligence System initialized on Client";

// SYSTEMs Init Clients
Triggers0 = execVM "Scripts\Init\init_Triggers.sqf";
waitUntil {sleep 1; scriptDone Triggers0 };

// Hint end of init
hintSilent "LOADED!"; 