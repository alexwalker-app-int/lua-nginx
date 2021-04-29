local utils = require("mitigation/utils")
local ck = require "resty.cookie"
local _M = {}

function _M.read_signals(cookies)
    local signals = {
        OZ_DT = "",
        OZ_TC = "",
        OZ_SG = ""
    }
    local i=0
    while true do
        local cookieName = "cookie_OZ_DT" .. tostring(i)
        if cookies[cookieName] == nil then
            break
        end
        signals.OZ_DT = signals.OZ_DT .. cookies[cookieName]
        i=i+1
    end
    i=0
    while true do
        local cookieName = "cookie_OZ_TC" .. tostring(i)
        if cookies[cookieName] == nil then
            break
        end
        signals.OZ_TC = signals.OZ_TC .. cookies[cookieName]
        i=i+1
    end
    i=0
    while true do
        local cookieName = "cookie_OZ_SG" .. tostring(i)
        if cookies[cookieName] == nil then
            break
        end
        signals.OZ_SG = signals.OZ_SG .. cookies[cookieName]
        i=i+1
    end
    return signals
end

function _M.redact_signals()
    local redacted_cookies = ""
    -- if we found some signal cookies, then we want to iterate them, keeping any others, but clearing these ones
    local cookie, err = ck:new()
    if err then
        return redacted_cookies, err
    end
    local fields, err = cookie:get_all()
    if not fields then
        return redacted_cookies, err
    end
    for k, v in pairs(fields) do
        if not utils.starts(k, "OZ_DT") and not utils.starts(k, "OZ_TC") and not utils.starts(k, "OZ_SG") then
            -- these are the ones to keep
            redacted_cookies = redacted_cookies .. k .. "=" .. v .. "; "
        end
    end
    return redacted_cookies, nil
end
return _M

