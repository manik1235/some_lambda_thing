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
