require 'base64'
require 'digest'
require 'zlib'

class STFU
  attr_accessor :loglevel

  def initialize(host,port,creds)
    @host = host
    @port = port
    @creds = creds
    @loglevel = 1
  end

  # method stubs - these are the methods that need to be implemented for each unique target application.
  #    above each is a brief description of the intended purpose of each method and its desired inputs/
  #    outputs, however since they are unimplemented, they can be used however works

  # login method for providing credentials to a server application in order to obtain a valid session token
  # input: creds - a hash or array of valid credentials
  # output: a server response to parse for a token 
  def login(creds)
    raise "You need to implement a login method to obtain a session token for testing."
  end

  # parse_token method for taking a server response and parsing out the session token from it
  # input: resp - a server response to parse for a session token 
  # output: a session token
  def parse_token(resp)
    raise "You need to implement a parser method to retrieve a session token from a server response."
  end

  # valid_token? method for testing validity of a given session token. uses token to access secure areas
  #    and tests whether or not it was successful
  # input: token - a session token 
  # output: true == token is valid for accessing secure areas of target application
  #         false == token is invalid
  def valid_token?(token)
    raise "You need to implement a method to check the validity of session tokens."
  end

  # logout method for invalidating a given session token
  # input: token - a valid session token
  # output: none 
  def logout(token)
    raise "You need to implement a logout method to invalidate a session token for testing."
  end
  # end method stubs

  # main 'do everything' method
  def run_tests
    count = 0
    puts "Starting test run..."
    self.methods.each {|test|
      next if test !~ /^test_/
      puts "[*] Running '#{test}'..." if @loglevel > 2
      count +=1 if self.method(test).call
    }
    
    if count > 0
      puts "Found #{count} failure#{"s" if count > 1 || count == 0}."
    else
      puts "Found no failures. Tokens seem sane."
    end
  end
  
  # tests (prepend all test method names with 'test_' for dynamic calling)
  #    return true to signify finding something bad (ie: test_is_static? returns true if tokens are static)
  
  # are tokens static per user? across multiple users?
  def test_is_static?
    token1 = parse_token(login(@creds[0]))
    if valid_token?(token1)
      logout(token1)
    else
      raise "Supplied creds did not yield valid session token."
    end
    
    token2 = parse_token(login(@creds[0]))
    if valid_token?(token2)
      logout(token2)
    else
      raise "Supplied creds did not yield valid session token."
    end

    if @creds.length > 1
      token3 = parse_token(login(@creds[1]))
      if valid_token?(token3)
        logout(token3)
      else
        raise "Supplied creds did not yield valid session token."
      end
      if token1 == token3
        puts "[!] Tokens static across multiple users."
        return true
      end
    end

    if token1 == token2
      puts "[!] Tokens static for each user."
      return true
    end

    return false
  end

  # are tokens generated sequentially? are multiple tokens similar to each other?
  def test_is_sequential?
    token1 = parse_token(login(@creds[0]))
    if valid_token?(token1)
      logout(token1)
    else
      raise "Supplied creds did not yield valid session token."
    end

    token2 = parse_token(login(@creds[0]))
    if valid_token?(token2)
      logout(token2)
    else
      raise "Supplied creds did not yield valid session token."
    end

    if token1.to_i != 0 || token2.to_i != 0
      diff = (token1.to_i - token2.to_i).abs
      if diff > 0 && diff < 10
        puts "[!] Token strings seem sequential."
        return true
      end
    elsif token1.length == token2.length
      diff = 0
      token1.bytes.each_index {|i|
        diff += 1 if token1.bytes[i] != token2.bytes[i]
      }
      if diff > 0 && diff < 3
        puts "[!] Token strings seem similar."
        return true
      end
    end

    return false
  end

  # do tokens persist after logout?
  def test_is_persistent?
    token = parse_token(login(@creds[0]))
    if valid_token?(token)
      logout(token)
    else
      raise "Supplied creds did not yield valid session token."
    end

    if valid_token?(token)
      puts "[!] Tokens still valid after logout."
      return true
    end

    return false
  end

  # are well-formed, but invalid tokens accepted? NOTE: this could be better...
  def test_is_validated?
    token = parse_token(login(@creds[0]))
    if valid_token?(token)
      if valid_token?(token.reverse)
        logout(token)
        puts "[!] Well-formed yet invalid tokens are accepted."
        return true
      end
    else
      raise "Supplied creds did not yield valid session token."
    end

    return false
  end

  # do tokens contain known/static values? NOTE: this could be expanded upon
  def test_is_made_of_known_values?
    token = parse_token(login(@creds[0]))
    if valid_token?(token)
      logout(token)
    else
      raise "Supplied creds did not yield valid session token."
    end
    
    failed = false
    token = token.to_s
    token64 = ""
    if token =~ /([A-Za-z0-9+\/]{4})*([A-Za-z0-9+\/]{4}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}==$)/
      puts "[?] Tokens look base64 encoded." if @loglevel > 1
      token64 = Base64.decode64(token)
    end

    if token.include?(@creds[0]["user"]) || token64.include?(@creds[0]["user"])
      puts "[!] Tokens contain username."
      failed = true
    end

    if token.include?(@creds[0]["pass"]) || token64.include?(@creds[0]["pass"])
      puts "[!] Tokens contain password."
      failed = true
    end

    if token.include?(Digest::MD5.hexdigest(@creds[0]["user"])) || token64.include?(Digest::MD5.hexdigest(@creds[0]["user"]))
      puts "[!] Tokens contain md5sum of username."
      failed = true
    end

    if token.include?(Digest::MD5.hexdigest(@creds[0]["pass"])) || token64.include?(Digest::MD5.hexdigest(@creds[0]["pass"]))
      puts "[!] Tokens contain md5sum of password."
      failed = true
    end

    return failed
  end

  # are tokens non-random? TODO: IMPLEMENT MOAR/BETTER RANDOMNESS TESTS
  #   modeled after cryptanalib's is_random() function
  #   https://github.com/nccgroup/featherduster/tree/master/cryptanalib
  #   thx @dan_crowley!
  def test_is_nonrandom?
    tokens = []
    10.times {
      token = parse_token(login(@creds[0]))
      if valid_token?(token)
        tokens << token.to_s
        logout(token)
      else
        raise "Supplied creds did not yield valid session token."
      end
    }
    sample = tokens.join
    puts "[?] Sample size not large enough for true randomness detection." if (@loglevel > 1) && (tokens.length < 5 || sample.length < 100)

    failed = 0

    failed +=1 if arithmetic_mean(sample)
    failed +=1 if char_freq(sample)
    failed +=1 if compression_ratio(sample)
    
    if failed > 1
      puts "[!] Multiple randomness tests failed. Tokens very likely to be non-random."
      return true
    elsif failed == 1
      puts "[!] One randomness test failed. Tokens possibly non-random."
      return true
    else
      return false
    end
  end

  # detect charset and use that as expected mean
  def arithmetic_mean(str)
    if str =~ /^\d+$/
      expected = 52.5
    elsif str =~ /^[0-9a-z]+$/
      expected = 93.67
    elsif str =~ /^[0-9a-z]+$/i
      expected = 86.89
    elsif str =~ /^[0-9a-z+\/=]+$/i
      expected = 85.2
    elsif str =~ /^[ -~]+$/
      expected = 79.0
    else
      expected = 127.5 # punt
    end

    low_bar = 0.87 * expected
    high_bar = 1.13 * expected

    actual = str.each_char.inject(0) {|sum,x| sum + x.ord} / str.length.to_f
    puts "[?] Arithmetic mean is #{actual} (random strings would probably be between #{low_bar} and #{high_bar})." if @loglevel > 1
    return true if actual <= low_bar || actual >= high_bar

    return false
    
  end

  # not really appropriate for long strings or numeric tokens...basically sucks, but there it is...
  def char_freq(str)
    chars = {}
    str.each_char {|char|
      chars[char] = 0 unless chars.include?(char)
      chars[char] += 1
    }

    puts "[?] Unique characters found: #{chars.length} out of #{str.length}, Most frequent character: #{chars.sort_by {|k,v| v}.last.inspect}." if @loglevel > 1
    return true if chars.length < (str.length / 15) && chars.sort_by {|k,v| v}.last[1] > 30

    return false
  end
      
  # again, not sure this makes sense for numeric tokens...expected compression ratio is from my own testing
  def compression_ratio(str)
    expected = 0.68
    actual = Zlib.deflate(str,9).length / str.length.to_f
    puts "[?] Compression ratio is #{actual} (random strings would probably be > #{expected})." if @loglevel > 1
    return true if actual <= expected
    
    return false
  end
end
