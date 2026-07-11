params ["_registry", "_records"];

private _seen = createHashMap;
private _created = 0;
private _changed = 0;
private _commands = 0;

{
    _x params ["_markerId", "_shape", "_pos", "_type", "_size", "_alpha", "_text", "_color", "_brush"];
    private _descriptor = [_shape, _pos, _type, _size, _alpha, _text, _color, _brush];
    _seen set [_markerId, true];

    if !(_markerId in _registry) then {
        createMarkerLocal [_markerId, _pos];
        _markerId setMarkerPosLocal _pos;
        _markerId setMarkerShapeLocal _shape;
        if (_shape == "ICON") then {
            _markerId setMarkerTypeLocal _type;
        } else {
            _markerId setMarkerBrushLocal _brush;
        };
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
    private _shapeChanged = (_previous select 0) != _shape;
    if (_shapeChanged) then {
        _markerId setMarkerShapeLocal _shape;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 1) isNotEqualTo _pos) then {
        _markerId setMarkerPosLocal _pos;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if (_shape == "ICON" && {_shapeChanged || {(_previous select 2) != _type}}) then {
        _markerId setMarkerTypeLocal _type;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if (_shape != "ICON" && {_shapeChanged || {(_previous select 7) != _brush}}) then {
        _markerId setMarkerBrushLocal _brush;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 3) isNotEqualTo _size) then {
        _markerId setMarkerSizeLocal _size;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 4) != _alpha) then {
        _markerId setMarkerAlphaLocal _alpha;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 5) != _text) then {
        _markerId setMarkerTextLocal _text;
        _commands = _commands + 1;
        _markerChanged = true;
    };
    if ((_previous select 6) != _color) then {
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
