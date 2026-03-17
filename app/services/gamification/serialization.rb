module Gamification
  module Serialization
    module_function

    def profile_payload(profile, badges_limit: 5)
      return nil unless profile

      {
        total_xp: profile.total_xp,
        current_level: profile.current_level,
        current_streak: profile.current_streak,
        longest_streak: profile.longest_streak,
        current_level_start_xp: profile.current_level_start_xp,
        next_level_xp: profile.next_level_xp,
        xp_to_next_level: profile.xp_to_next_level,
        level_progress_percent: profile.level_progress_percent,
        completed_assignments_count: profile.completed_assignments_count,
        graded_assignments_count: profile.graded_assignments_count,
        badges_count: profile.badges_count,
        average_grade: profile.average_grade,
        attendance_rate: profile.attendance_rate,
        last_active_on: profile.last_active_on,
        last_synced_at: profile.last_synced_at,
        breakdown: profile.metadata.fetch("xp_breakdown", {}),
        badges: serialize_badges(profile.student_badges.order(awarded_at: :desc, id: :desc).limit(badges_limit))
      }
    end

    def serialize_badges(badges)
      badges.map do |badge|
        {
          id: badge.id,
          code: badge.code,
          name: badge.name,
          description: badge.description,
          awarded_at: badge.awarded_at,
          metadata: badge.metadata
        }
      end
    end
  end
end
