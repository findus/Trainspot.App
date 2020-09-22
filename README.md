# Trainspot.App

Visualizes the approximate location of trains that are departing and arriving at a specific train station and displays additional information like delay, next stop and a representation of the driven track.

<img src="https://raw.githubusercontent.com/findus/x/master/Picture1.png" width="250"> <img src="https://raw.githubusercontent.com/findus/x/master/Picture2.png" width="250">

## Dies ist eine kleine Demo Application, die Fahrplandaten grafisch aufbereitet.

## Features:

Der Fahrtverlauf von Zügen, die vom ausgewählten Bahnhof abfahren, oder ankommen wird auf einer Map angezeigt.
Aus den Fahrplandaten wird eine ungefähre Position der Züge abgeleitet, welche dann sekündlich auf der Map aktualisiert wird.

Aus aktueller User-Position und einem gewählten Zug berechnet die App zu welchem Zeitpunkt der Zug an der User-Position vorbeifahren sollte.

Zusätzlich zeigt die App auch folgende Infos an:
- Die Liniennummer
- Status: (Hält, Fährt, Startet in x Minuten)
- Verspätung
- Letzter Halt
- Nächster Halt
- Entfernung zum User in Kilometern (gemessen an der Trassenlänge)
- Vorraussichtliche Ankunftszeit beim User in Sekunden
- Vom aktuell ausgewählten Zug werden minütlich die Fahrplandaten aktualisiert, um stehts aktuelle Verspätungsdaten verfügbar zu haben

# Einstellungen:

In der App lassen sich folgende Einstellungen anpassen:

## -  Entfernung zum Bahnhof
  - Versucht Züge zu entfernen, die schon laut Fahrplan am User vorbei gefahren sind
    - Beispiel: User steht 5 Minuten vom Hauptbahnhof entfernt, und in 2 Minuten fährt ein ICE ein. Dieser ist warscheinlich schon vorbei gefahren und kann somit ausgeblendet werden.
  
## - Maximale Distanz zur Bahnstrecke
  - Entfernt Züge, deren zu befahrene Trasse zu weit vom User entfernt liegen, z.B. von Regionallinien, die in die andere Richtung abfahren

## - Manuelle Positionsbestimmung
  - Schaltet Apples Userlocation-Service aus, und ermöglicht dem User seine Position manuell zu setzen.
  - Diese funktion ist als Fallback aktiv, wenn Apples Location-Diense inaktiv sind, oder der Nutzer dies der App explizit verboten hat.

# Geplante Features:
- Simulation der Beschleunigung und Bremswege der Züge, um etwas genauere Positionangaben zu ermitteln
- Behalte Züge bei Refresh
  - Löscht Züge nicht, die beim neuen Fahrplan-Fetch nicht mehr dabei sind
