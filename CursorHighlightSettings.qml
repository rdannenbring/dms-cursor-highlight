import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "cursorHighlight"

    readonly property var daemonInstance: pluginService && pluginService.pluginDaemonInstances ? pluginService.pluginDaemonInstances[pluginId] : null
    readonly property bool ringActive: daemonInstance ? daemonInstance.active : false

    // Read-only code box with a copy button
    component BindCode: StyledRect {
        id: codeBox

        property string code

        width: parent.width
        height: codeEdit.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.withAlpha(Theme.outline, 0.3)

        TextEdit {
            id: codeEdit
            anchors.left: parent.left
            anchors.right: copyButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingS
            text: codeBox.code
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            selectionColor: Theme.primary
            selectedTextColor: Theme.surface
        }

        DankActionButton {
            id: copyButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXS
            iconName: "content_copy"
            iconSize: Theme.iconSize - 6
            buttonSize: 28
            tooltipText: "Copy to clipboard"
            onClicked: {
                Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | dms cl copy", "_", codeBox.code]);
                ToastService.showInfo("Copied to clipboard");
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Cursor Highlight"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Click-through ring around the cursor for presentations and screen sharing"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: generalColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: generalColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "General"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: parent.width - ringToggle.width - Theme.spacingM
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        text: "Show Ring"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Same as: dms ipc call cursorHighlight toggle"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }

                DankToggle {
                    id: ringToggle
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.ringActive
                    onToggled: isChecked => {
                        if (root.daemonInstance)
                            root.daemonInstance.active = isChecked;
                    }
                }
            }

            SliderSetting {
                settingKey: "pollRate"
                label: "Polling Rate"
                description: "How often the cursor position is sampled. Higher is smoother, slightly more CPU"
                defaultValue: 60
                minimum: 10
                maximum: 240
                unit: "Hz"
                rightIcon: "speed"
            }
        }
    }

    StyledRect {
        width: parent.width
        height: appearanceColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: appearanceColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Appearance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            SelectionSetting {
                id: styleSetting
                settingKey: "style"
                label: "Style"
                description: "Shape drawn at the cursor position"
                defaultValue: "ring"
                options: [
                    { label: "Ring", value: "ring" },
                    { label: "Dot", value: "dot" },
                    { label: "Arrow", value: "arrow" }
                ]
            }

            SliderSetting {
                settingKey: "size"
                label: "Size"
                description: styleSetting.value === "arrow" ? "Length of the arrow" : "Radius of the highlight"
                defaultValue: 28
                minimum: 8
                maximum: 100
                unit: "px"
                rightIcon: "radio_button_unchecked"
            }

            SliderSetting {
                visible: styleSetting.value === "ring"
                settingKey: "thickness"
                label: "Ring Thickness"
                description: "Border width of the ring"
                defaultValue: 4
                minimum: 1
                maximum: 20
                unit: "px"
                rightIcon: "line_weight"
            }

            ColorSetting {
                id: colorSetting
                settingKey: "color"
                label: "Color"
                description: "Defaults to the theme primary color"
                defaultValue: Theme.primary
            }

            DankButton {
                text: "Reset Color to Theme Default"
                iconName: "format_color_reset"
                onClicked: {
                    // Remove the stored value entirely (instead of saving the current
                    // theme color as a fixed hex) so the highlight keeps following the theme
                    colorSetting.isInitialized = false;
                    colorSetting.value = colorSetting.defaultValue;
                    root.saveValue("color", undefined);
                    colorSetting.isInitialized = true;
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: tipsColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surface

        Column {
            id: tipsColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                spacing: Theme.spacingM

                DankIcon {
                    name: "info"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "Keybind Tips"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Example Hyprland binds - adjust keys to taste."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
                lineHeight: 1.4
            }

            StyledText {
                text: "Show while holding a key (e.g. Control):"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            BindCode {
                code: "bind = , Control_L, exec, dms ipc call cursorHighlight enable\nbindr = , Control_L, exec, dms ipc call cursorHighlight disable"
            }

            StyledText {
                text: "Toggle with a keybind (e.g. Super+Shift+M):"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            BindCode {
                code: "bindd = SUPER SHIFT, M, Toggle cursor ring, exec, dms ipc call cursorHighlight toggle"
            }
        }
    }
}
