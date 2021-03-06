import QtQuick 2.0

/*
 * Questo component contiene tutta la parte destra della schermata
 */
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


    /**************************************************************
     * Signal emessi verso l'esterno
     **************************************************************/

    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()

    /* Questo signal indica che è stata premuta una nuova scarpa e che bisogna creare una nuova view che la visualizzi;
     * passa come parametro l'id della scarpa toccata e il riferimento alla FlipableSurface che corrisponde alla scarpa
     * selezionata (è una copia visiva della list entry selezionata) */
    signal needShoeIntoContext(int id, variant shoeSelectedFlipable)



    height: parent.height
    width: 600 * scaleX


    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShoeImagesList che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: container.touchEventOccurred()
    }


    //Font da usare per le scritte
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
            height: 170 * scaleY
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
             * di SimilarShoesList (per dire, la y avrebbe un valore inferiore perchè non terrebbe conto del titolo che c'è in alto).
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

        //Quando il flipable diventa visibile faccio scomparire l'highlightRectangle che era apparso nel mentre sopra l'oggetto
        //della lista che il flipable sostituisce (l'highlightRectangle compare solo se ci vuole un po' a caricare la scarpa)
        onVisibleChanged: {
            if(visible)
                highlightRectangle.opacity = 0
        }
    }


    //Rettangolo che contie tutta la lista
    Rectangle {
        id: listContainer
        anchors.top: separator.bottom
        height: parent.height - (title.height + separator.height) - 30 * scaleY
        width: parent.width


        //MouseArea che ha il solo scopo di avvisare quando avvengono touch events
        MouseArea {
            anchors.fill: parent
            onClicked: container.touchEventOccurred()
        }





        //Testo da mostrare al posto della lista quando è vuota (non sono state trovate scarpe simili per questa scarpa)
        Text {
            //La scritta è visibile solo la lista è vuota
            visible: similarList.count == 0

            text: "Nessuna scarpa simile trovata"

            font.family: metroFont.name
            font.pointSize: 15
            font.letterSpacing: 1.3
            font.weight: Font.Bold

            color: "black"

            anchors.centerIn: parent
        }

        //Abilito lo scorrimento della lista solo se è permesso fare click (la proprietà isClickAllowed è esterna, ricevuta
        //dalla ShoeView in cui sta' questo component)
        enabled: isClickAllowed

        ListView {
            id: similarList

            //Dato che l'altezza data da similarList.height non rappresenta la vera altezza della lista calcolata in base
            //al numero di elementi, la calcolo manualmente
            property real actualHeight: similarList.count * (similarList.delegateHeight + similarList.spacing)

            //Dimensioni degli item della lista
            property real delegateWidth: similarList.width
            property real delegateHeight: 170 * scaleY


            //La lista è grande quanto tutto il container
            anchors.fill: listContainer
            anchors.rightMargin: verticalScrollBar.width + (1 * scaleX)

            //Attivo lo scrolling della lista supera la larghezza del suo container
            boundsBehavior: actualHeight < listContainer.width ? Flickable.StopAtBounds : Flickable.DragOverBounds

            //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
            //contenente le thumbnail
            model: similiarShoesModel

            clip: true


            //Il delegate usa un component creato ad hoc
            delegate: SimilarShoesDelegate {
                id: suggestionContainer

                height: similarList.delegateHeight
                width: similarList.delegateWidth
                textFont: metroFont
                color: container.backgroundColor

                //Setto le varie proprietà della scarpa in questione
                thumbnailSource: modelData.thumbnail
                modelText: modelData.model
                brandText: modelData.brand
                priceText: modelData.price


                //Al click bisogna apire la nuova schermata con la scarpa clickata
                MouseArea {
                    anchors.fill: parent;

                    onClicked: {
                        /* Procedo con la creazione della nuova schermata solo se i click utente sono abilitati; non lo sono durante
                         * le transizioni tra una schermata e l'altra, quindi dopo l'esecuzione del codice che segue
                         * non sarà possibile premere su un'altra scarpa fino a quando la transizione non termina */
                        if(isClickAllowed){

                            //Notifico l'esterno che è avvenuto un click
                            container.touchEventOccurred();

                            //Sposto la lista in modo che si veda l'elemento, in modo che se fosse stata premuta un'entry
                            //parzialmente visibile adesso si veda del tutto
                            similarList.positionViewAtIndex(index, ListView.Contain)


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

                            //Emitto quindi il signal che avverte che c'è bisogno di caricare una nuova scarpa, passando anche
                            //il flipable come parametro in modo che possa essere usato in ShoeView
                            container.needShoeIntoContext(modelData.id, shoeSelectedFlipable)


                            /* Bisogna fare un'ultima cosa, far apparire l'highlightRectangle sopra l'elemento premuto. Per farlo
                             * però occorre ottenere le coordinate locali dell'elemento in rispetto a tutta la SimilarShoesList
                             * (il procedimento è simile a quello della funzione createCopy() della flipableSurface) */
                            var localCoordinates = suggestionContainer.mapToItem(container, 0, 0)

                            //Prese le coordinate, setto la posizione in base a quella dell'elemento, tornando però indietro
                            //di alcuni pixel per lasciare più spazio tra il bordo e l'inizio delle scritte del delegate
                            highlightRectangle.x = localCoordinates.x - 10 * scaleX

                            //Adesso devo settare la y. Per via dello spacing tra gli elementi, che è assente nel primo, bisogna
                            //settare una y diversa se l'elemento premuto è il primo della lista
                            if(index == 0)
                            {
                                //Nel primo elemento non c'è spacing, quindi setto la y così come l'ho calcolata (togliendo 1 pixel
                                //per far si che il bordo vada sopra il separatore che c'è sopra la lista)
                                highlightRectangle.y = localCoordinates.y - 1 * scaleY

                                //L'altezza allo stesso modo non tiene conto dello spacing, ed è pari a quella dell'elemento della
                                //lista (più un paio di pixel per far si che vada sopra il separatore tra gli item della lista)
                                highlightRectangle.height = suggestionContainer.height + 2 * scaleY
                            }
                            else
                            {
                                //Se altrimenti l'element premuto non è il primo della lista, bisogna considerare lo spacing
                                //quando si mettono le coordinate e l'altezza
                                highlightRectangle.y = localCoordinates.y - similarList.spacing
                                highlightRectangle.height = suggestionContainer.height + similarList.spacing + 1 * scaleY
                            }

                            //Infine rendo visibile l'highlightRectangle mettendo l'opacità a 1, causando un'animazione di fade in
                            highlightRectangle.opacity = 1
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

            orientation: ListView.Vertical
            spacing: 9 * scaleY

            //Quando inizia il movimento della lista da parte dell'utente devo bloccare il timer che fa scomparire la scrollbar
            onMovementStarted: {
                //Eseguo il codice solo se la barra è visibile
                if(verticalScrollBar.visible)
                {
                    //Rimetto l'opacità della barra al valore di default, qualora non fosse già così
                    verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity

                    //Termino il timer, qualora fosse in esecuzione
                    fadeOutTimer.stop()
                }
            }

            //Quando finisce il movimento della lista da parte dell'utente devo mandare in esecuzione il timer
            //che fa scomparire la scrollbar
            onMovementEnded: {
                if(verticalScrollBar.visible)
                    fadeOutTimer.restart()
            }
        }

        //La scrollbar è definita in un file a parte e compare solo se l'altezza della lista supera l'altezza dello schermo
        ScrollBar {
            id: verticalScrollBar
            flickable: similarList
            position: "right"
            handleSize: 6
            listBackgroundColor: listContainer.color

            //La scrollbar è visibile se l'altezza della lista supera l'altezza del suo container
            visible: similarList.actualHeight >= listContainer.height

            onBarClicked: {
                //Rimetto l'opacità della barra al valore di default, qualora non fosse già così
                verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity

                //Termino il timer, qualora fosse in esecuzione
                fadeOutTimer.stop()

                //Notifico l'esterno che è avvenuto un click
                container.touchEventOccurred()
            }

            onBarReleased: {
                if(verticalScrollBar.visible)
                    fadeOutTimer.restart()
            }
        }

        //Timer che si occupa di far sparire la ScrollBar dopo un tot di tempo dal termine dell'input utente
        Timer {
            id: fadeOutTimer
            interval: 2000
            running: true //Faccio partire il timer all'inizio del programma
            repeat: false

            //Quando scatta il timer, porto l'opacità della barra a zero
            onTriggered: verticalScrollBar.barOpacity = 0
        }


        Rectangle {
            id: separatorList
            width: parent.width
            height: 1 * scaleY
            color: "#9FB7BF"
            anchors.top: listContainer.bottom
        }

        //Quando la lista diventa visibile, faccio comparire la scrollbar e riavvio il timer che la fa scomparire; in questo modo
        //quando si torna ad una ShoeView precedentemente visitata, la barra compare subito
        onVisibleChanged: {
            if(visible)
            {
                verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity;
                fadeOutTimer.restart();
            }
        }
    }

    /* Rettangolo che ha solo la cornice e che appare solo quando si preme una scarpa simile e c'è un attesa mentre si
     * caricano i dati. Non è usato l'highlight proprio della ListView in quanto per via dello spacing e della grandzza del
     * delegate della lista uscirebbe male; è meglio infatti creare un rettangolo apposito da spostare all'occorrenza */
    Rectangle {
        id: highlightRectangle

        //Colore che rende invisibile il rettangolo
        color: "#00000000"

        //Nonostante il colore del rettangolo sia invisibile, il bordo si vede comunque
        border.width: 2
        border.color: "#9FB7BF"

        //L'highlightRectangle di fatto è sempre visibile, solo che ha opacità a 0 quando non deve apparire
        opacity: 0

        //La larghezza è pari a quella della lista (pari a quella del delegate) più qualche pixel per coprire più spazio;
        //l'altezza è invece definita in base all'item della lista premuto, in quanto può variare
        width: similarList.width + 9 * scaleX

        radius: 2

        Behavior on opacity {
            NumberAnimation {
                duration: 250

                easing.type: Easing.InOutSine
            }
        }
    }
}
