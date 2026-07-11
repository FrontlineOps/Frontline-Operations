#define FLO_OPERATIONS_CT_WEBBROWSER 106

class FLO_OperationsDialog {
    idd = 9950;
    movingEnable = 0;
    enableSimulation = 1;
    onUnload = "uiNamespace setVariable ['FLO_OperationsControl', controlNull]; uiNamespace setVariable ['FLO_OperationsMapControl', controlNull]; FLO_OperationsBrowserReady = false; FLO_OperationsMapInitialized = false";

    class Controls {
        class Browser: RscText {
            idc = 9951;
            type = FLO_OPERATIONS_CT_WEBBROWSER;
            style = 0;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 0};
        };

        class Map: FLO_RscMap {
            idc = 9952;
            x = "safeZoneX + (safeZoneW * 0.175)";
            y = "safeZoneY + (safeZoneH * 0.085)";
            w = "safeZoneW * 0.635";
            h = "safeZoneH * 0.87";
            colorBackground[] = {0.035, 0.065, 0.08, 1};
            colorOutside[] = {0.012, 0.025, 0.035, 1};
            colorSea[] = {0.04, 0.13, 0.18, 1};
            colorForest[] = {0.12, 0.21, 0.16, 0.9};
            colorForestBorder[] = {0.24, 0.36, 0.28, 0.9};
            colorGrid[] = {0.21, 0.52, 0.62, 0.32};
            colorGridMap[] = {0.21, 0.52, 0.62, 0.22};
            colorRoads[] = {0.64, 0.7, 0.72, 0.95};
            colorRoadsFill[] = {0.18, 0.23, 0.25, 1};
            colorMainRoads[] = {0.91, 0.72, 0.39, 0.95};
            colorMainRoadsFill[] = {0.27, 0.23, 0.18, 1};
            maxSatelliteAlpha = 0.72;
            alphaFadeStartScale = 0.12;
            alphaFadeEndScale = 0.24;
        };
    };
};
