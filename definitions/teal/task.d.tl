local record thrd 
    create: function(entry: function, args?: {any}): number
    join: function(tid: number): boolean, any...
    id: function(): number
    list: function(): {number}
end

return thrd