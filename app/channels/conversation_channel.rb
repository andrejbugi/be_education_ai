class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])
    reject unless subscribable?(conversation)

    stream_for conversation
  end

  private

  def subscribable?(conversation)
    return false unless conversation&.active?

    conversation.conversation_participants.active.exists?(user_id: current_user.id)
  end
end
