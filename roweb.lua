local RoWeb = {Version = "v1.4.5"}
RoWeb.__index = RoWeb

local reqName = syn and "syn.request" or
http_request and "http_request" or
request and "request" or
HttpPost and "HttpPost"

request = http_request or request or HttpPost or syn.request

function RoWeb:new(url, options)
    local options = options or {}
    options.Url = url
    options.Method = "GET"

    local req = request(options)

    local _page = {data = req, url = options.Url, options = options}
    setmetatable(_page, self)
    return _page
end

function toJson(string)
    local jsonData = nil
    local success, err = pcall(function() 
        jsonData = game:GetService("HttpService"):JSONDecode(string)  
    end)   
    return jsonData or false
end

function RoWeb:toJson(string)
    return toJson(string)
end

function RoWeb:method()
    return http_request or request or HttpPost or syn.request 
end

function RoWeb:getHeaders()
    return self.data.Headers
end

function RoWeb:getCookies()
    return self.data.Cookies
end

function RoWeb:synspy(callback)
    if (not syn) then return error("executor not supported") end
    local callbackType = type(callback)
    if (callback == nil or callbackType:lower() ~= "function") then return error("callback function expected but got "..callbackType or nil) end
    local instances = {
        HttpGet = RoWeb.Version,
        HttpGetAsync = RoWeb.Version,
        HttpPost = RoWeb.Version,
        HttpPostAsync = RoWeb.Version,
        GetObjects = RoWeb.Version
    }
    local __nc
    local QID = _G.ID
    __nc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if (_G.ID ~= QID) then return __nc(self, ...) end
        local method = getnamecallmethod()
        if (instances[method]) then
            callback({method = method, data = "game:"..method..'("'.. ... .. '")'})
        end
        return __nc(self, ...)
    end))
    local __rq
    __rq = hookfunction(request, newcclosure(function(req)
        if (_G.ID ~= QID) then return __rq(req) end
        coroutine.wrap(function()
            local s, res = pcall(__rq, req)
            if (not s) then error("error played during getting response of hooking "..req.Url) end
            callback({method = reqName, req = req, res = res})
        end)()
        return __rq(req)
    end))
    if (syn) then
        local wb
        wb = hookfunction(syn.websocket.connect, function(...)
            if (_G.ID ~= QID) then return wb(...) end
            callback({method = "syn.websocket.connect", Url = ...})
            return wb(...)
        end)
    end
end

function RoWeb:getFingerprint() 
    local fingerprint = {}
    local req = request({Url = "https://httpbin.org/headers"})
    for _, v in pairs(toJson(req.Body).headers) do
        if string.find(_:lower(), "fingerprint") then 
            fingerprint[_] = v
        elseif string.find(_:lower(), "identifier") or string.find(_:lower(), "hwid") then
            fingerprint[_] = v
        elseif string.find(_:lower(), "agent") then
            fingerprint[_] = v
        elseif string.find(_:lower(), "id") and _:lower() ~= "x-amzn-trace-id" then
            fingerprint[_] = v
        end
    end
    return fingerprint
end

function RoWeb:getBody(options)
    if options and options.JSON then 
        local success, jsonData = pcall(function() 
            return game:GetService("HttpService"):JSONDecode(self.data.Body)  
        end)
        if not success then
            return error("Cannot parse body: " .. tostring(jsonData))
        end
        return jsonData 
    end
    return self.data.Body
end

return RoWeb
