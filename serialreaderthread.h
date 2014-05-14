#ifndef SERIALREADERTHREAD_H
#define SERIALREADERTHREAD_H

#include <QThread>
#include <QSerialPort>

class SerialReaderThread : public QThread
{
    Q_OBJECT

public:
    explicit SerialReaderThread(QObject *parent = 0);

private:
    static const QString PORT_NAME;
    static const int BAUD_RATE;
    static const int DATA_BITS;
    static const int PARITY;
    static const int STOP_BITS;

    static const int CODE_SIZE;
    static const int CHECKSUM_SIZE;

    QSerialPort serialPort;

    bool checkChecksum(char *buffer, char *code);

protected:
    virtual void run();

signals:
    void codeArrived(QString code);

};

#endif // SERIALREADERTHREAD_H
