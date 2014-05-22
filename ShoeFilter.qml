import QtQuick 2.0
//import QtGraphicalEffects 1.0

Rectangle {
    id: container

    property real filterPanelWidth: 1920 * scaleX
    property real filterPanelHeight: 330 * scaleY
    property string filterPanelbackgroundColor: "#FA626262"

    property real draggingRectangleWidth: 350 * scaleX
    property real draggingRectangleHeight: 41 * scaleY
    property string draggingRectanglebackgroundColor: "#646464"

    property int startY: 0

    property Rectangle backgroundRectangle


    FontLoader { id: metroFont; source: "qrc:segeo-wp.ttf" }

    Rectangle {
        id: draggingRectangle

        width: draggingRectangleWidth
        height: draggingRectangleHeight

        color: draggingRectanglebackgroundColor
        radius: 6

        anchors.bottom: container.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Behavior on y {
            NumberAnimation {
                easing.type: Easing.OutSine
                duration: 150
            }
        }

        onYChanged:  {
            //L'opacità varia in base alla y del mouse, dopo la pressione
            backgroundRectangle.opacity = Math.abs((draggingRectangle.y / filterPanelHeight)/(15))
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

        MouseArea {
            id: clickable
            anchors.fill: draggingRectangle

            drag.target: draggingRectangle
            drag.axis: Drag.YAxis
            drag.maximumY: -draggingRectangle.height
            drag.minimumY: -filterPanelHeight

            onPressed: {
                startY = draggingRectangle.y
                draggingRectangle.anchors.bottom = undefined

                backgroundRectangle.visible = true


                if(startY == - Math.floor(draggingRectangle.height)){
                        backgroundRectangle.opacity = 0
                }
            }

            onReleased: {
                //Accenno il movimento verso il basso
                if(startY == - (Math.floor(filterPanelHeight))){
                    if(startY <= Math.round(draggingRectangle.y) + 1){
                        arrow.text = "«"
                        draggingRectangle.y = -draggingRectangle.height

                        //Faccio scomparire il rettangolo scuro sullo sfondo
                        backgroundRectangle.visible = false
                        backgroundRectangle.opacity = 0
                    }else{
                        arrow.text = "»"
                        draggingRectangle.y = 0 - filterPanelHeight
                    }
                }

                //Accenno il movimento verso l'alto
                if(startY == - (Math.floor(draggingRectangle.height))){
                    if(startY < Math.round(draggingRectangle.y)){
                        //se non ho sollevato il rettangolo, riabbasso il pannello
                        arrow.text = "«"
                        draggingRectangle.y = -draggingRectangle.height

                        //Faccio scomparire il rettangolo scuro sullo sfondo
                        backgroundRectangle.visible = false
                        backgroundRectangle.opacity = 0
                    }else if(startY >= Math.round(draggingRectangle.y)){
                        //Se invece la y iniziale è maggiore di quella attuale (e quindi il rettangolo è più in alto, sollevo il pannello
                        arrow.text = "»"
                        draggingRectangle.y = 0 - filterPanelHeight
                    }
                }
            }
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

    //                //Al click bisogna apire la nuova schermata con la scarpa clickata
    //                MouseArea {
    //                    anchors.fill: parent;

    //                    onClicked: {
    //                        //Procedo con la creazione della nuova schermata solo se non è già stata premuta un'altra scarpa, per evitare
    //                        //la creazione di più schermate insiem
    //                        if(isClickable){

    //                            //Notifico che non è più possibile clickare
    //                            isClickable = false

    //                            //Notifico l'esterno che è avvenuto un click
    //                            container.touchEventOccurred();

    //                            //Sposto la lista in modo che si veda l'elemento, in modo che se fosse stata premuta un'entry
    //                            //parzialmente visibile adesso si veda del tutto
    //                            filteredList.positionViewAtIndex(index, ListView.Contain)


    //                            //Creo una copia dell'entry della lista clickata , in modo che appaia una FlipableSurface al
    //                            //suo posto per la transizione visiva che porta al cambio di schermata
    //                            var shoeSelectedFlipable = flipableSurface.createCopy(filteredContainer)

    //                            //Salvo nel flipable il riferimento all'entry della lista clickata, per farla scomparire/ricomparire
    //                            //quando iniziano/finiscono le transizioni
    //                            shoeSelectedFlipable.frontListItem = filteredContainer

    //                            /* Faccio diventare padre del flipable il container di SimilarShoesList, nel caso non lo fosse già;
    //                             * questo perchè durante la transizione il flipable prende come padre il container di ShoeView, e nel
    //                             * caso in cui si prema su una scarpa e poi si trni indietro, il flipable avrebbe ancora quel padre;
    //                             * bisogna riportare come padre quello originario (il container di SimilarShoesList), altrimenti
    //                             * il flipable apparirebbe per un attimo nella parte sbagliata dello schermo in quanto userebbe
    //                             * un sistema di coordinate diverso da quello che dovrebbe usare */
    //                            shoeSelectedFlipable.parent = container

    //                            //Infine emitto il signal che avverte che c'è bisogno di caricare una nuova scarpa, passando anche
    //                            //il flipable come parametro in modo che possa essere usato in ShoeView
    //                            container.needShoeIntoContext(modelData.id, shoeSelectedFlipable)


    //                            /// Sezione Timer ///
    //                            //Cambio l'indice della lista; automaticamente verrà cambiata anche la mainImage
    //                            filteredList.currentIndex = index
    //                        }
    //                    }

    //                }

    //                Component.onCompleted: {
    //                    filteredContainer.separator.visible = (filteredList.counter != (filteredList.count - 1))
    //                    filteredList.counter++
    //                }

    //                //Se la lista diventa invisible (e quindi tutto il component), riporto al colore di default tutti gli elementi
    //                //della lista; questo è per riportare al colore normale eventuali elementi clickati quando si cambia schermata
    //                onVisibleChanged: {
    //                    if(!visible)
    //                        filteredContainer.color = container.backgroundColor
    //                }
                }

                orientation: ListView.Horizontal
                spacing: 9 * scaleX


    //            /* Per evitare il rischio di un utente che preme mille volte su una scarpa consigliata senza aspettare il termine della
    //             * transizione alla nuova schermata (facendo creare quindi mille view), viene usato un booleano che diventa false e blocca
    //             * la possibilità di aprire nuove schermate una volta premuta una scarpa; per far si però che quando si torni indietro
    //             * in una schermata già vista sia possibile premere di nuovo su una scarpa, bisogna rimettere il booleano su true.
    //             * Visto che il booleano va di pari passo con la visibilità della view, uso questo listener per disattivare/riattivare
    //             * il booleano quando la view cambia visiblità; così facendo quando si rivista una view vecchia, il booleano ritorna true */
    //            onVisibleChanged: {
    //                container.isClickable = container.visible
    //            }

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
}
