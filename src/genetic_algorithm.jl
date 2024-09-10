##### Genetic Algorithm

using Random
using PrettyPrinting
using Base: ReverseOrdering
using Test

# TODO:
# x Init_pop
# x eval_fit
# 	- Character frequency
# 	- Bigram
# 	- Trigram
# x selection
# x crossover
# x mutate
# - replace_pop
# - objective

function geneticalgorithm()
  POPULATION_SIZE = 5
  MAX_GENERATIONS = 2
  MUTATION_RATE = 2
  CROSSOVER_RATE = 75

  pop = initialize_population(POPULATION_SIZE)

  for gen in 1:MAX_GENERATIONS
    # Evaluate fitness
    fit_scores = []
    for genome in pop
      # @info genome

      genome_fitness = evaluate_fitness(genome)
      push!(fit_scores, [gen, genome, genome_fitness])
    end

    # Sort population by fitness
    sorted_pop = sort(fit_scores, by=x -> x[3])

    parents = selection(sorted_pop, 5)

    # Initialize new population
    new_pop = []
    push!(new_pop, sorted_pop[1][2])

    while length(new_pop) < POPULATION_SIZE
      # Crossover
      if rand(1:100) < CROSSOVER_RATE
        child = crossover(parents)
        # Mutation
        if rand(1:100) < MUTATION_RATE
          child = mutate(child)
        end
        push!(new_pop, child)
      else
        push!(new_pop, generate_random_genome())
      end
    end
    pop = new_pop

    pprintln(fit_scores)
  end

  return pop[1]
end

function generate_random_genome()::Matrix{Char}
  keys::Vector{Char} = [
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
    'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
  ]

  shuffle!(keys)

  # @info "Genome: $(genome)"
  return permutedims(reshape(keys, 10, 3))
end

function initialize_population(pop_size::Int64)::Vector{Matrix{Char}}
  # @info "Population: $(pop)"
  return [generate_random_genome() for _ in 1:pop_size]
end

function calculate_travel_distance(start_x, start_y, end_x, end_y)
  distance_class = Dict(
    "A" => 1.972, # A-Q
    "B" => 1.892, # A-Z
    "C" => 1.000, # F-G
    "D" => 1.257, # F-T
    "E" => 1.592, # J-Y Unique
    "F" => 1.783, # F-B Unique
    "G" => 1.129, # J-N Unique
    "H" => 2.124, # Q-Z
    "I" => 2.634, # R-B Unique
    "J" => 2.020, # T-V
  )

  distance = 0

  coordinates = (start_x, start_y, end_x, end_y)

  # J-N Unique
  if coordinates in [(2, 7, 3, 6), (3, 6, 2, 7), (2, 5, 3, 4), (3, 4, 2, 5)]
    distance = distance_class["G"]

    # J-Y Unique
  elseif coordinates in [(2, 7, 1, 6), (1, 6, 2, 7), (2, 5, 1, 4), (1, 4, 2, 5)]
    distance = distance_class["E"]

    # F-B Unique
  elseif coordinates in [(2, 4, 3, 5), (3, 5, 2, 4), (2, 6, 3, 7), (3, 7, 2, 6)]
    distance = distance_class["F"]


    # F-T, H-U Semi-Unique
  elseif coordinates in [(2, 4, 1, 5), (2, 6, 1, 7), (1, 5, 2, 4), (1, 7, 2, 6)]
    distance = distance_class["D"]

    # R-B, Y-M Semi-Unique
  elseif coordinates in [(1, 4, 3, 5), (3, 5, 1, 4), (1, 6, 3, 7), (3, 7, 1, 6)]
    distance = distance_class["I"]

    # T-V, U-N Semi-Unique
  elseif coordinates in [(1, 5, 3, 4), (3, 4, 1, 5), (1, 7, 3, 6), (3, 6, 1, 7)]
    distance = distance_class["J"]

    # No movement
  elseif (start_x == end_x && start_y == end_y)
    distance = 0

  elseif start_y == end_y

    # Second to First row & vice versa
    if start_x + end_x == 3
      distance = distance_class["A"]

      # Second to Third row & vice versa
    elseif start_x + end_x == 5
      distance = distance_class["B"]

      # First to Third row & vice versa
    elseif start_x + end_x == 4
      distance = distance_class["H"]
    end

    # Side to side (Can only happen to index fingers)
  elseif (start_x == end_x) && ((start_y, end_y) in [(4, 5), (5, 4), (6, 7), (7, 6)])
    distance = distance_class["C"]

  else
    println(start_x, start_y, end_x, end_y)
    @error "Invalid movement"
  end

  return distance
end

function find_character_index(matrix::Matrix, char::Char)
  for i = 1:3
    for j = 1:10
      if matrix[i, j] == lowercase(char)
        return (i, j)
      end
      j += 1
    end
    i += 1
  end
end

