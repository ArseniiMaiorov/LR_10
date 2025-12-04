#ifndef DATASTORE_H
#define DATASTORE_H

#include <QObject>
#include <QVariant>
#include <QStandardPaths>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

class DataStore : public QObject
{
    Q_OBJECT
public:
    explicit DataStore(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap loadData();
    Q_INVOKABLE bool saveData(const QVariantMap &data);
    Q_INVOKABLE bool exportNote(const QVariantMap &note, const QString &filePath);
    Q_INVOKABLE QString dataLocation() const;

private:
    QString dataFilePath() const;
    void ensureDataDir() const;
    QVariantMap defaultData() const;
};

#endif // DATASTORE_H