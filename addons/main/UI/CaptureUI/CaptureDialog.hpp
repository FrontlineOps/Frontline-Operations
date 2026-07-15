/*
 * FLO Capture Balance UI
 * Author: Frontline Operations
 *
 * Description:
 * HTML-based HUD element showing balance of power during objective capture.
 * Uses iframe (type 106) for modern CSS animations and effects.
 *
 * IDC Reference (for SQF):
 *   IDD: 1100
 *   1101 - IFrame control (HTML UI)
 */

class FLO_CaptureUI {
    idd = 1100;
    duration = 1e11;
    fadein = 0;
    fadeout = 0;
    onLoad = "[_this select 0] call FLO_fnc_captureUIOnLoad";
    onUnload = "[] call FLO_fnc_captureUIOnUnload";

    class ControlsBackground {};

    class Controls {
        class IFrame: RscText {
            type = 106;
            idc = 1101;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
            url = "\z\flo\addons\main\UI\CaptureUI\_site\index.html";
        };
    };
};

