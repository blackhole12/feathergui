local C = require 'feather.libc'

local Array = require 'feather.array'
local F = require 'feather.shared'
local Backend = require 'feather.backend'
local Enum = require 'feather.enum'
local Flags = require 'feather.flags'
local Message = require 'feather.message'
local Hash = require 'feather.hash'
local cond = require 'std.cond'
local OS = require 'feather.os'
local Constraint = require 'std.constraint'
local List = require 'std.terralist'
local Object = require 'std.object'
local Unique = require 'std.unique'

--local String = require 'feather.string'

local struct TestHarness {
  passed : int;
  total : int;
}

TestHarness.methods.Test = Constraint(function(a) return Constraint.MetaMethod(TestHarness, {a, Constraint.Cast(a), Constraint.Optional(Constraint.Rawstring)}, nil,
function(self, result, expected, op)
  op = op or "__eq"
  return quote
    self.total = self.total + 1
    var r = result
    var e = expected
    if operator(op, r, e) then
      self.passed = self.passed + 1
    else
      --s = String:append("Test Failed, expected ", e, " but got ", r, ": ", [ result:prettystring() ])
      --buf = s:torawstring()
      --C.printf(buf)
      
      C.printf("Test Failed: %s", [ result:prettystring() ])
    end
  end
end) end, Constraint.TerraType)

terra TestHarness:array()
  var a : Array(int)
  a:add(1)
  self:Test(a(0), 1)
  self:Test(a.size, 1)
  a:reserve(5)
  self:Test(a.capacity, 5)
  self:Test(a.size, 1)
  a:add(2)
  self:Test(a.size, 2)
  a:add(3)
  self:Test(a.size, 3)
  a:add(4)
  self:Test(a.size, 4)
  a:insert(5, 4)
  self:Test(a.size, 5)
  self:Test(a(1), 2)
  self:Test(a(2), 3)
  self:Test(a(3), 4)
  self:Test(a(4), 5)
  a:insert(0, 0)
  self:Test(a.size, 6)
  self:Test(a.capacity, 6, "__ge")
  self:Test(a(0), 0)
  self:Test(a(1), 1)
  self:Test(a(2), 2)
  self:Test(a(3), 3)
  self:Test(a(4), 4)
  self:Test(a(5), 5)

  a:clear()
  self:Test(a.size, 0)
  a:add(1)
  self:Test(a.size, 1)
  self:Test(a(0), 1)
end

terra TestHarness:backend()

end

terra TestHarness:color()
  var c : F.Color = F.Color{ 0 }
  self:Test(c.r, 0)
  self:Test(c.g, 0)
  self:Test(c.b, 0)
  self:Test(c.a, 0)
  self:Test(c.v, 0)

  c.r = 0xFF
  self:Test(c.r, 0xFF)
  self:Test(c.g, 0)
  self:Test(c.b, 0)
  self:Test(c.a, 0)
  self:Test(c.v, 0x00FF0000)

  c.g = 0xFF
  c.b = 0xFF
  c.a = 0xFF
  self:Test(c.r, 0xFF)
  self:Test(c.g, 0xFF)
  self:Test(c.b, 0xFF)
  self:Test(c.a, 0xFF)
  self:Test(c.v, 0xFFFFFFFF)

  c.r = 0x34
  c.g = 0x56
  c.b = 0x78
  c.a = 0x12
  self:Test(c.r, 0x34)
  self:Test(c.g, 0x56)
  self:Test(c.b, 0x78)
  self:Test(c.a, 0x12)
  self:Test(c.v, 0x12345678)
  
  var c2 = F.Color { 0x12345678 }
  self:Test(c2.r, 0x34)
  self:Test(c2.g, 0x56)
  self:Test(c2.b, 0x78)
  self:Test(c2.a, 0x12)
  self:Test(c2.v, 0x12345678)
end

local TestEnum = Enum{
  "First",
  "second",
  "THIRD",
}

