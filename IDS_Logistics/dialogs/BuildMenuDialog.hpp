#include "Defines.hpp"

class IDS_Logistics_BuildMenuDialog {
    idd = 9500;
    movingEnable = 0;
    enableSimulationGlobal = 1;
    onLoad = "[_this select 0] call IDS_Logistics_fnc_handlePreview;";

    class Objects {
        class Entity: RscEntity {
            idc = 9506;
            type = 82;
            model = "\A3\Structures_F\Mil\Cargo\Cargo_HQ_V1_F.p3d"; // Default model
            scale = 0.01;
            direction[] = {0, -0.35, -0.65};
            up[] = {0, 0.65, -0.35};
            
            x = 0.36 * safezoneW + safezoneX; // Center of preview area
            y = 0.685 * safezoneH + safezoneY;
            z = 0.2;
            
            xBack = 0.36 * safezoneW + safezoneX;
            yBack = 0.685 * safezoneH + safezoneY;
            zBack = 0.5;
            
            inBack = 1;
            enableZoom = 0;
            zoomDuration = 0.001;
            shadow = 0;
            access = 0;
        };
    };
    
    class ControlsBackground {
        class Background: IGUIBack {
            idc = -1;
            x = 0.25 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.5 * safezoneW;
            h = 0.5 * safezoneH;
            colorBackground[] = {0.1, 0.1, 0.1, 0.8};
        };
        
        class HeaderBackground: IGUIBack {
            idc = -1;
            x = 0.25 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.5 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.4, 0.4, 0.4, 1};
        };
        
        class Title: RscText {
            idc = -1;
            text = "Base Building - Select Entity";
            x = 0.25 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.5 * safezoneW;
            h = 0.05 * safezoneH;
            colorText[] = {1, 1, 1, 1};
            sizeEx = 0.04;
            style = ST_CENTER;
        };

        class PreviewFrame: RscFrame {
            idc = -1;
            x = 0.26 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.2 * safezoneW;
            h = 0.07 * safezoneH;
            colorText[] = {0.5, 0.5, 0.5, 1};
        };
    };
    
    class Controls {
        // Categories list
        class CategoryLabel: RscText {
            idc = -1;
            text = "Categories:";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.31 * safezoneH + safezoneY;
            w = 0.2 * safezoneW;
            h = 0.03 * safezoneH;
        };
        
        class CategoryList: RscListBox {
            idc = 9501;
            x = 0.26 * safezoneW + safezoneX;
            y = 0.35 * safezoneH + safezoneY;
            w = 0.2 * safezoneW;
            h = 0.25 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 1};
            rowHeight = 0.05;
            sizeEx = 0.03;
            onLBSelChanged = "_this call IDS_Logistics_fnc_updateEntityList";
        };
        
        // Entities list
        class EntitiesLabel: RscText {
            idc = -1;
            text = "Entities:";
            x = 0.47 * safezoneW + safezoneX;
            y = 0.31 * safezoneH + safezoneY;
            w = 0.27 * safezoneW;
            h = 0.03 * safezoneH;
        };
        
        class SearchEdit: RscEdit {
            idc = 9502;
            x = 0.54 * safezoneW + safezoneX;
            y = 0.31 * safezoneH + safezoneY;
            w = 0.2 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.3, 0.3, 0.3, 1};
            text = "";
            tooltip = "Search entities";
            onKeyUp = "_this call IDS_Logistics_fnc_searchEntities";
        };
        
        class EntitiesList: RscListBox {
            idc = 9503;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.35 * safezoneH + safezoneY;
            w = 0.27 * safezoneW;
            h = 0.25 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 1};
            rowHeight = 0.05;
            sizeEx = 0.03;
            onLBSelChanged = "_this call IDS_Logistics_fnc_updatePreview";
        };
        
        // Entity preview
        class PreviewLabel: RscText {
            idc = -1;
            text = "Preview:";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.1 * safezoneW;
            h = 0.03 * safezoneH;
        };
        
        class EntityInfo: RscStructuredText {
            idc = 9504;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.27 * safezoneW;
            h = 0.11 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.2, 0.8};
            size = 0.03;
        };
        
        // Action buttons
        class SelectButton: RscButton {
            idc = 9505;
            text = "Select";
            x = 0.57 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.08 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2, 0.6, 0.2, 1};
            colorBackgroundActive[] = {0.2, 0.8, 0.2, 1};
            action = "call IDS_Logistics_fnc_selectEntity";
        };
        
        class CancelButton: RscButton {
            idc = -1;
            text = "Cancel";
            x = 0.66 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.08 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.6, 0.2, 0.2, 1};
            colorBackgroundActive[] = {0.8, 0.2, 0.2, 1};
            action = "closeDialog 0";
        };
    };
};