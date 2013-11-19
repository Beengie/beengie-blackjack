require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

# TODO:
# 1. Make player_name entry on same page as the well
# 2. Double down
# 3. Handle split?

BLACKJACK_VALUE = 21
DEALER_STANDS = 17
SHOW_ENVIRONMENT = true
set :sessions, true

helpers do
  def add_cards(add_cards, hide = false) # add totals to cards
    value = 0
    flag_ace = false
    ace_count = 0
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
 
  def show_env
    if SHOW_ENVIRONMENT
      string = "<div class=\"dropdown\">"
      string << "<a class=\"btn dropdown-toggle\" data-toggle=\"dropdown\" href=\"#\">Click to see environment details <span class=\"caret\"></span></a>"
      string << "<ul id=\"menu1\" class=\"dropdown-menu\" role=\"menu\" aria-labelledby=\"dLabel\">"
      env.each do |k, v|
        if v.is_a?(Hash)
          v.each do |l, m|
            unless m.is_a?(Array)
              string << "<li role=\"presentation\" id=\"dLabel\">#{l}: #{m}</li>"
            else
              string << "<li>#{l}:</li>"

              string << "<ul>"
              m.each do |p|
                string << "<li>#{p}</li>"
              end
              string << "</ul>"
            end
          end
        else
          string << "<li>#{k}: #{v}</li>"
        end
      end
      string << "</ul></div>"
      return string
    end
  end

  def player_view
    if session[:player_cards].size != 0
      string = "<div id='player_div'>"
      string << "<h4>#{session[:player_name]}'s cards:</h4>"
      session[:player_cards].each do |card|
        string << card_pic(card)
      end
      string << "</div>"
      return string
    end
  end

  def dealer_view
    if session[:dealer_cards].size != 0
      string = "<div id='dealer_div'>"
      string << "<h4>Dealer's cards:</h4>"
      session[:dealer_cards].each do |card|
        if session[:first_card] == true
          string << "<img id='card' src='images/cards/cover.jpg' />"
          session[:first_card] = false
        else
          string << card_pic(card)
        end
      end
      string << "</div>"
      return string
    end
  end

  def form_buttons
    bet_label = ""
    if session[:player_cards].size != 0
      string = "<h5>Would you like to?</h5>"
    else
      string = "<h5>Place initial bet.</h5>"
    end
    mini = ""
    action = ""
    if session[:game_won] == false
      action = "/hit_stay"
      mini = "<div class='btn-group'>"
      mini << "<button id='hit_button' type='submit' name='hit_stay' value='hit' class='btn'>Hit</button>"
      mini << "<button id='stay_button' type='submit' name='hit_stay' value='stay' class='btn'>Stay</button>"
      mini << "</div>"
    elsif session[:game_won] == true && session[:player_chips] == 0
      action = "/more_money"
      mini << "<button id='more' type='submit' name='more' value='more' class='btn'>$500 more</button>"
      mini << "<button id='quit' type='submit' name='more' value='quit' class='btn'>Quit</button>"  
    elsif session[:game_won] == true || session[:game_won] == "new"
      if session[:player_chips] >= 50
        max_bet = 50
      else
        max_bet = session[:player_chips]
      end
      bet_label = "Place bet"
      action = "/place_bet"
      mini = "<div class='input-prepend input-append'>"
      mini << "<span class='add-on'>$</span>"
      mini << "<input class='input-mini' name='player_bet' type='number' min='1' max='#{max_bet}' value='#{session[:player_bet]}'/>>"
      mini << "<div class='btn-group'>"
      mini << "<button id='again_yes' type='submit' name='play_again' value='play' class='btn'>#{bet_label}</button>"
      mini << "<button id='quit' type='submit' name='play_again' value='quit' class='btn'>Quit</button>"
      mini << "</div>"
      mini << "</div>"
    end
    string << "<form id='form_btns' method='post' action='#{action}'>"
    string << mini
    string << "</form>"

    unless session[:game_won] == "bye"
      return string
    end
  end

  def need_cards?
    if session[:deck].size == 0 
      session[:game_message] = "The deck has been shuffled."
      new_deck
      if session[:player_cards].size > 0
        session[:player_cards].each do |card|
          session[:deck].delete(card)
        end
      end
      if session[:dealer_cards].size > 0
        session[:dealer_cards].each do |card|
          session[:deck].delete(card)
        end
      end
    end
  end

  def stats_table
    if session[:games] == 0
      win_percent = 0
    else
      win_percent = ((session[:wins].to_f/session[:games].to_f) * 100).round(1)
    end
    string = "&nbsp;<br/><table><thead><th>Stats</th></thead>"
    string << "<tr><td align='center'>#{session[:deck].size} cards in deck</td></tr>"
    string << "<tr><td align='center'>Games: #{session[:games]} / Wins: #{session[:wins]}<br/>%#{win_percent}</td></tr>"
    string << "<tr><td>#{session[:player_name]}'s chips: $#{session[:player_chips].to_s}</td></tr>"
    string << "<tr><td>Current bet: $#{session[:player_bet].to_s}</td></tr>"
    string << "<tr><td>&nbsp;</td></tr>"\

    if session[:player_cards].size != 0
      string << "<tr><td>#{session[:player_name]}'s hand: #{add_cards(session[:player_cards]).to_s}</td></tr>"
      unless session[:game_won] == false
        mini = "Dealer has: " 
      else 
        mini = "Dealer showing: " 
      end 
      string << "<tr><td>#{mini} #{add_cards(session[:dealer_cards], session[:first_card]).to_s}</td></tr>"
    end
    string << "</table>"
    unless session[:game_won] == "bye"
      return string
    end
  end

  def card_pic(card)
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
    no_money?
  elsif add_cards(session[:player_cards]) > BLACKJACK_VALUE
    add_chips
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "You busted! The dealer wins with #{add_cards(session[:dealer_cards])}."
    no_money?
  elsif add_cards(session[:dealer_cards]) > add_cards(session[:player_cards])
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "The dealer won with #{add_cards(session[:dealer_cards])}."
    no_money?
  elsif add_cards(session[:player_cards]) > add_cards(session[:dealer_cards])
    add_chips
    session[:wins] += 1
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "The dealer stays at #{add_cards(session[:dealer_cards])}. You win #{session[:player_win_hand_chips]} chips..."
    no_money?
  elsif add_cards(session[:player_cards]) ==  add_cards(session[:dealer_cards])
    add_chips("push")
    session[:games] += 1
    session[:game_won] = true
    session[:game_message] = "It's a push. You receive your #{session[:player_win_hand_chips]} back."
    no_money?
  end
