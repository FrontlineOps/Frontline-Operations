private _REPSCORE = FLO_ReputationHandle get "value";  

private _nearRoad = selectRandom ( (position player) nearRoads 500 ) ; 

private _mrker = createMarkerLocal [str getpos _nearRoad, getpos _nearRoad]; 
_mrker setMarkerTypeLocal "hd_warning";
_mrker setMarkerColorLocal "colorCivilian";
_mrker setMarkerTextLocal "Repair Vehicle"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true;
[markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;
 
sleep 5;

["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_REPAIR", "info"] call FLO_fnc_sendNotification;

private _V = createVehicle [ selectRandom CivVehArray, getpos _nearRoad, [], 4, "NONE"]; 
private _nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
private _dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
_V setdamage 0.7;

_V addEventHandler ["Killed", {

private _MMarks = allMapMarkers select { markerText _x == "Repair Vehicle"};
private _M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

["ScoreAdded", ["Vehicle Destroyed", 00]] call BIS_fnc_showNotification;  

removeAllActions (_this select 0);
}];

[     
  _V,
  "Repair Civilian Vehicle",
  "Screens\FOBA\iconRepairAt_ca.paa",
  "Screens\FOBA\iconRepairAt_ca.paa",
  "_this distance _target < 7",       
  "_caller distance _target < 7",  
  {},
  {},
  {

  private _MMarks = allMapMarkers select { markerText _x == "Repair Vehicle"};
  private _M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
  deleteMarker _M ; 

  (_this select 0) setdamage 0;

  [0.35, 'increase'] call FLO_fnc_adjustReputation;

  ["ScoreAdded", ["Vehicle Repaired", 00]] call BIS_fnc_showNotification;  
  playMusic "EventTrack01_F_Curator";   

  execVM "Scripts\Civ_Relations.sqf";

  [(_this select 0),(_this select 2)] remoteExec ["bis_fnc_holdActionRemove",[0,-2] select isDedicated,true];
  },
  {},
  [],
  11,
  0,
  true,
  false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _V]; 


//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

if (_REPSCORE < 7) then {
  private _PRL = [getpos _V, East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
  [_PRL, getpos _V, 100] call BIS_fnc_taskPatrol;
};