terra TestHarness:enum()
  self:Test(TestEnum.First.v, 0)
  self:Test(TestEnum.second.v, 1)
  self:Test(TestEnum.THIRD.v, 2)

  var e : TestEnum = TestEnum.First
  self:Test(e.v, 0)
  e.v = 0
  e = TestEnum.second
  e.v = 1
  self:Test(e.v, 1)
  e = TestEnum.THIRD
  self:Test(e.v, 2)
  e.v = 2
  self:Test(e, TestEnum.THIRD)
end

local TestFlags = Flags{
  "First",
  "second",
  "THIRD",
}

terra TestHarness:flags()
  self:Test(TestFlags.First.val, 1)
  self:Test(TestFlags.second.val, 2)
  self:Test(TestFlags.THIRD.val, 4)
  var f = TestFlags.First + TestFlags.THIRD
  self:Test(f.First and f.second, false)
  self:Test(f.First, true)
  self:Test(not f.second, true)
  self:Test(f.THIRD, true)
  f.THIRD = false
  f.second = true
  self:Test(f.First and f.second, true)
  self:Test(f.First and f.second and not f.THIRD, true)
end

terra TestHarness:hash()

end

terra TestHarness:message()

end

terra TestHarness:rect()
  var a = F.Rect{array(1f,2f,3f,4f)}
  self:Test(a.l, 1)
  self:Test(a.t, 2)
  self:Test(a.r, 3)
  self:Test(a.b, 4)
  self:Test(a.left, 1)
  self:Test(a.top, 2)
  self:Test(a.right, 3)
  self:Test(a.bottom, 4)
  self:Test(a.data[0], 1)
  self:Test(a.data[1], 2)
  self:Test(a.data[2], 3)
  self:Test(a.data[3], 4)

  var b = F.Rect{array(5f,6f,7f,8f)}
  var c = a + b
  self:Test(c.l, 6f)
  self:Test(c.t, 8f)
  self:Test(c.r, 10f)
  self:Test(c.b, 12f)
  c = b - a
  self:Test(c.l, 4f)
  self:Test(c.t, 4f)
  self:Test(c.r, 4f)
  self:Test(c.b, 4f)
  c = a - b
  self:Test(c.l, -4f)
  self:Test(c.t, -4f)
  self:Test(c.r, -4f)
  self:Test(c.b, -4f)
  c = b * a
  self:Test(c.l, 5f)
  self:Test(c.t, 12f)
  self:Test(c.r, 21f)
  self:Test(c.b, 32f)
  c = b / a
  self:Test(c.l, 5f)
  self:Test(c.t, 3f)
  self:Test(c.r, (7f/3f))
  self:Test(c.b, 2f)

  c = a + 1f
  self:Test(c.l, 2f)
  self:Test(c.t, 3f)
  self:Test(c.r, 4f)
  self:Test(c.b, 5f)
  c = 1f + a
  self:Test(c.l, 2f)
  self:Test(c.t, 3f)
  self:Test(c.r, 4f)
  self:Test(c.b, 5f)
  c = 2f * a
  self:Test(c.l, 2f)
  self:Test(c.t, 4f)
  self:Test(c.r, 6f)
  self:Test(c.b, 8f)

  var d = a.topleft + b.bottomright
  self:Test(d.x, 8)
  self:Test(d.y, 10)

  self:Test(a, b, "__ne")
  self:Test(a, a)
  self:Test(a == b, false)
end

terra TestHarness:vec()
  var a = F.Veci{array(1,2)}
  self:Test(a.x, 1)
  self:Test(a.y, 2)
  self:Test(a.v[0], 1)
  self:Test(a.v[1], 2)
  a.x = 5
  a.y = 6
  self:Test(a.x, 5)
  self:Test(a.y, 6)

  var b = F.Veci{array(-3,-4)}
  var c = a + b
  self:Test(c.x, 2)
  self:Test(c.y, 2)
  c = a - b
  self:Test(c.x, 8)
  self:Test(c.y, 10)
  c = a * b
  self:Test(c.x, -15)
  self:Test(c.y, -24)
  a.x = 1
  a.y = 2
  c = b / a
  self:Test(c.x, -3)
  self:Test(c.y, -2)

  c = a + 3
  self:Test(c.x, 4)
  self:Test(c.y, 5)

  c = 4 - b
  self:Test(c.x, 7)
  self:Test(c.y, 8)

  self:Test(a, b, "__ne")
  b.x = a.x
  b.y = a.y
  self:Test(a, b)
