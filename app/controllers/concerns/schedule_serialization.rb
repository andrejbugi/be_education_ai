module ScheduleSerialization
  private

  def serialize_schedule_slot(slot)
    {
      id: slot.id,
      day_of_week: slot.day_of_week,
      period_number: slot.period_number,
      subject_id: slot.subject_id,
      teacher_id: slot.teacher_id,
      room_name: slot.room_name,
      room_label: slot.room_label,
      display_room_name: slot.effective_room_name,
      display_room_label: slot.effective_room_label,
      display_room_source: slot.effective_room_source,
      subject: {
        id: slot.subject.id,
        name: slot.subject.name,
        code: slot.subject.code,
        room_name: slot.subject.room_name,
        room_label: slot.subject.room_label
      },
      teacher: {
        id: slot.teacher.id,
        full_name: slot.teacher.full_name,
        room_name: slot.teacher.teacher_profile&.room_name,
        room_label: slot.teacher.teacher_profile&.room_label
      },
      classroom: {
        id: slot.classroom.id,
        name: slot.classroom.name,
        room_name: slot.classroom.room_name,
        room_label: slot.classroom.room_label
      }
    }
  end
end
