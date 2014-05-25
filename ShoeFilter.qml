import QtQuick 2.0
//import QtGraphicalEffects 1.0

Rectangle {
    id: container

    property real filterPanelWidth: 1920 * scaleX
    property real filterPanelHeight: 330 * scaleY
    property string filterPanelbackgroundColor: "#FA626262"

    property real draggingRectangleWidth: 350 * scaleX
    property real draggingRectangleHeight: 41 * scaleY
    property string draggingRectangleBackgroundColor: "#646464"

    property Rectangle backgroundRectangle


    //Booleano per indicare se il pannello è aperto o no
    property bool isOpen: false


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



    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShoeImagesList che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: container.touchEventOccurred()
    }

    FontLoader { id: metroFont; source: "qrc:segeo-wp.ttf" }

    Rectangle {
        id: draggingRectangle

        width: draggingRectangleWidth
        height: draggingRectangleHeight

        color: draggingRectangleBackgroundColor
        radius: 6

        anchors.bottom: container.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Behavior on y {
            NumberAnimation {
                easing.type: Easing.OutSine
                duration: 150
            }
        }

        Rectangle {
            anchors.bottom: draggingRectangle.bottom
            width: parent.width
            height: 10 * scaleY
            color: draggingRectangle.color
        }

        Text {
            id: arrow
            text: "«"
            font.family: metroFont.name
            font.pointSize: 16

            rotation: 90
            anchors.top: parent.top
            anchors.topMargin: -9 * scaleY
            anchors.horizontalCenter: parent.horizontalCenter

            color: filteredShoesTitle.color
        }

        Text {
            text: "Filtra Scarpe"            
            font.family: metroFont.name
            font.pointSize: 9
            font.letterSpacing: 1.2

            anchors.bottom: parent.bottom
//          anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: filteredShoesTitle.color
        }



        onYChanged:  {
            //L'opacità varia in base alla y del mouse, dopo la pressione
//            backgroundRectangle.opacity = Math.abs((draggingRectangle.y / filterPanelHeight)/(7))
            backgroundRectangle.opacity = 0
        }


        MouseArea {
            id: clickableArea

            //Booleano per indicare se si sta trascinando il rettangolo quando lo si è premuto, oppure se si è solo clickato
            //su di esso senza trascinarlo e poi si è staccato il dito dallo schermo
            property bool hasMoved: false;

            //Coordinata iniziale del mouse durante un evento di dragging
            property int startY;

            //Posizione iniziale del rettangolo durante un evento di dragging
            property int startingRectangleY;

            //Coordinata y precedente durante le fasi di dragging; cambia seguendo il dito
            property int previousY;


            anchors.fill: draggingRectangle


            drag.target: draggingRectangle
            drag.axis: Drag.YAxis
            drag.maximumY: -draggingRectangle.height
            drag.minimumY: -filterPanelHeight

            onPressed: {
                //Salvo la coordinata iniziale del mouse...
                startY = mouse.y

                //...e la posizione iniziale del rettangolo
                startingRectangleY = draggingRectangle.y

                draggingRectangle.anchors.bottom = undefined

                backgroundRectangle.visible = true

                if(previousY == - Math.floor(draggingRectangle.height))
                    backgroundRectangle.opacity = 0

                //Segnalo che è avvenuto un evento touch
                container.touchEventOccurred()
            }

            //Per gestire il dragging e aprire/chiudere il pannello correttamente, salvo la y della MouseArea ogni volta che cambia
            //mentre si sta premendo il rettangolo; in questo modo posso poi capire in che direzione si stava trascinando il rettangolo
            onMouseYChanged: {
                previousY = mouse.y

                /* Se non ci si era ancora mossi e la y iniziale è diversa da quella attuale, vuol dire che adesso ci si è spostati
                 * e quindi lo segnalo; serve per capire quando si fa un click senza dragging sul rettangolo; in tal caso infatti
                 * scatterebbe lo stesso onMouseYChanged anche se di fatto la y non è cambiata; c'è bisogno quindi di un booleano
                 * per capire quando quella situazione avviene */
                if(!hasMoved && startY != previousY)
                    hasMoved = true
            }

            //Quando si rilascia il dito è il momento in cui si decide se aprire o chiudere il pannello
            onReleased: {
                /* Caso in cui si clicka sul rettangolo una sola volta, senza trascinare. Questo accade quando la y precedente
                 * è uguale a quella attuale, mentre non ci si è ancora mossi (è importante che non ci si sia ancora mossi, in
                 * quanto si potrebbe trascinare il dito per poi tornare ad una posizione "ferma" e che farebbe scattare questa
                 * if anche se non dovrebbe) */
                if(previousY == mouse.y && !hasMoved)
                {
                    //Al click, se il pannello era aperto, lo chiudo; altrimenti lo apro
                    if(isOpen)
                        closePanel()
                    else
                        openPanel()

                    //Termino qua la funzione, avendo trovato a cosa corrispondeva l'evento
                    return;
                }


                /* Caso in cui il rettangolo è stato trascinato un po' e poi è ritornato alla posizione di partenza; in tal caso,
                 * bisogna riportare tutto alla posizione iniziale e non fare altro. Questo evento accade quando la posizione
                 * del rettangolo attuale è uguale a quella che aveva inizialmente e ci si è mossi */
                if(draggingRectangle.y == startingRectangleY && hasMoved)
                {
                    //Se il pannello era aperto, lo riapro (in realtà appunto era già aperto, ma chiamando la funzione
                    //mi assicuro che vengano fatte le cose che servono quando il pannello è aperto); viceversa se era chiuso
                    if(isOpen)
                        openPanel()
                    else
                        closePanel()

                    //Termino qua la funzione, avendo trovato a cosa corrispondeva l'evento
                    return;
                }

                /* Caso in cui il rettangolo è stato trascinato un po' e poi il dito è stato rilasciato mentre era in movimento.
                 * In questo caso, controllo l'ultima y salvata con quella attuale: se era minore, vuol dire che si stava
                 * trascinando il rettangolo verso l'alto, e quindi lo apro; altrimenti è il contrario, e quindi lo chiudo */
                if(previousY <= mouse.y)
                    openPanel()
                else
                    closePanel()
            }
        }
    }



    /* Questa FlipableSurface è usata per mostrare la transizione di flipping quando si seleziona una scarpa. Il funzionamento
     * è analogo a quello usato in SimiliarShoesList.qml, quindi i commenti dei dettagli sono lasciati la */
    FlipableSurface {
        id: flipableSurface

        visible: false

        front: SimilarShoesDelegate {
            id: delegateCopy

            //Inizialmente setto solo dei valori costanti, indipendenti dalla scarpa e uguali per ogni entry della lista
            height: filteredList.height - (2 * scaleY)
            width: 350 * scaleX
            textFont: metroFont

            filtered: true
        }


//        onVisibleChanged: {
//            if(visible && !filteredList.atXBeginning)
//                leftSmoother.opacity = 0
//            else if(!visible && !filteredList.atXBeginning)
//                leftSmoother.opacity = 1

//            if(visible && !filteredList.atXEnd)
//                rightSmoother.opacity = 0
//            else if(!visible && !filteredList.atXEnd)
//                rightSmoother.opacity = 1

//            leftSmoother.opacity = Qt.binding(function() { return filteredList.atXBeginning ? 0 : 1 })
//            rightSmoother.opacity = Qt.binding(function() { return filteredList.atXEnd ? 0 : 1 })
//        }

        function createCopy(toCopy)
        {
            delegateCopy.color = toCopy.color

            delegateCopy.thumbnailSource = toCopy.thumbnailSource
            delegateCopy.modelText = toCopy.modelText
            delegateCopy.brandText = toCopy.brandText
            delegateCopy.priceText = toCopy.priceText

            var localCoordinates = toCopy.mapToItem(container, 0, 0)

            flipableSurface.x = localCoordinates.x
            flipableSurface.y = localCoordinates.y

            return flipableSurface;
        }
    }

    Rectangle {
        id: filterPanel

        width: filterPanelWidth
        height: filterPanelHeight

//        x: 100
//        y: 100

        color: filterPanelbackgroundColor

        anchors.top: draggingRectangle.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Rectangle {
            id: listContainer
            anchors.right: filterPanel.right
            anchors.bottom: filterPanel.bottom
            anchors.bottomMargin: 50 * scaleY
            width: 1150 * scaleX
            height: 180 * scaleY

            color: "#00000000"

            ListView {
                id: filteredList

                property int counter: 0;

                //La lista è grande quanto tutto il container
                anchors.fill: listContainer

                enabled: isClickAllowed

                //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
                //contenente le thumbnail
                model: similiarShoesModel

                clip: true

                //Il delegate usa un component creato ad hoc
                delegate: SimilarShoesDelegate {
                    id: filteredContainer

                    height: filteredList.height - (2 * scaleY)
                    width: 350 * scaleX
                    textFont: metroFont

                    //Setto le varie proprietà della scarpa in questione
                    thumbnailSource: modelData.thumbnail
                    modelText: modelData.model
                    brandText: modelData.brand
                    priceText: modelData.price

                    filtered: true

                    //Al click bisogna apire la nuova schermata con la scarpa clickata. Il funzionamento è analogo a quanto accade
                    //in SimiliarShoesList.qml, quindi i commenti riguardo i dettagli sono lasciati la
                    MouseArea {
                        anchors.fill: parent;

                        onClicked: {
                            if(isClickAllowed) {

                                container.touchEventOccurred();

                                filteredList.positionViewAtIndex(index, ListView.Contain)


                                var shoeSelectedFlipable = flipableSurface.createCopy(filteredContainer)

                                shoeSelectedFlipable.frontListItem = filteredContainer

                                shoeSelectedFlipable.parent = container

                                container.needShoeIntoContext(modelData.id, shoeSelectedFlipable)


                                /// Sezione Timer ///
                                //Cambio l'indice della lista; automaticamente verrà cambiata anche la mainImage
                                filteredList.currentIndex = index
                            }
                        }
                    }
                }

                orientation: ListView.Horizontal
                spacing: 9 * scaleX


    //            //Quando inizia il movimento della lista da parte dell'utente devo bloccare il timer che fa scomparire la scrollbar
    //            onMovementStarted: {
    //                //Eseguo il codice solo se la barra è visibile
    //                if(verticalScrollBar.visible)
    //                {
    //                    //Rimetto l'opacità della barra al valore di default, qualora non fosse già così
    //                    verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity

    //                    //Termino il timer, qualora fosse in esecuzione
    //                    fadeOutTimer.stop()
    //                }
    //            }

    //            //Quando finisce il movimento della lista da parte dell'utente devo mandare in esecuzione il timer
    //            //che fa scomparire la scrollbar
    //            onMovementEnded: {
    //                if(verticalScrollBar.visible)
    //                    fadeOutTimer.restart()
    //            }
            }
        }


        Rectangle {
            id: leftSmoother
            width: filteredList.height
            height: filteredList.height

            anchors.left: listContainer.left
            anchors.verticalCenter: listContainer.verticalCenter
            rotation: -90
            opacity: filteredList.atXBeginning ? 0 : 1

            gradient: Gradient {
                     GradientStop { position: 0.0; color: filterPanel.color }
                     GradientStop { position: 1.0; color: "#00000000" }
                 }

            Behavior on opacity {
                NumberAnimation {
                    duration: 600;
                    easing.type: Easing.OutQuad
                }
            }
        }

        Rectangle {
            id: rightSmoother
            width: filteredList.height
            height: filteredList.height

            anchors.right: listContainer.right
            anchors.verticalCenter: listContainer.verticalCenter
            rotation: 90
            opacity: filteredList.atXEnd ? 0 : 1

            gradient: Gradient {
                     GradientStop { position: 0.0; color: filterPanel.color }
                     GradientStop { position: 1.0; color: "#00000000" }
                 }

            Behavior on opacity {
                NumberAnimation {
                    duration: 600;
                    easing.type: Easing.OutQuad
                }
            }
        }

        Text {
            id: filteredShoesTitle

            text: "Scarpe Filtrate"
            font.family: metroFont.name
            font.pointSize: 24
            font.letterSpacing: 1.3
            font.weight: Font.Bold
            color: "#EDEDED"

            anchors.bottom: listContainer.top
            anchors.bottomMargin: 34 * scaleY
            anchors.horizontalCenter: listContainer.horizontalCenter
        }

        Rectangle {
            id: titleUnderline

            height: 2 * scaleY
            width: listContainer.width
            anchors.bottom: filteredShoesTitle.bottom
            anchors.bottomMargin: - (15 * scaleY)
            anchors.horizontalCenter: listContainer.horizontalCenter

            color: filteredShoesTitle.color
        }
    }


    /* Funzione che effettua il necessario per aprire il pannello dei filtri */
    function openPanel()
    {
        arrow.text = "»"
        draggingRectangle.y = 0 - filterPanelHeight

        //Dichiaro che ora il pannello è aperto
        isOpen = true

        //Riporto su false il booleano che serve per decifrare gli eventi della MouseArea, in modo che sia pronto all'uso in seguito
        clickableArea.hasMoved = false
    }

    /* Funzione che effettua il necessario per chiudere il pannello dei filtri; è usata anche dall'esterno in ShoeView */
    function closePanel()
    {
        arrow.text = "«"
        draggingRectangle.y = -draggingRectangle.height

        //Faccio scomparire il rettangolo sullo sfondo
        backgroundRectangle.visible = false
        backgroundRectangle.opacity = 0

        //Dichiaro che ora il pannello è chiuso
        isOpen = false

        //Riporto su false il booleano che serve per decifrare gli eventi della MouseArea, in modo che sia pronto all'uso in seguito
        clickableArea.hasMoved = false
    }
}
