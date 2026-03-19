module QuizGames
  class FeatureWindow
    DEFAULT_TIMEZONE = "Europe/Skopje"
    DEFAULT_AVAILABLE_FROM = "18:00"
    DEFAULT_AVAILABLE_UNTIL = "20:00"

    def initialize(school:)
      @school = school
    end

    def current_date
      local_now.to_date
    end

    def available_now?
      return false unless within_window?(current_minute_of_day, available_from, available_until)

      blocked_windows.none? do |window|
        within_window?(current_minute_of_day, window.fetch("start_time"), window.fetch("end_time"))
      end
    end

    def available_from
      @available_from ||= normalize_time(setting_value("available_from")) || DEFAULT_AVAILABLE_FROM
    end

    def available_until
      @available_until ||= normalize_time(setting_value("available_until")) || DEFAULT_AVAILABLE_UNTIL
    end

    def timezone
      @timezone ||= begin
        zone_name = setting_value("timezone").presence || DEFAULT_TIMEZONE
        ActiveSupport::TimeZone[zone_name]&.tzinfo&.name || DEFAULT_TIMEZONE
      end
    end

    def blocked_windows
      @blocked_windows ||= Array(setting_value("blocked_windows")).filter_map do |window|
        next unless window.is_a?(Hash)

        start_time = normalize_time(window["start_time"] || window[:start_time] || window["available_from"])
        end_time = normalize_time(window["end_time"] || window[:end_time] || window["available_until"])
        next if start_time.blank? || end_time.blank?

        {
          "start_time" => start_time,
          "end_time" => end_time
        }
      end
    end

    private

    attr_reader :school

    def local_now
      @local_now ||= Time.current.in_time_zone(timezone)
    end

    def current_minute_of_day
      (local_now.hour * 60) + local_now.min
    end

    def setting_value(key)
      quiz_game_settings[key] || quiz_game_settings[key.to_sym]
    end

    def quiz_game_settings
      @quiz_game_settings ||= begin
        raw_settings = school&.settings
        settings_hash = raw_settings.is_a?(Hash) ? raw_settings : {}
        quiz_settings = settings_hash["quiz_games"] || settings_hash[:quiz_games] || {}
        quiz_settings.is_a?(Hash) ? quiz_settings : {}
      end
    end

    def normalize_time(value)
      match = value.to_s.match(/\A(\d{1,2}):(\d{2})\z/)
      return nil unless match

      hour = match[1].to_i
      minute = match[2].to_i
      return nil unless hour.between?(0, 23) && minute.between?(0, 59)

      format("%02d:%02d", hour, minute)
    end

    def within_window?(minute_of_day, start_time, end_time)
      start_minute = time_to_minutes(start_time)
      end_minute = time_to_minutes(end_time)
      return false if start_minute.nil? || end_minute.nil? || start_minute == end_minute

      if start_minute < end_minute
        minute_of_day >= start_minute && minute_of_day < end_minute
      else
        minute_of_day >= start_minute || minute_of_day < end_minute
      end
    end

    def time_to_minutes(value)
      time = normalize_time(value)
      return nil unless time

      hours, minutes = time.split(":").map(&:to_i)
      (hours * 60) + minutes
    end
  end
end
