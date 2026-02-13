let numbers = [1, 2, 3, 4, 5];

let squared = map(fn(x) { x * x }, numbers);
print("Squared numbers:", squared);

let even = filter(fn(x) { x % 2 == 0 }, numbers);
print("Even numbers:", even);

let sum = reduce(fn(acc, x) { acc + x }, numbers, 0);
print("Sum of numbers:", sum);
