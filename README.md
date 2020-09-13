# Train Location Visualizer

Visualizes the approximate location of trains that are departing and arriving at a specific train station and displays additional information like delay, next stop and path.

<img src="https://raw.githubusercontent.com/findus/x/master/Picture1.png" width="250"> <img src="https://raw.githubusercontent.com/findus/x/master/Picture2.png" width="250">

Dies ist eine kleine Demo Application, die Fahrplandaten grafisch aufbereitet.

Der Fahrtverlauf von Zügen, die vom ausgewählten Bahnhof abfahren, oder ankommen wird auf einer Map angezeigt.
Aus den Fahrplandaten wird eine ungefähre Position der Züge abgeleitet, welche dann sekündlich auf der Map aktualisiert wird.

Aus aktueller User-Position und einem gewählten Zug berechnet die App, zu welchem Zeitpunkt der Zug an der User-Position vorbeifahren sollte.

Zusätzlich zeigt die App auch folgende Infos an:
- Die Liniennummer
- Status: (Hält, Fährt, Startet in x Minuten)
- Verspätung
- Letzter Halt
- Nächster Halt
- Entfernung zum User in Kilometern
- Vorraussichtliche Ankunftszeit beim User in Sekunden

Settings:

- Entfernung zum Bahnhof
  - Versucht Züge zu entfernen, die schon laut Fahrplan am User vorbei gefahren sind
  
- Maximale Distanz zur Bahnstrecke
  - Entfernt Züge, deren Trasse zu weit vom User entfernt liegen, z.B. von Regionallinien, die in die andere Richtung fahren
  
 - Behalte Züge bei Refresh (noch nicht implementiert)
  - Löscht Züge nicht, die beim neuen Fahrplan-Fetch nicht mehr dabei sind
 
 - Manuelle Positionsbestimmung
  - Schaltet Apples Userlocatin-Service aus, und ermöglicht dem User seine Position manuell zu setzen, fallback wenn Locationdiense inaktiv sind, oder der Nutzer dies der App Verboten hat.
