["Mission", 3, "Resetting Mission ..."] call FLO_fnc_log;

_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerTimeName = _missionTag + "_Time";
private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";
private _structureMarkerName = _missionTag + "_StructureMarkers";
private _missionStructureTypes = _missionTag + "_StructureTypes";



sleep 2;

profileNamespace setVariable [_MarkerTimeName, nil];
profileNamespace setVariable [_MarkerDataName, nil];
profileNamespace setVariable [_VehicleDataName, nil];
profileNamespace setVariable [_ObjectDataName, nil];
profileNamespace setVariable [_structureMarkerName, nil];
profileNamespace setVariable [_missionStructureTypes, nil];


sleep 5;
["Mission", 3, "Mission Reset !"] call FLO_fnc_log;


sleep 5;
"" remoteExec ["hint", 0];	