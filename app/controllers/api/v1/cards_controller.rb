class Api::V1::CardsController < ApplicationController
  # TODO: use Action Cable to send data to the client app via websocket
  def index
    @cards = Card.order('created_at DESC').all
    render json: @cards, status: 200
  end

  def new
    @card = Card.new
  end

  def get_list_id
    board = Trello::Board.find(ENV['TRELLO_BOARD_ID'])

    list = board.lists[0]

    if list.present?
      list.id
    else
      list = Trello::List.create board_id: board.id, name: 'Main list'
      list.id
    end
  end

  def create
    trello_card = Trello::Card.create(name: card_params[:name], desc: card_params[:desc], due: card_params[:due],
                                      idList: get_list_id)
    @card = Card.where(remote_trello_card_id: trello_card.id).first_or_initialize(remote_trello_card_id: trello_card.id, name: card_params[:name], desc: card_params[:desc],
                                     due: card_params[:due], list_id: get_list_id)

    if @card.save
      render json: @card, status: :created
    else
      render json: { error: 'check params again', status: 400 }, status: 400
    end
  end

  private

  def card_params
    params.require(:card).permit(:name, :desc, :due)
  end
end
