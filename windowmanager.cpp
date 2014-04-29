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


WindowManager::WindowManager(QQuickView *parent) :
    QQuickView(parent)
{

}

void WindowManager::setupScreen()
{
    //Recupero informazioni sulla grandezza dello schermo, in modo da visualizzare la view fullscreen correttamente
    QDesktopWidget widget;
    QRect mainScreenSize = widget.availableGeometry(widget.primaryScreen());


    /* Aggiungo al contesto dell'engile qml una proprietà che corrisponde all'istanza di questa classe. In questo modo nei file qml
     * che si chiameranno sarà nota la proprietà "firstWindow", e si potranno chiamare i metodi definiti Q_INVOKABLE nell'header
     * della classe, oltre che i membri definiti con Q_PROPERTY (in questo caso però di questi non ce ne sono) */
    this->rootContext()->setContextProperty("firstWindow", this);

    /* Definisco nel contesto dell'engine qml altre due proprietà, che sono i valori per cui bisogna moltiplicare ogni coordinata di larghezza
     * e altezza presente nei file qml in modo tale che le posizioni e le grandezze degli oggetti scalino bene su tutti i monitor.
     * Come risoluzione target si usa 1920x1080 */
    this->rootContext()->setContextProperty("scaleX", (qreal) mainScreenSize.width() / 1920);
    this->rootContext()->setContextProperty("scaleY", (qreal) mainScreenSize.height() / 1080);


    //Carico il file base
    this->setSource(QUrl("qrc:/qml/main.qml"));


    //Con questa chiamata l'elemento root del file QML otterrà la stessa grandezza della finestra in cui sta. Così facendo
    //posso mettere la finestra in fullscreen e la parte fatta in QML si adatterà automaticamente
    this->setResizeMode(QQuickView::SizeRootObjectToView);

//    QObject *rootObject = (QObject *)this->rootObject();
//    rootObject->setProperty("color", "red");


    this->showFullScreen();
}


/* Slot chiamato dal secondo thread non appena è letto un nuovo codice. Questo metodo dovrebbe teoricamente
 * prendere i dati della scarpa dal db grazie al codice ricevuto, preparare i dati da mostrare nella view qml,
 * e avvertire la parte qml che deve creare una nuova view del tipo indicato (che dovrà mostrare i dati recuperati) */
void WindowManager::getCode(QString code)
{
    qDebug() << "code received: " << code;

    //Quello che devo fare adesso è avvisare la parte qml che deve creare una nuova view. Il file main.qml ha nell'oggetto root una
    //funzione apposita, quindi quello che devo fare è chiamarla. Per poterlo fare, recupero l'oggetto root
    QObject *object = this->rootObject();

    //Con il metodo statico invokeMethod() sfrutto il sistema meta-object based di qml per chiamare il metodo specificato, passando come
    //parametro l'item qml che contiene quella funzione
    QMetaObject::invokeMethod(object, "addView");
}



