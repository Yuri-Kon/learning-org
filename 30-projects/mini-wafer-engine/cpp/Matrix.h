#pragma once

#include <cstddef>
#include <vector>

class Matrix {
    public:
    Matrix(std::size_t rows, std::size_t cols, double initial_value = 0.0);

    std::size_t rows() const;
    std::size_t cols() const;

    double& at(std::size_t row, std::size_t col);
    double at(std::size_t row, std::size_t col) const;
    private:
    std::size_t rows_;
    std::size_t cols_;
    std::vector<double> data_;
};
