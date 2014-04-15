#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <QQuickView>

class WindowManager : public QQuickView
{
    Q_OBJECT

public:
    WindowManager(QQuickView *parent = 0);

    void setupScreen();

public slots:
    void getCode(char* code);

};

#endif // WINDOWMANAGER_H
