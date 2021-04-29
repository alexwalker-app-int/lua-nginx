local _M = {}

function _M.inject(body)
    -- todo these need to be validated
    if ngx.var.detection_tag_spa == nil or ngx.var.detection_tag_spa == "" then
        ngx.var.detection_tag_spa = "0"
    end
    if ngx.var.detection_tag_mo == nil or ngx.var.detection_tag_mo == "" then
        ngx.var.detection_tag_mo = "2"
    end
    local scriptUrl = "https://" ..
            ngx.var.detection_tag_host ..
            ngx.var.detection_tag_path .. "?pd=acc&spa=" ..
            ngx.var.detection_tag_spa .. "&mo=" ..
            ngx.var.detection_tag_mo .. "&ci=" ..
            ngx.var.detection_tag_ci .. "&dt=" ..
            ngx.var.detection_tag_dt

    local scriptTag = "<script src=\""..scriptUrl.."\"></script>"
    local headMatch, err = ngx.re.match(body, "</head>")
    if err then
        return nil, "error checking for </head> " .. err
    end
    if headMatch then
        return ngx.re.gsub(body, "</head>", scriptTag .. "</head>"), nil
    else
        if err then
            return nil, "error injecting scrip " .. err
        end
        local bodyMatch, err = ngx.re.match(body, "<body[^>]*>")
        if err then
            return nil, "error checking for <body...>" .. err
        end
        if bodyMatch then
            return ngx.re.gsub(body, "<body[^>]*>", "<head>" ..scriptTag .. "</head>" .. bodyMatch[0]), nil
        end
    end
    return nil, "no match"
end

return _M
