#ifndef SHOE_H
#define SHOE_H

#include <QObject>
#include <QString>
#include <vector>

class Shoe : public QObject
{
    Q_OBJECT
public:
//    explicit Shoe(int id, QString brand, QString model, QString color, QString sex, float price, QString category, std::vector<float> sizes, QString mediaPath, QObject *parent = 0);
    explicit Shoe(int id, QString brand, QString model, QString color, QString sex, float price, QString category, std::map<float, int> sizesAndQuantities, QString mediaPath);
    explicit Shoe(QObject *parent = 0);


    void setId(int id);
    void setBrand(QString brand);
    void setModel(QString model);
    void setColor(QString color);
    void setSex(QString sex);
    void setPrice(float price);
    void setCategory(QString category);
    void setSizesAndQuantities(std::map<float, int> sizesAndQuantities);
    void setMediaPath(QString mediaPath);

    int getId();
    QString getBrand();
    QString getModel();
    QString getColor();
    QString getSex();
    float getPrice();
    QString getCategory();
    const std::map<float, int>& getSizesAndQuantities();
    QString getMediaPath();

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
