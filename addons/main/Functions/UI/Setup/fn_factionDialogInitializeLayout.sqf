/* Record numeric force controls once; objective templates share their space. */
disableSerialization;
params ["_display"];
private _body = _display displayCtrl 1950;
private _objectives = uiNamespace getVariable ["FLO_FactionObjectiveGroupControls", []];
private _anchor = ctrlPosition (_display displayCtrl 2096);
private _bottom = ctrlPosition (_display displayCtrl 2093);
private _numericTop = (_anchor select 1) - ((_anchor select 3) * 1.8);
private _numericBottom = (_bottom select 1) + (_bottom select 3) + 0.01;
private _numeric = [];
{
    private _y = (ctrlPosition _x) select 1;
    if ((ctrlParentControlsGroup _x) isEqualTo _body && {_y >= _numericTop} && {_y <= _numericBottom}
        && {!(_x in _objectives)} && {!(ctrlIDC _x in [2094, 2095, 2096])}) then {
        _numeric pushBack _x;
    };
} forEach allControls _display;
_display setVariable ["FLO_SetupNumericControls", _numeric];
["composition"] call FLO_fnc_factionDialogShowCompositionTab;
