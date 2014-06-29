#include "windowmanager.h"


#include <QQuickView>
#include <QWindow>

#include <QRect>
#include <QDesktopWidget>

#include <QApplication>

#include <QtDeclarative/QDeclarativeView>

#include <QDebug>
#include <QThread>
#include <QQmlContext>

#include <QQmlEngine>

#include <QQmlComponent>
#include <QTimer>
#include <QQuickItem>


#include <shoedatabase.h>
#include <shoe.h>
#include <serialreaderthread.h>
#include <databaseinterface.h>
#include <arduino.h>

#include <vector>
#include <QVariant>
#include <QDir>

#include <QDeclarativeEngine>

//Dato che uso il "vector" di C++, utilizzo il namespace std come scorciatoia invece di scrivere "std::vector"
using namespace std;


//Costanti che definiscono le dimensioni della risoluzione target dell'applicazione
const int WindowManager::TARGET_RESOLUTION_WIDTH = 1920;
const int WindowManager::TARGET_RESOLUTION_HEIGHT = 1080;


WindowManager::WindowManager(QQuickView *parent) :
    QQuickView(parent)
{

}

/**
 * @brief WindowManager::setupScreen è un metodo che si occupa di inizializzare tutto il necessario per l'applicazione
 */
void WindowManager::setupScreen()
{
    //Chiamo rispettivamente il metodo interno che si occupa di creare il thread che recupera i dati delle scarpe in modo
    //asincrono ed il metodo per creare il thread che gestisce la porta seriale dell'RFID reader (se è attaccato)
    this->setupDataThread();
    this->setupRFIDThread();


    QQmlContext* rootContext = this->rootContext();

    /* Aggiungo al contesto dell'engine qml una proprietà che corrisponde all'istanza di questa classe. In questo modo nei file qml
     * che si chiameranno sarà nota la proprietà "firstWindow", e si potranno chiamare i metodi definiti Q_INVOKABLE nell'header
     * della classe, oltre che i membri definiti con Q_PROPERTY (in questo caso però di questi non ce ne sono) */
    rootContext->setContextProperty("window", this);


    //Inserisco come proprietà le informazioni sulla risoluzione target da usare
    rootContext->setContextProperty("TARGET_RESOLUTION_WIDTH", TARGET_RESOLUTION_WIDTH);
    rootContext->setContextProperty("TARGET_RESOLUTION_HEIGHT", TARGET_RESOLUTION_HEIGHT);


    //Recupero informazioni sulla grandezza dello schermo vera e propria, in modo da visualizzare la view in fullscreen correttamente
    QDesktopWidget desktopWidget;
    QRect mainScreenSize = desktopWidget.screenGeometry(desktopWidget.primaryScreen());


    /* Definisco nel contesto dell'engine qml altre due proprietà, che sono i valori per cui bisogna moltiplicare ogni coordinata di larghezza
     * e altezza presente nei file qml in modo tale che le posizioni e le grandezze degli oggetti scalino bene su tutti i monitor.
     * Come risoluzione target si usa 1920x1080 */
    rootContext->setContextProperty("scaleX", (qreal) mainScreenSize.width() / TARGET_RESOLUTION_WIDTH);
    rootContext->setContextProperty("scaleY", (qreal) mainScreenSize.height() / TARGET_RESOLUTION_HEIGHT);


    //Carico il file base
    this->setSource(QUrl("qrc:/qml/main.qml"));


    //Con questa chiamata l'elemento root del file QML otterrà la stessa grandezza della finestra in cui sta. Così facendo
    //posso mettere la finestra in fullscreen e la parte fatta in QML si adatterà automaticamente
    this->setResizeMode(QQuickView::SizeRootObjectToView);


    //Una volta mandato a tutto schermo, controllo se ci sono più monitor attaccati; nel caso sposto la finestra nel secondo
    if(desktopWidget.screenCount() > 1)
    {
        /* Recupero le informazioni sul secondo screen attaccato; il rettangolo ritornato avrà coordinate che partono da subito
         * dopo il primo schermo e avrà dimensioni pari a quelle del secondo schermo. Se ad esempio il secondo schermo ha
         * dimensioni 1920x1080 ed il primo 1366x768, il rettangolo restituito avrà il punto in alto a sinistra alle
         * coordinate (1366, 0) (cioè subito dopo il primo schermo) e dimensioni 1920x1080 */
        QRect secondaryScreenGeometry = desktopWidget.screenGeometry(1);

        //Sposto la view nel rettangolo recuperato
        this->setGeometry(secondaryScreenGeometry);
    }


    /* Mando in esecuzione a tutto schermo; è importante farlo dopo l'eventuale switch di schermi, altrimenti la view diventa
     * fullscreen con dimensioni basate sul primo schermo; se ad esempio il primo schermo fosse più piccolo del secondo,
     * la view apparirebbe nel secondo schermo ma con le dimensioni del primo schermo invece che con quelle del secondo */
    this->showFullScreen();


    //Appena avviato carico una scarpa per provare, simulando l'arrivo di un codice RFID
    emit requestShoeData("asd");
}

