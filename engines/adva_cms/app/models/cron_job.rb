class CronJob < ActiveRecord::Base
  belongs_to :cronable, :polymorphic => true
  
  attr_accessible :command, :due_at
  validates_presence_of :command
  
  after_save :create_crontab
  after_destroy :remove_crontab
  
  def due_at=(datetime)
    if datetime.kind_of? Hash
      self.minute  = datetime[:minute]
      self.hour    = datetime[:hour]
      self.day     = datetime[:day]
      self.month   = datetime[:month]
      self.weekday = "*"
    elsif datetime.kind_of? DateTime
      self.minute  = datetime.min.to_s
      self.hour    = datetime.hour.to_s
      self.day     = datetime.day.to_s
      self.month   = datetime.month.to_s
      self.weekday = "*"
    end
  end
  
  def due_at
    @exact_due_time_check = []
    [self.minute,self.hour,self.day,self.month].each do |time|
      @exact_due_time_check << !(time =~ /[\*\/\-]/) || !time.nil?
    end
    @exact_due_time_check << (self.weekday == "*")

    if @exact_due_time_check.include? false
      nil
    else
      DateTime.new Date.today.year, self.month.to_i, self.day.to_i, self.hour.to_i, self.minute.to_i
    end
  end
  
  def create_crontab
    CronEdit::Crontab.Add self.test_aware_id, { :command => self.runner_command,
                                                :minute => self.minute,
                                                :hour => self.hour,
                                                :day => self.day,
                                                :month => self.month,
                                                :weekday => self.weekday }
  end
  
  def remove_crontab
    CronEdit::Crontab.Remove self.test_aware_id
  end

  def runner_command
    "export GEM_PATH=#{ENV["GEMDIR"]}; " +
    "#{ruby_path} -rubygems #{RAILS_ROOT}/script/runner -e #{RAILS_ENV} " +
    "'#{self.command}; #{autoclean}'"
  end

  #TODO: CronEdit needs rewrite
  def test_aware_id
    RAILS_ENV == 'test' ? "test-#{self.id}" : self.id
  end
  
private
  
  def autoclean
    "CronJob.find(#{self.id}).destroy;"
  end
  
  def ruby_path
    File.join(Config::CONFIG["bindir"], Config::CONFIG["RUBY_INSTALL_NAME"]+Config::CONFIG["EXEEXT"])
  end
end
