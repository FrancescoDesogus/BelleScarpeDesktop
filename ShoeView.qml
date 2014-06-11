import QtQuick 2.0
import QtWebKit 3.0
//import  QtMultimedia 5.0


//Contenitore principale della view
Rectangle {
    id: container
    color: "#FFFFFF"

    //Le dimensioni della view sono grandi quanto tutto lo schermo
    width: TARGET_RESOLUTION_WIDTH * scaleX
    height: TARGET_RESOLUTION_HEIGHT * scaleY


    /**************************************************************
     * Costanti usate per definire le grandezze dei vari elementi
     **************************************************************/

    //Costanti che contengono la durata di fading verso il bianco che si hanno quando la ShoeView appare/scompare dopo una
    //transizione con un'altra ShoeView sotto input utente diretto
    property int fadingInDuration: 300
    property int fadingOutDuration: 400

    /* Quando si effettuano transizioni tra due ShoeView (senza aver di mezzo l'RFID reader) si effettua una transizione usando
     * una FlipableSurface. Mantengo quindi il riferimento della FlipableSurface da usare in modo che sia accessibile dall'esterno
     * (cioè dal file ViewManagerLogic.js in particolare) in modo che possa essere eseguita la transizione quando serve */
    property FlipableSurface flipableSurface;

    /* Booleano per indicare se l'utente può interagire con la maggior parte dei componenti dell'interfaccia. Durante le transizioni
     * tra una schermata e l'altra non è permesso premere su alcuni componenti per evitare problemi, ma di default lo
     * si deve poter fare (così se per caso una transizione non dovesse capitare per qualche motivo ma la nuova schermata appare
     * lo stesso si potrebbe interagire comunque) */
    property bool isClickAllowed: true


    /**************************************************************
     * Signal emessi verso l'esterno
     **************************************************************/

    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()

    //Questo signal indica che è stata premuta una nuova scarpa e che bisogna creare una nuova view che la visualizzi;
    //passa come parametro l'id della scarpa toccata
    signal needShoeIntoContext(int id)

    //Signal che indica che bisogna tornare indietro di una view nello stack di viste
    signal goBack()

    //Signal per indicare l'inizio/fine dei vari tipi di transizione (dovuta a RFID o dovuta a input utente diretto).
    //Questi signal sono emessi dall'esterno (dal ViewManager) e sono "ascoltati" dentro ShoeView
    signal transitionFromRFIDStarted()
    signal transitionFromRFIDEnded()
    signal transitionStarted()
    signal transitionEnded()


    /* Questa proprietà permette di inserire una Rotation, che da' più libertà di rotazione per il container (la cui proprietà
     * "rotation" permette di ruotare solo intorno all'asse z). La Rotation è usata per fare una rotazione intorno all'asse y
     * quando si avvia l'animazione di transizione in seguito ad una nuova view dovuta da un messaggio dell'RFID reader.
     * Nota: le Transform inserite qua dentro sono SEMPRE applicate all'oggetto, non solo durante animazioni o cose simili */
    transform: Rotation {
        //Stabilisco la posizione del punto cardine da cui fare l'animazione; il punto è a sinistra del container, centrato in altezza
        origin.x: 0
        origin.y: container.height/2

        //Stabilisco intorno a quali assi effettuare la rotazione; in questo caso solo intorno all'asse y
        axis.x: 0
        axis.y: 1
        axis.z: 0

        /* Stabilisco l'angolo di default. Mettere un valore diverso da 0 farebbe si che tutta la ShoeView avesse quell'angolo
         * costantemente così, non solo durante l'animazione, che non è quello che si vuole. L'angolo è cambiato solo durante
         * l'animazione, poi è riportato a zero */
        angle: 0
    }



    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShowView che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: container.touchEventOccurred()
    }


    //Component contenente la lista delle thumbnail delle immagini e l'immagine attualmente selezionata
    ShoeImagesList {
        id: imagesList

        /* Intercetto il signal dichiarato dentro ShoeImagesList; il signal coincide con un tap sulla main image, che deve implicare
         * un focus sull'immagine. Il signal riceve come parametro l'indice della lista di thumbnail che indica
         * quale immagine della contenente le immagini ingrandite deve essere mostrata per prima */
        onMainImageClicked: {
            if(container.isClickAllowed)
            {
                //Quando il signal scatta, cambio lo stato del rettangolo che oscura lo schermo
                mainImageFocusBackground.state = "visible";

                //Rendo "normale" il dot corrispondende all'index della lista che era stato precedentemente visualizzato,
                //qualora esistesse
                imageFocusList.dotsArray[imageFocusList.currentIndex].opacity = 1

                //Cambio l'indice della lista contenente le immagini ingrandite in base all'indice ricevuto dal signal; dopodichè
                //rendo visibile la lista stessa
                imageFocusList.currentIndex = listIndex
                imageFocusList.state = "visible"


                //Salvo quale è l'indice dell'immagine attualmente visibile
                imageFocusList.currentVisibleIndex = listIndex

                //Stabilisco che il dot correntemente attivo della lista è quello corrispondente all'index selezionato
                imageFocusList.currentActiveDot = imageFocusList.dotsArray[listIndex]

                //Rendo "attivo" il dot
                imageFocusList.currentActiveDot.scale = 1

                //Rendo invisibile il rettangolo per aprire il pannello dei filtri
                filterPanel.state = "hidden"
            }
        }

        //Anche ShoeImagesList ha un signal onTouchEventOccurred; quando scatta, propago l'evento verso l'esterno
        onTouchEventOccurred: container.touchEventOccurred()

        //Per fare il fade in/out effect, utilizzo un Behavior che esegue l'animazione nel tempo stabilito quando l'opacità cambia
        Behavior on opacity {
            NumberAnimation {
                duration: imagesList.opacity == 0 ? fadingOutDuration  : fadingInDuration
            }
        }
    }

    //Component contenente le informazioni sulla scarpa
    ShoeDetail {
        id: shoeDetail
        anchors.left: imagesList.right
        anchors.leftMargin: 50 * scaleX

        //Anche ShoeDetail ha un signal onTouchEventOccurred; quando scatta, propago l'evento verso l'esterno
        onTouchEventOccurred: container.touchEventOccurred()

        //Per fare il fade in/out effect, utilizzo un Behavior che esegue l'animazione nel tempo stabilito quando l'opacità cambia
        Behavior on opacity {
            NumberAnimation {
                duration: shoeDetail.opacity == 0 ? fadingOutDuration  : fadingInDuration
            }
        }
    }


    //Component la lista delle scarpe simili
    SimiliarShoesList {
        id: similiarShoesList
        anchors.right: parent.right

        anchors.top: parent.top

        //Per fare il fade in/out effect, utilizzo un Behavior che esegue l'animazione nel tempo stabilito quando l'opacità cambia
        Behavior on opacity {
            NumberAnimation {
                duration: similiarShoesList.opacity == 0 ? fadingOutDuration  : fadingInDuration
            }
        }

        //Anche SimiliarShoesList ha un signal onTouchEventOccurred; quando scatta, propago l'evento verso l'esterno
        onTouchEventOccurred: container.touchEventOccurred()


        //Signal che viene emesso quando si preme su una scarpa consigliata e bisogna cambiare schermata. Il signal passa
        //come parametri l'id della scarpa da caricare e la FlipableSurface da usare per la transizione visiva
        onNeedShoeIntoContext: {
            //Recupero la FlipableSurface che dovrà essere usata per la transizione
            flipableSurface = shoeSelectedFlipable

            /* Le coordinate attuali di flipableSurface sono relative al suo vecchio padre, il container di SimilarShoesList.
             * Dato che ora cambierà padre, e quindi sistema di coordinate, recupero le sue coordinate globali in base al
             * container di ShoeView usando la funzione mapToItem().
             * Nota: affinchè le coordinate globali vengano calcolate correttamente con questa funzione, le coordinate locali
             * del flipable devono essere prese localmente a tutto il container di SimilarShoesList */
            var globalCoordinates = flipableSurface.mapToItem(container.parent, 0, 0)

            /* A questo punto dell'esecuzione, il flipable ha come padre SimilarShoesList; questo vuol dire che le sue coordinate
             * sono locali a quel component, e non può neanche andare oltre i suoi limiti visivi. Dato che la FlipableSurface dovrà
             * muoversi per tutto lo schermo, occorre far diventare la ShoeView in questione padre del flipable, cosicchè non sia
             * più vincolato a muoversi dentro SimilarShoesList */
            flipableSurface.parent = container

            //Le coordinate appena prese servono per sapere da dove partire con l'animazione di flip, ed eventualmente dove tornare
            //quando si preme il tasto back. Salvo quindi le coordinate nelle rispettive proprietà del flipable
            flipableSurface.initialX = globalCoordinates.x
            flipableSurface.initialY = globalCoordinates.y

            //Salvo anche il riferimento dell'intera ShoeView. In realtà lo avrei già, essendo la ShoeView il padre di
            //flipableSurface, ma per evitare ambiguità ho preferito creare una proprietà a posta
            flipableSurface.frontShoeView = container


            //Pronto il flipable, emitto il signal che chiamerà il rispettivo slot di C++ che si occuperà di caricare la scarpa,
            //creare la nuova view e attivare l'animazione del flipable inserendo la nuova view come "back" della FlipableSurface
            container.needShoeIntoContext(id)


            //Infine porto a zero l'opacità di tutti i componenti "che contano" di ShoeView; grazie alla proprietà
            //Behavior on opacity che hanno tutti questi, verrà avviata l'animazione di fade out
            imagesList.opacity = 0
            shoeDetail.opacity = 0
            similiarShoesList.opacity = 0
            backButton.opacity = 0
        }
    }

    Image {
        id: backButton

        //Proprietà che indica se il bottone è disabilitato o meno; lo è quando non ci sono schermate verso cui tornare indietro
        property bool isDisabled: false;

        //Se il bottone è disabilitato, carico l'immagine apposita, altrimenti quella normale
        source: isDisabled ? "qrc:///qml/back_disabled_mini.png" : "qrc:///qml/back_enabled_mini.png"

        width: 65 * scaleX
        height: 65 * scaleY

        fillMode: Image.PreserveAspectFit

        antialiasing: true

        x: 180 * scaleX
        y: 10 * scaleY

        Behavior on opacity {
            NumberAnimation {
                duration: backButton.opacity == 0 ? fadingOutDuration  : fadingInDuration
            }
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true

            onPressed: {
                container.touchEventOccurred()

                if(!backButton.isDisabled)
                    backButton.source =  "qrc:///qml/back_pressed_mini.png"
            }

            onClicked: {
                container.touchEventOccurred()

                if(!backButton.isDisabled)
                    container.goBack()
            }

            onReleased: {
                if(!backButton.isDisabled)
                    backButton.source = "qrc:///qml/back_enabled_mini.png"
            }

            onEntered: {
                if(!backButton.isDisabled)
                    backButton.source = "qrc:///qml/back_disabled_mini.png"
            }

            onExited: {
                if(!backButton.isDisabled)
                    backButton.source = "qrc:///qml/back_enabled_mini.png"
            }
        }
    }


    //Rettangolo che funge da background oscurato per quando si preme su una thumbnail per mostrare l'immagine ingrandita
    Rectangle {
        id: mainImageFocusBackground
        width: parent.width
        height: parent.height
        color: "black"
        state: "invisible" //Stabilisco che lo stato iniziale è invisible, definito più sotto


        //Aggiungo due stati, uno per quando è visibile e uno per quando non lo è
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

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente
        Component.onCompleted: {
            mainImageFocusBackground.visible = false
        }

        /* Questa MouseArea è usata esclusivamente quando il pannello per i filtri è aperto. Infatti, nonostante la MouseArea copra
         * tutto lo schermo, quando si apre la lista delle immagini e compare il background, essendo le immagini grandi quanto
         * tutto lo schermo quando si preme da qualunque parte questa MouseArea non intercetta nessun evento. Li intercetta però
         * quando il pannell oper i filtri è aperto; in tal caso infatti si rende visibile anche questo background, che ha il solo
         * scopo di aspettare gli eventi da questa MouseArea. Quando ne riceve uno, si rende invisibile e chiude il pannello */
        MouseArea {
            anchors.fill: parent

            onClicked: {
                //Procedo solo se i click sono abilitati; non lo sono durante le transizioni, in quanto sarebbe possibile
                //far scomparire il pannello durante una transizione premendo su questo background
                if(container.isClickAllowed)
                {
                    //Rendo invisibile il background (di fatto era presente, anche se aveva l'opacità a 0)...
                    mainImageFocusBackground.visible = false

                    //...e chiudo il pannello per filtrare
                    filterPanel.closePanel();
                }
            }
        }
    }


    //Lista contenente le immagini delle scarpe ingrandite; di default è invisibile, si attiva solo quando si preme sull'immagine
    //attualmente selezionata nella lista di thumbnail
    ListView {
        id: imageFocusList

        //Array che contiene tutti i dot della lista
        property var dotsArray: [];

        //Indice dell'immagine attualmente visibile nello schermo
        property int currentVisibleIndex;

        //Proprietà che contene il dot della lista attualmente attivo (quello relativo all'immagine attualmente visibile)
        property Item currentActiveDot;


        //La lista è grande quanto tutto lo schermo, quindi occupa tutto il parent
        anchors.fill: parent

        //Inizialmente lo stato è invisibile
        state: "invisible"

        /* Segnalo che la lista non deve seguire automaticamente l'elemento attualmente selezionato; senza questo booleano
         * la lista si sposterebbe da sola (moooolto lentamente) verso l'elemento da visualizzare quando la lista diventa
         * inizialmente visibile */
        highlightFollowsCurrentItem: false

        //Incrementare il valore della decelerazione fa si che si scrolli tra una imagine e l'altra più velocemente
        flickDeceleration: 10000

        orientation: ListView.Horizontal

        //Lo snapMode messo in questo modo fa si che si possa scorrere un solo elemento della lista per volta
        snapMode: ListView.SnapOneItem


        //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
        //contenente le thumbnail
        model: imagesModel

        //Il delegate corrisponde ad una singola immagine per ogni item della lista
        delegate: Component {
            Image {
                id: focusedImage
                source: modelData

                height: parent.height

                //L'immagine deve essere larga quanto tutto lo schermo in modo che nella lsita si veda una sola immagine alla volta
                width: container.width

                //Questa impostazione mantiene l'aspect ratio dell'immagine; in questo modo nonostante l'immagine sia grande
                //quanto lo schermo, si vede come come dovrebbe apparire normalmente
                fillMode: Image.PreserveAspectFit


                //L'immagine ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(),
                //in modo da avvisare chi userà il component ShowView che è stato ricevuto un touch event
                MouseArea {
                    anchors.fill: parent
                    onClicked: container.touchEventOccurred()
                }


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

                        //Avviso anche che c'è stato un touch event
                        container.touchEventOccurred();

                        //Rendo anche nuovamente visibile il pannello per i filtri cambiandone lo stato
                        filterPanel.state = "visible"
                    }

                    //Al click avviso che c'è stato un touch event
                    onClicked: container.touchEventOccurred()
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

                        container.touchEventOccurred();

                        filterPanel.state = "visible"
                    }

                    onClicked: container.touchEventOccurred()
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


        //Component per i dot della lista. E' dichiarato come Component in modo tale che sia possibile crarne istanze via JavaScript
        Component {
            id: listDot

            //Il dot vero e proprio è questo rettangolo con radius per farlo sembrare un cerchio
            Rectangle {
                width: 20 * scaleX
                height: 20 * scaleY

                color: "#807a7a"

                radius: 20

                scale: 0.5

                //Animazione per quando si cambia lo scale
                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                    }
                }
            }
        }


        /* Contenitore dei dot della lista. Per far si che siano sempre centrati orizzontalmente, quando vengono creati
         * dinamicamente vengono inseriti in questo container in modo che sia posizionato in modo che i dot siano messi bene
         * (utilizzo un Item e non un Rectangle come container in modo che non si veda lo sfondo del rettangolo dietro) */
        Item {
            id: listDotsContainer

            //Coordinata y in cui appariranno i dot
            y: imageFocusList.height - 75 * scaleY

            //Anchor per centrare orizzontalmente i dot
            anchors.horizontalCenter: imageFocusList.horizontalCenter
        }


        /* Questa funzione è chiamata al termine del caricamento della lista (quindi una sola volta) e serve a creare
         * dinamicamente i dot degli elementi della lista */
        function createDots(sizes)
        {
            //Variabile che conterrà una singola istanza del Component "listDot" creato poco più sopra
            var item;

            //Coordinata x iniziale per il primo dot; il valore della x incrementerà (la y è sempre a 0)
            var x = 0;

            //Spazio tra un dot e l'altro
            var dotsSpacing = 5 * scaleX;

            //Numero di dot da creare
            var dotsCount = imageFocusList.count

            //Larghezza di un singolo dot; deve essere uguale a quella definita nel Component "listDot"
            var dotWidth = 20 * scaleX

            //Dato che i dot dovranno essere inseriti nel contenitore listDotsContainer, bisogna dare una larghezza ad esso.
            //Calcolo quindi la lunghezza totale che deve avere...
            var totalWidth = (dotsCount - 1) * (dotWidth + dotsSpacing) + dotWidth

            //...e la assegno al container
            listDotsContainer.width = totalWidth


            //Creo tanti dot quanti sono gli elementi della lista
            for(var i = 0; i < dotsCount; i++)
            {
                //Creo una istanza del Component listDot e la inserisco all'interno del container per i dot
                item = listDot.createObject(listDotsContainer);

                //La posiziono nella scena
                item.x = x;
                item.y = 0;

                //Incremento la x, aggiungendo un margine di separazione tra un elemento e l'altro
                x = x + item.width + dotsSpacing;

                //Infine salvo l'item appena inserito nell'array, in modo da poterci accedere in seguito
                dotsArray[i] = item
            }
        }


        /* Quando si scorre la lista il contentX varia in base all'elemento della lista attualmente visualizzato. Per far si
         * che i dot cambino seguendo l'immagine attualmente visibile, ogni volta che il contentX cambia
         * controllo se l'immagine visibile è cambiata; se lo è, aggiorno il dot */
        onContentXChanged: {
            /* Calcolo a quale indice si è arrivati nello scorrimento. Per farlo mi baso sul fatto che tutti gli item della
             * lista hanno la stessa larghezza (tutto lo schermo), quindi per capire a quale indice si è basta recuperare
             * la posizione attuale all'interno della lista e dividerla per la larghezza; arrotondo il numero in quanto
             * durante un flick la posizione del contentX sta' variando e quindi non sempre ha un valore intero */
            var index = Math.round(contentX / container.width);

            //Se l'indice calcolato è diverso dall'indice precedentemente salvato, vuol dire che ci si è spostati. Procedo
            //quindi con il cambio del dot attivo
            if(currentVisibleIndex != index)
            {
                //Rendo inattivo il dot precedentemente attivo
                currentActiveDot.scale = 0.5

                //Aggiorno il dot correntemente attivo con quello corrispondente all'immagine attualmente visibile
                currentActiveDot = dotsArray[index];

                //Rendo il dot attivo
                currentActiveDot.scale = 1;


                //Aggiorno l'indice dell'immagine attualmente attiva
                currentVisibleIndex = index
            }
        }


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

                        from: -150 * scaleY
                        to: 0
                    }

                    //Animazione per i dot della lista
                    NumberAnimation {
                        target: listDotsContainer

                        properties: "opacity"
                        duration: 250

                        from: 0
                        to: 1
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

                NumberAnimation {
                    target: imageFocusList.currentItem

                    easing.type: Easing.OutCirc

                    properties: "y";
                    duration: 500

                    from: 0
                    to: -50 * scaleY
                }

                NumberAnimation {
                    target: listDotsContainer

                    properties: "opacity"
                    duration: 250

                    from: 1
                    to:0
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

        //Quando il component è stato caricato, setto la sua visibilità su false per non farlo vedere inizialmente. Creo
        //anche i dot della lista chiamando la funzione apposita
        Component.onCompleted: {
            imageFocusList.visible = false

            createDots()
        }


        /* Faccio si che quando cambi l'indice della lista, la lista visualizzi l'elemento attualmente selezionato.
         * Nota: se highlightFollowsCurrentItem fosse stato true la chiamata a positionViewAtIndex avrebbe provocato
         * un'animazione di transizione (mooolto lenta); messo su false, lo spostamento è istantaneo */
        onCurrentIndexChanged: imageFocusList.positionViewAtIndex(currentIndex, ListView.Contain)
    }


    //Component contenente il pannello per filtrare
    ShoeFilter {
        id: filterPanel

        //Inizialmente il pannello è invisibile; apparirà in seguito alla fine della transizione che mostrerà la ShoeView
        visible: false

        //Rettangolo per scuro per il background, riciclato dalla ShoeView
        backgroundRectangle: mainImageFocusBackground

        //Fisso il pannello in basso al centro dello schermo
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter


        //Anche ShoeFilter ha un signal onTouchEventOccurred; quando scatta, propago l'evento verso l'esterno
        onTouchEventOccurred: container.touchEventOccurred()

        //Signal che viene emesso quando si preme su una scarpa consigliata e bisogna cambiare schermata. Il funzionamento
        //è analogo all'onNeedShoeIntoContext di SimiliarShoesList, quindi i commenti sono lasciati la
        onNeedShoeIntoContext: {
            flipableSurface = shoeSelectedFlipable

            var globalCoordinates = flipableSurface.mapToItem(container.parent, 0, 0)

            flipableSurface.parent = container

            flipableSurface.initialX = globalCoordinates.x
            flipableSurface.initialY = globalCoordinates.y

            flipableSurface.frontShoeView = container

            container.needShoeIntoContext(id)

            imagesList.opacity = 0
            shoeDetail.opacity = 0
            similiarShoesList.opacity = 0
            backButton.opacity = 0

            //A differenza di quanto faccio in onNeedShoeIntoContext di SimiliarShoesList, qua metto a 0 anche l'opacità
            //del pannello dei filtri, che rimane aperto durante la transizione e deve svanire
            filterPanel.opacity = 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: filterPanel.opacity == 0 ? fadingOutDuration  : fadingInDuration
            }
        }


        //Dichiaro alcuni stati che servono meramente per attivare determinate transizioni
        states: [
            State {
                name: "hidden"
            },

            State {
                name: "visible"
            }
        ]


        transitions: [            
            //Transizione per quando si passa allo stato visibile mentre il pannello è chiuso
            Transition {
                to: "visible"

                //Animazione per il movimento sull'asse y
                NumberAnimation {
                    target: filterPanel

                    easing.type: Easing.OutCirc

                    properties: "y";
                    duration: 300

                    to: container.height
                }

                onRunningChanged: {
                    //All'avvio dell'animazione rendo visibile il pannello qualora non lo fosse
                    if(running)
                        filterPanel.visible = true
                    //Al termine, reinserisco l'anchor che si assume fosse stato tolto in precedenza (altrimenti non si potrebbe
                    //spostare verso l'alto)
                    else
                        filterPanel.anchors.bottom = container.bottom
                }
            },

            //Transizione per quando si passa allo stato invisibile mentre il pannello è chiuso
            Transition {
                to: "hidden"

                NumberAnimation {
                    target: filterPanel

                    properties: "y";
                    duration: 300

                    to: container.height + filterPanel.draggingRectangleHeight
                }

                onRunningChanged: {
                    //All'avvio dell'animazione rimuovo l'anchor che tiene il pannello in basso, altrimenti l'animazione
                    //non avrebbe alcun effetto
                    if(running)
                        filterPanel.anchors.bottom = undefined
                    //Al termine rendo invisibile il pannello
                    else
                        filterPanel.visible = false
                }
            }
        ]
    }


    //Ascolto il signal che indica l'inizio di una transizione da RFID
    onTransitionFromRFIDStarted: {
        //Durante la transizione, non deve essere permesso clickare sullo schermo per far apparire nuove schermate, quindi
        //rendo false il booleano apposito
        container.isClickAllowed = false;

        //Nascondo il pannello per i filtri
        filterPanel.state = "hidden"
    }

    //Ascolto il signal che indica la fine di una transizione da RFID
    onTransitionFromRFIDEnded: {
        //Riabilito i click utente
        container.isClickAllowed = true;

        //Rendo visibile il pannello
        filterPanel.state = "visible"
    }

    //Ascolto il signal che indica l'inizio di una transizione normale causata dall'input utente diretto
    onTransitionStarted: {
        //Disabilito i click utente durante la transizione
        container.isClickAllowed = false;

        //Se il pannello dei filtri non era aperto, lo faccio scomparire sotto lo schermo
        if(!filterPanel.isOpen)
            filterPanel.state = "hidden"
    }

    //Ascolto il signal che indica il termine di una transizione normale causata dall'input utente diretto
    onTransitionEnded: {
        //Riabilito i click utente
        container.isClickAllowed = true;

        //Se il pannello dei filtri non era aperto, lo faccio ricomparire da sotto lo schermo
        if(!filterPanel.isOpen)
            filterPanel.state = "visible"
    }


    //Ascolto per quando la ShoeView diventa visibile; in quel momento infatti porto l'opacità di tutti i component "che contano"
    //a 1, qualora fosse stata messa a 0 in seguito ad una transizione
    onVisibleChanged: {
        if(visible)
        {
            imagesList.opacity = 1
            shoeDetail.opacity = 1
            similiarShoesList.opacity = 1
            backButton.opacity = 1
            filterPanel.opacity = 1
        }
    }





    //    Video {

    //        width: 200
    //        height: 200

    //        x: 100
    //        y: 100

    //        source: "https://www.youtube.com/watch?v=xydR7A6EP7U"
    //    }


    /* Funzione per disabilitare il bottone per tornare indietro di schermata; è chiamata da connectNewViewEvents() nel main.qml
     * quando la ShoeView è la "prima della lista" */
    function disableBackButton()
    {
        backButton.isDisabled = true;
    }
}
