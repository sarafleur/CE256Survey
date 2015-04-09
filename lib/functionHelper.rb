def factorial(myInt)
  total = 1
  myInt.downto(1) { |n| total *= n }
  return total
end
