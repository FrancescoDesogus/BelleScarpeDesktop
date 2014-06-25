#include "shoefilterdata.h"

ShoeFilterData::ShoeFilterData()
{

}

void ShoeFilterData::setAllBrands(const QStringList &allBrands)
{
    this->allBrands = allBrands;
}

void ShoeFilterData::setAllCategories(const QStringList &allCategories)
{
    this->allCategories = allCategories;
}

void ShoeFilterData::setAllColors(const QStringList &allColors)
{
    this->allColors = allColors;
}

void ShoeFilterData::setAllSizes(const QStringList &allSizes)
{
    this->allSizes = allSizes;
}

void ShoeFilterData::setPriceRange(const QStringList &priceRange)
{
    this->priceRange = priceRange;
}




QStringList ShoeFilterData::getAllBrands()
{
    return this->allBrands;
}

QStringList ShoeFilterData::getAllCategories()
{
    return this->allCategories;
}

QStringList ShoeFilterData::getAllColors()
{
    return this->allColors;
}

QStringList ShoeFilterData::getAllSizes()
{
    return this->allSizes;
}

QStringList ShoeFilterData::getPriceRange()
{
    return this->priceRange;
}

