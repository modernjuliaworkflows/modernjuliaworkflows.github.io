# This file was generated, do not modify it. # hide
function sum_of_divisors(n)
    divisors = filter(x -> n % x == 0, 1:n)
    @debug "sum_of_divisors" n divisors
    return sum(divisors)
end