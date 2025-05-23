using Random
using PrettyPrinting
using Statistics
using Plots

const seed = 281820

const POPULATION_SIZE = 200
const ELITE_SIZE = 20
const MAX_GENERATIONS = 1000
const MAX_STAGNANT = 500
const CROSSOVER_RATE = 90 #/100
const MUTATION_RATE = 1 #/1000

const TD_WEIGHT = 0.4
const FU_WEIGHT = 0.18
const HA_WEIGHT = 0.16
const FA_WEIGHT = 0.16
const BS_WEIGHT = 0.05
const HD_WEIGHT = 0.05

# const TD_WEIGHT = 0
# const FU_WEIGHT = 0.13
# const HA_WEIGHT = 0.28
# const FA_WEIGHT = 0.22
# const BS_WEIGHT = 0.20
# const HD_WEIGHT = 0.17

# const TD_WEIGHT = 1
# const FU_WEIGHT = 0
# const HA_WEIGHT = 0
# const FA_WEIGHT = 0
# const BS_WEIGHT = 0
# const HD_WEIGHT = 0

const BASE_TD = 15585.5
const BASE_FU = 41760.5
const BASE_HA = 8857
const BASE_FA = 1879
const BASE_BS = 607
const BASE_HD = 4013

const text_file = open(io -> read(io, String), "dummy_text.txt")

function geneticalgorithm(seed::Union{Int,Nothing}=nothing)
  println("Running Genetic Algorithm\n")
  println("CPU Threads: ", Sys.CPU_THREADS)
  println("RAM: ", round(Sys.total_memory() / 1024^3, digits=2), " GB\n")

  println("Seed: $(seed)")
  println("Population size: $(POPULATION_SIZE)")
  println("Elite size: $(ELITE_SIZE)")
  println("Max Gen: $(MAX_GENERATIONS)")
  println("Max Stagnant: $(MAX_STAGNANT)")
  println("Crossover rate: $(CROSSOVER_RATE)%")
  println("Mutation rate: $(MUTATION_RATE/10)%\n")

  println("TD Weight: $(TD_WEIGHT)")
  println("FU Weight: $(FU_WEIGHT)")
  println("HA Weight: $(HA_WEIGHT)")
  println("FA Weight: $(FA_WEIGHT)")
  println("BS Weight: $(BS_WEIGHT)")
  println("HD Weight: $(HD_WEIGHT)\n")

  start_time = time()

  if !isnothing(seed)
    Random.seed!(seed)
  end

  pop = initialize_population(POPULATION_SIZE)

  best_genome = nothing
  stagnant_count = 0

  for gen in 1:MAX_GENERATIONS
    fit_scores = []

    fit_scores = evaluate_population_fitness(pop)

    sorted_pop = sort(fit_scores, by=x -> x[3], rev=true)

    elite = [individual[2] for individual in sorted_pop[1:ELITE_SIZE]]

    new_pop = copy(elite)

    while length(new_pop) < POPULATION_SIZE
      parents = selection(sorted_pop, 2)

      if rand(0:100) < CROSSOVER_RATE
        child = crossover(parents[1], parents[2])
        if rand(0:1000) < MUTATION_RATE
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

    print_progress(gen, best_genome, elapsed_time, stagnant_count)

    if stagnant_count > MAX_STAGNANT
      println("\nFinished prematurely at: ", gen)
      return best_genome
    end
  end

  println("\n\nDone!\n")

  return pop[1]
end

function generate_random_genome()::Matrix{Char}
  keys = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
    'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/']
  shuffle!(keys)
  return permutedims(reshape(keys, 10, 3))
end

function initialize_population(pop_size::Int64)
  pop = Vector{Matrix{Char}}(undef, pop_size)
  Threads.@threads for i in 1:pop_size
    pop[i] = generate_random_genome()
  end
  return pop
end

