#pragma once

#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

typedef std::pair<std::string, std::string> string_pair;

// Hash combine function from Boost.
template <class T>
inline void hash_combine(std::size_t& seed, const T& v)
{
    std::hash<T> hasher;
    seed ^= hasher(v) + 0x9e3779b9 + (seed<<6) + (seed>>2);
}

struct PairHash {
    template <typename T, typename U>
    size_t operator()(std::pair<T, U> const &pair) const {
        size_t seed = 0;
        hash_combine(seed, pair.first);
        hash_combine(seed, pair.second);
        return seed;
    }
};

class Merges {
public:
    Merges(std::vector<string_pair> const &merges);

    /**
     * Apply merges to the given an initial set of pieces (usually string
     * representations of bytes).
     * 
     * @param pieces The pieces to merge
     * @return std::vector<std::string> Pieces after applying merges.
     */
    std::vector<std::string> apply_merges(std::vector<std::string> pieces) const;
    
    /**
     * Get all merges used by the BBPE instance.
     * 
     * @return std::vector<std::pair<std::string, std::string>> 
     */
    std::vector<std::pair<std::string, std::string>> merges() const;
private:
    string_pair find_best_pair(std::vector<std::string> const &pieces) const;
    std::unordered_map<string_pair, size_t, PairHash> _merges;
};