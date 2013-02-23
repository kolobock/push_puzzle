class PuzzleController < ApplicationController
  def index
    @puzzles = (0..15).to_a.shuffle
  end
end
