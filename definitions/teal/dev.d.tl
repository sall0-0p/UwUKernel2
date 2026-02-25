local record dev
    open: function(name: string): number
    list: function(): {string}
    type: function(name: string): string
    methods: function(name: string): {string}
end

return dev;