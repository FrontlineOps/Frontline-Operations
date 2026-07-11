params ["_registry", "_records"];

private _seen = createHashMap;
private _created = 0;
private _changed = 0;
private _commands = 0;

{
    _x params ["_markerId", "_pos", "_type", "_size", "_alpha", "_text", "_color"];
    private _descriptor = [_pos, _type, _size, _alpha, _text, _color];
    _seen set [_markerId, true];

    if !(_markerId in _registry) then {
        createMarkerLocal [_markerId, _pos];
        _markerId setMarkerPosLocal _pos;
        _markerId setMarkerShapeLocal "ICON";
        _markerId setMarkerTypeLocal _type;
        _markerId setMarkerSizeLocal _size;
        _markerId setMarkerColorLocal _color;
        _markerId setMarkerTextLocal _text;
        _markerId setMarkerAlphaLocal _alpha;
        _registry set [_markerId, _descriptor];
        _created = _created + 1;
        _commands = _commands + 7;
        continue;
    };

    private _previous = _registry get _markerId;
    private _markerChanged = false;
    if ((_previous select 0) isNotEqualTo _pos) then {
        _markerId setMarkerPosLocal _pos;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 1) != _type) then {
        _markerId setMarkerTypeLocal _type;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 2) isNotEqualTo _size) then {
        _markerId setMarkerSizeLocal _size;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 3) != _alpha) then {
        _markerId setMarkerAlphaLocal _alpha;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 4) != _text) then {
        _markerId setMarkerTextLocal _text;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 5) != _color) then {
        _markerId setMarkerColorLocal _color;
        _commands = _commands + 1;
        _markerChanged = true;
    };

    if (_markerChanged) then {
        _registry set [_markerId, _descriptor];
        _changed = _changed + 1;
    };
} forEach _records;

[_seen, _created, _changed, _commands]
