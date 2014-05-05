import QtQuick 2.0

Rectangle {
    id: view1
    color: "#EEEEEE"
    width: 1920 * scaleX
    height: 1080 * scaleY

    ShoeImagesList {
        id: imagesList

        onMainImageClicked: {
            mainImageFocusBackground.state = "visible";
            mainImage.source = imageSource;
            mainImage.state = "visible";
        }
    }

    ShoeDetail {
        id: shoeDetail
        anchors.left: imagesList.right
        anchors.leftMargin: 200 * scaleX
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
                mainImage.state = "invisible";
            }
        }

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente
        Component.onCompleted: {
            mainImageFocusBackground.visible = false
        }
    }

    //Immagine di dettaglio della thumbnail attualmente selezionata
    Image {
        id: mainImage
        clip: true
        fillMode: Image.PreserveAspectFit //Questa impostazione mantiene l'aspect ratio dell'immagine a prescindere dalla sua grandezza
        smooth: true

        //Ancoro l'immagine a sinistra della lista delle thumbnail e al centro dell'altezza del padre (il superContainer)
        anchors {
            horizontalCenter: parent.horizontalCenter
//            verticalCenter: parent.verticalCenter
        }

        visible: false


        state: "invisible" //Stabilisco che lo stato iniziale è invisible, definito più sotto


        //Aggiungo due state, uno per quando è visibile e uno per quando non lo è
        states: [
            //Stato per quando il rettangolo è visibile
            State {
                name: "visible"

                PropertyChanges {
                    target: mainImage

                    visible: true
                }
            },

            //Stato per quando il rettangolo è invisibile
            State {
                name: "invisible"

                PropertyChanges {
                    target: mainImage

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


                ParallelAnimation {

                    //Creo una NumberAnimation, usata per definire animazioni che cambiano proprietà con valori numerici
                    NumberAnimation {
                        //Definisco che il target dell'animazione è il background
                        target: mainImage

                        //L'unica proprietà che verrà modificata sarà l'opacità
                        properties: "opacity";
                        duration: 250;

                        //Con questa animazione l'opacità cambierà da 0 a 0.5
                        from: 0
                        to: 1
                    }

                    //Creo una NumberAnimation, usata per definire animazioni che cambiano proprietà con valori numerici
                    NumberAnimation {
                        target: mainImage

                        easing.overshoot: 3
                        easing.amplitude: 1.7

                        properties: "y";
                        duration: 500

                        easing.type: Easing.OutBack

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
                    target: mainImage

                    properties: "opacity";
                    duration: 250;

                    to: 0
                }

                onRunningChanged: {
                    if (!running)
                        mainImage.visible = false
                }
            }
        ]



        PinchArea {
            anchors.fill: parent
            pinch.target: photoFrame
            pinch.minimumRotation: -360
            pinch.maximumRotation: 360
            pinch.minimumScale: 0.1
            pinch.maximumScale: 10
            onPinchFinished: photoFrame.border.color = "black";
            MouseArea {
                id: dragArea
                hoverEnabled: true
                anchors.fill: parent
                drag.target: photoFrame
                onPressed: photoFrame.z = ++root.highestZ;
                onEntered: photoFrame.border.color = "red";
                onExited: photoFrame.border.color = "black";
                onWheel: {
                    if (wheel.modifiers & Qt.ControlModifier) {
                        photoFrame.rotation += wheel.angleDelta.y / 120 * 5;
                        if (Math.abs(photoFrame.rotation) < 4)
                            photoFrame.rotation = 0;
                    } else {
                        photoFrame.rotation += wheel.angleDelta.x / 120;
                        if (Math.abs(photoFrame.rotation) < 0.6)
                            photoFrame.rotation = 0;
                        var scaleBefore = image.scale;
                        image.scale += image.scale * wheel.angleDelta.y / 120 / 10;
                        photoFrame.x -= image.width * (image.scale - scaleBefore) / 2.0;
                        photoFrame.y -= image.height * (image.scale - scaleBefore) / 2.0;
                    }
                }
            }
        }
    }



}
