import QtQuick 2.0
import QtQuick.XmlListModel 2.0


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


        //Inizialmente l'unica schermata presente è quella di timeout, che aspetta di ricevere info dall'RFID reader
        ScreensaverView {
            id: screensaverView
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


    /* Funzione chiamata da C++ dopo la creazione di una nuova ShoeView. Si occupa di connettere la view appena aggiunta (e passata come
     * parametro da C++) agli eventi dell'applicazione, come il timer di inattivià o il view manager.
     * Dopo l'esecuzione di questa funzione apparirà la nuova view */
    function connectNewViewEvents(newView)
    {
        /* La ShoeView ha un custom signal chiamato touchEventOccurred che scatta quando l'interfaccia riceve un qualunque Touch
         * input su di essa. Dato che dopo un certo tempo di inattività l'interfaccia deve ritornare alla schermata di partenza,
         * ogni touch event deve riazzerare il timer (se è stato ricevuto un touch event infatti vuol dire che l'interfaccia è
         * attiva).
         * Associo quindi al signal la funzione che si occupa di riazzerare il timer; questa funzione manderà il timer in esecuzione
         * qualora non lo fosse (ad esempio ciò avviene quando è scattato un timer di inattività; in quel caso il timer non è più
         * in esecuzione, ma deve partire non appena l'RFID reader legge qualcosa e viene appunto chiamata la funzione addView()) */
        newView.touchEventOccurred.connect(screenTimeoutTimer.restart);


        //Connetto il signal della ShoeView che indica che bisogna caricare un'altra scarpa allo slot della classe C++
        //che si occupa di recuperarla e di creare la nuova view
        newView.needShoeIntoContext.connect(window.loadNewShoeView)

        //Connetto il signal della ShoeView che indica che bisogna tornare indietro di una view nello stack di view
        newView.goBack.connect(myViewManager.goBack);


        //Setto inizialmente la visibilità della nuova view su falso
        newView.visible = false;

        //Connetto la visibilità della view con il metodo per gestire i cambi di view
        myViewManager.connectViewEvents(newView, true);

        //Adesso che la view è connessa col gestore, la rendo visibile. Questo farà si che la view corrente sparisca per lasciare
        //spazio alla view appena aggiunta
        newView.visible = true;
    }


    /* Funzione che si occupa di riportare l'interfaccia alla schermata di timeout. Ciò implica che l'history delle view visitate,
     * cioè lo stack di view, si svuota, inserendo esclusivamente la view di timeout fino a quando non si leggono nuovi dati
     * dall'RFID reader*/
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

        newView.visible = false;

        //Chiamo il metodo del ViewManager che riazzera lo stack di view, in modo che rimanga solo la ScreensaverView
        //che si sta per mettere; passo al metodo la ScreensaverView, in modo che venga inserita nell'array
        myViewManager.resetToView(newView);

        //Connetto la visibilità della view con il metodo per gestire i cambi di view
        myViewManager.connectViewEvents(newView, false);

        //Adesso che la view è connessa col gestore, la rendo visibile. Questo farà si che la view corrente sparisca per lasciare
        //spazio alla view appena aggiunta
        newView.visible = true;


        //Mi segno inoltre che ora la schermata attiva è quella dello screensaver
        myViewManager.isScreensaverOn = true;
    }


    function emptyViewStack()
    {

        mainWindow.isScreensaverOn = true;

        myViewManager.emptyViewStack()

        //Connetto la visibilità della view con il metodo per gestire i cambi di view
        myViewManager.connectViewEvents(newView, true);

        //Mi segno inoltre che ora la schermata attiva è quella dello screensaver
        myViewManager.isScreensaverOn = true;
    }


    /* Funzione che viene chiamata da C++ quando non è possibile recuperare una data scarpa dal database, riportnado
     * alla schermata principale (da aggiungere: messaggio di errore visivo) */
    function cantLoadShoe()
    {
        console.log("Non è stato possibile caricare la scarpa, merda...");

        //Riporto alla schermata di timeout, se non era già attiva
        if(!myViewManager.isScreensaverOn)
            resetView();
    }
}
