pragma Singleton
import QtQuick
import Quickshell
import "../../core"
import "../../styles"

Singleton {
    id: root

    readonly property int popupGap: 2
    readonly property int popupGapFloating: 4

    function belowBar(): real {
        return BarService.barY;
    }

    function anchorCenterX(anchorItem: Item, popupWidth: real, screenW: real): real {
        if (!anchorItem)
            return 0;
        var pos = mapAnchorGlobalPos(anchorItem);
        if (!pos)
            return 0;
        var x = pos.x + (anchorItem.width - popupWidth) / 2;
        return clampX(x, popupWidth, screenW);
    }

    function anchorRightX(anchorItem: Item, popupWidth: real, screenW: real): real {
        if (!anchorItem)
            return 0;
        var pos = mapAnchorGlobalPos(anchorItem);
        if (!pos)
            return 0;
        var x = pos.x + anchorItem.width - popupWidth;
        return clampX(x, popupWidth, screenW);
    }

    function mapAnchorGlobalPos(anchorItem: Item): var {
        if (!anchorItem)
            return null;
        if (anchorItem.mapToItem) {
            try {
                var pos = anchorItem.mapToItem(null, 0, 0);
                if (pos)
                    return pos;
            } catch (e) {}
        }
        if (anchorItem.window && anchorItem.window.mapFromItem) {
            var wpos = anchorItem.window.mapFromItem(anchorItem, 0, 0);
            if (wpos)
                return wpos;
        }
        if (anchorItem.QsWindow && anchorItem.QsWindow.mapFromItem) {
            var qpos = anchorItem.QsWindow.mapFromItem(anchorItem, 0, 0);
            if (qpos)
                return qpos;
        }
        return null;
    }

    function barRightX(popupWidth: real, screenW: real): real {
        var sw = screenW || 1920;
        var x = BarService.barX + BarService.barWidth - popupWidth - Theme.spaceMd;
        return clampX(x, popupWidth, sw);
    }

    function barCenterX(popupWidth: real, screenW: real): real {
        var sw = screenW || 1920;
        var x = BarService.barX + (BarService.barWidth - popupWidth) / 2;
        return clampX(x, popupWidth, sw);
    }

    function aboveItem(anchorItem: Item, popupHeight: real, gap: real): real {
        if (!anchorItem)
            return 0;
        var pos = anchorItem.QsWindow?.mapFromItem(anchorItem, 0, 0);
        if (!pos)
            return 0;
        var y = pos.y - popupHeight - (gap || popupGap);
        return Math.max(0, y);
    }

    function clampX(x: real, popupWidth: real, screenW: real): real {
        var sw = screenW || 1920;
        if (x + popupWidth > sw)
            return Math.max(0, sw - popupWidth);
        return Math.max(0, x);
    }
}
