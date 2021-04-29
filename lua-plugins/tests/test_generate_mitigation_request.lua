local mitigation = require("../mitigation/mitigation")
require 'busted.runner'()
-- a trick to work around resty's limitations of modifying these variables in test
setmetatable(ngx,{status=0, arg={}})

describe("testing mitigation functions", function()
    before_each(function()
            ngx.var = {
                mitigation_api_key = "abc123",
                scheme = "https",
                http_host = "example.com",
                request_uri = "/hello",
                custom_fields = '{\"respond_bot\": \"true\"}',
                detection_tag_et = "10",
                detection_tag_mo = "2",
                remote_addr = "127.0.0.1"
            }
            ngx.req = {}
            ngx.ctx = {}
    end)
    -- todo: this is failing as converting to string does not produce same order.
    -- better to use the table version for comparison, however need to convert custom_fields to a comparable type
    -- going in as string, coming out as table
    --local expected = '{"client_ds":{"ip":"127.0.0.1","mo":"2","pd":"acc","custom":{"respond_bot":true},"url":"https:\\/\\/example.com\\/hello","et":"10"}}'
    describe("test generateRequestContent", function()
            it("respond_bot should be true", function()
                local request, err = mitigation.generate_mitigation_content({}, {})
                --assert.are.equal(tostring(json.encode(request)), expected)
                assert.are.equal(err, nil)
                assert.are.equal(request.client_ds.custom.respond_bot, "true")
            end)
    end)
end)