#define FLO_STORE_KITS_CT_WEBBROWSER 106

class FLO_StoreKitsDialog {
    idd = 9810;
    movingEnable = 0;
    enableSimulation = 1;
    onUnload = "uiNamespace setVariable ['FLO_StoreKitsControl', controlNull]";

    class Controls {
        class Browser: RscText {
            idc = 9811;
            type = FLO_STORE_KITS_CT_WEBBROWSER;
            style = 0;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};