function evaluate_fitness(genome::Matrix{Char})
  score = 0
  dummy_text = open(io -> read(io, String), "dummy_text.txt")

  score += evaluate_travel_distance(genome, dummy_text)

  # character_frequency = boo
  # bigram_frequency = boo
  # trigram_frequency = boo

  return score
end

function evaluate_travel_distance(genome::Matrix{Char}, text_file)
  default_finger_coordinate = Dict(
    "01_L-Pinky" => (2, 1),
    "02_L-Ring" => (2, 2),
    "03_L-Middle" => (2, 3),
    "04_L-Index" => (2, 4),
    "05_R-Index" => (2, 7),
    "06_R-Middle" => (2, 8),
    "07_R-Ring" => (2, 9),
    "08_R-Pinky" => (2, 10)
  )

  finger_assignments = Dict()

  for i in 1:3
    finger_assignments[genome[i, 1]] = "01_L-Pinky"
    finger_assignments[genome[i, 2]] = "02_L-Ring"
    finger_assignments[genome[i, 3]] = "03_L-Middle"
    for j in 4:5
      finger_assignments[genome[i, j]] = "04_L-Index"
    end
    for j in 6:7
      finger_assignments[genome[i, j]] = "05_R-Index"
    end
    finger_assignments[genome[i, 8]] = "06_R-Middle"
    finger_assignments[genome[i, 9]] = "07_R-Ring"
    finger_assignments[genome[i, 10]] = "08_R-Pinky"
  end

  total_distance = 0

  buffer_coordinates = (0, 0)
  buffer_finger = ""

  for char in lowercase(text_file)
    # @info "Start"
    # @info char
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments[char]
      # @info "current finger: " current_finger
      # @info "buffer finger: " buffer_finger

      if current_finger == buffer_finger
        start_coordinates = buffer_coordinates
        # @info "isSameFinger? true" start_coordinates

      else
        start_coordinates = default_finger_coordinate[current_finger]
        # @info "isSameFinger? false" start_coordinates

      end

      end_coordinates = find_character_index(genome, char)
      # @info "end coordinates: " end_coordinates

      # distance = calculate_travel_distance(start_coordinates[1], start_coordinates[2], end_coordinates[1], end_coordinates[2])
      # @info "distance: " distance
      # total_distance += distance
      total_distance += calculate_travel_distance(start_coordinates[1], start_coordinates[2], end_coordinates[1], end_coordinates[2])

      buffer_coordinates = end_coordinates
      # @info "buffer coordinates: " buffer_coordinates
      buffer_finger = finger_assignments[char]
      # @info "buffer finger: " buffer_finger
    end
    # @info "End"
  end

  return round(total_distance, digits=2)

end

function evaluate_character_frequency(genome)
  character_frequency = Dict(
    "a" => 0.8691,
    "n" => 0.5563,
    "e" => 0.5431,
    "i" => 0.3590,
    "r" => 0.3308,
    "m" => 0.2966,
    "k" => 0.2791,
    "t" => 0.2611,
    "u" => 0.2589,
    "s" => 0.2472,
    "g" => 0.2176,
    "p" => 0.2005,
    "l" => 0.1814,
    "b" => 0.1672,
    "o" => 0.1275,
    "d" => 0.1010,
    "h" => 0.0956,
    "j" => 0.0477,
    "y" => 0.0428,
    "c" => 0.0420,
    "w" => 0.0216,
    "f" => 0.0190,
    "v" => 0.0094,
    "z" => 0.0022,
    "q" => 0.0001,
    "x" => 0.0001,
    ";" => 0.0001,
    "." => 0.0001,
    "," => 0.0001,
    "/" => 0.0001,
  )

  position_score = [
    # [06, 02, 01, 06, 11, 14, 09, 01, 07, 09],
    # [00, 00, 00, 00, 07, 07, 00, 00, 00, 00],
    # [07, 08, 10, 06, 10, 04, 02, 05, 05, 03],
    [1.0, 3.5, 3.5, 2.5, 1.5, 1.0, 2.5, 3.5, 3.5, 1.0],
    [4.0, 4.0, 4.0, 4.0, 2.0, 2.0, 4.0, 4.0, 4.0, 4.0],
    [1.5, 2.0, 2.0, 3.0, 1.0, 2.5, 3.0, 2.5, 2.5, 2.0]
  ]

  score = 0

  for row = 1:3
    for col = 1:10
      char = genome[row, col]
      score += character_frequency[string(char)] * position_score[row][col]
    end
  end

  return score
end

function evaluate_bigram_frequency(genome)
  common_bigrams = Dict(
    "an" => 0.2774,
    "ng" => 0.1476,
    "er" => 0.1465,
    "en" => 0.1402,
    "me" => 0.1203,
    "ka" => 0.1011,
    "pe" => 0.0888,
    "ra" => 0.0787,
    "ta" => 0.0687,
    "ar" => 0.0683,
    "la" => 0.0654,
    "em" => 0.0651,
    "ga" => 0.0619,
    "be" => 0.0618,
    "at" => 0.0593,
    "si" => 0.0591,
    "ma" => 0.0554,
    "as" => 0.0546,
    "in" => 0.0538,
    "te" => 0.0532,
  )

  score = 0

  function get_bigram_coordinates(arguments)

  end

  return score
