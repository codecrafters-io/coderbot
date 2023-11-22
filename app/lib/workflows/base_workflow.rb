class Workflows::BaseWorkflow
  attr_accessor :status

  def initialize
    @status = "pending"
  end

  def failure!
    self.status = "failure"
  end

  def failure?
    status == "failure"
  end

  def run!
    raise NotImplementedError
  end

  def success!
    self.status = "success"
  end

  def success?
    status == "success"
  end
end
