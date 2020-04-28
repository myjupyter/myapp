local cartridge = require('cartridge')
local log       = require('log')
local json      = require('json')

local role_name = 'custom'

local httpd = cartridge.service_get('httpd')

local function response(req, code, message)
    local resp  = req:render({text = req.method..' '..req.path})
    
    resp.status = code
    resp.body = message
    
    return resp
end

local function user_exists(id, users)
    local user = users.index.secondary:get{id}
    if user ~= nil then
        return true
    end
    return false
end

local function get_header(users)
    httpd:route({method = 'GET', path = '/kv/:id'}, 
        function(req)              
            log.info('GET')

            local id   = req:stash('id')
            local user = users.index.secondary:get{id}

            if user ~= nil then
                return response(req, 200, json.encode{id = id, value = user['value']})
            end
            
            return response(req, 404, "Not Found")
        end
    )
end


local function put_header(users)
    httpd:route({method = 'PUT', path = '/kv/:id'}, 
        function(req)              
            log.info('PUT DATA')

            local id   = req:stash('id') 
            local tab = json.decode(req:read())

            if tab.value == nil then
                return response(req, 400, "Incorrect Body")
            end

            if user_exists(id, users) ~= false then
                local user = users.index.secondary:get{id}
                users:put{user['user_id'] , id, tab.value}
                return response(req, 200, 'Success') 
            end
            
            users:put{nil, id, tab.value}
            return response(req, 200, 'Success') 
        end
    )
end

local function delete_header(users)
    httpd:route({method = 'DELETE', path = '/kv/:id'}, 
        function(req)              

            local id   = req:stash('id')
            
            if user_exists(id, users) == false then
                return response(req, 404, 'Not Found')
            end

            users.index.secondary:delete{id}
            return response(req, 200, "Success") 
        end
    )
end

local function post_header(users)
    httpd:route({method = 'POST', path = '/kv'}, 
        function(req)              
            log.info('POST DATA')
            return {status = 400, body = "Incorrect Body"} 
        end
    )

end

local function init(opts) 
    
    local users = box.space.users

    get_header(users)
    put_header(users)
    delete_header(users)
    post_header(users)

    return true
end

local function stop()
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args
    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    return true
end

return {
    role_name = role_name,
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    -- dependencies = {'cartridge.roles.vshard-router'},
}
