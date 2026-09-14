params ["_display", "_data"];
if (isNull _display) exitWith {false};
private _state = _display getVariable "FLO_StorePreview";
private _action = _data getOrDefault ["action", ""];
switch (_action) do {
    case "orbit": {
        private _dx = _data getOrDefault ["x", 0];
        private _dy = _data getOrDefault ["y", 0];
        if (_dx isEqualType 0 && {_dy isEqualType 0} && {finite _dx} && {finite _dy}) then {
            _state set ["angle", ((_state get "angle") + (-90 max _dx min 90)) mod 360];
            _state set ["pitch", -30 max ((_state get "pitch") + (-30 max _dy min 30)) min 60];
        };
    };
    case "zoom": {
        private _delta = _data getOrDefault ["value", 0];
        if (_delta isEqualType 0 && {finite _delta}) then {_state set ["zoom", 0.45 max ((_state get "zoom") + (-0.3 max _delta min 0.3)) min 2]};
    };
    case "reset": {_state set ["angle", 135]; _state set ["pitch", 8]; _state set ["zoom", 1]};
    case "mode": {
        private _mode = _data getOrDefault ["value", ""];
        if (_mode in ["character", "equipment"]) then {
            _state set ["mode", _mode];
            [_display, _state get "selection"] call FLO_fnc_storePreviewSelect;
        };
    };
    case "viewport": {
        private _rect = _data getOrDefault ["rect", []];
        if (_rect isEqualType [] && {count _rect == 4} && {_rect findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 1}} == -1} && {_rect select 2 > 0.05} && {_rect select 3 > 0.05}) then {_state set ["viewport", _rect]};
    };
};
[_display] call FLO_fnc_storePreviewUpdateCamera;
true
