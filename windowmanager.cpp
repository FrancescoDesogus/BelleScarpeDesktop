#include "windowmanager.h"


#include <QQuickView>
#include <QWindow>

#include <QRect>
#include <QDesktopWidget>

#include <QApplication>

#include <QtDeclarative/QDeclarativeView>

#include <QDebug>
#include <QQmlContext>

#include <QQmlEngine>

#include <QQmlComponent>
#include <Qtimer>
#include <QQuickItem>


#include <shoedatabase.h>
#include <shoe.h>
#include <dataobject.h>

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

void WindowManager::setupScreen()
{
    /* Aggiungo al contesto dell'engile qml una proprietà che corrisponde all'istanza di questa classe. In questo modo nei file qml
     * che si chiameranno sarà nota la proprietà "firstWindow", e si potranno chiamare i metodi definiti Q_INVOKABLE nell'header
     * della classe, oltre che i membri definiti con Q_PROPERTY (in questo caso però di questi non ce ne sono) */
    this->rootContext()->setContextProperty("window", this);


    //Inserisco come proprietà le informazioni sulla risoluzione target da usare
    this->rootContext()->setContextProperty("TARGET_RESOLUTION_WIDTH", TARGET_RESOLUTION_WIDTH);
    this->rootContext()->setContextProperty("TARGET_RESOLUTION_HEIGHT", TARGET_RESOLUTION_HEIGHT);


    //Recupero informazioni sulla grandezza dello schermo vera e propria, in modo da visualizzare la view in fullscreen correttamente
    QDesktopWidget desktopWidget;
    QRect mainScreenSize = desktopWidget.screenGeometry(desktopWidget.primaryScreen());


    /* Definisco nel contesto dell'engine qml altre due proprietà, che sono i valori per cui bisogna moltiplicare ogni coordinata di larghezza
     * e altezza presente nei file qml in modo tale che le posizioni e le grandezze degli oggetti scalino bene su tutti i monitor.
     * Come risoluzione target si usa 1920x1080 */
    this->rootContext()->setContextProperty("scaleX", (qreal) mainScreenSize.width() / TARGET_RESOLUTION_WIDTH);
    this->rootContext()->setContextProperty("scaleY", (qreal) mainScreenSize.height() / TARGET_RESOLUTION_HEIGHT);


    //Carico il file base
    this->setSource(QUrl("qrc:/qml/main.qml"));


    //Con questa chiamata l'elemento root del file QML otterrà la stessa grandezza della finestra in cui sta. Così facendo
    //posso mettere la finestra in fullscreen e la parte fatta in QML si adatterà automaticamente
    this->setResizeMode(QQuickView::SizeRootObjectToView);


    //Mando in esecuzione a tutto schermo
    this->showFullScreen();


    //Una volta mandato a tutto schermo, controllo se ci sono più monitor attaccati; nel caso sposto la finestra nel secondo
    if(desktopWidget.screenCount() > 1)
    {
        //Recupero le informazioni sul secondo screen attaccato
        QRect secondaryScreenGeometry = desktopWidget.screenGeometry(desktopWidget.primaryScreen() + 1);

        //Setto la nuova geometria della finestra in base a quella del nuovo monitor
        this->setGeometry(secondaryScreenGeometry);
    }


    //Appena avviato carico una scarpa per provare, simulando l'arrivo di un codice RFID
    loadNewShoeView("asd");
}


/**
 * @brief WindowManager::loadNewShoeView è uno slot chiamato dal secondo thread non appena viene letto un nuovo codice.
 *        Il metodo si occupa di recuperare la scarpa a cui corrisponde il codice RFID ricevuto, e quindi di creare una
 *        nuova view che mostri la nuova scarpa
 *
 * @param RFIDcode il codice RFID della scarpa da ricercare
 */
void WindowManager::loadNewShoeView(QString RFIDcode)
{
    qDebug() << "code received: " << RFIDcode;

    //Apro il database, visto che dovrò effettuare query
    database.open();

    //Recupero la scarpa
    Shoe *shoe = database.getShoeFromId(RFIDcode);

    //Chiamo il metodo che si occupa effettivamente di recuperare il resto delle informazioni, di creare la nuova view ecc...
    loadShoe(shoe, true);
}



/**
 * @brief WindowManager::loadNewShoeView è uno slot chiamato da QML quando si preme ad esempio su una scarpa diversa da quella
 *        correntemente mostrata in modo da visualizzare la sua pagina.
 *        Il metodo si occupa di recuperare la scarpa a cui corrisponde il codice RFID ricevuto, e quindi di creare una
 *        nuova view che mostri la nuova scarpa
 *
 * @param id l'id della scarpa da ricercare
 */
void WindowManager::loadNewShoeView(int id)
{
    //Apro il database, visto che dovrò effettuare query
    database.open();

    //Recupero la scarpa
    Shoe *shoe = database.getShoeFromId(id);

    //Chiamo il metodo che si occupa effettivamente di recuperare il resto delle informazioni, di creare la nuova view ecc...
    loadShoe(shoe, false);
}



