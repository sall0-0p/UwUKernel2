local record io
    dup: function(old_fd: number, new_fd?: number): number
    pipe: function(): number, number
end

return io