#pragma once

#include <string>
#include <unordered_map>
#include <vector>

#include "util.hh"

struct Piece {
    std::string piece;
    bool is_initial;

    Piece()
        : piece(), is_initial(false) {}
    Piece(const std::string &piece, bool initial)
        : piece(piece), is_initial(initial) {}

    bool operator==(const Piece &rhs) const {
        return piece == rhs.piece && is_initial == rhs.is_initial;
    }
};

struct PieceHash {
    size_t operator()(const Piece &piece) const {
        size_t seed = 0;
        hash_combine(seed, piece.piece);
        hash_combine(seed, piece.is_initial);
        return seed;
    }
};

struct PieceStorage {
    std::vector<Piece> _id_to_piece;
    std::unordered_map<Piece, size_t, PieceHash> _piece_to_id;

    void add_piece(const std::string &piece, const bool is_initial);
    size_t size() const;
    const Piece &id_to_piece(const int id) const;
    size_t piece_to_id(const Piece &piece) const;
    int try_piece_to_id(const Piece &piece) const;
};