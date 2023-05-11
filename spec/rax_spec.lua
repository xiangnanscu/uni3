describe("rax api:", function()
  it("insert one row statement only", function()
    local radix = require("xodel.router")
    local rx = radix.new({
      { path = { "/user/:name/age/#age" }, handler = "/user/:name/age/:age", method = { 'GET', 'POST' } },
      { path = { "/user/:name" },          handler = "/user/:name" }
    })
    rx:insert("/hello", { handler = "/hello", method = 'GET' })
    -- test matching
    assert.are.same({ nil, "method not allowed", 405 }, { rx:match("/hello") })
    local data, matched = rx:match("/user/xiangnan/age/22", "GET")
    assert.are.same(data, "/user/:name/age/:age")
    assert.are.same(matched, { name = "xiangnan", age = "22" })
    -- ngx.say(rx:match("/user/xiangnan/age/22", "PUT"))
    -- ngx.say(rx:match("/user/xiangnan/age/not_matched", "GET"))
  end)
  it("test prefix match", function()
    local radix = require("xodel.router")
    local rx = radix.new({
      { path = { "/user*" },            handler = "/user*" },
      { path = { "/name/*" },           handler = "/name/*" },
      { path = { "/bar/*rest" },        handler = "/bar/*rest" },
      { path = { "/foo/*/rest" },       handler = "/foo/*/rest" },
      { path = { "/baz/*middle/rest" }, handler = "/baz/*middle/rest" }
    })
    -- test matching
    assert.are.same(rx:match("/user"), "/user*")
    assert.are.same(rx:match("/user2"), "/user*")
    assert.are.same(rx:match("/user/bar"), "/user*")
    assert.are.same(rx:match("/user/"), "/user*")
    assert.are.same(rx:match("/name/"), "/name/*")
    assert.are.same(rx:match("/name/1"), "/name/*")
    assert.are.same(rx:match("/name"), nil)
    assert.are.same({ rx:match("/bar/123/456") }, { "/bar/*rest", { rest = "123/456" } })
    assert.are.same(rx:match("/foo/1/rest"), "/foo/*/rest")
    assert.are.same(rx:match("/foo/1/aest"), nil)
    assert.are.same(rx:match("/foo/rest"), nil)
    assert.are.same(rx:match("/foo"), nil)
    assert.are.same({ rx:match("/foo/1/rest") }, { "/foo/*/rest", { [':ext'] = '1' } })
    assert.are.same({ rx:match("/foo//rest") }, { "/foo/*/rest", { [':ext'] = '' } })
    assert.are.same({ rx:match("/foo/x/y/z/rest") }, { "/foo/*/rest", { [':ext'] = 'x/y/z' } })
    assert.are.same({ rx:match("/baz/x/y/z/rest") }, { "/baz/*middle/rest", { middle = 'x/y/z' } })
  end)
  -- it("test special match", function()
  --   local radix = require("xodel.router")
  --   local utils = require("xodel.utils")
  --   local rx = radix.new({
  --     { path = "/foo*bar/:arg", handler = "/foo*bar/:arg" },
  --   })
  --   print(utils.repr(rx))
  --   assert.are.same({ rx:match("/foo*bar/:arg") }, { "/foo*bar/:arg", { arg = 'ok' } })
  -- end)
end)
