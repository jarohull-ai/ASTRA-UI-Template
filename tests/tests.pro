QT += core gui qml quick quickcontrols2 testlib
CONFIG += c++17 testcase
TARGET = tests

INCLUDEPATH += ../src

SOURCES += tests.cpp ../src/dashboardmodel.cpp ../src/translator.cpp
HEADERS += ../src/dashboardmodel.h ../src/translator.h
RESOURCES += ../src/resources.qrc
