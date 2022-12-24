class Api::V1::WebhooksController < ApplicationController
  def get_list_id
    board = Trello::Board.find(ENV['TRELLO_BOARD_ID'])

    list = board.lists[0]
    list.id
  end

  def show
    render status: 200
  end

  def create
    raw_post = request.raw_post
    data_parsed = JSON.parse(raw_post)
    event = data_parsed['action'] && data_parsed['action']['type']
    parsedCard = data_parsed['action'] && data_parsed['action']['data'] && data_parsed['action']['data']['card']
    case event
    when 'createCard'
      card = Card.where(remote_trello_card_id: parsedCard['id']).first_or_initialize(remote_trello_card_id: parsedCard['id'], name: parsedCard['name'], list_id: get_list_id)
      if card.save
        render json: @card, status: 201
      else
        render json: { error: 'check attributes again', status: 400 }, status: 400
      end

    when 'updateCard'
      card = Card.find_by(remote_trello_card_id: parsedCard['id'])

      if card.present?

        card['name'] = parsedCard['name']
        card['desc'] = parsedCard['desc'] if parsedCard['desc']
        card['due'] = parsedCard['due'] if parsedCard['due']

        if card.save
          render json: @card, status: 200
        else
          render json: { error: 'check attributes again', status: 400 }, status: 400
        end
      end

    when 'deleteCard'
      card = Card.find_by(remote_trello_card_id: parsedCard['id'])
      card.destroy
    else
      p 'uhandled event'
    end
  end
end