/**
 * @brief WindowManager::setupDataThread è un metodo chiamato da setupScreen() che si occupa di creare il thread che recupera
 *        i dati dal database e di eseguire le connessioni di signal e slot che servono a far si che le richieste dei dati da
 *        parte del main thread, il recupero dei dati dal thread del database ed il conseguente passaggio di dati dal secondo
 *        thread a quello principale avvengano in modo asincrono
 */
void WindowManager::setupDataThread()
{
    //Creo l'istanza del thread
    QThread* dataThread = new QThread(this);


    /* Sposto quello che nel gergo di Qt viene detto "work thread object" nel thread. In questo modo l'istanza della classe
     * DatabaseInterface vivrà all'interno di quel thread. D'ora in avanti, se connetto un signal del thread principale
     * ad uno slot dell'oggetto databaseInterface, quest slot verrà eseguito nell'altro thread */
    databaseInterface.moveToThread(dataThread);

    //Connetto il signal che dichiara l'inizio dell'esecuzione dle thread con lo slot dell'interfaccia che si occupa di
    //inizializzare il database. In questo modo mi assicuro che la connessione con il db avvenga nel nuovo thread
    QObject::connect(dataThread, SIGNAL(started()), &databaseInterface, SLOT(initDatabase()));


    //Connetto la chiusura dell'applicazione con lo stop del thread, in modo che si blocchi se l'applicazione si chiude
    QObject::connect(this, SIGNAL(destroyed()), dataThread, SLOT(quit()));

    /* Connetto tutti i segnali di richiesta di dati ai corrispettivi slot dell'oggetto che funge da interfaccia tra il thread
     * principale ed il database. Registro quindi:
     * 1) il segnale per caricare i filtri delle scarpe (cioè i dati riguardanti tutte le marche presenti nel db,
     *    tutte le categorie, colori, ecc. Dato che c'è bisogno di questi dati subito, e dato che sono
     *    uguali per ogni schermata, questo segnale verrà emesso una sola volta all'inizio dell'applicazione;
     * 2) il segnale che richiede i dati di una scarpa in seguito all'arrivo di un codice RFID;
     * 3) il segnale che richiede i dati di una scarpa in seguito ad un input utente;
     * 4) il segnale che richiede di filtrare le scarpe in base ai dati passati. */
    QObject::connect(this, SIGNAL(requestFilters()), &databaseInterface, SLOT(loadFilters()));
    QObject::connect(this, SIGNAL(requestShoeData(QString)), &databaseInterface, SLOT(loadShoeData(QString)));
    QObject::connect(this, SIGNAL(requestShoeData(int)), &databaseInterface, SLOT(loadShoeData(int)));
    QObject::connect(this, SIGNAL(requestFilterData(QVariant,QVariant,QVariant,QVariant,QVariant,int,int)), &databaseInterface, SLOT(loadFilterData(QVariant,QVariant,QVariant,QVariant,QVariant,int,int)));

    /* Connetto anche una chain di signal tra la classe stessa; il signal che causa l'evento è la richiesta di una scarpa in
     * seguito ad un messaggio RFID. Il signal che viene chiamato serve a notificare QML che è sta per arrivare una scarpa.
     * E' un po' ridondante la cosa, ma non è possibile usare il signal requestShoeData(), che ha una parametro, con uno slot QML
     * che non ne ha (in QML non servirebbe prendere il codice RFID ricevuto infatti); è invece possibile collegare un signal
     * che ha una parametro con uno che non ne ha. In questo in QML posso ascoltare il signal che non prende parametri e collegarci
     * slot (che in QML sono normali funzioni) che non ne ricevono */
    QObject::connect(this, SIGNAL(requestShoeData(QString)), this, SIGNAL(dataIncomingFromRFID()));


    /* Nelle Qt  signal e slot funzionano di default solo con classi native di Qt o classi che estendono QObject. Per far si che
     * che classi particolari (come std::vector<Shoe*>) siano supportate dal sistema signal/slot, esiste chiamo il metodo apposito
     * che si occupa di estendere il sistema meta-object delle Qt per supportare questa classe, in modo che possa usarla fra poco
     * nella comunicazione tra signal e slot */
    qRegisterMetaType<std::vector<Shoe*> >();

    /* Poco sopra ho connesso tutti i signal relativi alla richiesta, da parte del main thread, di dati da caricare dal thread
     * del database. Adesso connetto i signal opposti, ovvero quello che sono emessi dal database per avvisare al thread principale
     * che sono pronti i dati (che vengono passati nel signal). Registro quindi:
     * 1) il signal che passa i dati dei filtri applicabili per le scarpe;
     * 2) il signal che passa i dati di una scarpa caricata (e un booleano per indicare se la scarpa viene da un
     *    messaggio RFID o da un input utente);
     * 3) il signal che passa l'array contenente le scarpe filtrate. */
    QObject::connect(&databaseInterface, SIGNAL(filtersLoaded(ShoeFilterData*)), this, SLOT(setFiltersIntoContext(ShoeFilterData*)));
    QObject::connect(&databaseInterface, SIGNAL(shoeDataLoaded(Shoe*,bool)), this, SLOT(loadNewShoeView(Shoe*,bool)));
    QObject::connect(&databaseInterface, SIGNAL(filterDataLoaded(std::vector<Shoe*>)), this, SLOT(showFilteredShoes(std::vector<Shoe*>)));

    //Eseguite tutte le connessioni, faccio partire il thread
    dataThread->start();

    /* Dato che i filtri delle scarpe servono subito e sono in comune a tutte le scarpe, emitto subito il signal per recuperarle.
     * NOTA: anche se il recupero dei dati è fatto in modo asincrono, non c'è pericolo che venga mostrata una view di una scarpa
     * prima che i dati vengano presi, in quanto un'eventuale necessità di recuperare una scarpa in seguito ad un messaggio RFID
     * (fatto tramite l'emissione del signal requestShoeData()) verrebbe automaticamente accodato a questo dei filtri in quanto
     * questo è il funzionamento di default del sistema signal/slot. In sostanza, fino a quando i dati dei filtri non sono stati
     * recuperati (o il recupero è fallito, ed in tal caso vorrebbe dire che non verrebbero mostrati i filtri nel pannello causando
     * degli errori nella console ma non rovinando l'user experience) non è possibile caricare una scarpa; un'eventuale richiesta
     * di caricamento viene messa in coda fino a quando i dati dei filtri non sono recuperati */
    emit requestFilters();
}

