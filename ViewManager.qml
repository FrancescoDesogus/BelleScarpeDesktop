import QtQuick 2.0

//Importo il file contenente la logica dietro lo stack di view
import "ViewManagerLogic.js" as ViewManagerJs

/* Il ViewManager si occupa di gestire le view che verranno visualizzate nell'applicazione, gestendo la loro visibilità e mettendo
 * transizioni animate quando nuova view vengono visualizzate */
Rectangle {
    id: viewManager
    anchors.fill: parent

    //Mettendo questa proprietà faccio si che quando si crea un oggetto di tipo ViewManager e si mettono al suo interno dei figli,
    //questi diventino figli del viewContainer definito poco più in basso
    default property alias content: viewsContainer.children

    clip: true

    Rectangle {
        id: flipableFront

        property Item currentView;
    }

   Rectangle {
        id: flipableBack

        property Item nextView;
    }

    //Questo rectangle conterrà tutte le view che il viewManager gestirà
    Flipable {
        id: viewsContainer
        anchors.fill: parent


        front: flipableFront

        back: flipableBack

        transform: Rotation {
             id: rotation
             origin.x: viewsContainer.width/2
             origin.y: viewsContainer.height/2
             axis.x: 0; axis.y: 1; axis.z: 0     // set axis.y to 1 to rotate around y-axis
             angle: 0    // the default angle
        }

        states: State {
             name: "flip"
             PropertyChanges { target: rotation; angle: -180 }
//             when: flipable.flipped
         }

         transitions: Transition {
             NumberAnimation { target: rotation; property: "angle"; duration: 1500 }
         }



        property Item currentView;
        property Item nextView;
    }

    Rotation { id: lol; origin.x: 0; origin.y: 0; axis {x:1; y:0; z:0} }
    Rotation { id: boh; origin.x: 0; origin.y: 0; axis {x:1; y:0; z:0} }


//    Component.onCompleted: {
//        lol.angle = currentView.angle
//    }

//    Timer {
//         interval: 30
//         running: true
//         repeat: true
//         onTriggered: {
//             myText.xAngle = myText.xAngle + 1;
//             myText.yAngle = myText.yAngle + 1.5;
//             myText.zAngle = myText.zAngle + 2.5
//         }
//    }


    states: State {
        name: "flip"

        PropertyChanges {
            target: viewsContainer.currentView;

//            transformOrigin: Item.Left

            transform: lol


//            transform: [
//                Rotation { origin.x: 300; origin.y: 80; axis {x:1; y:0; z:0} angle:myText.xAngle },
//                Rotation { origin.x: 300; origin.y: 80; axis {x:0; y:1; z:0} angle:myText.yAngle },
//                Rotation { origin.x: 300; origin.y: 80; axis {x:0; y:0; z:1} angle:myText.zAngle }
//            ]
        }

        PropertyChanges {
            target: viewsContainer.nextView;

            transformOrigin: Item.Left

            transform: boh
        }
    }

    property double xAngle: 0
    property double yAngle: 0
    property double zAngle: 0


//    Text {
//         id: myText
//         text: "Rotation"; font.pointSize: 100; color: "red"; x: 150; y: 100


//    }
//    Timer {
//         interval: 30
//         running: true
//         repeat: true
//         onTriggered: {
//             myText.xAngle = myText.xAngle + 1;
//             myText.yAngle = myText.yAngle + 1.5;
//             myText.zAngle = myText.zAngle + 2.5
//         }
//    }



    //Per avere un'animazione tra i cambi di stato creo delle transizioni
    transitions: [
        //Transizione per quando si passa dallo stato invisible allo stato visible
        Transition {
            from: "*"
            to: "flip"


            SequentialAnimation {
                 PropertyAction {
                     targets: viewsContainer.currentView, viewsContainer.nextView;
                     property: "transformOrigin, transform"
                 }

                 //Per l'immagine si hanno 2 animazioni in contemporanea, quindi ci vuole una ParallelAnimation
                 ParallelAnimation {

                     //Animazione per l'opacità
                     NumberAnimation {
                         /* Il target dell'animazione è il currentItem; per questo è importante che prima del cambiamento di stato
                          * sia settato correttamente il currentIndex con quello dell'immagine da mostrare, in modo che il
                          * currentItem sia effettivamente aggiornato */
                         target: viewsContainer.currentView

                         properties: "rotation"
                         duration: 1500

                         from: 0
                         to: 180
//                         properties: "scale"
//                         duration: 3000

//                         from: 1
//                         to: 0
                     }

                     //Animazione per il movimento sull'asse y
                     NumberAnimation {
                         target: viewsContainer.nextView

                         properties: "rotation"
                         duration: 1500

                         from: -180
                         to: 0

//                         properties: "scale"
//                         duration: 1500

//                         from: 0
//                         to: 1
                     }
                  }
             }


        }]

    ParallelAnimation {

        id: currentView



         NumberAnimation {
             id: prova1

             properties: "scale";
             from: 1;
             duration: 0
         }

         onStopped: target.visible = false;
    }

    ParallelAnimation {

        id: nextView



         NumberAnimation {
             id: prova2

             properties: "scale";
             from: 0;
             duration: 1
         }
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
    function connectViewEvents(view, isFlipable)
    {
        if(!isFlipable)
            //Quando la visibilità cambierà, scatterà il metodo showView() che gestirà il cambiamento di visibilità della view
            view.visibleChanged.connect(function() {
                ViewManagerJs.showView(view);
            });
        else
            view.visibleChanged.connect(function() {
                ViewManagerJs.showViewFlipable(view);
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

    function emptyViewStack()
    {
        ViewManagerJs.emptyViewStack();
    }
}
