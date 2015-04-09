
class Variable
  def self.permutation_count(tab)
    return factorial(tab.length)
  end

  def factorial(n)
    return (1..n).inject(:*) || 1
  end
end
