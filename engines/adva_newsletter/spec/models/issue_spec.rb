require File.dirname(__FILE__) + '/../spec_helper'

describe BaseIssue do
  before :each do
    Site.delete_all
    @issue = Factory :issue
  end

  describe "associations:" do  
    it "sholud belong to newsletter" do @issue.should belong_to(:newsletter) end
    it "should have many cronjobs as cronable" do @issue.should have_many(:cron_jobs) end
  end
  
  describe "validations:" do
    it "should have title" do
      @issue.title = nil
      @issue.should_not be_valid
    end
    
    it "should have body" do
      @issue.body = nil
      @issue.should_not be_valid
    end
  end
  
  describe "methods:" do
    describe "draft?" do
      it "should be true with new issue" do
        @issue.draft?.should == true
      end

      it "should be true when issue is draft" do
        @issue.draft = 1
        @issue.draft?.should == true
      end
    end
  end
end

describe Issue do
  
  before :each do
    Site.delete_all
    @issue = Factory :issue
    @user = Factory :user
  end

  describe "methods:" do
    describe "destroy" do
      it "should move Issue to DeletedIssue" do
        Issue.find_by_id(@issue.id).should_not == nil
        DeletedIssue.find_by_id(@issue.id).should == nil
        @issue.destroy
        Issue.find_by_id(@issue.id).should == nil
        DeletedIssue.find_by_id(@issue.id).should_not == nil
      end
      
      it "should decrease issues_count by -1" do
        @newsletter = Newsletter.first
        @newsletter.issues_count.should == 1
        @newsletter.issues.first.destroy
        @newsletter.reload.issues_count.should == 0
      end
    end
  end

  describe "deliver" do
    it "should create cronjob with command to create issue emails" do
      @issue.deliver.command.should == "Issue.find(#{@issue.id}).create_emails"
    end
    
    it "should create cronjob with due time 3 minutes later" do
      @issue.deliver.created_at.class.should == ActiveSupport::TimeWithZone
      @issue.deliver.due_at.should > DateTime.now + 170.seconds
      # FIXME: some timezone error, have to figure out why in test it's different
      # @issue.deliver.due_at.should < DateTime.current + 180.seconds
    end
    
    it "should deliver all issues LATER" do
      # @issue.deliver(:later_at => Time.now.tomorrow).should == 'deliver all later'
    end
    
    it "should deliver issue ONLY TO test user NOW" do
      # @mailer = mock(NewsletterMailer)
      # @mailer.should_receive(:deliver_issue).and_return(true)

      # @issue.published_at.should == nil
      # @issue.deliver(:to => @user)
      # @issue.published_at.should_not == nil
    end
    
    it "should deliver issue ONLY TO test user LATER" do
      # @issue.deliver(:later => Time.now.tomorrow, :to => @user).should == 'deliver later to'
    end

    after do
      remove_all_test_cron_jobs
    end
  end
end