/**
 * @brief WindowManager::setupRFIDThread è un metodo chiamato da setupScreen() che si occupa di creare il thread che controlla
 *        la porta seriale a cui è attaccato l'RFID reader in modo da avvisare quando viene letto un messaggio RFID
 */
void WindowManager::setupRFIDThread()
{
    //Creo l'istanza del thread
    SerialReaderThread* serialReaderThread = new SerialReaderThread(this);

    //Connetto l'evento della chiusura dell'applicazione con uno slot creato appositamente per gestire la chiusura del thread
    QObject::connect(this, SIGNAL(destroyed()), serialReaderThread, SLOT(prepareToQuit()));

    //Connetto il signal del thread che avvisa dell'arrivo di un codice RFID con il signal del main thread che si occupa
    //di avvisare il thread della gestione dati in modo da recuperare la scarpa del codice
    QObject::connect(serialReaderThread, SIGNAL(codeArrived(QString)), this, SIGNAL(requestShoeData(QString)));

    //Terminati i preparativi, avvio il thread
    serialReaderThread->start();
}

/**
 * @brief WindowManager::setFiltersIntoContext è uno slot chiamato dal thread del database una volta che i dai dei filtri
 *        applicabili alle scarpe (cioè la lista di tutte le marche presenti nel db, delle categorie, colori, ecc.)
 *        sono caricati. Il suo compito è di inserire questi dati nel contesto globale di QML, in quanto sono dati condivisi
 *        da tutte le view delle scarpe.
 *
 * @param filters oggetto contenente i filtri applicabili per le scarpe
 */
