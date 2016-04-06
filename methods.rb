## Zach Litzinger Vigenere cipher
#to make output look better I suggest installing the gem 'colorize'
#you can do this by typing "gem install colorize" into your terminal
require 'colorize'

$frequencies = Hash[
  "a" => 8.55, "b" => 1.60, "c" => 3.16, "d" => 3.87, "e" => 12.1, "f" => 2.18,
  "g" => 2.09, "h" => 4.96, "i" => 7.33, "j" => 0.22, "k" => 0.81, "l" => 4.21,
  "m" => 2.53, "n" => 7.17, "o" => 7.47, "p" => 2.07, "q" => 0.10, "r" => 6.33,
  "s" => 6.73, "t" => 8.94, "u" => 2.68, "v" => 1.06, "w" => 1.83, "x" => 0.19,
  "y" => 1.72, "z" => 0.11]

#Code for "encode"

def alphabet_number array
  alphabet = ('a'..'z').to_a
  array.map {|x| x = alphabet.index(x).to_i + 1}
end

def number_alphabet array
  alphabet = ('a'..'z').to_a
  array.map {|x| x = alphabet[(x - 1)]}
end

def make_key_repeat array, length
  newarray = array
  (length / array.length).times do
    newarray += array
  end
  newarray.take(length)
end

def v_encode message, key
  message_array = alphabet_number(message.split(""))
  key_array = make_key_repeat(alphabet_number(key.split("")), message_array.length)
  number_alphabet(message_array.map.with_index{ |x,i| (message_array[i].to_i + key_array[i].to_i - 1) % 26}).take(message_array.length).join("")
end

#puts 'this was just encoded ' + v_encode('iamdoingthisbymyselfanditshard', 'litzinger')

#Code for "decode"

def v_decode message, key
  message_array = alphabet_number(message.split(""))
  key_array = alphabet_number(make_key_repeat(key.split(""), message_array.length)).take(message_array.length)
  number_alphabet(message_array.map.with_index{ |m,i| (m.to_i - key_array[i].to_i + 1) % 26}).take(message_array.length).join("")
end

def v_decode_file file, key
  message = ""
  File.open(file).each do |line|
    message += v_decode line.delete(" "), key ##makes sure that there are no spaces
  end
  message
end

#puts 'this was just decoded ' + v_decode_file('code.txt', 'litzinger')

#Code for Finding Keyword
## We know it is between 3 and 8 letters long

def find_key_lengths string
  array = []
  string_array = string.split("")
  guess = (3..8).to_a #if generalizing, 8 can be string_array.length
  guess.each do |x|
    matches = 0
    string_array.each.with_index do |y, i|
      if string_array[i] == string_array[i + x]
        matches += 1
      end
    end
    array.push(matches)
  end
  array.map.with_index{|x, i| i + 3 if x >= (array.max)}.compact
end

#puts find_key_lengths "coliwicojqkwbjplvwffjvapvjuikicomitxrxnemtbefickmpeitf"

def find_key_lengths_by_file file
  key_lengths = []
  File.open(file).each do |line|
    key_lengths += find_key_lengths line.delete(" ")
  end
  key_lengths.uniq!
end

#puts find_key_lengths_by_file 'secretcode.txt'

#need to use a Caesar key to try to find individual letters for the Veginere Cipher
##This will be using a frequency analysis to show the likelyhood of each letter being the correct one
def frequency string
  $frequencies[string]
end

def c_encode message, key
  alphabet = ('a'..'z').to_a
  new_index = (alphabet.index(key) + 1) % 26
  v_encode(message, alphabet[new_index.to_i])
end

def c_decode message, key
  alphabet = ('a'..'z').to_a
  new_index = (alphabet.index(key) + 1) % 26
  v_decode(message, alphabet[new_index.to_i])
end

def frequency_value array, letter
  (array.count(letter).to_f/array.length.to_f) * 100
end

#gives a value of comparison to natural text (lower is best)
def alphabet_frequency string, letter
  decode_attempt = c_decode string, letter
  frequency_total_array = []
  $frequencies.each do |key, array|
  frequency_total_array.push((frequency_value(decode_attempt.split(""), key) - $frequencies[key]).abs)
end
frequency_total_array.inject(0, :+)
end

#puts alphabet_frequency "thereisnowayyoucouldevergetthiswithoutknowingtherightanswercanyouidontknowithinkwewillfindout", "a"

def best_letter string
  alphabet = ('a'..'z').to_a
  frequency_hash = Hash['a' => 1]
  alphabet.each do |x|
    frequency_hash[x] = alphabet_frequency(string, x)
  end
  #puts frequency_hash
  number_alphabet [(alphabet_number(frequency_hash.min_by{|k,v| v}.first.split("")).first + 1) % 26]
end

def every_nth_string string, n, start
  string_array = string.split("")
  ((start..string_array.size).step(n).map{ |i| string_array[i] }).join("")
end

#puts every_nth_string "coliwicojqkwbjplvwffjvapvjuikicomitxrxnemtbefickmpeitf", 6, 0

def every_nth_string_from_file file, n, start
  message = ""
  File.open(file).each do |line|
    message += every_nth_string line.delete(" ").delete("\n"), n, start ##makes sure that there are no spaces
  end
  message.to_s
end

def gets_key_word_from_file file, array_of_lengths
  array_of_words = []
  array_of_lengths.each do |length|
    word_length = (0..(length - 1)).to_a
    word_length.each do |number|
      word_length[number] = best_letter (every_nth_string_from_file 'secretcode.txt', length, number)
    end
    array_of_words.push(word_length.join(""))
  end
  array_of_words
end

#puts (every_nth_string_from_file 'secretcode.txt', 6, 1)

#puts gets_key_word_from_file 'secretcode.txt', (find_key_lengths_by_file 'secretcode.txt')

def crack_vigenere file
  answer = ""
  words = gets_key_word_from_file file, (find_key_lengths_by_file file)
  words.each.with_index do |word, i|
    answer += "Attempt: #{i + 1} : #{word} \n".red + "#{v_decode_file 'secretcode.txt', word} \n"
  end
  answer
end

puts crack_vigenere 'secretcode.txt'

#puts (best_letter "ccbfvcrbmooriafbvcsogzshucufubqfwjfsdhachrbowwposrsoompigissmscovucfcfcccvztfrbshssssss")

#puts c_decode "jyrgxmsr", "d"

#puts v_encode "function", "key"
#puts v_decode "pylmxgyr", "key"

#puts c_encode "function", "o"
#puts c_decode "gvodujpo", "a"

##every sixth letter of the code
#ccbfvcrbmooriafbvcsogzshucudhachrbow
#oojfjoxep
#ljpjumnfehwdexxxumaymcjybnw
