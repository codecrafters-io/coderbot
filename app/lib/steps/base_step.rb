class Steps::BaseStep
  attr_accessor :workflow

  def initialize(workflow:)
    @workflow = workflow
  end

  def run!
    raise NotImplementedError
  end
end
