class SavedSearchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_saved_search, only: [ :show, :edit, :update, :destroy, :execute ]

  def index
    @saved_searches = current_user.saved_searches.order(created_at: :desc)
  end

  def show
    @search_service = PropertySearchService.new(@saved_search.criteria)
    result = @search_service.call

    if result.success?
      @properties = result.data[:properties]
      @pagination = result.data[:pagination]
    else
      @properties = Property.none
      @pagination = {}
      flash.now[:alert] = "Search failed: #{result.error}"
    end
  end

  def new
    @saved_search = current_user.saved_searches.build
  end

  def create
    @saved_search = current_user.saved_searches.build(saved_search_params)

    if @saved_search.save
      redirect_to saved_searches_path, notice: "Search saved successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @saved_search.update(saved_search_params)
      redirect_to saved_searches_path, notice: "Search updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @saved_search.destroy
    redirect_to saved_searches_path, notice: "Search deleted successfully."
  end

  def execute
    result = @saved_search.execute_search

    if result.any?
      redirect_to saved_search_path(@saved_search), notice: "Found #{result.count} properties matching your saved search."
    else
      redirect_to saved_search_path(@saved_search), notice: "No new properties found matching your saved search."
    end
  end

  private

  def set_saved_search
    @saved_search = current_user.saved_searches.find(params[:id])
  end

  def saved_search_params
    params.require(:saved_search).permit(:name, :frequency, criteria: {})
  end
end
