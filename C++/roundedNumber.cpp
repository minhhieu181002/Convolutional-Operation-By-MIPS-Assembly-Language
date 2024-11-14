#include<iostream>
#include<cmath>
using namespace std;

float roundToOneDecimal(float value) {
    // Multiply by 10, round, then divide by 10
    return std::round(value * 10.0f) / 10.0f;
}
int main() {
    float val = -1999.99;
    cout << roundToOneDecimal(val) << endl; // Should print 104.1
    return 0;
}