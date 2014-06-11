import QtQuick 2.0
//import QtGraphicalEffects 1.0

Rectangle {
    id: container

    property real filterPanelWidth: 1920 * scaleX
    property real filterPanelHeight: 300 * scaleY
    property string filterPanelbackgroundColor: "#FA626262"

    property real draggingRectangleWidth: 350 * scaleX
    property real draggingRectangleHeight: 41 * scaleY
    property string draggingRectangleBackgroundColor: "#646464"

    property Rectangle backgroundRectangle

    property string textColor: "#EDEDED"


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

            color: textColor
        }

        Text {
            text: "Filtra Scarpe"            
            font.family: metroFont.name
            font.pointSize: 9
            font.letterSpacing: 1.2

            anchors.bottom: parent.bottom
//          anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: textColor
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


        /* Dato che ci sono gli "smoother" a destra e a sinistra della lista delle scarpe, durante le transizioni quando si preme
         * su una scarpa (e quindi quando flipableSurface diventa visibile per effettuare la transizione) bisogna farli scomparire
         * e poi ricomparire se e quando la schermata torna ad essere mostrata, in modo che l'entry della lista clickata non finisca
         * sopra uno smoother durante la transizione al contrario (in tal caso finirebbe sopra lo smoothere poi subito sotto
         * all'improvviso, rendendo l'aspetto visivo per niente "smooth") */
        onVisibleChanged: {
            //Se la flipableSurface diventa visibile, e la lista non era all'inizio (e quindi il leftSmoother è visibile),
            //nascondo lo smoother
            if(visible && !filteredList.atXBeginning)
                leftSmoother.opacity = 0
            /* Se quando la transizione è terminata (e quindi la flipableSurface non è più visibile) la lista non si trova
             * all'inizio, e quindi il leftSmoother prima era visibile, devo farlo ricomparire. Non basta mettere l'opacità a 1
             * perchè il binding che lo faceva apparire/scomparire quando ci si spostava nella lista (definito al momento
             * della dichiarazione dello smoother) si era rotto quando gli era stata messa l'opacità a 0.
             * Quindi, invece di settare l'opacità a 1, ripristino il binding con la funzione apposita, in modo che d'ora in avanti
             * continui a lavorare correttamente come stava facendo prima della transizione */
            else if(!visible && !filteredList.atXBeginning)
                leftSmoother.opacity = Qt.binding(function() { return filteredList.atXBeginning ? 0 : 1 })

            //Stesso discorso di sopra per il rightSmoother
            if(visible && !filteredList.atXEnd)
                rightSmoother.opacity = 0
            else if(!visible && !filteredList.atXEnd)
                rightSmoother.opacity = Qt.binding(function() { return filteredList.atXEnd ? 0 : 1 })
        }

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

        FilterList {
            id: brandsFilterList

            title: "Marca"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: filterPanel.left
            anchors.leftMargin: 20 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: allBrandsModel
            backgroundColor: filterPanel.color
        }

        FilterList {
            id: categoryFilterList

            title: "Categoria"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: brandsFilterList.right
            anchors.leftMargin: 50 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: allCategoriesModel
            backgroundColor: filterPanel.color
        }

        FilterList {
            id: colorFilterList

            title: "Colore"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: categoryFilterList.right
            anchors.leftMargin: 50 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: allColorsModel
            backgroundColor: filterPanel.color
        }

        FilterList {
            id: sizeFilterList

            title: "Taglia"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: colorFilterList.right
            anchors.leftMargin: 50 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: allSizesModel
            backgroundColor: filterPanel.color
        }


        FilterList {
            id: sexFilterList

            title: "Sesso"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: sizeFilterList.right
            anchors.leftMargin: 50 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: ListModel {
                ListElement {
                    name: "Uomo"
                }

                ListElement {
                    name: "Donna"
                }
            }

            backgroundColor: filterPanel.color
        }



        //Slider per scegliere il range del prezzo. Visivamente rappresenta il rettangolo più chiaro che c'è sotto lo slider
        Rectangle {
            id: priceRangeSliderContainer

            visible: true

            width: 230 * scaleX
            height: 10 * scaleY

    //        x: 100 * scaleX
    //        y: 100 * scaleY

            anchors.verticalCenter: sexFilterList.verticalCenter
            anchors.left: sexFilterList.right
            anchors.leftMargin: 150 * scaleX

            //Colore più chiaro
            color: "#d9d1d1"


            //Mouse area per far spostare il dot più vicino alla zona clickata quando si preme sulla parte parte dello slider più chiara
            MouseArea {
                anchors.fill: parent

                onPressed: {
                    /* Le coordinate arrivano ad una grandezza massima pari alla lunghezza del container; dato che anche i dot sono
                     * inseriti dentro il container, le loro coordinate sono date in base adesso. Di conseguenza è possibile
                     * comparare direttamente la coordinata clickata con la posizione dei dot per capire quale è il dot più vicino.
                     * Se la coordinata del mouse è maggiore della posizione del dot di destra, vuol dire che si è premuto alla sua
                     * destra, e quindi il dot più vicino è quello destro; nel caso, sposto il pallino nel punto clickato (meno
                     * la larghezza del pallino a metà per centrare il pallino dove si è clickato).
                     * Altrimenti, è stato premuto a sinistra del dot di sinistra, quindi sposto quello */
                    if(mouse.x > rightDot.x)
                        rightDot.x = mouse.x - rightDot.width/2
                    else
                        leftDot.x = mouse.x - rightDot.width/2
                }
            }


            //Rettangolo tra i due dot; cambia forma in base a come si spostano i dot
            Rectangle {
                id: rectangleBetweenDots

                //Inizialmente ha le stesse dimensioni del container principale
                width: priceRangeSliderContainer.width
                height: priceRangeSliderContainer.height


                //Colore più scuro
                color: "#99807a7a"

                //Mouse area per far spostare il dot più vicino alla zona clickata quando si preme sul rettangolo
                MouseArea {
                    anchors.fill: parent

                    onPressed: {
                        var offset = (mouse.x + leftDot.x - leftDot.width/2)

                        /* Dato che la larghezza del rettangolo tra i dot cambia forma, ed in particolare cambia posizione quando
                         * si sposta il dot di sinistra, le coordinate del mouse date non sono mai fisse e non sono nel range
                         * che va da 0 alla larghezza totale dello slider, come accadeva per il container. Di conseguenza, per capire
                         * quale è il dot più vicino al punto clickato è necessario riportare le misure in modo assoluto.
                         * La variabile offset contiene la coordinata del mouse riportata in piano assoluto, quindi direttamente
                         * confrontabile con le coordinate dei due dot */
                        if(rightDot.x - offset > offset - leftDot.x)
                            leftDot.x = offset
                        else
                            rightDot.x = offset
                    }
                }
            }

            //Dot di sinistra
            Rectangle {
                id: leftDot

                width: 20 * scaleX
                height: 20 * scaleY

                //Sposto un po' il dot in negativo inizialmente in modo che sia un po' fuori dal rettangolo
                x: -rightDot.width/2
                y: -5 * scaleY

                radius: 20

                color: "#3e3e3e"

                //MouseArea per abilitare il dragging
                MouseArea {
                    anchors.fill: parent

                    drag.target: leftDot
                    drag.axis: Drag.XAxis

                    //I limiti del drag sono a sinistra quello che sarebbe lo 0 del dot, a destra il dot di sinistra
                    drag.minimumX: -rightDot.width/2
                    drag.maximumX: rightDot.x

                    onPressed:{
                        leftDot.z = 1
                        rightDot.z = 0
                    }
                }

                //Quando si sposta il dot bisogna cambiare la grandezza del rettangolo tra i due dot, in modo che parta
                //sempre dal left dot
                onXChanged: {
                    /* Il piano di coordinate tra il rettangolo e il dot è lo stesso, ed il range va da 0 fino alla lunghezza massima
                     * dello slider. Quando sposto il leftDot quindi sposto anche il punto di partenza del rettangolo che sta' in mezzo
                     * in modo che lo segue */
                    rectangleBetweenDots.x = x

                    //Cambio poi la lunghezza del rettangolo, tenendo conto che il dot di destra può essere spostato. Se il dot
                    //di destra è fermo nell'estremo destro, (priceRangeSliderContainer.width - rightDot.x) vale zero
                    rectangleBetweenDots.width = priceRangeSliderContainer.width - x - (priceRangeSliderContainer.width - rightDot.x)
                    leftPrice.text = Math.round((priceRangeModel[0] * leftDot.x) / (-rightDot.width/2))


                }

                Text {
                    id: leftPrice
                    text: priceRangeModel[0]
                    anchors.bottom: leftDot.top
                    color: "white"
                }
            }

            //Dot di destra
            Rectangle {
                id: rightDot

                width: 20 * scaleX
                height: 20 * scaleY

                //Sposto un po' il dot inizialmente in modo che sia un po' fuori dal rettangolo verso destra
                x: priceRangeSliderContainer.width - rightDot.width/2
                y: -5 * scaleY

                radius: 20

                color: "#3e3e3e"

                MouseArea {
                    anchors.fill: parent

                    drag.target: rightDot
                    drag.axis: Drag.XAxis
                    drag.maximumX: priceRangeSliderContainer.width - rightDot.width/2
                    drag.minimumX: leftDot.x

                    onPressed:{
                        leftDot.z = 0
                        rightDot.z = 1
                    }
                }

                //Quando si sposta il dot, bisogna cambiare la larghezza del rettangolo al centro in modo che sia uguale alla
                //posizione del dot di destra, tenendo conto che il left dot può essere spostato e quindi anche il rettangolo
                onXChanged: {
                    rectangleBetweenDots.width = x - rectangleBetweenDots.x
                    rightPrice.text = Math.round((priceRangeModel[1] * rightDot.x) / (priceRangeSliderContainer.width / 2))
                }

                Text {
                    id: rightPrice
                    text: priceRangeModel[1]
                    anchors.bottom: rightDot.top
                    color: "white"
                }
            }
        }









        Rectangle {
            id: listContainer
            anchors.horizontalCenter: filterPanel.horizontalCenter
            anchors.bottom: filterPanel.bottom
            anchors.bottomMargin: 50 * scaleY
            width: filterPanel.width
            height: 150 * scaleY

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

//        Text {
//            id: filteredShoesTitle

//            text: "Scarpe Filtrate"
//            font.family: metroFont.name
//            font.pointSize: 21
//            font.letterSpacing: 1.3
//            font.weight: Font.Bold
//            color: "#EDEDED"

//            anchors.bottom: listContainer.top
//            anchors.bottomMargin: 34 * scaleY
//            anchors.horizontalCenter: listContainer.horizontalCenter
//        }

        Rectangle {
            id: titleUnderline

            height: 1 * scaleY
            width: listContainer.width
//            anchors.bottom: filteredShoesTitle.bottom
//            anchors.bottomMargin: - (15 * scaleY)
            anchors.bottom: listContainer.top
            anchors.bottomMargin: 10 * scaleY
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
