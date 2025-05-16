# Filtering
## Preprocessing

source_file = open("./kbbi.csv")

corpus_file = "corpus.txt"
filtered_corpus_file = "filtered_corpus_2.csv"

bigram_file = "bigrams.csv"
trigram_file = "trigrams.csv"

letter_freq = "letter_freq.csv"

function filter_text_file(input_file::String, output_file::String)
  allowed_chars = Set(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    ';', ':', ',', '<', '.', '>', '/', '?', '\'', '"'])

  open(input_file, "r") do infile
    open(output_file, "w") do outfile
      for line in eachline(infile)
        parts = split(line, ' ')
        if length(parts) == 2
          word, word_freq = parts
          if all(c -> c in allowed_chars, word)
            write(outfile, word * " " * word_freq * "\n")
          end
        end
      end
    end
  end

  println("Filtered text saved to: ", output_file)
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
  filter_text_file(corpus_file, filtered_corpus_file)
end

function compileanalysis()
  analyze_bigrams(filtered_corpus_file, bigram_file)
  analyze_trigrams(filtered_corpus_file, trigram_file)
  analyzeletterfreq(filtered_corpus_file, letter_freq)
end

preprocessing()
compileanalysis()
