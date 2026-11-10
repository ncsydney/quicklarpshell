pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool playerVisible: false

    function toggle() { playerVisible = !playerVisible }
    function show()   { playerVisible = true }
    function hide()   { playerVisible = false }

    // Functie om shuffle te toggelen op de actieve speler
    function toggleShuffle(player) {
        if (player && typeof player.shuffle !== "undefined") {
            player.shuffle = !player.shuffle;
        }
    }

    // Functie om repeat te toggelen (cyclisch: None -> Track -> Playlist -> None, of aan/uit afhankelijk van de speler)
    function toggleRepeat(player) {
        if (player && typeof player.loopStatus !== "undefined") {
            // Mpris loopStatus ondersteunt typisch: "None", "Track", "Playlist"
            if (player.loopStatus === "None") {
                player.loopStatus = "Playlist";
            } else if (player.loopStatus === "Playlist") {
                player.loopStatus = "Track";
            } else {
                player.loopStatus = "None";
            }
        }
    }
}
