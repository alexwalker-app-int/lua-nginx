local _M = {}

function _M.starts(String, Start)
    return string.sub(String,1,string.len(Start))==Start
end

-- string split split
function _M.split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

-- Support string before and after trim
function _M.trim(s)
    local gs = (s:gsub("^%s*(.-)%s*$", "%1"))
    return gs
end

function _M.table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end
        -- Check the value type
        if type(v) == "table" then
            result = result.. _M.table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end
return _M
