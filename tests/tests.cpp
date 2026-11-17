#include <QtTest>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSettings>
#include <QTemporaryDir>

#include "dashboardmodel.h"
#include "translator.h"

// A minimal model: two percentage metrics and one that is not a percentage,
// so both chart axes get exercised.
class TestModel : public DashboardModel {
public:
    TestModel() : DashboardModel("astra-ui-test", "astra-ui-test") {
        addMetric("cpu", "Processor", "%", "#4fc3ff");
        addMetric("mem", "Memory", "%", "#b18cff");
        addMetric("rate", "Rate", "MiB/s", "#2fe0d0", false);
        sample();
    }
    void sample() override {
        publish("cpu", "42.0", "%", "detail", 42.0);
        publish("mem", "18.0", "%", QString(), 18.0);
        publish("rate", "3.20", "MiB/s", QString(), 3.2);
    }
};

class Tests : public QObject {
    Q_OBJECT
private:
    QTemporaryDir m_dir;

    // Every test gets an empty settings scope, so a previous run cannot decide
    // what this run considers the default layout.
    void freshScope() { QSettings("astra-ui-test", "astra-ui-test").clear(); }

private slots:
    void initTestCase() {
        QVERIFY(m_dir.isValid());
        QSettings::setPath(QSettings::NativeFormat, QSettings::UserScope, m_dir.path());
    }

    void catalogAndDefaults() {
        freshScope();
        TestModel m;
        QCOMPARE(m.catalog().size(), 3);
        // visibleByDefault=false keeps "rate" out of the first-run layout.
        QCOMPARE(m.order(), QStringList({"cpu", "mem"}));
    }

    void toggleMoveReset() {
        freshScope();
        TestModel m;
        m.toggle("rate");
        QCOMPARE(m.order(), QStringList({"cpu", "mem", "rate"}));
        m.move("rate", -1);
        QCOMPARE(m.order(), QStringList({"cpu", "rate", "mem"}));
        m.toggle("cpu");
        QVERIFY(!m.order().contains("cpu"));
        m.reset();
        QCOMPARE(m.order(), QStringList({"cpu", "mem", "rate"}));
    }

    void chartsAxes() {
        freshScope();
        TestModel m;
        // A percentage chart is pinned to 0-100; anything else follows the data.
        QCOMPARE(m.ceiling("cpu"), 100.0);
        QCOMPARE(m.ceiling("rate"), 3.2 * 1.2);
        QCOMPARE(m.card("cpu").value("value").toString(), QString("42.0"));
        QCOMPARE(m.card("cpu").value("history").toList().size(), 1);
    }

    void historyIsBounded() {
        QTemporaryDir dir;
        DashboardModel m("astra-ui-test-2", dir.path() + "/settings");
        m.addMetric("x", "X", "%");
        for (int i = 0; i < 120; i++)
            m.publish("x", QString::number(i), "%", QString(), i);
        QCOMPARE(m.card("x").value("history").toList().size(), 90);
    }

    void unavailableGreysOut() {
        QTemporaryDir dir;
        DashboardModel m("astra-ui-test-3", dir.path() + "/settings");
        m.addMetric("x", "X", "%");
        m.publish("x", "", "", "sensor missing", 0, false);
        const QVariantMap card = m.card("x");
        QCOMPARE(card.value("available").toBool(), false);
        QCOMPARE(card.value("value").toString(), QString::fromUtf8("\u2014"));
        QCOMPARE(card.value("unit").toString(), QString());
    }

    void persistence() {
        QTemporaryDir dir;
        {
            DashboardModel m("astra-ui-test-4", dir.path() + "/settings");
            m.addMetric("a", "A", "%");
            m.addMetric("b", "B", "%", QString(), false);
            m.toggle("b");
            m.setGlass(.6);
            m.setPalette("ice");
            m.move("b", -1);
        }
        DashboardModel restored("astra-ui-test-4", dir.path() + "/settings");
        restored.addMetric("a", "A", "%");
        restored.addMetric("b", "B", "%", QString(), false);
        QCOMPARE(restored.order(), QStringList({"b", "a"}));
        QCOMPARE(restored.glass(), .6);
        QCOMPARE(restored.accent(), QString("#70ddff"));
    }

    void stripRoundTrip() {
        freshScope();
        TestModel m;
        QVERIFY(m.strip().isEmpty());
        m.setStrip(QVariantMap{{"ready", true}, {"score", 97}, {"state", "healthy"}});
        QCOMPARE(m.strip().value("score").toInt(), 97);
        QCOMPARE(m.strip().value("state").toString(), QString("healthy"));
    }

    void languageSwitch() {
        QTemporaryDir dir;
        Translator t(dir.path() + "/language");
        QCoreApplication::installTranslator(&t);
        t.setChoice("pl");
        QCOMPARE(t.language(), QString("pl"));
        QCOMPARE(QCoreApplication::translate("x", "Edit layout"), QString("Edytuj układ"));
        QCOMPARE(QCoreApplication::translate("x", "HISTORY / 90 s"), QString("HISTORIA / 90 s"));
        t.setChoice("en");
        QCOMPARE(QCoreApplication::translate("x", "Edit layout"), QString("Edit layout"));
        t.setChoice("auto");
        QCOMPARE(t.language(), QString("en"));
        t.setChoice("not a code");
        QCOMPARE(t.choice(), QString("auto"));
        QCoreApplication::removeTranslator(&t);
    }

    void rendersAndResponds() {
        QQuickStyle::setStyle("Material");
        freshScope();
        TestModel model;
        QTemporaryDir dir;
        Translator translator(dir.path() + "/language");
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty("feed", &model);
        engine.rootContext()->setContextProperty("i18n", &translator);
        engine.load(QUrl("qrc:/qml/Main.qml"));
        QVERIFY(!engine.rootObjects().isEmpty());
        auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        QVERIFY(window);
        QTest::qWait(200);
        // The shell's own shortcuts: edit mode, pause.
        QTest::keyClick(window, Qt::Key_E);
        QCOMPARE(window->property("editing").toBool(), true);
        QTest::keyClick(window, Qt::Key_Space);
        QVERIFY(model.paused());
        // It must still draw when squeezed to the minimum size.
        window->resize(720, 600);
        QTest::qWait(150);
        QVERIFY(!window->grabWindow().isNull());
    }

};

QTEST_MAIN(Tests)
#include "tests.moc"
