# Removes all crontab jobs created by test
#
# Usege:
#
# after do
#   remove_all_test_cron_jobs
# end
#
def remove_all_test_cron_jobs
  CronEdit::Crontab.List.keys.each do |key|
    CronEdit::Crontab.Remove(key) if key =~ /test-/
  end
end
