#include <stdexcept>

#include "wordpiece.hh"

void PieceStorage::add_piece(const std::string &piece, const bool is_initial) {
    _id_to_piece.emplace_back(piece, is_initial);
    _piece_to_id.emplace(std::move(Piece(piece, is_initial)), _id_to_piece.size() - 1);
}

size_t PieceStorage::size() const {
    return _id_to_piece.size();
}

const Piece &PieceStorage::id_to_piece(const int id) const {
    if (id < 0 || id >= size()) {
        throw std::runtime_error("invalid piece ID '" + std::to_string(id) + "'");
    }

    return _id_to_piece[id];
}

size_t PieceStorage::piece_to_id(const Piece &piece) const {
    const auto idx = _piece_to_id.find(piece);
    if (idx != _piece_to_id.cend()) {
        return idx->second;
    } else {
        throw std::runtime_error("unknown piece '(" + piece.piece + ", " + std::to_string(piece.is_initial) + ")'");
    }
}

int PieceStorage::try_piece_to_id(const Piece &piece) const {
    const auto idx = _piece_to_id.find(piece);
    if (idx != _piece_to_id.cend()) {
        return idx->second;
    } else {
        return -1;
    }
}