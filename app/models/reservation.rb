class Reservation < ApplicationRecord

  # =========================================================================
  # 0. ASSIGNING "RESERVATION" MODEL TO "ROOM" MODEL
  # =========================================================================

  belongs_to :room

  # =========================================================================
  # 1. MANDATORY CLASS REQUIREMENTS THAT MUST BE CHECKED
  # =========================================================================

  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_date_after_start_date
  validate :room_capacity_not_exceeded

  private # Section below becomes "Private", internal class use only. 

  # =========================================================================
  # 2. FUNCTION A: CHECKING NO MISSING DATA + END > START CONDITIONS
  # =========================================================================

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date <= start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  # =========================================================================
  # 3. FUNCTION B: CHECKING FOR "NO-OVERLAP" POLICY GIVEN MAX. CAP.
  # =========================================================================

  def room_capacity_not_exceeded

    # A. START REQUIREMENTS
    # =========================================================================
    return if room.blank? || start_date.blank? || end_date.blank?
    return if end_date <= start_date
    return if room.capacity.blank? || room.capacity <= 0

    # B. OVERLAP DETECTION: 
    # =========================================================================
    # Condition: start_time_A < end_B and start_B < end_time_A
    # note. Collection of overlapping reservations relative to new reservation.

    overlapping = room.reservations
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .where.not(id: id)

    # C. EVENT GENERATION: 
    # =========================================================================

    # For each conflicting event (loop), calculates:
    # - EFFECT. START: When overlap window starts.
    # - EFFECT. END: When overlap window ends. 
    
    # For each conflicting event, saves in EVENTS[]:
    # [EFFECT. START OR EFFECT. END] AND [1 OR -1]
  
    events = []

    overlapping.each do |reservation|
      effective_start = [reservation.start_date, start_date].max
      effective_end = [reservation.end_date, end_date].min

      events << [effective_start, 1]
      events << [effective_end, -1]
    end

    # D. ADDING NEW RESERVATION TO EVENTS[]
    # =========================================================================

    events << [start_date, 1]
    events << [end_date, -1]

    # E. CHRONOLOGICAL SORTING:
    # =========================================================================

    # Events with values TIME and CHANGE sorted:

    # - 1st by TIME,
    # - 2nd by CHANGE if TIME == TIME

    events.sort_by! { |time, change| [time, change] }

    # F. ACTIVE RESERVATION TRACKING
    # =========================================================================
    
    # Calculates the number of concurrently active
    # reservations given booked reservations and new reservation. 

    active_reservations = 0

    events.each do |time, change|
      active_reservations += change

      # If the active reservations exceed room capacity,
      # the new reservation is rejected and displays a 
      # custom error message. 

      if active_reservations > room.capacity
        errors.add(:base, "Room capacity would be exceeded")
        break
      end
    end
  end
end