class Puzzle
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  PuzzleDimension = 4
  PuzzleSize = PuzzleDimension ** 2 - 1
  SolvedPuzzles = (0..PuzzleSize).to_a.freeze

  attr_accessor :puzzles, :solved_puzzles

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def generate_puzzles
    @puzzles = SolvedPuzzles.shuffle
    self.generate_puzzles unless self.can_be_solved?
    @puzzles
  end

  ## Algorithm from
  # =>http://ru.m.wikipedia.org/wiki/%D0%9F%D1%8F%D1%82%D0%BD%D0%B0%D1%88%D0%BA%D0%B8#section_2
  def can_be_solved?
    digit_puzzles = @puzzles - [0]
    empty_row = @puzzles.index(0) / PuzzleDimension + 1
    ((1..PuzzleSize-1).inject(0) do |noi, n|
      noi += digit_puzzles[n, PuzzleSize - n].count { |p| p < digit_puzzles[n-1] }
    end + empty_row).even?
  end

  def solve
    raise 'Cannot be solved!' unless self.can_be_solved?
    @solved_puzzles = self.class.solve(self.puzzles)
  end

  def self.solve(puzzles)

  end

  def distance_to_goal
    @distance_to_goal ||= @puzzles.zip(SolvedPuzzles).inject(0) do |sum, (a,b)|
      sum += manhattan_distance a % PuzzleDimension, a / PuzzleDimension,
                                b % PuzzleDimension, b / PuzzleDimension
    end
  end

  def manhattan_distance(x1, y1, x2, y2)
    (x1 - x2).abs + (y1 - y2).abs
  end
end
