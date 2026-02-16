import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Public properties for BarWidget to read
  property real waterTemp: 0
  property int pumpRpm: 0
  property int fanRpm: 0
  property bool sensorAvailable: false

  // Resolved hwmon path
  property string hwmonPath: ""

  // Polling interval in seconds from settings
  readonly property int pollingInterval: parseInt(cfg.pollingInterval ?? defaults.pollingInterval ?? 5)

  Component.onCompleted: {
    hwmonScanner.checkNext();
  }

  // Scan hwmon0..15 to find the d5next sensor
  FileView {
    id: hwmonScanner
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        Logger.w("WaterTemp", "No d5next hwmon sensor found");
        return;
      }
      hwmonScanner.path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      hwmonScanner.reload();
    }

    onLoaded: {
      const name = text().trim();
      if (name === "d5next") {
        root.hwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        root.sensorAvailable = true;
        Logger.i("WaterTemp", `Found d5next sensor at ${root.hwmonPath}`);
        // Set paths and read immediately, then timer takes over
        tempReader.path = `${root.hwmonPath}/temp1_input`;
        pumpReader.path = `${root.hwmonPath}/fan1_input`;
        fanReader.path = `${root.hwmonPath}/fan2_input`;
        tempReader.reload();
        pumpReader.reload();
        fanReader.reload();
      } else {
        currentIndex++;
        Qt.callLater(() => { checkNext(); });
      }
    }

    onLoadFailed: function(error) {
      currentIndex++;
      Qt.callLater(() => { checkNext(); });
    }
  }

  // Periodically read all sensors
  Timer {
    id: pollTimer
    interval: root.pollingInterval * 1000
    repeat: true
    running: root.sensorAvailable
    onTriggered: {
      tempReader.reload();
      pumpReader.reload();
      fanReader.reload();
    }
  }

  // Read temp1_input (value in millidegrees C)
  FileView {
    id: tempReader
    printErrors: false

    onLoaded: {
      const raw = parseInt(text().trim());
      if (!isNaN(raw)) {
        root.waterTemp = Math.round(raw / 1000.0 * 10) / 10;
      }
    }

    onLoadFailed: function(error) {
      Logger.w("WaterTemp", "Failed to read temperature: " + error);
    }
  }

  // Read fan1_input (pump RPM)
  FileView {
    id: pumpReader
    printErrors: false

    onLoaded: {
      const raw = parseInt(text().trim());
      if (!isNaN(raw)) {
        root.pumpRpm = raw;
      }
    }

    onLoadFailed: function(error) {
      Logger.w("WaterTemp", "Failed to read pump RPM: " + error);
    }
  }

  // Read fan2_input (fan RPM)
  FileView {
    id: fanReader
    printErrors: false

    onLoaded: {
      const raw = parseInt(text().trim());
      if (!isNaN(raw)) {
        root.fanRpm = raw;
      }
    }

    onLoadFailed: function(error) {
      Logger.w("WaterTemp", "Failed to read fan RPM: " + error);
    }
  }
}
