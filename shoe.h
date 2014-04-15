#ifndef SHOE_H
#define SHOE_H

#include <QObject>

class Shoe : public QObject
{
    Q_OBJECT
public:
    explicit Shoe(QObject *parent = 0);

signals:

public slots:

};

#endif // SHOE_H
