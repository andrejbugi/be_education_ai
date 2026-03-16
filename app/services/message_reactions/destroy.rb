module MessageReactions
  class Destroy
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize(message:, user:, reaction:)
      @message = message
      @user = user
      @reaction = reaction
    end

    def call
      reaction_record = message.message_reactions.find_by(user: user, reaction: reaction)
      return Result.new(success?: false, errors: ["Reaction not found"]) unless reaction_record

      reaction_record.destroy!
      Result.new(success?: true, errors: [])
    end

    private

    attr_reader :message, :user, :reaction
  end
end
