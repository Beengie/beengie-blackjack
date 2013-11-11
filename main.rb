require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

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
  erb :new_game
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  erb :place_bet
end

get '/test' do
  # binding.pry
  "MAF Industries " << params[:some]
end

get '/place_bet' do
  # redirect '/place_bet'
end

post '/place_bet' do
  session[:player_bet] = params[:player_bet].to_i
  session[:player_chips] -= session[:player_bet]
  deal_cards
  redirect '/blackjack'
end

get '/blackjack' do 
  # player_turn
  # dealer_turn
  # check winner
  # play_again

  erb :blackjack
  # erb :blackjack, layout: false # removes laout
end
