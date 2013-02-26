class Puzzle
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  PuzzleDimension = 4
  # PuzzleDimension = 3
  PuzzleSize = PuzzleDimension ** 2 - 1
  SolvedPuzzles = (1..PuzzleSize).to_a.concat([0]).freeze

  attr_reader :puzzles

  # def initialize(attributes = {})
  #   attributes.each do |name, value|
  #     send("#{name}=", value)
  #   end
  # end
  def initialize(puzzles=nil)
    @puzzles = puzzles
  end

  def generate_puzzles
    @puzzles = SolvedPuzzles.shuffle
    self.generate_puzzles unless self.can_be_solved?
    puzzles
  end

  ## Algorithm from
  # =>http://ru.m.wikipedia.org/wiki/%D0%9F%D1%8F%D1%82%D0%BD%D0%B0%D1%88%D0%BA%D0%B8#section_2
  def can_be_solved?
    digit_puzzles = puzzles - [0]
    empty_row = zero_position / PuzzleDimension + 1
    ((1..PuzzleSize-1).inject(0) do |noi, n|
      noi += digit_puzzles[n, PuzzleSize - n].count { |p| p < digit_puzzles[n-1] }
    end + empty_row).even?
  end

  def solved?
    SolvedPuzzles == puzzles
  end

  def zero_position
    @zero_position ||= puzzles.index(0)
  end

  def swap(swap_index)
    new_puzzles = puzzles.clone
    new_puzzles[zero_position] = new_puzzles[swap_index]
    new_puzzles[swap_index] = 0
    Puzzle.new new_puzzles
  end

  ### source http://6brand.com/solving-8-puzzle-with-artificial-intelligence.html
  def distance_to_goal
    @distance_to_goal ||= begin
      puzzles.zip(SolvedPuzzles).inject(0) do |sum, (a,b)|
        sum += manhattan_distance a % PuzzleDimension, a / PuzzleDimension.to_i,
                                  b % PuzzleDimension, b / PuzzleDimension.to_i
      end
    end
  end

  private

  def manhattan_distance(x1, y1, x2, y2)
    (x1 - x2).abs + (y1 - y2).abs
  end
end

class State
  Directions = [:left, :right, :up, :down]

  attr_reader :puzzle, :path

  def initialize(puzzle, path = [])
    @puzzle, @path = puzzle, path
  end

  def solved?
    puzzle.solved?
  end

  def branches
    Directions.map do |dir|
      branch_toward dir
    end.compact.shuffle
  end

  def cost
    steps_from_start + steps_to_goal
  end

  def steps_from_start
    path.size
  end

  def steps_to_goal
    puzzle.distance_to_goal
  end

  private

  def branch_toward(direction)
    blank_position = puzzle.zero_position
    blankx = blank_position % Puzzle::PuzzleDimension
    blanky = (blank_position / Puzzle::PuzzleDimension).to_i
    cell = case direction
           when :left
             blank_position - 1 unless 0 == blankx
           when :right
             blank_position + 1 unless (Puzzle::PuzzleDimension - 1) == blankx
           when :up
             blank_position - Puzzle::PuzzleDimension unless 0 == blanky
           when :down
             blank_position + Puzzle::PuzzleDimension unless (Puzzle::PuzzleDimension - 1) == blanky
           end
    State.new puzzle.swap(cell), @path + [direction] if cell
  end
end

class PuzzleSolve
  require 'set'
  require 'timeout'

  class << self
    def search(state)
      $visited << state.puzzle.puzzles
      state.branches.reject do |branch|
        $visited.include? branch.puzzle.puzzles
      end.each do |branch|
        $frontier << branch
      end
    end

    def progress!
      progress "nodes visited: #{$visited.size}\t\tfrontier count: #{$frontier.length}"
    end

    def solve(puzzle)
      $visited = Set.new
      $frontier = Queue.new
      state = State.new puzzle
      # Timeout::timeout(300) do
      loop {
        progress!
        break if state.solved?
        search state
        return if $frontier.length == 0
        state = $frontier.pop
      }
      # end
      puts ''
      state
    end

    def progress(str)
      print "\r"
      print str
      STDOUT.flush
    end
  end
end

class Queue
  def initialize
    @elements = []
  end

  def <<(element)
    @elements << element
    sort!
  end

  def pop
    @elements.shift
  end

  def length
    @elements.size
  end

  private

  def sort!
    @elements = @elements.sort_by { |s| s.cost }
  end
end
