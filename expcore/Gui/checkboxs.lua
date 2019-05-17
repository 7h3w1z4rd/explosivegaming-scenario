--- Gui class define for checkboxs and radiobuttons
--[[
>>>> Using an option set
    An option set is a set of radio buttons where only one of them can be active at a time, this means that when one
    is clicked all the other ones are set to false, an option set must be defined before hand and will always store
    its state but is not limited by how it can categorize the store.

    First you must register the store with a name and a update callback, and an optional function for categorize:

    local example_option_set =
    Gui.new_option_set('example-option-set',function(value,category)
        game.print('Example options set '..category..' is now: '..tostring(value))
    end,Gui.player_store)

    Then you must register some radiobutton defines and include them in the option set:

    local example_option_one =
    Gui.new_radiobutton()
    :set_caption('Option One')
    :add_as_option(example_option_set,'One')

    local example_option_two =
    Gui.new_radiobutton()
    :set_caption('Option Two')
    :add_as_option(example_option_set,'Two')

    Note that these radiobuttons can still have on_element_update events but this may result in a double trigger of events as
    the option set update is always triggered; also add_store cant be used as the option set acts as the store however get
    and set store will still work but will effect the option set rather than the indivual radiobuttons.

>>>> Functions
    Checkbox.new_checkbox(name) --- Creates a new checkbox element define
    Checkbox._prototype_checkbox:on_element_update(callback) --- Registers a handler for when an element instance updates
    Checkbox._prototype_checkbox:on_store_update(callback) --- Registers a handler for when the stored value updates

    Checkbox.new_radiobutton(name) --- Creates a new radiobutton element define
    Checkbox._prototype_radiobutton:on_element_update(callback) --- Registers a handler for when an element instance updates
    Checkbox._prototype_radiobutton:on_store_update(callback) --- Registers a handler for when the stored value updates
    Checkbox._prototype_radiobutton:add_as_option(option_set,option_name) --- Adds this radiobutton to be an option in the given option set (only one can be true at a time)

    Checkbox.new_option_set(name,callback,categorize) --- Registers a new option set that can be linked to radiobutotns (only one can be true at a time)
    Checkbox.draw_option_set(name,element) --- Draws all radiobuttons that are part of an option set at once (Gui.draw will not work)

    Checkbox.reset_radiobutton(element,exclude,recursive) --- Sets all radiobutotn in a element to false (unless excluded) and can act recursivly

    Other functions present from expcore.gui.core
]]
local Gui = require './core'
local Store = require 'expcore.store'
local Game = require 'utils.game'

--- Event call for on_checked_state_changed and store update
-- @tparam define table the define that this is acting on
-- @tparam element LuaGuiElement the element that triggered the event
-- @tparam value boolean the new state of the checkbox
local function event_call(define,element,value)
    if define.events.on_element_update then
        local player = Game.get_player_by_index(element.player_index)
        define.events.on_element_update(player,element,value)
    end
end

--- Store call for store update
-- @tparam define table the define that this is acting on
-- @tparam element LuaGuiElement the element that triggered the event
-- @tparam value boolean the new state of the checkbox
local function store_call(define,element,value)
    element.state = value
    event_call(define,element,value)
end

local Checkbox = {
    option_sets={},
    option_categorize={},
    _prototype_checkbox=Gui._prototype_factory{
        on_element_update = Gui._event_factory('on_element_update'),
        on_store_update = Gui._event_factory('on_store_update'),
        add_store = Gui._store_factory(store_call),
        add_sync_store = Gui._sync_store_factory(store_call)
    },
    _prototype_radiobutton=Gui._prototype_factory{
        on_element_update = Gui._event_factory('on_element_update'),
        on_store_update = Gui._event_factory('on_store_update'),
        add_store = Gui._store_factory(store_call),
        add_sync_store = Gui._sync_store_factory(store_call)
    }
}

--- Creates a new checkbox element define
-- @tparam[opt] name string the optional debug name that can be added
-- @treturn table the new checkbox element define
function Checkbox.new_checkbox(name)

    local self = Gui._define_factory(Checkbox._prototype_checkbox)
    self.draw_data.type = 'checkbox'
    self.draw_data.state = false

    if name then
        self:debug_name(name)
    end

    self.post_draw = function(element)
        if self.store then
            local category = self.categorize and self.categorize(element) or nil
            local state = self:get_store(category,true)
            if state then element.state = true end
        end
    end

    Gui.on_checked_state_changed(self.name,function(event)
        local element = event.element

        if self.option_set then
            local value = Checkbox.option_sets[self.option_set][element.name]
            local category = self.categorize and self.categorize(element) or value
            self:set_store(category,value)

        elseif self.store then
            local value = element.state
            local category = self.categorize and self.categorize(element) or value
            self:set_store(category,value)

        else
            local value = element.state
            event_call(self,element,value)

        end
    end)

    return self
