#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <QQuickView>

class WindowManager : public QQuickView
{
    Q_OBJECT

public:
    WindowManager(QQuickView *parent = 0);

    void setupScreen();

private:
    static const int TARGET_RESOLUTION_WIDTH;
    static const int TARGET_RESOLUTION_HEIGHT;

public slots:
    void getCode(QString code);
    void loadShoeIntoContext(int id);

};

#endif // WINDOWMANAGER_H
