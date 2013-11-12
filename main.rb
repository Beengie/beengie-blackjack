require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

# TODO: 
# 1. pull image from helper
# 2. set betting to work (adding when win and special earnings with blackjack)
# 3. fix styling
# 4. improve workflow


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
      if flag_ace == true && value > 21
        for aces in 1..ace_count
          value -= 10
        end
      end
    end
    return value
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
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:game_message] = nil
  end
end

def is_blackjack?(card_array) # see if cards are blackjack
  if add_cards(card_array) == 21 
    true 
  else
    false
  end
end

def have_winner(player_cards, dealer_cards)
  dealers_hand_value = add_cards(dealer_cards)
  players_hand_value = add_cards(player_cards)
  if dealers_hand_value > 21
    return "The dealer busted! You win!"
    winner = true
  elsif players_hand_value > 21
    return "You busted! The dealer wins!"
    winner = true
  elsif dealers_hand_value > players_hand_value
    return "The dealer won."
    winner = true
  elsif players_hand_value > dealers_hand_value
    return "You won!"
    winner = true
  elsif players_hand_value ==  dealers_hand_value
    return "It's a push."
    winner = true
  end

end


def deal_cards
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
end

get '/' do
  set_chips
  new_deck
  session[:game_message] = nil
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
    session[:player_cards] << session[:deck].pop
    if add_cards(session[:player_cards]) > 21
      session[:game_message] = have_winner(session[:player_cards], session[:dealer_cards])
    end
    erb :blackjack
  else
    while add_cards(session[:dealer_cards]) < 17
      session[:dealer_cards] << session[:deck].pop
    end
    session[:game_message] = have_winner(session[:player_cards], session[:dealer_cards])
  end
  erb :blackjack
end

post '/place_bet' do
  session[:player_bet] = params[:player_bet].to_i
  session[:player_chips] -= session[:player_bet]
  deal_cards
  if is_blackjack?(session[:player_cards]) == true || is_blackjack?(session[:dealer_cards]) == true
    if is_blackjack?(session[:player_cards]) == true && is_blackjack?(session[:dealer_cards]) == true
     session[:game_message] = have_winner(session[:player_cards], session[:dealer_cards])
    else
      if is_blackjack?(session[:player_cards]) == true
        session[:game_message] = session[:player_name] << ", you got blackjack!"
      elsif is_blackjack?(session[:dealer_cards]) == true
         session[:game_message] = "The dealer got blackjack, you lose."
      end
    end
  end

  erb :blackjack
end

get '/blackjack' do 
  erb :blackjack
end
