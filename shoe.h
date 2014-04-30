#ifndef SHOE_H
#define SHOE_H

#include <QObject>
#include <QString>
#include <vector>

class Shoe : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int id READ getId)
    Q_PROPERTY(QString brand READ getBrand)
    Q_PROPERTY(QString model READ getModel)
    Q_PROPERTY(QString color READ getColor)
    Q_PROPERTY(QString sex READ getSex)
    Q_PROPERTY(float price READ getPrice)
    Q_PROPERTY(QString category READ getCategory)
//    Q_PROPERTY(QString sizes READ getBrand)


public:
    explicit Shoe(int id, const QString& brand, const QString& model, const QString& color, const QString& sex, float price, const QString& category, const std::map<float, int>& sizesAndQuantities, const QString& mediaPath);


    void setId(int id);
    void setBrand(const QString& brand);
    void setModel(const QString& model);
    void setColor(const QString& color);
    void setSex(const QString& sex);
    void setPrice(float price);
    void setCategory(const QString& category);
    void setSizesAndQuantities(const std::map<float, int>& sizesAndQuantities);
    void setMediaPath(const QString& mediaPath);

    int getId();
    const QString& getBrand();
    const QString& getModel();
    const QString& getColor();
    const QString& getSex();
    float getPrice();
    const QString& getCategory();
    const std::map<float, int>& getSizesAndQuantities();
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
    std::map<float, int> sizesAndQuantities;
    QString mediaPath;

signals:

public slots:

};

#endif // SHOE_H
