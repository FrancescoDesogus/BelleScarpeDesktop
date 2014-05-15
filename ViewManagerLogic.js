//Variabile globale che contiene la view correntemente mostrata
var currentView;

//Variabile globale che contiene lo stack delle view precedentemente viste. Tutte le view contenute nell'array NON saranno visibili.
//La view correntemente visibile non è infatti presente nell'array
var viewHistory = new Array();


/* Questo metodo viene chiamato quando una view cambia visibilità. In un dato momento solo una view può essere visibile, quindi quando una view
 * cambia visibilità (cioè diventa invisibile), un'altra diventa visibile. Questo porta ad una transizione, terminata la quale la view che era
 * precedentente mosrata deve scomparire, causando una ulteriore chiamata a questo metodo in quanto la sua visibilità cambia. */
function showView(nextView)
{
    /* Quando una view diventa visibile, la view precedentemente visibile diventa scompare, causando anch'essa una chiamata a questa funzione;
     * quando ciò accade però, la funzione non deve fare nulla, in quanto la view che deve scomparire deve semplicemente diventare invisibile,
     * senza fare altro (la view diventa invisibile solo al termine dell'animazione, come definito nell'apposita animazione in ViewManager.qml) */
    if(nextView.visible)
    {
        //La view che deve diventare visibile potrebbe essere la view precedente dello stack, quindi devo controllare
        var isPreviousView = false;

        var arraySize = viewHistory.length;

        //Controllo quindi se la view da mostrare è uguale all'ultima view contenuta nello stack
        if(arraySize > 0 && viewHistory[arraySize - 1] == nextView)
        {
            //Se lo è, lo segnalo con un booleano...
            isPreviousView = true;

            //...e tolgo l'ultima view dallo stack, dato che ora diventerà visibile
            viewHistory.pop();
        }

        /* Adesso devo preparare le animazioni. Se la view da mostrare è nuova, posiziono la view all'estremo destro del viewManager (che è
         * grande quanto la view che lo contiene; nel nostro caso tutto lo schermo). Se invece la view da mostrare era una view presa dallo stack,
         * moltiplico la larghezza per -1 per posizionare la view a sinistra dello schermo, visto che la transizione sarà "al contrario" */
        nextView.x = viewManager.width * (isPreviousView ? -1 : 1);

        //Se le animazioni erano già in atto (cioè se si sta cambiando view mentre c'era un cambiamento già in atto), le completo per poi riniziarle
        if(currentViewAnimation.running)
            currentViewAnimation.complete();

        if(currentViewAnimationWithDestruction.running)
            currentViewAnimationWithDestruction.complete();

        if(nextViewAnimation.running)
            nextViewAnimation.complete();


        if(!isPreviousView)
        {
            //Setto come target dell'animazione per la view che deve scomparire la view corrente, e la sposto fino all'estremo destro se la view1
            //da mostrare proveniva dallo stack, altrimento all'estremo sinistro. Fatto ciò, avvio l'animazione
            currentViewAnimation.target = currentView;
            currentViewAnimation.to = viewManager.width * (isPreviousView ? 1 : -1);
            currentViewAnimation.running = true;
        }
        else
        {
            //Stessa cosa di sopra, solo che se si sta tornando indietro ad una view precedente, la view attuale deve scomparire definitivamente
            //dalla memoria; chiamo quindi questa versione dell'animazione che distrugge la view al termine, invece di renderla solo invisibile
            currentViewAnimationWithDestruction.target = currentView;
            currentViewAnimationWithDestruction.to = viewManager.width * (isPreviousView ? 1 : -1);
            currentViewAnimationWithDestruction.running = true;
        }

        //Animazione per la view da mostrare
        nextViewAnimation.target = nextView;
        nextViewAnimation.to = 0;
        nextViewAnimation.running = true;


        //Adesso currentView non è più visibile, quindi la devo inserire nello stack, ma solo se nextView non proveniva dallo stack
        //(infatti in tal caso è stata appena rimossa dallo stack, quindi non bisogna rimettercela)
        if(currentView && !isPreviousView)
            viewHistory.push(currentView);

        //Terminato tutto, la view corrente diventa quindi la view che ora comparirà
        currentView = nextView;
    }
}


