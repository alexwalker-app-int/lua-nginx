local mitigation = require("../mitigation/multipart")
local utils = require("mitigation/utils")
require 'busted.runner'()
setmetatable(ngx,{status=0, arg={}})
describe("testing multipart functions", function()
    describe("test header splitting", function()
        it("current field should be username", function()
            local res = {"Content-Disposition","form-data; name=\"username\"","Content-Disposition: form-data; name=\"username\""}
            local current_field, err = mitigation.handle_header(res)
            assert.are.equal(err, nil)
            assert.are.equal(current_field, "username")
        end)
    end)
    describe("test body rebuilding", function()
        it("current body should be hello", function()
            local res = "hello"
            local current_field = "place holder"
            local current_body = ""
            current_body, _ = mitigation.handle_body(current_field, current_body, res)
            --hello from multipart body
            assert.are.equal(err, nil)
            assert.are.equal(current_body, "hello")
        end)
    end)
    describe("test body rebuilding", function()
        it("current body should be hello", function()
            local res = "hello"
            local current_field = "place holder"
            local current_body = ""
            local fields = {}
            current_body, _ = mitigation.handle_body(current_field, current_body, res)
            fields, _ = mitigation.handle_part_end(fields, current_field, current_body)
            assert.are.equal(err, nil)
            assert.are.equal(fields[current_field], res)
        end)
    end)
end)
