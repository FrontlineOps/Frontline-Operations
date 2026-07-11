params [["_text", "", [""]]];

private _escaped = "";
{
    _escaped = _escaped + (switch _x do {
        case 10: { "<br/>" };
        case 13: { "" };
        case 38: { "&amp;" };
        case 60: { "&lt;" };
        case 62: { "&gt;" };
        default { toString [_x] };
    });
} forEach toArray _text;

_escaped
