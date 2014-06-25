#include "databaseinterface.h"
#include "shoefilterdata.h"
#include <QDebug>

using namespace std;

DatabaseInterface::DatabaseInterface(QObject *parent) :
    QObject(parent)
{

}


void DatabaseInterface::loadShoeData(int id)
{
    Shoe* shoe = database.getShoeFromId(id);

    shoe->setSimilarShoes(database.getSimiliarShoes(shoe));


    emit shoeDataLoaded(shoe, false);
}

void DatabaseInterface::loadShoeData(QString RFIDcode)
{
    Shoe* shoe = database.getShoeFromId(RFIDcode);

    shoe->setSimilarShoes(database.getSimiliarShoes(shoe));


    emit shoeDataLoaded(shoe, true);
}

void DatabaseInterface::loadFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice)
{
    vector<Shoe*> filteredShoes = database.getFilteredShoes(brandList.toStringList(), categoryList.toStringList(), colorList.toStringList(), sizeList.toStringList(), sexList.toStringList(), minPrice, maxPrice);

    emit filterDataLoaded(filteredShoes);
}


void DatabaseInterface::loadFilters()
{
    QStringList allBrands = database.getAllBrands();
    QStringList allCategories = database.getAllCategories();
    QStringList allColors = database.getAllColors();
    QStringList allSizes = database.getAllSizes();
    QStringList priceRange = database.getPriceRange();

    ShoeFilterData* filters = new ShoeFilterData();

    filters->setAllBrands(allBrands);
    filters->setAllCategories(allCategories);
    filters->setAllColors(allColors);
    filters->setAllSizes(allSizes);
    filters->setPriceRange(priceRange);

    emit filtersLoaded(filters);
}