function evaluate_fitness(genome, show=false)
  finger_assignments_dict = assign_finger_assignments(genome)

  char_freq = zeros(3, 10)
  buffer_coordinates = (0, 0)

  # Finger utilisation variables
  finger_utilisation = Dict(finger => 0 for finger in values(finger_assignments_dict))

  # Travel distance variables
  total_distance = 0.0

  # Finger alternation variables
  finger_alternation = 0
  buffer_finger = ""

  # Hand alternation variables
  hand_alternation = 0
  buffer_hand = ""

  # Big step variables
  big_step = 0

  # Hit Direction variables
  hit_direction = 0

  for char in lowercase(text_file)
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments_dict[char]

      (i, j) = find_character_index(genome, char)

      # Travel distance
      x1, y1 = current_finger == buffer_finger ? buffer_coordinates : default_finger_coordinate[current_finger]
      x2, y2 = (i, j)

      total_distance += calculate_travel_distance(x1, y1, x2, y2)

      # Finger utilisation
      finger_utilisation[current_finger] += 1
      char_freq[i, j] += 1

      # Hand alternation
      if occursin("R-", current_finger)
        current_hand = "Right Hand"
      else
        current_hand = "Left Hand"
      end

      if current_hand == buffer_hand
        hand_alternation += 1
        # Hit direction
        if calculate_direction(buffer_coordinates[2], y2) == "Outwards"
          hit_direction += 1
        end
      end

      # Finger alternation
      if current_finger == buffer_finger
        finger_alternation += 1
      end

      # Big step
      if abs(x1 - x2) > 1
        big_step += 1
      end

      buffer_hand = current_hand
      buffer_finger = current_finger
      buffer_coordinates = x2, y2

    end
  end

  # Calculate finger utilisation score
  fu_multiplier_array = [0.5, 1.0, 4.0, 2.0, 2.0, 4.0, 1.0, 0.5]

  fu_score = 0
  sorted_fu = sort(collect(finger_utilisation))

  for i = 1:8
    fu_score += sorted_fu[i][2] * fu_multiplier_array[i]
  end

  if (show == true)
    println(sorted_fu)

    println("Travel Distance (Lower better): ", round(total_distance, digits=2))
    println("Finger Utilisation (Higher better): ", fu_score)
    println("Hand Alternation (Lower better): ", hand_alternation)
    println("Finger Alternation (Lower better): ", finger_alternation)
    println("Avoidance of Big Steps (Lower better): ", big_step)
    println("Hit Direction (Lower better): ", hit_direction)
  end

  # Normalize scores
  td_norm = 1 - (round(total_distance, digits=2) / BASE_TD) # Lower better
  fu_norm = ((fu_score - BASE_FU) / BASE_FU) # Higher better
  ha_norm = ((BASE_HA - hand_alternation) / BASE_HA) # Lower better
  fa_norm = ((BASE_FA - finger_alternation) / BASE_FA) # Lower better
  bs_norm = ((BASE_BS - big_step) / BASE_BS) # Lower better
  hd_norm = ((BASE_HD - hit_direction) / BASE_HD) # Lower better

  final_score = (td_norm * TD_WEIGHT) + (fu_norm * FU_WEIGHT) + (ha_norm * HA_WEIGHT) + (fa_norm * FA_WEIGHT) + (bs_norm * BS_WEIGHT) + (hd_norm * HD_WEIGHT)

  return final_score
end

# Stochastic Universal Sampling
# Returns `n` selected chromosomes as parents
function selection(fit_scores, n)
  # Extract fitness values from fit_scores
  fitness_values = [score[3] for score in fit_scores]

  # Shift fitness values to make them non-negative
  min_fitness = minimum(fitness_values)
  if min_fitness < 0
    fitness_values .-= min_fitness  # Shift all values by the absolute value of the minimum
  end

  # Calculate the total fitness of the population
  total_fitness = sum(fitness_values)

  # If total_fitness is zero (all fitness values were zero after shifting), set equal probabilities
  if total_fitness == 0
    fitness_values .= 1.0  # Assign equal fitness to all individuals
    total_fitness = sum(fitness_values)
  end

  # Calculate the pointer distance and generate pointers
  pointer_distance = total_fitness / n
  start = rand() * pointer_distance
  pointers = [start + i * pointer_distance for i in 0:(n-1)]

  # Initialize selected parents
  parents = []
  current_sum = 0.0
  pointer_index = 1

  # Iterate through chromosomes to assign parents to pointers
  for (i, chrom) in enumerate(fit_scores)
    # Accumulate fitness (using shifted fitness values)
    current_sum += fitness_values[i]

    # Iterate through pointers that need a parent
    for p in pointer_index:n
      if current_sum >= pointers[p]
        # Add chromosome to parents
        push!(parents, chrom[2])
        # Move to the next pointer
        pointer_index += 1
      else
        # Stop checking further pointers for this chromosome
        break
      end
    end
  end

  return parents
end

function crossover(parent_1, parent_2)
  n = length(parent_1)

  point1, point2 = sort(rand(1:n, 2))

  child = fill(' ', n)

  child[point1:point2] = parent_1[point1:point2]

  function fill_child!(child, parent)
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

  fill_child!(child, parent_2)

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

const distance_class = Dict(
  "A" => 1.000, # F-G
  "B" => 1.028, # A-Q
  "C" => 1.108, # A-Z
  "D" => 1.129, # J-N Unique
  "E" => 1.257, # F-T
  "F" => 1.592, # J-Y Unique
  "G" => 1.783, # F-B Unique
  "H" => 2.124, # Q-Z
  "I" => 2.634, # R-B Unique
  "J" => 2.020, # T-V
)

