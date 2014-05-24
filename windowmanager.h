#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <QQuickView>
#include <ShoeDatabase.h>
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

    //Database dal quale recuperare informazioni sulle scarpe
    ShoeDatabase database;

    void loadShoe(Shoe *shoe, bool isFromRFID);

public slots:
    void loadNewShoeView(int id);
    void loadNewShoeView(QString RFIDcode);
};

#endif // WINDOWMANAGER_H