void WindowManager::loadShoe(Shoe *shoe, bool isFromRFID)
{
    //Se shoe è uguale a null, c'è stato qualche problema con il recupero della scarpa dal db, quindi bisogna gestirlo
    if(shoe == NULL)
    {
        //Recupero l'elemento root di qml (contenente il view manager)
        QObject *qmlRoot = this->rootObject();

        //Chiamo un metodo della root per gestire l'errore; il metodo si occuperà di mostrare un errore visivo
        QMetaObject::invokeMethod(qmlRoot, "cantLoadShoe");

        //Chiudo il db e concludo qua il metodo
        database.close();

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

    //Recupero dal db il vettore contenente tutte le scarpe simili a quella considerata in base ai parametri specificati
    vector<Shoe*> similiarShoes = database.getSimiliarShoes(shoe->getId(), shoe->getSex(), shoe->getCategory());

    //Inserisco nel model tutte le scarpe
    for(int i = 0; i < similiarShoes.size(); i++)
       similiarShoesModel.append(similiarShoes[i]);





    //Modello Di prova
    QList<QObject*> similiarShoesModelProva;

    for(int i = 0; i < 1; i++)
       similiarShoesModelProva.append(similiarShoes[i]);






    //Dato che ho prelevato tutto quello che mi serviva dal db, posso chiuderlo
    database.close();


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
    QQmlContext *context = new QQmlContext(this->rootContext());

    //Creato il context, lo arricchisco di tutti i dati appena recuperati. Nota: posso passare direttamente "shoe" perchè
    //estende QObject e ha definite delle Q_PROPERTY per accedere ai suoi dati
    context->setContextProperty("shoe", shoe);
    context->setContextProperty("thumbnailModel", QVariant::fromValue(imagesAndVideoPathsModel));
    context->setContextProperty("imagesModel", QVariant::fromValue(imagesOnlyPathsModel));
    context->setContextProperty("similiarShoesModel", QVariant::fromValue(similiarShoesModel));




    context->setContextProperty("similiarShoesModelProva", QVariant::fromValue(similiarShoesModelProva));



    //Terminata la creazione e l'arricchimento del context, creo un nuovo component con il file che è la view della scarpa
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


void WindowManager::prova()
{
    database.open();

    Shoe *shoe = database.getShoeFromId(1);

    if(shoe == NULL)
    {
        QObject *qmlRoot = this->rootObject();

        QMetaObject::invokeMethod(qmlRoot, "cantLoadShoe");

        database.close();

        return;
    }

    QDir path = QDir::currentPath() + "/debug/shoes_media/" + shoe->getMediaPath() + "/";


    QStringList imagesAndVideoPathsModel;
    QStringList imagesOnlyPathsModel;

    QStringList nameFilter;
    nameFilter << "*.png" << "*.jpg" << "*.gif";

    foreach (QFileInfo fInfo, path.entryInfoList(nameFilter, QDir::Files, QDir::Name))
        imagesAndVideoPathsModel.append("file:///" + fInfo.absoluteFilePath());

    imagesOnlyPathsModel = imagesAndVideoPathsModel;

    QFile inputFile(path.absolutePath() + "/video_links.txt");

    if(inputFile.open(QIODevice::ReadOnly))
    {
       QTextStream in(&inputFile);

       while(!in.atEnd())
       {
          imagesAndVideoPathsModel.append(in.readLine());
       }

       inputFile.close();
    }
    else
        qDebug() << "Non è stato possibile aprire il file con i video; il file potrebbe non essere presente";


    QList<QObject*> similiarShoesModel;

    vector<Shoe*> similiarShoes = database.getSimiliarShoes(shoe->getId(), shoe->getSex(), shoe->getCategory());

    for(int i = 0; i < similiarShoes.size(); i++)
       similiarShoesModel.append(similiarShoes[i]);

    database.close();


    QQmlContext *context = new QQmlContext(this->rootContext());


    context->setContextProperty("shoe", shoe);
    context->setContextProperty("thumbnailModel", QVariant::fromValue(imagesAndVideoPathsModel));
    context->setContextProperty("imagesModel", QVariant::fromValue(imagesOnlyPathsModel));
    context->setContextProperty("similiarShoesModel", QVariant::fromValue(similiarShoesModel));


    QQmlComponent component(this->engine(), QUrl("qrc:/qml/ShoeView.qml"));

    QQuickItem *newView = qobject_cast<QQuickItem*>(component.create(context));

//    QDeclarativeEngine::setObjectOwnership(newView, QDeclarativeEngine::JavaScriptOwnership);


//    QObject *qmlRoot = this->rootObject();


//    QObject *viewManager = qmlRoot->findChild<QObject*>("myViewManager");

//    newView->setParentItem(qobject_cast<QQuickItem*>(viewManager));


//    QMetaObject::invokeMethod(qmlRoot, "connectNewViewEvents", Q_ARG(QVariant, QVariant::fromValue(newView)), Q_ARG(QVariant, QVariant::fromValue(true)));
}
