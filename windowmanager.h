#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <QQuickView>
#include <ShoeDatabase.h>
#include <databaseinterface.h>
#include <shoefilterdata.h>
#include <QQmlComponent>

class WindowManager : public QQuickView
{
    Q_OBJECT

public:
    WindowManager(QQuickView *parent = 0);

    void setupScreen();

private:
    //Costanti che contengono le dimensioni della risoluzione usata come target dell'applicazione (di default, 1920x1080)
    static const int TARGET_RESOLUTION_WIDTH;
    static const int TARGET_RESOLUTION_HEIGHT;


    DatabaseInterface databaseInterface;


    std::vector<QQmlContext*> qmlContextList;

    void setupDataThread();

signals:
    void requestFilters();
    void requestShoeData(QString RFIDcode);
    void requestShoeData(int id);
    void requestFilterData(QVariant brandList, QVariant categoryList, QVariant colorList, QVariant sizeList, QVariant sexList, int minPrice, int maxPrice);

public slots:
//    void loadNewShoeView(int id);
//    void loadNewShoeView(QString RFIDcode);
    void showFilteredShoes(std::vector<Shoe *> filteredShoes);
    void movingToPreviousView();
    void loadNewShoeView(Shoe *shoe, bool isFromRFID);
    void setFiltersIntoContext(ShoeFilterData* filters);

};

#endif // WINDOWMANAGER_H
