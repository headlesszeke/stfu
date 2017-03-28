#!/usr/bin/env ruby
require 'stfu'

# debug class for ironing out randomness tests against random strings
class RandomString < STFU
  def login(creds)
    return true
  end

  def parse_token(resp)
    charset = [("a".."z"),("A".."Z"),("0".."9")].map(&:to_a).flatten
    return (0..63).map {charset[rand(charset.length)]}.join
  end

  def valid_token?(token)
    return true
  end

  def logout(token)
    # skip
  end

  def test_is_made_of_known_values?
    return false
  end

  def test_is_persistent?
    return false
  end

  def test_is_validated?
    return false
  end
end

target = RandomString.new("","",[])
target.loglevel = 3
target.run_tests
