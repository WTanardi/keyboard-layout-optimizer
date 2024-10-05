using Random
using PrettyPrinting

const seed = 281820

const POPULATION_SIZE = 500
const MAX_GENERATIONS = 1000
const MUTATION_RATE = 15
const CROSSOVER_RATE = 75
const ELITE_SIZE = 25

const TD_WEIGHT = 0.35
const FB_WEIGHT = 0.1
const FU_WEIGHT = 0.2
const CU_WEIGHT = 0.05
const TE_WEIGHT = 0.3

const BASE_TD = 15585.5
const BASE_FB = 4479
const BASE_FU = 44950.5
const BASE_CU = 1879
const BASE_TE = 636459

function geneticalgorithm(seed::Union{Int,Nothing}=nothing)
  println("Running Genetic Algorithm")

  start_time = time()

  if !isnothing(seed)
    Random.seed!(seed)
  end

  pop = initialize_population(POPULATION_SIZE)

  best_genome = nothing
  stagnant_count = 0

  for gen in 1:MAX_GENERATIONS
    fit_scores = []
    for genome in pop
      genome_fitness = evaluate_fitness(genome)
      push!(fit_scores, [gen, genome, genome_fitness])
    end

    sorted_pop = sort(fit_scores, by=x -> x[3], rev=true)
    parents = roulette_selection(sorted_pop)

    elite = [individual[2] for individual in sorted_pop[1:ELITE_SIZE]]
    new_pop = copy(elite)

    while length(new_pop) < POPULATION_SIZE
      if rand(1:100) < CROSSOVER_RATE
        child = crossover(parents[1], parents[2])
        if rand(1:100) < MUTATION_RATE
          child = mutate(child)
        end
        push!(new_pop, child)
      else
        push!(new_pop, generate_random_genome())
      end
    end
    pop = new_pop

    current_best_genome = pop[1]

    if current_best_genome !== best_genome
      best_genome = current_best_genome
      stagnant_count = 0
    else
      stagnant_count += 1
    end

    elapsed_time = time() - start_time

    print("\rGeneration $(gen)'s best: ", best_genome, " | Time elapsed: $(round(elapsed_time, digits=2))s")
    flush(stdout)

    if stagnant_count > 100
      println("\nFinished prematurely at: ", gen)
      return best_genome
    end
  end

  println("\nDone!")
  return pop[1]
end

function generate_random_genome()::Matrix{Char}
  keys::Vector{Char} = [
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
    'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
  ]

  return permutedims(reshape(shuffle!(keys), 10, 3))
end

function initialize_population(pop_size::Int64)::Vector{Matrix{Char}}
  return [generate_random_genome() for _ in 1:pop_size]
end

function evaluate_fitness(genome)
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

  finger_assignments = Dict{Char,String}()
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

  text_file = open(io -> read(io, String), "dummy_text.txt")
  finger_usage = Dict(finger => 0 for finger in values(finger_assignments))
  char_freq = zeros(3, 10)
  total_distance = 0.0
  consecutive_usage = 0
  buffer_finger = ""
  buffer_coordinates = (0, 0)

  for char in lowercase(text_file)
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments[char]

      (i, j) = find_character_index(genome, char)

      # Finger usage
      finger_usage[current_finger] += 1
      char_freq[i, j] += 1

      # Travel distance
      start_coordinates = current_finger == buffer_finger ? buffer_coordinates : default_finger_coordinate[current_finger]
      end_coordinates = (i, j)
      total_distance += calculate_travel_distance(start_coordinates[1], start_coordinates[2], end_coordinates[1], end_coordinates[2])

      # Consecutive usage
      if current_finger == buffer_finger
        consecutive_usage += 1
      end

      buffer_finger = current_finger
      buffer_coordinates = end_coordinates
    end
  end

  # Calculate finger usage score
  fu_multiplier_array = [1, 1.5, 4.0, 2.0, 2.0, 4.0, 1.5, 1]

  # fu_score = sum(finger_usage[finger] * fu_multiplier_array[idx] for (idx, finger) in enumerate(keys(finger_usage)))
  fu_score = 0
  sorted_fu = sort(collect(finger_usage))

  fu_multiplier_array = [1, 1.5, 4.0, 2.0, 2.0, 4.0, 1.5, 1]
  for i = 1:8
    fu_score += sorted_fu[i][2] * fu_multiplier_array[i]
  end

  # Calculate typing effort score
  te_multiplier_array = [
    [1.0, 4.0, 4.0, 3.0, 2.0, 1.0, 3.0, 4.0, 4.0, 1.0],
    [5.0, 5.0, 5.0, 5.0, 1.0, 1.0, 5.0, 5.0, 5.0, 5.0],
    [1.0, 2.0, 2.0, 3.0, 1.0, 2.0, 3.0, 2.0, 2.0, 1.0]
  ]

  te_score = sum(sum(char_freq .* te_multiplier_array))

  # Calculate finger balance score
  fb_score = 0
  sorted_keys = sort(collect(keys(finger_usage)))
  for i in 1:div(length(sorted_keys), 2)
    key_left = sorted_keys[i]
    key_right = sorted_keys[end-i+1]
    value_left = finger_usage[key_left]
    value_right = finger_usage[key_right]
    fb_score += -abs(value_left - value_right)
  end

  # println(round(total_distance, digits=2))
  # println(abs(fb_score))
  # println(fu_score)
  # println(abs(consecutive_usage))
  # println(cf_score)

  # Normalize scores
  td_norm = 1 - (round(total_distance, digits=2) / BASE_TD) # Lower better
  fb_norm = ((BASE_FB - abs(fb_score)) / BASE_FB) # Lower better (closer to 0)
  fu_norm = ((fu_score - BASE_FU) / BASE_FU) # Higher better
  cu_norm = ((BASE_CU - abs(consecutive_usage)) / BASE_CU) # Lower better
  te_norm = ((te_score - BASE_TE) / BASE_TE) # Higher better

  final_score = (td_norm * TD_WEIGHT) + (fb_norm * FB_WEIGHT) + (fu_norm * FU_WEIGHT) + (cu_norm * CU_WEIGHT) + (te_norm * TE_WEIGHT)

  return final_score
