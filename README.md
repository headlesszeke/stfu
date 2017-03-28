STFU
==
### Session Token Fuzzing Utility: A ruby library for auditing session tokens.

I needed a way to quickly and easily spin up tests for checking a session token in a secure app for
common weaknesses like lack of randomness, usage of known values, etc. This library is the result
of that need. It is designed to be generic and easily extensible in order to work against any type of
target, not just webapps. Basically, you define a new class which inherits from the STFU class, then
implement four basic methods for obtaining a session token in your target app (login, parse_token,
valid_token?, and logout). You create a new instance of your class and call the run_tests method
on it. Then just sit back while it runs through the prerolled suite of tests and see if anything
shakes loose. You can also easily stub out individual tests that don't make sense for your current
target or define new ones specific to your target (any method named with "test_" will be automatically
added to the test queue) from within your class. See *examples/vap2500.rb* for an example of an
implementation that works against older versions of the Arris VAP2500 that had significant problems
with its implementation of tokens used as cookies. 

Installation
--

All the requirements for STFU should be standard ruby libraries I believe...If I'm wrong, let me know
and I'll document here.

At some point, I'll probably make this a ruby gem, but in the meantime it's easy enough just to add
STFU to your RUBYLIB path.
```
export RUBYLIB="$RUBYLIB:/path/to/stfu/"
```

Usage
--

Create a ruby script like so (see examples/ for more detail):
```
require 'stfu'
# require any other libs you need for interacting with your target

class MyClass < STFU
  def login(creds)
    # implement login routine, return response that contains session token to test
  end

  def parse_token(resp)
    # implement routine to parse a response and return the token
  end

  def valid_token?(token)
    # implement a routine to access secure area using token to verify
    # return true if access succeeded, false if access failed
  end

  def logout(token)
    # implement logout routine to invalidate current token, no return needed
  end
end

host = [target ip address]
port = [target port]
creds = [{"user" => "user1", "pass" => "pass1234"},
         {"user" => "user2", "pass" => "pass5678"}]

target = MyClass.new(host,port,creds)
target.loglevel = 2 # optionally set loglevel (1 == default, higher == more logging)
target.run_tests
```

Files
--

  * stfu.rb - the main library
  * examples/vap2500.rb - example for testing old Arris VAP2500 tokens
  * examples/random_strings.rb - example for testing against random strings, basically debugging but shows stubbing out of unneeded methods

TODO
--

  * implement more test cases
  * improve randomness testing...or just stick with arithmetic_mean and call it good
  * flesh out 'test_is_made_of_known_values?' further
  * improve 'test_is_sequential?', specifically wrt similarity
  * improve 'test_is_validated?' - better define/detect what is 'well-formed'
  * improve documentation...maybe...someday...
