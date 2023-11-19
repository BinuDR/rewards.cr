require "./eaccess"

module Rewards
  VERSION = "0.3.2"

  def self.account()
    ENV["GS_ACCOUNT"]
  end

  def self.password()
    ENV["GS_PASSWORD"]
  end

  def self.claim!(account = self.account, password = self.password)
    EAccess.fetch_characters(account: account, password: password).each {|character|
      begin
        Task.retry(3) {
          _0, _1, otp = EAccess.auth(account: account, password: password, character: character)
          self.login(character, otp)
        }
      rescue error
        puts "account=%s\nerror=%s\ntrace=\n%s" % [account, error.message, error.backtrace.join("\n")]
      end
    }
  end

  def self.login(character, otp)
    game = otp.use()
    game.read_timeout = 3
    server = TCPServer.new("localhost", 0)
    while from_game = game.gets
      break if game.closed?
      next if from_game.nil? || from_game.strip.empty?
      break if from_game =~ /\[You are dead.\]/
      break if from_game =~ /You are a ghost!/
      break if from_game =~ /\[A Junk Yard\]/
      break if from_game =~ /Thank you for logging into DragonRealms/
      break if from_game =~ /Current login streak/
      game << "boost\n" if from_game =~ /^<prompt/
    end
    server.close
    puts "%s> logged in - #{from_game}" % [character.ljust(15)]
  end
end
