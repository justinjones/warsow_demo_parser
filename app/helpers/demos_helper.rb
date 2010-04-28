module Merb
  module DemosHelper
    # helpers defined here available to all views.
    def map_image(map = nil)
      map ? image_tag("maps/#{map}_thumb.jpg") : image_tag('maps/unknown.jpg')
    end

    # Reports the approximate distance in time between two Time or Date objects or integers as seconds.
    # Set <tt>include_seconds</tt> to true if you want more detailed approximations when distance < 1 min, 29 secs
    # Distances are reported base on the following table:
    #
    # 0 <-> 29 secs                                                             # => less than a minute
    # 30 secs <-> 1 min, 29 secs                                                # => 1 minute
    # 1 min, 30 secs <-> 44 mins, 29 secs                                       # => [2..44] minutes
    # 44 mins, 30 secs <-> 89 mins, 29 secs                                     # => about 1 hour
    # 89 mins, 29 secs <-> 23 hrs, 59 mins, 29 secs                             # => about [2..24] hours
    # 23 hrs, 59 mins, 29 secs <-> 47 hrs, 59 mins, 29 secs                     # => 1 day
    # 47 hrs, 59 mins, 29 secs <-> 29 days, 23 hrs, 59 mins, 29 secs            # => [2..29] days
    # 29 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs   # => about 1 month
    # 59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 31 secs                  # => [2..12] months
    # 1 yr minus 30 secs <-> 2 yrs minus 31 secs                                # => about 1 year
    # 2 yrs minus 30 secs <-> max time or date                                  # => over [2..X] years
    #
    # With include_seconds = true and the difference < 1 minute 29 seconds
    # 0-4   secs      # => less than 5 seconds
    # 5-9   secs      # => less than 10 seconds
    # 10-19 secs      # => less than 20 seconds
    # 20-39 secs      # => half a minute
    # 40-59 secs      # => less than a minute
    # 60-89 secs      # => 1 minute
    #
    # Examples:
    #
    #   from_time = Time.now
    #   distance_of_time_in_words(from_time, from_time + 50.minutes) # => about 1 hour
    #   distance_of_time_in_words(from_time, from_time + 15.seconds) # => less than a minute
    #   distance_of_time_in_words(from_time, from_time + 15.seconds, true) # => less than 20 seconds
    #
    # Note: Rails calculates one year as 365.25 days.
    def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      distance_in_minutes = (((to_time - from_time).abs)/60).round
      distance_in_seconds = ((to_time - from_time).abs).round

      case distance_in_minutes
        when 0..1
          return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
          case distance_in_seconds
            when 0..4   then 'less than 5 seconds'
            when 5..9   then 'less than 10 seconds'
            when 10..19 then 'less than 20 seconds'
            when 20..39 then 'half a minute'
            when 40..59 then 'less than a minute'
            else             '1 minute'
          end
                        
        when 2..44           then "#{distance_in_minutes} minutes"
        when 45..89          then 'about 1 hour'
        when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
        when 1440..2879      then '1 day'
        when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
        when 43200..86399    then 'about 1 month'
        when 86400..525959   then "#{(distance_in_minutes / 43200).round} months"
        when 525960..1051919 then 'about 1 year'
        else                      "over #{(distance_in_minutes / 525960).round} years"
      end
    end

    # Like distance_of_time_in_words, but where <tt>to_time</tt> is fixed to <tt>Time.now</tt>.
    def time_ago_in_words(from_time, include_seconds = false)
      distance_of_time_in_words(from_time, Time.now, include_seconds)
    end
  end
end