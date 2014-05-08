import QtQuick 2.0

//Contenitore principale della view
Rectangle {
    id: container
    color: "#EEEEEE"

    //Le dimensioni della view sono prese dal padre che usa questo Component, e sono grandi quanto tutto lo schermo
    width: parent.width
    height: parent.height


    /**************************************************************
     * Costanti usate per definire le grandezze dei vari elementi
     **************************************************************/


    //Component contenente la lista delle thumbnail delle immagini e l'immagine attualmente selezionata
    ShoeImagesList {
        id: imagesList

        //Intercetto il signal dichiarato dentro ShoeImagesList; il signal coincide con un tap sulla main image, che deve implicare
        //un focus sull'immagine. Il signal riceve come parametro "imageSource", il path del file dell'immagine
        onMainImageClicked: {
            //Quando il signal scatta, cambio lo stato del rettangolo che oscura lo schermo, setto il path dell'immagine
            //a quello ricevuto dal signal e rendo visibile l'immagine stessa
            mainImageFocusBackground.state = "visible";
//            mainImage.source = imageSource;
//            mainImage.state = "visible";
            imageList.state = "visible"

//            imageList.currentItem = imageList.c
            imageList.positionViewAtIndex(listIndex, ListView.Visible)
            imageList.currentIndex = listIndex

//            imageList.currentItem.source = imageSource
        }
    }

    //Component contenente le informazioni sulla scarpa
    ShoeDetail {
        id: shoeDetail
        anchors.left: imagesList.right
    }


    //Rettangolo che funge da background oscurato per quando si preme su una thumbnail per mostrare l'immagine ingrandita
    Rectangle {
        id: mainImageFocusBackground
        width: parent.width
        height: parent.height
        color: "black"
        state: "invisible" //Stabilisco che lo stato iniziale è invisible, definito più sotto


        //Aggiungo due state, uno per quando è visibile e uno per quando non lo è
        states: [
            //Stato per quando il rettangolo è visibile
            State {
                //Definisco il nome con cui accederò allo stato
                name: "visible"

                //Quando si ha questo stato si attivano i seguenti cambiamenti
                PropertyChanges {
                    //Definisco che il target dei cambiamenti delle proprietà è il rettangolo stesso
                    target: mainImageFocusBackground

                    //Quando lo stato è visibile, rendo effettivamente visibile il rettangolo
                    visible: true
                }
            },

            //Stato per quando il rettangolo è invisibile
            State {
                name: "invisible"

                PropertyChanges {
                    target: mainImageFocusBackground

                    /* Anche in questo caso setto la visibilità su true. Non lo metto invisibile perchè altrimenti quando si passa
                     * da visible a invisible il rettangolo scompare immediatamente senza aspettare la fine dell'animazione; quindi
                     * il rettangolo diventa inivisibile solo al termine dell'animazione.
                     * Dato che all'avvio dell'applicazione il rettangolo deve essere invisibile (non basta mettre l'opacità a 0;
                     * facendo così prenderebbe gli input della MouseArea annessa e non deve accadere; all'avvio deve essere per forza
                     * "visible: false"), se dentro lo stato "inivisible" non mettessi la visibilità su true, quando si passerebbe
                     * da visible a invisible scatterebbe subito il "visible: false" messo all'avvio, e ciò non va bene. Bisogna
                     * quindi continuare a mettere la visibilità su true anche quando lo stato è invisible, e toglierla solo al
                     * termine dell'animazione */
                    visible: true
                }
            }
        ]

        //Per avere un'animazione tra i cambi di stato creo delle transizioni
        transitions: [
            //Transizione per quando si passa dallo stato invisible allo stato visible
            Transition {
                //Inserisco qua il nome dello stato di partenza coinvolto nella transizione e lo stato da raggiungere
                from: "invisible"
                to: "visible"


                //Creo una NumberAnimation, usata per definire animazioni che cambiano proprietà con valori numerici
                NumberAnimation {
                    //Definisco che il target dell'animazione è il background
                    target: mainImageFocusBackground

                    //L'unica proprietà che verrà modificata sarà l'opacità
                    properties: "opacity";
                    duration: 500;

                    //Con questa animazione l'opacità cambierà da 0 a 0.5
                    from: 0
                    to: 0.75
                }
            },

            //Transizione per quando si passa dallo stato visible allo stato invisible
            Transition {
                from: "visible"
                to: "invisible"

                NumberAnimation {
                    target: mainImageFocusBackground

                    properties: "opacity";
                    duration: 250;

                    to: 0
                }

                /* La differenza con la transizione precedente è che quando quella per far diventare il background finisce bisogna
                 * rendere il rettangolo invisibile, altrimenti, anche se di fatto non è più visibile perchè l'opacità è a 0,
                 * continuerebbe ad intercettare gli input nella MouseArea annessa, e ciò non deve accadere.
                 * Controllo quindi quando cambia lo stato, e running == false tolgo la visibilità perchè vuol dire
                 * che l'animazione è terminata */
                onRunningChanged: {
                    if (!running)
                        mainImageFocusBackground.visible = false
                }
            }
        ]


        //Inserisco una MouseArea grande quanto tutto lo schermo in modo che se si preme da qualsiasi parte mentre il background
        //è visibile si torni allo stato iniziale
        MouseArea {
            anchors.fill: parent

            //Al click rimetto lo stato su "invisible"
            onClicked: {
                mainImageFocusBackground.state = "invisible";
            }
        }

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente
        Component.onCompleted: {
            mainImageFocusBackground.visible = false
        }
    }


    ListView {
        id: imageList
        anchors.fill: parent

        state: "invisible"

        highlightFollowsCurrentItem: false

        model: myModel
        delegate: Component {
            Image {
                id: thumbnail
                source: "file:///" + model.modelData.source
                height: parent.height
                width: container.width
                fillMode: Image.PreserveAspectFit //Questa impostazione mantiene l'aspect ratio dell'immagine a prescindere dalla sua grandezza


                MouseArea {
                    width: (thumbnail.width - thumbnail.paintedWidth)/2
                    height: parent.height

                    onReleased: {
                        imageList.state = "invisible"
                        mainImageFocusBackground.state = "invisible";

                    }
                }

                MouseArea {
                    width: (thumbnail.width - thumbnail.paintedWidth)/2
                    height: parent.height
                    x: (thumbnail.width - thumbnail.paintedWidth)/2 + thumbnail.paintedWidth


                    onReleased: {
                        console.log(imageList.currentIndex)

                        imageList.state = "invisible"
                        mainImageFocusBackground.state = "invisible";
                    }
                }

                //        //La PinchArea permette lo zoom... però non fa a provarlo senza schermo touch
                //        PinchArea {
                //            anchors.fill: parent
                //            pinch.target: mainImage
                //            pinch.minimumRotation: -360
                //            pinch.maximumRotation: 360
                //            pinch.minimumScale: 0.1
                //            pinch.maximumScale: 10

                //            onPinchFinished: console("finished")
                //        }
                //    }
            }
        }

        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem


        //Aggiungo due stati, uno per quando è visibile e uno per quando non lo è
        states: [
            //Stato per quando il rettangolo è visibile
            State {
                name: "visible"

                PropertyChanges {
                    target: imageList

                    visible: true
                }


            },

            //Stato per quando il rettangolo è invisibile
            State {
                name: "invisible"

                PropertyChanges {
                    target: imageList

                    visible: true
                }
            }
        ]

        //Per avere un'animazione tra i cambi di stato creo delle transizioni
        transitions: [
            //Transizione per quando si passa dallo stato invisible allo stato visible
            Transition {
                //Inserisco qua il nome dello stato di partenza coinvolto nella transizione e lo stato da raggiungere
                from: "invisible"
                to: "visible"


                //Per l'immagine si hanno 2 animazioni in contemporanea, quindi ci vuole una ParallelAnimation
                ParallelAnimation {

                    //Animazione per l'opacità
                    NumberAnimation {
                        target: imageList.currentItem

                        properties: "opacity"
                        duration: 250

                        from: 0
                        to: 1
                    }

                    //Animazione per il movimento sull'asse y
                    NumberAnimation {
                        target: imageList.currentItem


                        easing.type: Easing.OutCirc


                        properties: "y";
                        duration: 500

                        from: -150
                        to: 0
                    }
                 }
            },

            //Transizione per quando si passa dallo stato visible allo stato invisible
            Transition {
                from: "visible"
                to: "invisible"

                NumberAnimation {
                    target: imageList.currentItem

                    properties: "opacity";
                    duration: 250;

                    to: 0
                }

                onRunningChanged: {
                    if (!running)
                        imageList.visible = false
                }
            }
        ]

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente
        Component.onCompleted: {
            imageList.visible = false
        }

    }    
}
