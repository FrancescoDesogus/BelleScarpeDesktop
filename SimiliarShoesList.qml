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

    //Colore di background di tutto il component
    property string backgroundColor: "#00000000"

    //Booleano che indica se si può clickare su una scarpa consigliata per cambiare schermata; inizialmente si può, ma una vola
    //clickata una il booleano diventa false per evitare di poter premere molte volte di fila e creare mille schermate
    property bool isClickable: true


    //Questo signal indica che è stata premuta una nuova scarpa e che bisogna creare una nuova view che la visualizzi;
    //passa come parametro l'id della scarpa toccata
    signal needShoeIntoContext(int id)



    height: parent.height
    width: 600 * scaleX
//    color: "red"

    FontLoader {
        id: metroFont;
        source: "qrc:segeo-wp.ttf"
    }

    Text {
        id: title
        text: "Scarpe Simili".toUpperCase()
        font.family: metroFont.name
        font.pointSize: 24
        font.weight: Font.Normal
        font.letterSpacing: 1.2
        color: "#9FB7BF"
//        height: 50 * scaleY
        anchors.left: container.left
        anchors.top: container.top
        anchors.topMargin: 15 * scaleY
    }

    Rectangle {
        id: separator
        width: parent.width
        height: 1 * scaleY
        color: "#9FB7BF"
        anchors.top: title.bottom
        anchors.topMargin: 10 * scaleY
    }

    Rectangle {
        id: listContainer
        anchors.top: separator.bottom
        height: 700 * scaleY
        width: parent.width

        ListView {
            id: similarList

            property int counter: 0;

            //La lista è grande quanto tutto lo schermo, quindi "riempie" tutto il parent
            anchors.fill: listContainer

            /* Segnalo che la lista non deve seguire automaticamente l'elemento attualmente selezionato; senza questo booleano
             * la lista si sposterebbe da sola (moooolto lentamente) verso l'elemento da visualizzare quando la lista diventa
             * inizialmente visibile */
            highlightFollowsCurrentItem: false

            //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
            //contenente le thumbnail
            model: similiarShoesModel

            clip: true

            //Il delegate corrisponde ad una singola immagine per ogni item della lista
            delegate: Component {

                Rectangle {
                    id: suggestionContainer
                    width: similarList.width
                    height: 170 * scaleY
                    color: container.backgroundColor

                    Behavior on color { ColorAnimation { duration: 100 }}

                    Image {
                        id: similarThumbnail
                        antialiasing: true
                        source: modelData.thumbnail
                        width: 150 * scaleX
                        height: 120 * scaleY
                        fillMode: Image.PreserveAspectFit
                        anchors.right: suggestionContainer.right
                        anchors.rightMargin: 5 * scaleX
                        anchors.verticalCenter: suggestionContainer.verticalCenter
                    }

                    Text {
                        id: t1
                        anchors.left: suggestionContainer.left
    //                    anchors.leftMargin: 50 * scaleX
                        font.letterSpacing: 1.2
                        color: "#9FB7BF"
                        text: modelData.brand + " " + modelData.model
                        font.family: metroFont.name
                        font.pointSize: 14
                        font.weight: Font.Light
                    }

                    Text {
                        id: brand
                        anchors.top: t1.bottom
                        anchors.topMargin: 7 * scaleY
                        text: modelData.brand
                        font.family: metroFont.name
                        font.pointSize: 12
                        font.weight: Font.Light
                    }

                    Text {
                        id: model
                        anchors.top: brand.bottom
                        anchors.topMargin: 7 * scaleY
                        text: modelData.model
                        font.family: metroFont.name
                        font.pointSize: 12
                        font.weight: Font.Light
                    }

                    Text {
                        id: price
                        anchors.top: model.bottom
                        anchors.topMargin: 7 * scaleY
                        text: modelData.price
                        font.family: metroFont.name
                        font.pointSize: 12
                        font.weight: Font.Light
                    }

                    Rectangle {
                        id: separator
                        width: parent.width
                        height: 1 * scaleY
                        color: "#9FB7BF"
                        anchors.bottom: suggestionContainer.bottom
//                        visible: (similarList.counter == (similarList.count -1))
                    }

                    Component.onCompleted: {
                        separator.visible = (similarList.counter != (similarList.count -1))
                        similarList.counter++
                    }

                    MouseArea {
                        anchors.fill: parent;


                        onClicked: {
                            if(isClickable){
                                suggestionContainer.color = "#DEDEDE"
                                isClickable = false
                                container.needShoeIntoContext(modelData.id)
                            }
                        }
                    }


                    //Se la lista diventa invisible (e quindi tutto il component), riporto al colore di default tutti gli elementi
                    //della lista; questo è per riportare al colore normale eventuali elementi clickati quando si cambia schermata
                    onVisibleChanged: {
                        if(!visible)
                            suggestionContainer.color = container.backgroundColor
                    }
                }
            }

            orientation: ListView.Vertical
            spacing: 9


            /* Per evitare il rischio di un utente che preme mille volte su una scarpa consigliata senza aspettare il termine della
             * transizione alla nuova schermata (facendo creare quindi mille view), viene usato un booleano che diventa false e blocca
             * la possibilità di aprire nuove schermate una volta premuta una scarpa; per far si però che quando si torni indietro
             * in una schermata già vista sia possibile premere di nuovo su una scarpa, bisogna rimettere il booleano su true.
             * Visto che il booleano va di pari passo con la visibilità della view, uso questo listener per disattivare/riattivare
             * il booleano quando la view cambia visiblità; così facendo quando si rivista una view vecchia, il booleano ritorna true */
            onVisibleChanged: {
                container.isClickable = container.visible
            }
        }

        Rectangle {
            id: separatorList
            width: parent.width
            height: 1 * scaleY
            color: "#9FB7BF"
            anchors.top: listContainer.bottom
//            visible: (!similarList.atYEnd || similarList.moving)
        }

        Image {
            id: qrCode
            anchors.top: separatorList.bottom
            anchors.left: parent.left
            anchors.topMargin: 25 * scaleY
            width: 250 * scaleX
            height: 250 * scaleY
            source: "qrc:///qml/qrcode.png"
    //        anchors.horizontalCenter: parent.horizontalCenter
    //        anchors.left: parent
        }
    }
}
