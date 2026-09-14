params ["_control", "_args"];

// Native ExecJS interprets raw UTF-8 bytes as single-byte text. Keep its input ASCII.
if ((_args select 0) == "ExecJS") then {
    private _codes = toArray (_args select 1);
    if (_codes findIf {_x > 127} != -1) then {
        private _hex = "0123456789abcdef";
        private _script = (_codes apply {
            if (_x < 128) then {toString [_x]} else {
                format ["\u%1%2%3%4",
                    _hex select [floor (_x / 4096) mod 16, 1],
                    _hex select [floor (_x / 256) mod 16, 1],
                    _hex select [floor (_x / 16) mod 16, 1],
                    _hex select [_x mod 16, 1]]
            }
        }) joinString "";
        _args = ["ExecJS", _script];
    };
};
_control ctrlWebBrowserAction _args;
