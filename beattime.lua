--[[ OBS Studio Swatch Internet Time (Beat Time) Script

This script transforms a text source into a Swatch Internet Time (@beats) clock.
Beat time is based on Biel Mean Time (UTC+1) and ranges from @000 to @999.
]]

obs         = obslua
source_name = ""

activated = false

----------------------------------------------------------
-- Function to calculate and display Swatch Internet Time
----------------------------------------------------------

function set_beat_time(source)
    -- Get current UTC timestamp
    local utc = os.time(os.date("!*t"))

    -- Convert to Biel Mean Time (UTC+1)
    local bmt = utc + 3600

    -- Seconds since BMT midnight
    local seconds = bmt % 86400

    -- Calculate beats (0-999)
    local beats = math.floor(seconds / 86.4)

    -- Format as @000
    local text = string.format("@%03d", beats)

    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
end

function timer_callback()
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        set_beat_time(source)
        obs.obs_source_release(source)
    end
end

function activate(activating)
    if activated == activating then
        return
    end

    activated = activating

    if activating then
        -- Check once per second so the display updates immediately when a beat changes
        obs.timer_add(timer_callback, 1000)
    else
        obs.timer_remove(timer_callback)
    end
end

----------------------------------------------------------
-- Called when a source is activated/deactivated
----------------------------------------------------------

function activate_signal(cd, activating)
    local source = obs.calldata_source(cd, "source")
    if source ~= nil then
        local name = obs.obs_source_get_name(source)
        if name == source_name then
            activate(activating)
        end
    end
end

function source_activated(cd)
    activate_signal(cd, true)
end

function source_deactivated(cd)
    activate_signal(cd, false)
end

function reset()
    activate(false)

    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local active = obs.obs_source_showing(source)
        obs.obs_source_release(source)
        activate(active)
    end
end

----------------------------------------------------------

function script_description()
    return "Displays Swatch Internet Time (@beats) in a text source.\n\n" ..
           "Beat Time is based on Biel Mean Time (UTC+1) and ranges from @000 to @999."
end

function script_properties()
    local props = obs.obs_properties_create()

    local p = obs.obs_properties_add_list(
        props,
        "source",
        "Text Source",
        obs.OBS_COMBO_TYPE_EDITABLE,
        obs.OBS_COMBO_FORMAT_STRING
    )

    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_id(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
    end

    obs.source_list_release(sources)

    return props
end

function script_update(settings)
    activate(false)

    source_name = obs.obs_data_get_string(settings, "source")

    reset()
end

function script_load(settings)
    local sh = obs.obs_get_signal_handler()
    obs.signal_handler_connect(sh, "source_show", source_activated)
    obs.signal_handler_connect(sh, "source_hide", source_deactivated)
end
