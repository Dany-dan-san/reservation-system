
class RoomsController < ApplicationController
  def index
    @rooms = Room.order(:name)
    @room = Room.new
  end

  def show
    @room = Room.find(params[:id])
    @reservations = @room.reservations.order(:start_date)
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)

    if @room.save
      redirect_to rooms_path, notice: "Room created successfully."
    else
      @rooms = Room.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def room_params
    params.require(:room).permit(:name, :capacity)
  end
end