end

do
  local primitives = List{int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, bool, function() end,
    float, double, tuple(), tuple(int, float), int32[8], vector(float, 4), "string", 3.14, {}, {"fake"}, `6, `3.2,
    &float, &&float }

  local constraints = { Constraint.Number, Constraint.String, Constraint.Table, Constraint.LuaValue, Constraint.TerraType,
    Constraint.Field, Constraint.Method, Constraint.Integral, Constraint.Float, Constraint.Pointer, Constraint.Type,
    Constraint.Value, Constraint.Empty, Constraint.BasicConstraint, function(e) return Constraint.BasicConstraint(e, true) end }

  local function testconstraint(target, pred)
    local f = function(v) 
      local ok, err = pcall(target, v)
      if ok ~= pred(v) then
        error ("Expected "..tostring(target).." to return "..tostring(pred(v)).." for "..tostring(v).." but got "..tostring(ok))
      end
    end
    primitives:app(f)
    f(nil)
  end
  
  testconstraint(Constraint.TerraType, function(v) return terralib.types.istype(v) end)
  testconstraint(Constraint.Number, function(v) return type(v) == "number" end)
  testconstraint(Constraint.String, function(v) return type(v) == "string" end)
  testconstraint(Constraint.Table, function(v) return type(v) == "table" end)
  testconstraint(Constraint.LuaValue, function(v) return v ~= nil end)
  testconstraint(Constraint.Integral, function(v) return terralib.types.istype(v) and v:isintegral() end)
  testconstraint(Constraint.Float, function(v) return terralib.types.istype(v) and v:isfloat() end)
  testconstraint(Constraint.Pointer(float, 0), function(v) return v == float end)
  testconstraint(Constraint.Pointer(float), function(v) return v == &float end)
  testconstraint(Constraint.Pointer(float, 2), function(v) return v == &&float end)
  testconstraint(Constraint.Type(Constraint.Integral), function(v) return terralib.types.istype(v) and v:isintegral() end)
  testconstraint(Constraint.Value(Constraint.Integral), function(v) return type(v) == "table" and v.gettype ~= nil and v:gettype():isintegral() end)
  testconstraint(Constraint.Empty, function(v) return v == nil end)
  testconstraint(Constraint.BasicConstraint(uint8), function(v) return v == uint8 end)
  testconstraint(Constraint.BasicConstraint(int8, true), function(v) return v == bool or (terralib.types.istype(v) and v:isarithmetic()) end)

  local function testfunction(params, ret, vararg, expected, fn) 
    local ok, err = pcall(Constraint.Function(params, ret, vararg), fn)
    if ok ~= expected then
      error ("Expected "..tostring(expected).." but got "..tostring(ok).." for "..tostring(params).." : "..tostring(ret))
    end
  end

  testfunction({}, nil, nil, true, terra() end)
  testfunction({}, tuple(), nil, true, terra() end)
  testfunction({}, nil, Constraint.Integral, true, terra() end)
  testfunction({}, nil, nil, true, Constraint.Meta({}, nil, function() end))
  testfunction({}, tuple(), nil, true, Constraint.Meta({}, nil, function() end))
  testfunction({}, nil, Constraint.Integral, true, Constraint.Meta({}, nil, function() end))
  testfunction({}, nil, nil, true, Constraint.Meta({}, tuple(), function() end))
  
  local primtypes = primitives:filter(function(e) return terralib.types.istype(e) end)
  primtypes:app(function(e) return testfunction({e}, nil, nil, true, Constraint.Meta({e}, nil, function() end)) end)
  primtypes:app(function(e) return testfunction({bool}, nil, nil, e == bool, Constraint.Meta({e}, nil, function() end)) end)
  primtypes:app(function(e) return testfunction({bool}, nil, nil, e == bool, terra(asdf: e) end) end)
  
  primtypes:app(function(e) return testfunction({}, e, nil, true, Constraint.Meta({}, e, function() end)) end)
  primtypes:app(function(e) return testfunction({}, bool, nil, e == bool, Constraint.Meta({}, e, function() end)) end)
  primtypes:app(function(e) return testfunction({e}, e, nil, true, Constraint.Meta({e}, e, function() end)) end)
  primtypes:app(function(e) return testfunction({e}, e, nil, true, terra(asdf: e) : e end) end)
  primtypes:app(function(e) return testfunction({bool}, bool, nil, e == bool, Constraint.Meta({e}, e, function() end)) end)
  primtypes:app(function(e) return testfunction({bool}, bool, nil, e == bool, terra(asdf: e) : e end) end)

  testfunction({int, int}, int, nil, false, Constraint.Meta({int}, int, function() end))
  testfunction({int, int}, int, nil, false, Constraint.Meta({int, int}, nil, function() end))
  testfunction({int, int}, int, nil, false, Constraint.Meta({}, int, function() end))
  testfunction({}, int, nil, false, Constraint.Meta({int}, int, function() end))
  testfunction({int}, nil, nil, false, Constraint.Meta({int}, int, function() end))
  testfunction({int, int}, int, nil, false, terra(asdf: int) : int end)
  testfunction({int, int}, int, nil, false, terra(asdf: int, a: int) : {} end)
  testfunction({int, int}, int, nil, false, terra() : int end)
  testfunction({}, int, nil, false, terra(asdf: int) : int end)
  testfunction({int}, nil, nil, false, terra(asdf: int) : int end)
  testfunction({int}, {int, int}, nil, false, terra(asdf: int) : int end)

  primtypes:app(function(e) return testfunction({e, e}, e, nil, true, terra(a: e, b: e) : e end) end)
  primtypes:app(function(e) return testfunction({e, e}, e, nil, true, Constraint.Meta({e, e}, e, function() end)) end)
  primtypes:app(function(e) return testfunction({e, e}, {e, e}, nil, true, terra(a: e, b: e) : {e, e} end) end)

  local function testmethod(params, ret, static, vararg, expected, fn, name)
    name = name or "foobar"
    local s = fn
    if not s.isstruct or not s:isstruct() then
      s = struct{}
      s.methods[name] = fn
    end
    local ok, err = pcall(Constraint.MethodConstraint(name, params, ret, static, vararg), s)
    if ok ~= expected then
      error ("Expected "..tostring(expected).." but got "..tostring(ok).." for "..tostring(params).." : "..tostring(ret))
    end
  end

  function expect(constraint, expect, ...)
    local ok, err = pcall(constraint, ...)
    if ok ~= expect then
      error ("Expected "..tostring(constraint).." to return "..tostring(expect).." for "..tostring(unpack({...})).." but got "..tostring(ok))
    end
  end

  testmethod({}, nil, true, nil, true, terra() end)
  testmethod({}, tuple(), true, nil, true, terra() end)
  testmethod({}, nil, true, Constraint.Integral, true, terra() end)
  testmethod({}, nil, true, nil, true, Constraint.Meta({}, nil, function() end))
  testmethod({}, tuple(), true, nil, true, Constraint.Meta({}, nil, function() end))
  testmethod({}, nil, true, Constraint.Integral, true, Constraint.Meta({}, nil, function() end))
  testmethod({}, nil, true, nil, true, Constraint.Meta({}, tuple(), function() end))

  testmethod({}, nil, true, nil, false, terra(self : int) end)
  testmethod({}, nil, true, nil, false, Constraint.Meta({int}, tuple(), function() end))
  testmethod({}, nil, false, nil, false, terra() end)
  testmethod({}, nil, false, nil, false, Constraint.Meta({}, tuple(), function() end))

  local fiddle = struct{ foobar : float, meta : bool }
  fiddle.methods["terra"] = terra(self : &fiddle) : {} end
  fiddle.methods["ret"] = terra(self : &fiddle) : int end
  fiddle.methods["param"] = terra(self : &fiddle, a : int) : int end
  fiddle.methods["meta"] = Constraint.MetaMethod(fiddle, {}, tuple(), function(self) end)
  fiddle.methods["metaret"] = Constraint.MetaMethod(fiddle, {}, int, function(self) end)
  fiddle.methods["metaparam"] = Constraint.MetaMethod(fiddle, {int}, int, function(self) end)
  
  testmethod({}, nil, false, nil, true, fiddle, "terra")
  testmethod({}, int, false, nil, true, fiddle, "ret")
  testmethod({int}, int, false, nil, true, fiddle, "param")
  testmethod({}, nil, false, nil, true, fiddle, "meta")
  testmethod({}, int, false, nil, true, fiddle, "metaret")
  testmethod({int}, int, false, nil, true, fiddle, "metaparam")
  testmethod({}, int, false, nil, false, fiddle, "metaparam")

  expect(Constraint.Negative("terra", false), true, fiddle)
  List{"foobar", "asdf", ""}:app(function(s) expect(Constraint.Negative(s, true), true, fiddle) end)

  primtypes:app(function(e) return expect(Constraint.Field("meta", e), e == bool, fiddle) end)
  expect(Constraint.Field("foobar", Constraint.Float), true, fiddle)

  local nested = struct{ f : fiddle }

  expect(Constraint.Field("f", Constraint.MakeConstraint(fiddle)), true, nested)
  expect(Constraint.Field("f", Constraint.Field("foobar", float) * Constraint.Field("meta", bool)), true, nested)
  expect(Constraint.Field("f", Constraint.MakeConstraint(float)), false, nested)
  expect(Constraint.Field("f", Constraint.Field("foobar", int) * Constraint.Field("meta", bool)), false, nested)

  testfunction({Constraint.Type(int)}, nil, nil, true, Constraint.Meta({Constraint.Type(int)}, nil, function(a) end))
  testfunction({Constraint.Type(int)}, nil, nil, false, Constraint.Meta({int}, nil, function(a) end))
  testfunction({}, Constraint.Type(int64), nil, true, Constraint.Meta({}, Constraint.Type(int64), function() return int64 end))
  testfunction({}, Constraint.Type(int64), nil, false, Constraint.Meta({}, int64, function() return int64 end))
  
  local topointer = Constraint(function(a) return Constraint.Meta({Constraint.Pointer(a, 0)}, Constraint.Pointer(a, 1), function(e) return `&[e] end) end, Constraint.TerraType)
  expect(topointer, true, quote var a : int = 3 in a end)
  expect(topointer, true, quote var a : bool = true in a end)
  expect(topointer:Types(int), true, quote var a : int = 3 in a end)
  expect(topointer:Types(float), false, quote var a : int = 3 in a end)

  local inner = terra(a : int) : int return a end
  local innerbad = terra(a : float) : int return a end
  local wrap = Constraint.Meta({Constraint.Number, Constraint.Function({int}, int)}, Constraint.Number, function(a, b) return b(a) end)
  expect(wrap, true, 3, inner)
  expect(wrap, false, `3, inner)
  expect(wrap, false, 3, innerbad)

  local nest = Constraint.Meta({Constraint.Number, Constraint.Function({int}, int), Constraint.Function({Constraint.Number, Constraint.Function({int}, int)}, Constraint.Number)}, Constraint.Number, function(a, b, c) return c(a, b) end)
  expect(nest, true, 3, inner, wrap)
  expect(nest, false, 3, wrap, wrap)
  expect(nest, false, 3, inner, inner)
  expect(nest, false, `3, inner, wrap)
  expect(nest, false, 3, 3, wrap)
  expect(nest, false, 3, inner, 3)
  expect(nest, false, 3, innerbad, wrap)

  expect(nest, true, 3, macro(function(a) return a end, function(a) return a end), wrap)

  expect(Constraint.Negative("f") + Constraint.Field("f", Constraint.Field("foobar", float) * Constraint.Field("meta", bool)), true, nested)
  expect(Constraint.Negative("f") + Constraint.Field("f2", Constraint.Field("foobar", float) * Constraint.Field("meta", bool)), false, nested)
  expect(Constraint.Negative("f") + Constraint.Field("f", Constraint.Field("foobar", int) * Constraint.Field("meta", bool)), false, nested)
  expect(Constraint.Negative("f") + Constraint.Field("f2", Constraint.Field("foobar", float) * Constraint.Field("meta", bool)), false, nested)
  --local nest = Constraint.Meta(Constraint.Number, Constraint.Function({Constraint.Number, Constraint.Function({int}, int)}, Constraint.Number), function(a, b) return b(a, inner) end)
  
  local opt = Constraint.Meta({Constraint.Empty + Constraint.Number}, Constraint.Number, function(a) return 3 end)
  expect(opt, true, 2)
  expect(opt, true)
  expect(opt, false, 2, 2)

  local opt2 = Constraint.Meta({Constraint.Empty + Constraint.Number}, Constraint.Empty + Constraint.Number, function(a) return a end)
  expect(opt2, true, 2)
  expect(opt2, true)
  expect(opt2, false, 2, 2)

  expect(Constraint.Meta({Constraint.Empty + Constraint.String}, Constraint.Empty + Constraint.String, function(a) return a end), true, "asdf")

  fiddle.methods["over"] = terralib.overloadedfunction("overload", { terra(self: &fiddle, s : int) : int return s end, terra(self: &fiddle, s : rawstring) : rawstring return s end })
  testmethod({int}, int, false, nil, true, fiddle, "over")
  testmethod({rawstring}, rawstring, false, nil, true, fiddle, "over")
  testmethod({rawstring}, int, false, nil, false, fiddle, "over")
  testmethod({Constraint.Value(rawstring) + int}, int, false, nil, true, fiddle, "over")
  testmethod({Constraint.Empty + int}, int, false, nil, true, fiddle, "over")
  testmethod({Constraint.Empty + int}, rawstring, false, nil, false, fiddle, "over")

  expect(Constraint.IsConstraint, true, Constraint.IsConstraint)
  expect(Constraint.IsConstraint, false, {})
end

local ObjectTest = struct{ i : bool, d : bool }
terra ObjectTest:init()
  Object._init(self, { true, false })
end
terra ObjectTest:destruct()
  self.d = true
end

terra TestHarness:object()
  var obj : ObjectTest = ObjectTest{ false, false }
  self:Test(obj.i, false)
  self:Test(obj.d, false)

  Object.init(obj)
  self:Test(obj.i, true)
  self:Test(obj.d, false)

  Object.destruct(obj)
  self:Test(obj.i, true)
  self:Test(obj.d, true)
end

local SUBTESTLEN = 11

local terra PrintColumns(a : rawstring, b : rawstring, c : rawstring) : {}
  C.printf("%-*s %-*s %-*s\n", 24, a, [SUBTESTLEN], b, 8, c);
end

local T = {}

terra T.main(argc : int, argv : &rawstring) : int
  C.printf("Feather v%i.%i.%i Test Utility\n\n", [F.Version[1]], [F.Version[2]], [F.Version[3]])

  var harness = TestHarness{ }
  
  PrintColumns("Internal Tests", "Subtests", "Pass/Fail")
  PrintColumns("--------------", "--------", "---------")

  escape 
    for k, v in pairs(TestHarness.methods) do
      if not terralib.ismacro(v) then
        emit(quote
          harness.passed, harness.total = 0, 0
          harness:[k]()
          var buf : int8[SUBTESTLEN + 1]
          C.snprintf(buf, [SUBTESTLEN + 1], "%u/%u", harness.passed, harness.total);
          PrintColumns(k, buf, terralib.select(harness.passed == harness.total, "PASS", "FAIL"))
        end)
      end
    end
  end

  return 0;
end

return T
