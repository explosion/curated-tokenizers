#include <cstddef>
#include <unordered_map>
#include <utility>
#include <vector>

#include "merges.hh"

Merges::Merges(std::vector<Merge> const &merges) {
    for (size_t i = 0; i < merges.size(); i++) {
        MergeValue value;
        value.rank = static_cast<int>(i);
        value.merged_id = merges[i].merged_id;
        _merges[merges[i].merge] = value;
    }
}

std::vector<int> Merges::apply_merges(std::vector<int> ids) const {
    // This function could be optimized more, e.g.:
    //
    // * Use an LRU cache for frequent inputs.
    // * Keep a priority queue of merges rather than reconstucting
    //   a pair list each iteration.
    //
    // But let's see if performance is actually an issue in practice.

    while (ids.size() != 1) {
        auto iter = find_best_pair(ids);
        if (iter == _merges.end()) {
            break;
        }

        auto best_pair = iter->first;

        std::vector<int> new_ids;
        for (size_t i = 0; i < ids.size();) {
            if (i < ids.size() - 1 && ids[i] == best_pair.first && ids[i+1] == best_pair.second) {
                // Merge
                new_ids.emplace_back(iter->second.merged_id);
                i += 2;
            } else {
                // Copy
                new_ids.emplace_back(ids[i]);
                ++i;
            }

        }

        ids = new_ids;
    }
    
    return ids;
}

MergesMap::const_iterator Merges::find_best_pair(std::vector<int> const &ids) const {
    auto best_iter = _merges.end();
    size_t best_rank = _merges.size();
    for (size_t i = 0; i < ids.size() - 1; ++i) {
        auto cur_pair = std::make_pair(ids[i], ids[i + 1]);
        auto iter = _merges.find(cur_pair);
        if (iter == _merges.end()) {
            continue;
        }

        if (iter->second.rank < best_rank) {
            best_iter = iter;
            best_rank = iter->second.rank;
        }
    }

    return best_iter;
}

std::vector<merge_pair> Merges::merges() const {
    std::vector<merge_pair> merges(_merges.size());
    for (auto const &merge: _merges) {
        merges[merge.second.rank] = merge.first;
    }

    return merges;
}