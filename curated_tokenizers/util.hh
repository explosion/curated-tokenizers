#pragma once

#include <utility>

// Hash combine function from Boost, see
// https://www.boost.org/doc/libs/1_55_0/doc/html/hash/combine.html
// for usage information.
template <class T>
inline void hash_combine(std::size_t& seed, const T& v)
{
    std::hash<T> hasher;
    seed ^= hasher(v) + 0x9e3779b9 + (seed<<6) + (seed>>2);
}
