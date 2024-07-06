# HAL9000-installer
Installationsprogramm für https://github.com/juergenpabel/HAL9000

`git clone https://github.com/juergenpabel/HAL9000-installer.git`  
`cd HAL9000-installer`  
`./start.sh`  

Dieses Installationsprogramm sollte auf allen (aktuellen) Debian-basierten Linux Systemen funktionieren.
Während der Installation werden benötigte System-Pakete (podman, ...) installiert, es wird ein lokaler
(nicht-privilegierter) Benutzer 'hal9000' (und eine gleichnamige Gruppe) als Applikationsbenutzer
erstellt sowie verschiedene Änderungen an der Systemkonfiguration (Soundkarte, ...) vorgenommen; dann
werden Container-Images runtergeladen (oder neu gebaut). Zuletzt werden die Container zum automatischen
Start während des Systemstarts in per SystemD registriert (in einer Benutzer-Instanz von SystemD unter
dem Benutzer 'hal9000'). Das wäre es im Großen und Ganzen.

Dieses Installationsprogramm nutzt eine text-basierte Benutzer-Oberfläche (TUI) und kann daher auch per
SSH genutzt werden. Ab einer "Auflösung" von 120 Spalten und 30 Zeilen sieht es dann auch ganz passable
aus. Es werden 3 Bildschirmseiten bereitgestellt:
- Installation (über die '1' oder per Maus-Klick in die Fusszeile aufrufbar)
- Terminal (über die '2' oder per Maus-Klick in die Fusszeile aufrufbar)
- Hilfe (über die '9' oder per Maus-Klick in die Fusszeile aufrufbar)

Das Beenden des Installationsprogramms erfolgt über STRG-C (oder per Maus-Klick in die Fusszeile).

## Bildschirmseite: Installation
![Screenshot: Installer screen](resources/images/screen_installer.png)

Die Bildschirmseite 'Installation' wird genutzt um das System auf die Ausführung der HAL9000-Anwendung
(die in Containern erfolgt) vorzubereiten, z.B. Software-Pakete installieren und System-Konfigurationen
vornehmen. Die Bildschirmseite besteht aus drei Elementen:
- Interaktionsbereich
- Schaltfläche ("button")
- Ausführungsfenster

Im ersten Schritt müssend ein paar Auswahlmöglichkeiten beantwortet werden:
- Strategie: "Standard" oder "Experte" ("Standard" wird empfohlen, da die eigentliche Installation dann
voll-automatisch erfolgt)
- Binärdateien: Ob vor-kompilierte Dateien ("images") heruntergeladen werden sollen oder (als Teil der
Installation) kompiliert werden sollen
- Version: Welcher Versionsstand genutzt werden soll (aktuell nur 'Stable' oder 'Development')
- Konfiguration: Welche (Demo-)Konfiguration genutzt werden soll (Deutsch/Englisch)
- Soundkarte: Welche Soundkarte genutzt werden soll (auf einem Raspberry Zero2W wird ein Treiber für den
Respeaker 2-mic mit installiert)
- Arduino: Welches (der unterstützten) Arduino-Boards wird eingesetzt (oder "None" zur exklusiven Nutzung
des HTTP-Frontends)

Danach (im "Standard" Modus) wird die berechnete Liste der Installationsschritte dargestellt und über die
Schaltfläche ("button") kann die Installation gestartet werden. Die Ausführung der Schritte wird im
Ausführungsfenster angezeigt, während im Interaktionsbereich die Liste der Installationsschritte entsprechend
des Fortschritts aktualisiert wird.

## Bildschirmseite: Terminal
![Screenshot: Terminal screen](resources/images/screen_terminal.png)

Die Bildschirmseite 'Terminal' kann genutzt werden, um interaktiv Kommandos abzusetzen (selbst während der
Ausführung von Installationsschritten).

## Bildschirmseite: Hilfe
![Screenshot: Help screen](resources/images/screen_help.png)

Nun ja... hier ist sie.

