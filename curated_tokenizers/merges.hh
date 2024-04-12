#pragma once

#include <cstddef>
#include <unordered_map>
#include <utility>
#include <vector>

#include "util.hh"

typedef std::pair<int, int> merge_pair;

struct PairHash {
    template <typename T, typename U>
    size_t operator()(std::pair<T, U> const &pair) const {
        size_t seed = 0;
        hash_combine(seed, pair.first);
        hash_combine(seed, pair.second);
        return seed;
    }
};

/**
 * Merge operation.
 */
struct Merge {
    merge_pair merge;
    int merged_id;
};


/**
 * Value of merges used in the merge lookup table. 
 */
struct MergeValue {
    int rank;
    int merged_id;
};

typedef std::unordered_map<merge_pair, MergeValue, PairHash> MergesMap;

class Merges {
public:
    Merges(std::vector<Merge> const &merges);

    /**
     * Apply merges to the given an initial set of piece ids.
     * 
     * @param ids The ids to merge
     * @return std::vector<int> Ids after applying merges.
     */
    std::vector<int> apply_merges(std::vector<int> ids) const;
    
    /**
     * Get all merges used by the BBPE instance.
     * 
     * @return std::vector<std::pair<int, int>> 
     */
    std::vector<merge_pair> merges() const;
private:
    MergesMap::const_iterator find_best_pair(std::vector<int> const &ids) const;
    MergesMap _merges;
};