#ifndef SHOEFILTERDATA_H
#define SHOEFILTERDATA_H

#include <QObject>
#include <QStringList>

class ShoeFilterData : public QObject
{
    Q_OBJECT

    /* Definisco una serie di proprietà che saranno visibili da QML se si inserisce un oggetto ShoeFilterData nel context QML */
    Q_PROPERTY(QStringList allBrandsModel READ getAllBrands CONSTANT)
    Q_PROPERTY(QStringList allCategoriesModel READ getAllCategories CONSTANT)
    Q_PROPERTY(QStringList allColorsModel READ getAllColors CONSTANT)
    Q_PROPERTY(QStringList allSizesModel READ getAllSizes CONSTANT)
    Q_PROPERTY(QStringList priceRangeModel READ getPriceRange CONSTANT)


public:
    ShoeFilterData();


    void setAllBrands(const QStringList &allBrands);
    void setAllCategories(const QStringList &allCategories);
    void setAllColors(const QStringList &allColors);
    void setAllSizes(const QStringList &allSizes);
    void setPriceRange(const QStringList &priceRange);

    QStringList getAllBrands();
    QStringList getAllCategories();
    QStringList getAllColors();
    QStringList getAllSizes();
    QStringList getPriceRange();

private:
    QStringList allBrands;
    QStringList allCategories;
    QStringList allColors;
    QStringList allSizes;
    QStringList priceRange;
};

#endif // SHOEFILTERDATA_H
