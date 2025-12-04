#include "datastore.h"

#include <QDir>
#include <QTextStream>
#include <QDateTime>

DataStore::DataStore(QObject *parent) : QObject(parent) {}

QString DataStore::dataLocation() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

QString DataStore::dataFilePath() const
{
    return dataLocation() + QDir::separator() + QStringLiteral("notes.json");
}

void DataStore::ensureDataDir() const
{
    const QString dirPath = dataLocation();
    QDir dir(dirPath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }
}

QVariantMap DataStore::defaultData() const
{
    QVariantMap subscription;
    subscription[QStringLiteral("plan")] = QStringLiteral("Free");
    subscription[QStringLiteral("active")] = false;
    subscription[QStringLiteral("expiration")] = QString();

    QVariantMap defaultNote;
    defaultNote[QStringLiteral("id")] = QStringLiteral("welcome-note");
    defaultNote[QStringLiteral("title")] = QStringLiteral("Добро пожаловать");
    defaultNote[QStringLiteral("content")] = QStringLiteral("Начните создавать свои первые заметки и блокноты.");
    defaultNote[QStringLiteral("attachments")] = QVariantList();
    defaultNote[QStringLiteral("lastModified")] = QDateTime::currentDateTime().toString(Qt::ISODate);

    QVariantMap defaultNotebook;
    defaultNotebook[QStringLiteral("id")] = QStringLiteral("default-notebook");
    defaultNotebook[QStringLiteral("title")] = QStringLiteral("Мои заметки");
    defaultNotebook[QStringLiteral("notes")] = QVariantList{defaultNote};

    QVariantMap data;
    data[QStringLiteral("subscription")] = subscription;
    data[QStringLiteral("notebooks")] = QVariantList{defaultNotebook};
    return data;
}

QVariantMap DataStore::loadData()
{
    ensureDataDir();
    QFile file(dataFilePath());
    if (!file.exists()) {
        const QVariantMap defaults = defaultData();
        saveData(defaults);
        return defaults;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        return defaultData();
    }

    const QByteArray bytes = file.readAll();
    file.close();

    const QJsonDocument doc = QJsonDocument::fromJson(bytes);
    if (!doc.isObject()) {
        return defaultData();
    }

    return doc.object().toVariantMap();
}

bool DataStore::saveData(const QVariantMap &data)
{
    ensureDataDir();
    QFile file(dataFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }

    const QJsonDocument doc = QJsonDocument::fromVariant(data);
    const QByteArray bytes = doc.toJson(QJsonDocument::Indented);
    const qint64 written = file.write(bytes);
    file.close();
    return written == bytes.size();
}

bool DataStore::exportNote(const QVariantMap &note, const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        return false;
    }

    QTextStream stream(&file);
    stream.setEncoding(QStringConverter::Utf8);

    const QString title = note.value(QStringLiteral("title")).toString();
    const QString content = note.value(QStringLiteral("content")).toString();
    const QVariantList attachments = note.value(QStringLiteral("attachments")).toList();
    const QString lastModified = note.value(QStringLiteral("lastModified")).toString();

    stream << "Заметка: " << title << "\n";
    stream << "Последнее изменение: " << lastModified << "\n\n";
    stream << content << "\n\n";

    if (!attachments.isEmpty()) {
        stream << "Вложения:" << "\n";
        for (const QVariant &attachmentVar : attachments) {
            const QVariantMap attachment = attachmentVar.toMap();
            stream << "- [" << attachment.value(QStringLiteral("type")).toString() << "] "
                   << attachment.value(QStringLiteral("path")).toString() << "\n";
        }
    }

    file.close();
    return true;
}