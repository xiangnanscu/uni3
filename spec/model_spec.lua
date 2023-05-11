local utils = require("xodel.utils")
local models = require("models")()
local repr = require "xodel.repr"
local array = require "xodel.array"

-- https://github.com/lunarmodules/busted/tree/master/busted/outputHandlers
local LINE = array:new():fill('_', 1, 80):join("")
local function loger(...)
  for _, o in pairs { ... } do
    print(LINE)
    print(repr(o))
  end
end

-- loger(utils.getenv())
_G.loger = loger
local function eval(s, ctx)
  -- print(LINE)
  print(s)
  local res = { utils.eval(s, utils.dict(models, ctx)) }
  if type(res[1]) == 'string' then
    print('  ', res[1])
  end
  return unpack(res)
end

-- assert.are.same({ table = "great" }, { table = "great" })
-- assert.are_not.equal({ table = "great" }, { table = "great" })
-- assert.truthy("this is a string") -- truthy: not false or nil
-- assert.True(1 == 1)
-- assert.is_true(1 == 1)
-- assert.falsy(nil)
-- assert.has_error(function() error("Wat") end, "Wat")
describe("Xodel api:", function()
  it("insert one row statement only", function()
    local res = eval [[usr:insert({email='1@qq.com', name='u1'}, {'name', 'email'}):statement()]]
    assert.are.same(res, [[INSERT INTO usr (name, email) VALUES ('u1', '1@qq.com')]])
  end)
  it("insert one row", function()
    local res = eval [[usr:insert{email='1@qq.com', name='u1'}:exec()]]
    assert.are.same(res, { affected_rows = 1 })
  end)
  it("insert one row returning a column", function()
    local res = eval [[usr:insert{email='6@qq.com', name='u6'}:returning("id"):exec()]]
    assert.are.same(res, { { id = 2 }, affected_rows = 1 })
  end)
  it("insert one row returning a compact column", function()
    local res = eval [[usr:insert{email='9@qq.com', name='u9'}:returning("id"):compact():exec()]]
    assert.are.same(res, { { 3 }, affected_rows = 1 })
  end)
  it("insert one row returning two columns", function()
    local res = eval [[usr:insert{email='7@qq.com', name='u7'}:returning("email", "name"):exec()]]
    assert.are.same(res, { { name = 'u7', email = '7@qq.com' }, affected_rows = 1 })
  end)
  it("insert one row returning two compact columns", function()
    local res = eval [[usr:insert{email='10@qq.com', name='u10'}:returning("email", "name"):compact():exec()]]
    assert.are.same(res, { { '10@qq.com', 'u10' }, affected_rows = 1 })
  end)
  it("insert multiple rows", function()
    local res = eval [[usr:insert{{email='2@qq.com', name='u2'},{email='3@qq.com', name='u3'}}:exec()]]
    assert.are.same(res, { affected_rows = 2 })
  end)
  it("insert multiple rows returning a column", function()
    local res = eval [[usr:insert{{email='11@qq.com', name='u11'},{email='12@qq.com', name='u12'}}:returning("name"):exec()]]
    assert.are.same(res, { { name = 'u11' }, { name = 'u12' }, affected_rows = 2 })
  end)
  it("insert multiple rows returning two columns", function()
    local res = eval [[usr:insert{{email='13@qq.com', name='u13'},{email='14@qq.com', name='u14'}}:returning("name", "email"):exec()]]
    assert.are.same(res,
      { { name = 'u13', email = '13@qq.com' }, { name = 'u14', email = '14@qq.com' }, affected_rows = 2 })
  end)
  it("insert multiple rows returning a compact column", function()
    local res = eval [[usr:insert{{email='15@qq.com', name='u15'},{email='16@qq.com', name='u16'}}:returning("name"):compact():exec()]]
    assert.are.same(res, { { 'u15' }, { 'u16' }, affected_rows = 2 })
  end)
  it("insert multiple rows returning two compact columns", function()
    local res = eval [[usr:insert{{email='17@qq.com', name='u17'},{email='18@qq.com', name='u18'}}:returning("name", "email"):compact():exec()]]
    assert.are.same(res,
      { { 'u17', '17@qq.com' }, { 'u18', '18@qq.com' }, affected_rows = 2 })
  end)
  it("merge multiple rows returning a default column for created rows", function()
    local res = eval [[usr:merge({{email='4@qq.com', name='u4'},{email='3@qq.com', name='u3'}}, 'name')]]
    assert.are.same(res, { { 'u4' }, affected_rows = 1, })
  end)
  it("merge multiple rows returning a specified column for created rows", function()
    local res = eval [[usr:returning("email"):merge({{email='4@qq.com', name='u4'},{email='5@qq.com', name='u5'}}, 'name')]]
    assert.are.same(res, { { '5@qq.com' }, affected_rows = 1, })
  end)
  it("merge multiple rows returning specified columns for created rows", function()
    local res = eval [[usr:returning("email", "name"):merge({{email='19@qq.com', name='u19'},{email='20@qq.com', name='u20'}}, 'name')]]
    assert.are.same(res, { { '19@qq.com', 'u19' }, { '20@qq.com', 'u20' }, affected_rows = 2, })
  end)
  it("upsert multiple rows returning a default column for created rows", function()
    local res = eval [[usr:upsert({{email='21@qq.com', name='u21'},{email='22@qq.com', name='u22'}}, 'email')]]
    assert.are.same(res, { { '21@qq.com' }, { '22@qq.com' }, affected_rows = 2, })
  end)
  it("upsert multiple rows returning a specified column for created rows", function()
    local res = eval [[usr:returning("email"):upsert({{email='4@qq.com', name='u4'},{email='23@qq.com', name='u23'}}, 'email')]]
    assert.are.same(res, { { '4@qq.com' }, { '23@qq.com' }, affected_rows = 2, })
  end)
  it("upsert multiple rows returning specified columns for created rows", function()
    local res = eval [[usr:returning("email", "name"):upsert({{email='24@qq.com', name='u24'},{email='25@qq.com', name='u25'}}, 'email')]]
    assert.are.same(res, { { '24@qq.com', 'u24' }, { '25@qq.com', 'u25' }, affected_rows = 2, })
  end)
  it("insert one row with default", function()
    local res = eval [[usr:insert({email='26@qq.com'}, {'name', 'email'}):returning("name"):exec()]]
    local name_default = models.usr.fields.name.default
    assert.are.same(res, { { name = name_default }, affected_rows = 1 })
  end)
  it("insert multiple rows with default", function()
    local res = eval [[usr:insert({{email='27@qq.com'},{email='28@qq.com'}}, {'name', 'email'}):returning("name"):exec()]]
    local name_default = models.usr.fields.name.default
    assert.are.same(res, { { name = name_default }, { name = name_default }, affected_rows = 2 })
  end)
  it("insert multiple rows with default compact", function()
    local res = eval [[usr:insert({{email='29@qq.com'},{email='30@qq.com'}}, {'name', 'email'}):returning("name"):compact():exec()]]
    local name_default = models.usr.fields.name.default
    assert.are.same(res, { { name_default }, { name_default }, affected_rows = 2 })
  end)
  local wu, u1
  it("where by one table", function()
    wu = eval [[usr:where{email='1@qq.com'}:exec()]]
    assert.are.same(wu, { { id = 1, name = 'u1', email = '1@qq.com', views = 0 } })
  end)
  it("where or statement", function()
    local statement = eval [[usr:where_or{email='1@qq.com', name='u1'}:statement()]]
    assert(statement == [[SELECT * FROM usr WHERE usr.email = '1@qq.com' OR usr.name = 'u1']] or
      statement == [[SELECT * FROM usr WHERE usr.name = 'u1' OR usr.email = '1@qq.com']])
  end)
  it("save instance from array returned from where", function()
    u1 = wu[1]
    u1.name = 'wow'
    local saved = eval([[u1:save()]], { u1 = u1 })
    assert.are.same(saved, { id = 1, name = 'wow', email = '1@qq.com', views = 0 })
  end)
  it("get", function()
    local u = eval [[usr:get{email='1@qq.com'}]]
    assert.are.same("wow", u.name)
  end)
  it("where by two strings", function()
    local res = eval [[usr:where('email','1@qq.com'):exec()]]
    assert.are.same(res, { { id = 1, name = 'wow', email = '1@qq.com', views = 0 } })
  end)
  it("where by three strings", function()
    local res = eval [[usr:where('email','=','1@qq.com'):exec()]]
    assert.are.same(res, { { id = 1, name = 'wow', email = '1@qq.com', views = 0 } })
  end)
  it("where api equals", function()
    assert.are.same(
      models.usr:where('email', '1@qq.com'):statement(),
      models.usr:where('email', '=', '1@qq.com'):statement(),
      models.usr:where { 'email', '1@qq.com' }:statement()
    )
  end)
  local ops = { lt = "<", lte = "<=", gt = ">", gte = ">=", ne = "<>", eq = "=" }
  for key, op in pairs(ops) do
    it("where key number operator " .. key, function()
      local statement = eval(string.format([[usr:where{id__%s=2}:statement()]], key))
      assert.are.same(statement, string.format([[SELECT * FROM usr WHERE usr.id %s 2]], op))
    end)
  end
  it("where eq", function()
    local res = eval [[usr:where{name__eq='u1'}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name = 'u1']])
  end)
  it("where in", function()
    local res = eval [[usr:where{name__in={'u1','u2'}}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name IN ('u1', 'u2')]])
  end)
  it("where contains", function()
    local res = eval [[usr:where{name__contains='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name LIKE '%u%']])
  end)
  it("where startswith", function()
    local res = eval [[usr:where{name__startswith='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name LIKE 'u%']])
  end)
  it("where endswith", function()
    local res = eval [[usr:where{name__endswith='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name LIKE '%u']])
  end)
  it("where null true", function()
    local res = eval [[usr:where{name__null=true}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name IS NULL]])
  end)
  it("where null false", function()
    local res = eval [[usr:where{name__null=false}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name IS NOT NULL]])
  end)
  it("where notin", function()
    local res = eval [[usr:where{name__notin={'u1','u2'}}:statement()]]
    assert.are.same(res, [[SELECT * FROM usr WHERE usr.name NOT IN ('u1', 'u2')]])
  end)
  it("create with foreign model default returning", function()
    local u = models.usr:get { id = 1 }
    local res = eval([[profile:create{usr_id=u}]], { u = u })
    assert.are.same(res, { affected_rows = 1 })
  end)
  it("where foreignkey eq", function()
    local res = eval [[profile:where{usr_id__name__eq='u1'}:statement()]]
    assert.are.same(res, [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name = 'u1']])
  end)
  it("where foreignkey in", function()
    local res = eval [[profile:where{usr_id__name__in={'u1','u2'}}:statement()]]
    assert.are.same(res,
      [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name IN ('u1', 'u2')]])
  end)
  it("where foreignkey contains", function()
    local res = eval [[profile:where{usr_id__name__contains='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name LIKE '%u%']])
  end)
  it("where foreignkey startswith", function()
    local res = eval [[profile:where{usr_id__name__startswith='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name LIKE 'u%']])
  end)
  it("where foreignkey endswith", function()
    local res = eval [[profile:where{usr_id__name__endswith='u'}:statement()]]
    assert.are.same(res, [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name LIKE '%u']])
  end)
  it("where foreignkey null true", function()
    local res = eval [[profile:where{usr_id__name__null=true}:statement()]]
    assert.are.same(res, [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name IS NULL]])
  end)
  it("where foreignkey null false", function()
    local res = eval [[profile:where{usr_id__name__null=false}:statement()]]
    assert.are.same(res,
      [[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.name IS NOT NULL]])
  end)
  for key, op in pairs(ops) do
    it("where foreignkey number operator " .. key, function()
      local statement = eval(string.format([[profile:where{usr_id__views__%s=2}:statement()]], key))
      assert.are.same(statement,
        string.format([[SELECT * FROM profile INNER JOIN usr T1 ON (profile.usr_id = T1.id) WHERE T1.views %s 2]], op))
    end)
  end
  it("where exists", function()
    local statement = eval [[usr:where_exists(usr:where{id=1}):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE EXISTS (SELECT * FROM usr WHERE usr.id = 1)')
  end)
  it("where null", function()
    local statement = eval [[usr:where_null("name"):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE usr.name IS NULL')
  end)
  it("where in", function()
    local statement = eval [[usr:where_in("id", {1,2,3}):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE (usr.id) IN (1, 2, 3)')
  end)
  it("where between", function()
    local statement = eval [[usr:where_between("id", 2, 4):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE usr.id BETWEEN 2 AND 4')
  end)
  it("where not", function()
    local statement = eval [[usr:where_not("name", "foo"):statement()]]
    assert.are.same(statement, "SELECT * FROM usr WHERE NOT (usr.name = 'foo')")
  end)
  it("where not null", function()
    local statement = eval [[usr:where_not_null("name"):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE usr.name IS NOT NULL')
  end)
  it("where not in", function()
    local statement = eval [[usr:where_not_in("id", {1,2,3}):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE (usr.id) NOT IN (1, 2, 3)')
  end)
  it("where not between", function()
    local statement = eval [[usr:where_not_between("id", 2, 4):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE usr.id NOT BETWEEN 2 AND 4')
  end)
  it("where not exists", function()
    local statement = eval [[usr:where_not_exists(usr:where{id=1}):statement()]]
    assert.are.same(statement, 'SELECT * FROM usr WHERE NOT EXISTS (SELECT * FROM usr WHERE usr.id = 1)')
  end)
  it("update by where", function()
    local res = eval [[usr:update{views=10}:where("id", 1):exec()]]
    assert.are.same(res, { affected_rows = 1 })
    local u = models.usr:get { id = 1 }
    assert.are.same(u.views, 10)
  end)
  it("update by where with foreignkey", function()
    local u = models.profile:get { usr_id__name__contains = 'wow' }
    assert.are.same(u.sex, 'f')
    local res = eval [[profile:update{sex='m'}:where{usr_id__name__contains='wow'}:exec()]]
    assert.are.same(res, { affected_rows = 1 })
    local u = models.profile:get { usr_id__name__contains = 'wow' }
    assert.are.same(u.sex, 'm')
  end)
  it("updates partial", function()
    local res = eval [[usr:updates({{email='4@qq.com', name='u4'},{email='3@qq.com', name='??'}}, 'name')]]
    assert.are.same(res, { { 'u4' }, affected_rows = 1 })
  end)
  it("updates all", function()
    local res = eval [[usr:updates({{email='4@qq.com', name='u4'},{email='3@qq.com', name='u3'}}, 'name')]]
    assert.are.same(res, { { 'u3' }, { 'u4' }, affected_rows = 2 })
  end)
  it("model:all() and model:count()", function()
    local us = eval [[usr:all()]]
    local cnt = eval [[usr:count()]]
    assert.are.same(#us, cnt)
  end)
  local fu
  it("model load foreign row", function()
    local p = models.profile:get { id = 1 }
    fu = p.usr_id
    assert.are.same(fu, { id = 1 })
  end)
  it("fetch extra foreignkey field from database on demand", function()
    assert.are.same(fu.name, 'wow')
    assert.are.same(getmetatable(fu), models.usr.RecordClass)
  end)
  it("model load foreign row with specified columns", function()
    local p = eval [[profile:select("sex"):load_fk('usr_id', 'name', 'views'):get()]]
    assert.are.same(p, { sex = 'm', usr_id = { name = 'wow', views = 10 } })
  end)
  it("model load foreign row with all columns by *", function()
    local p = eval [[profile:select("sex"):load_fk('usr_id', '*'):get()]]
    local u = models.usr:get { id = p.usr_id.id }
    assert.are.same(p, { sex = 'm', usr_id = u })
  end)
  it("model load foreign row with specified columns two api are the same", function()
    local p1 = eval [[profile:select("sex"):load_fk('usr_id', 'name', 'views'):get()]]
    local p2 = eval [[profile:select("sex"):load_fk('usr_id', {'name', 'views'}):get()]]
    assert.are.same(p1, p2)
  end)
  local gu
  it("model instance get", function()
    gu = eval [[usr:get{name='wow'}]]
    assert.are.same(gu.name, 'wow')
  end)
  it("model instance save", function()
    gu.name = 'yoy'
    gu = eval([[gu:save()]], { gu = gu })
    assert.are.same(gu.name, 'yoy')
    gu = models.usr:get { id = gu.id }
    assert.are.same(gu.name, 'yoy')
  end)
  it("model instance save_update", function()
    gu.name = 'xxx'
    gu = eval([[gu:save()]], { gu = gu })
    local u = models.usr:get { id = gu.id }
    assert.are.same(u.name, 'xxx')
  end)
  it("model class save_create", function()
    local tmp = eval([[usr:save_create{name='tmp',email='tmp@qq.com'}]])
    local du = models.usr:get { name = 'tmp' }
    assert.are.same(tmp, du)
  end)
  it("model class delete", function()
    local res = eval([[usr:delete{email='tmp@qq.com'}:returning("name"):exec()]])
    assert.are.same(res, { { name = 'tmp' }, affected_rows = 1 })
  end)
  it("model instance save_create", function()
    local tmp = eval([[usr{name='tmp',email='tmp@qq.com'}:save_create()]])
    local du = models.usr:get { name = 'tmp' }
    assert.are.same(tmp, du)
  end)
  it("model instance delete", function()
    local du = models.usr:get { name = 'tmp' }
    local res = eval([[du:delete()]], { du = du })
    assert.are.same(res, { { id = du.id }, affected_rows = 1 })
  end)
  it("model get_or_create", function()
    local res, created = eval([[usr:get_or_create{email='tmp@qq.com'}]])
    assert.are.same(res, { email = 'tmp@qq.com', id = res.id })
    assert.are.same(created, true)
  end)
  it("model instance delete use non primary key", function()
    local du = models.usr:get { email = 'tmp@qq.com' }
    local res = eval([[du:delete('email')]], { du = du })
    assert.are.same(res, { { email = 'tmp@qq.com' }, affected_rows = 1 })
  end)
  it("model get_or_create with defaults", function()
    local res, created = eval([[usr:get_or_create({email='tmp@qq.com'}, {name='bar'})]])
    assert.are.same(res, { email = 'tmp@qq.com', id = res.id, name = 'bar' })
    assert.are.same(created, true)
  end)
  it("create with foreign model returning all", function()
    local u = models.usr:get { id = 1 }
    local res = eval([[profile:returning("*"):create{usr_id=u}]], { u = u })
    assert.are.same(res, { { id = 2, sex = 'f', usr_id = 1 }, affected_rows = 1 })
  end)
  it("test shortcuts join", function()
    local p = models.profile:join('usr_id'):select('usr.email'):get { id = 1 }
    assert.are.same(p, { email = '1@qq.com' })
  end)
  it("insert from delete returning", function()
    local name = '3@qq.com'
    local u = models.usr:get { email = name }
    local p = models.log:returning("*"):create(
      models.usr:delete { email = name }:returning('id'):returning_literal("usr", "delete"),
      { 'delete_id', 'model_name', "action" })
    assert.are.same(p[1].delete_id, u.id)
  end)
  it("insert from delete returning version 2", function()
    local name = '4@qq.com'
    local u = models.usr:get { email = name }
    local p = models.log:returning("*"):create(
      models.usr:delete { email = name }:returning('id', "'usr'", "'delete'"),
      { 'delete_id', 'model_name', "action" })
    assert.are.same(p[1].delete_id, u.id)
  end)
end)
