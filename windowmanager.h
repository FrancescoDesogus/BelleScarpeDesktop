#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <QQuickView>
#include <ShoeDatabase.h>
#include <databaseinterface.h>
#include <serialreaderthread.h>
#include <shoefilterdata.h>
#include <arduino.h>
#include <QQmlComponent>
#include <QTimer>

class WindowManager : public QQuickView
{
    Q_OBJECT

public:
    WindowManager(QQuickView *parent = 0);
    ~WindowManager();

    void setupScreen();

private:
    //Costanti che contengono le dimensioni della risoluzione usata come target dell'applicazione (di default, 1920x1080)
    static const int TARGET_RESOLUTION_WIDTH;
    static const int TARGET_RESOLUTION_HEIGHT;

    //Oggetto che funge da interfaccia con il database; è usato in un thread secondario in modo da prendere i dati in modo asincrono
    DatabaseInterface databaseInterface;

    /* Oggetto che si occupa di mandare messaggi all'Arduino per accedere le luci delle scarpe filtrate. E' un puntatore per far si
     * che possa collegare il signal destroyed() della quickview con uno slot della classe Arduino; se non fosse un puntatore infatti
     * lo slot non verrebbe chiamato, in quanto essendo l'oggetto arduino figlio della finestra che fa scattare il signal destroyed(),
     * verrebbe subito eliminato insieme a tutti gli altri figli non appena il signal scatta. Questo invece non accade se è
     * un puntatore; nel caso infatti viene eliminato solo alla fine, dopo gli altri figli. In questo modo lo slot vien chiamato */
    Arduino* arduino;

    //Oggetto per mantenere e gestire il thread per l'RFID reader
    SerialReaderThread* serialReaderThread;


    //Lista dei context QML delle ShoeView; serve per tener traccia del context della view attualmente visibile, tenendo conto
    //che si può tornare indietro ad una ShoeView precedente
    std::vector<QQmlContext*> qmlContextList;


    void setupDataThread();
    void setupRFIDThread();

signals:
    //Signal per segnalare il thread del database che deve recuperare i filtri applicabili alle scarpe
    void requestFilters();

    //Signal per segnalare il thread del database che deve recuperare i dati di una scarpa in seguito ad un messaggio RFID
    void requestShoeData(QString RFIDcode);

    //Signal per segnalare il thread del database che deve recuperare i dati di una scarpa in seguito ad un input utente
    void requestShoeData(int id);

    //Signal per segnalare il thread del database che deve effettuare una ricerca di scarpe in base ai filtri selezionati
    void requestFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice);

    //Signal per notificare QML dell'arrivo imminente di dati in seguito ad un messaggio RFID
    void dataIncomingFromRFID();

public slots:
    //Slot chiamato dal thread del database quando sono pronti i dati dei filtri applicabili alle scarpe
    void setFiltersIntoContext(ShoeFilterData* filters);

    //Slot chiamato dal thread del database quando è pronta la scarpa da mostrare
    void loadNewShoeView(Shoe *shoe, bool isFromRFID);

    //Slot chiamato dal thread del database quando sono pronte le scarpe da mostrare in seguito ad una ricerca
    void showFilteredShoes(std::vector<Shoe *> filteredShoes);

    //Slot chiamato da QML per segnalare C++ che si sta tornando indietro di una view nello stack di ShoeView
    void movingToPreviousView();
};

#endif // WINDOWMANAGER_H
