import QtQuick 2.0

//Importo il file contenente la logica dietro lo stack di view; gli do un nome per poter accedere alle sue funzionalità
import "ViewManagerLogic.js" as ViewManagerJs

/*
 * Il ViewManager si occupa di gestire le view che verranno visualizzate nell'applicazione, gestendo la loro visibilità e mettendo
 * transizioni animate quando nuova view vengono visualizzate.
 * Funge da intermediario tra il main.qml e il ViewManagerLogic.js, che è quello si occupa effettivamente di gestire transizioni,
 * history e quant'altro.
 */
Rectangle {
    id: viewManager
    anchors.fill: parent


    /* Questa ParallelAnimation contene l'animazione da mostrare quando si deve mostrare una nuova ShoeView in seguito alla lettura
     * di un messaggio dall'RFID reader. Viene usata in ViewManagerLogic.js nel metodo showViewFromRFID(). Per poterla usare
     * è necessario che sia la view che deve sparire che quella che deve apparire abbiano, nella proprietà "transform" del loro
     * container, un elemeneto "Rotation".
     * La ParallelAnimation contiene due macro-animazioni: una per la view che deve sparire, una per la view che deve apparire*/
    ParallelAnimation {
        id: rfidTransition

        /* Dato che non si possono settare target per una ParallelAnimation, ma si settano per le singole animazioni che lo
         * compongono, creo delle proprietà che saranno i target delle animazioni. Servono 2 proprietà per ciascuna delle view
         * coinvolte nell'animazione: una proprietà per contenere la view stessa e una per contenere l'elemento Rotation che
         * è richiesto che sia presente nella proprietà "transform" della view.
         * Di seguito ci sono le proprietà per la view che deve apparire */
        property Item nextViewContainer;
        property Rotation nextViewRotationTransform;

        //Proprietà per la view correntemente mostrata (e che quindi deve lasciare spazio alla nuova)
        property Item currentViewContainer;
        property Rotation currentViewRotationTransform;

        //Macro-animazione per la view che deve apparire
        SequentialAnimation {
            /* Dato che viene eseguita una rotazione che ha come perno il punto a sinistra del container della view, eseguo
             * questa PropertyAction che non fa altro che applicare immediatamente la proprietà specificata, in modo che le
             * animazioni che la seguano la utilizzino */
            PropertyAction {
                target: rfidTransition.nextViewContainer;

                //Faccio cambiare il punto cardine della rotazione...
                property: "transformOrigin";

                //...e gli do' come valore il punto a sinistra del rettangolo che funge da container della view
                value: Item.Left
            }

            //Stabilita la proprietà qua sopra, inizio con la vera e propria animazione
            ParallelAnimation {
                //Animazione per la rotazione
                NumberAnimation {
                    //Il target dell'animazione è la "transform" Rotation della view. Questa era stata settata in modo da ruotare
                    //attorno all'asse y
                    target: rfidTransition.nextViewRotationTransform

                    duration: 1000

                    property: "angle"

                    from: 90
                    to: 0
                }

                //Animazione per fare un po' di scaling
                NumberAnimation {
                    target: rfidTransition.nextViewContainer

                    duration: 1000

                    property: "scale"

                    from: 0.5
                    to: 1
                }

                //Animazione per fare un fade in
                NumberAnimation {
                    target: rfidTransition.nextViewContainer

                    duration: 1000

                    property: "opacity"

                    from: 0.25
                    to: 1
                }
            }
        }


        //Macro-animazione per la view che deve sparire; stesso discorso della view che deve apparire, cambiano solo i valori
        //all'interno delle varie animazioni e la durata complessiva di tutte
        SequentialAnimation {

            PropertyAction {
                target: rfidTransition.currentViewContainer

                property: "transformOrigin"

                value: Item.Left
            }

            ParallelAnimation {

                NumberAnimation {
                    target: rfidTransition.currentViewRotationTransform

                    duration: 500

                    property: "angle"

                    from: 0
                    to: -90
                }

                NumberAnimation {
                    target: rfidTransition.currentViewContainer

                    duration: 500

                    property: "scale"

                    from: 1
                    to: 0.85
                }

                NumberAnimation {
                    target: rfidTransition.currentViewContainer

                    duration: 800

                    property: "opacity"

                    from: 1
                    to: 0.25
                }
            }
        }

        onRunningChanged: {
            //Quando parte la transizione emitto i signal delle view coinvolte per indicare loro che è iniziata la transizione,
            //in modo che possano disabilitare la possibilità di clickare e cose simili
            if(running)
            {
                rfidTransition.currentViewContainer.transitionFromRFIDStarted()
                rfidTransition.nextViewContainer.transitionFromRFIDStarted()
            }
            //Quando la transizione finisce, distruggo la view che è sparita, per salvare memoria. Inoltre emitto il signal che
            //indica alla ShoeView che è apparsa che è finita la transizione
            else
            {
                rfidTransition.currentViewContainer.destroy();

                rfidTransition.nextViewContainer.transitionFromRFIDEnded()
            }
        }
    }



    //Animazione per lo slide verso sinistra per la view che deve apparire
    PropertyAnimation {
        id: nextViewAnimation
        duration : 500
        property: "x"
        easing.type: Easing.InQuad
    }

    /* Animazione identica a quella sopra, ma usata quando si torna indietro nello stack di view; in tal caso infatti la view corrente
     * deve sparire definitivamente, non viene salvata. Essendo creata dinamicamente quindi, è meglio distruggerla al
     * termine dell'animazione, altrimenti a lungo andare tutte le view che si accumulano in questo modo potrebbero
     * causare problemi in quanto a performance */
    PropertyAnimation {
        id: currentViewAnimationWithDestruction
        duration : 500
        property: "x"
        easing.type: Easing.InQuad

        //Quando l'animazione parte disabilito i click nella view che è stata targettata; al termine la distruggo
        onRunningChanged: {
            if(running)
                target.disableClicks();
            else
                target.destroy();
        }
    }

    //Animazione per lo slide verso sinistra per la view corrente, che deve sparire (attualmente questa animazione non è più usata)
    PropertyAnimation {
        id: currentViewAnimation
        duration : 500
        property: "x"
        easing.type: Easing.InQuad

        //Quando l'animazione finisce, rendo invisibile il target dell'animazione (cioè la view che deve sparire)
        onStopped: target.visible = false;
    }




    /* Questa funzione si occupa di mostrare la view passatagli come parametro con una transizione "RFID style". E'
     * usata in stile "una botta e via" quando si crea una ShoeView in seguito alla lettura di un messaggio dall'RFID reader */
    function showViewFromRFID(newView)
    {
        ViewManagerJs.showViewFromRFID(newView);
    }

    /* Questa funzione si occupa di mostrare la view passatagli come parametro con una "spinning transition". E'
     * usata come transizione di default per quando si cambia schermata in seguito al click dell'user su una scarpa
     * diversa da quella attualmente visualizzata */
    function showView(newView)
    {
        ViewManagerJs.showView(newView);
    }


    /* Funzione che si occupa di tornare indietro di una view nello stack; la funzione è messa qua e non
     * in ViewManagerJs.js perchè deve essere accessibile dall'esterno */
    function goBack()
    {
        ViewManagerJs.goBack();
    }


    /* Funzione che si occupa di svuotare l'array contenente l'history delle view visitate e che visualizza la view di timeout
     * eseguendo una transizione visiva */
    function resetToScreensaverView(newView)
    {
        ViewManagerJs.resetToView(newView);
    }


    /* Funzione che si occupa di salvare il riferimento alla prima view visibile nell'applicazione */
    function setStartingView(startingView)
    {
        ViewManagerJs.setStartingView(startingView)
    }
}