end

--- Creates a new radiobutton element define, has all functions checkbox has
-- @tparam[opt] name string the optional debug name that can be added
-- @treturn table the new button element define
function Checkbox.new_radiobutton(name)
    local self = Checkbox.new_checkbox(name)
    self.draw_data.type = 'radiobutton'

    local mt = getmetatable(self)
    mt.__index = Checkbox._prototype_radiobutton

    return self
end

--- Adds this radiobutton to be an option in the given option set (only one can be true at a time)
-- @tparam option_set string the name of the option set to add this element to
-- @tparam option_name string the name of this option that will be used to idenitife it
-- @tparam self the define to allow chaining
function Checkbox._prototype_radiobutton:add_as_option(option_set,option_name)
    self.option_set = option_set
    self.option_name = option_name or self.name

    Checkbox.option_sets[option_set][self.option_name] = self.name
    Checkbox.option_sets[option_set][self.name] = self.option_name

    self:add_store(Checkbox.option_categorize[option_set])

    return self
end

--- Gets the stored value of the radiobutton or the option set if present
-- @tparam category[opt] string the category to get such as player name or force name
-- @treturn any the value that is stored for this define
function Checkbox._prototype_radiobutton:get_store(category,internal)
    if not self.store then return end
    local location = not internal and self.option_set or self.store

    if self.categorize then
        return Store.get_child(location,category)
    else
        return Store.get(location)
    end
end

--- Sets the stored value of the radiobutton or the option set if present
-- @tparam category[opt] string the category to get such as player name or force name
-- @tparam value any the value to set for this define, must be valid for its type ie boolean for checkbox etc
-- @treturn boolean true if the value was set
function Checkbox._prototype_radiobutton:set_store(category,value,internal)
    if not self.store then return end
    local location = not internal and self.option_set or self.store

    if self.categorize then
        return Store.set_child(location,category,value)
    else
        return Store.set(location,category)
    end
end

--- Registers a new option set that can be linked to radiobutotns (only one can be true at a time)
-- @tparam name string the name of the option set, must be unique
-- @tparam callback function the update callback when the value of the option set chagnes
-- callback param - value string - the new selected option for this option set
-- callback param - category string - the category that updated if categorize was used
-- @tpram categorize function the function used to convert an element into a string
-- @treturn string the name of this option set to be passed to add_as_option
function Checkbox.new_option_set(name,callback,categorize)

    Store.register(name,function(value,category)
        local options = Checkbox.option_sets[name]
        for opt_name,define_name in pairs(options) do
            if Gui.defines[define_name] then
                local define = Gui.get_define(define_name)
                local state = opt_name == value
                define:set_store(category,state,true)
            end
        end
        callback(value,category)
    end)

    Checkbox.option_categorize[name] = categorize
    Checkbox.option_sets[name] = {}

    return name
end

--- Draws all radiobuttons that are part of an option set at once (Gui.draw will not work)
-- @tparam name string the name of the option set to draw the radiobuttons of
-- @tparam element LuaGuiElement the parent element that the radiobuttons will be drawn to
function Checkbox.draw_option_set(name,element)
    if not Checkbox.option_sets[name] then return end
    local options = Checkbox.option_sets[name]

    for _,option in pairs(options) do
        if Gui.defines[option] then
            Gui.defines[option]:draw_to(element)
        end
    end

end

--- Sets all radiobutotn in a element to false (unless excluded) and can act recursivly
-- @tparam element LuaGuiElement the root gui element to start setting radio buttons from
-- @tparam[opt] exclude ?string|table the name of the radiobutton to exclude or a table of radiobuttons where true will set the state true
-- @tparam[opt=false] recursive boolean if true will recur as much as possible, if a number will recur that number of times
-- @treturn boolean true if successful
function Checkbox.reset_radiobuttons(element,exclude,recursive)
    if not element or not element.valid then return end
    exclude = type(exclude) == 'table' and exclude or exclude ~= nil and {[exclude]=true} or {}
    recursive = type(recursive) == 'number' and recursive-1 or recursive

    for _,child in pairs(element.children) do
        if child and child.valid and child.type == 'radiobutton' then
            local state = exclude[child.name] or false
            local define = Gui.defines[child.name]

            if define then
                local category = define.categorize and define.categorize(child) or state
                define:set_store(category,state)

            else
                child.state = state

            end

        elseif child.children and (type(recursive) == 'number' and recursive >= 0 or recursive == true) then
            Checkbox.reset_radiobutton(child,exclude,recursive)

        end
    end

    return true
end

return Checkbox