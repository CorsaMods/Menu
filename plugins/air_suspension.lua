local plugin = {
    name = "Air Suspension",
    version = "1.0",
    author = "you"
}

function plugin.init()
    -- your suspension logic here
    print("[ModMenu] Air Suspension loaded")
end

function plugin.destroy()
    -- cleanup on disable
end

return plugin
