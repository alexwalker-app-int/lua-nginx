local signals = require("../mitigation/signals")
local utils = require("mitigation/utils")
require 'busted.runner'()
setmetatable(ngx,{status=0, arg={}})

describe("testing reading signal cookies", function()
    describe("concatenate cookies", function()
        it("cookie should be hello world", function()
            local res = {
                cookie_OZ_DT0="HEL",
                cookie_OZ_DT1="LO ",
                cookie_OZ_DT2="WOR",
                cookie_OZ_DT3="LD!",
            }
            local args = signals.read_signals(res)
            assert.are.equal(args["OZ_DT"], "HELLO WORLD!")
        end)
        it("two cookies should be re built", function()
            local res = {
                cookie_OZ_DT0="aerw3Eah",
                cookie_OZ_DT1="uZzXqEjq",

                cookie_OZ_TC0="2GAMbw1+",
                cookie_OZ_TC1="EW.u6zFtQ",
                cookie_OZ_TC2="y[+`}C82b",
                cookie_OZ_TC3="o:Fg5^.H-",
                cookie_OZ_TC4="@\"n7el-(",
                cookie_OZ_TC5="5U\1Brp~~",
                cookie_OZ_TC6="l})!yV+X%",
                cookie_OZ_TC7="+$OOx_e(r@",
                cookie_OZ_TC8="6fxN3P>5=)s",
            }
            local args = signals.read_signals(res)
            assert.are.equal(args["OZ_DT"], "aerw3EahuZzXqEjq")
            assert.are.equal(args["OZ_TC"], "2GAMbw1+EW.u6zFtQy[+`}C82bo:Fg5^.H-@\"n7el-(5U\1Brp~~l})!yV+X%+$OOx_e(r@6fxN3P>5=)s")
        end)
        it("there are no cookies", function()
            local res = {}
            local args = signals.read_signals(res)
            assert.are.equal(args["OZ_DT"], "")
            assert.are.equal(args["OZ_TC"], "")
            assert.are.equal(args["OZ_SG"], "")
        end)
    end)
end)
