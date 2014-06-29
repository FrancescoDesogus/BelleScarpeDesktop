#include "databaseinterface.h"
#include "shoefilterdata.h"
#include <QDebug>

using namespace std;

DatabaseInterface::DatabaseInterface(QObject *parent) :
    QObject(parent)
{

}

/**
 * @brief DatabaseInterface::initDatabase è uno slot chiamato non appena il thread in cui l'istanza di DatabaseInterface gira
 *        inizia. Serve per creare la connessione col database, in quanto per via di come i database sono gestiti dalle Qt, la
 *        connessione non può essere condivisa da più thread; connettendo questo slot al signal che dichiara l'inizio
 *        dell'esecuzione del nuovo thread mi assicuro che la connessione ed il setup del db sono eseguiti nel nuovo thread
 */
void DatabaseInterface::initDatabase()
{
    database.init();
}

/**
 * @brief DatabaseInterface::loadShoeData è uno slot chiamato dal main thread quando bisogna caricare una scarpa dal database
 *        in seguito all'arrivo di un messaggio RFID
 *
 * @param RFIDcode il codice RFID ricevuto, con cui ricercare la scarpa
 */
void DatabaseInterface::loadShoeData(QString RFIDcode)
{
    //Chiamo il metodo apposito del database per ricercare la scarpa; il risultato può essre NULL in caso di errori o se
    //la scarpa non è stata trovata
    Shoe* shoe = database.getShoeFromId(RFIDcode);

    //Recupero eventuali scarpe simili dal db e le inserisco nella scarpa
    shoe->setSimilarShoes(database.getSimiliarShoes(shoe));

    //Infine emitto il signal che avvisa il main thread che la scarpa è pronta, segnalando con un booleano che viene da un RFID
    emit shoeDataLoaded(shoe, true);
}


/**
 * @brief DatabaseInterface::loadShoeData è uno slot chiamato dal main thread quando bisogna caricare una scarpa dal database
 *        in seguito ad un input utente (il codice è analogo a loadShoeData(QString))
 *
 * @param id l'id della scarpa da ricercare
 */
void DatabaseInterface::loadShoeData(int id)
{
    Shoe* shoe = database.getShoeFromId(id);

    shoe->setSimilarShoes(database.getSimiliarShoes(shoe));

    emit shoeDataLoaded(shoe, false);
}

/**
 * @brief DatabaseInterface::loadFilterData è uno slot chiamato dal main thread quando bisogna ricercare scarpe dal database
 *        in base ai filtri passati
 *
 * @param brandList lista delle marche da filtrare
 * @param categoryList lista delle categorie da filtrare
 * @param colorList lista dei colori da filtrare
 * @param sizeList lista delle taglie da filtrare
 * @param sexList lista del sesso da filtrare
 * @param minPrice prezzo minimo da applicare nella ricerca
 * @param maxPrice prezzo massimo da applicare nella ricerca
 */
void DatabaseInterface::loadFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice)
{
    //Eseguo la ricerca nel database; il risultato può essere un array vuoto in caso di errori o di scarpe non trovate
    vector<Shoe*> filteredShoes = database.getFilteredShoes(brandList.toStringList(), categoryList.toStringList(), colorList.toStringList(), sizeList.toStringList(), sexList.toStringList(), minPrice, maxPrice);

    //Infine emitto il signal che avvisa il main thread che i risultati sono pronti, e li passo
    emit filterDataLoaded(filteredShoes);
}


/**
 * @brief DatabaseInterface::loadFilters è uno slot chiamato dal main thread quando bisogna recuperare i filri
 *        applicabili alle scarpe
 */
void DatabaseInterface::loadFilters()
{
    //Recupero tutti i filtri con gli appositi metodi
    QStringList allBrands = database.getAllBrands();
    QStringList allCategories = database.getAllCategories();
    QStringList allColors = database.getAllColors();
    QStringList allSizes = database.getAllSizes();
    QStringList priceRange = database.getPriceRange();

    //Creo l'oggetto che conterrà i dati e setto tutti i risultati ottenuti
    ShoeFilterData* filters = new ShoeFilterData();
    filters->setAllBrands(allBrands);
    filters->setAllCategories(allCategories);
    filters->setAllColors(allColors);
    filters->setAllSizes(allSizes);
    filters->setPriceRange(priceRange);

    //Infine emitto il signal che avvisa il main thread che i risultati sono pronti, e li passo
    emit filtersLoaded(filters);
}
