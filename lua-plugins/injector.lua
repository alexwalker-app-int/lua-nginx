local injection = require("mitigation/injection")
if ngx.arg[1] ~= "" then
    local injected_body, err = injection.inject(ngx.arg[1])
    if err ~= nil then
        ngx.log(ngx.ERR, err)
    else
        ngx.arg[1] = injected_body
    end
end
