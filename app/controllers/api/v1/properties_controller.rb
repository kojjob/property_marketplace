module Api
  module V1
    class PropertiesController < BaseController
      before_action :authenticate_user!, only: [ :create, :update, :destroy ]
      before_action :set_property, only: [ :show, :update, :destroy ]
      before_action :ensure_owner, only: [ :update, :destroy ]

      def index
        properties = Property.includes(:user, :property_images)
        properties = apply_filters(properties)
        properties = properties.order(created_at: :desc)

        render json: {
          properties: properties.map { |p| property_json(p) },
          total_count: properties.count,
          current_user_id: current_user&.id
        }
      end

      def show
        render json: property_json(@property, detailed: true)
      end

      def create
        @property = current_user.properties.build(property_params)

        if @property.save
          render json: property_json(@property), status: :created
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @property.update(property_params)
          render json: property_json(@property)
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @property.destroy
        head :no_content
      end

      private

      def set_property
        @property = Property.find(params[:id])
      end

      def ensure_owner
        render json: { error: "Not authorized" }, status: :forbidden unless @property.user == current_user
      end

      def apply_filters(scope)
        scope = scope.where(city: params[:city]) if params[:city].present?
        scope = scope.where(property_type: params[:property_type]) if params[:property_type].present?
        scope = scope.where("price >= ?", params[:min_price]) if params[:min_price].present?
        scope = scope.where("price <= ?", params[:max_price]) if params[:max_price].present?
        scope
      end

      def property_params
        params.require(:property).permit(
          :title, :description, :price, :property_type, :bedrooms, :bathrooms,
          :square_feet, :address, :city, :state, :postal_code, :country
        )
      end

      def property_json(property, detailed: false)
        base = {
          id: property.id,
          title: property.title,
          description: property.description,
          price: property.price,
          property_type: property.property_type,
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          square_feet: property.square_feet,
          address: property.address,
          city: property.city,
          state: property.region,
          postal_code: property.postal_code,
          country: property.country,
          created_at: property.created_at,
          updated_at: property.updated_at
        }

        if detailed
          base.merge(
            user_id: property.user_id,
            images: property.property_images.map { |img| { id: img.id, image_url: img.image_url, caption: img.caption } }
          )
        else
          base
        end
      end
    end
  end
end
