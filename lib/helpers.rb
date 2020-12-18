# frozen_string_literal: true

def count_values(ary, default = 0)
  count = ary.group_by(&:itself).transform_values(&:count)
  count.default = default if default
  count
end

def intersect_with_multiplicity(arr1, arr2)
  multiplicities2 = count_values(arr2)
  count_values(arr1)
    .map { |k, v| [k] * [multiplicities2[k] || 0, v].min }
    .reduce([], &:+)
end

def subtract_with_multiplicity(arr1, arr2)
  multiplicities2 = count_values(arr2)
  count_values(arr1)
    .map { |k, v| [k] * (v - (multiplicities2[k] || 0)) }
    .reduce([], &:+)
end

def equality_length(str1, str2)
  str1.each_char.zip(str2.each_char).reduce(0) do |equality_length, chars|
    break equality_length if chars[0] != chars[1]

    equality_length + 1
  end
end

# find for each string in arr_of_str the minimum length of a substring at the start
# of str, such that this substring is unique over all such substrings for all
# the strings in arr_of_str and store it in a hash (key is the string).  if this
# minimum length does not exist for a string, the length of the complete
# string + 1 is instead stored.
def minimum_unique_start_lengths(arr_of_str)
  arr_of_str = arr_of_str.sort

  unique_lengths = {}
  (0..arr_of_str.length - 2).each do |i|
    cur_str = arr_of_str[i]
    next_str = arr_of_str[i + 1]
    unique_length = equality_length(cur_str, next_str) + 1
    unique_lengths[cur_str] = [unique_lengths[cur_str] || 0, unique_length].max
    unique_lengths[next_str] = unique_length
  end

  unique_lengths
end
