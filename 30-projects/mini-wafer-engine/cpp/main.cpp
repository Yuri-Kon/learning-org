#include "Matrix.h"
#include <iostream>

int main() {
  Matrix wafer(3, 4, 0.0);

  wafer.at(0, 0) = 1.5;
  wafer.at(1, 2) = 9.8;

  std::cout << "Mini Wafer Processing Engine started.\n";
  std::cout << "rows = " << wafer.rows() << "\n";
  std::cout << "cols = " << wafer.cols() << "\n";
  std::cout << "value(1, 2) = " << wafer.at(1, 2) << "\n";

  return 0;
}
