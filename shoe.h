#ifndef SHOE_H
#define SHOE_H

#include <QObject>
#include <QString>
#include <vector>
#include <QVariantMap>

class Shoe : public QObject
{
    //La macro Q_OBJECT deve essere sempre chiamata quando si estende QObject
    Q_OBJECT

    /* Definisco una serie di proprietà che saranno visibili da QML se si inserisce un oggetto Shoe nel contesto. Per ogni
     * proprietà specifico il tipo ed il nome con cui sarà visibile in QML e stabilisco che metodo chiamare quando si usa
     * quella data proprietà (un getter). Nessuna proprietà modifica un valore della classe, quindi lo segnalo con CONSTANT.
     * Nota: per la map contenente le grandezze da visualzzare uso una QVariantMap perchè è direttamente usabile in QML come
     * un array associativo di javascript */
    Q_PROPERTY(int id READ getId CONSTANT)
    Q_PROPERTY(QString brand READ getBrand CONSTANT)
    Q_PROPERTY(QString model READ getModel CONSTANT)
    Q_PROPERTY(QString color READ getColor CONSTANT)
    Q_PROPERTY(QString sex READ getSex CONSTANT)
    Q_PROPERTY(float price READ getPrice CONSTANT)
    Q_PROPERTY(QString category READ getCategory CONSTANT)
    Q_PROPERTY(QVariantMap sizes READ getSizesAndQuantities CONSTANT)
    Q_PROPERTY(QString thumbnail READ getThumbnailPath CONSTANT)


public:
    //Costruttore
    explicit Shoe(int id, const QString& brand, const QString& model, const QString& color, const QString& sex, float price, const QString& category, const QVariantMap& sizesAndQuantities, const QString& mediaPath, const QString& RFIDcode);

    //Setter
    void setId(int id);
    void setBrand(const QString& brand);
    void setModel(const QString& model);
    void setColor(const QString& color);
    void setSex(const QString& sex);
    void setPrice(float price);
    void setCategory(const QString& category);
    void setSizesAndQuantities(const QVariantMap& sizesAndQuantities);
    void setMediaPath(const QString& mediaPath);
    void setRFIDcode(const QString& RFIDcode);
    void setThumbnailPath(const QString& thumbnailPath);


    //Getter
    int getId();
    const QString& getBrand();
    const QString& getModel();
    const QString& getColor();
    const QString& getSex();
    float getPrice();
    const QString& getCategory();
    const QVariantMap& getSizesAndQuantities();
    const QString& getMediaPath();
    const QString& getRFIDcode();
    const QString& getThumbnailPath();

    void toString();

private:
    //Campi della classe
    int id;
    QString brand;
    QString model;
    QString color;
    QString sex;
    float price;
    QString category;
    QVariantMap sizesAndQuantities; //La map è da String a bool (ogni taglia ha associato un bool per indicare se è disponibile)
    QString mediaPath;
    QString RFIDcode;
    QString thumbnailPath;

signals:

public slots:

};

#endif // SHOE_H
