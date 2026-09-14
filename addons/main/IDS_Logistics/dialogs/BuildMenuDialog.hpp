#include "Defines.hpp"
class IDS_Logistics_BuildMenuDialog {
    idd = 9500;
    movingEnable = 0;
    enableSimulationGlobal = 1;
    onLoad = "[_this select 0] call IDS_Logistics_fnc_handlePreview";
    class RscObject
    {
        type = CT_OBJECT;
        scale = 1;
        direction[] = {0,0,1};
        model = "\core\empty\empty.p3d";
        up[] = {0,1,0};
        shadow = 0;
    };

    class Objects {
        class Entity: RscObject {
            idc = 9506;
            type = 82;
            model = "\A3\Structures_F\Mil\Cargo\Cargo_HQ_V1_F.p3d";
            scale = 0.01;
            direction[] = {0, -0.35, -0.65};
            up[] = {0, 0.65, -0.35};
            x = "0.285 * safezoneW + safezoneX";
            y = "0.45 * safezoneH + safezoneY";
            z = 0.2;
            xBack = "0.285 * safezoneW + safezoneX";
            yBack = "0.45 * safezoneH + safezoneY";
            zBack = 0.5;
            inBack = 1;
            enableZoom = 0;
            zoomDuration = 0.001;
            shadow = 0;
        };
    };

    class ControlsBackground {
        class Background: FLO_RscBackground {
            idc = -1; x = "safeZoneX + 0.08 * safeZoneW"; y = "safeZoneY + 0.10 * safeZoneH";
            w = "0.84 * safeZoneW"; h = "0.78 * safeZoneH";
        };
        class Preview: FLO_RscSurface {
            idc = -1; x = "safeZoneX + 0.10 * safeZoneW"; y = "safeZoneY + 0.22 * safeZoneH";
            w = "0.35 * safeZoneW"; h = "0.44 * safeZoneH";
        };
    };
    class Controls {
        class Title: FLO_RscText_Title {
            idc = -1; text = "Base construction";
            x = "safeZoneX + 0.1 * safeZoneW"; y = "safeZoneY + 0.115 * safeZoneH";
            w = "0.6 * safeZoneW"; h = "0.045 * safeZoneH";

        };
        class Close: FLO_RscButton_Secondary {
            idc = -1; text = "Close";
            x = "safeZoneX + 0.79 * safeZoneW"; y = "safeZoneY + 0.115 * safeZoneH";
            w = "0.11 * safeZoneW"; h = "0.045 * safeZoneH";
            action = "closeDialog 0";
        };
        class PreviewHelp: FLO_RscText_Muted {
            idc = -1; text = "W/A/S/D: rotate   |   +/-: zoom";
            x = "safeZoneX + 0.1 * safeZoneW"; y = "safeZoneY + 0.665 * safeZoneH";
            w = "0.35 * safeZoneW"; h = "0.035 * safeZoneH";

        };
        class EntityInfo: FLO_RscStructuredText {
            idc = 9504; text = "";
            x = "safeZoneX + 0.1 * safeZoneW"; y = "safeZoneY + 0.715 * safeZoneH";
            w = "0.35 * safeZoneW"; h = "0.13 * safeZoneH";

        };
        class CategoryLabel: FLO_RscText_Label {
            idc = -1; text = "Category";
            x = "safeZoneX + 0.48 * safeZoneW"; y = "safeZoneY + 0.185 * safeZoneH";
            w = "0.19 * safeZoneW"; h = "0.03 * safeZoneH";

        };
        class CategoryList: FLO_RscCombo {
            idc = 9501; text = "";
            x = "safeZoneX + 0.48 * safeZoneW"; y = "safeZoneY + 0.22 * safeZoneH";
            w = "0.19 * safeZoneW"; h = "0.045 * safeZoneH";
            onLBSelChanged = "_this call IDS_Logistics_fnc_updateEntityList";
        };
        class SearchLabel: FLO_RscText_Label {
            idc = -1; text = "Search";
            x = "safeZoneX + 0.69 * safeZoneW"; y = "safeZoneY + 0.185 * safeZoneH";
            w = "0.19 * safeZoneW"; h = "0.03 * safeZoneH";

        };
        class SearchEdit: FLO_RscEdit {
            idc = 9502; text = "";
            x = "safeZoneX + 0.69 * safeZoneW"; y = "safeZoneY + 0.22 * safeZoneH";
            w = "0.19 * safeZoneW"; h = "0.045 * safeZoneH";
            tooltip = "Filter objects by name"; onKeyUp = "_this call IDS_Logistics_fnc_searchEntities";
        };
        class EntitiesList: FLO_RscListBox {
            idc = 9503; text = "";
            x = "safeZoneX + 0.48 * safeZoneW"; y = "safeZoneY + 0.285 * safeZoneH";
            w = "0.4 * safeZoneW"; h = "0.445 * safeZoneH";
            onLBSelChanged = "_this call IDS_Logistics_fnc_updatePreview";
        };
        class SelectButton: FLO_RscButton {
            idc = 9505; text = "Place selected object";
            x = "safeZoneX + 0.48 * safeZoneW"; y = "safeZoneY + 0.755 * safeZoneH";
            w = "0.4 * safeZoneW"; h = "0.055 * safeZoneH";
            action = "call IDS_Logistics_fnc_selectEntity";
        };
    };
};
