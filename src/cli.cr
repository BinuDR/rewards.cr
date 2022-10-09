require "./rewards"
require "./task"
require "csv"

accounts = CSV.parse(ARGF)
accounts.each do |info|
  account, password = info
  puts "==== Account: #{account} ===="
  begin
    Rewards.claim!(account, password)
  rescue error
    puts "account=%s\nerror=%s\ntrace=\n%s" % [account, error.message, error.backtrace.join("\n")]
  end
end