function showViewFlipable(nextView)
{
    /* Quando una view diventa visibile, la view precedentemente visibile diventa scompare, causando anch'essa una chiamata a questa funzione;
     * quando ciò accade però, la funzione non deve fare nulla, in quanto la view che deve scomparire deve semplicemente diventare invisibile,
     * senza fare altro (la view diventa invisibile solo al termine dell'animazione, come definito nell'apposita animazione in ViewManager.qml) */
    if(nextView.visible)
    {
//        viewsContainer.back = nextView;
//        viewsContainer.front = currentView;
        flipableBack.nextView = nextView
        flipableFront.currentView = currentView

        viewsContainer.state = "flip"


//        currentView.transformOrigin = Item.Top
//        nextView.transformOrigin = Item.Bottom

//        lol.angle = currentView.rotation;
//        boh.angle = nextView.rotation;

//        viewsContainer.currentView = currentView
//        viewsContainer.nextView = nextView

//        viewManager.state = "flip"




//        /* Adesso devo preparare le animazioni. Se la view da mostrare è nuova, posiziono la view all'estremo destro del viewManager (che è
//         * grande quanto la view che lo contiene; nel nostro caso tutto lo schermo). Se invece la view da mostrare era una view presa dallo stack,
//         * moltiplico la larghezza per -1 per posizionare la view a sinistra dello schermo, visto che la transizione sarà "al contrario" */
//        nextView.x = viewManager.width * (isPreviousView ? -1 : 1);

//        //Se le animazioni erano già in atto (cioè se si sta cambiando view mentre c'era un cambiamento già in atto), le completo per poi riniziarle
//        if(currentViewAnimation.running)
//            currentViewAnimation.complete();

//        if(currentViewAnimationWithDestruction.running)
//            currentViewAnimationWithDestruction.complete();

//        if(nextViewAnimation.running)
//            nextViewAnimation.complete();


//        if(!isPreviousView)
//        {
//            //Setto come target dell'animazione per la view che deve scomparire la view corrente, e la sposto fino all'estremo destro se la view1
//            //da mostrare proveniva dallo stack, altrimento all'estremo sinistro. Fatto ciò, avvio l'animazione
//            currentViewAnimation.target = currentView;
//            currentViewAnimation.to = viewManager.width * (isPreviousView ? 1 : -1);
//            currentViewAnimation.running = true;
//        }
//        else
//        {
//            //Stessa cosa di sopra, solo che se si sta tornando indietro ad una view precedente, la view attuale deve scomparire definitivamente
//            //dalla memoria; chiamo quindi questa versione dell'animazione che distrugge la view al termine, invece di renderla solo invisibile
//            currentViewAnimationWithDestruction.target = currentView;
//            currentViewAnimationWithDestruction.to = viewManager.width * (isPreviousView ? 1 : -1);
//            currentViewAnimationWithDestruction.running = true;
//        }

//        //Animazione per la view da mostrare
//        nextViewAnimation.target = nextView;
//        nextViewAnimation.to = 0;
//        nextViewAnimation.running = true;


        //Adesso currentView non è più visibile, quindi la devo inserire nello stack, ma solo se nextView non proveniva dallo stack
        //(infatti in tal caso è stata appena rimossa dallo stack, quindi non bisogna rimettercela)
//        if(currentView && !isPreviousView)
//            viewHistory.push(currentView);

        //Terminato tutto, la view corrente diventa quindi la view che ora comparirà
        currentView = nextView;
    }
}


/* Funzione che si occupa di tornare indietro di una view nello stack */
function goBack()
{
    //Prendo l'indice dell'ultima view contenuta nello stack, che dovrà essere mostrata
    var last = viewHistory.length - 1;

    //Se c'è una view da cui tornare indietro procedo, altrimenti non faccio nulla
    if(last >= 0)
    {
        //Prendo l'ultima view
        var nextView = viewHistory[last];

        //...e la rendo visibile. Ciò implica una chiamata a showView(), che farà si che la view si visualizzi con una transizione.
        //Dopo l'esecuzione di quella funzione, l'array delle view perderà quindi l'ultimo elemento
        nextView.visible = true;
    }
}

/* Funzione che si occupa di svuotare l'array contenente l'history delle view visitate per inserirci esclusivamente
 * la ScreensaverView. Il parametro newView è la ScreensaverView che dovrà essere mostrata */
function reset(newView)
{
    //Dato che devo svuotare l'array, lo scorro per recuperare tutte le view in esso contenuto in modo da distruggerle
    //per liberare risorse. Nota: cancello tutte tranne l'ultima, che serve ancora in vita per fare la transazione visiva
    for(var i = 0; i < viewHistory.length - 1; i++)
        viewHistory[i].destroy();

    //Svuoto l'array
    viewHistory.length = 0;

    /* Inserisco esclusivamente la nuova view (la ScreensaverView) nell'array; lo faccio in modo tale che quando la view diventerà
     * visibile e la funzione showView() venga eseguita, la ScreensaverView appaia nell'array dell'history provocando una transizione
     * stile "goBack()" dato che crederà che si sta semplicemente transizionando indietro di una view.
     * In questo momento, currentView conterrà l'ultima view visualizzata, che dovrà scomparire */
    viewHistory.push(newView)
}


function emptyViewStack()
{
    //Dato che devo svuotare l'array, lo scorro per recuperare tutte le view in esso contenuto in modo da distruggerle
    //per liberare risorse
    for(var i = 0; i < viewHistory.length; i++)
        viewHistory[i].destroy();

    //Svuoto l'array
    viewHistory.length = 0;

    /* Inserisco esclusivamente la nuova view (la ScreensaverView) nell'array; lo faccio in modo tale che quando la view diventerà
     * visibile e la funzione showView() venga eseguita, la ScreensaverView appaia nell'array dell'history provocando una transizione
     * stile "goBack()" dato che crederà che si sta semplicemente transizionando indietro di una view.
     * In questo momento, currentView conterrà l'ultima view visualizzata, che dovrà scomparire */
//    viewHistory.push(newView)
}

