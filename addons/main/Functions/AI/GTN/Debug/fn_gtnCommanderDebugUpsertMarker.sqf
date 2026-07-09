/*
 * Function: FLO_fnc_gtnCommanderDebugUpsertMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or updates a GTN commander debug marker.
 *
 * Arguments:
 * 0: Marker id <STRING>
 * 1: Position <ARRAY>
 * 2: Marker type <STRING>
 * 3: Marker color <STRING>
 * 4: Marker text <STRING>
 * 5: Marker size <ARRAY>
 * 6: Marker alpha <NUMBER>
 *
 * Returns: None
 */
params ["_id", "_pos", "_type", "_color", "_text", ["_size", [0.6, 0.6]], ["_alpha", 1]];

createMarker [_id, _pos];
_id setMarkerPosLocal _pos;
_id setMarkerShapeLocal "ICON";
_id setMarkerTypeLocal _type;
_id setMarkerColorLocal _color;
_id setMarkerSizeLocal _size;
_id setMarkerTextLocal _text;
_id setMarkerAlpha _alpha;
