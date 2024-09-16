##### Genetic Algorithm

using Random
using PrettyPrinting
using Base: ReverseOrdering
using Test

# TODO:
# x Init_pop
# x eval_fit
# 	- Travel Distance
# 	- Finger Usage
# 	- Consecutive Finger Use
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
    fit_scores = []
    for genome in pop
      genome_fitness = evaluate_fitness(genome)
      push!(fit_scores, [gen, genome, genome_fitness])
    end

    sorted_pop = sort(fit_scores, by=x -> x[3])
    parents = selection(sorted_pop, 5)

    new_pop = []
    push!(new_pop, sorted_pop[1][2])

    while length(new_pop) < POPULATION_SIZE
      if rand(1:100) < CROSSOVER_RATE
        child = crossover(parents)
        if rand(1:100) < MUTATION_RATE
          child = mutate(child)
        end
        push!(new_pop, child)
      else
        push!(new_pop, generate_random_genome())
      end
    end
    pop = new_pop
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

  return permutedims(reshape(keys, 10, 3))
end

function initialize_population(pop_size::Int64)::Vector{Matrix{Char}}
  return [generate_random_genome() for _ in 1:pop_size]
end

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

function find_character_index(matrix::Matrix, char::Char)
  for i = 1:3
    for j = 1:10
      if matrix[i, j] == lowercase(char)
        return (i, j)
      end
    end
  end
end

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

function evaluate_fitness(genome::Matrix{Char})
  score = 0

  test_text = open(io -> read(io, String), "dummy_text.txt")

  score += evaluate_travel_distance(genome, test_text)

  # Fitness = Dict(
  # 	"Travel distance" => total_distance,
  # 	"Finger balance" => finger_usage,
  # 	"Consecutive finger usage" => tst,
  # )
end

function evaluate_travel_distance(genome, text_file)
  finger_assignments = create_finger_assignment_dict(genome)

  total_distance = 0
  buffer_coordinates = (0, 0)
  buffer_finger = ""

  for char in lowercase(text_file)
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments[char]

      if current_finger == buffer_finger
        start_coordinates = buffer_coordinates
      else
        start_coordinates = default_finger_coordinate[current_finger]
      end

      end_coordinates = find_character_index(genome, char)
      total_distance += calculate_travel_distance(start_coordinates[1], start_coordinates[2], end_coordinates[1], end_coordinates[2])

      buffer_coordinates = end_coordinates
      buffer_finger = finger_assignments[char]
    end
  end

  return round(total_distance, digits=2)
end

function evaluate_finger_balance(genome, text_file)
  finger_assignments = create_finger_assignment_dict(genome)

  finger_usage = Dict()
  for finger in values(finger_assignments)
    finger_usage[finger] = 0
  end

  for char in lowercase(text_file)
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments[char]
      finger_usage[current_finger] += 1
    end
  end

  return finger_usage
end

function evaluate_consecutive_finger_usage(genome, text_file)
  finger_assignments = create_finger_assignment_dict(genome)

  count = 0
  buffer_finger = ""

  for char in lowercase(text_file)
    if !isspace(char) && (char in genome)
      current_finger = finger_assignments[char]
      if current_finger == buffer_finger
        count += 1
      end
      buffer_finger = current_finger
    end
  end

  return count
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
  return offspring
end

function mutate(offspring)
  rows, cols = size(offspring)

  i1, j1 = rand(1:rows), rand(1:cols)
  i2, j2 = rand(1:rows), rand(1:cols)

  temp = offspring[i1, j1]
  offspring[i1, j1] = offspring[i2, j2]
  offspring[i2, j2] = temp

  return offspring
end

function create_finger_assignment_dict(genome)
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

  return finger_assignments
end

@time best_layout = geneticalgorithm()
println("Best Layout")
println(best_layout, evaluate_fitness(best_layout))

qwerty = [
  'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
  'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
]
reshaped_qwerty = permutedims(reshape(qwerty, 10, 3))
println("Qwerty score: 15585.5")
# println("Qwerty score: ", evaluate_fitness(reshaped_qwerty))

halmak = [
  'w', 'l', 'r', 'b', 'z', ';', 'q', 'u', 'd', 'j',
  's', 'h', 'n', 't', ',', '.', 'a', 'e', 'o', 'i',
  'f', 'm', 'v', 'c', '/', 'g', 'p', 'x', 'k', 'y'
]
reshaped_halmak = permutedims(reshape(halmak, 10, 3))
println("Halmak score: 9514.65")
# println("Halmak score: ", evaluate_fitness(reshaped_halmak))
