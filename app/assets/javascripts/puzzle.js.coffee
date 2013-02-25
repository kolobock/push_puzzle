# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  init_puzzles()
  $('div#container button').click ->
    $.get(
      '/puzzle/new'
      'json'
      (puzzles) ->
        fill_puzzles puzzles
    )

can_move = (from, to) ->
  possibilities = switch to
    when 0 then [1, 4]
    when 1 then [0, 2, 5]
    when 2 then [1, 3, 6]
    when 3 then [2, 7]
    when 4 then [0, 5, 8]
    when 5 then [1, 4, 6, 9]
    when 6 then [2, 5, 7, 10]
    when 7 then [3, 6, 11]
    when 8 then [4, 9, 12]
    when 9 then [5, 8, 10, 13]
    when 10 then [6, 9, 11, 14]
    when 11 then [7, 10, 15]
    when 12 then [8, 13]
    when 13 then [9, 12, 14]
    when 14 then [10, 13, 15]
    when 15 then [11, 14]
    else []
  from in possibilities

jQuery.fn.swapWith = (to) ->
  copy_to = $(to).clone(true)
  copy_from = $(this).clone(true)
  $(to).replaceWith(copy_from)
  $(this).replaceWith(copy_to)

check_victory = ->
  cells = $('div#board table td')
  return false if $(cells).index($('.empty')) isnt 15
  win = [1..15]
  puzzles = $(cells).filter($(':not(.empty)'))
  for el, ind in $(puzzles)
    return(false) if win[ind] isnt +$(el).text()
  $(puzzles).unbind('click').addClass('victory')

init_puzzles = ->
  puzzles = $('div#board table td:not(.empty)')

  $(puzzles).click ->
    cells = $('div#board table td')
    index = $(cells).index($(this))
    empty_index = $(cells).index($(cells).filter('.empty'))

    if can_move(index, empty_index)
      $(this).swapWith($(cells).eq(empty_index))
      check_victory()

fill_puzzles = (puzzles) ->
  $('div#board table td').removeClass().each (ind, el) ->
    $(el).text(puzzles[ind])
    $(el).addClass('empty') if puzzles[ind] is 0
  init_puzzles()
