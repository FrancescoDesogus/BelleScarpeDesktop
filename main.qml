import QtQuick 2.0


//Finestra principale di tutto l'applicativo
Rectangle {
    id: mainWindow

    //Le misure di larghezza, altezza e i valori di scalatura sono ricevuti da C++
    width: TARGET_RESOLUTION_WIDTH * scaleX
    height: TARGET_RESOLUTION_HEIGHT * scaleY


    //I figli del ViewManager sono gestiti dallo stesso. Uno solo dei figli può essere visibili in un dato momento
    ViewManager {
        id: myViewManager

        width: parent.width
        height: parent.height

        //La proprietà objectName mi permette di trovare questo componente da C++ cercandolo per nome
        objectName: "myViewManager"


        //Questa proprietà indica se attualmente la view visualizzata è quella dello screenSaver. All'inizio è così
        property bool isScreensaverOn: true

        //Riferimento alla ScreensaverView attualmente visualizzata (da usare solo se isScreensaverOn == true)
        property ScreensaverView currentScreensaverView;


        //Inizialmente l'unica schermata presente è quella di timeout, che aspetta di ricevere info dall'RFID reader
        ScreensaverView {
            id: screensaverView

            //Inizialmente, stabilisco che la screensaverView è la "currentView" usata nel file ViewManagerLogic.js per avere
            //un riferimento alla view attualmente mostrata
            Component.onCompleted: {
                myViewManager.setStartingView(screensaverView)

                //Salvo il riferimento alla view
                myViewManager.currentScreensaverView = screensaverView;

                //Connetto poi il signal della classe C++ che scatta quando è arrivato un messaggio RFID che richiede una scarpa
                //al signal della ScreensaverView che si occupa di fare i preparativi per riceverla
                window.dataIncomingFromRFID.connect(screensaverView.transitionFromRFIDincoming)
            }
        }
    }


    /* Timer di inattività; è usato per riportare alla schermata di timeout dopo un tot di tempo di inattività dell'interfaccia
     * (vale a dire, dopo un tot di tempo in cui lo schermo non è toccato da nessuno). Il timer è attivo solo se non si è già
     * nella schermata di timeout, e quando è attivo si riavvia ad ogni touch event ricevuto dall'interfaccia; quindi inizialmente
     * il timer non è attivo */
    Timer {
        id: screenTimeoutTimer
        interval: 300000 //5 minuti
        running: false
        repeat: false
        onTriggered: resetView()
     }

//    Timer {
//        id: videoTimeeer
//        interval: 3000
//        running: true
//        repeat: false
//        onTriggered: resetView()
//     }



    /* Funzione chiamata da C++ dopo la creazione di una nuova ShoeView. Si occupa di connettere la view appena aggiunta (e passata come
     * parametro da C++) agli eventi dell'applicazione, come il timer di inattivià o il view manager. In base al fatto che la view
     * è stata creata in seguito ad un messaggio RFID o meno, la funzione si comporta in modo leggermente diverso.
     * Dopo l'esecuzione di questa funzione apparirà la nuova view */
    function connectNewViewEvents(newShoeView, isFromRFID)
    {
        //Dato che si sta inserendo una nuova ShoeView al momento della chiamata di questa funzione, segno che lo screensaver non
        //è più attivo (nel caso lo fosse stato)
        myViewManager.isScreensaverOn = false;

        //Riavvio il timer che riporta alla schermata di timout
        screenTimeoutTimer.restart();


        /* La ShoeView ha un custom signal chiamato touchEventOccurred che scatta quando l'interfaccia riceve un qualunque Touch
         * input su di essa. Dato che dopo un certo tempo di inattività l'interfaccia deve ritornare alla schermata di partenza,
         * ogni touch event deve riazzerare il timer (se è stato ricevuto un touch event infatti vuol dire che l'interfaccia è
         * attiva).
         * Associo quindi al signal la funzione che si occupa di riazzerare il timer; questa funzione manderà il timer in esecuzione
         * qualora non lo fosse (ad esempio ciò avviene quando è scattato un timer di inattività; in quel caso il timer non è più
         * in esecuzione, ma deve partire non appena l'RFID reader legge qualcosa e viene appunto chiamata la funzione addView()) */
        newShoeView.touchEventOccurred.connect(screenTimeoutTimer.restart);


        //Connetto il signal della ShoeView che indica che bisogna caricare un'altra scarpa al signal di C++
        //che si occupa di inoltrare la richiesta al database in modo asincrono
        newShoeView.needShoeIntoContext.connect(window.requestShoeData)


        //Connetto il signal della view che richiede di filtrare scarpe in base ai filtri scelti con il signal di C++ che si
        //occupa di chiedere al database di effettuare effettivamente la ricerca
        newShoeView.needToFilterShoes.connect(window.requestFilterData)


        //Connetto il signal della ShoeView che indica che bisogna tornare indietro di una view nello stack di view
        newShoeView.goBack.connect(myViewManager.goBack);

        //Connetto il signal per tornare indietro di schermata anche con uno slot C++ che serve a gestire i riferimenti
        //del context della view QML (quello che fa è eliminare il context della view che sta scomparendo)
        newShoeView.goBack.connect(window.movingToPreviousView);


        //Connetto poi il signal della classe C++ che scatta quando è arrivato un messaggio RFID che richiede una scarpa
        //al signal della ShoeView che si occupa di fare i preparativi per riceverla
        window.dataIncomingFromRFID.connect(newShoeView.transitionFromRFIDincoming)


        //Quelle qua sopra erano le cose in comune per tutte le ShoeView. Però alcune cose dipendono dal fatto che la view
        //sia stata creata in seguito ad un messaggio dall'RFID reader  o meno
        if(isFromRFID)
        {
            /* Dato che la nuova view è stata creata creata in seguito ad un messaggio dall'RFID reader, vuol dire che lo stack
             * di view visitate verrà riazzerato, e quindi non sarà consentito tornare indietro di view (la nuova view che
             * si sta' inserendo fungerà quindi da nuovo punto di partenza). Di conseguenza, chiamo il metodo di ShoeView
             * che si occupa di disabilitare il bottone per tornare indietro di schermata */
            newShoeView.disableBackButton()

            //Eseguo la transizione visiva per mostrare la nuova view chiamando il metodo apposito. Tale metodo si occuperà
            //anche di riazzerare lo stack delle view visitate, in modo da ripartire da zero
            myViewManager.showViewFromRFID(newShoeView)
        }
        //Nel caso in cui la view è stata creata in base al click dell'utente su una scarpa, mi limito a mostrare
        //la nuova view con la transizione di default per questo tipo di view
        else
            myViewManager.showView(newShoeView)
    }


    /* Funzione che si occupa di riportare l'interfaccia alla schermata di timeout. Ciò implica che l'history delle view visitate,
     * cioè lo stack di view, si svuota, inserendo esclusivamente la view di timeout fino a quando non si leggono nuovi dati
     * dall'RFID reader */
    function resetView()
    {
        //Carico il componente della view di timeout
        var component = Qt.createComponent("ScreensaverView.qml");

        //Creo una istanza di quel componente mettendola come figlia del view manager
        var newView = component.createObject(myViewManager);

        if(newView == null)
        {
            console.log("C'è stato un errore nell'aggiunta della nuova view");
            return;
        }


        //Connetto il signal di C++ che indica l'arrivo imminente di dati di una scarpa in seguito ad un messaggio RFID al
        //signal della ScreensaverView che si occupa di gestirlo
        window.dataIncomingFromRFID.connect(newView.transitionFromRFIDincoming)


        //Segno che ora la schermata attiva è quella dello screensaver
        myViewManager.isScreensaverOn = true;

        //Salvo il riferimento della nuova ScreensaverView
        myViewManager.currentScreensaverView = newView;

        //Chiamo il metodo del ViewManager che riazzera lo stack di view e che si occupa di eseguire la transizione visiva
        myViewManager.resetToScreensaverView(newView);
    }



    /* Funzione che viene chiamata da C++ quando non è possibile recuperare una data scarpa dal database, riportnado
     * alla schermata principale (da aggiungere: messaggio di errore visivo) */
    function cantLoadShoe()
    {
        //Far si che venga visualizzato un errore migliore del log...
        console.log("Non e' stato possibile caricare la scarpa, merda... Magari non c'è connessione al server?");

        //Riporto alla schermata di timeout, se non era già attiva
        if(!myViewManager.isScreensaverOn)
            resetView();
        else
            myViewManager.currentScreensaverView.errorOccurred();
    }
}
