class Puzzle
  require 'inline'

  # include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  PuzzleDimension = 0

  class << self
    def puzzle_size
      @puzzle_size ||= self::PuzzleDimension ** 2 - 1
    end

    def solved_puzzles
      @solved_puzzles ||= (1..self.puzzle_size).to_a.concat([0]).freeze
      # @solved_puzzles ||= (0..self.puzzle_size).to_a.freeze
    end
  end

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
    @zero_position = @distance_to_goal = nil
    @puzzles = self.class.solved_puzzles.shuffle
    self.generate_puzzles unless self.can_be_solved?
    puzzles
  end

  ## Algorithm from
  # =>http://ru.m.wikipedia.org/wiki/%D0%9F%D1%8F%D1%82%D0%BD%D0%B0%D1%88%D0%BA%D0%B8#section_2
  def can_be_solved?
    digit_puzzles = puzzles - [0]
    empty_row = zero_position / self.class::PuzzleDimension + 1
    ((1..self.class.puzzle_size-1).inject(0) do |noi, n|
      noi += digit_puzzles[n, self.class.puzzle_size - n].count { |p| p < digit_puzzles[n-1] }
    end + empty_row).even?
  end

  def solved?
    self.class.solved_puzzles == puzzles
  end

  def zero_position
    @zero_position ||= puzzles.index(0)
  end

  def swap(swap_index)
    new_puzzles = puzzles.clone
    new_puzzles[zero_position] = new_puzzles[swap_index]
    new_puzzles[swap_index] = 0
    self.class.new new_puzzles
  end

  ### source http://6brand.com/solving-8-puzzle-with-artificial-intelligence.html
  def distance_to_goal
    @distance_to_goal ||= begin
      puzzles.zip(self.class.solved_puzzles).count { |a,b| a != b }
      # puzzles.zip(self.class.solved_puzzles).inject(0) do |sum, (a,b)|
      #   return sum unless a && b
      #   sum += manhattan_distance a % self.class::PuzzleDimension, (a / self.class::PuzzleDimension).to_i,
      #                             b % self.class::PuzzleDimension, (b / self.class::PuzzleDimension).to_i
      # end
    end
  end

  private

  # def manhattan_distance(x1, y1, x2, y2)
  #   (x1 - x2).abs + (y1 - y2).abs
  # end
  inline(:C) do |builder|
    builder.c "
               int manhattan_distance(int x1, int y1,
                                      int x2, int y2) {
                   int x = x1 - x2;
                   int y = y1 - y2;
                   return (x < 0 ? -x : x) + ( y < 0 ? -y : y);
                 }
    "
  end

end

# class State
#   Directions = [:left, :right, :up, :down]
# 
#   attr_reader :puzzle, :path, :parent
# 
#   def initialize(puzzle, path = [])
#     @puzzle, @path = puzzle, path
#   end
# 
#   def solved?
#     puzzle.solved?
#   end
# 
#   def branches
#     Directions.map do |dir|
#       branch_toward dir
#     end.compact.shuffle
#   end
# 
#   def cost
#     @cost ||= steps_from_start + steps_to_goal
#   end
# 
#   def steps_from_start
#     @steps_from_start ||= path.size
#   end
# 
#   def steps_to_goal
#     @steps_to_goal ||= puzzle.distance_to_goal
#   end
# 
#   # def <=>(b)
#   #   self.cost <=> b.cost
#   # end
# 
#   def set_parent(p)
#     @parent = p
#   end
# 
#   private
# 
#   def branch_toward(direction)
#     blank_position = puzzle.zero_position
#     blankx = blank_position % puzzle.class::PuzzleDimension
#     blanky = (blank_position / puzzle.class::PuzzleDimension).to_i
#     cell = case direction
#            when :left
#              blank_position - 1 unless 0 == blankx
#            when :right
#              blank_position + 1 unless (puzzle.class::PuzzleDimension - 1) == blankx
#            when :up
#              blank_position - puzzle.class::PuzzleDimension unless 0 == blanky
#            when :down
#              blank_position + puzzle.class::PuzzleDimension unless (puzzle.class::PuzzleDimension - 1) == blanky
#            end
#     State.new puzzle.swap(cell), @path + [direction] if cell
#   end
# end
# 
class PuzzleSolve
  require 'set'
  require 'timeout'
  require 'priority_queue'

  class << self
    def search(state)
      $visited << state.puzzle.puzzles.hash
      state.branches.reject do |branch|
        $visited.include? branch.puzzle.puzzles.hash
      end.each do |branch|
        # $frontier << branch
        $frontier.push branch, branch.cost
        branch.set_parent(state) if state.cost < branch.cost
      end
      # $frontier.sort!
    end

    def progress!
      progress "nodes visited: #{$visited.size}\t\tfrontier count: #{$frontier.length}"
    end

    def solve(puzzle)
      $visited = Set.new
      # $frontier = Queue.new
      $frontier = PriorityQueue.new
      state = State.new puzzle
      Timeout::timeout(120) do
        begin
          progress!
          break if state.solved?
          search state
          # return if $frontier.length == 0
          # state = $frontier.pop
          # state = $frontier.delete_min
          state = $frontier.delete_min.first
        end until $frontier.empty?
      end
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

# class Queue
#   attr_reader :elements
#   def initialize
#     @elements = []
#   end
# 
#   def <<(element)
#     @elements << element
#     # sort!
#   end
# 
#   def delete_min
#     @elements.delete( @elements.min { |el| el.cost } )
#   end
# 
#   def pop
#   #   el = @elements.select { |s| ss = s.path.size; ps = $parent_state.path.size; ss >= ps ? s.path[0,ps] == $parent_state.path : $parent_state.path[0,ss] == s.path } if $parent_state
#   #   el = @elements unless el.present?
#   #   @elements.delete(el.first)
#     @elements.shift
#   end
# 
#   def length
#     @elements.size
#   end
#   alias_method :size, :length
# 
#   def include?(el)
#     @elements.include? el
#   end
# 
#   def sort!
#     @elements = @elements.sort_by { |s| s.cost }
#   end
# end
# 