end

def no_money?
  if session[:player_chips] == 0
    session[:game_message] << "<br/>You are out of chips! The house took it all. Thanks for the money."
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
  session[:game_won] = "new"
  erb :blackjack
end

post '/more_money' do
  if params[:more] == "more"
  reset_values
  set_chips
  session[:game_won] = "new"
  erb :blackjack
  else
    redirect '/goodbye'
  end
end

get '/goodbye' do
  reset_values
  session[:game_message] = "Thanks for playing, goodbye"
  session[:game_won] = "bye"
  erb :blackjack
end

post '/hit_stay' do
  if params[:hit_stay] == "hit"
    need_cards?
    session[:player_cards] << session[:deck].pop
    if add_cards(session[:player_cards]) > BLACKJACK_VALUE
      have_winner
    end
    erb :blackjack
  else
    while add_cards(session[:dealer_cards]) < DEALER_STANDS
      need_cards?
      session[:dealer_cards] << session[:deck].pop
    end
    have_winner
  end
  erb :blackjack
end

post '/place_bet' do
  if params[:play_again] == "play"
    session[:game_won] = false
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:game_message] = nil
    session[:player_bet] = params[:player_bet].to_i
    session[:player_chips] -= session[:player_bet]
    deal_cards
    if is_blackjack?(session[:player_cards]) == true || is_blackjack?(session[:dealer_cards]) == true
      if is_blackjack?(session[:player_cards]) == true && is_blackjack?(session[:dealer_cards]) == true
        have_winner
      else
        if is_blackjack?(session[:player_cards]) == true
          add_chips("blackjack")
          session[:wins] += 1
          session[:games] += 1
          session[:game_won] = true
          session[:game_message] = session[:player_name] + ", you got blackjack!  You win #{session[:player_win_hand_chips]} chips..."
          no_money?
        elsif is_blackjack?(session[:dealer_cards]) == true
          session[:games] += 1
          session[:game_won] = true
          session[:game_message] = "The dealer got blackjack, you lose."
          no_money?
        end
      end
    end
  erb :blackjack
  else
    redirect '/goodbye'
  end
end