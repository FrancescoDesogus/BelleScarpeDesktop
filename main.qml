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
        objectName: "myViewManager"

        property Component lastChild;

//        ShoeView {
//            id: showView

//        }

        //Inizialmente l'unica schermata presente è quella di timeout, che aspetta di ricevere info dall'RFID reader
        ScreensaverView {
            id: screensaverView
        }

//        Component.onCompleted: addView()
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


    /* Funzione per aggiungere una view al ViewManager dinamicamente (keyword da cercare su google: Dynamic QML Object Creation from JavaScript).
     * Dopo l'esecuzione del metodo, la nuova view creata diventerà la view visibile.
     * Questa funzione è chiamata da C++ usando il metodo invokeMethod(); è messa quindi in questo file in modo che ci si possa accedere facilmente */
    function addView()
    {
        //Creo il componente; la view deve essere quindi definita in un file a parte, e verrà usata come custom component di qml
        var component = Qt.createComponent("ShoeView.qml");

        //Preso il component, creo una sua istanza e passo come parent il ViewManager, in modo che la nuova view diventi sua figlia
        var newView = component.createObject(myViewManager);

        //Controllo che l'oggetto sia stato creato correttamente
        if(newView == null)
        {
            console.log("C'è stato un errore nell'aggiunta della nuova view");
            return;
        }

        /* La ShoeView ha un custom signal chiamato touchEventOccurred che scatta quando l'interfaccia riceve un qualunque Touch
         * input su di essa. Dato che dopo un certo tempo di inattività l'interfaccia deve ritornare alla schermata di partenza,
         * ogni touch event deve riazzerare il timer (se è stato ricevuto un touch event infatti vuol dire che l'interfaccia è
         * attiva).
         * Associo quindi al signal la funzione che si occupa di riazzerare il timer; questa funzione manderà il timer in esecuzione
         * qualora non lo fosse (ad esempio ciò avviene quando è scattato un timer di inattività; in quel caso il timer non è più
         * in esecuzione, ma deve partire non appena l'RFID reader legge qualcosa e viene appunto chiamata la funzione addView()) */
        newView.touchEventOccurred.connect(screenTimeoutTimer.restart);


        newView.needShoeIntoContext.connect(window.loadShoeIntoContext);


        //Setto inizialmente la visibilità della nuova view su falso
        newView.visible = false;

        //Connetto la visibilità della view con il metodo per gestire i cambi di view
        myViewManager.connectViewEvents(newView);

        //Adesso che la view è connessa col gestore, la rendo visibile. Questo farà si che la view corrente sparisca per lasciare
        //spazio alla view appena aggiunta
        newView.visible = true;
    }


    /* Funzione per aggiungere una view al ViewManager dinamicamente (keyword da cercare su google: Dynamic QML Object Creation from JavaScript).
     * Dopo l'esecuzione del metodo, la nuova view creata diventerà la view visibile.
     * Questa funzione è chiamata da C++ usando il metodo invokeMethod(); è messa quindi in questo file in modo che ci si possa accedere facilmente */
    function prova()
    {
        myViewManager.lastChild.visible = false;

//        myViewManager.lastChild.needShoeIntoContext.connect(window.loadShoeIntoContext);
        myViewManager.lastChild.needShoeIntoContext.connect(function(id) {
            console.log("asdasdsdsadad man");
            window.loadShoeIntoContext(id);
        });


        myViewManager.connectViewEvents(myViewManager.lastChild);

        console.log("ahahahah")


        myViewManager.lastChild.goBack.connect(function() {
            console.log("yo man")
            myViewManager.goBack()
        });

        myViewManager.lastChild.visible = true;
    }


    /* Funzione che si occupa di riportare l'interfaccia alla schermata di timeout. Ciò implica che l'history delle view visitate,
     * cioè lo stack di view, si svuota, inserendo esclusivamente la view di timeout fino a quando non si leggono nuovi dati
     * dall'RFID reader.
     * Il codice della funzione come funzionamento è praticamente identico a quello di addView() */
    function resetView()
    {
        //Carico il componente della view di timeout
        var component = Qt.createComponent("ScreensaverView.qml");

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


        myViewManager.connectViewEvents(newView);

        newView.visible = true;
    }
}
