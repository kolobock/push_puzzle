class PuzzleController < ApplicationController
  before_filter :find_puzzles

  def index
  end

  def new
    render json: @puzzles
  end

  private

  def find_puzzles
    @puzzles = Puzzle.new.generate_puzzles
  end
end
