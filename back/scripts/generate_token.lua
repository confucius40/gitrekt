-- this just generates a token, it uses /dev/urandom so be sure to be in UNIX.
local function random_bytes(n)
    local f = assert(io.open("/dev/urandom", "rb"))
    local data = f:read(n)
    f:close()

    assert(data and #data == n, "failed to read random bytes")
    return data
end

local function to_hex(data)
    return (data:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

local token = to_hex(random_bytes(32))

print(token)
