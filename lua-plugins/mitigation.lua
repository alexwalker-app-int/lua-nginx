-- handles the incoming request
local mitigation = require("mitigation/mitigation")
local signals = require("mitigation/signals")
local utils = require("mitigation/utils")
local json = require ("cjson")

local function abort(message, headers)
    if message ~= nil then
        ngx.log(ngx.ERR, "aborted due to " .. message)
    end
    local success, detection_tag_spa = pcall(tonumber, ngx.var.detection_tag_spa);
    if success and detection_tag_spa == 1 then -- 1 represents an SPA so we don't want to respond with a redirect probably
        local response_body = {
            error = "invalid request"
        }
        local response_code = tonumber(ngx.var.block_spa_response_code) or ngx.HTTP_BAD_REQUEST
        if ngx.var.block_spa_response_body ~= nil and ngx.var.block_spa_response_body ~= "" then
            local success, json_response = pcall(json.decode, ngx.var.block_spa_response_body);
            if not success then
                ngx.log(ngx.ERR, "could not decode response from mitigation engine: " .. err)
            end
            response_body = json_response
        end
        ngx.status = response_code
        ngx.header.content_type = "application/json; charset=utf-8"
        ngx.say(json.encode(response_body))
        return ngx.exit(response_code)
    end
    --todo confirm redirect starts with leading slash
    ngx.header.location = ngx.var.block_redirect_url or headers["Referer"] or "/"
    return ngx.exit(tonumber(ngx.var.block_redirect_status_code) or ngx.HTTP_MOVED_TEMPORARILY)
end

local function continue(status, body, err) -- this should do anything before allowing the request through, like logging
    if err ~= nil then
        ngx.log(ngx.ERR, "continue received error: " .. err)
        ngx.req.set_header("X-MITIGATION-ERROR", err)
        return true
    elseif status ~= 200 then
        ngx.log(ngx.ERR, "status code expected 200, was " .. status)
        ngx.req.set_header("X-MITIGATION-STATUS", status)
        return true
    end
    local success, jsonRaw = pcall(json.decode, body);
    if not success then
        ngx.log(ngx.ERR, "could not decode response from mitigation engine: " .. err)
        ngx.req.set_header("X-MITIGATION-ERROR", err)
        return true
    end
    ngx.req.set_header("X-MITIGATION-RESULT", jsonRaw)
    if jsonRaw["action"] == nil then
        ngx.log(ngx.ERR, "mitigation engine did not supply an action: " .. err)
        return true
    end
    local headers, err = ngx.req.get_headers(0)
    if err ~= nil then
        ngx.log(ngx.ERR, "could not retrieve headers: " .. err)
        ngx.req.set_header("X-MITIGATION-ERROR", err)
        return true
    end
    if jsonRaw["action"] == "block" then
        --todo should we allow a passive mode irrespective of policy engine?
        abort("action == block", headers)
        return false
    end
    return true
end

local function makeRequest(request_body)
    if ngx.var.mitigation_api_scheme == nil or ngx.var.mitigation_api_scheme == "" then
        ngx.var.mitigation_api_scheme = "https"
    end
    if ngx.var.mitigation_api_host == nil or ngx.var.mitigation_api_host == "" then
        ngx.var.mitigation_api_host = "vesper.p.botx.us"
    end
    if ngx.var.mitigation_api_port == nil or ngx.var.mitigation_api_port == "" then
        ngx.var.mitigation_api_port = "443"
    end
    ngx.var.mitigation_api_ssl_verify = ngx.var.mitigation_api_ssl_verify ~= "false"
    if ngx.var.mitigation_api_path == nil or ngx.var.mitigation_api_path == "" then
        ngx.var.mitigation_api_path = "/decision"
    end
    --default to production. Getting env var to override this if set
    local status, body, err = mitigation.fetch_via_https(
        ngx.var.mitigation_api_scheme,
        ngx.var.mitigation_api_host,
        ngx.var.mitigation_api_port,
        ngx.var.mitigation_api_ssl_verify,
        ngx.var.mitigation_api_path,
        json.encode(request_body)
    )
    if err ~= nil then
        ngx.log(ngx.ERR, "error fetching mitigation response: " .. err)
    end
    return continue(status, body, err)
end


if ngx.var.request_method == "POST" or ngx.var.request_method == "PUT" or ngx.var.request_method == "PATCH" then
    local headers, _ = ngx.req.get_headers(0)

    local args = signals.read_signals(ngx.var)
    -- todo currently retrieving the signal-cookies using the var parameters,
    -- writing back with library. Should we be using library everywhere in that case?
    -- my guess is reading them off ngx.var is faster
    if args["OZ_DT"] ~= "" or args["OZ_TC"] ~= "" or args["OZ_SG"] ~= "" then
        local request_body = mitigation.generate_mitigation_content(args, headers)
        makeRequest(request_body)
        local redacted_cookies, err = signals.redact_signals()
        if err then
            ngx.log(ngx.ERR, "error redacting signals ", err)
        else
            ngx.req.set_header("Cookie", redacted_cookies)
            return
        end
    end

    local contentType = ngx.var.content_type
    if contentType == nil then
        -- todo: can we infer it - could the wrong content type game the system?
        contentType = "application/json"
    end
    if utils.starts(contentType, "application/x-www-form-urlencoded") then
        ngx.req.read_body()
        local args = ngx.req.get_post_args()
        local request_body = mitigation.generate_mitigation_content(args, headers)
        local continuing = makeRequest(request_body)
        if continuing then
            ngx.req.set_body_data(ngx.encode_args(mitigation.redact_from_payload(args)))
        end
    elseif utils.starts(contentType, "multipart/form-data") then
        -- todo handle multiparts body correctly
        --local args, _ = multipart.read_parameters()
        --local request_body = mitigation.generate_mitigation_content(args, headers)
        --makeRequest(request_body)
        ngx.log(ngx.WARN, "multipart/form-data is not currently supported")
    elseif utils.starts(contentType, "application/json") then
        ngx.req.read_body()
        local args = json.decode( ngx.req.get_body_data() )
        local request_body = mitigation.generate_mitigation_content(args, headers)
        local continuing =  makeRequest(request_body)
        if continuing then
            ngx.req.set_body_data(json.encode(mitigation.redact_from_payload(args)))
        end
    end

end
