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
