class ApplicationService
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  def failure(error, data = {})
    ServiceResult.new(success: false, error: error, data: data)
  end
end

class ServiceResult
  attr_reader :data, :error

  def initialize(success:, data: {}, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def to_h
    {
      success: @success,
      data: @data,
      error: @error
    }.compact
  end
end
