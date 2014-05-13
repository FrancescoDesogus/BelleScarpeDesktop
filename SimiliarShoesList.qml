import QtQuick 2.0

Rectangle
{
    id: container

    /**************************************************************
     * Costanti usate per definire le grandezze dei vari elementi
     **************************************************************/

    //Dimensioni di ogni thumbnail della lista
    property real listEntryWidth: 230 * scaleX
    property real listEntryHeight: 230 * scaleY
    property real listEntryHalvedHeight: listEntryHeight / 2

    //Larghezza totale della lista (tiene conto della larghezza della scrollbar)
    property real listContainerWidth: (listEntryWidth + 30 * scaleX)


    width: 100
    height: 62


    ListView {
        id: prova2

        //La lista è grande quanto tutto lo schermo, quindi "filla" tutto il parent
        anchors.fill: parent


        /* Segnalo che la lista non deve seguire automaticamente l'elemento attualmente selezionato; senza questo booleano
         * la lista si sposterebbe da sola (moooolto lentamente) verso l'elemento da visualizzare quando la lista diventa
         * inizialmente visibile */
        highlightFollowsCurrentItem: false

        //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
        //contenente le thumbnail
        model: similiarShoesModel

        //Il delegate corrisponde ad una singola immagine per ogni item della lista
        delegate: Component {

            Rectangle {
                x: 300
                y: 300
                width: 100
                height: 100
                color: "red"
                Text {
                    id: t1
                    anchors.centerIn: parent
                    text: modelData.brand
                }

                            Text {
                                anchors.left: t1.right
                //                anchors.centerIn: parent
                                text: modelData.model
                            }

            }
        }

        orientation: ListView.Vertical
    }
}
