# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# Sample data for the Booking Platform

date = Date.current + 2.days

def booking_time(date, hour, minute = 0)
  Time.zone.local(date.year, date.month, date.day, hour, minute)
end

# Create sample rooms
rooms = {
  small: Room.find_or_create_by!(name: "Room A") do |room|
    room.capacity = 1
  end,

  team: Room.find_or_create_by!(name: "Room B") do |room|
    room.capacity = 2
  end,

  hall: Room.find_or_create_by!(name: "Room C") do |room|
    room.capacity = 3
  end
}

# Sample reservations: [room, start hour, end hour]
bookings = [
  [rooms[:small], 10, 11],
  [rooms[:team], 9, 11],
  [rooms[:team], 10, 12],
  [rooms[:hall], 14, 16],
  [rooms[:hall], 15, 17]
]

bookings.each do |room, start_hour, end_hour|
  Reservation.find_or_create_by!(
    room: room,
    start_date: booking_time(date, start_hour),
    end_date: booking_time(date, end_hour)
  )
end

puts "Seed data ready!"
puts "Rooms: #{Room.count}"
puts "Reservations: #{Reservation.count}"
puts "Sample booking date: #{date}"
