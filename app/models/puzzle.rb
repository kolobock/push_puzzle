class Puzzle
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  PushPuzzles = (0..15).to_a.freeze

  attr_accessor :puzzles

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def generate_puzzles
    @puzzles = PushPuzzles.shuffle
    self.generate_puzzles unless self.can_be_solved?
    @puzzles
  end

  ## Algorithm from
  # =>http://ru.m.wikipedia.org/wiki/%D0%9F%D1%8F%D1%82%D0%BD%D0%B0%D1%88%D0%BA%D0%B8#section_2
  def can_be_solved?
    digit_puzzles = @puzzles - [0]
    noi_sum = 0
    (1..14).each do |n|
      num = digit_puzzles[n-1]
      noi_sum += digit_puzzles[n, 15 - n].count { |p| p < num }
    end
    empty = @puzzles.index(0) / 4 + 1
    (noi_sum + empty).even?
  end
end
