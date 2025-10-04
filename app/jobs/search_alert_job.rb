class SearchAlertJob < ApplicationJob
  queue_as :default

  def perform
    SavedSearch.active.due_for_alert.find_each do |saved_search|
      new_properties = saved_search.new_properties_since_last_run

      if new_properties.any?
        SearchAlertMailer.new_properties_alert(saved_search, new_properties).deliver_later
      end

      saved_search.update(last_run_at: Time.current)
    end
  end
end
