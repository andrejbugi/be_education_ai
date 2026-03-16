module ChatSerialization
  private

  def serialize_conversation(conversation)
    participant = conversation.participant_for(current_user)

    {
      id: conversation.id,
      school_id: conversation.school_id,
      conversation_type: conversation.conversation_type,
      active: conversation.active,
      last_message_at: conversation.last_message_at,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at,
      participants: conversation.active_conversation_participants.map { |conversation_participant| serialize_conversation_participant(conversation_participant) },
      current_user_state: participant && {
        joined_at: participant.joined_at,
        last_read_message_id: participant.last_read_message_id,
        last_read_at: participant.last_read_at,
        active: participant.active
      },
      unread_count: unread_count_for(conversation, participant),
      last_message: conversation.last_message ? serialize_message(conversation.last_message) : nil
    }
  end

  def serialize_conversation_participant(participant)
    user = participant.user
    presence = user.user_presence_status

    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      roles: user.roles.map(&:name),
      joined_at: participant.joined_at,
      last_read_message_id: participant.last_read_message_id,
      last_read_at: participant.last_read_at,
      presence_status: presence&.status || "offline",
      last_seen_at: presence&.last_seen_at
    }
  end

  def serialize_message(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      sender_name: message.sender.full_name,
      body: message.body,
      message_type: message.message_type,
      status: message.status,
      reply_to_message_id: message.reply_to_message_id,
      edited_at: message.edited_at,
      deleted_at: message.deleted_at,
      created_at: message.created_at,
      updated_at: message.updated_at,
      attachments: message.message_attachments.map { |attachment| serialize_message_attachment(attachment) },
      reactions: message.message_reactions.map { |reaction| serialize_message_reaction(reaction) },
      delivered_user_ids: message.message_deliveries.map(&:user_id).sort,
      read_user_ids: message.message_reads.map(&:user_id).sort
    }
  end

  def serialize_message_attachment(attachment)
    {
      id: attachment.id,
      attachment_type: attachment.attachment_type,
      file_name: attachment.file_name,
      content_type: attachment.content_type,
      file_size: attachment.file_size,
      storage_key: attachment.storage_key,
      file_url: attached_message_file_url(attachment) || attachment.file_url,
      created_at: attachment.created_at
    }
  end

  def serialize_message_reaction(reaction)
    {
      id: reaction.id,
      user_id: reaction.user_id,
      reaction: reaction.reaction,
      created_at: reaction.created_at
    }
  end

  def attached_message_file_url(attachment)
    return nil unless attachment.file.attached?

    rails_blob_url(attachment.file, host: request.base_url)
  end

  def unread_count_for(conversation, participant)
    scope = conversation.messages.visible.where.not(sender_id: current_user.id)
    scope = scope.where("messages.id > ?", participant.last_read_message_id) if participant&.last_read_message_id.present?
    scope.count
  end
end
