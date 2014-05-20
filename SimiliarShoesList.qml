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



    /* Questo signal indica che è stata premuta una nuova scarpa e che bisogna creare una nuova view che la visualizzi;
     * passa come parametro l'id della scarpa toccata e il riferimento alla FlipableSurface che corrisponde alla scarpa
     * selezionata (è una copia visiva della list entry selezionata) */
    signal needShoeIntoContext(int id, variant shoeSelectedFlipable)



    height: parent.height
    width: 600 * scaleX

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



    /* Questa FlipableSurface è usata per mostrare la transizione di spinning quando si seleziona una scarpa. Inizialmente l'idea
     * era di rendere ogni entry della lista come FlipableSurface, ma per eseguire la transizione era necessario spostare l'entry
     * e cambiarne il padre, di fatto rimuovendola in un modo non convenzionale dalla lista; questo rendeva impossibile reinserirla
     * nuovamente quando si faceva il reflip. Di conseguenza questa flipableSurface si occupa di "imitare" l'entry selezionata,
     * nel senso che ne diventa una copia visiva per la durata della transizione e "fa finta di essere lei". Quando si seleziona
     * un'altra scarpa, imita quell'altra e così via */
    FlipableSurface {
        id: flipableSurface

        //Di default la flipableSurface non è visibile; diventa tale solo durante le transizioni
        visible: false

        /* Stabilisco come front lo stesso tipo di component che uso nel delegate della lista, solo che inizialmente è vuoto
         * di elementi. Quando si selezionerà una scarpa della lista, sarà questo front a diventare la copia dell'entry clickata,
         * recuperando tutte le informazioni che servono */
        front: SimilarShoesDelegate {
            id: delegateCopy

            //Inizialmente setto solo dei valori costanti, indipendenti dalla scarpa e uguali per ogni entry della lista
            width: similarList.width
            textFont: metroFont
            color: container.backgroundColor
        }


        /* Questa funzione viene chiamata dall'entry della lista clickata, e si occupa di popolare la copia in modo che diventi
         * tale e quale all'entry */
        function createCopy(toCopy)
        {
            //Ne prendo il colore (se è cambiato quando l'entry è stata clickata...
            delegateCopy.color = toCopy.color

            //...e tutte le altre informazioni che cambiano da scarpa a scarpa
            delegateCopy.thumbnailSource = toCopy.thumbnailSource
            delegateCopy.modelText = toCopy.modelText
            delegateCopy.brandText = toCopy.brandText
            delegateCopy.priceText = toCopy.priceText


            /* Adesso devo settare le coordinate del flipable (non tocco quelle di delegateCopy in quanto è incollata al flipable e
             * non serve). Per farlo, recupero le coordinate locali a SimilarShoesList dell'entry della lista con la funzione
             * mapToItem(), in quanto toCopy contiene le coordinate dell'entry rispetto al padre, non rispetto al container
             * di SimilarShoesList (per dire, la y avrebe un valore inferiore perchè non terrebbe conto del titolo che c'è in alto).
             * Serve avere le coordinate locali "giuste" per usare di nuovo il metodo mapToItem() dentro  ShoeView in modo da
             * ottenere le coordinate globali dell'entry della lista. Servono quelle globali in quanto durante le transizioni
             * il flipable prende come padre il container di ShoeView, che è grande appunto tutto lo schermo */
            var localCoordinates = toCopy.mapToItem(container, 0, 0)

            //Recuperate le coordinate locali a tutto il component SimilarShoesList, le assegno al flipable
            flipableSurface.x = localCoordinates.x
            flipableSurface.y = localCoordinates.y

            //Restituisco quindi il flipable, il cui front è adesso una copia visiva dell'entry della lista clickata
            return flipableSurface;
        }
    }


    Rectangle {
        id: listContainer
        anchors.top: separator.bottom
        height: 700 * scaleY
        width: parent.width

        ListView {
            id: similarList

            property int counter: 0;

            //La lista è grande quanto tutto il container
            anchors.fill: listContainer

            //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
            //contenente le thumbnail
            model: similiarShoesModel

            clip: true

            //Il delegate usa un component creato ad hoc
            delegate: SimilarShoesDelegate {
                id: suggestionContainer

                width: similarList.width
                textFont: metroFont
                color: container.backgroundColor

                //Setto le varie proprietà della scarpa in questione
                thumbnailSource: modelData.thumbnail
                modelText: modelData.model
                brandText: modelData.brand
                priceText: modelData.price


                MouseArea {
                    anchors.fill: parent;

                    onClicked: {
                        if(isClickable){
                            suggestionContainer.color = "#DEDEDE"

                            isClickable = false


                            //Creo una copia dell'entry della lista clickata , in modo che appaia una FlipableSurface al
                            //suo posto per la transizione visiva che porta al cambio di schermata
                            var shoeSelectedFlipable = flipableSurface.createCopy(suggestionContainer)

                            //Salvo nel flipable il riferimento all'entry della lista clickata, per farla scomparire/ricomparire
                            //quando iniziano/finiscono le transizioni
                            shoeSelectedFlipable.frontListItem = suggestionContainer

                            /* Faccio diventare padre del flipable il container di SimilarShoesList, nel caso non lo fosse già;
                             * questo perchè durante la transizione il flipable prende come padre il container di ShoeView, e nel
                             * caso in cui si prema su una scarpa e poi si trni indietro, il flipable avrebbe ancora quel padre;
                             * bisogna riportare come padre quello originario (il container di SimilarShoesList), altrimenti
                             * il flipable apparirebbe per un attimo nella parte sbagliata dello schermo in quanto userebbe
                             * un sistema di coordinate diverso da quello che dovrebbe usare */
                            shoeSelectedFlipable.parent = container

                            //Infine emitto il signal che avverte che c'è bisogno di caricare una nuova scarpa, passando anche
                            //il flipable come parametro in modo che possa essere usato in ShoeView
                            container.needShoeIntoContext(modelData.id, shoeSelectedFlipable)
                        }
                    }

                }

                Component.onCompleted: {
                    suggestionContainer.separator.visible = (similarList.counter != (similarList.count -1))
                    similarList.counter++
                }

                //Se la lista diventa invisible (e quindi tutto il component), riporto al colore di default tutti gli elementi
                //della lista; questo è per riportare al colore normale eventuali elementi clickati quando si cambia schermata
                onVisibleChanged: {
                    if(!visible)
                        suggestionContainer.color = container.backgroundColor
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
