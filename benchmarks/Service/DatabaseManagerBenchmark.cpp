#include <DatabaseManager/DatabaseManager.h>

#include <QCoreApplication>
#include <benchmark/benchmark.h>

#include <filesystem>
#include <memory>
#include <string>

namespace {

std::unique_ptr<Service::DatabaseManager> makeDb()
{
    static int counter = 0;
    const auto path    = std::filesystem::temp_directory_path() /
                         ("tenjin-bench-" + std::to_string(++counter) + ".db");
    return std::make_unique<Service::DatabaseManager>(path.string());
}

void BM_AddWord(benchmark::State& state)
{
    auto db = makeDb();
    int  i  = 0;
    for (auto _ : state) {
        auto r = db->AddWord("word-" + std::to_string(i++));
        benchmark::DoNotOptimize(r);
    }
}
BENCHMARK(BM_AddWord);

void BM_GetAllWords(benchmark::State& state)
{
    auto db = makeDb();
    for (int i = 0; i < state.range(0); ++i) {
        (void)db->AddWord("word-" + std::to_string(i));
    }
    for (auto _ : state) {
        auto r = db->GetAllWords();
        benchmark::DoNotOptimize(r);
    }
    state.SetItemsProcessed(int64_t(state.iterations()) * state.range(0));
}
BENCHMARK(BM_GetAllWords)->Arg(100)->Arg(1000)->Arg(10000);

} // namespace

int main(int argc, char** argv)
{
    QCoreApplication app(argc, argv);
    benchmark::Initialize(&argc, argv);
    if (benchmark::ReportUnrecognizedArguments(argc, argv))
        return 1;
    benchmark::RunSpecifiedBenchmarks();
    benchmark::Shutdown();
    return 0;
}
