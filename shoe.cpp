#include "shoe.h"
#include <vector>
#include <QString>
#include <QDebug>

using namespace std;


/**
 * @brief Shoe::Shoe costruttore. Tutti gli oggetti vengono passati come "const Object&" ìn modo tale che venga passato il riferimento all'oggetto
 *        al costruttore. In pratica, per evitare che passare ogni oggetto al costruttore equivalga a fare una copia dello stesso (inefficiente),
 *        viene passato il suo riferimento, tipo un puntatore. La differenza con un puntatore è che l'oggeto si utilizza sempre con il . invece
 *        che con ->, ed è così che generalmente si fa per passare oggetti a membri di una classe.
 *        Lo stesso viene fatto per ogni setter e getter della classe, in modo da evitare il più possibile di fare copie di oggetti
 *

  Esempio 1:

  QString s = "asd";
  QString& sRef = s;

  sRef = "ciao";  //Dopo questa istruzione s == "ciao"

  ****************

  Esempio 2:

  QString s = "asd";
  QString& sRef = s;

  QString tmp = "asdasd";

  sRef = tmp  //Dopo questa istruzione s == "asdasd". sRef non "punta" a tmp, continua SEMPRE a puntare a s

  ****************

  Esempio 3:

  QString s = "asd";
  const QString& sRef = s;

  QString tmp = "asdasd";

  sRef = tmp  //Errore di compilazione: dato che sRef è const, non si può fare l'assegnamento; in questo modo è un po' come usare un puntatore
              //solo che il riferimento è sempre uguale, non c'è rischio che cambi l'oggetto puntato

 *
 *
 */
Shoe::Shoe(int id, const QString& brand, const QString& model, const QString& color, const QString& sex, float price, const QString& category, const QVariantMap& sizesAndQuantities, const QString& mediaPath, const QString& RFIDcode)
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
    this->setRFIDcode(RFIDcode);
}



void Shoe::setId(int id)
{
    this->id = id;
}

void Shoe::setBrand(const QString& brand)
{
    this->brand = brand;
}

void Shoe::setModel(const QString& model)
{
    this->model = model;
}

void Shoe::setColor(const QString& color)
{
    this->color = color;
}

void Shoe::setSex(const QString &sex)
{
    this->sex = sex;
}

void Shoe::setPrice(float price)
{
    this->price = price;
}

void Shoe::setCategory(const QString& category)
{
    this->category = category;
}

void Shoe::setSizesAndQuantities(const QVariantMap &sizes)
{
    this->sizesAndQuantities = sizes;
}

void Shoe::setMediaPath(const QString& mediaPath)
{
    this->mediaPath = mediaPath;
}

void Shoe::setRFIDcode(const QString& RFIDcode)
{
    this->RFIDcode = RFIDcode;
}

void Shoe::setThumbnailPath(const QString& thumbnailPath)
{
    this->thumbnailPath = thumbnailPath;
}




int Shoe::getId()
{
    return this->id;
}

const QString& Shoe::getBrand()
{
    return this->brand;
}

const QString& Shoe::getModel()
{
    return this->model;
}

const QString& Shoe::getColor()
{
    return this->color;
}

const QString& Shoe::getSex()
{
    return this->sex;
}

float Shoe::getPrice()
{
    return this->price;
}

const QString& Shoe::getCategory()
{
    return this->category;
}

const QVariantMap& Shoe::getSizesAndQuantities()
{
    return this->sizesAndQuantities;
}

const QString &Shoe::getMediaPath()
{
    return this->mediaPath;
}

const QString &Shoe::getRFIDcode()
{
    return this->RFIDcode;
}

const QString &Shoe::getThumbnailPath()
{
    return this->thumbnailPath;
}


void Shoe::toString()
{
    qDebug() << this->id << ") brand: " << this->brand << "; model: " << this->model << "; color: " << this->color << "; sex: " << this->sex <<
                "; price: " << this->price << "; category: " << this->category << "; mediaPath: " << this->mediaPath << "; RFIDcode: " + this->RFIDcode;
}
