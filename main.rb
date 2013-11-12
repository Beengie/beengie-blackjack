require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

# TODO: 
# 1. pull image from helper
# 2. set betting to work (adding when win and special earnings with blackjack)
# 3. fix styling
# 4. improve workflow

BLACKJACK_VALUE = 21
DEALER_STANDS = 17
set :sessions, true

helpers do
  def add_cards(add_cards, hide = false) # add totals to cards
    value = 0
    flag_ace = false
    ace_count = 0
    # print add_cards[1]
    add_cards.each do |s, c|
      if hide == false
        if c.is_a? Integer
          value +=c
        else
          if c == "ace"
            flag_ace = true
            ace_count += 1
            value +=11
          else
            value +=10
          end
        end
      else
        hide = false
      end
    end
    if ace_count != 0
      if flag_ace == true && value > BLACKJACK_VALUE
        for aces in 1..ace_count
          value -= 10
        end
      end
    end
    return value
  end

  def need_cards?
    if session[:deck].size == 0 
      binding.pry
      session[:game_message] = "The deck has been shuffled."
      new_deck
      if session[:player_cards].size > 0
        session[:player_cards].each do |card|
          session[:deck].delete(session[card])
        end
      end
      if session[:dealer_cards].size > 0
        session[:dealer_cards].each do |card|
          session[:deck].delete(session[card])
        end
      end
    end
  end

  def stats_table
    string = "<table><thead><th>Stats</th></thead>"
    string << "<tr><td align='center'>#{session[:deck].size} cards in deck</td></tr>"
    string << "<tr><td align='center'>Games: #{session[:games]} / Wins: #{session[:wins]}<br/>%#{(session[:wins].to_f/session[:games].to_f) * 100}</td></tr>"
    string << "<tr><td>#{session[:player_name]}'s chips: $#{session[:player_chips].to_s}</td></tr>"
    string << "<tr><td>Current bet: $#{session[:player_bet].to_s}</td></tr>"
    string << "<tr><td>#{session[:player_name]}'s hand: #{add_cards(session[:player_cards]).to_s}</td></tr>"
    string << "<tr><td>&nbsp;</td></tr>"

    unless session[:game_won] == false
      mini = "Dealer has: " 
    else 
      mini = "Dealer showing: " 
    end 
    string << "<tr><td>#{mini} #{add_cards(session[:dealer_cards], session[:first_card]).to_s}</td></tr>"


    string << "</table>"
    return string
  end

  def card_pic(card)
    # binding.pry
    return "<img id=\"card\" src=\"images/cards/#{card[0]}_#{card[1]}.jpg\" />"
  end

  def set_chips
    session[:player_chips] = 500
  end

  def new_deck
    session[:deck] = []
    for suit_num in 1..4 # set suits
      case suit_num
      when 1
        suit = "hearts"
      when 2
        suit = "diamonds"
      when 3
        suit = "spades"
      when 4
        suit = "clubs"
      end

      session[:deck].push([suit, "ace"])
      for card in 2..10 # set numbered cards
        session[:deck].push([suit, card])
      end

      for face_card_num in 1..3 # set face cards
        case face_card_num
        when 1
          face_card = "jack"
        when 2
          face_card = "queen"
        when 3
          face_card = "king"
        end
        session[:deck].push([suit, face_card])
      end
    end
    session[:deck].shuffle!
  end

  def reset_values
    session[:game_won] = false
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:player_bet] = 0
    session[:player_win_hand_chips] = 0
    session[:game_message] = nil
  end
end

def is_blackjack?(card_array) # see if cards are blackjack
  if add_cards(card_array) == BLACKJACK_VALUE 
    true 
  else
    false
  end
end

def add_chips(push_bj = "")
  if push_bj == "blackjack"
    session[:player_win_hand_chips] = (session[:player_bet] * (3.0/2.0)).to_i
  elsif push_bj == "push"
    session[:player_win_hand_chips] = session[:player_bet].to_i
  else
    session[:player_win_hand_chips] = (session[:player_bet] * 2).to_i
  end
  session[:player_chips] += session[:player_win_hand_chips]
end

def have_winner
  if add_cards(session[:dealer_cards]) > BLACKJACK_VALUE
    add_chips
    session[:wins] += 1
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "The dealer busted with #{add_cards(session[:dealer_cards])}! You win #{session[:player_win_hand_chips]} chips... "
  elsif add_cards(session[:player_cards]) > BLACKJACK_VALUE
    add_chips
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "You busted! The dealer wins with #{add_cards(session[:dealer_cards])}."
  elsif add_cards(session[:dealer_cards]) > add_cards(session[:player_cards])
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "The dealer won with #{add_cards(session[:dealer_cards])}."
  elsif add_cards(session[:player_cards]) > add_cards(session[:dealer_cards])
    add_chips
    session[:wins] += 1
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "The dealer stays at #{add_cards(session[:dealer_cards])}. You win #{session[:player_win_hand_chips]} chips..."
  elsif add_cards(session[:player_cards]) ==  add_cards(session[:dealer_cards])
    add_chips("push")
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "It's a push. You receive your #{session[:player_win_hand_chips]} back."
  end
end


def deal_cards
  need_cards?
  session[:player_cards] << session[:deck].pop
  need_cards?
  session[:dealer_cards] << session[:deck].pop
  need_cards?
  session[:player_cards] << session[:deck].pop
  need_cards?
  session[:dealer_cards] << session[:deck].pop
end

get '/' do
  set_chips
  new_deck
  session[:games] = 0
  session[:wins] = 0
  reset_values
  erb :new_game
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  erb :place_bet
end

post '/play_again' do
  # binding.pry
  if params[:play_again] == "Play Again"
    reset_values
    erb :place_bet
  else
    reset_values
    session[:game_message] = "Thanks for playing, goodbye"
    erb :blackjack
  end
end

post '/hit_stay' do
  # binding.pry
  if params[:hit_stay] == "Hit"
    need_cards?
    session[:player_cards] << session[:deck].pop
    if add_cards(session[:player_cards]) > BLACKJACK_VALUE
      session[:game_message] = have_winner
    end
    erb :blackjack
  else
    while add_cards(session[:dealer_cards]) < DEALER_STANDS
      need_cards?
      session[:dealer_cards] << session[:deck].pop
    end
    session[:game_message] = have_winner
  end
  erb :blackjack
end

post '/place_bet' do
  session[:player_bet] = params[:player_bet].to_i
  session[:player_chips] -= session[:player_bet]
  deal_cards
  if is_blackjack?(session[:player_cards]) == true || is_blackjack?(session[:dealer_cards]) == true
    if is_blackjack?(session[:player_cards]) == true && is_blackjack?(session[:dealer_cards]) == true
     session[:game_message] = have_winner
    else
      if is_blackjack?(session[:player_cards]) == true
        add_chips("blackjack")
        session[:wins] += 1
        session[:games] += 1
        session[:game_won] = true
        session[:game_message] = session[:player_name] + ", you got blackjack!  You win #{session[:player_win_hand_chips]} chips..."
      elsif is_blackjack?(session[:dealer_cards]) == true
        session[:games] += 1
        session[:game_won] = true
        session[:game_message] = "The dealer got blackjack, you lose."
      end
    end
  end

  erb :blackjack
end

get '/blackjack' do 
  erb :blackjack
end
