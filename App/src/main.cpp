#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSqlDatabase>
#include <QStandardPaths>
#include <QStringList>
#include <QTextStream>

#include <exception>

#include <ViewModels/AppViewModel.h>
#include <ViewModels/LogViewModel.h>
#include <ViewModels/ReviewViewModel.h>

#include <QtQml/qqmlextensionplugin.h>
Q_IMPORT_QML_PLUGIN(TenjinViewPlugin)

// Global pointers used by the message handler. Set up in main before the
// handler is installed. The handler runs on whatever thread logged, so it
// marshals onto the LogModel's (GUI) thread via a queued invocation.
static LogViewModel*    g_logModel        = nullptr;
static QtMessageHandler g_previousHandler = nullptr;

static void tenjinMessageHandler(QtMsgType type, const QMessageLogContext& ctx, const QString& msg)
{
    // Keep the default behaviour (still prints to the terminal).
    if (g_previousHandler)
        g_previousHandler(type, ctx, msg);

    if (!g_logModel)
        return;

    QString level;
    switch (type) {
    case QtDebugMsg:
        level = QStringLiteral("debug");
        break;
    case QtInfoMsg:
        level = QStringLiteral("info");
        break;
    case QtWarningMsg:
        level = QStringLiteral("warning");
        break;
    case QtCriticalMsg:
        level = QStringLiteral("critical");
        break;
    case QtFatalMsg:
        level = QStringLiteral("critical");
        break;
    }
    QMetaObject::invokeMethod(
        g_logModel, "append", Qt::QueuedConnection, Q_ARG(QString, level), Q_ARG(QString, msg));
}

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Tenjin");
    app.setOrganizationName("Tenjin");
    app.setOrganizationDomain("tenjin.app");

    // Fusion is the only Quick Controls style guaranteed on every platform
    // without extra plugin dependencies.
    QQuickStyle::setStyle(QStringLiteral("Fusion"));

    // Construct the app/database layer. The DatabaseManager ctor throws if the
    // SQLite driver isn't available or the DB can't be opened. Log the failure
    // loudly: qCritical() goes to idevicesyslog, AND we write a fatal.txt to
    // AppDataLocation so the user can retrieve it via the Files app
    // (UIFileSharingEnabled=true). Without this, a Qt init failure looks
    // identical to a pre-main() AMFI kill: silent black-screen exit, no crash
    // report in Analytics Data.
    auto writeFatal = [](const QString& what) {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(dir);
        QFile log(dir + "/fatal.txt");
        if (log.open(QIODevice::Append | QIODevice::Text)) {
            QTextStream(&log) << QDateTime::currentDateTime().toString(Qt::ISODate) << " " << what
                              << "\n";
        }
    };

    // Pre-create AppDataLocation before anything tries to use it; on iOS the
    // directory returned by writableLocation() does not exist until mkpath'd,
    // and any sqlite3_open() / QSettings write below would fail SQLITE_CANTOPEN.
    QDir().mkpath(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));

    std::unique_ptr<AppViewModel> appVMPtr;
    try {
        appVMPtr = std::make_unique<AppViewModel>();
    } catch (const std::exception& e) {
        const QString msg = QStringLiteral("FATAL: app/database init failed: ") + e.what();
        qCritical().noquote() << msg;
        qCritical() << "Available SQL drivers:" << QSqlDatabase::drivers();
        writeFatal(msg);
        writeFatal(QStringLiteral("  drivers=") + QSqlDatabase::drivers().join(','));
        if (!QSqlDatabase::drivers().contains(QStringLiteral("QSQLITE"))) {
            const QString hint =
                QStringLiteral("QSQLITE driver NOT registered. On a static build the driver plugin "
                               "must be linked into the app (Qt6::QSQLiteDriverPlugin).");
            qCritical().noquote() << hint;
            writeFatal(hint);
        }
        return -1;
    } catch (...) {
        const QString msg = QStringLiteral("FATAL: unknown exception in AppViewModel ctor");
        qCritical().noquote() << msg;
        writeFatal(msg);
        return -1;
    }
    AppViewModel& appVM = *appVMPtr;

    // Debug-console log capture. Created before installing the handler.
    LogViewModel logModel;
    g_logModel        = &logModel;
    g_previousHandler = qInstallMessageHandler(tenjinMessageHandler);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("appVM", &appVM);
    engine.rootContext()->setContextProperty("reviewVm", appVM.reviewVM());
    engine.rootContext()->setContextProperty("logModel", &logModel);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [](const QUrl& url) {
            qCritical() << "QML creation FAILED:" << url;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    const QUrl url(QStringLiteral("qrc:/qt/qml/TenjinView/Main.qml"));
    qDebug() << "Loading:" << url;
    engine.load(url);
    qDebug() << "Root objects after load:" << engine.rootObjects().size();

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FAILED: no root objects for" << url;
        return -1;
    }
    return app.exec();
}
