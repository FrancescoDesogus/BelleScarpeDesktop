
//Variabile globale che contiene la view correntemente mostrata
var currentView;

//Variabile globale che contiene lo stack delle view precedentemente viste. Tutte le view contenute nell'array NON saranno visibili.
//La view correntemente visibile non è infatti presente nell'array
var viewHistory = new Array();


/*
 * FUNZIONE ATTUALMENTE NON PIU' IN USO - era usata nella versione precedente del view manager
 *
 * Questa funzione viene chiamata quando una view cambia visibilità. In un dato momento solo una view può essere visibile,
 * quindi quando una view cambia visibilità (cioè diventa invisibile), un'altra diventa visibile. Questo porta ad una transizione,
 * terminata la quale la view che era precedentente mosrata deve scomparire, causando una ulteriore chiamata a questo
 * metodo in quanto la sua visibilità cambia. */
function showViewNotUsed(nextView)
{
    /* Quando una view diventa visibile, la view precedentemente visibile scompare, causando anch'essa una chiamata a questa funzione;
     * quando ciò accade però, la funzione non deve fare nulla, in quanto la view che deve scomparire deve semplicemente
     * diventare invisibile, senza fare altro (la view diventa invisibile solo al termine dell'animazione, come definito nell'apposita
     * animazione in ViewManager.qml) */
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

        /* Adesso devo preparare le animazioni. Se la view da mostrare è nuova, posiziono la view all'estremo destro del viewManager
         * (che è grande quanto la view che lo contiene; nel nostro caso tutto lo schermo). Se invece la view da mostrare era una
         * view presa dallo stack, moltiplico la larghezza per -1 per posizionare la view a sinistra dello schermo, visto che
         * la transizione sarà "al contrario" */
        nextView.x = viewManager.width * (isPreviousView ? -1 : 1);

        //Se le animazioni erano già in atto (cioè se si sta cambiando view mentre c'era un cambiamento già in atto),
        //le completo per poi riniziarle
        if(currentViewAnimation.running)
            currentViewAnimation.complete();

        if(currentViewAnimationWithDestruction.running)
            currentViewAnimationWithDestruction.complete();

        if(nextViewAnimation.running)
            nextViewAnimation.complete();


        if(!isPreviousView)
        {
            //Setto come target dell'animazione per la view che deve scomparire la view corrente, e la sposto fino all'estremo destro
            // se la view1 da mostrare proveniva dallo stack, altrimento all'estremo sinistro. Fatto ciò, avvio l'animazione
            currentViewAnimation.target = currentView;
            currentViewAnimation.to = viewManager.width * (isPreviousView ? 1 : -1);
            currentViewAnimation.running = true;
        }
        else
        {
            /* Stessa cosa di sopra, solo che se si sta tornando indietro ad una view precedente, la view attuale deve scomparire
             * definitivamente dalla memoria; chiamo quindi questa versione dell'animazione che distrugge la view al termine,
             * invece di renderla solo invisibile */
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


/* Questa funzione si occupa di mostrare la view passatagli come parametro con una "spinning transition". E'
 * usata come transizione di default per quando si cambia schermata in seguito al click dell'user su una scarpa
 * diversa da quella attualmente visualizzata.
 * La view DEVE essere una ShoeView contenente un riferimento alla FlipableSurface che ha fatto scattare l'evento */
function showView(nextView)
{
    /* Dato che l'animazione è usata per passare da una ShoeView ad un'altra ShoeView, assumo che la currentView sia sempre
     * una ShoeView. Di conseguenza recupero la FlipableSurface che è stata clickata dall'utente e assegno come "back"
     * la nuova view da mostrare. Il "front" è già impostato ed è la parte della currentView che ha scatenato l'evento */
    currentView.flipableSurface.back = nextView

    /* Settato il "back" del flipable, chiamo il metodo per far partire l'animazione. E' infatti la FlipableSurface stessa
     * a gestire l'animazione, in quanto deve far riferimento ad elementi definiti nella FlipableSurface stessa ed inserire
     * le animazioni nel ViewManager.qml sarebbe stato macchinoso.
     * Terminata l'animazione, la currentView diventerà invisibile */
    currentView.flipableSurface.flip()

    //Avviata l'animazione, inserisco la view corrente nello stack di view visitate, in modo che sia possibile tornare indietro
    viewHistory.push(currentView);

    //Terminato tutto, la view corrente diventa quindi la view che ora comparirà
    currentView = nextView;
}


/* Funzione chiamata quando è stato ricevuto un messaggio dall'RFID reader e bisogna mostrare una nuova view; quello che fa
 * è riazzeare lo stack di view visitate e mostrare l'animazione di transizione per la nuova view */
function showViewFromRFID(nextView)
{
    //Chiamo la funzione per resetare lo stack di view
    emptyViewStack()

    /* Per avviare l'animazione di transizione per le nuove ShoeView create in seguito ad un messaggio RFID, bisogna passare
     * all'animazione la view corrente (che deve scomparire), la nuova view (che deve apparire) e gli elementi Rotation
     * contenuti nella proprietà "transform" di ciascuna delle due view.
     * Per recuperare le Rotation accedo alla lista di di transform applicate alle view e recupero la prima, che so essere
     * la Rotation che mi interessa.
     * NOTA: la currentView a questo punto può essere una ScreensaverView o una ShoeView; entrambe devono avere questa
     * Rotation definita tra le "transform" nel loro rispettivo file QML */
    rfidTransition.currentViewContainer = currentView
    rfidTransition.currentViewRotationTransform = currentView.transform[0]

    //Stessa cosa di sopra per la nuova view da mostrare
    rfidTransition.nextViewContainer = nextView
    rfidTransition.nextViewRotationTransform = nextView.transform[0]

    //Se c'animazioni erano già in atto (cioè se si sta cambiando view mentre c'era un cambiamento già in atto), le completo
    if(currentViewAnimationWithDestruction.running)
        currentViewAnimationWithDestruction.complete();

    if(nextViewAnimation.running)
        nextViewAnimation.complete();

    //Per assicurarmi che la nuova view non si piazzi subito sopra la vecchia che deve scomparire, metto la z della view corrente
    //uno step sopra la nuova in modo che appaia sopra durante l'animazione
    nextView.z = 0
    currentView.z = 1;

    //Eseguo quindi l'animazione
    rfidTransition.start();


    //Terminato tutto, la view corrente diventa quindi la view che ora comparirà
    currentView = nextView;
}


/* Funzione che si occupa di tornare indietro di una view nello stack */
function goBack()
{
    //Se c'è una view da cui tornare indietro procedo, altrimenti non faccio nulla; in realtà questo è controllato da fuori
    //prima di chiamare questa funzione, ma per sicurezza controllo anche qua
    if(viewHistory.length > 0)
    {
        //Rimuovo l'ultima view presente nell'history e la recupero
        var oldView = viewHistory.pop();

        /* La view precedente è per forza una ShoeView, dato che non è permesso tornare indietro da altre view che non lo siano;
         * di conseguenza la view precedente è stata cambiata con una transizione stile flipable. Quindi la vecchia view contiene
         * il "front" del flipable che l'ha fatta cambiare, per cui devo rimostrare rifar comparire quel front e la view stessa
         * con l'animazione presente in FlipableSurface. Recupero quindi la surface e chiamo il metodo apposito che farà
         * la transizione al contrario; al termine della transizione, la currentView attuale (che deve sparire) verrà
         * distrutta per salvare memoria */
        oldView.flipableSurface.reflip()

        //Adesso quindi la view attualmente visibile diventa quella appena pescata dall'history
        currentView = oldView;
    }
}



/* Funzione che si occupa di svuotare l'array contenente l'history delle view visitate e che visualizza la view di timeout
 * eseguendo una transizione visiva */
function resetToView(nextView)
{
    //Chiamo la funzione per resetare lo stack di view
    emptyViewStack();

    //Preparo la view correntemente visualizzata per muoversi verso destra con l'animazione apposita. Terminato lo spostamento,
    //la vecchia view si distruggerà
    currentViewAnimationWithDestruction.target = currentView;
    currentViewAnimationWithDestruction.to = viewManager.width;
    currentViewAnimationWithDestruction.running = true;


    //Preparo la nuova view per eseguire un'animazione di slide verso sinistra. La nuova view dovrà stare a sinistra della view corrente
    nextView.x = viewManager.width * (-1)

    //Animazione per la view da mostrare
    nextViewAnimation.target = nextView;
    nextViewAnimation.to = 0;
    nextViewAnimation.running = true;


    //Terminato tutto, la view corrente diventa quindi la view che ora comparirà
    currentView = nextView;
}

/* Funzione per resetare lo stack di view */
function emptyViewStack()
{
    /* Quello che bisogna fare è scorrere tutto l'array dell'history e distruggere ogni view presente, per salvare memoria. A furia
     * di fare prove però, mi è capitato un rarissimo bug in cui l'array conteneva elementi ma questi non erano view, o comunque
     * non era possibile distruggerle (non son riuscito a capire a cosa è dovuto e quando capita); quando il bug appariva,
     * le view venivano mostrate ma non funzionavano correttamente. Per evitare problemi, eseguo la distruzione in un try-catch che
     *  ho visto che è in grado di gestire l'errore.
     * Se e quando questo errore capita, mi limito quindi a riazzerare l'array senza distruggere le view (che presumibilmente sono
     * pochissime e non occupano niente spazio in memoria, quindi not a big deal) */
    try
    {
        for(var i = 0; i < viewHistory.length; i++)
            viewHistory[i].destroy();
    }
    catch(error)
    {
        console.log("ViewManagerLogic.js::emptyViewStack() error destroying views: " + error)
    }

    //Sia in caso di errori che in caso di successo, svuoto l'array e vado avanti
    viewHistory.length = 0;
}


/* Funzione che si occupa di salvare il riferimento alla prima view visibile nell'applicazione */
function setStartingView(startingView)
{
    currentView = startingView
}
