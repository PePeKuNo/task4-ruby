class ChatController < ApplicationController
  # NOTE: All actions require authentication (handled by ApplicationController)

  # GET /chat - Chat area (for parts 2 and 3)
  def index
    # NOTE: Get recent messages with user info for display
    @chat_messages = ChatMessage.includes(:user).chronological.limit(100)
    @chat_message = ChatMessage.new
  end

  # POST /chat - Send a new message
  def create
    @chat_message = current_user.chat_messages.build(chat_message_params)

    if @chat_message.save
      # NOTE: For Turbo Streams (real-time updates)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path, notice: 'Message sent.' }
      end
    else
      @chat_messages = ChatMessage.includes(:user).chronological.limit(100)
      respond_to do |format|
        # IMPORTANT: status 422 tells Turbo this is an error response (Rails convention)
        format.turbo_stream { render turbo_stream: turbo_stream.replace('chat_form', partial: 'chat/form', locals: { chat_message: @chat_message }), status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  private

  def chat_message_params
    params.require(:chat_message).permit(:content)
  end
end