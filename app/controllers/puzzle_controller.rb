class PuzzleController < ApplicationController
  def index
    # @puzzles = (0..15).to_a.shuffle
    @puzzles = Puzzle.new.generate_puzzles
  end

  def new
    @puzzles = Puzzle.new.generate_puzzles
    render json: @puzzles
  end
end
