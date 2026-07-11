#define FLO_DEVELOPMENT_CT_WEBBROWSER 106

class FLO_DevelopmentDialog {
    idd = 9960;
    movingEnable = 0;
    enableSimulation = 1;
    onUnload = "uiNamespace setVariable ['FLO_DevelopmentControl', controlNull]; FLO_DevelopmentBrowserReady = false";

    class Controls {
        class Browser: RscText {
            idc = 9961;
            type = FLO_DEVELOPMENT_CT_WEBBROWSER;
            style = 0;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 1};
        };
    };
};
