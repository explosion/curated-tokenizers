#pragma once

#include <string>

struct Piece {
    std::string piece;
    bool is_initial;

    Piece(const std::string &piece, bool initial)
        : piece(piece), is_initial(initial) {}
};