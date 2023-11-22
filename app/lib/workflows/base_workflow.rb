class Workflows::BaseWorkflow
  extend ActiveModel::Callbacks

  define_model_callbacks :run

  attr_accessor :status
  attr_accessor :identifier

  around_run do |base_workflow, block|
    puts "#{base_workflow.log_prefix} Running workflow...".colorize(:blue)

    block.call

    if base_workflow.success?
      puts "#{base_workflow.log_prefix} Workflow success.".colorize(:green)
    else
      puts "#{base_workflow.log_prefix} Workflow failed.".colorize(:red)
    end
  end

  def initialize
    @status = "pending"
  end

  def failure!
    self.status = "failure"
  end

  def failure?
    status == "failure"
  end

  def log_prefix
    "[#{self.class.name.demodulize}(#{identifier})]"
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
