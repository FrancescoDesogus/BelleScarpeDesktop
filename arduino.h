#ifndef ARDUINO_H
#define ARDUINO_H

#include <QObject>
#include <QTimer>
#include <QSerialPort>

/**
 * @brief The Arduino class si occupa di gestire l'arduino e permette di mandargli messaggi; la classe estende QObject
 *        in modo da poter essere usata nei QTimer
 */
class Arduino : public QObject
{
    Q_OBJECT

public:
    Arduino();

    bool turnOnLights(QString data);

private slots:
    bool turnOffAllLights();

private:
    static const QString PORT_NAME;
    static const int BAUD_RATE;
    static const int DATA_BITS;
    static const int PARITY;
    static const int STOP_BITS;
    static const QString SINGLE_LIGHTS_PREFIX;
    static const QString MOVING_MESSAGE_PREFIX;
    static const QString MOVING_MESSAGE_STOP_MOTION_PREFIX;
    static const QString TURN_OFF_LIGHTS_CODE;
    static const int TURN_OFF_TIME;

    //Oggetto che permette di mandare dati nella porta seriale
    QSerialPort serialPort;

    //Timer per spegnere le luci dopo un tot di tempo
    QTimer* arduinoTurnOffTimer;


    void setPortSettings();
};

#endif // ARDUINO_H
