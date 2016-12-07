module Api
  class BookingsController < ApiController
    def create
      booking = Booking.create(location_id: params[:location][:id], status: Booking::AVAILABLE)
      drivers = Driver.where("status = ? ", Driver::ACTIVE)
      driver_list = []
      drivers.each do |driver|
        driver_list.push("driver_#{driver.id}")
      end
      Pusher.trigger(driver_list, 'ride', {
        start_location: booking.location.pickup_address,
        destination: booking.location.dropoff_address,
        booking_id: booking.id
      })
    end

    def accept
      booking = Booking.find_by(id: params[:booking][:id])
      driver = User.find_by(token: params[:user][:token]).driver
      if booking && driver
        if booking.status != Booking::CLOSED
          booking.status = Booking::CLOSED
          booking.driver_id = driver.id
          driver.status = Driver::BUSY
          booking.save && driver.save
          render json: {message: "Proceed to pickup location"}
        else
          render json: {message: "Another driver is on the way"}
        end
      end
    end

    def start_ride
      driver = User.find_by(token: params[:user][:token]).driver
      driver.status = Driver::TRANSIT
      driver.save
    end

    def end_ride
      driver = User.find_by(token: params[:user][:token]).driver
      driver.status = Driver::ACTIVE
      driver.save
    end
  end
end
