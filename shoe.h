#ifndef SHOE_H
#define SHOE_H

#include <QObject>
#include <QString>
#include <vector>
#include <QVariantMap>

class Shoe : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int id READ getId CONSTANT )
    Q_PROPERTY(QString brand READ getBrand CONSTANT)
    Q_PROPERTY(QString model READ getModel CONSTANT)
    Q_PROPERTY(QString color READ getColor CONSTANT)
    Q_PROPERTY(QString sex READ getSex CONSTANT)
    Q_PROPERTY(float price READ getPrice CONSTANT)
    Q_PROPERTY(QString category READ getCategory CONSTANT)
    Q_PROPERTY(QVariantMap sizes READ getSizesAndQuantities)


public:
    explicit Shoe(int id, const QString& brand, const QString& model, const QString& color, const QString& sex, float price, const QString& category, const QVariantMap& sizesAndQuantities, const QString& mediaPath);


    void setId(int id);
    void setBrand(const QString& brand);
    void setModel(const QString& model);
    void setColor(const QString& color);
    void setSex(const QString& sex);
    void setPrice(float price);
    void setCategory(const QString& category);
    void setSizesAndQuantities(const QVariantMap& sizesAndQuantities);
    void setMediaPath(const QString& mediaPath);

    int getId();
    const QString& getBrand();
    const QString& getModel();
    const QString& getColor();
    const QString& getSex();
    float getPrice();
    const QString& getCategory();
    const QVariantMap& getSizesAndQuantities();
    const QString& getMediaPath();

    void toString();

private:
    int id;
    QString brand;
    QString model;
    QString color;
    QString sex;
    float price;
    QString category;
    QVariantMap sizesAndQuantities;
    QString mediaPath;

signals:

public slots:

};

#endif // SHOE_H
