import QtQuick 2.0

//Importo il file contenente la logica dietro lo stack di view
import "ViewManagerLogic.js" as ViewManagerJs

/* Il ViewManager si occupa di gestire le view che verranno visualizzate nell'applicazione, gestendo la loro visibilità e mettendo
 * transizioni animate quando nuova view vengono visualizzate */
Rectangle {
    id: viewManager
    anchors.fill: parent

    //Mettendo questa proprietà faccio si che quando si crea un oggetto di tipo ViewManager e si mettono al suo interno dei figli, questi
    //diventino figli del viewContainer definito poco più in basso
    default property alias content: viewsContainer.children

    clip: true

    //Questo rectangle conterrà tutte le view che il viewManager gestirà
    Rectangle {
        id: viewsContainer
        anchors.fill: parent
    }


    //Animazione per lo slide verso sinistra per la view corrente, che deve sparire
    PropertyAnimation {
        id: currentViewAnimation
        duration : 500
        property: "x"
        easing.type: Easing.InQuad
        onStopped: target.visible = false; //Quando l'animazione finisce, rendo invisibile il target dell'animazione (cioè la view che deve sparire)
    }


    /* Animazione identica a quella sopra, ma usata quando si torna indietro nello stack di view; in tal caso infatti la view corrente
     * deve sparire definitivamente, non viene salvata. Essendo creata dinamicamente quindi, è meglio distruggerla al termine dell'animazione,
     * altrimenti a lungo andare tutte le view che si accumulano in questo modo potrebbero causare problemi in quanto a performance */
    PropertyAnimation {
        id: currentViewAnimationWithDestruction
        duration : 500
        property: "x"
        easing.type: Easing.InQuad
        onStopped: target.destroy()
    }

    //Animazione per lo slide verso sinistra per la view che deve apparire
    PropertyAnimation {
        id: nextViewAnimation
        duration : 500
        property: "x"
        easing.type: Easing.InQuad
    }


    //Quando TUTTI i componenti qml sono stati creati, scatta questo metodo. Quello che faccio è connettere la visibilità di ogni view dichiarata
    //come figlia del viewManager (e quindi che questo gestirà) con il metodo che si occuperà di fare le transizioni tra view
    Component.onCompleted: {
        //Prendo tutti i figli dichiarati
        var views = viewsContainer.children;

        //Se ce ne sono procedi, altrimenti non faccio niente (nel nostro caso una view iniziale c'è sempre, ma è per generalizzare)
        if(views.length > 0)
        {
            //Setto come view corrente la prima view dichiarata
            ViewManagerJs.currentView = views[0];

            var view;

            //Scorro tutte le view
            for(var i = 0; i < views.length; i++)
            {
                view = views[i]

                //Se la view è la prima, la rendo visibile, altrimenti invisibile
                view.visible = (i == 0);

                //Connetto la view al signal per quando la sua visibilità cambia
                connectViewEvents(view);
            }
        }
    }

    /* Questa funzione connette il signal per la visiblità cambiata di una view con la funzione che si occupa
     * di effettuare una transizione visiva; la funzione è messa qua e non in ViewManagerJs.js perchè deve
     * essere accessibile dall'esterno */
    function connectViewEvents(view)
    {
        //Quando la visibilità cambierà, scatterà il metodo showView() che gestirà il cambiamento di visibilità della view
        view.visibleChanged.connect(function() {
            ViewManagerJs.showView(view);
        });
    }

    /* Funzione che si occupa di tornare indietro di una view nello stack; la funzione è messa qua e non
     * in ViewManagerJs.js perchè deve essere accessibile dall'esterno */
    function goBack()
    {
        ViewManagerJs.goBack();
    }

    /* Funzione che si occupa di svuotare l'array contenente l'history delle view visitate per inserirci esclusivamente
     * la ScreensaverView. Il parametro newView è la ScreensaverView che dovrà essere mostrata */
    function resetToView(newView)
    {
        ViewManagerJs.reset(newView);
    }
}
