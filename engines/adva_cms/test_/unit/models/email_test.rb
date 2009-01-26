require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class EmailTest < ActiveSupport::TestCase
  def setup
    super
    # FIXME move to db/populate
    Email.delete_all
    @email = Email.create! :from => "admin@example.org",
                           :to   => "user@example.org",
                           :mail => "add valid email here"
  end
  
  teardown do
    remove_all_test_cronjobs
  end

  test "is valid with from, to and mail" do
    @email.should be_valid
  end

  test "is invalid without from" do
    @email.from = nil
    @email.should_not be_valid
  end
  
  test "is invalid without to" do
    @email.to = nil
    @email.should_not be_valid
  end
  
  test "is invalid without mail" do
    @email.mail = nil
    @email.should_not be_valid
  end
  
  # CLASS METHODS
  
  # create_cronjob
  test "creates a cronjob" do
    response = Email.create_cronjob
    response.class.should == Cronjob 
    response.command.should == "Email.deliver_all"
  end
  
  # deliver_all
  test "deliver_all removes cronjob when all emails are delivered" do
    Cronjob.create :cron_id => "email_deliver_all", :command => "test"
    Email.destroy_all
    Email.deliver_all
    Cronjob.find_by_cron_id("email_deliver_all").should be_nil
  end
  
      
  test "defaults to 150 mails of outgoing per process" do
    Adva::Config.number_of_outgoing_mails_per_process = nil
    Adva::Config.number_of_outgoing_mails_per_process.should == 150
  end
end
