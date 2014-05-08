import QtQuick 2.0

/*
 * Questo component rappresenta l'oggetto che mostra la taglia di una scarpa; questi oggetti sono creati
 * dinamicamente in ShowDetail.qml. Il component ha 2 stati: quello di default è usato quando la data taglia
 * è disponibile in negozio; un altro, creato esplicitamente, è usato quando la data taglia non è disponibile
 */
Rectangle {
    id: container

    //Creo una proprietà "text" visibile dall'esterno che modifichi la proprietà del Text; senza questo non si potrebbe
    //modificare il testo dall'esterno
    property alias text: size.text

    //String che rappresenta il nome dello stato del component quando la data taglia non è disponibile in negozio
    property string unavailable: "unavailable"

    width: 75 * scaleX
    height: 60 * scaleY

    color: "#DEDEDE"

    radius: 5;


    Text {
        id: size
        color: "#333333"
        font.pixelSize: 17
        font.weight: Font.Light
        text: "size not defined"

        anchors.centerIn: parent
    }

    //Creo lo stato che modifichi il colore del component quando la taglia non è disponibile
    states: State {
            name: unavailable

            PropertyChanges {
                target: container
                color: "#F7F7F7"
            }

            PropertyChanges {
                target: size
                color: "#999999"
            }
        }
}
