import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "cursorHighlight"

    StyledText {
        text: "Cursor Highlight"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: "Click-through ring around the cursor for presentations and screen sharing. Toggle with: dms ipc call cursorHighlight toggle"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    SliderSetting {
        settingKey: "ringRadius"
        label: "Ring Radius"
        description: "Radius of the highlight ring"
        defaultValue: 28
        minimum: 8
        maximum: 100
        unit: "px"
        rightIcon: "radio_button_unchecked"
    }

    SliderSetting {
        settingKey: "ringThickness"
        label: "Ring Thickness"
        description: "Border width of the ring"
        defaultValue: 4
        minimum: 1
        maximum: 20
        unit: "px"
        rightIcon: "line_weight"
    }

    ColorSetting {
        settingKey: "ringColor"
        label: "Ring Color"
        description: "Defaults to the theme primary color"
        defaultValue: Theme.primary
    }
}
