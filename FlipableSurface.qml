import QtQuick 2.0

/*
 * Questo component è usato per fare l'effetto di flip nelle transizioni tra due ShoeView. A differenza del Flipable nativo di QML,
 * è possibile cambiare le propretà back e front quando si vuole (alla faccia tua, Qt).
 */
Rectangle {
    id: flipable

    /* Proprietà che rappresentano il front ed il back del flipable (e bah?). Il front DEVE essere dichiarato da subito, e non
     * deve cambiare. Il back è fatto a posta per essere inserito dopo quando serve (chiaramente deve essere inserito prima
     * di provare ad effettuare il flip), e può cambiare */
    property Item front;
    property Item back;

    /* Riferimento al vecchio padre del back. Infatti, quando viene inserita una view come "back" del flipable, non appena parte
     * l'animazione di flip il padre del back appena inserito diventa il backContainer definito più sotto. Visto che il backContainer
     * ha uno spazio di coordinate tutto suo, in base a dove è stato dichiarata la FlipableSurface in uso, e così anche il back,
     * al termine dell'animazione bisogna ripristinare il padre originario del back */
    property Item oldBackParent;


    /* Riferimento all'entry della lista che è stata selezionata e che ha causato il flip. Dato che per come è usata questa
     * FlipableSurface gli elementi che causano un flip sono sempre elementi di liste, e dato anche che per eseguire il flip
     * viene fatta una copia di quell'entry che viene sovrapposta all'originale in quanto non bisogna spostare l'entry originale
     * dalla lista (altrimenti non è più possibile reinserirla come elemento della lista), occorre tenere un riferimento
     * dell'entry che ha causato l'evento in modo da farla scomparire quando appare la copia ed inizia il flip e farla
     * ricomparire quando termina il reflip */
    property Item frontListItem;


    /* Riferimento alla ShoeView che contiene il front. Quando termina un flip, bisogna nascondere la view che conteneva il front,
     * visto che è scomparsa. Per farlo serve un riferimento a quella view. Allo stesso modo, quando si ha un reflip bisogna
     * farla ricomparire */
    property Item frontShoeView;


    //Proprietà che indica se il flip è fatto orizzontalmente o verticalmente; di default è orizzontale
    property bool horizontalFlip: true


    //Durata della transizione di flip e di reflip
    property int transitionDuration: 700


    /* Coordinate iniziali in cui era situato il front al momento del flip. Dato che la transizione del flip avviene lungo tutto
     * lo schermo, occorre che queste coordinate siano globali (per far si che ciò sia utile, bisogna far si il padre della
     * FlipableSurface sia il capo di tutta la ShoeView, altrimenti le coordinate globali non funzionerebbero a dovere). Non basta
     * quindi definire le coordinate iniziali come le coordinate iniziali del front, in quanto questo sarà definito all'interno
     * di un componente (ad esempio SimilarShoesList) e quindi saranno definite in base ad esso. Per questo motivo le coordinate
     * iniziali devono essere passate prima di fare il flip dalla ShoeView, che è il componente che ha "visione globale" di
     * tutto l'insieme */
    property real initialX
    property real initialY



    /* Signal che indica a chi userà la FlipableSurface se le è permesso effettuare click; i click vengono bloccati quando le
     * transizioni iniziano, e viene sbloccato quando finiscono */
    signal clickAllowed(bool isAllowed)


    //Al completamento del caricamento, faccio diventare il front figlio dell'apposito container; si assume quindi che il front
    //sia definito da subito, a differenza del back che può essere aggiunto in seguito
    Component.onCompleted: {
        front.parent = frontContainer
    }


    //Transform per il frontContainer. Serve per poterlo ruotare intorno ad assi diversi da quello di default (asse z). E'
    //definito al di fuori del frontContainer per poterci accedere direttamente da "flipable" durante le animazioni definite sotto
    Rotation {
         id: rotationTransformFront

         //Dichiaro che il centro di rotazione è il centro del container
         origin.x: frontContainer.width/2
         origin.y: frontContainer.height/2

         //A seconda che si debba ruotare orizontalmente o verticalmente, faccio ruotare intorno all'asse apposito
         axis.x: horizontalFlip ? 0 : 1;
         axis.y: horizontalFlip ? 1: 0;
         axis.z: 0

         //Angolo di default. Dato che il front è quello che si vede al momento iniziale del flip, l'angolo deve essere 0
         angle: 0
     }

    //Transform per il backContainer
    Rotation {
         id: rotationTransformBack

         origin.x: backContainer.width/2
         origin.y: backContainer.height/2

         axis.x: horizontalFlip ? 0 : 1;
         axis.y: horizontalFlip ? 1: 0;
         axis.z: 0

         //Dato che il back appare in seguito alla rotazione, inizialmente ruoto il container per farlo stare al rovescio in modo
         //che si raddrizzi con l'animazione. L'angolo messo al negativo è importante; se fosse 180 ruoterebbe al contrario
         angle: -180
     }

    //Container del front; non appena la FlipableSurface è stata caricata completamente, il front diventa figlio del frontContainer
    Rectangle {
        id: frontContainer

        //Il container assume la grandezza del front fin da subito
        width: front.width
        height: front.height

        //Inserisco come transform la Rotation apposita
        transform: rotationTransformFront

        /* Per dare l'illusione che dietro il front ci sia veramente il back, faccio sparire il frontContainer
         * (e quindi anche il front) non appena l'angolo supera la metà, ovvvero non appena fa 1/4 di giro sul suo asse. In
         * quel momento deve sparire e deve comparire il back */
        visible: (rotationTransformFront.angle < 90)
    }

    //Container del back; il back diventerà figlio del backContainer non appena l'animazione di flip
    //inizia (stesso discorso per il reflip)
    Rectangle {
        id: backContainer


        //Assegno la Transform per la rotazione
        transform: rotationTransformBack

        /* Gli anchors sono settati in modo che il backContainer stia esattamente sopra il front; in questo modo il back, grazie
         * al cambiamento di visibilità appena il front superà 90 gradi, fa si che il back sia effettivamente dietro il front */
        anchors.top: frontContainer.top
        anchors.bottom: frontContainer.bottom
        anchors.left: frontContainer.left
        anchors.right: frontContainer.right

        //Il discorso per la visibilità è analogo a quello per il frontContainer. Impostando al visibilità in questo modo,
        //non appena l'angolo di rotazione supererà la soglia fissata il back apparirà
        visible: (rotationTransformBack.angle >= -90)
    }


    //Le animazioni di flip e reflip sono definite come transizioni degli omonimi stati
    states: [
        State {
            name: "flip"

            //Lo stato di flip prevede che il frontContainer ruoti da 0 a 180 gradi...
            PropertyChanges {
                target: rotationTransformFront;
                angle: 180
            }

            //...e il backContainer da -180 a 0
            PropertyChanges {
                target: rotationTransformBack;
                angle: 0
            }
        },

        State {
            name: "reflip"

            //Lo stato di reflip prevede che il frontContainer ruoti da 180 a 0 gradi...
            PropertyChanges {
                target: rotationTransformFront;
                angle: 0
            }

            //...e il backContainer da 0 a -180 di nuovo
            PropertyChanges {
                target: rotationTransformBack;
                angle: -180
            }
        }
    ]


    //Transizioni visive tra gli stati
    transitions: [
        //Transizione per quando si flippa. Nota: ci sono alcune cose da fare prima di poter effettuare la transizione; vengono
        //fatte direttamente nella funzione flip(), prima che venga cambiato lo stato e quindi avviata la transizione
        Transition {
            to: "flip"

            //La transizione comprende una serie di animazioni sia per il frontContainer che per il backContainer, e avvengono
            //tutte in contemporanea
            ParallelAnimation {

                //Animazione di rotazione per il frontContainer
                NumberAnimation {
                    target: rotationTransformFront;

                    property: "angle";

                    duration: transitionDuration

                    easing.type: Easing.InOutSine
                }

                //Animazione di rotazione per il backContainer
                NumberAnimation {
                    target: rotationTransformBack;

                    duration: transitionDuration

                    property: "angle";

                    easing.type: Easing.InOutSine
                }

                //Animazione di spostamento sull'asse x del frontContainer
                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "x";

                    easing.type: Easing.InOutQuart

                    //Il punto di partenza può variare, ma il punto di arrivo è sempre l'origne
                    from: initialX
                    to: 0
                }

                //Animazione di spostamento sull'asse y del frontContainer
                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "y";

                    easing.type: Easing.InOutQuart

                    from: initialY
                    to: 0
                }

                //Animazione di spostamento sull'asse x del backContainer (attualmente non in uso perchè il backContainer
                //è ancorato al frontContainer e quindi si muove con quello
//                NumberAnimation {
//                    target: backContainer;

//                    duration: transitionDuration

//                    property: "x";

//                    easing.type: Easing.InOutQuart

//                    from: initialX
//                    to: 0
//                }

//                //Animazione di spostamento sull'asse x del backContainer (attualmente non in uso perchè il backContainer
                  //è ancorato al frontContainer e quindi si muove con quello
//                NumberAnimation {
//                    target: backContainer;

//                    duration: transitionDuration


//                    property: "y";

//                    easing.type: Easing.InOutQuart

//                    from: initialY
//                    to: 0
//                }

                //Animazione di scalatura per il frontContainer. Visto che c'è parecchia differenza in termini di grandezza
                //tra una ShoeView e una entry di una lista, la faccio aumentare di grandezza durante la transizione
                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "scale";

                    easing.type: Easing.InOutQuart

                    //Fraccio crescere il front oltre 3 volte tanto; i valori sono presi in seguito a tentativi per vedere
                    //quali erano i valori più carini
                    from: 1
                    to: 3.6
                }

                /* Animazione di scalatura per il backContainer. Visto che c'è parecchia differenza in termini di grandezza
                 * tra una ShoeView e una entry di una lista, oltre ad aumentare la grandezza del front faccio crescere il back
                 * partendo da zero */
                NumberAnimation {
                    target: backContainer;

                    duration: transitionDuration

                    property: "scale";

                    easing.type: Easing.InOutQuart

                    from: 0
                    to: 1
                }
            }

            /* Una volta terminata la transizione, faccio diventare il padre del back il padre originario, in modo che torni
             * nel suo sistema di coordinate originario. Oltre questo, rendo invisibile la ShoeView del front, che al termine
             * della transizione non è più visibile */
            onRunningChanged: {
                if(!running)
                {
                    back.parent = oldBackParent

                    frontShoeView.visible = false

                    //Emitto anche il signal per indicare che ora è permesso effettuare click, visto che la transizione è finita
                    clickAllowed(true)
                }
            }
        },

        //Transizione per quando si reflippa; analoga all'altra, cambiano solo i valori. La preparazione per la transizione è
        //fatta all'interno della funzione reflip()
        Transition {
            to: "reflip"

            ParallelAnimation {
                NumberAnimation {
                    target: rotationTransformFront;

                    duration: transitionDuration

                    property: "angle";

                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    target: rotationTransformBack;

                    duration: transitionDuration

                    property: "angle";

                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "x";

                    easing.type: Easing.InOutQuart

                    to: initialX
                }

                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "y";

                    easing.type: Easing.InOutQuart

                    to: initialY
                }

//                NumberAnimation {
//                    target: backContainer;

//                    duration: transitionDuration

//                    property: "x";

//                    easing.type: Easing.InOutQuart

//                    to: initialX
//                }

//                NumberAnimation {
//                    target: backContainer;

//                    duration: transitionDuration

//                    property: "y";


//                    easing.type: Easing.InOutQuart

//                    to: initialY
//                }


                NumberAnimation {
                    target: frontContainer;

                    duration: transitionDuration

                    property: "scale";

                    easing.type: Easing.InOutQuart

                    to: 1
                }

                NumberAnimation {
                    target: backContainer;

                    duration: transitionDuration

                    property: "scale";

                    easing.type: Easing.InOutQuart

                    to: 0
                }
            }

            /* Al termine della transizione bisogna fare alcune cose */
            onRunningChanged: {
                if(!running)
                {
                    //Distruggo il back, dato che è scomparso e non serve più perchè non ci si può ritornare (per farlo si
                    //creerà direttamente una nuova view)
                    back.destroy()


                    //Dato che la FlipableSurface era di fatto una copia della list entry che ha causato la transizione, e per questo
                    //motivo era stata fatta scomparire, la rendo visibile nuovamente
                    frontListItem.visible = true


                    /* Allo stesso modo, dato che ho appena fatto ricomparire la list entry, devo far scomparire la copia. Per farlo
                     * devo prima ripristinare il padre del frontContainer (che contiene il front, che sarebbe la copia della list
                     * entry), che era il flipable stesso (durante la transizione il padre del frontContainer era diventato
                     * la ShoeView in cui stava) */
                    frontContainer.parent = flipable

                    //Ripristinato il padre, rendo invisibile il flipable (che era la copia). Senza ripristinare il padre non
                    //sarebbe scomparso
                    flipable.visible = false


                    //Emitto anche il signal per indicare che ora è permesso effettuare click, visto che la transizione è finita
                    clickAllowed(true)
                }
            }
        }
    ]


    /* Funzione chiamata dentro ViewManagerLogic.js per avviare la rispettiva transizione. Prima di avviarla si occupa di
     * preparare alcune cose necessarie per il corretto funzionamento */
    function flip()
    {
        /* A questo punto dell'esecuzione, il padre di flipable è diventato la ShoeView in cui è presente il front. Per far si
         * che anche i container del front e del back si spostino nel piano di coordinate giusto, faccio diventare la stessa
         * ShoeView padre di entrambi */
        backContainer.parent = frontShoeView
        frontContainer.parent = frontShoeView

        //Prima della chiamata a flip() era stato inserito il back; ne approfitto quindi per settare la grandezza del container
        //in modo che sia pari a quella del back che ospita
        backContainer.width = back.width
        backContainer.height = back.height

        //Salvo il riferimento al padre attuale di back in modo da ripristinarlo in seguito e setto come nuovo padre il backContainer
        oldBackParent = back.parent
        back.parent = backContainer

        //Dato che la FlipableSurface in uso è una copia di un elemento della lista, che si deve sovrapporre e "far finta" che sia
        //l'entry della lista stessa, nascondo l'item...
        frontListItem.visible = false

        //...e rendo visibile la FlipableSurface, che si metterà esattamente sopra l'entry della lista che ora è invisibile
        flipable.visible = true



        //Emitto anche il signal indicando che non è permesso clickare, visto che la transizione sta' per iniziare
        clickAllowed(false)


        //Terminate le preparazioni, cambio lo stato per far partire la transizione
        flipable.state = "flip"
    }

    /* Funzione chiamata dentro ViewManagerLogic.js per avviare la rispettiva transizione. Prima di avviarla si occupa di
     * preparare alcune cose necessarie per il corretto funzionamento */
    function reflip()
    {
        //Dato che al termine del flip era stato ripristinato il padre originario del back, per il reflip lo rimetto come
        //figlio del backContainer
        back.parent = backContainer

        //Rendo inoltre visibile la ShoeView che ora apparirà, che è quella che contiene il front della FlipableSurface
        frontShoeView.visible = true


        //Emitto anche il signal indicando che non è permesso clickare, visto che la transizione sta' per iniziare
        clickAllowed(false)


        //Terminate le preparazioni, cambio lo stato per far partire la transizione
        flipable.state = "reflip"
    }
}

