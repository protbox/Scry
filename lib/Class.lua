local Class = {}
Class.__index = Class

-- initializer
function Class:new() end

function Class:extends()
  local cls = {}
  cls["__call"] = Class.__call
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end

function Class:is(obj)
  assert(obj, "Class:isa expects a class")
  assert(type(obj) == "table", "Parameter to Class:isa must be a table/class")
  local meta = getmetatable(self)
  while meta do
    if meta == obj then return true end
    meta = getmetatable(meta)
  end
  return false
end

-- create a new instance by calling Namespace()
function Class:__call(...)
  local inst = setmetatable({}, self)
  inst:new(...)
  return inst
end

return Class
