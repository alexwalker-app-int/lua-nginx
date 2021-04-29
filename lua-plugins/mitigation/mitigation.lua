local multipart = require("resty.upload")
local http = require("resty.http")
local json = require ("cjson")
local _M = {}

function _M.fetch_via_https(scheme, host, port, ssl_verify, path, body)
    local httpc = http.new()
    local options = {
        scheme = scheme,
        host = host,
        port = port,
        ssl_verify = ssl_verify
    }
    -- https://github.com/ledgetech/lua-resty-http/blob/master/lib/resty/http_connect.lua#L33
    local ok, err = httpc:connect(options)
    if err ~= nil then
        return 400, "", "connection failed: " .. err
    end
    if ngx.var.mitigation_api_key == "" or ngx.var.mitigation_api_key == nil then
        return 400, "", "need an api key"
    end
    local res, err = httpc:request {
        path = path,
        method = 'POST',
        body = body,
        headers = {
            ["Authorization"] = "Bearer " .. ngx.var.mitigation_api_key,
            ["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(tostring(body))
        }
    }
    if not res then
        httpc:close()
        return 400, "", "Request Failed"
    end
    -- Return the connection to the keepalive pool (using a keepalive pool reduces connection overhead between requests)
    httpc:set_keepalive()
    local body, err = res:read_body()
    return res.status, body, err
end

function _M.redact_from_payload(body)
    body["OZ_DT"] = nil
    body["OZ_TC"] = nil
    body["OZ_SG"] = nil
    return body
end

function _M.generate_mitigation_content(args, headers)
    local OZ_DT = args["OZ_DT"]
    local OZ_TC = args["OZ_TC"]
    local OZ_SG = args["OZ_SG"]
    local full_url = ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri
    -- todo check custom_fields_table is in fact a table
    local custom_fields_table = {}
    if ngx.var.custom_fields ~= nil and ngx.var.custom_fields ~= "" then
        custom_fields_table = json.decode(ngx.var.custom_fields)
    end
    local request_body = {
        client_ds = {
            et = ngx.var.detection_tag_et,
            ip = ngx.var.remote_addr,
            mo = ngx.var.detection_tag_mo,
            pd = "acc",
            ua = headers["user_agent"],
            --todo automate the value for ref
            --ref = ,
            url = headers["Referer"],
            endpoint = full_url,
            custom = custom_fields_table or nil
        },
        datatoken = OZ_DT,
        payload = OZ_TC,
        session = OZ_SG
    }
    return request_body
end

return _M
