local cartridge = require('cartridge')
local log       = require('log')

local role_name = 'init_db'

local function init(opts) 
    
    local users = box.schema.space.create('users',
        { if_not_exists = true }
    )

    users:format({
        {name = 'user_id',  type = 'unsigned'},
        {name = 'nickname', type = 'string'},
        {name = 'value',    type = 'map'},
    })

    box.schema.sequence.create('seq', { if_not_exists = true })
    
    users:create_index('user_id', {
        parts = {'user_id'},
        sequence = 'seq',
        if_not_exists = true,
    })

    users:create_index('secondary', {
        type = 'hash',
        parts = {'nickname'},
        if_not_exists = true,
    })

    log.info('Database has been inited!')

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