end

function roulette_selection(fit_scores)
  total_fitness = sum(x -> x[3], fit_scores)
  r1, r2 = rand(2) .* total_fitness
  current_sum = 0.0
  first_parent = last(fit_scores[2])
  second_parent = last(fit_scores[2])

  for i in eachindex(fit_scores)
    current_sum += fit_scores[i][3]
    if current_sum > r1
      first_parent = vec(fit_scores[i][2])
    end
    if current_sum > r2
      second_parent = vec(fit_scores[i][2])
    end
  end

  return first_parent, second_parent
end

function crossover(parent1::Vector{Char}, parent2::Vector{Char})
  n = length(parent1)

  point1, point2 = sort(rand(1:n, 2))

  child = fill(' ', n)

  child[point1:point2] = parent1[point1:point2]

  function fill_child!(child::Vector{Char}, parent::Vector{Char})
    j = point2 + 1
    i = point2 + 1
    while !all(!isspace, child)
      if j > n
        j = 1
      end
      if i > n
        i = 1
      end
      if !(parent[i] in child)
        child[j] = parent[i]
        j = j + 1
        if j > point1 && j <= point2
          j = point2 + 1
        end
      end
      i += 1
    end
  end

  fill_child!(child, parent2)

  return permutedims(reshape(child, 10, 3))
end

function mutate(offspring::Matrix{Char})
  rows, cols = size(offspring)

  i1, j1 = rand(1:rows), rand(1:cols)
  i2, j2 = rand(1:rows), rand(1:cols)

  offspring[i1, j1], offspring[i2, j2] = offspring[i2, j2], offspring[i1, j1]

  return offspring
end

# === HELPER FUNCTIONS ===

function calculate_travel_distance(start_x, start_y, end_x, end_y)
  distance_class = Dict(
    "A" => 1.028, # A-Q
    "B" => 1.108, # A-Z
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

function find_character_index(matrix::Matrix{Char}, char::Char)
  lc_char = lowercase(char)
  rows, cols = size(matrix)

  for i in 1:rows
    for j in 1:cols
      if matrix[i, j] == lc_char
        return (i, j)
      end
    end
  end

  return nothing
end

# === TESTING ===

@time best_layout = geneticalgorithm(seed)

println("Best Layout")
println(best_layout, evaluate_fitness(best_layout))

qwerty = [
  'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
  'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
]
reshaped_qwerty = permutedims(reshape(qwerty, 10, 3))
println("Qwerty score: ", evaluate_fitness(reshaped_qwerty))

halmak = [
  'w', 'l', 'r', 'b', 'z', ';', 'q', 'u', 'd', 'j',
  's', 'h', 'n', 't', ',', '.', 'a', 'e', 'o', 'i',
  'f', 'm', 'v', 'c', '/', 'g', 'p', 'x', 'k', 'y'
]
reshaped_halmak = permutedims(reshape(halmak, 10, 3))
println("Halmak score: ", evaluate_fitness(reshaped_halmak))

test = [
  'f', 'h', 'b', 'g', 'c', ';', 'p', 'l', 'd', 'v',
  'u', 'r', 'a', 'e', 'k', 't', 'i', 'n', 'm', 's',
  'q', 'x', 'z', 'o', 'w', 'j', 'y', ',', '.', '/'
]
reshaped_test = permutedims(reshape(test, 10, 3))
println("Test score: ", evaluate_fitness(reshaped_test))
