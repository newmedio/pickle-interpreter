#!/usr/bin/env ruby

require "base64"
class PickleInterpreter
	@@instructions = {}

	def self.register_instruction(code, funcsym)
		@@instructions[code] = funcsym
	end

	def initialize
		@stack = []
		@memo = []
		@exts = []
	end

	def self.unpickle(str)
		p = PickleInterpreter.new
		p.interpret_string(str)
	end

	def self.unpickle_base64(str)
		p = PickleInterpreter.new
		p.interpret_base64(str)
	end

	def self.unpickle_base64_signed(str)
		p = PickleInterpreter.new
		p.interpret_base64_signed(str)
	end

	def interpret(instruction_stack)
		while(!instruction_stack.empty?) do
			instr = instruction_stack.shift

			sym = @@instructions[instr]
			if sym.nil?
				raise "Error finding instruction: #{instr}"
			end
			if(sym == :STOP)
				return @stack.pop
			else
				self.send("instr_#{sym}", instruction_stack)
			end
		end
	end
	
	def interpret_string(str)
		interpret(str.chars.map{|char| char.ord})
	end

	def interpret_base64(str)
		interpret_string(Base64.decode64(str))		
	end

	def interpret_base64_signed(str)
		val = Base64.decode64(str)
		interpret_string(Base64.decode64(str).split(":", 2)[1])
	end

	def instr_PROTO(instruction_stack)
		val = instruction_stack.shift
		# Do nothing
	end
	register_instruction(128, :PROTO)

	def instr_INT(instruction_stack)
		@stack.push(read_nl_number(instruction_stack))
	end
	register_instruction("I".ord, :INT)

	def instr_BININT(instruction_stack)
		@stack.push(read_nbyte_long(instruction_stack, 4))
	end
	register_instruction("J".ord, :BININT)

	# NOTE - positive-only!
	def instr_BININT1(instruction_stack)
		@stack.push(instruction_stack.shift)
	end
	register_instruction("K".ord, :BININT1)

	# FIXME - positive-only!
	def instr_BININT2(instruction_stack)
		@stack.push(read_nbyte_long(instruction_stack, 2))
	end
	register_instruction("M".ord, :BININT2)

	def instr_EMPTY_DICT(instruction_stack)
		@stack.push({})
	end
	register_instruction("}".ord, :EMPTY_DICT)

	def instr_DICT(instruction_stack)
		tmphsh = {}
		lst = slice_to_mark()
		while(!lst.empty?) do
			val = lst.pop
			key = lst.pop
			tmphsh[key] = val
		end
		@stack.push(tmphsh)
	end
	register_instruction("d".ord, :DICT)

	def instr_EXT1(instruction_stack)
		ereg_idx = instruction_stack.shift
		@stack.push(@exts[ereg_idx])
	end
	register_instruction(130, :EXT1)

	def instr_EXT2(instruction_stack)
		ereg_idx = read_nbyte_long(instruction_stack, 2)
		@stack.push(@exts[ereg_idx])
	end
	register_instruction(131, :EXT2)

	def instr_EXT4(instruction_stack)
		ereg_idx = read_nbyte_long(instruction_stack, 4)
		@stack.push(@exts[ereg_idx])
	end
	register_instruction(132, :EXT4)

	def instr_GLOBAL(instruction_stack)
		modname = read_nl_string(instruction_stack)
		clsname = read_nl_string(instruction_stack)
		# FIXME - should I actually try to locate the classes?  Currently just returning a hash with special keys
		#       - should have a set of defines mods/classes that we can pull from
		@stack.push({"__module" => modname, "__class" => clsname})
	end
	register_instruction("c".ord, :GLOBAL)

	# FIXME - not really implemented.  Should have a set of defined callables
	def instr_REDUCE(instruction_stack)
		arg = @stack.pop
		callable = @stack.pop
		@stack.push({"__callable" => callable, "__argument" => arg})
	end
	register_instruction("R".ord, :REDUCE)

	# FIXME - not really implemented.  Just adds another parameter to a hash at the moment
	def instr_BUILD(instruction_stack)
		arg = @stack.pop
		@stack.last["__state"] = arg
	end
	register_instruction("b".ord, :BUILD)

	# FIXME - not really implemented.
	def instr_INST(instruction_stack)
		modname = read_nl_string(instruction_stack)
		clsname = read_nl_string(instruction_stack)
		args = slice_to_mark()
		@stack.push({"__init_arg" => args, "__module" => modname, "__class" => clsname})
	end
	register_instruction("i".ord, :INST)

	def instr_OBJ(instruction_stack)
		lst = slice_to_mark()
		class_obj = lst.shift
		@stack.push({"__init_arg" => lst, "__classobj" => class_obj})
	end
	register_instruction("o".ord, :OBJ)

	def instr_NEWOBJ(instruction_stack)
		arg = @stack.pop
		cls = @stack.pop
		@stack.push({"__classobj" => cls, "__init_arg" => arg})
	end
	register_instruction(129, :NEWOBJ)

	# FIXME - need to register persistent loaders
	def instr_PERSID(instruction_stack)
		persid = read_nl_string(instruction_stack)
		@stack.push({"__persid" => persid})
	end
	register_instruction("P".ord, :PERSID)

	# FIXME - need to register persistent loaders
	def instr_BINPERSID(instruction_stack)
		persid = @stack.pop
		@stack.push({"__persid" => persid})
	end
	register_instruction("Q".ord, :BINPERSID)

	def instr_SETITEM(instruction_stack)
		value = @stack.pop
		key = @stack.pop
		@stack.last[key] = value
	end
	register_instruction("s".ord, :SETITEM)

	def instr_PUT(instruction_stack)
		location = read_nl_number(instruction_stack)
		@memo[location] = @stack.last
	end
	register_instruction("p".ord, :PUT)

	def instr_BINPUT(instruction_stack)
		location = instruction_stack.shift
		@memo[location] = @stack.last
	end
	register_instruction("q".ord, :BINPUT)

	# FIXME - need to change encoding to UTF8
	def instr_BINUNICODE(instruction_stack)
		sz = read_nbyte_long(instruction_stack, 4)
		str = read_string(instruction_stack, sz)
		@stack.push(str)
	end
	register_instruction("X".ord, :BINUNICODE)

	# FIXME - not sure if encoding right.  Also need to get escape sequences
	def instr_UNICODE(instruction_stack)
		str = read_nl_string(instruction_stack)
		@stack.push(str)
	end
	register_instruction("V".ord, :UNICODE)

	def instr_NEWTRUE(instruction_stack)
		@stack.push(true)
	end
	register_instruction(136, :NEWTRUE)

	def instr_NEWFALSE(instruction_stack)
		@stack.push(false)
	end
	register_instruction(137, :NEWFALSE)

	def instr_NONE(instruction_stack)
		@stack.push(nil)
	end
	register_instruction("N".ord, :NONE)


	def instr_LONG_BINPUT(instruction_stack)
		location = read_nbyte_long(instruction_stack, 4)
		@memo[location] = @stack.last
	end
	register_instruction("r".ord, :LONG_BINPUT)

	def read_nl_number(instruction_stack)
		decimal = false
		decimal_instr = ".".ord
		terminator = "\n".ord
		val = 0
		offset = "0".ord
		decimal_level = 0
		negative = false

		nextval = instruction_stack.shift
		while(nextval != terminator) do
			if nextval == decimal_instr
				decimal = true
			else
				if nextval == 'L'
					# skip
				else
					if nextval == '-'
						negative = true
					else
						val = val * 10
						val = val + (nextval - offset)
						if decimal
							decimal_level = decimal_level + 1
						end
					end
				end
			end

			nextval = instruction_stack.shift
		end
	
		if negative
			val = 0 - val
		end
	
		if decimal
			divisor = 10 ** decimal_level
			val = val.to_f / divisor.to_f
		end

		return val
	end

	def instr_GET(instruction_stack)
		location = read_nl_number(instruction_stack)
		@stack.push(@memo[location])
	end
	register_instruction("g".ord, :GET)

	def instr_BINGET(instruction_stack)
		location = instruction_stack.shift
		@stack.push(@memo[location])	
	end
	register_instruction("h".ord, :BINGET)

	def instr_LONG_BINGET(instruction_stack)
		location = read_nbyte_long(instruction_stack, 4)
		@stack.push(@memo[location])
	end
	register_instruction("j".ord, :LONG_BINGET)

	def instr_MARK(instruction_stack)
		@stack.push(:mark)
	end
	register_instruction("(".ord, :MARK)

	def slice_to_mark()
		tmplist = []
		val = @stack.pop
		while(val != :mark) do
			tmplist.unshift(val)
			val = @stack.pop
		end

		return tmplist
	end

	def instr_POP_MARK(instruction_stack)
		while(true) do
			break if @stack.empty?
			nextval = @stack.pop
			break if nextval == :mark
		end
	end
	register_instruction("1".ord, :POP_MARK)

	# FIXME - twos complement
	def read_nbyte_long(instruction_stack, n)
		val = 0
		multiplier = 1
		while(n > 0) do
			nextval = instruction_stack.shift
			nextval = nextval * multiplier
			val = val + nextval

			multiplier = multiplier * 256
			n = n - 1
		end
	
		return val
	end

	def read_string(instruction_stack, str_size)
		str = ""
		while(str_size > 0) do
			nextchar = instruction_stack.shift
			str = str + nextchar.chr
			str_size = str_size - 1
		end

		return str
	end

	def instr_DUP(instruction_stack)
		@stack.push(@stack.last)
	end
	register_instruction("2".ord, :DUP)

	def instr_POP(instruction_stack)
		@stack.pop
	end
	register_instruction("0".ord, :POP)

	def instr_FLOAT(instruction_stack)
		@stack.push(read_nl_number(instruction_stack))
	end
	register_instruction("F".ord, :FLOAT)

	def instr_BINFLOAT(instruction_stack)
		str = ""
		ctr = 0
		while(ctr < 8) do
			str = "#{str}#{instruction_stack.shift.chr}"
			ctr = ctr + 1
		end
		val = str.unpack("G")[0]
		@stack.push(val)
	end
	register_instruction("G".ord, :BINFLOAT)

	def instr_EMPTY_LIST(instruction_stack)
		@stack.push([])
	end
	register_instruction("]".ord, :EMPTY_LIST)

	def instr_APPEND(instruction_stack)
		val = @stack.pop
		@stack.last.push(val)
	end
	register_instruction('a'.ord, :APPEND)

	def instr_APPENDS(instruction_stack)
		tmplist = slice_to_mark()
		tmplist.each do |tmp|
			@stack.last.push(tmp)
		end
	end
	register_instruction('e'.ord, :APPENDS)

	def instr_LIST(instruction_stack)
		@stack.push(slice_to_mark())
	end
	register_instruction("l".ord, :LIST)

	def instr_EMPTY_TUPLE(instruction_stack)
		@stack.push([])
	end
	register_instruction(')'.ord, :EMPTY_TUPLE)

	def instr_TUPLE(instruction_stack)
		@stack.push(slice_to_mark())
	end
	register_instruction('t'.ord, :TUPLE)

	def instr_TUPLE1(instruction_stack)
		@stack.push([@stack.pop])
	end
	register_instruction(133, :TUPLE1)

	def instr_TUPLE2(instruction_stack)
		val2 = @stack.pop
		val1 = @stack.pop
		@stack.push([val1, val2])
	end
	register_instruction(134, :TUPLE2)

	def instr_TUPLE3(instruction_stack)
		val3 = @stack.pop
		val2 = @stack.pop
		val1 = @stack.pop
		@stack.push([val1, val2, val3])
	end
	register_instruction(135, :TUPLE3)
	
	def instr_BINSTRING(instruction_stack)
		sz = read_nbyte_long(instruction_stack, 4)
		str = read_string(instruction_stack, sz)
		@stack.push(str)
	end
	register_instruction("T".ord, :BINSTRING)

	def instr_SHORT_BINSTRING(instruction_stack)
		str_size = instruction_stack.shift
		str = read_string(instruction_stack, str_size)
		@stack.push(str)
	end
	register_instruction("U".ord, :SHORT_BINSTRING)

	def instr_LONG(instruction_stack)
		@stack.push(read_nl_number(instruction_stack))
	end
	register_instruction("L".ord, :LONG)

	def instr_LONG1(instruction_stack)
		sz = instruction_stack.shift
		val = read_nbyte_long(instruction_stack, sz)
		@stack.push(val)
	end
	register_instruction(138, :LONG1)

	def instr_LONG4(instruction_stack)
		sz = read_nbyte_long(instruction_stack, 4)
		val = read_nbyte_long(instruction_stack, sz)
		@stack.push(val)
	end
	register_instruction(139, :LONG4)

	def read_nl_string(instruction_stack)
		str = ""
		terminator = "\n".ord
		nextval = instruction_stack.shift
		while(nextval != terminator) do
			str = str + nextval.chr
			nextval = instruction_stack.shift
		end

		return nextval
	end

	# FIXME - need to interpret string (repr-style according to docs)
	def instr_STRING(instruction_stack)
		str = read_nl_string(instruction_stack)
		@stack.push(str)
	end
	register_instruction("S".ord, :STRING)

	def instr_SETITEMS(instruction_stack)
		lst = slice_to_mark()
		while(!lst.empty?) do
			val = lst.pop
			key = lst.pop
			@stack.last[key] = val
		end
	end
	register_instruction("u".ord, :SETITEMS)

	def instr_STOP
		# we are treating this as a no-op
	end	
	register_instruction(".".ord, :STOP)
end