function calculate_travel_distance(start_x, start_y, end_x, end_y)
  distance = 0
  coordinates = (start_x, start_y, end_x, end_y)

  if coordinates in [(2, 7, 3, 6), (3, 6, 2, 7), (2, 5, 3, 4), (3, 4, 2, 5)]
    distance = distance_class["D"]
  elseif coordinates in [(2, 7, 1, 6), (1, 6, 2, 7), (2, 5, 1, 4), (1, 4, 2, 5)]
    distance = distance_class["F"]
  elseif coordinates in [(2, 4, 3, 5), (3, 5, 2, 4), (2, 6, 3, 7), (3, 7, 2, 6)]
    distance = distance_class["G"]
  elseif coordinates in [(2, 4, 1, 5), (2, 6, 1, 7), (1, 5, 2, 4), (1, 7, 2, 6)]
    distance = distance_class["E"]
  elseif coordinates in [(1, 4, 3, 5), (3, 5, 1, 4), (1, 6, 3, 7), (3, 7, 1, 6)]
    distance = distance_class["I"]
  elseif coordinates in [(1, 5, 3, 4), (3, 4, 1, 5), (1, 7, 3, 6), (3, 6, 1, 7)]
    distance = distance_class["J"]
  elseif (start_x == end_x && start_y == end_y)
    distance = 0
  elseif start_y == end_y
    if start_x + end_x == 3
      distance = distance_class["B"]
    elseif start_x + end_x == 5
      distance = distance_class["C"]
    elseif start_x + end_x == 4
      distance = distance_class["H"]
    end
  elseif (start_x == end_x) && ((start_y, end_y) in [(4, 5), (5, 4), (6, 7), (7, 6)])
    distance = distance_class["A"]
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

function calculate_direction(start, finish)
  # Define the middle of the range (center)
  center = 5.5  # For a range from 1 to 10

  # If start < finish, you're moving upwards (higher value)
  if start < finish
    if finish > center
      return "Outwards"  # Moving away from the center
    else
      return "Inwards"   # Moving towards the center
    end
  elseif start > finish
    if finish < center
      return "Outwards"  # Moving away from the center (in reverse)
    else
      return "Inwards"   # Moving towards the center
    end
  else
    return "No movement"  # No movement
  end
end

function evaluate_population_fitness(pop)
  fit_scores = Vector{Any}(undef, length(pop))
  Threads.@threads for i in eachindex(pop)
    fit_scores[i] = [i, pop[i], evaluate_fitness(pop[i])]
  end
  return fit_scores
end

const default_finger_coordinate = Dict(
  "01_L-Pinky" => (2, 1),
  "02_L-Ring" => (2, 2),
  "03_L-Middle" => (2, 3),
  "04_L-Index" => (2, 4),
  "05_R-Index" => (2, 7),
  "06_R-Middle" => (2, 8),
  "07_R-Ring" => (2, 9),
  "08_R-Pinky" => (2, 10)
)

function assign_finger_assignments(genome)
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
  return finger_assignments
end

function print_progress(gen, best_genome, elapsed_time, stagnant_count)
  # Move cursor up 1 line (if not first iteration)
  if gen > 1
    print("\e[1A\e[1A\e[1A\e[1A\e[1A\e[1A\e[1A")  # ANSI escape code: move up
  end

  # Overwrite both lines
  print("\rGeneration $(gen)'s best: \n\n")  # \n for newline

  print("\r", best_genome[1, :], " \n")
  print("\r", best_genome[2, :], " \n")
  print("\r", best_genome[3, :], " \n\n")

  print("\rTime elapsed: $(round(elapsed_time, digits=2))s  \n")  # Extra spaces to clear leftovers
  print("\rStagnant count: $(stagnant_count) ")  # Extra spaces to clear leftovers
  flush(stdout)
end

# === TESTING ===

@time best_layout = geneticalgorithm(seed)

println("\nBest Layout\n")
println(best_layout)
println("Best Layout score: ", evaluate_fitness(best_layout, true))

qwerty = [
  'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
  'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
]
reshaped_qwerty = permutedims(reshape(qwerty, 10, 3))

println("\nQwerty\n")
println(reshaped_qwerty)
println("Qwerty score: ", evaluate_fitness(reshaped_qwerty, true))

halmak = [
  'w', 'l', 'r', 'b', 'z', ';', 'q', 'u', 'd', 'j',
  's', 'h', 'n', 't', ',', '.', 'a', 'e', 'o', 'i',
  'f', 'm', 'v', 'c', '/', 'g', 'p', 'x', 'k', 'y'
]
reshaped_halmak = permutedims(reshape(halmak, 10, 3))

println("\nHalmak\n")
println(reshaped_halmak)
println("Halmak score: ", evaluate_fitness(reshaped_halmak, true))

test = [
  'f', 'h', 'b', 'g', 'c', ';', 'p', 'l', 'd', 'v',
  'u', 'r', 'a', 'e', 'k', 't', 'i', 'n', 'm', 's',
  'q', 'x', 'z', 'o', 'w', 'j', 'y', ',', '.', '/'
]
reshaped_test = permutedims(reshape(test, 10, 3))

println("\nTest\n")
println(reshaped_test)
println("Test score: ", evaluate_fitness(reshaped_test, true))
