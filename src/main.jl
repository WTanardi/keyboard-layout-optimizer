# Filtering for Bahasa Indonesia formal words
## Preprocessing
source_file = open("./kbbi.csv")

output_dir = "word_classes/"

if !isdir(output_dir)
  mkdir(output_dir)
end

corpus_file = "corpus.txt"

dict_file = "dict.csv"

filtered_corpus_file = "filtered_corpus.csv"

bigram_file = "bigrams.csv"
trigram_file = "trigrams.csv"

letter_freq = "letter_freq.csv"

files_array = [
  "nomina.csv",
  "verba.csv",
  "adjektiva.csv",
  "adverbia.csv",
  "pronomina.csv",
  "numeralia.csv",
  "preposisi.csv",
]

word_types = [
  "[n]",
  "[v]",
  "[a]",
  "[adv]",
  "[pron]",
  "[num]",
  "[p]",
]

function filterdict(input_file)
  file_by_line = readlines(input_file)

  for (output_file, word_type) in zip(files_array, word_types)
    type_array = []

    for line in file_by_line
      if contains(line, word_type)
        split_line = split(line)
        if length(split_line[1]) > 1
          word = split_line[1]
          push!(type_array, word)
        end
      end
    end

    output_path = joinpath(output_dir, output_file)

    open(output_path, "w") do file
      for word in type_array
        write(file, word * "\n")
      end
    end

    empty!(type_array)
  end

  println("Dictionary successfully filtered")
end

function compiledict(output_file)
  combined_set = Set{String}()

  for file_name in readdir(output_dir)
    file_path = joinpath(output_dir, file_name)
    for line in eachline(file_path)
      push!(combined_set, strip(line))
    end
  end

  open(output_file, "w") do file
    for word in sort(collect(combined_set))
      write(file, lowercase(word) * "\n")
    end
  end

  println("Dictionary successfully compiled")
end

function filtercorpus(input_file, dict_file, output_file)
  combined_words_set = Set{String}()

  for line in eachline(dict_file)
    push!(combined_words_set, strip(line))
  end

  filtered_lines = []

  for line in eachline(input_file)
    word, wordfreq = split(line, r"\s+", limit=2)

    if word in combined_words_set
      if wordfreq == "99"
        break
      end
      push!(filtered_lines, line)
    end
  end

  open(output_file, "w") do file
    for line in filtered_lines
      write(file, line * "\n")
    end
  end

  println("Corpus file successfully filtered")
end

function analyzeletterfreq(input_file, output_file, num_lines::Int=-1)
  letter_freq = Dict{Char,Int}()

  line_count = 0

  for line in eachline(input_file)
    line_count += 1
    if num_lines != -1 && line_count > num_lines
      break
    end
    for char in lowercase(line)
      if isletter(char)
        letter_freq[char] = get(letter_freq, char, 0) + 1
      end
    end
  end

  sorted_letters = sort(collect(letter_freq), by=x -> x[2], rev=true)

  open(output_file, "w") do file
    for (letter, count) in sorted_letters
      write(file, "$letter: $count\n")
    end
  end

  println("Letter frequency successfully analyzed")
end

function analyze_bigrams(input_file, output_file)
  # Initialize an empty dictionary to store bigram frequencies
  bigram_freq = Dict{String,Int}()

  # Read the file line by line
  for line in eachline(input_file)
    # Extract the first column (the words) from each line
    word = split(line)[1]

    # Convert to lowercase to normalize the text
    word = lowercase(word)

    # Loop through the word and count bigrams
    for i in 1:(length(word)-1)
      bigram = word[i:i+1]
      bigram_freq[bigram] = get(bigram_freq, bigram, 0) + 1
    end
  end

  # Sort the bigrams by frequency (descending order)
  sorted_bigrams = sort(collect(bigram_freq), by=x -> x[2], rev=true)

  # Print the bigram frequencies
  open(output_file, "w") do file
    for (bigram, count) in sorted_bigrams
      write(file, "$bigram: $count\n")
    end
  end
end

function analyze_trigrams(input_file, output_file)
  # Initialize an empty dictionary to store bigram frequencies
  trigram_frequency = Dict{String,Int}()

  # Read the file line by line
  for line in eachline(input_file)
    # Extract the first column (the words) from each line
    word = split(line)[1]

    # Convert to lowercase to normalize the text
    word = lowercase(word)

    # Loop through the word and count bigrams
    for i in 1:(length(word)-2)
      trigram = word[i:i+2]
      trigram_frequency[trigram] = get(trigram_frequency, trigram, 0) + 1
    end
  end

  # Sort the bigrams by frequency (descending order)
  sorted_trigrams = sort(collect(trigram_frequency), by=x -> x[2], rev=true)

  # Print the bigram frequencies
  open(output_file, "w") do file
    for (trigram, count) in sorted_trigrams
      write(file, "$trigram: $count\n")
    end
  end
end


function preprocessing()
  filterdict(source_file)
  compiledict(dict_file)
  filtercorpus(corpus_file, dict_file, filtered_corpus_file)
end

function compileanalysis()
  analyze_bigrams(filtered_corpus_file, bigram_file)
  analyze_trigrams(filtered_corpus_file, trigram_file)
  analyzeletterfreq(filtered_corpus_file, letter_freq)
end
