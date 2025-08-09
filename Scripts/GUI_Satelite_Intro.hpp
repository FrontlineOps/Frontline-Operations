class intro {
    idd = -1;
    movingEnable = 0;
    duration = 999999;
    fadein = 0;
    fadeout = 0;
    name = "intro";
    controls[] = {"title1", "title2", "title3"};

    class title1 {
        type = 0;
        idc = 1;
        size = 5;
        colorBackground[] = {0,0,0,0};
        colorText[] = {1,1,1,1};
        font = "PuristaMedium";
        text = "Screens\FOBA\BACK.paa";
        style = 48;
        sizeEx = 0.15;
        x = safeZoneX + 0.725 * safeZoneW;
        y = safeZoneY + 0.11 * safeZoneH;
        w = safeZoneW * 0.325;
        h = safeZoneH * 0.54;
    };

    class title2 {
        type = 0;
        idc = 1;
        size = 5;
        colorBackground[] = {0,0,0,0};
        colorText[] = {1,1,1,1};
        font = "PuristaMedium";
        text = "#(argb,512,512,1)r2t(HCAM_S,1)";
        style = 48;
        sizeEx = 0.15;
        x = safeZoneX + 0.75 * safeZoneW;
        y = safeZoneY + 0.24 * safeZoneH;
        w = safeZoneW * 0.244;
        h = safeZoneH * 0.25;
    };

    class title3 {
        type = 0;
        idc = 2;
        size = 2;
        colorBackground[] = {0,0,0,0};
        colorText[] = {1,1,1,1};
        font = "PuristaMedium";
        text = "Screens\FOBA\SAT_DLG.paa";
        style = 48;
        sizeEx = 0.15;
        x = safeZoneX + 0.725 * safeZoneW;
        y = safeZoneY + 0.11 * safeZoneH;
        w = safeZoneW * 0.325;
        h = safeZoneH * 0.54;
    };
};