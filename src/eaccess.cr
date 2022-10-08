require "socket"

module EAccess
  DEFAULT_GATEWAY = {"eaccess.play.net", 7900}

  struct OTP
    property host, port, key

    def initialize(@host : String, @port : Int32, @key : String)
    end

    def use()
      sock = TCPSocket.new(@host, @port)
      sock << @key + "\n"
      sock << "/FE:WIZARD /VERSION:1.0.1.22 /P:i386-mingw32 /XML\n"
      2.times do
        sleep 0.3
        sock << "<c>\r\n"
      end
      sock
    end
  end

  class ProtocolErr < Exception
  end

  class PasswordErr < Exception
  end

  class SubscriptionErr < Exception
  end

  def self.proto_err(message)
    raise ProtocolErr.new(message)
  end

  def self.parse_otp(message)
  end

  def self.get_tsv(sock)
    (sock.gets || "").split("\t").skip(1)
  end

  def self.fetch_characters(account : String, password : String)
    sock = TCPSocket.new(*DEFAULT_GATEWAY)
    # get the key to use as the mask for the actual password
    key = get_key(sock)

    otp = send_masked_pass(sock,
      key:      key,
      account:  account,
      password: password)

    games = get_games_list(sock)

    subscription = get_sub(sock)

    return get_character_list(sock).keys
  end

  def self.auth(account : String, password : String, character : String)
    sock = TCPSocket.new(*DEFAULT_GATEWAY)
    # get the key to use as the mask for the actual password
    key = get_key(sock)

    otp = send_masked_pass(sock,
      key:      key,
      account:  account,
      password: password)

    games = get_games_list(sock)

    subscription = get_sub(sock)

    characters = get_character_list(sock)

    login_as = characters.dig(character.downcase)

    game, otp = get_otp(sock, login_as)

    return {login_as, game, otp}
  end

  def self.get_key(sock) : String
    # tell the remote we are ready to receive the key
    sock << "K\n"
    key = sock.gets
    proto_err("no password key found") if key.nil?
    return key
  end

  def self.send_masked_pass(sock : TCPSocket, key : String, account : String, password : String)
    hash = compute_hash(account, key, password)
    sock << "A\t#{account}\t"
    sock.write hash.to_slice
    sock << "\n"
    resp = sock.gets
    raise ProtocolErr.new("no password resp") if resp.nil?
    raise PasswordErr.new("account: %s appears to have a different password" % account) if resp.ends_with?("PASSWORD")
    raise SubscriptionErr.new("account: %s does not appear to have a valid subscription" % account) if resp.ends_with?("REJECT")
    key, owner = resp.split("\t").skip(3)
    return key
  end

  def self.compute_hash(account : String, key : String, password : String)
    io = IO::Memory.new
    password.bytes.zip(key.bytes).each do |char, shift|
      masked = ((char-32)^shift)+32
      io.write_byte(masked.to_u8)
    end
    return io.to_slice
  end

  def self.get_games_list(sock : TCPSocket)
    sock << "M\n"
    get_tsv(sock)
      .in_groups_of(2)
      .each_with_object({} of String => String) do |pair, acc|
        game_name, game_code = pair
        if (game_name.is_a?(String) && game_code.is_a?(String))
          acc[game_code] = game_name
        end
      end
  end

  def self.get_sub(sock : TCPSocket)
    code = ENV.fetch("GAME_CODE", "DR")
    f, g, p = "FGP".chars.map do |c|
      sock << c + "\t%s\n" % code
      get_tsv(sock)
    end
    p
  end

  def self.get_character_list(sock : TCPSocket)
    sock << "C\n"
    get_tsv(sock).skip(4).each_slice(2).each_with_object({} of String => String) do |info, acc|
      acc[info.last.downcase] = info.first
    end
  end

  def self.get_otp(sock, login_as)
    sock << "L\t#{login_as}\tSTORM\n"

    decoded = get_tsv(sock).skip(1).each_with_object({} of String => String) do |kv, acc|
      k,v = kv.split("=")
      acc[k.downcase] = v
    end

    { decoded.dig("gamecode"),
      OTP.new(host: decoded.dig("gamehost"),
            port: decoded.dig("gameport").to_i,
            key:  decoded.dig("key"))}
  end
end
