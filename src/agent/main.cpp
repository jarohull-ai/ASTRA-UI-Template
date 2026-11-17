#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSettings>
#include <QTimer>

#include "agentmodel.h"
#include "translator.h"

// Agent console host. The contract is the same as the dashboard shell:
// one model as `feed`, one translator as `i18n`, load the QML.
int main(int argc, char **argv) {
    QString shot, language;
    for (int i = 1; i < argc; i++) {
        const QString arg = argv[i];
        if (arg == "--screenshot")
            shot = i + 1 < argc ? QString(argv[i + 1]) : QStringLiteral("/tmp/astra-agent.png");
        else if (arg == "--language" && i + 1 < argc)
            language = argv[i + 1];
        else if (arg == "--demo")          // pre-run one turn so the screenshot has content
            qputenv("ASTRA_AGENT_DEMO", "1");
    }
    if (!shot.isEmpty())
        qputenv("QT_QPA_PLATFORM", "offscreen");

    QGuiApplication app(argc, argv);
    app.setApplicationName("astra-ui-agent");
    app.setOrganizationName("astra-ui-agent");
    app.setDesktopFileName("astra-ui-agent");
    QQuickStyle::setStyle("Material");

    Translator translator;
    {
        QSettings st("astra-ui-agent", "astra-ui-agent");
        translator.setChoice(st.value("language", "auto").toString());
    }
    QObject::connect(&translator, &Translator::changed, &translator, [&] {
        QSettings st("astra-ui-agent", "astra-ui-agent");
        st.setValue("language", translator.choice());
    });
    if (!language.isEmpty())
        translator.setChoice(language);
    app.installTranslator(&translator);

    AgentModel feed;
    QQmlApplicationEngine engine;
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty("feed", &feed);
    engine.rootContext()->setContextProperty("i18n", &translator);
    engine.load(QUrl("qrc:/qml/AgentMain.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    // A screenshot or a demo run needs a turn on screen: feed one prompt and let
    // it stream, so the transcript, the tool rows and the strip are all populated.
    if (!shot.isEmpty() || qEnvironmentVariableIsSet("ASTRA_AGENT_DEMO")) {
        QTimer::singleShot(300, &app, [&feed] { feed.send(QStringLiteral("run the tests")); });
    }
    if (!shot.isEmpty()) {
        QTimer::singleShot(9000, &app, [&] {
            auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            const bool ok = window->grabWindow().save(shot);
            app.exit(ok ? 0 : 2);
        });
    }
    return app.exec();
}
