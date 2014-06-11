# We can unpickle that!

This is a library for deserializing Python pickle objects (proto 2). The goal was to be able to unpickle Django session data directly from Ruby.

## Install
As a gem:
```
gem install pickle-interpreter
```

Or in your Gemfile:
```
gem 'pickle-interpreter'
```

Require:
```ruby
require 'pickle_interpreter'
```

## Usage
For Base64-encoded strings:
```ruby
PickleInterpreter.unpickle_base64(my_string)
```

For binary strings, be sure it is using the ASCII-8bit character encoding:
```ruby
PickleInterpreter.unpickle(my_string)
```

For reading `session_data` from a `django_session` table:
```ruby
PickleInterpreter.unpickle_base64_signed(my_string).
```
*Note that this doesn't check the signature, the hash before the `:` is ignored.*

## Python Testing
```python
import base64
import pickle

session_data = <Base64 encoded string, such as django_session.session_data>
encoded_data = base64.b64decode(session_data)
hash, serialized = encoded_data.split(b':', 1)
data = pickle.loads(serialized)

# Pickle using protocol 2
serialized = pickle.dumps(data, 2)
session_data = base64.b64encode("hash" + b":" + serialized)
```

## Notes
I *think* I have at least a rudimentary implementation of all of the pickle instructions.  However, I don't use a lot of Python, so I don't really have anything to test on.  If you use this, and something breaks, if you send me the pickle file, and what it should decode to, I will get it fixed.  jonathan@newmedio.com

For objects, however, I pretty much just create a hash with the initialization parameters baked in somewhere (i.e. with a key like "__init_args" or something appropriate to how it was called).  This is certainly an area that can be improved.  However, you can also just walk the tree after the fact and look for these.

Let me know how it works, and if there is anything else I need to implement.  This is based on the 2014-06-10 version of this file:

http://svn.python.org/projects/python/trunk/Lib/pickletools.py