void WindowManager::setFiltersIntoContext(ShoeFilterData* filters)
{
    QQmlContext* rootContext = this->rootContext();

    //Inserisco l'oggetto nel contesto QML, in modo che i dati rilevanti siano accessibili direttamente da QML (la classe
    //ShoeFilterData estende QObject e ha dichiarate determinate proprietà accessibili da QML)
    rootContext->setContextProperty("filters", filters);
}


/**
 * @brief WindowManager::loadNewShoeView è uno slot che si occupa di caricare la scarpa passatagli in un context QML e di creare
 *        la ShoeView QML che usi quel context; il metodo si occupa di caricare anche parti accessorie della scarpa e di creare
 *        le proprietà che dovranno essere usate in QML per visualizzare determinate cose (come le liste).
 *        Lo slot è chiamao dal thread del database una volta che ha finito di recuperare la scarpa
 *
 * @param shoe la scarpa ricevuta dal thread del database
 * @param isFromRFID booleano che indica se la scarpa è stata caricata in seguito ad un messaggio RFID oppure no; serve saperlo
 *        per la parte QML
 */
void WindowManager::loadNewShoeView(Shoe *shoe, bool isFromRFID)
{
    //Se shoe è uguale a null, c'è stato qualche problema con il recupero della scarpa dal db, quindi bisogna gestirlo
    if(shoe == NULL)
    {
        //Recupero l'elemento root di qml (contenente il view manager)
        QObject *qmlRoot = this->rootObject();

        //Chiamo un metodo della root per gestire l'errore; il metodo si occuperà di mostrare un errore visivo
        QMetaObject::invokeMethod(qmlRoot, "cantLoadShoe");

        return;
    }


    /* Se l'oggeto Shoe è stato recuperato correttamente, procedo con il recupero delle sue informazioni. Dovranno essere mostrate
     * delle immagini, quindi recupero il path dal quale prenderle */
    QDir path = QDir::currentPath() + "/debug/shoes_media/" + shoe->getMediaPath() + "/";


    /* Creo due liste, che fungeranno da model per la lista delle thumbnail e quella delle immagini delle scarpe messe in evidenza:
     * la prima conterrà i path delle immagini salvate in olcale da usare e l'id dei video di YouTube, la seconda conterrà solo
     * i path delle immagini, niente video */
    QStringList imagesAndVideoPathsModel;
    QStringList imagesOnlyPathsModel;

    //Filtro per recuperare le immagini salvate in locale nella cartella specificata dalla scarpa
    QStringList nameFilter;
    nameFilter << "*.png" << "*.jpg" << "*.gif";

    //Scorro tutti i file della cartella, recuperando tutte le entry che rispettano i filtri
    foreach (QFileInfo fInfo, path.entryInfoList(nameFilter, QDir::Files, QDir::Name))
        imagesAndVideoPathsModel.append("file:///" + fInfo.absoluteFilePath());

    //Dato che ho preso tutte le immagini salvate in locale, faccio una copia per la lista che deve contenere solo immagini
    imagesOnlyPathsModel = imagesAndVideoPathsModel;


    //Adesso devo recuperare i video; gli id dei video di YouTube sono contenuti nel file video_links.txt, quindi lo recupero
    QFile inputFile(path.absolutePath() + "/video_links.txt");


    //Apro il file in modalità read only
    if(inputFile.open(QIODevice::ReadOnly))
    {
       QTextStream in(&inputFile);

       //Scorro il file
       while(!in.atEnd())
       {
           //Inserisco riga per riga tutti gli id dei video presenti
          imagesAndVideoPathsModel.append(in.readLine());
       }

       inputFile.close();
    }
    else
        qDebug() << "Non è stato possibile aprire il file con i video; il file potrebbe non essere presente";



    /* Adesso devo recuperare tutte le scarpe simili; creo quindi una lista di QObject che fungerà da model per la rispettiva lista
     * QML; le scarpe estendono QObject, quindi posso inserirle direttamente nella lista e saranno accessibili da QML le proprietà
     * definite Q_PROPERTY nella classe Shoe */
    QList<QObject*> similiarShoesModel;

    //Recupero dalla scarpa il vettore contenente tutte le scarpe simili a quella considerata in base ai parametri specificati
    vector<Shoe*> similiarShoes = shoe->getSimilarShoes();

    //Inserisco nel model tutte le scarpe
    for(int i = 0; i < similiarShoes.size(); i++)
       similiarShoesModel.append(similiarShoes[i]);



    /* Adesso la parte importante: bisogna epsorre le cose appena recuperate in modo che siano accessibili da QML.
     * In generale le viste QML sono basate su un context; nel metodo setupScreen() erano state aggiunte delle proprietà
     * al context del root, ovvero il context globale e condiviso da tutte le viste che nascono da quel root. Per far si
     * che ogni view aggiunta dinamicamente mostri esclusivamente i contenuti della scarpa della view, non bisogna mettere
     * questi contenuti nel context globale (altrimenti ogni volta che se ne aggiungono vengono sovrascritti i dati precedenti
     * e ogni view finisce per mostrare la stessa scarpa), ma bisogna far si che ogni view di una scarpa abbia un SUO context,
     * che parta da quello globale ma che si arricchisca dei dati che le servono.
     * Di conseguenza quello che faccio è creare un nuovo context da arricchirlo con i dati appena recuperati, e creo un nuovo
     * component (che sarà la view che mostrerà la scarpa) che usi il context appena creato.
     * Inizio con il creare un nuovo context, che parta dal context globale */
    QQmlContext* context = new QQmlContext(this->rootContext());

    //Creato il context, lo arricchisco di tutti i dati appena recuperati. Nota: posso passare direttamente "shoe" perchè
    //estende QObject e ha definite delle Q_PROPERTY per accedere ai suoi dati
    context->setContextProperty("shoe", shoe);
    context->setContextProperty("thumbnailModel", QVariant::fromValue(imagesAndVideoPathsModel));
    context->setContextProperty("imagesModel", QVariant::fromValue(imagesOnlyPathsModel));
    context->setContextProperty("similiarShoesModel", QVariant::fromValue(similiarShoesModel));


    /* All'interno della parte QML (nel file ShoeFilter) c'è la lista dei risultati delle ricerche di scarpe; questa lista
     * utilizza un model passato da C++ in modo da avere sempre i dati aggiornati. Inizialmente però il model non è presente, in
     * quanto chiaramente non è stata ancora fatta una ricerca; questo genera un messaggio di errore nella console, che si può
     * evitare settando un model iniziale vuoto che è condiviso da tuttte le view dell'applicazione.
     * Quindi creo il model vuoto... */
    QList<QObject*> filteredShoesModel;

    /* ...e lo inserisco nel context della view; il model verrà sovrascritto quando servirà. NOTA: verrebbe da pensare che essendo
     * il model inizialmente vuoto per ogni view convenga metterlo nel root context dell'applicazione... WRONG! Inizialmente
     * era così, ma il fatto che quando si esegue una ricerca il model passa dal root context a quello particolare della view
     * causava un casino di problemi random (del tipo variabili QML che a caso diventavano null o undefined), e questo avveniva
     * solo durante la prima ricerca (che era il momento in cui passava definitivamente dal root context al context della ShoeView
     * coinvolta)... capire a cosa era dovuto il bug non è stato semplice... */
    context->setContextProperty("filteredShoesModel", QVariant::fromValue(filteredShoesModel));


    //Se la scarpa arriva da un RFID vuol dire che si sta creando un nuovo set di view, e quello precedente (se c'era) viene
    //eliminato. Di conseguenza svuoto l'array che contiene i riferimenti ai context delle view, in modo da averlo pulito
    if(isFromRFID)
        qmlContextList.clear();

    //Aggiungo il context appena creato allo stack di context; serve per avere sempre un riferimento al context della view
    //attualmente attiva, altrimenti è impossibile recuperarlo
    qmlContextList.push_back(context);



    //Terminata la creazione ed il popolamento del context, creo un nuovo component con il file che è la view della scarpa
    QQmlComponent component(this->engine(), QUrl("qrc:/qml/ShoeView.qml"));

    //Creo quindi una istanza del component appena creato, inserendo il context sopra definito, e la recupero. Questa nuova view
    //quindi potrà accedere a tutte le proprietà sopra definite
    QQuickItem *newView = qobject_cast<QQuickItem*>(component.create(context));

    //Dichiaro che la parte JavaScript (e QML) hanno ownership sulla view. Questo serve per quando le view dinamicamente create
    //come quella creata poco sopra devono essere distrutte da QML; senza non potrebbero essere eliminate dal view manager
    QDeclarativeEngine::setObjectOwnership(newView, QDeclarativeEngine::JavaScriptOwnership);


    //La view appena creata non ha ancora un padre però, quindi devo assegnarlelo. Per farlo, devo prima recuperarlo, quindi
    //recupero la root di QML in modo da cercare il padre
    QObject *qmlRoot = this->rootObject();

    //Recupero il ViewManager, che sarà il padre della nuova view (in modo che possa gestirne le transizioni). Nota: la ricerca
    //non è fatta in base alla proprietà "id" del component, ma a quella "objectName", che in questo caso è "myViewManager"
    QObject *viewManager = qmlRoot->findChild<QObject*>("myViewManager");

    //Preso il view manager, lo setto come padre della nuova view
    newView->setParentItem(qobject_cast<QQuickItem*>(viewManager));


    /* Il processo di creazione della nuova view non è finito. Bisogna connettere la nuova view a eventi, signals e cose varie
     * che sono visibili e accessibili solo dalla parte QML, quindi quello che faccio è chiamare una funzione contenuta nel
     * file main.qml (che corrisponte ora a qmlRoot) che si occuperà di questi collegamenti, e le passo la nuova view
     * appena aggiunta. Dopo l'esecuzione di quella funzione, la nuova view verrà mostrata */
    QMetaObject::invokeMethod(qmlRoot, "connectNewViewEvents", Q_ARG(QVariant, QVariant::fromValue(newView)), Q_ARG(QVariant, QVariant::fromValue(isFromRFID)));
}


