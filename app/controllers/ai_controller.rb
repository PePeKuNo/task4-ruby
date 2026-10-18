class AiController < ApplicationController
  # IMPORTANT: Skip authentication for AI endpoints (for testing)
  # NOTA BENE: In production, you would want to protect these endpoints
  skip_before_action :require_login, only: [:chat, :tools], raise: false
  skip_before_action :check_user_status, only: [:chat, :tools], raise: false
  skip_before_action :verify_authenticity_token, only: [:chat, :tools], raise: false

  # POST /ai/chat - Part 2: Answer questions about users
  def chat
    question = params[:question]

    # NOTA BENE: Simple intent detection for demo purposes
    answer = case question
    when /сколько|количество|count|how many/i
      "Всего пользователей: #{User.count}. Активных: #{User.active.count}. Заблокированных: #{User.blocked.count}."
    when /email.*@/i
      email = question[/\S+@\S+/]
      user = User.find_by(email: email)
      user ? "Найден: #{user.full_name} (#{user.email}), статус: #{user.status}" : "Пользователь не найден"
    when /активн|active/i
      users = User.active.limit(5)
      "Активных пользователей: #{User.active.count}. Первые 5: #{users.map { |u| "#{u.full_name} (#{u.email})" }.join(', ')}"
    when /заблокир|blocked/i
      users = User.blocked.limit(5)
      "Заблокированных пользователей: #{User.blocked.count}. Первые 5: #{users.map { |u| "#{u.full_name} (#{u.email})" }.join(', ')}"
    else
      "Я могу ответить на вопросы о количестве пользователей, поиске по email, активных/заблокированных пользователях."
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
      users = users.where("email ILIKE ?", "%#{args[:email_like]}%") if args[:email_like].present?
      users = users.where(status: args[:status]) if args[:status].present?
      users = users.where("full_name ILIKE ?", "%#{args[:name_like]}%") if args[:name_like].present?
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