end

function evaluate_trigram_frequency(genome)
  common_trigrams = Dict(
    "men" => 0.704,
    "kan" => 0.563,
    "ang" => 0.548,
    "eng" => 0.481,
    "ber" => 0.463,
    "ter" => 0.335,
    "pen" => 0.320,
    "nga" => 0.318,
    "per" => 0.270,
    "gan" => 0.250,
    "era" => 0.249,
    "mem" => 0.248,
    "ran" => 0.243,
    "ara" => 0.227,
    "emb" => 0.218,
    "tan" => 0.210,
    "asi" => 0.203,
    "ela" => 0.194,
    "ing" => 0.193,
    "ung" => 0.183,
  )

  score = 0

  for i = 1:2
    for j = 1:10
      for k = 1:10
        for l = 1:10
          trigram = genome[i][j] + genome[i+1][k] + genome[i+2][l]
          if trigram in common_trigrams
            # Assign a higher score for more common bigrams
            score += common_trigrams[trigram] * 100
          end
        end
      end
    end
  end

  return score
end

function selection(fit_scores, k)
  parents = []
  current_elite = []

  for i in eachindex(fit_scores)
    if i == 1
      current_elite = fit_scores[i][2]
      buffer_elite = fit_scores[i][2]
      buffer_score = fit_scores[i][3]
    else
      buffer_elite = fit_scores[i][2]
      buffer_score = fit_scores[i][3]
    end
    if buffer_score < fit_scores[i][3]
      current_elite = buffer_elite
    end
  end

  push!(parents, current_elite)

  warrior = rand(fit_scores, k)

  score_array = []

  for i in eachindex(warrior)
    if fit_scores[i][2] !== current_elite
      push!(score_array, fit_scores[i][3])
    end
  end

  champion = nothing

  champion_score = minimum(score_array)

  for i in eachindex(fit_scores)
    if champion_score == fit_scores[i][3]
      champion = fit_scores[i][2]
    end
  end
  push!(parents, champion)
end

function crossover(selected_parents)
  offspring = fill(' ', 3, 10)
  visited = fill(false, 3, 10)

  mom = vec(selected_parents[1])
  dad = vec(selected_parents[2])
  flat_offspring = vec(offspring)

  for i in eachindex(mom)
    if visited[i]
      continue
    end

    cycle_start = i
    cycle_value = mom[i]

    while true
      flat_offspring[cycle_start] = mom[cycle_start]
      visited[cycle_start] = true

      cycle_start = findfirst(==(cycle_value), dad)
      cycle_value = mom[cycle_start]

      if visited[cycle_start]
        break
      end
    end
  end

  for i in eachindex(dad)
    if !visited[i]
      flat_offspring[i] = dad[i]
    end
  end

  offspring = reshape(flat_offspring, 3, 10)
  # @info "Offspring $(offspring)"
  return offspring
end

function mutate(offspring)
  rows, cols = size(offspring)

  i1, j1 = rand(1:rows), rand(1:cols)
  i2, j2 = rand(1:rows), rand(1:cols)

  temp = offspring[i1, j1]
  offspring[i1, j1] = offspring[i2, j2]
  offspring[i2, j2] = temp

  # @info "Mutated Offspring: $(offspring)"
  return offspring
end


@time best_layout = geneticalgorithm()
println("Best Layout")
println(best_layout, evaluate_fitness(best_layout))

# qwerty = [
#   'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
#   'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
#   'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
# ]
#
# reshaped_qwerty = permutedims(reshape(qwerty, 10, 3))
#
# println(reshaped_qwerty)
# println(reshaped_qwerty[2, 4])
# println(reshaped_qwerty[1, 5])
# println(calculate_travel_distance(2, 7, 3, 6))

# @time println(eval_fit(permutedims(reshape(qwerty, 10, 3))))

# distance_matrix = [
# "1.972", "1.972", "1.972", "1.972", "1.257", "1.592", "1.972", "1.972", "1.972", "1.972";
# "0", "0", "0", "0", "1", "1", "0", "0", "0", "0";
# "1.892", "1.892", "1.892", "1.892", "1.783", "1.129", "1.892", "1.892", "1.892", "1.892"
# ]

# distance_matrix = [
# "1.972", "2.172", "2.172", "1.972", "1.743", "1.408", "1.972", "2.172", "2.172", "1.972";
# "3.000", "3.000", "3.000", "3.000", "2.000", "2.000", "3.000", "3.000", "3.000", "3.000";
# "1.992", "1.842", "1.842", "1.992", "1.217", "1.871", "1.992", "1.842", "1.842", "1.992"
# ]


