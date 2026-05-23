#pragma once

#include <QSqlDatabase>

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace Service {

// ── Aliases ───────────────────────────────────────────────────────────────────
template <typename T>
using Result_t = std::expected<T, std::string>;

using ID_t        = std::int64_t;
using Timestamp_t = std::string;

// ── Enums ─────────────────────────────────────────────────────────────────────
enum class ContentType_t : std::uint8_t {
    Definition = 0,
    MediaPath  = 1,
    Note       = 2,
    Divider    = 3,
};

enum class FilterMode_t : std::uint8_t {
    And = 0,
    Or  = 1,
};

// ── Structs ───────────────────────────────────────────────────────────────────
struct Word_t {
    ID_t        id;
    std::string word;
    Timestamp_t createdAt;
};

struct Tag_t {
    ID_t        id;
    std::string name;
};

struct ContentBlock_t {
    ID_t          id;
    ID_t          wordId;
    ContentType_t type;
    std::string   content;
    int           row;
    int           col;
    int           rowSpan;
    int           colSpan;
    std::string   pos; // part of speech (definitions only); empty otherwise
};

struct WordRelation_t {
    ID_t        id;
    ID_t        wordId;
    ID_t        wordRelationId;
    std::string relationType;
};

struct Deck_t {
    ID_t         id;
    std::string  name;
    bool         bIsSmart;
    FilterMode_t filterMode;
    Timestamp_t  createdAt;
};

struct Review_t {
    ID_t          id;
    ID_t          deckId;
    ID_t          wordId;
    float         easeFactor;
    std::uint16_t intervalDays;
    std::uint16_t repetitions;
    Timestamp_t   nextReviewDate;
    Timestamp_t   lastReviewDate;
};

// ── DatabaseManager ───────────────────────────────────────────────────────────
class DatabaseManager
{
public:
    explicit DatabaseManager(const std::string& filepath);
    ~DatabaseManager();

    DatabaseManager(const DatabaseManager&)            = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;
    DatabaseManager(DatabaseManager&&)                 = delete;
    DatabaseManager& operator=(DatabaseManager&&)      = delete;

    // ── Word ─────────────────────────────────────────────────────────────────
    Result_t<Word_t>              AddWord(const std::string& word);
    Result_t<Word_t>              GetWord(const std::string& word);
    Result_t<std::vector<Word_t>> GetAllWords();
    Result_t<bool>                DeleteWord(ID_t id);

    // ── Tag ──────────────────────────────────────────────────────────────────
    Result_t<Tag_t>              AddTag(const std::string& name);
    Result_t<Tag_t>              GetTag(std::string_view name);
    Result_t<std::vector<Tag_t>> GetAllTags();
    Result_t<bool>               DeleteTag(ID_t id);

    // ── Word ↔ Tag ────────────────────────────────────────────────────────────
    Result_t<bool>                AddTagToWord(ID_t wordId, ID_t tagId);
    Result_t<bool>                RemoveTagFromWord(ID_t wordId, ID_t tagId);
    Result_t<std::vector<Tag_t>>  GetTagsForWord(ID_t wordId);
    Result_t<std::vector<Word_t>> GetWordsForTag(ID_t tagId);

    // ── Content Blocks ────────────────────────────────────────────────────────
    Result_t<ContentBlock_t>              AddContentBlock(const ContentBlock_t& block);
    Result_t<ContentBlock_t>              UpdateContentBlock(const ContentBlock_t& block);
    Result_t<bool>                        DeleteContentBlock(ID_t id);
    Result_t<std::vector<ContentBlock_t>> GetContentForWord(ID_t wordId);
    Result_t<bool> SaveContentLayout(const std::vector<ContentBlock_t>& blocks);

    // ── Full-Text Search (FTS5) ───────────────────────────────────────────────
    Result_t<std::vector<Word_t>>         SearchWords(const std::string& query);
    Result_t<std::vector<ContentBlock_t>> SearchContent(const std::string& query);

    // ── Substring search (LIKE) ───────────────────────────────────────────────
    // Case-insensitive substring match on the word text / tag name. Used for the
    // search dropdown so partial matches work even for words with no content.
    Result_t<std::vector<Word_t>> SearchWordsByName(const std::string& substring);
    Result_t<std::vector<Tag_t>>  SearchTagsByName(const std::string& substring);
    // Words whose content blocks contain the substring (any block).
    Result_t<std::vector<Word_t>> SearchWordsByContent(const std::string& substring);

    // ── Word Relations ────────────────────────────────────────────────────────
    Result_t<WordRelation_t> AddWordRelation(ID_t wordId, ID_t relatedId, const std::string& type);
    Result_t<bool>           RemoveWordRelation(ID_t id);
    Result_t<std::vector<WordRelation_t>> GetRelationsForWord(ID_t wordId);

    // ── Deck ──────────────────────────────────────────────────────────────────
    Result_t<Deck_t>              AddDeck(const std::string& name, bool isSmart, FilterMode_t mode);
    Result_t<Deck_t>              GetDeck(ID_t id);
    Result_t<std::vector<Deck_t>> GetAllDecks();
    Result_t<bool>                DeleteDeck(ID_t id);

    // ── Deck ↔ Word (manual decks) ────────────────────────────────────────────
    Result_t<bool> AddWordToDeck(ID_t deckId, ID_t wordId);
    Result_t<bool> RemoveWordFromDeck(ID_t deckId, ID_t wordId);

    // ── Deck ↔ Tag (smart deck filters) ───────────────────────────────────────
    Result_t<bool>               AddTagFilterToDeck(ID_t deckId, ID_t tagId);
    Result_t<bool>               RemoveTagFilterFromDeck(ID_t deckId, ID_t tagId);
    Result_t<std::vector<Tag_t>> GetTagFiltersForDeck(ID_t deckId);

    // ── Review (SM-2) ─────────────────────────────────────────────────────────
    Result_t<Review_t>              InitReview(ID_t deckId, ID_t wordId);
    Result_t<Review_t>              SubmitReview(ID_t deckId, ID_t wordId, int quality);
    Result_t<std::vector<Review_t>> GetDueReviews(ID_t deckId);

    // ── Cross-table ───────────────────────────────────────────────────────────
    Result_t<std::vector<Word_t>> GetWordsForDeck(ID_t deckId);
    Result_t<std::vector<Word_t>> GetWordsByTags(const std::vector<ID_t>& tagIds,
                                                 FilterMode_t             mode);

    // ── Import / Export ───────────────────────────────────────────────────────
    // Serialize the whole collection to a JSON document and write it to path.
    Result_t<bool> ExportToJson(const QString& path);
    // Merge a JSON document into the collection. Matching is by guid; for an
    // existing record the incoming version wins only if its updated_at is newer
    // (last-write-wins per record). New records are inserted. Nothing is deleted.
    Result_t<bool> ImportFromJson(const QString& path);

private:
    // Assign a guid to any row in word/tag/deck/word_content that has none.
    void backfillGuids();

    QSqlDatabase m_db;
};

} // namespace Service
