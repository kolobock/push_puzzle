require 'priority_queue'

class Algorithm
  attr_reader :states

  def progress!
    progress "nodes visited: #{@close.size}\t\tfrontier count: #{@open.length}"
  end

  def progress(str)
    print "\r"
    print str
    STDOUT.flush
  end

  def search(start_state)
    @close = Set.new
    # @open = Set.new
    @open = PriorityQueue.new

    start_state.setG 0
    start_state.setH State.getH(start_state)
    @open.push start_state, start_state.getF

    until @open.empty? do
      progress!
      x = @open.delete_min_return_key
      # x = getMin
      break x if x.solved?
      @close.add x.puzzle
      # @open.delete x
      x.branches.each do |neighbor|
        next if @close.include? neighbor.puzzle
        g = x.g + x.getDistance(neighbor)
        isBetter = false
        if inc = @open.include?(neighbor)
          isBetter = g < neighbor.g
        else
          neighbor.setH State.getH(neighbor)
          @open.push neighbor, neighbor.getF
          isBetter = true
        end
        if isBetter
          neighbor.set_parent x.puzzle
          neighbor.setG g
          @open.change_priority(neighbor, neighbor.getF) if inc
        end
      end
    end
  end

  private

  def getMin
    @open.each.sort_by { |s| s.getF }.first
  end
end

class State

  # Directions = [:up, :down, :left, :right]

  # attr_reader :puzzle, :path, :parent
  attr_reader :puzzle, :parent, :g, :h
  Size = FifteenPuzzle::PuzzleDimension
  SolvedPuzzle = FifteenPuzzle.solved_puzzles
  Directions = [-Size, Size, -1, 1]

  def initialize(puzzle, parent=nil)
    @puzzle = puzzle
    @parent = parent
    # @size = (@puzzle.size ** 0.5).to_i
    # top = -Size
    # bottom = Size
    # left = -1
    # right = 1
    # @directions = [top, bottom, left, right]
    @g = @h = 0
  end

  def self.solved_puzzle(size)
    @solved_puzzle && @solved_puzzle[:"#{size}"] ||
      @solved_puzzle = { "#{size}".to_sym => (1..size ** 2 - 1).to_a.concat([0]) }
      # @solved_puzzle[:"#{size}"] = (0..size ** 2).to_a
  end

  def self.getH(state)
    penalty = Size
    res = 0
    (0..state.puzzle.size).each do |ind|
      if (ind+1) % Size == 0
        penalty -= 1
      end
      if state.puzzle[ind] != SolvedPuzzle[ind]
        res += penalty
      end
    end
    # state.puzzle.zip(solved_puzzle(state.size)).count {|a,b| a != b}
    res
  end

  def solved?
    puzzle.eql? self.class::SolvedPuzzle
  end

  def branches
    # Directions.map do |dir|
    #   branch_toward dir
    # end.compact.shuffle
    # @directions.map do | dir|
    Directions.map do | dir|
      branch_toward dir
    end.compact.shuffle
  end

  def getF
    g + h
  end

  def setG(num)
    @g = num.to_i
  end

  def setH(num)
    @h = num.to_i
  end

  def set_parent(p)
    @parent = p
  end

  def getDistance(s)
    res = 0
    while s.present? && self.not_eql?(s)
      s = s.parent
      res += 1
    end
    res
  end

  def not_eql?(st)
    ! puzzle.eql?(st.puzzle)
  end

  private

  def branch_toward(direction)
    # blank_position = puzzle.zero_position
    # blankx = blank_position % puzzle.class::PuzzleDimension
    # blanky = (blank_position / puzzle.class::PuzzleDimension).to_i
    # cell = case direction
    #        when :left
    #          blank_position - 1 unless 0 == blankx
    #        when :right
    #          blank_position + 1 unless (puzzle.class::PuzzleDimension - 1) == blankx
    #        when :up
    #          blank_position - puzzle.class::PuzzleDimension unless 0 == blanky
    #        when :down
    #          blank_position + puzzle.class::PuzzleDimension unless (puzzle.class::PuzzleDimension - 1) == blanky
    #        end
    # State.new puzzle.swap(cell), @path + [direction] if cell
    zero = puzzle.index(0)
    number = zero + direction
    return if number < 0 || number >= puzzle.size
    return if direction == 1 && ((zero + 1) % Size == 0)
    return if direction == -1 && ((zero + 1) % Size == 1)
    new_puzzle = puzzle.dup
    new_puzzle[zero] = new_puzzle[number]
    new_puzzle[number] = 0
    State.new new_puzzle
  end
end

