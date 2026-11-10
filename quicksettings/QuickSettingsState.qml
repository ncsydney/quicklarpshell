pragma Singleton
import QtQuick
import QtCore
import Quickshell

QtObject {
    id: root

    property bool settingsVisible: false
    property bool networkMenuVisible: false
    property bool bluetoothMenuVisible: false

    function toggle() {
        settingsVisible = !settingsVisible;
        if (!settingsVisible) {
            networkMenuVisible = false;
            bluetoothMenuVisible = false;
        }
    }
    function show()   { settingsVisible = true }
    function hide()   {
        settingsVisible = false;
        networkMenuVisible = false;
        bluetoothMenuVisible = false;
    }

    function toggleNetworkMenu() {
        networkMenuVisible = !networkMenuVisible;
        if (networkMenuVisible) bluetoothMenuVisible = false;
    }

    function toggleBluetoothMenu() {
        bluetoothMenuVisible = !bluetoothMenuVisible;
        if (bluetoothMenuVisible) networkMenuVisible = false;
    }
}
