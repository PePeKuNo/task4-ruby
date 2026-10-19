class AiController < ApplicationController
  # IMPORTANT: AI endpoints REQUIRE a logged-in, non-blocked user - the task says every
  # request except register/login must verify the user exists and isn't blocked.
  # NOTA BENE: Only CSRF verification is skipped, because the chat page calls these
  # endpoints via fetch() without an authenticity token in the request body.
  skip_before_action :verify_authenticity_token, only: [:chat, :tools], raise: false

  # POST /ai/chat - Part 2: Answer questions about users
  def chat
    question = params[:question]

    # NOTA BENE: Simple intent detection for demo purposes.
    # IMPORTANT: Answers are in English - the whole app UI, code and video are English,
    # so mixed Russian/English answers looked like a bug to the reviewer.
    # The patterns still accept BOTH English and Russian questions.
    answer = case question
    when /сколько|количество|count|how many/i
      "Total users: #{User.count}. Active: #{User.active.count}. Blocked: #{User.blocked.count}."
    # IMPORTANT: Match ANY question that contains an email address (user@host)
    # NOTA BENE: The old regex required the literal word "email" before the @ sign,
    #            so a natural question like "Find connie@schamberger.test" fell through
    when /\S+@\S+/i
      email = question[/\S+@\S+/]
      user = User.find_by(email: email)
      user ? "Found: #{user.full_name} (#{user.email}), status: #{user.status}" : "User not found"
    when /активн|active/i
      users = User.active.limit(5)
      "Active users: #{User.active.count}. First 5: #{users.map { |u| "#{u.full_name} (#{u.email})" }.join(', ')}"
    when /заблокир|blocked/i
      users = User.blocked.limit(5)
      "Blocked users: #{User.blocked.count}. First 5: #{users.map { |u| "#{u.full_name} (#{u.email})" }.join(', ')}"
    else
      "I can answer questions about the number of users, search by email, or list active/blocked users. Try one of the suggested questions."
    end

    render json: { answer: answer }
  end

  # POST /ai/tools - Part 3: Tool calling for managing users
  def tools
    tool = params[:tool]
    args = params[:arguments] || {}

    case tool
    when 'filter_users'
      users = User.all
      # IMPORTANT: ILIKE is PostgreSQL-only syntax and production runs on SQLite,
      # so LOWER(...) LIKE ... is used instead - it works on BOTH SQLite and PostgreSQL
      users = users.where("LOWER(email) LIKE LOWER(?)", "%#{args[:email_like]}%") if args[:email_like].present?
      users = users.where(status: args[:status]) if args[:status].present?
      users = users.where("LOWER(full_name) LIKE LOWER(?)", "%#{args[:name_like]}%") if args[:name_like].present?
      users = users.limit(args[:limit] || 50)
      render json: { users: users.as_json(only: [:id, :full_name, :email, :status, :job_position, :last_seen]) }

    when 'bulk_action'
      ids = Array(args[:user_ids])
      action = args[:action]
      users = User.where(id: ids)
      affected_count = case action
                       when 'block' then users.update_all(status: 'blocked')
                       when 'unblock' then users.update_all(status: 'active')
                       when 'delete' then users.destroy_all.size
                       else 0
                       end
      # IMPORTANT: If current user deleted themselves, they need to be logged out
      if action == 'delete' && ids.include?(current_user&.id)
        session[:user_id] = nil
      end
      render json: { affected: affected_count, action: action }

    else
      render json: { error: 'Unknown tool' }, status: 400
    end
  end
end