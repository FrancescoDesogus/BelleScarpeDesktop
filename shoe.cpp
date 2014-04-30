#include "shoe.h"
#include <vector>
#include <QString>
#include <QDebug>

using namespace std;


/**
 * @brief Shoe::Shoe
 * @param id
 * @param brand
 * @param model
 * @param color
 * @param sex
 * @param price
 * @param category
 * @param sizesAndQuantities
 * @param mediaPath
 *
 *
 */
Shoe::Shoe(int id, QString brand, const QString& model, QString color, QString sex, float price, QString category, std::map<float, int> sizesAndQuantities, QString mediaPath)
{
    this->setId(id);
    this->setBrand(brand);
    this->setModel(model);
    this->setColor(color);
    this->setSex(sex);
    this->setPrice(price);
    this->setCategory(category);
    this->setSizesAndQuantities(sizesAndQuantities);
    this->setMediaPath(mediaPath);


    QString s = "Cacca";
    const QString& sRef = s;

    QString tmp = "pupù";

//    sRef = tmp;

    const QString *ref = &sRef;

}



void Shoe::setId(int id)
{
    this->id = id;
}

void Shoe::setBrand(QString brand)
{
    this->brand = brand;
}

void Shoe::setModel(const QString& model)
{
    this->model = model;
}

void Shoe::setColor(QString color)
{
    this->color = color;
}

void Shoe::setSex(QString sex)
{
//    if(sex == "m")
//        this->sex = "Uomo";
//    else
//        this->sex = "Donna";
    this->sex = sex;
}

void Shoe::setPrice(float price)
{
    this->price = price;
}

void Shoe::setCategory(QString category)
{
    this->category = category;
}

void Shoe::setSizesAndQuantities(map<float, int> sizes)
{
    this->sizesAndQuantities = sizes;
}

void Shoe::setMediaPath(QString mediaPath)
{
    this->mediaPath = mediaPath;
}




int Shoe::getId()
{
    return this->id;
}

QString Shoe::getBrand()
{
    return this->brand;
}

QString Shoe::getModel()
{
    return this->model;
}

QString Shoe::getColor()
{
    return this->color;
}

QString Shoe::getSex()
{
    return this->sex;
}

float Shoe::getPrice()
{
    return this->price;
}

QString Shoe::getCategory()
{
    return this->category;
}

const map<float, int>& Shoe::getSizesAndQuantities()
{
    return this->sizesAndQuantities;
}

QString Shoe::getMediaPath()
{
    return this->mediaPath;
}


void Shoe::toString()
{
    qDebug() << this->id << ") brand: " << this->brand << "; model: " << this->model << "; color: " << this->color << "; sex: " << this->sex <<
                "; price: " << this->price << "; category: " << this->category << "; mediaPath: " << this->mediaPath;

    QString sizes;

    map<float, int>::iterator ii = this->sizesAndQuantities.begin();

    while (ii != this->sizesAndQuantities.end())
    {
        qDebug() << "    size: " << (*ii).first << "; quantity: " << (*ii).second;

        ii++;
    }
}
