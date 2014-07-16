#ifndef SERIALREADERTHREAD_H
#define SERIALREADERTHREAD_H

#include <QThread>
#include <QTimer>
#include <QSerialPort>

/**
 * @brief The SerialReaderThread class per gestire l'RFID Reader in un thread separato
 */
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

    static const int PACKET_SIZE;
    static const int CODE_SIZE;
    static const int CHECKSUM_SIZE;

    static const int INTERVAL_BETWEEN_PACKETS;

    QSerialPort serialPort;

    bool checkChecksum(char *buffer, char *code);

protected:
    virtual void run();

public slots:
    void prepareToQuit();

signals:
    //Signal che avvisa il main thread è che arrivato un codice RFID di una scarpa
    void codeArrived(QString code);

};

#endif // SERIALREADERTHREAD_H
