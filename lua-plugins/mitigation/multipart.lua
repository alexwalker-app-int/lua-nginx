local utils = require("mitigation/utils")
local upload = require("resty.upload")

local chunk_size = 4096 -- or 8192

local _M = {}

function _M.handle_header(res)
    -- 2. if its a header, we want to know if this is a file upload or not
    -- todo is this reliable? 1 and 2 maybe replacable with the keys we are actually after in the table
    local key = res[1]
    local value = res[2]
    local current_field = string
    if key == "Content-Disposition" then
        -- 3. we don't want any files as this will require buffering the content, which could be large, e.g
        -- form-data; name="testFileName"; filename="testfile.txt"
        if value:find("filename") then
            return current_field, "this is a file"
        end
        local kvlist = utils.split(value, ';')
        -- 4. with this being A.N.Other field, we will process it
        for _, kv in ipairs(kvlist) do
            local seg = utils.trim(kv)
            if seg:find("name") then -- 5. the key is coming from the name parameter
                local kv_field = utils.split(seg, "=")
                local field_name = string.sub(kv_field[2], 2, -2)
                if field_name then -- 6. if we find the substring, we can set a global record of it
                    current_field = field_name
                end
                break
            else
                current_field = "" -- 6.b otherwise make sure its cleared
            end
        end
    end
    return current_field, nil
end
function _M.handle_body(current_field, current_body, res)
    if current_field ~= "" then
        current_body = current_body .. res
    end
    return current_body
end
function _M.handle_part_end(fields, current_field, current_body)
    if current_field ~= ""  then
        fields[current_field] = current_body
    end
    return fields
end
function _M.read_parameters()
    local form, err = upload:new(chunk_size)
    if not form then
        ngx.log(ngx.ERR, "failed to new upload: ", err)
        ngx.exit(500)
    end

    form:set_timeout(1000)
    local fields = {}
    local current_field = string
    local current_body = string
    while true do
        -- 1. read the line in, typ will tell us if this is the header, the body or the end of the part
        local typ, res, err = form:read()
        if not typ then
            return fields, err
        end
        if typ == "header" then
            current_field, err = _M.handle_header(res)
            if err ~= nil then
                goto skip_to_next_header
            end
        end
        if typ == "body" then -- 7. if the type is body, and we found a name for the field, then start concatenating the body
            current_body = _M.handle_body(current_field, current_body, res)
        end
        if typ == "part_end" then -- 8. once we know this part has completed we can store the body in the table
            fields = _M.handle_part_end(fields, current_field, current_body)
            current_body = ""
            current_field = "" -- 8.b must clear these values so that next loop we don't store or overwrite anything
        end
        if typ == "eof" then
            --this tells us that all of the parts have finished
            break
        end
        ::skip_to_next_header::
    end
    return fields, nil
end
return _M

