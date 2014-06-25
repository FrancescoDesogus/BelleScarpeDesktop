#ifndef DATABASEINTERFACE_H
#define DATABASEINTERFACE_H

#include <QObject>
#include <shoe.h>
#include <shoedatabase.h>
#include <shoefilterdata.h>

class DatabaseInterface : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseInterface(QObject *parent = 0);

//    Shoe* getLoadedShoe();
//    std::vector<Shoe*>* getFilteredShoes();

private:
    ShoeDatabase database;

//    Shoe* shoe;
//    std::vector<Shoe*> filteredShoes;


signals:
    void filtersLoaded(ShoeFilterData* filters);
    void shoeDataLoaded(Shoe* shoe, bool fromRFID);
    void filterDataLoaded(std::vector<Shoe*> filteredShoes);

public slots:
    void loadFilters();
    void loadShoeData(int id);
    void loadShoeData(QString RFIDcode);
    void loadFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice);

};

#endif // DATABASEINTERFACE_H
