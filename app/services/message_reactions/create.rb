module MessageReactions
  class Create
    Result = Struct.new(:success?, :reaction, :errors, keyword_init: true)

    def initialize(message:, user:, reaction:)
      @message = message
      @user = user
      @reaction = reaction
    end

    def call
      reaction_record = message.message_reactions.find_or_initialize_by(user: user, reaction: reaction)
      reaction_record.save!

      Result.new(success?: true, reaction: reaction_record, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, reaction: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :message, :user, :reaction
  end
end
