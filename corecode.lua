DiscordLink = DiscordLink or {
    _config_path = SavePath .. 'DiscordLink.json',
    validation_rules = {
        channel_id = {
            required = true,
            type = "string"
        },
        channel_name = {
            required = true,
            type = "string"
        },
        server_name = {
            required = true,
            type = "string"
        },
        send_version = {
            type = "boolean"
        },
        version_identifier = {
            type = "string"
        }
    },
    attributes = {},
}

function DiscordLink:_validate(attributes)
    for name, rules in pairs(DiscordLink.validation_rules) do
        if attributes[name] then
            if rules.type and type(attributes[name]) ~= rules.type then
                log(string.format("DiscordLink: %s must be a %s in attributes table", name, rules.type))
                return false
            end
        elseif rules.required then
            log(string.format("DiscordLink: %s must be present in attributes table", name))
            return false
        end
    end

    return true
end

function DiscordLink:set_attributes(attributes)
    if not self:_validate(attributes) then
        return
    end

    for k, v in pairs(attributes) do
        if self.attributes[k] == nil then
            self.attributes[k] = v
        end
    end
end

function DiscordLink:load()
	local file = io.open(self._config_path, 'r')
	if file then
        local attributes = json.decode(file:read('*all'))
        if not attributes or not self:_validate(attributes) then
            return
        end

		for k, v in pairs(attributes) do
			self.attributes[k] = v
		end

		file:close()
	end
end

DiscordLink:load()