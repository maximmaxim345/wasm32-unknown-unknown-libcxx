#include "test.hpp"
#include <algorithm>
#include <cmath>
#include <inttypes.h>
#include <numeric>
#include <vector>

int AutoCxxTestFunction(int a, int b, int c) { return CxxTestFunction(a, b, c); }

// This is some example code that uses various C++ standard library functions
int CxxTestFunction(int a, int b, int c) {
  // Create a vector with the input parameters
  std::vector<int> numbers = {a, b, c};

  // Use std::sort to sort the vector in ascending order
  std::sort(numbers.begin(), numbers.end());

  // Use std::accumulate to sum up all the elements
  int sum = std::accumulate(numbers.begin(), numbers.end(), 0);

  // Calculate the average using the sum
  double average = static_cast<double>(sum) / numbers.size();

  // Use std::count_if to count numbers greater than the average
  int count_above_avg =
      std::count_if(numbers.begin(), numbers.end(),
                    [average](int num) { return num > average; });

  // Use std::transform to apply a function (e.g., square) to each element
  std::transform(numbers.begin(), numbers.end(), numbers.begin(),
                 [](int num) { return num * num; });

  // Use std::accumulate again to sum up the squared values
  int sum_of_squares = std::accumulate(numbers.begin(), numbers.end(), 0);

  // Return a combination of results to test various stdlib functions
  return sum + count_above_avg + static_cast<int>(std::sqrt(sum_of_squares));
}
