#ifndef SERIALREADERTHREAD_H
#define SERIALREADERTHREAD_H

#include <QThread>

class SerialReaderThread : public QThread
{
    Q_OBJECT
public:
    explicit SerialReaderThread(QObject *parent = 0);

protected:
    virtual void run();

public slots:
    void sendCode();

signals:
    void codeArrived(char *code);

};

#endif // SERIALREADERTHREAD_H
