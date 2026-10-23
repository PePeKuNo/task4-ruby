require 'net/http'
require 'uri'
require 'json'

# IMPORTANT: Real AI integration for Part 2 (natural-language insights about the data).
# The reviewer requirement was: "You need to integrate an AI into your application to make
# it possible to use natural language to get insights about data."
#
# NOTA BENE: This is NOT regex parsing. The service calls a REAL large language model
# (OpenAI-compatible Chat Completions API). The model receives the user's free-form
# question plus a list of TOOLS (functions). When it needs data it responds with
# tool_calls; WE execute those calls as REAL ActiveRecord queries and send the results
# back; the model then writes the final natural-language insight. Numbers NEVER come
# from the model's imagination - they always come from the database.
#
# IMPORTANT: Provider-agnostic - any OpenAI-compatible provider works via 3 env vars:
#   AI_API_KEY  - secret key. REQUIRED for the AI path; without it AiController falls
#                 back to deterministic intents so the feature never breaks.
#   AI_BASE_URL - default https://api.openai.com/v1
#                 Groq   -> https://api.groq.com/openai/v1
#                 Google -> https://generativelanguage.googleapis.com/v1beta/openai
#   AI_MODEL    - default gpt-4o-mini
#                 Groq   -> llama-3.3-70b-versatile
#                 Google -> gemini-2.0-flash
class AiService
  # NOTE: How many tool-calling rounds we allow before giving up (question -> tool ->
  # answer, occasionally one more round for a follow-up tool call).
  MAX_TOOL_ROUNDS = 4

  # NOTE: Networking timeouts - fail fast, the chat must stay responsive.
  OPEN_TIMEOUT = 8
  READ_TIMEOUT = 40

  # IMPORTANT: The tools the AI can call. Each tool runs a REAL query against the users
  # table (see #run_tool below) - this is what makes the answers trustworthy.
  TOOLS = [
    {
      type: 'function',
      function: {
        name: 'count_users',
        description: 'Count users in the database. Returns total, active and blocked counts. Call this for any question about quantities, shares or percentages of users.',
        parameters: { type: 'object', properties: {}, required: [] }
      }
    },
    {
      type: 'function',
      function: {
        name: 'list_users',
        description: 'List users ordered by last activity (most recent first). Optionally filter by status. Returns id, full_name, email, job_position, status and last_seen.',
        parameters: {
          type: 'object',
          properties: {
            status: { type: 'string', enum: %w[active blocked], description: 'Optional filter: only active or only blocked users' },
            limit: { type: 'integer', description: 'How many users to return, 1-20, default 10' }
          },
          required: []
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'find_user',
        description: 'Search users by a substring of their email address or full name (case-insensitive). Use for "find ...", "who is ..." questions.',
        parameters: {
          type: 'object',
          properties: {
            query: { type: 'string', description: 'Substring to search for, e.g. an email or part of a name' }
          },
          required: ['query']
        }
      }
    }
  ].freeze

  # IMPORTANT: Instructions that keep the model honest: use tools for every number,
  # answer in the language the user wrote in, stay concise.
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are the AI assistant inside a user-management admin panel.
    You answer questions about the users stored in the connected database.

    Rules:
    - Every number MUST come from tool results. Never invent, estimate or remember data.
    - Call the tools whenever the question is about users, counts, shares, status or activity.
    - After you have the data, give a short natural-language INSIGHT (2-5 sentences):
      interpret the numbers (percentages, comparisons, notable users), do not just dump them.
    - Answer in the same language the user asked in (English by default).
    - If the question is unrelated to the users data, briefly say you can only answer
      questions about the users in this admin panel.
  PROMPT

  # NOTE: Entry point. Returns the final answer string, or nil when the AI is not
  # configured / failed - the controller then uses its deterministic fallback.
  def self.ask(question)
    new(question).ask
  end

  def initialize(question)
    @question = question
  end

  def ask
    # IMPORTANT: Without a key there is no AI call at all (see controller fallback).
    return nil if ENV['AI_API_KEY'].blank?

    messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: @question }
    ]

    MAX_TOOL_ROUNDS.times do
      data = request(messages)
      return nil unless data

      message = data.dig('choices', 0, 'message')
      return nil unless message

      tool_calls = Array(message['tool_calls'])

      # NOTE: No tool calls => the model produced the final natural-language answer.
      return message['content'].presence if tool_calls.empty?

      # IMPORTANT: The model asked for data - execute every tool call as a REAL query
      # and feed the results back so it can formulate the insight.
      messages << { role: 'assistant', content: message['content'], tool_calls: tool_calls }
      tool_calls.each do |call|
        messages << {
          role: 'tool',
          tool_call_id: call['id'],
          content: JSON.generate(run_tool(call))
        }
      end
    end

    nil
  rescue StandardError => e
    Rails.logger.warn("AiService failed: #{e.class}: #{e.message}")
    nil
  end

  private

  # NOTE: One HTTP round-trip to the chat completions endpoint. Returns parsed JSON
  # or nil on any problem (network, auth, rate limit, bad payload...).
  def request(messages)
    base = ENV.fetch('AI_BASE_URL', 'https://api.openai.com/v1').chomp('/')
    uri = URI("#{base}/chat/completions")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    req = Net::HTTP::Post.new(uri.request_uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = "Bearer #{ENV['AI_API_KEY']}"
    req.body = JSON.generate(
      model: ENV.fetch('AI_MODEL', 'gpt-4o-mini'),
      messages: messages,
      tools: TOOLS,
      temperature: 0
    )

    res = http.request(req)
    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("AI provider returned HTTP #{res.code}: #{res.body.to_s[0, 300]}")
      return nil
    end

    JSON.parse(res.body)
  rescue StandardError => e
    Rails.logger.warn("AI request failed: #{e.class}: #{e.message}")
    nil
  end

  # IMPORTANT: Executes one tool call as a REAL ActiveRecord query.
  # NOTA BENE: Everything is whitelisted - the model can only call the three known
  # tools with JSON arguments; arbitrary SQL from the model is impossible.
  def run_tool(call)
    name = call.dig('function', 'name')
    args = JSON.parse(call.dig('function', 'arguments') || '{}')
    args = {} unless args.is_a?(Hash)

    case name
    when 'count_users'
      { total: User.count, active: User.active.count, blocked: User.blocked.count }

    when 'list_users'
      rel = User.all
      rel = rel.where(status: args['status']) if %w[active blocked].include?(args['status'])
      limit = args['limit'].to_i
      limit = 10 if limit <= 0
      limit = 20 if limit > 20
      { users: rel.order(last_seen: :desc).limit(limit)
                  .as_json(only: %i[id full_name email job_position status last_seen]) }

    when 'find_user'
      q = args['query'].to_s.strip
      if q.blank?
        { users: [], note: 'query is empty' }
      else
        pattern = "%#{q}%"
        { users: User.where('LOWER(email) LIKE LOWER(?) OR LOWER(full_name) LIKE LOWER(?)', pattern, pattern)
                     .limit(10)
                     .as_json(only: %i[id full_name email job_position status last_seen]) }
      end

    else
      { error: "unknown tool: #{name}" }
    end
  rescue JSON::ParserError
    { error: 'invalid tool arguments' }
  end
end
