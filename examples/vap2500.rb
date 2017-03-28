#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'stfu'

class Vap2500 < STFU
  def login(creds)
    user = creds["user"]
    pass = creds["pass"]
    uri = URI.parse("http://#{@host}:#{@port}/login.php")
    boundary = "blah"
    header = {"Content-Type":"multipart/form-data, boundary=#{boundary}"}

    post_body = ""
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"user\"\r\n\r\n"
    post_body << "#{user}\r\n"
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"pwd\"\r\n\r\n"
    post_body << "#{pass}\r\n"
    post_body << "--#{boundary}\r\n"

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri, header)
    req.body = post_body

    return http.request(req)
  end

  def parse_token(resp)
    resp.body =~ /createCookie\x28"p", "(.{32})"/
    return $1
  end

  def valid_token?(token)
    uri = URI.parse("http://#{@host}:#{@port}/status_device.php")
    header = {"Cookie":"p=#{token}"}
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri, header)
    resp = http.request(req)
    return resp.body =~ /tools_admin/
  end

  def logout(token)
    # no logout functionality
  end

  def test_is_persistent?
    # cookies are always persistent since there is no logout, just stub this test out
    return false
  end
end

host = "127.0.0.1"
port = "8080"
creds = [{"user" => "ATTadmin", "pass" => "2500!VaP"},
         {"user" => "super", "pass" => "M0torola!"}]

target = Vap2500.new(host,port,creds)
target.loglevel = 2
target.run_tests
