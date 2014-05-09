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

        /* Intercetto il signal dichiarato dentro ShoeImagesList; il signal coincide con un tap sulla main image, che deve implicare
         * un focus sull'immagine. Il signal riceve come parametro l'indice della lista di thumbnail che indica
         * quale immagine della contenente le immagini ingrandite deve essere mostrata per prima */
        onMainImageClicked: {
            //Quando il signal scatta, cambio lo stato del rettangolo che oscura lo schermo
            mainImageFocusBackground.state = "visible";

            //Cambio l'indice della lista contenente le immagini ingrandite in base all'indice ricevuto dal signal; dopodichè
            //rendo visibile la lista stessa
            imageFocusList.currentIndex = listIndex
            imageFocusList.state = "visible"
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


    //Lista contenente le immagini delle scarpe ingrandite; di default è invisibile, si attiva solo quando si preme sull'immagine
    //attualmente selezionata nella lista di thumbnail
    ListView {
        id: imageFocusList

        //La lista è grande quanto tutto lo schermo, quindi "filla" tutto il parent
        anchors.fill: parent

        //Inizialmente lo stato è invisibile
        state: "invisible"

        /* Segnalo che la lista non deve seguire automaticamente l'elemento attualmente selezionato; senza questo booleano
         * la lista si sposterebbe da sola (moooolto lentamente) verso l'elemento da visualizzare quando la lista diventa
         * inizialmente visibile */
        highlightFollowsCurrentItem: false

        //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
        //contenente le thumbnail
        model: myModel

        //Il delegate corrisponde ad una singola immagine per ogni item della lista
        delegate: Component {
            Image {
                id: focusedImage
                source: "file:///" + model.modelData.source
                height: parent.height

                //L'immagine deve essere larga quanto tutto lo schermo in modo che nella lsita si veda una sola immagine alla volta
                width: container.width

                //Questa impostazione mantiene l'aspect ratio dell'immagine; in questo modo nonostante l'immagine sia grande
                //quanto lo schermo, si vede come come dovrebbe apparire normalmente
                fillMode: Image.PreserveAspectFit

                //Per far si che si nasconda la lista quando si preme al di fuori dell'immagine creo due MouseArea da posizionare
                //in modo che siano una a sinistra dell'immagine e una alla sua destra; inizio con la MouseArea di sinistra
                MouseArea {
                    /* L'altezza deve essere grande tanto quanto lo schermo, mentre la larghezza + data dalla grandezza totale
                     * occupata dall'immagine (tutto lo schermo) meno la grandezza effettivamente disegnata (quella reale
                     * dell'immagine), il tutto diviso per due in quanto il centro dell'immagine è proprio al centro dello schermo */
                    height: parent.height
                    width: (focusedImage.width - focusedImage.paintedWidth)/2

                    //Per evitare che si chiuda la lista mentre si preme per scorrerla, l'evento per chiuderla scatta solo
                    //quando si preme e si rilascia subito la MouseArea
                    onReleased: {
                        /* Dato che scorrendo la lista l'indice non cambia (in quanto si sta solo scorrendo, non si sta selezionando
                         * alcun elemento), e dato che l'animazione di svanimeto dell'immagine viene fatta solo sull'oggetto
                         * correntemente selezionato, cambio l'indice della lista con quello dell'immagine attualmente visualizzata
                         * al momento dello svanimento della lista, in modo che l'immagine scompaia con l'animazione */
                        imageFocusList.currentIndex = index

                        //Cambiato l'indice, rendo invisibile sia la lista che lo sfondo scuro; le animazioni saranno eseguite
                        //come transizioni tra stati di questi componenti
                        imageFocusList.state = "invisible"
                        mainImageFocusBackground.state = "invisible";
                    }
                }

                //MouseArea per la parte destra dell'immagine
                MouseArea {
                    //Le dimensioni sono uguali a quelle della prima MouseArea...
                    height: parent.height
                    width: (focusedImage.width - focusedImage.paintedWidth)/2

                    //...quello che cambia è che la MouseArea deve partire con una x che sia tale da far si che copra solo
                    //la parte a destra dell'immagine
                    x: (focusedImage.width - focusedImage.paintedWidth)/2 + focusedImage.paintedWidth

                    onReleased: {
                        imageFocusList.currentIndex = index

                        imageFocusList.state = "invisible"
                        mainImageFocusBackground.state = "invisible";
                    }
                }

//                //La PinchArea permette lo zoom... però non fa a provarlo senza schermo touch
//                PinchArea {
//                    anchors.fill: parent
//                    pinch.target: mainImage
//                    pinch.minimumRotation: -360
//                    pinch.maximumRotation: 360
//                    pinch.minimumScale: 0.1
//                    pinch.maximumScale: 10
//                }

            }
        }

        orientation: ListView.Horizontal

        //Lo snapMode messo in questo modo fa si che si possa scorrere un solo elemento della lista per volta
        snapMode: ListView.SnapOneItem


        //Aggiungo due stati, uno per quando la lista è visibile e uno per quando non lo è; il funzionamento è identico
        //a quanto fatto per il rettangolo mainImageFocusBackground
        states: [
            //Stato per quando è visibile
            State {
                name: "visible"

                PropertyChanges {
                    target: imageFocusList

                    visible: true
                }
            },

            //Stato per quando la lista è invisibile
            State {
                name: "invisible"

                PropertyChanges {
                    target: imageFocusList

                    visible: true
                }
            }
        ]

        //Per avere un'animazione tra i cambi di stato creo delle transizioni
        transitions: [
            //Transizione per quando si passa dallo stato invisible allo stato visible
            Transition {
                from: "invisible"
                to: "visible"


                //Per l'immagine si hanno 2 animazioni in contemporanea, quindi ci vuole una ParallelAnimation
                ParallelAnimation {

                    //Animazione per l'opacità
                    NumberAnimation {
                        /* Il target dell'animazione è il currentItem; per questo è importante che prima del cambiamento di stato
                         * sia settato correttamente il currentIndex con quello dell'immagine da mostrare, in modo che il
                         * currentItem sia effettivamente aggiornato */
                        target: imageFocusList.currentItem

                        properties: "opacity"
                        duration: 250

                        from: 0
                        to: 1
                    }

                    //Animazione per il movimento sull'asse y
                    NumberAnimation {
                        target: imageFocusList.currentItem


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
                    target: imageFocusList.currentItem

                    properties: "opacity";
                    duration: 250;

                    to: 0
                }

                onRunningChanged: {
                    if(!running)
                    {
                        imageFocusList.visible = false

                        //Quando l'animazione termina, oltre a rendere invisible la lista rimetto l'opacità a 1 all'elemento
                        //correntemente selezionato nella lista, in quanto con l'animazione era svanito
                        imageFocusList.currentItem.opacity = 1
                    }
                }
            }
        ]

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente
        Component.onCompleted: {
            imageFocusList.visible = false
        }


        /* Faccio si che quando cambi l'indice della lista, la lista visualizzi l'elemento attualmente selezionato.
         * Nota: se highlightFollowsCurrentItem fosse stato true la chiamata a positionViewAtIndex avrebbe provocato
         * un'animazione di transizione (mooolto lenta); messo su false, lo spostamento è istantaneo */
        onCurrentIndexChanged: imageFocusList.positionViewAtIndex(currentIndex, ListView.Contain)
    }    
}
