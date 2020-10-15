# Example request
# https://8x16jr2jii.execute-api.us-east-1.amazonaws.com/dev/some-lambda-thing?action=drawCard&rank=5&suit=3
# Returns
# card: "5♥"
# https://8x16jr2jii.execute-api.us-east-1.amazonaws.com/dev/some-lambda-thing?action=dealHands&number=5

require 'aws-sdk'
require 'json'

def log_card(the_card)
  resp = client.put_item({
    item: {
      card: [the_card],
      game_id: game_id,
      item: "drawn_cards",
    },
    return_consumed_capacity: "TOTAL",
    table_name: "card-table",
  })
  resp.to_h
end


def lambda_handler(event:, context:)
  #{ statusCode: 200, body: JSON.generate(response(event["queryStringParameters"])) }
  query = event["queryStringParameters"]

  methods = [
    :function_name,
    :function_version,
    :invoked_function_arn,
    :memory_limit_in_mb,
    :aws_request_id,
    :log_group_name,
    :log_stream_name,
    :deadline_ms,
    :identity,
    :client_context,
  ]

  Card.create_deck

  context_items = methods.map { |m| { m => context.send(m) } }

  { statusCode: 200, body: JSON.generate(response(query).merge({ event: event, context: context_items })) }
end

def response(query)
  action = query["action"]

  if action == "drawCard"
    rank = query["rank"].to_i
    suit = query["suit"].to_i

    the_card = draw_card(rank, suit)

    return { card: the_card, log: log_card(the_card) }
  elsif action == "dealHands"
    number = query["number"].to_i
    return { hands: deal_hands(number) }
  else
    return { error: "I don't understand '#{query}'." }
  end
end

def deal_hands(number)
  resp = client.batch_get_item({
    request_items: {
      "card-table" => {
        keys: [
          {
            game_id: "poker",
            item: "deck",
          },
        ],
      },
    },
  })

  deck = resp[:responses]["card-table"].first["deck"]

  game = Game.new(game: "poker", deck: deck)

  hands = game.deal_hands(number)
  { hands: hands }
end

def client
  @_client ||= Aws::DynamoDB::Client.new
end

def draw_card(rank, suit)
  Card.new(rank: rank, suit: suit).to_s
end

class Game
  attr_reader :game
  attr_accessor :deck

  def initialize(game:, deck:)
    @game = game
    @deck = deck
  end

  def game_id
    # uuid
    "1"
  end

  def cards_per_hand
    return 5 if game == "poker"
  end

  def deal_hands(number)
    hands = {}
    number.times do |player|
      hand = []
      cards_per_hand.times do |index|
        hand << deck.delete_at(random_index(deck.length))
      end
      hands[player] = hand
    end

    update_deck
    hands
  end

  def random_index(size)
    Random.rand(size)
  end

  def update_deck
    client.put_item({
      item: {
        deck: deck,
        game_id: game_id,
        item: "deck",
      },
      return_consumed_capacity: "TOTAL",
      table_name: "card-table",
    })
  end
end

class Card
  attr_accessor :rank,
    :suit

  RANKS = {
    1 => "A",
    11 => "J",
    12 => "Q",
    13 => "K",
  }

  SUITS = {
    1 => "\u2663",
    2 => "\u2664",
    3 => "\u2665",
    4 => "\u2666",
  }

  def self.create_deck(deck: nil, game_id: "poker")
    deck ||= Card.ranks.flat_map do |rank|
      Card.suits.map do |suit|
        "#{rank}#{suit}"
      end
    end

    client.put_item({
      item: {
        deck: deck,
        game_id: game_id,
        item: "deck",
      },
      return_consumed_capacity: "TOTAL",
      table_name: "card-table",
    })
  end

  def initialize(rank:, suit:)
    @rank = rank
    @suit = suit
  end

  def self.ranks
    (1..13).to_a.map do |rank|
      stringify(rank: rank)
    end
  end

  def self.suits
    (1..4).to_a.map do |suit|
      stringify(suit: suit)
    end
  end

  def to_s
    "#{stringify(rank: rank)}#{stringify(suit: suit)}"
  end

  def self.stringify(rank: nil, suit: nil)
    if rank
      return RANKS[rank] || rank
    elsif suit
      return SUITS[suit]
    end
  end

  def stringify(rank: nil, suit: nil)
    self.class.stringify(rank: rank, suit: suit)
  end
end
