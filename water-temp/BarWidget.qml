import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property int capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name)
  readonly property int iconSize: Style.toOdd(capsuleHeight * 0.48)
  readonly property int miniGaugeWidth: Math.max(3, Style.toOdd(iconSize * 0.25))

  readonly property var main: pluginApi?.mainInstance
  readonly property real waterTemp: main?.waterTemp ?? 0
  readonly property int pumpRpm: main?.pumpRpm ?? 0
  readonly property int fanRpm: main?.fanRpm ?? 0
  readonly property bool sensorAvailable: main?.sensorAvailable ?? false
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  // Gauge ratios
  readonly property real tempRatio: Math.max(0, Math.min(1, (waterTemp - 20) / 30))
  readonly property real pumpRatio: Math.max(0, Math.min(1, pumpRpm / 5000))
  readonly property real fanRatio: Math.max(0, Math.min(1, fanRpm / 3000))

  readonly property string tooltipText: {
    if (!sensorAvailable) return "D5 Next: sensor not found";
    return `Coolant: ${waterTemp.toFixed(1)}°C\nPump: ${pumpRpm} RPM\nFan: ${fanRpm} RPM`;
  }

  // Required properties injected by PluginBarWidgetSlot
  property var pluginApi: null
  property ShellScreen screen
  property string section: ""
  property string widgetId: ""

  implicitWidth: isVertical ? capsuleHeight : Math.round(mainGrid.implicitWidth + Style.marginXL)
  implicitHeight: isVertical ? Math.round(mainGrid.implicitHeight + Style.marginXL) : capsuleHeight

  // Capsule background
  Rectangle {
    id: capsule
    anchors.fill: parent
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    GridLayout {
      id: mainGrid
      anchors.centerIn: parent
      flow: root.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rows: root.isVertical ? -1 : 1
      columns: root.isVertical ? 1 : -1
      columnSpacing: root.isVertical ? 0 : Style.marginM
      rowSpacing: root.isVertical ? Style.marginM : 0

      // Coolant temp
      Item {
        implicitWidth: tempContent.implicitWidth
        implicitHeight: tempContent.implicitHeight
        Layout.alignment: Qt.AlignCenter

        GridLayout {
          id: tempContent
          anchors.centerIn: parent
          flow: GridLayout.LeftToRight
          rows: 1
          columnSpacing: 3

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            Layout.alignment: Qt.AlignCenter

            NIcon {
              icon: "droplet"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: Color.mOnSurface
            }
          }

          Rectangle {
            Layout.alignment: Qt.AlignCenter
            width: root.miniGaugeWidth
            height: root.iconSize
            radius: width / 2
            color: Color.mOutline

            Rectangle {
              property real fillHeight: parent.height * root.tempRatio
              anchors.bottom: parent.bottom
              width: parent.width
              height: fillHeight
              radius: parent.radius
              color: Color.mPrimary

              Behavior on fillHeight {
                enabled: !Settings.data.general.animationDisabled
                NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
              }
            }
          }
        }
      }

      // Pump RPM
      Item {
        implicitWidth: pumpContent.implicitWidth
        implicitHeight: pumpContent.implicitHeight
        Layout.alignment: Qt.AlignCenter

        GridLayout {
          id: pumpContent
          anchors.centerIn: parent
          flow: GridLayout.LeftToRight
          rows: 1
          columnSpacing: 3

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            Layout.alignment: Qt.AlignCenter

            NIcon {
              icon: "rotate-clockwise"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: Color.mOnSurface
            }
          }

          Rectangle {
            Layout.alignment: Qt.AlignCenter
            width: root.miniGaugeWidth
            height: root.iconSize
            radius: width / 2
            color: Color.mOutline

            Rectangle {
              property real fillHeight: parent.height * root.pumpRatio
              anchors.bottom: parent.bottom
              width: parent.width
              height: fillHeight
              radius: parent.radius
              color: Color.mPrimary

              Behavior on fillHeight {
                enabled: !Settings.data.general.animationDisabled
                NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
              }
            }
          }
        }
      }

      // Fan RPM
      Item {
        implicitWidth: fanContent.implicitWidth
        implicitHeight: fanContent.implicitHeight
        Layout.alignment: Qt.AlignCenter

        GridLayout {
          id: fanContent
          anchors.centerIn: parent
          flow: GridLayout.LeftToRight
          rows: 1
          columnSpacing: 3

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            Layout.alignment: Qt.AlignCenter

            NIcon {
              icon: "propeller"
              pointSize: root.iconSize
              applyUiScale: false
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, contentHeight)
              color: Color.mOnSurface
            }
          }

          Rectangle {
            Layout.alignment: Qt.AlignCenter
            width: root.miniGaugeWidth
            height: root.iconSize
            radius: width / 2
            color: Color.mOutline

            Rectangle {
              property real fillHeight: parent.height * root.fanRatio
              anchors.bottom: parent.bottom
              width: parent.width
              height: fillHeight
              radius: parent.radius
              color: Color.mPrimary

              Behavior on fillHeight {
                enabled: !Settings.data.general.animationDisabled
                NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
              }
            }
          }
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton

    onEntered: {
      TooltipService.show(root, tooltipText, BarService.getTooltipDirection());
    }
    onExited: {
      TooltipService.hide();
    }
  }
}
