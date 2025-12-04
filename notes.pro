QT += quick quickcontrols2
CONFIG += c++17

SOURCES += \
    src/main.cpp \
    src/datastore.cpp

HEADERS += \
    src/datastore.h

RESOURCES += qml/qml.qrc

# Minimum Qt version requirement
QT_MIN_VERSION = 6.8

# Target configuration
TARGET = NotesApp
TEMPLATE = app

# Ensure the build links against shared Qt libraries (avoid static image format deps)
CONFIG -= static staticlib
CONFIG += shared

# Enable high DPI scaling
DEFINES += QT_DEPRECATED_WARNINGS
CONFIG += c++17