#ifndef SERIALREADERTHREAD_H
#define SERIALREADERTHREAD_H

#include <QThread>
#include <QTimer>
#include <QSerialPort>

/**
 * @brief The SerialReaderThread class per gestire l'RFID Reader in un thread separato. L'uso del thread è fatto seguendo
 *        l'idea del worker-object (motivo per cui la classe estende QObject); il thread è creato nel costruttore della classe
 *        e l'istanza della classe viene subito spostata in quel thread
 */
class SerialReaderThread : public QObject
{
    Q_OBJECT

public:
    explicit SerialReaderThread(QObject *parent = 0);
    ~SerialReaderThread();

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

    //Riferimento al thread vero e proprio
    QThread* thread;

    //Oggetto per leggere dalla porta seriale
    QSerialPort serialPort;

    //Booleano che indica se è possibile ricevere pacchetti (in realtà vengono sempre ricevuti, ma se questo bool è
    //false non vengono processati)
    bool canReceivePackets;

    //Timer per riabilitare la ricezione dei pacchetti dopo l'arrivo di uno
    QTimer* timerInterval;


    bool checkChecksum(char *buffer, char *code);

private slots:
    void run();
    void allowIncomingPackets();

signals:
    //Signal che avvisa il main thread è che arrivato un codice RFID di una scarpa
    void codeArrived(QString code);

};

#endif // SERIALREADERTHREAD_H
