import QtQuick 2.0

/* Item che contiene l'indicatore di caricamento, visibile e animato quando si stanno recuperando dati dal database.
 * E' creato come Item perchè così posso renderlo grande quanto tutto il padre (il container della lista) senza
 * che però risulti visibile; questo aiuta per centrare l'indicatore di caricamento nel container della lista.
 * Per rendere visibile l'indicatore è sufficente settare "running" su true */
Item {
    id: loadIndicator

//    anchors.fill: parent

    property bool running: false
    property string imageSource: "qrc:/images/busy.png"

    //Rendo visibile il tutto solo se sta effettivamente caricando
    visible: running

    Image {
        id: image

        anchors.centerIn: parent

        source: loadIndicator.imageSource

        //Animazioni eseguite in parallelo; la prima rende visibile l'indicatore con un fade in, la seconda
        //lo fa ruotare per l'eternità
        ParallelAnimation {
            running: loadIndicator.running

            NumberAnimation { target: image; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            NumberAnimation { target: image; property: "rotation"; from: 0; to: 360; loops: Animation.Infinite; duration: 1200 }
        }
    }
}
