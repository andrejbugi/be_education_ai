module QuizGames
  class LearningGamesAvailabilityService
    def initialize(school:)
      @school = school
    end

    def call
      window = FeatureWindow.new(school: school)

      {
        available_now: window.available_now?,
        available_from: window.available_from,
        available_until: window.available_until,
        games: resolved_configs.map do |config|
          {
            game_key: config.game_key,
            title: config.title,
            description: config.description,
            icon_key: config.icon_key,
            is_enabled: config.is_enabled,
            position: config.position,
            metadata: config.metadata
          }
        end
      }
    end

    private

    attr_reader :school

    def resolved_configs
      return LearningGameConfig.where(school_id: nil, is_enabled: true).order(:position, :id) unless school

      configs = LearningGameConfig.where(is_enabled: true, school_id: [nil, school.id])
                                  .order(Arel.sql("CASE WHEN school_id = #{school.id} THEN 0 ELSE 1 END"), :position, :id)

      selected = {}
      configs.each do |config|
        selected[config.game_key] ||= config
      end

      selected.values.sort_by { |config| [config.position, config.game_key] }
    end
  end
end
