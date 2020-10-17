# Example request
# https://8x16jr2jii.execute-api.us-east-1.amazonaws.com/dev/some-lambda-thing?action=drawCard&rank=5&suit=3
# Returns
# card: "5♥"
# https://8x16jr2jii.execute-api.us-east-1.amazonaws.com/dev/some-lambda-thing?action=dealHands&number=5

require 'aws-sdk'
require 'json'
require_relative './card'
require_relative './game'

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

def mock_http_for_lambda(action: "dealHands", number: "5")
  # e.g. lambda_handler(event: { "queryStringParameters" => { "action" => "dealHands", "number" => "5" } }, context: {})
  lambda_handler(event: { "queryStringParameters" => { "action" => action, "number" => number } }, context: {})
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

  #Card.create_deck

  #context_items = methods.map { |m| { m => context.send(m) } }

  { statusCode: 200, body: JSON.generate(response(query)) } #.merge({ event: event, context: context_items })) }
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