/**
 * @brief WindowManager::showFilteredShoes è uno slot chiamato da un signal del thread del database che scatta quando sono state
 *        recuperate le scarpe filtrate, che sono quindi da passare a QML per essere mostrate
 *
 * @param filteredShoes la lista delle scarpe filtrate
 */
void WindowManager::showFilteredShoes(vector<Shoe*> filteredShoes)
{
    /* Adesso devo recuperare tutte le scarpe simili; creo quindi una lista di QObject che fungerà da model per la rispettiva lista
     * QML; le scarpe estendono QObject, quindi posso inserirle direttamente nella lista e saranno accessibili da QML le proprietà
     * definite Q_PROPERTY nella classe Shoe */
    QList<QObject*> filteredShoesModel;

    QString arduinoLights;

    //Inserisco nel model tutte le scarpe
    for(int i = 0; i < filteredShoes.size(); i++)
    {
        filteredShoesModel.append(filteredShoes[i]);

        //Ne approfitto poi per recuperare il carattere contenente la luce corrispondente alla scarpa, in modo da accenderla
        //in seguito con l'Arduino
        arduinoLights.append(filteredShoes[i]->getArduinoLight());
    }

    //Accendo le luci di tutte le scarpe trovate; se non è possibile accenderle, non vengono mostrati errori (viene restituito false).
    //Se le luci sono state accese, parte un timer che le spegne dopo un tot di tempo
    arduino.turnOnLights(arduinoLights);


    if(qmlContextList.size() == 0)
        qDebug() << "qmlContextList size == 0!";

    //Recupero l'ultimo context presente nella lista dei context delle ShoeView; l'ultimo context è quello relativo alla view
    //attualmente visualizzata, che è quella che stava attendendo la fine della ricerca di scarpe
    QQmlContext* context = qmlContextList.back();

    //Preso il context, setto la proprietà che è usata dal model della lista che mostra i risultati delle ricerche
    context->setContextProperty("filteredShoesModel", QVariant::fromValue(filteredShoesModel));
}


/**
 * @brief WindowManager::movingToPreviousView è uno slot chiamato da un signal QML che indica che si sta tornando di indietro
 *        di una view nello stack. Alla parte C++ interessa perchè quando si torna indietro di una view bisogna eliminare il
 *        riferimento al context della view che sta sparendo dallo stack di context, dato che ora non serve più.
 *        In questo modo si ha sempre il riferimento al context della view attualmente visibile
 */
void WindowManager::movingToPreviousView()
{
    /* Rimuovo l'ultimo context presente nello stack, ma solo se così facendo rimane almeno un elemento nell'array. Infatti
     * premendo molte volte il tasto "back" di fila fino ad arrivare alla prima ShoeView presente può causare lo svuotamento
     * dell'array qmlContextList, che farebbe perdere il riferimento della prima view. Questo causerebbe crash quando
     * poi si cerca di prendere il context di quella view (quando si devono mostrare i risultati di una ricerca). In sostanza,
     * bisogna far si che l'array contenga sempre il primo context della lista */
    if(qmlContextList.size() > 1)
        qmlContextList.pop_back();
}
