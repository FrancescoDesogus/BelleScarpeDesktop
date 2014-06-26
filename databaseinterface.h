#ifndef DATABASEINTERFACE_H
#define DATABASEINTERFACE_H

#include <QObject>
#include <shoe.h>
#include <shoedatabase.h>
#include <shoefilterdata.h>


/**
 * @brief The DatabaseInterface class si occupa di fungere da interfaccia tra il thread principale ed il thread del database.
 *        L'istanza della classe si trova nel thread del database, e fornisce esclusivamente slot e signal per comunicare con il main
 *        thread e con il database (che sta nello stesso thread dell'istanza di DatabaseInterface)
 */
class DatabaseInterface : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseInterface(QObject *parent = 0);

private:
    ShoeDatabase database;


signals:
    //Signal che avvisa il main thread che i filtri applicabili alle scarpe sono stati recuperati; i filtri possono essere liste
    //vuote in caso di errori o se non ne sono stati trovati
    void filtersLoaded(ShoeFilterData* filters);

    //Signal che avvisa il main thread che la scarpa è stata caricata; la scarpa può essere NULL se non è stata trovata o ci sono
    //stati errori
    void shoeDataLoaded(Shoe* shoe, bool fromRFID);

    //Signal che avvisa il main thread che la ricerca delle scarpe è conclusa; la lista delle scarpe può essere vuota se non ne
    //sono state trovate o se c'è stato un erore
    void filterDataLoaded(std::vector<Shoe*> filteredShoes);

public slots:
    void loadFilters();
    void loadShoeData(int id);
    void loadShoeData(QString RFIDcode);
    void loadFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice);

};

#endif // DATABASEINTERFACE_H
