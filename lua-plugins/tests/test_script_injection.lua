local injection = require("mitigation/injection")
require 'busted.runner'()
-- a trick to work around resty's limitations of modifying these variables in test
setmetatable(ngx,{status=0, arg={}})

describe("testing injection capability", function()
    before_each(function()
        ngx.var = {
            detection_tag_host = "s.gihwyz.com",
            detection_tag_path = "/static/gs/5.0.0/pagespeed.js",
            detection_tag_spa = "0",
            detection_tag_mo = "2",
            detection_tag_ci = "845155",
            detection_tag_dt = "8451551584148378445000"
        }
        ngx.req = {}
        ngx.ctx = {}
    end)
    describe("test head injection", function()
        it("check regex injecting inside head", function()
            local body = "<html><head></head><body></body></html>"
            local injected, err = injection.inject(body)
            assert.are.equal(err, nil)
           local expected = "<html><head><script src=\"https://" ..
                    ngx.var.detection_tag_host ..
                    ngx.var.detection_tag_path .. "?pd=acc&spa=" ..
                    ngx.var.detection_tag_spa .. "&mo=" ..
                    ngx.var.detection_tag_mo .. "&ci=" ..
                    ngx.var.detection_tag_ci .. "&dt=" ..
                    ngx.var.detection_tag_dt .."\"></script></head><body></body></html>"
            assert.are.equal(injected, expected)
        end)
        it("check regex inserting head during injection", function()
            local body = "<html><body></body></html>"
            local injected, err = injection.inject(body)
            assert.are.equal(err, nil)
            local expected = "<html><head><script src=\"https://" ..
                    ngx.var.detection_tag_host ..
                    ngx.var.detection_tag_path .. "?pd=acc&spa=" ..
                    ngx.var.detection_tag_spa .. "&mo=" ..
                    ngx.var.detection_tag_mo .. "&ci=" ..
                    ngx.var.detection_tag_ci .. "&dt=" ..
                    ngx.var.detection_tag_dt .."\"></script></head><body></body></html>"
            assert.are.equal(injected, expected)
        end)
        it("check regex inserting head and can handle classes during injection", function()
            local body = "<html><body class=\"some_class\"></body></html>"
            local injected, err = injection.inject(body)
            assert.are.equal(err, nil)
            local expected = "<html><head><script src=\"https://" ..
                    ngx.var.detection_tag_host ..
                    ngx.var.detection_tag_path .. "?pd=acc&spa=" ..
                    ngx.var.detection_tag_spa .. "&mo=" ..
                    ngx.var.detection_tag_mo .. "&ci=" ..
                    ngx.var.detection_tag_ci .. "&dt=" ..
                    ngx.var.detection_tag_dt .. "\"></script></head><body class=\"some_class\"></body></html>"
            assert.are.equal(injected, expected)
        end)
    end)
end)
