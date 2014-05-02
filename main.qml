import QtQuick 2.0
import QtQuick.XmlListModel 2.0

Rectangle {
    id: mainWindow
    width: 1920 * scaleX
    height: 1080 * scaleY


    //I figli del ViewManager sono gestiti dallo stesso. Uno solo dei figli può essere visibili in un dato momento
    ViewManager {
        id: myViewManager
        objectName: "myViewManager"

        ShoeView {
            id: showView

        }

    }

    /* Funzione per aggiungere una view al ViewManager dinamicamente (keyword da cercare su google: Dynamic QML Object Creation from JavaScript).
     * Dopo l'esecuzione del metodo, la nuova view creata diventerà la view visibile.
     * Questa funzione è chiamata da c++ usando il metodo invokeMethod(); è messa quindi in questo file in modo che ci si possa accedere facilmente */
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

        //Setto inizialmente la visibilità della nuova view su falso
        newView.visible = false;

        //Connetto la visibilità della view con il metodo per gestire i cambi di view
        myViewManager.connectViewEvents(newView);

        //Adesso che la view è connessa col gestore, la rendo visibile. Questo farà si che la view corrente sparisca per lasciare
        //spazio alla view appena aggiunta
        newView.visible = true;
    }

}
