This is a library for reading Python pickle objects.

If you have a Base64-encoded string, you can just do PickleInterpreter.unpickle_base64(my_string)

If you have the actual binary string, be sure it is using the ASCII-8bit character encoding.  Then you can do PickleInterpreter.unpickle(my_string)

If you are reading from the django_session table (which is why I bothered with this in the first place), you can do PickleInterpreter.unpickle_base64_signed(my_string).  Note that in this function we don't check the signature, we just ignore it.

I *think* I have at least a rudimentary implementation of all of the pickle instructions.  However, I don't use a lot of Python, so I don't really have anything to test on.  If you use this, and something breaks, if you send me the pickle file, and what it should decode to, I will get it fixed.  jonathan@newmedio.com

For objects, however, I pretty much just create a hash with the initialization parameters baked in somewhere (i.e. with a key like "__init_args" or something appropriate to how it was called).  This is certainly an area that can be improved.  However, you can also just walk the tree after the fact and look for these.

Let me know how it works, and if there is anything else I need to implement.  This is based on the 2014-06-10 version of this file:

http://svn.python.org/projects/python/trunk/Lib/pickletools.py


