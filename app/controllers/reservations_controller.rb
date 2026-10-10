class ReservationsController < ApplicationController
  def index
    load_index_data
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def new
    @reservation = Reservation.new(room_id: params[:room_id])
    @rooms = Room.order(:name)
  end

  def create
    @new_reservation = Reservation.new(reservation_params)

    if @new_reservation.save
      redirect_to reservations_path, notice: "Reservation created successfully."
    else
      load_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @reservation = Reservation.find(params[:id])
    @rooms = Room.order(:name)
  end

  def update
    @reservation = Reservation.find(params[:id])

    if @reservation.update(reservation_params)
      redirect_to reservations_path, notice: "Reservation updated successfully."
    else
      @editing_reservation = @reservation
      load_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy!

    redirect_to reservations_path,
                notice: "Reservation deleted successfully.",
                status: :see_other
  end

  private

  def load_index_data
    @reservations = Reservation.includes(:room).order(:start_date)
    @rooms = Room.order(:name)
    @new_reservation ||= Reservation.new
  end

  def reservation_params
    params.require(:reservation).permit(:room_id, :start_date, :end_date)
  end
end
