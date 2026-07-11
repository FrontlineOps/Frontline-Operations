if (!hasInterface) exitWith {};

private _display = uiNamespace getVariable ["FLO_NotificationDisplay", displayNull];
if (isNull _display) exitWith {
    if (!FLO_NotificationRenderQueued) then {
        FLO_NotificationRenderQueued = true;
        FLO_NotificationLayer cutRsc ["FLO_NotificationTitle", "PLAIN"];
        [
            {
                FLO_NotificationRenderQueued = false;
                [] call FLO_fnc_notificationRender;
            },
            [],
            FLO_NotificationRenderRetryDelay
        ] call CBA_fnc_waitAndExecute;
    };
};
FLO_NotificationRenderQueued = false;

private _w = 0.285 * safeZoneW;
private _h = 0.074 * safeZoneH;
private _gap = 0.010 * safeZoneH;
private _x = safeZoneX + safeZoneW - _w - (0.010 * safeZoneW);
private _y0 = safeZoneY + (0.145 * safeZoneH);
private _accentW = 0.0045 * safeZoneW;
private _padX = 0.010 * safeZoneW;
private _titleH = 0.024 * safeZoneH;

for "_i" from 0 to ((count FLO_NotificationActive) - 1) do {
    private _entry = FLO_NotificationActive select _i;
    private _style = [_entry get "type"] call FLO_fnc_notificationStyle;
    private _controls = [];

    if ("controls" in _entry && {!isNull ((_entry get "controls") select 0)}) then {
        _controls = _entry get "controls";
    } else {
        private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
        private _bg = _display ctrlCreate ["RscText", -1, _group];
        private _accent = _display ctrlCreate ["RscText", -1, _group];
        private _topLine = _display ctrlCreate ["RscText", -1, _group];
        private _title = _display ctrlCreate ["RscText", -1, _group];
        private _body = _display ctrlCreate ["RscStructuredText", -1, _group];

        _controls = [_group, _bg, _accent, _topLine, _title, _body];
        _entry set ["controls", _controls];

        _group ctrlSetFade 1;
        _group ctrlCommit 0;
        _group ctrlSetFade 0;
        _group ctrlCommit 0.14;
    };

    _controls params ["_group", "_bg", "_accent", "_topLine", "_title", "_body"];

    private _y = _y0 + (_i * (_h + _gap));
    private _accentColor = _style get "accent";
    private _backgroundColor = _style get "background";
    private _accentHtml = _style get "accentHtml";

    _group ctrlSetPosition [_x, _y, _w, _h];
    _group ctrlCommit 0.18;

    _bg ctrlSetPosition [0, 0, _w, _h];
    _bg ctrlSetBackgroundColor _backgroundColor;
    _bg ctrlCommit 0;

    _accent ctrlSetPosition [0, 0, _accentW, _h];
    _accent ctrlSetBackgroundColor _accentColor;
    _accent ctrlCommit 0;

    _topLine ctrlSetPosition [0, 0, _w, 0.002 * safeZoneH];
    _topLine ctrlSetBackgroundColor _accentColor;
    _topLine ctrlCommit 0;

    _title ctrlSetPosition [_accentW + _padX, 0.010 * safeZoneH, _w - _accentW - (_padX * 2), _titleH];
    _title ctrlSetText (toUpper (_entry get "title"));
    _title ctrlSetTextColor _accentColor;
    _title ctrlCommit 0;

    _body ctrlSetPosition [
        _accentW + _padX,
        0.032 * safeZoneH,
        _w - _accentW - (_padX * 2),
        _h - (0.036 * safeZoneH)
    ];
    _body ctrlSetStructuredText (parseText format [
        "<t color='#F2F7FA' size='0.90'>%1</t><br/><t color='%2' size='0.60'>%3</t>",
        [_entry get "message"] call FLO_fnc_notificationEscapeStructuredText,
        _accentHtml,
        "FLO"
    ]);
    _body ctrlCommit 0;
};
