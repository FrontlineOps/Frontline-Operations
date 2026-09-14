/* Frame the local subject in the transparent browser opening, including narrow screens. */
params ["_display"];
if (isNull _display) exitWith {};
private _state = _display getVariable "FLO_StorePreview";
private _subject = _state get "subject";
// General bounds include firing/memory proxies much larger than the equipment itself.
private _bounds = boundingBoxReal [_subject, "Geometry"];
if ((_bounds select 0) isEqualTo (_bounds select 1)) then {_bounds = 0 boundingBoxReal _subject};
private _center = ((_bounds select 0) vectorAdd (_bounds select 1)) vectorMultiply 0.5;
private _size = (_bounds select 1) vectorDiff (_bounds select 0);
private _radius = (vectorMagnitude _size * 0.5) max 0.15;
if (_subject isEqualTo (_state get "man")) then {_center = [0, 0, 0.95]; _radius = 1.05};
private _target = _subject modelToWorldVisualWorld _center;
private _rect = _state get "viewport";
_rect params ["_x", "_y", "_width", "_height"];
private _resolution = getResolution;
private _aspect = (_resolution select 0) / (_resolution select 1);
private _distance = _radius / ((_width min (_height / _aspect)) * 0.62) * (_state get "zoom");
private _angle = _state get "angle";
private _pitch = _state get "pitch";
private _forward = [sin _angle * cos _pitch, cos _angle * cos _pitch, -sin _pitch];
private _right = [cos _angle, -sin _angle, 0];
private _up = _right vectorCrossProduct _forward;
private _shift = (_right vectorMultiply ((0.5 - (_x + _width / 2)) * _distance * 1.4)) vectorAdd
    (_up vectorMultiply (((_y + _height / 2) - 0.5) * _distance * 1.4 / _aspect));
private _camera = _state get "camera";
_camera camSetPos (ASLToAGL ((_target vectorDiff (_forward vectorMultiply _distance)) vectorAdd _shift));
_camera camSetTarget (ASLToAGL (_target vectorAdd _shift));
_camera camCommit 0;
(_state get "light") setPosASL (_target vectorDiff (_forward vectorMultiply (_radius * 3)) vectorAdd [0, 0, _radius]);
