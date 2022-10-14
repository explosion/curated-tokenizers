#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "merges.hh"

Merges::Merges(std::vector<string_pair> const &merges) {
    for (size_t i = 0; i < merges.size(); i++) {
        _merges[merges[i]] = i;
    }
}

std::vector<std::string> Merges::apply_merges(std::vector<std::string> pieces) const {
    // This function could be optimized more, e.g.:
    //
    // * Use an LRU cache for frequent inputs.
    // * Keep a priority queue of merges rather than reconstucting
    //   a pair list each iteration.
    //
    // But let's see if performance is actually an issue in practice.

    while (pieces.size() != 1) {
        auto best_pair = find_best_pair(pieces);
        if (best_pair.first.empty() && best_pair.second.empty()) {
            break;
        }

        std::vector<std::string> new_pieces;
        for (size_t i = 0; i < pieces.size();) {
            if (i < pieces.size() - 1 && pieces[i] == best_pair.first && pieces[i+1] == best_pair.second) {
                // Merge
                new_pieces.emplace_back(pieces[i] + pieces[i + 1]);
                i += 2;
            } else {
                // Copy
                new_pieces.emplace_back(pieces[i]);
                ++i;
            }

        }

        pieces = new_pieces;
    }
    
    return pieces;
}

string_pair Merges::find_best_pair(std::vector<std::string> const &pieces) const {
    string_pair best_pair;
    size_t best_rank = _merges.size();
    for (size_t i = 0; i < pieces.size() - 1; ++i) {
        auto cur_pair = std::make_pair(pieces[i], pieces[i + 1]);
        auto iter = _merges.find(cur_pair);
        if (iter == _merges.end()) {
            continue;
        }

        if (iter->second < best_rank) {
            best_pair = cur_pair;
            best_rank = iter->second;
        }
    }

    return best_pair;
}

std::vector<std::pair<std::string, std::string>> Merges::merges() const {
    std::vector<std::pair<std::string, std::string>> merges(_merges.size());
    for (auto const &merge: _merges) {
        merges[merge.second] = merge.first;
    }

    return merges;
}