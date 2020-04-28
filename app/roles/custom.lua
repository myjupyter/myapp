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
            local id   = req:stash('id')
            local user = users.index.secondary:get{id}

            if user ~= nil then
                log.info('GET 200 Success')
                return response(
                        req, 200, 
                        json.encode{ 
                            id = id,
                            value = json.encode(user['value'])
                        }
                )
            end
            
            log.info('GET 404 Not Found')
            return response(req, 404, "Not Found")
        end
    )
end


local function put_header(users)
    httpd:route({method = 'PUT', path = '/kv/:id'}, 
        function(req)              
            local id   = req:stash('id') 
            local tab = nil
            
            local ok, err = pcall(function()
                tab = json.decode(req:read())
            end)

            if not ok then 
                log.info('PUT 400 Incorrect Body')
                return response(req, 400, "Incorrect Body")
            end

            if tab.value == nil then
                log.info('PUT 400 Incorrect Body')
                return response(req, 400, "Incorrect Body")
            end

            if user_exists(id, users) ~= false then
                local user = users.index.secondary:get{id}
                users:put{user['user_id'] , id, tab.value}
                log.info('PUT 200 Success')
                return response(req, 200, 'Success') 
            end
            
            users:put{nil, id, tab.value}
            log.info('PUT 200 Success')
            
            return response(req, 200, 'Success') 
        end
    )
end

local function delete_header(users)
    httpd:route({method = 'DELETE', path = '/kv/:id'}, 
        function(req)              
            local id   = req:stash('id')
            
            if user_exists(id, users) == false then
                log.info('DELETE 404 Not Found')
                return response(req, 404, 'Not Found')
            end

            users.index.secondary:delete{id}
            log.info('DELETE 200 Success')
            
            return response(req, 200, "Success") 
        end
    )
end

local function post_header(users)
    httpd:route({method = 'POST', path = '/kv'}, 
        function(req)              

            local tab = nil
            local ok, err = pcall(function()
                tab = json.decode(req:read())
            end)

            if not ok then
                log.info('POST 400 Incorrect Body')
                return response(req, 400, "Incorrect Body")
            end

            if tab.key == nil or tab.value == nil then
                log.info('POST 400 Incorrect Body')
                return response(req, 400, "Incorrect Body")
            end

            if user_exists(tab.key, users) == true then
                log.info('POST 409 Already Exists')
                return response(req, 409, "Already Exists")
            end
            
            users:insert{nil, tab.key, tab.value}
            log.info('POST 200 Success')
            
            return response(req, 200, "Success") 
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
