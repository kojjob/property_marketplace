module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!
      before_action :authenticate_user_from_token!

      respond_to :json

      private

      def authenticate_user_from_token!
        token = request.headers["Authorization"]&.split(" ")&.last
        return unless token

        # For simplicity, use user ID as token in development/test
        if Rails.env.development? || Rails.env.test?
          @current_user = User.find_by(id: token.to_i)
        else
          begin
            payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
            @current_user = User.find(payload["user_id"])
          rescue JWT::DecodeError, ActiveRecord::RecordNotFound
            @current_user = nil
          end
        end
      end

      def current_user
        @current_user
      end

      def authenticate_user!
        render json: { error: "Not authenticated" }, status: :unauthorized unless current_user
      end
    end
  end
end
