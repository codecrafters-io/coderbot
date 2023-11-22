class Steps::BaseStep
  extend ActiveModel::Callbacks

  define_model_callbacks :run

  attr_accessor :workflow
  attr_accessor :status

  around_run do |step, block|
    puts "#{workflow.log_prefix} - Running #{step.class.name.demodulize}".colorize(:blue)

    block.call

    if step.success?
      puts "#{workflow.log_prefix} - #{step.class.name.demodulize} success.".colorize(:green)
    else
      puts "#{workflow.log_prefix} - #{step.class.name.demodulize} failed.".colorize(:red)
    end
  end

  def initialize(workflow:)
    @workflow = workflow
    @status = "pending"
  end

  def failure!
    self.status = "failure"
  end

  def failure?
    status == "failure"
  end

  def run!
    run_callbacks :run do
      do_run!
    end
  end

  def success!
    self.status = "success"
  end

  def success?
    status == "success"
  end

  protected

  def do_run!
    raise NotImplementedError
  end
end
