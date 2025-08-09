class RscNotifications {
    idd = 1001;
    fadein = 0;
    fadeout = 0;
    duration = 1e+011;
    onLoad = "uiNamespace setVariable ['RscNotifications', _this select 0]";
    onUnLoad = "uiNamespace setVariable ['RscNotifications', nil]";

    class controlsBackground {};
    class controls {
        class IFrame: RscText {
            type = 106;
            idc = 1002;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
            url = "IDS_Notifications\ui\_site\index.html";
        };
    };
};