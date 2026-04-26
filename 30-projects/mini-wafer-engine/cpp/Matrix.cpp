#include "Matrix.h"

#include <stdexcept>

Matrix::Matrix(std::size_t rows, std::size_t cols, double initial_value)
    : rows_(rows), cols_(cols), data_(rows * cols, initial_value) {}

std::size_t Matrix::rows() const {
  return rows_;
}

std::size_t Matrix::cols() const {
  return cols_;
}

double& Matrix::at(std::size_t row, std::size_t col) {
  if (row >= rows_ || col >= cols_) {
    throw std::out_of_range("Matrix index out of range");
  }
  return data_[row * cols_ + col];
}

double Matrix::at(std::size_t row, std::size_t col) const {
  if (row >= rows_ || col >= cols_) {
    throw std::out_of_range("Matrix index out of range");
  }
  return data_[row * cols_ + col];
}
