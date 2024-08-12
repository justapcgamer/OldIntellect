-- Services
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local players = game:GetService("Players")
local camera = game.Workspace.CurrentCamera
local drawingUI = Instance.new("ScreenGui")
local coreGui = game:GetService("CoreGui")
RunService = game:GetService("RunService")

-- Variables
local Executor, ExecutorVersion = "intellect", "user"
local bit32 = table.clone(bit32)
local bit = bit32
TARGET_FRAME_RATE = 0
frameStart = os.clock()
connection = nil

-- Tables
debug = table.clone(debug)
Drawings = {}
Drawing = {}
Instances = {} 
cache = {}
cached = {}
crypt = {}
crypt.base64 = {}
invalidated = {}
lz4 = {}
base64 = {}
http = {}

-- Environment Init
while not game:IsLoaded() do
    game.Loaded:Wait()
end

local player = players.LocalPlayer

if not player then
    error("intellect> localplayer is not available, some functions won't work!")
end

if not player.Character then
    player.CharacterAdded:Wait()
end

local character = player.Character
local animate = character:FindFirstChild("Animate")
if not animate then
    animate = character:WaitForChild("Animate")
end

type Streamer = {
	Offset: number,
	Source: string,
	Length: number,
	IsFinished: boolean,
	LastUnreadBytes: number,

	read: (Streamer, len: number?, shiftOffset: boolean?) -> string,
	seek: (Streamer, len: number) -> (),
	append: (Streamer, newData: string) -> (),
	toEnd: (Streamer) -> ()
}

type BlockData = {
	[number]: {
		Literal: string,
		LiteralLength: number,
		MatchOffset: number?,
		MatchLength: number?
	}
}

local function plainFind(str, pat)
	return string.find(str, pat, 0, true)
end

local function streamer(str): Streamer
	local Stream = {}
	Stream.Offset = 0
	Stream.Source = str
	Stream.Length = string.len(str)
	Stream.IsFinished = false	
	Stream.LastUnreadBytes = 0

	function Stream.read(self: Streamer, len: number?, shift: boolean?): string
		local len = len or 1
		local shift = if shift ~= nil then shift else true
		local dat = string.sub(self.Source, self.Offset + 1, self.Offset + len)

		local dataLength = string.len(dat)
		local unreadBytes = len - dataLength

		if shift then
			self:seek(len)
		end

		self.LastUnreadBytes = unreadBytes
		return dat
	end

	function Stream.seek(self: Streamer, len: number)
		local len = len or 1

		self.Offset = math.clamp(self.Offset + len, 0, self.Length)
		self.IsFinished = self.Offset >= self.Length
	end

	function Stream.append(self: Streamer, newData: string)
		self.Source ..= newData
		self.Length = string.len(self.Source)
		self:seek(0) 
	end

	function Stream.toEnd(self: Streamer)
		self:seek(self.Length)
	end

	return Stream
end

function getinstances()
    return game:GetDescendants()
end

function compareinstances(a, b)
	if not clonerefs[a] then
		return a == b
	   else
		if table.find(clonerefs[a], b) then return true end
	   end
	   return false
	  end

function getnilinstances()
	datamodel={game}game.DescendantRemoving:Connect(function(a)cache[a]='REMOVE'end)game.DescendantAdded:Connect(function(a)cache[a]=true;table.insert(datamodel,a)end)for b,c in pairs(game:GetDescendants())do table.insert(datamodel,c)end
	local nilinstances = {}
	for i, v in pairs(datamodel) do
		if v.Parent ~= nil then continue end
		table.insert(nilinstances, v)
	end 
	return nilinstances
end

function getrenv()
    return _G
end

function getgenv(): { [string]: any }
    return getfenv(2)
end

function getgc()
    local function lookatduhobjectcuhh(obj, visited, results)
        if visited[obj] then return end
        visited[obj] = true
        
        if type(obj) == "table" or type(obj) == "function" then
            table.insert(results, obj)
            if type(obj) == "table" then
                for _, v in pairs(obj) do
                    lookatduhobjectcuhh(v, visited, results)
                end
            end
        end
    end

    local visited, results = {}, {}
    lookatduhobjectcuhh(getgenv(), visited, results)
    
    return results
end

function fireclickdetector(fcd, distance, event)
	local ClickDetector = fcd:FindFirstChild("ClickDetector") or fcd
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local upval1 = ClickDetector.Parent
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Size = Vector3.new(30, 30, 30)
	part.Anchored = true
	part.CanCollide = false
	part.Parent = workspace
	ClickDetector.Parent = part
	ClickDetector.MaxActivationDistance = math.huge
	local connection = nil
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		part.CFrame = workspace.Camera.CFrame * CFrame.new(0, 0, -20) * CFrame.new(workspace.Camera.CFrame.LookVector.X, workspace.Camera.CFrame.LookVector.Y, workspace.Camera.CFrame.LookVector.Z)
		game:GetService("VirtualUser"):ClickButton1(Vector2.new(20, 20), workspace:FindFirstChildOfClass("Camera").CFrame)
	end)
	ClickDetector.MouseClick:Once(function()
		connection:Disconnect()
		ClickDetector.Parent = upval1
		part:Destroy()
	end)
end

function setfpscap(fps)
    TARGET_FRAME_RATE = fps
    if connection then
        connection:Disconnect()
    end

    if TARGET_FRAME_RATE > 0 then
        connection = RunService.PreSimulation:Connect(function()
            while os.clock() - frameStart < 1 / TARGET_FRAME_RATE do
            end
            frameStart = os.clock()
        end)
    end
end

function getcustomasset(assetID)
    if type(assetID) ~= "string" or assetID == "" then
        return ""  
    end    return "rbxasset://" .. assetID
end

function isrbxactive()
    local player = game:GetService("Players").LocalPlayer
    if player and player.Character then
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            return true
        end
    end
    return false
end

local intellect = {
    Saved_Metatable = {},
    ReadOnly = {},
    OriginalTables = {},
    Luau_setmetatable = setmetatable
}

function isreadonly(tbl)
    return intellect.ReadOnly[tbl] or table.isfrozen(tbl) or false
end

function setreadonly(tbl, readOnly)
    if readOnly then
        intellect.ReadOnly[tbl] = true
        local clone = table.clone(tbl)
        intellect.OriginalTables[clone] = tbl
        return intellect.Luau_setmetatable(clone, {
            __index = tbl,
            __newindex = function(_, key, value)
                error("attempt to modify a readonly table")
            end
        })
    else
        return tbl 
    end
end

function getrawmetatable(object)
    if type(object) ~= "table" and type(object) ~= "userdata" then
        error("expected tbl or userdata", 2)
    end
    local raw_mt = debug.getmetatable(object)
    if raw_mt and raw_mt.__metatable then
        raw_mt.__metatable = nil 
        local result_mt = debug.getmetatable(object)
        raw_mt.__metatable = "Locked!" 
        return result_mt
    end
    
    return raw_mt
end

function setrawmetatable(object, newmetatbl)
    if type(object) ~= "table" and type(object) ~= "userdata" then
        error("expected table or userdata", 2)
    end
    if type(newmetatbl) ~= "table" and newmt ~= nil then
        error("new metatable must be a table or nil", 2)
    end
    local raw_mt = debug.getmetatable(object)
        if raw_mt and raw_mt.__metatable then
        local old_metatable = raw_mt.__metatable
        raw_mt.__metatable = nil  
                local success, err = pcall(setmetatable, object, newmetatbl)
                raw_mt.__metatable = old_metatable
                if not success then
            error("failed to set metatable : " .. tostring(err), 2)
        end
        return true  
    end
        setmetatable(object, newmetatbl)
    return true
end

function isscriptable(object, property)
    if object and typeof(object) == 'Instance' then
        local success, result = pcall(function()
            return object[property] ~= nil
        end)
        return success and result
    end
    return false
end

function setscriptable(instance, property, scriptable)
    local className = instance.ClassName
        if not scriptableProperties[className] then
        scriptableProperties[className] = {}
    end
        local wasScriptable = scriptableProperties[className][property] or false
        scriptableProperties[className][property] = scriptable
        if scriptable then
        local mt = getmetatable(instance) or {}
        mt.__index = function(t, key)
            if key == property then
                return scriptable
            end
            return rawget(t, key)
        end
        mt.__newindex = function(t, key, value)
            if key == property then
                rawset(t, key, value)
            else
                rawset(t, key, value)
            end
        end
        setmetatable(instance, mt)
    end
    return wasScriptable
end

function getloadedmodules()
    local moduleScripts = {}
    for _, obj in pairs(game:GetDescendants()) do
        if typeof(obj) == "Instance" and obj:IsA("ModuleScript") then 
            table.insert(moduleScripts, obj) 
        end
    end
    return moduleScripts
end

function getrunningscripts()
    local runningScripts = {}
    for _, obj in pairs(game:GetDescendants()) do
        if typeof(obj) == "Instance" and obj:IsA("ModuleScript") then
            table.insert(runningScripts, obj)
        elseif typeof(obj) == "Instance" and obj:IsA("LocalScript") then
            if obj.Enabled == true then
                table.insert(runningScripts, obj)
            end
        end
    end
    return runningScripts
end

function getscripts()
    local scripts = {}
    for _, scriptt in game:GetDescendants() do
        if scriptt:isA("LocalScript") or scriptt:isA("ModuleScript") then
            table.insert(scripts, scriptt)
        end
    end
    return scripts
end

function getscripthash(script)
	local isValidType = nil;
	if typeof(script) == "Instance" then
		isValidType = script:IsA("Script") or script:IsA("LocalScript") or script:IsA("LuaSourceContainer")
	 end
	 assert(isValidType, "Expected a script, localscript, or LuaSourceContainer")
	 return script:GetHash()
end

function getsenv(script)
	local fakeEnvironment = getfenv()

	return setmetatable({
		script = script,
	}, {
		__index = function(self, index)
			return fakeEnvironment[index] or rawget(self, index)
		end,
		__newindex = function(self, index, value)
			xpcall(function()
				fakeEnvironment[index] = value
			end, function()
				rawset(self, index, value)
			end)
		end,
	})
end

function getconnections(event)
    if not event or not event.Connect then
        error("invalidevent")
    end
    local connections = {}
        for _, connection in ipairs(event:GetConnected()) do
        local connectinfo = {
            Enabled = connection.Enabled, 
            ForeignState = connection.ForeignState, 
            LuaConnection = connection.LuaConnection, 
            Function = connection.Function,
            Thread = connection.Thread,
            Fire = connection.Fire, 
            Defer = connection.Defer, 
            Disconnect = connection.Disconnect,
            Disable = connection.Disable, 
            Enable = connection.Enable,
        }
        
        table.insert(connections, connectinfo)
    end
    return connections
end

function cloneref(reference)
		assert(reference, "Missing #1 argument")
		assert(typeof(reference) == "Instance", "Expected #1 argument to be Instance, got "..tostring(typeof(reference)).." instead")
		if game:FindFirstChild(reference.Name)  or reference.Parent == game then 
			return reference
		else
			local class = reference.ClassName
			local cloned = Instance.new(class)
			local mt = {
				__index = reference,
				__newindex = function(t, k, v)

					if k == "Name" then
						reference.Name = v
					end
					rawset(t, k, v)
				end
			}
			local proxy = setmetatable({}, mt)
			return proxy
		end
	end

function clonefunction(fnc)
		return function(...) return fnc(...) end
	end	

function checkcaller()
 local info = debug.info(getgenv, 'slnaf')
 return debug.info(1, 'slnaf')==info
end

function debug.getinfo(f, options)
	if type(options) == "string" then
		options = string.lower(options) 
	else
		options = "sflnu"
	end
	local result = {}
	for index = 1, #options do
		local option = string.sub(options, index, index)
		if "s" == option then
			local short_src = debug.info(f, "s")
			result.short_src = short_src
			result.source = "=" .. short_src
			result.what = if short_src == "[C]" then "C" else "Lua"
		elseif "f" == option then
			result.func = debug.info(f, "f")
		elseif "l" == option then
			result.currentline = debug.info(f, "l")
		elseif "n" == option then
			result.name = debug.info(f, "n")
		elseif "u" == option or option == "a" then
			local numparams, is_vararg = debug.info(f, "a")
			result.numparams = numparams
			result.is_vararg = if is_vararg then 1 else 0
			if "u" == option then
				result.nups = -1
			end
		end
	end
	return result
end

function debug.getconstant(f, i)
    local c = debug.getconstants(f)
    return c[i]
end

function debug.getconstants(f)
    local c = {}
    local i = 1
    while true do
        local k = debug.getconstant(f, i)
        if not k then break end
        c[i] = k
        i = i + 1
    end
    return c
end

function debug.getstack(l, i)
    local s = {}
    local j = 1
    while true do
        local n, v = debug.getlocal(l + 1, j)
        if not n then break end
        s[j] = v
        j = j + 1
    end
    return i and s[i] or s
end

function debug.getupvalue(f, i)
    local _, v = debug.getupvalue(f, i)
    return v
end

function debug.getupvalues(f)
    local u = {}
    local i = 1
    while true do
        local _, v = debug.getupvalue(f, i)
        if not _ then break end
        u[i] = v
        i = i + 1
    end
    return u
end

function debug.getproto(f, index)
    local function find_prototype(func, idx)
        local count = 1
        local i = 1
        while true do
            local name, upvalue = debug.getupvalue(func, i)
            if not name then break end
            if type(upvalue) == "function" then
                if count == idx then
                    return upvalue
                end
                count = count + 1
            end
            i = i + 1
        end
        return nil
    end
    
    return find_prototype(f, index)
end

function debug.getprotos(f)
    local protos = {}
    local i = 1
        local function get_prototypes(func)
        local index = 1
        while true do
            local name, func = debug.getupvalue(func, index)
            if not name then break end
            if type(func) == "function" then
                table.insert(protos, func)
                get_prototypes(func) 
            end
            index = index + 1
        end
    end
    get_prototypes(f)
    
    return protos
end

function debug.getmetatable(tableorud)
    local result = getmetatable(tableorud)

    if result == nil then -- No meta
        return
    end

    if type(result) == "table" and pcall(setmetatable, tableorud, result) then -- This checks if it's real without overwriting
        return result --* We dont cache this as it will be the same always anyways
    end
    -- Metamethod bruteforcing
    -- For Full (except __gc & __tostring) Metamethod list Refer to - https://github.com/luau-lang/luau/blob/master/VM/src/ltm.cpp#L34

    -- Todo: Look into more ways of making metamethods error (like https://github.com/luau-lang/luau/blob/master/VM%2Fsrc%2Flvmutils.cpp#L174)

    --TODO We can also rebuild many non-dynamic things like len or arithmetic  metamethods since we know what arguments to expect in those usually

    local real_metamethods = {}

    xpcall(function()
        return tableorud._
    end, function()
        real_metamethods.__index = debug.info(2, "f")
    end)

    xpcall(function()
        tableorud._ = tableorud
    end, function()
        real_metamethods.__newindex = debug.info(2, "f")
    end)

    -- xpcall(function()
    -- -- !MAKE __mode ERROR SOMEHOW..
    -- end, function()
    -- 	newTable.__mode = debug.info(2, "f")
    -- end)

    xpcall(function()
        return tableorud:___() -- Make sure this doesn't exist in the tableorud
    end, function()
        real_metamethods.__namecall = debug.info(2, "f")
    end)

    xpcall(function()
        tableorud() -- ! This might not error on tables with __call defined
    end, function()
        real_metamethods.__call = debug.info(2, "f")
    end)

    xpcall(function() -- * LUAU
        for _ in tableorud do -- ! This will never error on tables
        end
    end, function()
        real_metamethods.__iter = debug.info(2, "f")
    end)

    xpcall(function()
        return #tableorud -- ! This will never error on tables, with userdata the issue is same as __concat - is it even a defined metamethod in that case?
    end, function()
        real_metamethods.__len = debug.info(2, "f")
    end)

    -- * Make sure type_check_semibypass lacks any metamethods
    local type_check_semibypass = {} -- bypass typechecks (which will return error instead of actual metamethod)

    xpcall(function()
        return tableorud == type_check_semibypass -- ! This will never error (it calls __eq but we need it to error); ~= can also be used
    end, function()
        real_metamethods.__eq = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud + type_check_semibypass
    end, function()
        real_metamethods.__add = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud - type_check_semibypass
    end, function()
        real_metamethods.__sub = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud * type_check_semibypass
    end, function()
        real_metamethods.__mul = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud / type_check_semibypass
    end, function()
        real_metamethods.__div = debug.info(2, "f")
    end)

    xpcall(function() -- * LUAU
        return tableorud // type_check_semibypass
    end, function()
        real_metamethods.__idiv = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud % type_check_semibypass
    end, function()
        real_metamethods.__mod = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud ^ type_check_semibypass
    end, function()
        real_metamethods.__pow = debug.info(2, "f")
    end)

    xpcall(function()
        return -tableorud
    end, function()
        real_metamethods.__unm = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud < type_check_semibypass
    end, function()
        real_metamethods.__lt = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud <= type_check_semibypass
    end, function()
        real_metamethods.__le = debug.info(2, "f")
    end)

    xpcall(function()
        return tableorud .. type_check_semibypass -- TODO Not sure if this would work on userdata.. (do they even have __concat defined? would it be called?)
    end, function()
        real_metamethods.__concat = debug.info(2, "f")
    end)

    -- xpcall(function()
    -- -- !MAKE __type ERROR SOMEHOW..
    -- end, function()
    -- 	newTable.__type = debug.info(2, "f")
    -- end)
    -- FAKE __type INBOUND
    real_metamethods.__type = typeof(tableorud)

    real_metamethods.__metatable = getmetatable(game) -- "The metatable is locked"

    -- xpcall(function()
    -- -- !MAKE __tostring  ERROR SOMEHOW..
    -- end, function()
    -- 	newTable.__tostring = debug.info(2, "f")
    -- end)

    -- FAKE __tostring INBOUND (We wrap it because 1. No rawtostring & 2. In case tableorud Name changes)
    real_metamethods.__tostring = function()
        return tostring(tableorud)
    end

    -- xpcall(function()
    -- -- !MAKE __gc ERROR SOMEHOW..
    -- end, function()
    -- 	newTable.__gc = debug.info(2, "f")
    -- end)

    -- table.freeze(real_metamethods) -- Not using for compatibility -- We can't check readonly state of an actual metatable sadly (or can we?)
    return real_metamethods
end

function debug.setconstant(f, i, v)
    local c = debug.getconstants(f)
    local tmp = function() return v end
    local nf = load(string.dump(tmp))
    debug.setupvalue(nf, 1, v)
    for j = 1, #c do
        if j == i then
            debug.setupvalue(f, j, v)
        else
            debug.setupvalue(f, j, c[j])
        end
    end
end

function debug.setstack(l, i, v)
    local n = debug.getlocal(l + 1, i)
    if n then
        debug.setlocal(l + 1, i, v)
    end
end

function debug.setupvalue(f, i, v)
    local nf = load(string.dump(f))
    local j = 1
    while true do
        local n = debug.getupvalue(nf, j)
        if not n then break end
        if j == i then
            debug.setupvalue(nf, j, v)
        else
            debug.setupvalue(nf, j, debug.getupvalue(f, j))
        end
        j = j + 1
    end
    return nf
end

function debug.setmetatable(tableorud, newmt)
    assert(type(tableorud) == "table" or type(tableorud) == "userdata", "First argument must be a table or userdata")
    assert(type(newmt) == "table" or newmt == nil, "Second argument must be a table or nil")
    local current_metatable = debug.getmetatable(tableorud)
        if current_metatable and current_metatable.__metatable then
        error("Metatable is locked and cannot be changed.")
    end
    local success, result = pcall(setmetatable, tableorud, newmt)
        if not success then
        error("Failed to set metatable: " .. tostring(result))
    end
    return newmt
end

function gethui()
    local success, hui = pcall(function()
        return game:GetService("CoreGui")["RobloxGui"]
    end)
    if success then
        return hui
    else
        warn("Failed to get RobloxGui")
        return nil
    end
end

	drawingUI.Name = "Drawing"
	drawingUI.IgnoreGuiInset = true
	drawingUI.DisplayOrder = 0x7fffffff
	drawingUI.Parent = coreGui
	local drawingIndex = 0
	local uiStrokes = table.create(0)
	local baseDrawingObj = setmetatable({
		Visible = true,
		ZIndex = 0,
		Transparency = 1,
		Color = Color3.new(),
		Remove = function(self)
			setmetatable(self, nil)
		end
	}, {
		__add = function(t1, t2)
			local result = table.clone(t1)

			for index, value in t2 do
				result[index] = value
			end
			return result
		end
	})
	local drawingFontsEnum = {
		[0] = Font.fromEnum(Enum.Font.Roboto),
		[1] = Font.fromEnum(Enum.Font.Legacy),
		[2] = Font.fromEnum(Enum.Font.SourceSans),
		[3] = Font.fromEnum(Enum.Font.RobotoMono),
	}
	-- function
	local function getFontFromIndex(fontIndex: number): Font
		return drawingFontsEnum[fontIndex]
	end

	local function convertTransparency(transparency: number): number
		return math.clamp(1 - transparency, 0, 1)
	end
	-- main
	local DrawingLib = {}
	DrawingLib.Fonts = {
		["UI"] = 0,
		["System"] = 1,
		["Plex"] = 2,
		["Monospace"] = 3
	}
	local drawings = {}
	function Drawing.new(drawingType)
		drawingIndex += 1
		if drawingType == "Line" then
			local lineObj = ({
				From = Vector2.zero,
				To = Vector2.zero,
				Thickness = 1
			} + baseDrawingObj)

			local lineFrame = Instance.new("Frame")
			lineFrame.Name = drawingIndex
			lineFrame.AnchorPoint = (Vector2.one * .5)
			lineFrame.BorderSizePixel = 0

			lineFrame.BackgroundColor3 = lineObj.Color
			lineFrame.Visible = lineObj.Visible
			lineFrame.ZIndex = lineObj.ZIndex
			lineFrame.BackgroundTransparency = convertTransparency(lineObj.Transparency)

			lineFrame.Size = UDim2.new()

			lineFrame.Parent = drawingUI
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(lineObj[index]) == "nil" then return end

					if index == "From" then
						local direction = (lineObj.To - value)
						local center = (lineObj.To + value) / 2
						local distance = direction.Magnitude
						local theta = math.deg(math.atan2(direction.Y, direction.X))

						lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
						lineFrame.Rotation = theta
						lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
					elseif index == "To" then
						local direction = (value - lineObj.From)
						local center = (value + lineObj.From) / 2
						local distance = direction.Magnitude
						local theta = math.deg(math.atan2(direction.Y, direction.X))

						lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
						lineFrame.Rotation = theta
						lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
					elseif index == "Thickness" then
						local distance = (lineObj.To - lineObj.From).Magnitude

						lineFrame.Size = UDim2.fromOffset(distance, value)
					elseif index == "Visible" then
						lineFrame.Visible = value
					elseif index == "ZIndex" then
						lineFrame.ZIndex = value
					elseif index == "Transparency" then
						lineFrame.BackgroundTransparency = convertTransparency(value)
					elseif index == "Color" then
						lineFrame.BackgroundColor3 = value
					end
					lineObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							lineFrame:Destroy()
							lineObj.Remove(self)
							return lineObj:Remove()
						end
					end
					return lineObj[index]
				end
			})
		elseif drawingType == "Text" then
			local textObj = ({
				Text = "",
				Font = DrawingLib.Fonts.UI,
				Size = 0,
				Position = Vector2.zero,
				Center = false,
				Outline = false,
				OutlineColor = Color3.new()
			} + baseDrawingObj)

			local textLabel, uiStroke = Instance.new("TextLabel"), Instance.new("UIStroke")
			textLabel.Name = drawingIndex
			textLabel.AnchorPoint = (Vector2.one * .5)
			textLabel.BorderSizePixel = 0
			textLabel.BackgroundTransparency = 1

			textLabel.Visible = textObj.Visible
			textLabel.TextColor3 = textObj.Color
			textLabel.TextTransparency = convertTransparency(textObj.Transparency)
			textLabel.ZIndex = textObj.ZIndex

			textLabel.FontFace = getFontFromIndex(textObj.Font)
			textLabel.TextSize = textObj.Size

			textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
				local textBounds = textLabel.TextBounds
				local offset = textBounds / 2

				textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
				textLabel.Position = UDim2.fromOffset(textObj.Position.X + (if not textObj.Center then offset.X else 0), textObj.Position.Y + offset.Y)
			end)

			uiStroke.Thickness = 1
			uiStroke.Enabled = textObj.Outline
			uiStroke.Color = textObj.Color

			textLabel.Parent, uiStroke.Parent = drawingUI, textLabel
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(textObj[index]) == "nil" then return end

					if index == "Text" then
						textLabel.Text = value
					elseif index == "Font" then
						value = math.clamp(value, 0, 3)
						textLabel.FontFace = getFontFromIndex(value)
					elseif index == "Size" then
						textLabel.TextSize = value
					elseif index == "Position" then
						local offset = textLabel.TextBounds / 2

						textLabel.Position = UDim2.fromOffset(value.X + (if not textObj.Center then offset.X else 0), value.Y + offset.Y)
					elseif index == "Center" then
						local position = (
							if value then
								camera.ViewportSize / 2
								else
								textObj.Position
						)

						textLabel.Position = UDim2.fromOffset(position.X, position.Y)
					elseif index == "Outline" then
						uiStroke.Enabled = value
					elseif index == "OutlineColor" then
						uiStroke.Color = value
					elseif index == "Visible" then
						textLabel.Visible = value
					elseif index == "ZIndex" then
						textLabel.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)

						textLabel.TextTransparency = transparency
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						textLabel.TextColor3 = value
					end
					textObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							textLabel:Destroy()
							textObj.Remove(self)
							return textObj:Remove()
						end
					elseif index == "TextBounds" then
						return textLabel.TextBounds
					end
					return textObj[index]
				end
			})
		elseif drawingType == "Circle" then
			local circleObj = ({
				Radius = 150,
				Position = Vector2.zero,
				Thickness = .7,
				Filled = false
			} + baseDrawingObj)

			local circleFrame, uiCorner, uiStroke = Instance.new("Frame"), Instance.new("UICorner"), Instance.new("UIStroke")
			circleFrame.Name = drawingIndex
			circleFrame.AnchorPoint = (Vector2.one * .5)
			circleFrame.BorderSizePixel = 0

			circleFrame.BackgroundTransparency = (if circleObj.Filled then convertTransparency(circleObj.Transparency) else 1)
			circleFrame.BackgroundColor3 = circleObj.Color
			circleFrame.Visible = circleObj.Visible
			circleFrame.ZIndex = circleObj.ZIndex

			uiCorner.CornerRadius = UDim.new(1, 0)
			circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)

			uiStroke.Thickness = circleObj.Thickness
			uiStroke.Enabled = not circleObj.Filled
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			circleFrame.Parent, uiCorner.Parent, uiStroke.Parent = drawingUI, circleFrame, circleFrame
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(circleObj[index]) == "nil" then return end

					if index == "Radius" then
						local radius = value * 2
						circleFrame.Size = UDim2.fromOffset(radius, radius)
					elseif index == "Position" then
						circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, .6, 0x7fffffff)
						uiStroke.Thickness = value
					elseif index == "Filled" then
						circleFrame.BackgroundTransparency = (if value then convertTransparency(circleObj.Transparency) else 1)
						uiStroke.Enabled = not value
					elseif index == "Visible" then
						circleFrame.Visible = value
					elseif index == "ZIndex" then
						circleFrame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)

						circleFrame.BackgroundTransparency = (if circleObj.Filled then transparency else 1)
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						circleFrame.BackgroundColor3 = value
						uiStroke.Color = value
					end
					circleObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							circleFrame:Destroy()
							circleObj.Remove(self)
							return circleObj:Remove()
						end
					end
					return circleObj[index]
				end
			})
		elseif drawingType == "Square" then
			local squareObj = ({
				Size = Vector2.zero,
				Position = Vector2.zero,
				Thickness = .7,
				Filled = false
			} + baseDrawingObj)

			local squareFrame, uiStroke = Instance.new("Frame"), Instance.new("UIStroke")
			squareFrame.Name = drawingIndex
			squareFrame.BorderSizePixel = 0

			squareFrame.BackgroundTransparency = (if squareObj.Filled then convertTransparency(squareObj.Transparency) else 1)
			squareFrame.ZIndex = squareObj.ZIndex
			squareFrame.BackgroundColor3 = squareObj.Color
			squareFrame.Visible = squareObj.Visible

			uiStroke.Thickness = squareObj.Thickness
			uiStroke.Enabled = not squareObj.Filled
			uiStroke.LineJoinMode = Enum.LineJoinMode.Miter

			squareFrame.Parent, uiStroke.Parent = drawingUI, squareFrame
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(squareObj[index]) == "nil" then return end

					if index == "Size" then
						squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, 0.6, 0x7fffffff)
						uiStroke.Thickness = value
					elseif index == "Filled" then
						squareFrame.BackgroundTransparency = (if value then convertTransparency(squareObj.Transparency) else 1)
						uiStroke.Enabled = not value
					elseif index == "Visible" then
						squareFrame.Visible = value
					elseif index == "ZIndex" then
						squareFrame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)

						squareFrame.BackgroundTransparency = (if squareObj.Filled then transparency else 1)
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						uiStroke.Color = value
						squareFrame.BackgroundColor3 = value
					end
					squareObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							squareFrame:Destroy()
							squareObj.Remove(self)
							return squareObj:Remove()
						end
					end
					return squareObj[index]
				end
			})
		elseif drawingType == "Image" then
			local imageObj = ({
				Data = "",
				DataURL = "rbxassetid://0",
				Size = Vector2.zero,
				Position = Vector2.zero
			} + baseDrawingObj)

			local imageFrame = Instance.new("ImageLabel")
			imageFrame.Name = drawingIndex
			imageFrame.BorderSizePixel = 0
			imageFrame.ScaleType = Enum.ScaleType.Stretch
			imageFrame.BackgroundTransparency = 1

			imageFrame.Visible = imageObj.Visible
			imageFrame.ZIndex = imageObj.ZIndex
			imageFrame.ImageTransparency = convertTransparency(imageObj.Transparency)
			imageFrame.ImageColor3 = imageObj.Color

			imageFrame.Parent = drawingUI
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(imageObj[index]) == "nil" then return end

					if index == "Data" then
						-- later
					elseif index == "DataURL" then -- temporary property
						imageFrame.Image = value
					elseif index == "Size" then
						imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Visible" then
						imageFrame.Visible = value
					elseif index == "ZIndex" then
						imageFrame.ZIndex = value
					elseif index == "Transparency" then
						imageFrame.ImageTransparency = convertTransparency(value)
					elseif index == "Color" then
						imageFrame.ImageColor3 = value
					end
					imageObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							imageFrame:Destroy()
							imageObj.Remove(self)
							return imageObj:Remove()
						end
					elseif index == "Data" then
						return nil -- TODO: add error here
					end
					return imageObj[index]
				end
			})
		elseif drawingType == "Quad" then
			local quadObj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				PointD = Vector3.zero,
				Thickness = 1,
				Filled = false
			} + baseDrawingObj)

			local _linePoints = table.create(0)
			_linePoints.A = DrawingLib.new("Line")
			_linePoints.B = DrawingLib.new("Line")
			_linePoints.C = DrawingLib.new("Line")
			_linePoints.D = DrawingLib.new("Line")
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(quadObj[index]) == "nil" then return end

					if index == "PointA" then
						_linePoints.A.From = value
						_linePoints.B.To = value
					elseif index == "PointB" then
						_linePoints.B.From = value
						_linePoints.C.To = value
					elseif index == "PointC" then
						_linePoints.C.From = value
						_linePoints.D.To = value
					elseif index == "PointD" then
						_linePoints.D.From = value
						_linePoints.A.To = value
					elseif (index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex") then
						for _, linePoint in _linePoints do
							linePoint[index] = value
						end
					elseif index == "Filled" then
						-- later
					end
					quadObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" then
						return function()
							for _, linePoint in _linePoints do
								linePoint:Remove()
							end

							quadObj.Remove(self)
							return quadObj:Remove()
						end
					end
					if index == "Destroy" then
						return function()
							for _, linePoint in _linePoints do
								linePoint:Remove()
							end

							quadObj.Remove(self)
							return quadObj:Remove()
						end
					end
					return quadObj[index]
				end
			})
		elseif drawingType == "Triangle" then
			local triangleObj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				Thickness = 1,
				Filled = false
			} + baseDrawingObj)

			local _linePoints = table.create(0)
			_linePoints.A = DrawingLib.new("Line")
			_linePoints.B = DrawingLib.new("Line")
			_linePoints.C = DrawingLib.new("Line")
			local bs = table.create(0)
			table.insert(drawings,bs)
			return setmetatable(bs, {
				__newindex = function(_, index, value)
					if typeof(triangleObj[index]) == "nil" then return end

					if index == "PointA" then
						_linePoints.A.From = value
						_linePoints.B.To = value
					elseif index == "PointB" then
						_linePoints.B.From = value
						_linePoints.C.To = value
					elseif index == "PointC" then
						_linePoints.C.From = value
						_linePoints.A.To = value
					elseif (index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex") then
						for _, linePoint in _linePoints do
							linePoint[index] = value
						end
					elseif index == "Filled" then
						-- later
					end
					triangleObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" then
						return function()
							for _, linePoint in _linePoints do
								linePoint:Remove()
							end

							triangleObj.Remove(self)
							return triangleObj:Remove()
						end
					end
					if index == "Destroy" then
						return function()
							for _, linePoint in _linePoints do
								linePoint:Remove()
							end

							triangleObj.Remove(self)
							return triangleObj:Remove()
						end
					end
					return triangleObj[index]
				end
			})
		end
	end

Drawing.Fonts = {
    ['UI'] = 0,
    ['System'] = 1,
    ['Plex'] = 2,
    ['Monospace'] = 3
}

function isrenderobj(thing)
    return Drawings[thing] ~= nil
end

function getrenderproperty(thing, prop)
    return thing[prop]
end

function setrenderproperty(thing, prop, val)
    local success, err = pcall(function()
        thing[prop] = val
    end)
    if not success and err then 
        warn(err) 
    end
end

function cleardrawcache()
 for _, v in pairs(Drawings) do
  v:Remove()
 end
 table.clear(Drawings)
end

function mouse1click(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 0, true, game, false)
	task.wait()
	vim:SendMouseButtonEvent(x, y, 0, false, game, false)
  end
  
  function mouse2click(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 1, true, game, false)
	task.wait()
	vim:SendMouseButtonEvent(x, y, 1, false, game, false)
  end
  
  function mouse1press(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 0, true, game, false)
  end
  
  function mouse1release(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 0, false, game, false)
  end
  
  function mouse2press(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 1, true, game, false)
  end
  
  function mouse2release(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseButtonEvent(x, y, 1, false, game, false)
  end
  
  function mousescroll(x, y, a)
	x = x or 0
	y = y or 0
	a = a and true or false
	vim:SendMouseWheelEvent(x, y, a, game)
  end
  
  function keyclick(key)
	if typeof(key) == 'number' then
	  if not keys[key] then 
		return error("Key "..tostring(key) .. ' not found!') 
	  end
	  vim:SendKeyEvent(true, keys[key], false, game)
	  task.wait()
	  vim:SendKeyEvent(false, keys[key], false, game)
	elseif typeof(key) == 'EnumItem' then
	  vim:SendKeyEvent(true, key, false, game)
	  task.wait()
	  vim:SendKeyEvent(false, key, false, game)
	end
  end
  
  function keypress(key)
	if typeof(key) == 'number' then
	  if not keys[key] then 
		return error("Key "..tostring(key) .. ' not found!') 
	  end
	  vim:SendKeyEvent(true, keys[key], false, game)
	elseif typeof(key) == 'EnumItem' then
	  vim:SendKeyEvent(true, key, false, game)
	end
  end
  
  function keyrelease(key)
	if typeof(key) == 'number' then
	  if not keys[key] then 
		return error("Key "..tostring(key) .. ' not found!') 
	  end
	  vim:SendKeyEvent(false, keys[key], false, game)
	elseif typeof(key) == 'EnumItem' then
	  vim:SendKeyEvent(false, key, false, game)
	end
  end
  
  function mousemoverel(relx, rely)
	local Pos = workspace.CurrentCamera.ViewportSize
	relx = relx or 0
	rely = rely or 0
	local x = Pos.X * relx
	local y = Pos.Y * rely
	vim:SendMouseMoveEvent(x, y, game)
  end
  
  function mousemoveabs(x, y)
	x = x or 0
	y = y or 0
	vim:SendMouseMoveEvent(x, y, game)
  end

function cache.iscached(thing)
    if not thing.Parent then
        return cache[thing] ~= 'REMOVE'
    else
        return false
    end
end

function cache.invalidate(thing)
    cache[thing] = 'REMOVE'
    thing.Parent = nil
end

function cache.replace(a, b)
    if cache[a] then
        cache[a] = b
    end
end

function crypt.base64encode(data)
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6-i) or 0) end
        return letters:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

function crypt.base64decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0')
        end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0)
        end
        return string.char(c)
    end))
end

local function a(b)return string.gsub(b,".",function(c)return string.format("%02x",string.byte(c))end)end;local function d(e,f)local b=""for g=1,f do local h=e%256;b=string.char(h)..b;e=(e-h)/256 end;return b end;local function i(b,g)local f=0;for j=g,g+3 do f=f*256+string.byte(b,j)end;return f end;local function k(l,m)local n=64-(m+9)%64;m=d(8*m,8)l=l.."\128"..string.rep("\0",n)..m;assert(#l%64==0)return l end;local function o(l,g,p)local q={}local r={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}for j=1,16 do q[j]=i(l,g+(j-1)*4)end;for j=17,64 do local s=q[j-15]local t=bit.bxor(bit.rrotate(s,7),bit.rrotate(s,18),bit.rshift(s,3))s=q[j-2]local u=bit.bxor(bit.rrotate(s,17),bit.rrotate(s,19),bit.rshift(s,10))q[j]=(q[j-16]+t+q[j-7]+u)%2^32 end;local v,w,c,x,y,z,A,B=p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8]for g=1,64 do local t=bit.bxor(bit.rrotate(v,2),bit.rrotate(v,13),bit.rrotate(v,22))local C=bit.bxor(bit.band(v,w),bit.band(v,c),bit.band(w,c))local D=(t+C)%2^32;local u=bit.bxor(bit.rrotate(y,6),bit.rrotate(y,11),bit.rrotate(y,25))local E=bit.bxor(bit.band(y,z),bit.band(bit.bnot(y),A))local F=(B+u+E+r[g]+q[g])%2^32;B=A;A=z;z=y;y=(x+F)%2^32;x=c;c=w;w=v;v=(F+D)%2^32 end;p[1]=(p[1]+v)%2^32;p[2]=(p[2]+w)%2^32;p[3]=(p[3]+c)%2^32;p[4]=(p[4]+x)%2^32;p[5]=(p[5]+y)%2^32;p[6]=(p[6]+z)%2^32;p[7]=(p[7]+A)%2^32;p[8]=(p[8]+B)%2^32 end;function crypt.hash(l)l=k(l,#l)local p={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}for g=1,#l,64 do o(l,g,p)end;return a(d(p[1],4)..d(p[2],4)..d(p[3],4)..d(p[4],4)..d(p[5],4)..d(p[6],4)..d(p[7],4)..d(p[8],4))end

function crypt.generatebytes(size)
    local randomBytes = table.create(size)
    for i = 1, size do
        randomBytes[i] = string.char(math.random(0, 255))
    end
    return crypt.base64encode(table.concat(randomBytes))
end

function crypt.generatekey()
    return crypt.generatebytes(32)
end

function crypt.encrypt(plaintext, key)
	local result = {}
	plaintext = tostring(plaintext)
	key = tostring(key)
	for i = 1, #plaintext do
		local byte = string.byte(plaintext, i)
		local keyByte = string.byte(key, (i - 1) % #key + 1)
		table.insert(result, string.format("%02X", bit32.bxor(byte, keyByte)))
	end
	return table.concat(result)
end

function crypt.decrypt(hex, key)
	local result = {}
	key = tostring(key)
	for i = 1, #hex, 2 do
		local byte_str = string.sub(hex, i, i+1)
		local byte = tonumber(byte_str, 16)
		local keyByte = string.byte(key, ((i - 1) // 2) % #key + 1)
		table.insert(result, string.char(bit32.bxor(byte, keyByte)))
	end
	return table.concat(result)
end

function lz4compress(str: string): string
	local blocks: BlockData = {}
	local iostream = streamer(str)
	if iostream.Length > 12 then
		local firstFour = iostream:read(4)
		local processed = firstFour
		local lit = firstFour
		local match = ""
		local LiteralPushValue = ""
		local pushToLiteral = true
		repeat
			pushToLiteral = true
			local nextByte = iostream:read()
			if plainFind(processed, nextByte) then
				local next3 = iostream:read(3, false)
				if string.len(next3) < 3 then
					LiteralPushValue = nextByte .. next3
					iostream:seek(3)
				else
					match = nextByte .. next3
					local matchPos = plainFind(processed, match)
					if matchPos then
						iostream:seek(3)
						repeat
							local nextMatchByte = iostream:read(1, false)
							local newResult = match .. nextMatchByte

							local repos = plainFind(processed, newResult) 
							if repos then
								match = newResult
								matchPos = repos
								iostream:seek(1)
							end
						until not plainFind(processed, newResult) or iostream.IsFinished
						local matchLen = string.len(match)
						local pushMatch = true
						if iostream.Length - iostream.Offset <= 5 then
							LiteralPushValue = match
							pushMatch = false
						end
						if pushMatch then
							pushToLiteral = false
							local realPosition = string.len(processed) - matchPos
							processed = processed .. match
							table.insert(blocks, {
								Literal = lit,
								LiteralLength = string.len(lit),
								MatchOffset = realPosition + 1,
								MatchLength = matchLen,
							})
							lit = ""
						end
					else
						LiteralPushValue = nextByte
					end
				end
			else
				LiteralPushValue = nextByte
			end
			if pushToLiteral then
				lit = lit .. LiteralPushValue
				processed = processed .. nextByte
			end
		until iostream.IsFinished
		table.insert(blocks, {
			Literal = lit,
			LiteralLength = string.len(lit)
		})
	else
		local str = iostream.Source
		blocks[1] = {
			Literal = str,
			LiteralLength = string.len(str)
		}
	end
	local output = string.rep("\x00", 4)
	local function write(char)
		output = output .. char
	end
	for chunkNum, chunk in blocks do
		local litLen = chunk.LiteralLength
		local matLen = (chunk.MatchLength or 4) - 4
		local tokenLit = math.clamp(litLen, 0, 15)
		local tokenMat = math.clamp(matLen, 0, 15)
		local token = bit32.lshift(tokenLit, 4) + tokenMat
		write(string.pack("<I1", token))
		if litLen >= 15 then
			litLen = litLen - 15
			repeat
				local nextToken = math.clamp(litLen, 0, 0xFF)
				write(string.pack("<I1", nextToken))
				if nextToken == 0xFF then
					litLen = litLen - 255
				end
			until nextToken < 0xFF
		end
		write(chunk.Literal)
		if chunkNum ~= #blocks then
			write(string.pack("<I2", chunk.MatchOffset))
			if matLen >= 15 then
				matLen = matLen - 15
				repeat
					local nextToken = math.clamp(matLen, 0, 0xFF)
					write(string.pack("<I1", nextToken))
					if nextToken == 0xFF then
						matLen = matLen - 255
					end
				until nextToken < 0xFF
			end
		end
	end
	local compLen = string.len(output) - 4
	local decompLen = iostream.Length
	return string.pack("<I4", compLen) .. string.pack("<I4", decompLen) .. output
end

function lz4decompress(lz4data: string): string
	local inputStream = streamer(lz4data)
	local compressedLen = string.unpack("<I4", inputStream:read(4))
	local decompressedLen = string.unpack("<I4", inputStream:read(4))
	local reserved = string.unpack("<I4", inputStream:read(4))
	if compressedLen == 0 then
		return inputStream:read(decompressedLen)
	end
	local outputStream = streamer("")
	repeat
		local token = string.byte(inputStream:read())
		local litLen = bit32.rshift(token, 4)
		local matLen = bit32.band(token, 15) + 4
		if litLen >= 15 then
			repeat
				local nextByte = string.byte(inputStream:read())
				litLen += nextByte
			until nextByte ~= 0xFF
		end
		local literal = inputStream:read(litLen)
		outputStream:append(literal)
		outputStream:toEnd()
		if outputStream.Length < decompressedLen then
			local offset = string.unpack("<I2", inputStream:read(2))
			if matLen >= 19 then
				repeat
					local nextByte = string.byte(inputStream:read())
					matLen += nextByte
				until nextByte ~= 0xFF
			end
			outputStream:seek(-offset)
			local pos = outputStream.Offset
			local match = outputStream:read(matLen)
			local unreadBytes = outputStream.LastUnreadBytes
			local extra
			if unreadBytes then
				repeat
					outputStream.Offset = pos
					extra = outputStream:read(unreadBytes)
					unreadBytes = outputStream.LastUnreadBytes
					match ..= extra
				until unreadBytes <= 0
			end
			outputStream:append(match)
			outputStream:toEnd()
		end
	until outputStream.Length >= decompressedLen
	return outputStream.Source
end

function iscclosure(func)
    return debug.info(func, "s") == "[C]"
end

function islclosure(func)
    return debug.info(func, "s") ~= "[C]"
end

function newlclosure(func)
    return function(bullshit)
        return func(bullshit)
    end
end

function newcclosure(func)
    local wrappedFunc
    wrappedFunc = function(...)
        return func(...)
    end
    local coroutineFunc = coroutine.wrap(wrappedFunc)
    return coroutineFunc
end

function islua(func)
    return debug.info(func, "s") ~= "[C]"
end

function isexecutorclosure(closure)
    if closure == print then
        return false
    end
    
    for _, v in pairs(_G) do
        if v == closure then
            return false
        end
    end
    
    return true
end

function getscriptclosure(script)
    return function()
        return table.clone(require(script))
    end
end

function identifyexecutor()
    return Executor, ExecutorVersion
end

function getthreadidentity()
    identity = 3
    return identity
end

function getcallbackvalue(object, methodName, ...)
    if object and type(object[methodName]) == "function" then
        return object[methodName]
    end
    local args = {...}
    return args[1]  
end

function request(args)
	local Body = nil
	local Timeout = 0
	local function callback(success, body)
	 Body = body
	 Body['Success'] = success
	end
	HttpService:RequestInternal(args):Start(callback)
	while not Body and Timeout < 10 do
	 task.wait(.00000001)
	 Timeout = Timeout + .1
	end
	return Body
   end

function ezrqst(url, method, body)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local args = {
        Url = url,
        Method = method,
        Headers = headers,
        Body = body and HttpService:JSONEncode(body) or nil
    }

    local success, response = pcall(function() return request(args) end)
    if success and response.Success then
        return response.Body
    else
        return nil, "Request failed with status: " .. (response and response.StatusCode or "Unknown")
    end
end

function HttpGet(url)
    local response, errorMsg = ezrqst(url, "GET", nil)
    if response then
        return response
    else
        warn(errorMsg)
        return nil
    end
end

function getclipboard()
    local url = "http://localhost:443/getclipboard"
    local response = ezrqst(url, "GET")
    if response and response.content then
        print(response.content)
    else
        print("No content found or request failed: " .. (response.error or "Unknown error"))
    end
end

function setclipboard(content)
    local url = "http://localhost:443/setclipboard"
    local body = { content = content }
    local response = ezrqst(url, "POST", body)
    if response and response.message then
        print(response.message)
    else
        print("Request failed: " .. (response.error or "Unknown error"))
    end
end

function messagebox(message)
    local url = "http://localhost:443/messagebox"
    local headers = { ["Content-Type"] = "text/plain" }
    local body = message  
    local response, error = ezrqst(url, "POST", body, headers)
    if response then
        print(response)
    else
        print("Request failed: " .. (error or "Unknown error"))
    end
end

function isfolder(path)
    local url = "http://localhost:443/isfolder"
    local body = { path = path }
    local response = ezrqst(url, "POST", body)
    return response and response.is_folder or false
end

function makefolder(path)
    local url = "http://localhost:443/makefolder"
    local body = { path = path }
    ezrqst(url, "POST", body)
end

function writefile(path, content)
    local url = "http://localhost:443/writefile"
    local body = { path = path, content = content }
    local response = ezrqst(url, "POST", body)
end

function listfiles(path, content)
    local url = "http://localhost:443/listfiles"
    local body = { path = path, content = content }
    ezrqst(url, "POST", body)
end

function makefile(path, content)
    local url = "http://localhost:443/makefile"
    local body = { path = path, content = content }
    ezrqst(url, "POST", body)
end

function appendfile(path, content)
    local url = "http://localhost:443/appendfile"
    local body = { path = path, content = content }
    ezrqst(url, "POST", body)
end

function readfile(path)
    local url = "http://localhost:443/readfile"
    local body = { path = path }
    local response = ezrqst(url, "POST", body)
    return response and response.content or ""
end

function isfile(path)
    local url = "http://localhost:443/isfile"
    local body = { path = path }
    local response = ezrqst(url, "POST", body)
    return response.is_file
end

function delfile(path)
    local url = "http://localhost:443/delfile"
    local body = { path = path }
    ezrqst(url, "POST", body)
end

function getidentity()
    return getthreadidentity()
end

function getthreadcontext()
    return getthreadidentity()
end

function setidentity()
    return setthreadidentity()
end

function setthreadcontext()
    return setthreadidentity()
end

function checkclosure()
    return isexecutorclosure()
end

function isourclosure()
    return isexecutorclosure()
end

function crypt.base64_encode(data)
    return base64encode(data)
end

function base64_encode(data)
    return base64encode(data)
end

function base64.encode(data)
    return base64encode(data)
end

function crypt.base64_decode(data)
    return base64decode(data)
end

function crypt.base64.encode(data)
	return base64encode(data)
end

function crypt.base64.decode(data)
	return base64decode(data)
end

function base64_decode(data)
    return base64decode(data)
end

function base64.decode(data)
    return base64decode(data)
end

function http.request(args)
	return request(args)
end

function http_request(args)
	return request(args)
end

function isgameactive()
	return isrbxactive()
end

function toclipboard(content)
	return setclipboard(content)
end

function getexecutorname()
	return identifyexecutor()
end

function replaceclosure()
    return replaceclosure
end

function getscriptfunction(ohio)
    return getscriptclosure(ohio)
end

function dumpstring()
    return dumpstring
end

function queueonteleport()
    return queueonteleport
end

function consoleclear()
    return consoleclear
end

function consolecreate()
    return consolecreate
end

function consoledestroy()
    return consoledestroy
end

function consoleinput()
    return consoleinput
end

function consoleprint()
    return consoleprint
end

function rconsolename()
    return rconsolename
end

function consolesettitle()
    return consolesettitle
end

local RunBytecode = coroutine.wrap(function()
	-- // Environment changes in the VM are not supposed to alter the behaviour of the VM so we localise globals beforehand
	local type = type
	local pcall = pcall
	local error = error
	local tonumber = tonumber
	local assert = assert
	local setmetatable = setmetatable

	local string_format = string.format

	local table_move = table.move
	local table_pack = table.pack
	local table_unpack = table.unpack
	local table_create = table.create
	local table_insert = table.insert
	local table_remove = table.remove

	local coroutine_create = coroutine.create
	local coroutine_yield = coroutine.yield
	local coroutine_resume = coroutine.resume
	local coroutine_close = coroutine.close

	local buffer_fromstring = buffer.fromstring
	local buffer_len = buffer.len
	local buffer_readu8 = buffer.readu8
	local buffer_readu32 = buffer.readu32
	local buffer_readstring = buffer.readstring
	local buffer_readf32 = buffer.readf32
	local buffer_readf64 = buffer.readf64

	local bit32_bor = bit32.bor
	local bit32_band = bit32.band
	local bit32_btest = bit32.btest
	local bit32_rshift = bit32.rshift
	local bit32_lshift = bit32.lshift
	local bit32_extract = bit32.extract

	local ttisnumber = function(v) return type(v) == "number" end
	local ttisstring = function(v) return type(v) == "string" end
	local ttisboolean = function(v) return type(v) == "boolean" end
	local ttisfunction = function(v) return type(v) == "function" end

	-- // opList contains information about the instruction, each instruction is defined in this format:
	-- // {OP_NAME, OP_MODE, K_MODE, HAS_AUX}
	-- // OP_MODE specifies what type of registers the instruction uses if any
	--		0 = NONE
	--		1 = A
	--		2 = AB
	--		3 = ABC
	--		4 = AD
	--		5 = AE
	-- // K_MODE specifies if the instruction has a register that holds a constant table index, which will be directly converted to the constant in the 2nd pass
	--		0 = NONE
	--		1 = AUX
	--		2 = C
	--		3 = D
	--		4 = AUX import
	--		5 = AUX boolean low 1 bit
	--		6 = AUX number low 24 bits
	-- // HAS_AUX boolean specifies whether the instruction is followed up with an AUX word, which may be used to execute the instruction.

	local opList = {
		{ "NOP", 0, 0, false },
		{ "BREAK", 0, 0, false },
		{ "LOADNIL", 1, 0, false },
		{ "LOADB", 3, 0, false },
		{ "LOADN", 4, 0, false },
		{ "LOADK", 4, 3, false },
		{ "MOVE", 2, 0, false },
		{ "GETGLOBAL", 1, 1, true },
		{ "SETGLOBAL", 1, 1, true },
		{ "GETUPVAL", 2, 0, false },
		{ "SETUPVAL", 2, 0, false },
		{ "CLOSEUPVALS", 1, 0, false },
		{ "GETIMPORT", 4, 4, true },
		{ "GETTABLE", 3, 0, false },
		{ "SETTABLE", 3, 0, false },
		{ "GETTABLEKS", 3, 1, true },
		{ "SETTABLEKS", 3, 1, true },
		{ "GETTABLEN", 3, 0, false },
		{ "SETTABLEN", 3, 0, false },
		{ "NEWCLOSURE", 4, 0, false },
		{ "NAMECALL", 3, 1, true },
		{ "CALL", 3, 0, false },
		{ "RETURN", 2, 0, false },
		{ "JUMP", 4, 0, false },
		{ "JUMPBACK", 4, 0, false },
		{ "JUMPIF", 4, 0, false },
		{ "JUMPIFNOT", 4, 0, false },
		{ "JUMPIFEQ", 4, 0, true },
		{ "JUMPIFLE", 4, 0, true },
		{ "JUMPIFLT", 4, 0, true },
		{ "JUMPIFNOTEQ", 4, 0, true },
		{ "JUMPIFNOTLE", 4, 0, true },
		{ "JUMPIFNOTLT", 4, 0, true },
		{ "ADD", 3, 0, false },
		{ "SUB", 3, 0, false },
		{ "MUL", 3, 0, false },
		{ "DIV", 3, 0, false },
		{ "MOD", 3, 0, false },
		{ "POW", 3, 0, false },
		{ "ADDK", 3, 2, false },
		{ "SUBK", 3, 2, false },
		{ "MULK", 3, 2, false },
		{ "DIVK", 3, 2, false },
		{ "MODK", 3, 2, false },
		{ "POWK", 3, 2, false },
		{ "AND", 3, 0, false },
		{ "OR", 3, 0, false },
		{ "ANDK", 3, 2, false },
		{ "ORK", 3, 2, false },
		{ "CONCAT", 3, 0, false },
		{ "NOT", 2, 0, false },
		{ "MINUS", 2, 0, false },
		{ "LENGTH", 2, 0, false },
		{ "NEWTABLE", 2, 0, true },
		{ "DUPTABLE", 4, 3, false },
		{ "SETLIST", 3, 0, true },
		{ "FORNPREP", 4, 0, false },
		{ "FORNLOOP", 4, 0, false },
		{ "FORGLOOP", 4, 8, true },
		{ "FORGPREP_INEXT", 4, 0, false },
		{ "FASTCALL3", 3, 1, true },
		{ "FORGPREP_NEXT", 4, 0, false },
		{ "DEP_FORGLOOP_NEXT", 0, 0, false },
		{ "GETVARARGS", 2, 0, false },
		{ "DUPCLOSURE", 4, 3, false },
		{ "PREPVARARGS", 1, 0, false },
		{ "LOADKX", 1, 1, true },
		{ "JUMPX", 5, 0, false },
		{ "FASTCALL", 3, 0, false },
		{ "COVERAGE", 5, 0, false },
		{ "CAPTURE", 2, 0, false },
		{ "SUBRK", 3, 7, false },
		{ "DIVRK", 3, 7, false },
		{ "FASTCALL1", 3, 0, false },
		{ "FASTCALL2", 3, 0, true },
		{ "FASTCALL2K", 3, 1, true },
		{ "FORGPREP", 4, 0, false },
		{ "JUMPXEQKNIL", 4, 5, true },
		{ "JUMPXEQKB", 4, 5, true },
		{ "JUMPXEQKN", 4, 6, true },
		{ "JUMPXEQKS", 4, 6, true },
		{ "IDIV", 3, 0, false },
		{ "IDIVK", 3, 2, false },
	}

	local LUA_MULTRET = -1
	local LUA_GENERALIZED_TERMINATOR = -2

	local function luau_newsettings()
		return {
			vectorCtor = function() warn("vectorCtor was not provided") end,
			vectorSize = 4,
			useNativeNamecall = false,
			namecallHandler = function() warn("Native __namecall handler was not provided") end,
			extensions = {},
			callHooks = {},
			errorHandling = true,
			generalizedIteration = true,
			allowProxyErrors = false,
			useImportConstants = false,
			staticEnvironment = {},
		}
	end

	local function luau_validatesettings(luau_settings)
		assert(type(luau_settings) == "table", "luau_settings should be a table")
		assert(type(luau_settings.vectorCtor) == "function", "luau_settings.vectorCtor should be a function")
		assert(type(luau_settings.vectorSize) == "number", "luau_settings.vectorSize should be a number")
		assert(type(luau_settings.useNativeNamecall) == "boolean", "luau_settings.useNativeNamecall should be a boolean")
		assert(type(luau_settings.namecallHandler) == "function", "luau_settings.namecallHandler should be a function")
		assert(type(luau_settings.extensions) == "table", "luau_settings.extensions should be a table of functions")
		assert(type(luau_settings.callHooks) == "table", "luau_settings.callHooks should be a table of functions")
		assert(type(luau_settings.errorHandling) == "boolean", "luau_settings.errorHandling should be a boolean")
		assert(type(luau_settings.generalizedIteration) == "boolean", "luau_settings.generalizedIteration should be a boolean")
		assert(type(luau_settings.allowProxyErrors) == "boolean", "luau_settings.allowProxyErrors should be a boolean")
		assert(type(luau_settings.staticEnvironment) == "table", "luau_settings.staticEnvironment should be a table")
		assert(type(luau_settings.useImportConstants) == "boolean", "luau_settings.useImportConstants should be a boolean")
	end

	local function resolveImportConstant(static, count, k0, k1, k2)
		local res = static[k0]
		if count < 2 or res == nil then
			return res
		end
		res = res[k1]
		if count < 3 or res == nil then
			return res
		end
		res = res[k2]
		return res
	end

	local function luau_deserialize(bytecode, luau_settings)
		if luau_settings == nil then
			luau_settings = luau_newsettings()
		else 
			luau_validatesettings(luau_settings)
		end

		-- local stream = if type(bytecode) == "string" then buffer_fromstring(bytecode) else bytecode
		local stream = bytecode
        local cursor = 0

		local function readByte()
			local byte = buffer_readu8(stream, cursor)
			cursor = cursor + 1
			return byte
		end

		local function readWord()
			local word = buffer_readu32(stream, cursor)
			cursor = cursor + 4
			return word
		end

		local function readFloat()
			local float = buffer_readf32(stream, cursor)
			cursor = cursor + 4
			return float
		end

		local function readDouble()
			local double = buffer_readf64(stream, cursor)
			cursor = cursor + 8
			return double
		end

		local function readVarInt()
			local result = 0

			for i = 0, 4 do
				local value = readByte()
				result = bit32_bor(result, bit32_lshift(bit32_band(value, 0x7F), i * 7))
				if not bit32_btest(value, 0x80) then
					break
				end
			end

			return result
		end

		local function readString()
			local size = readVarInt()

			if size == 0 then
				return ""
			else
				local str = buffer_readstring(stream, cursor, size)
				cursor = cursor + size

				return str
			end
		end

		local luauVersion = readByte()
		local typesVersion = 0
		if luauVersion == 0 then
			warn("Failed to run script: Bad script", 0)
		elseif luauVersion < 3 or luauVersion > 6 then
			warn("Script unsupported", 0)
		elseif luauVersion >= 4 then
			typesVersion = readByte()
		end

		local stringCount = readVarInt()
		local stringList = table_create(stringCount)

		for i = 1, stringCount do
			stringList[i] = readString()
        end
        
		local function readInstruction(codeList)
			local value = readWord()
            
			local opcode = bit32_band(value, 0xFF)
			local opinfo = opList[opcode + 1]
			local opname = opinfo[1]
			local opmode = opinfo[2]
			local kmode = opinfo[3]
			local usesAux = opinfo[4]

			local inst = {
				opcode = opcode;
				opname = opname;
				opmode = opmode;
				kmode = kmode;
				usesAux = usesAux;
			}

			table_insert(codeList, inst)

			if opmode == 1 then --[[ A ]]
				inst.A = bit32_band(bit32_rshift(value, 8), 0xFF)
			elseif opmode == 2 then --[[ AB ]]
				inst.A = bit32_band(bit32_rshift(value, 8), 0xFF)
				inst.B = bit32_band(bit32_rshift(value, 16), 0xFF)
			elseif opmode == 3 then --[[ ABC ]]
				inst.A = bit32_band(bit32_rshift(value, 8), 0xFF)
				inst.B = bit32_band(bit32_rshift(value, 16), 0xFF)
				inst.C = bit32_band(bit32_rshift(value, 24), 0xFF)
			elseif opmode == 4 then --[[ AD ]]
				inst.A = bit32_band(bit32_rshift(value, 8), 0xFF)
				local temp = bit32_band(bit32_rshift(value, 16), 0xFFFF)
				inst.D = if temp < 0x8000 then temp else temp - 0x10000
			elseif opmode == 5 then --[[ AE ]]
				local temp = bit32_band(bit32_rshift(value, 8), 0xFFFFFF)
				inst.E = if temp < 0x800000 then temp else temp - 0x1000000
			end

			if usesAux then 
				local aux = readWord()
				inst.aux = aux

				table_insert(codeList, {value = aux, opname = "auxvalue" })
			end

			return usesAux
		end

		local function checkkmode(inst, k)
			local kmode = inst.kmode

			if kmode == 1 then --// AUX
				inst.K = k[inst.aux +  1]
			elseif kmode == 2 then --// C
				inst.K = k[inst.C + 1]
			elseif kmode == 3 then--// D
				inst.K = k[inst.D + 1]
			elseif kmode == 4 then --// AUX import
				local extend = inst.aux
				local count = bit32_rshift(extend, 30)
				local id0 = bit32_band(bit32_rshift(extend, 20), 0x3FF)

				inst.K0 = k[id0 + 1]
				inst.KC = count
				if count == 2 then
					local id1 = bit32_band(bit32_rshift(extend, 10), 0x3FF)

					inst.K1 = k[id1 + 1]
				elseif count == 3 then
					local id1 = bit32_band(bit32_rshift(extend, 10), 0x3FF)
					local id2 = bit32_band(bit32_rshift(extend, 0), 0x3FF)

					inst.K1 = k[id1 + 1]
					inst.K2 = k[id2 + 1]
				end
				if luau_settings.useImportConstants then
					inst.K = resolveImportConstant(
						luau_settings.staticEnvironment,
						count, inst.K0, inst.K1, inst.K2
					)
				end
			elseif kmode == 5 then --// AUX boolean low 1 bit
				inst.K = bit32_extract(inst.aux, 0, 1) == 1
				inst.KN = bit32_extract(inst.aux, 31, 1) == 1
			elseif kmode == 6 then --// AUX number low 24 bits
				inst.K = k[bit32_extract(inst.aux, 0, 24) + 1]
				inst.KN = bit32_extract(inst.aux, 31, 1) == 1
			elseif kmode == 7 then --// B
				inst.K = k[inst.B + 1]
			elseif kmode == 8 then --// AUX number low 16 bits
				inst.K = bit32_band(inst.aux, 0xf)
			end
		end

		local function readProto(bytecodeid)
			local maxstacksize = readByte()
			local numparams = readByte()
			local nups = readByte()
			local isvararg = readByte() ~= 0

			if luauVersion >= 4 then
				readByte() --// flags 
				local typesize = readVarInt();
				cursor = cursor + typesize;
			end

			local sizecode = readVarInt()
			local codelist = table_create(sizecode)

			local skipnext = false 
			for i = 1, sizecode do
				if skipnext then 
					skipnext = false
					continue 
				end

				skipnext = readInstruction(codelist)
			end

			local sizek = readVarInt()
			local klist = table_create(sizek)

			for i = 1, sizek do
				local kt = readByte()
				local k

				if kt == 0 then --// Nil
					k = nil
				elseif kt == 1 then --// Bool
					k = readByte() ~= 0
				elseif kt == 2 then --// Number
					k = readDouble()
				elseif kt == 3 then --// String
					k = stringList[readVarInt()]
				elseif kt == 4 then --// Import
					k = readWord()
				elseif kt == 5 then --// Table
					local dataLength = readVarInt()
					k = table_create(dataLength)

					for i = 1, dataLength do
						k[i] = readVarInt()
					end
				elseif kt == 6 then --// Closure
					k = readVarInt()
				elseif kt == 7 then --// Vector
					local x,y,z,w = readFloat(), readFloat(), readFloat(), readFloat()

					if luau_settings.vectorSize == 4 then
						k = luau_settings.vectorCtor(x, y, z, w)
					else 
						k = luau_settings.vectorCtor(x, y, z)
					end
				end

				klist[i] = k
			end

			-- // 2nd pass to replace constant references in the instruction
			for i = 1, sizecode do
				checkkmode(codelist[i], klist)
			end

			local sizep = readVarInt()
			local protolist = table_create(sizep)

			for i = 1, sizep do
				protolist[i] = readVarInt() + 1
			end

			local linedefined = readVarInt()

			local debugnameindex = readVarInt()
			local debugname 

			if debugnameindex ~= 0 then
				debugname = stringList[debugnameindex]
			else 
				debugname = "(??)"
			end

			-- // lineinfo
			local lineinfoenabled = readByte() ~= 0
			local instructionlineinfo = nil 

			if lineinfoenabled then
				local linegaplog2 = readByte()

				local intervals = bit32_rshift((sizecode - 1), linegaplog2) + 1

				local lineinfo = table_create(sizecode)
				local abslineinfo = table_create(intervals)

				local lastoffset = 0
				for j = 1, sizecode do
					lastoffset += readByte()
					lineinfo[j] = lastoffset
				end

				local lastline = 0
				for j = 1, intervals do
					lastline += readWord()
					abslineinfo[j] = lastline % (2 ^ 32)
				end

				instructionlineinfo = table_create(sizecode)

				for i = 1, sizecode do 
					--// p->abslineinfo[pc >> p->linegaplog2] + p->lineinfo[pc];
					table_insert(instructionlineinfo, abslineinfo[bit32_rshift(i - 1, linegaplog2) + 1] + lineinfo[i])
				end
			end

			-- // debuginfo
			if readByte() ~= 0 then
				local sizel = readVarInt()
				for i = 1, sizel do
					readVarInt()
					readVarInt()
					readVarInt()
					readByte()
				end
				local sizeupvalues = readVarInt()
				for i = 1, sizeupvalues do
					readVarInt()
				end
			end

			return {
				maxstacksize = maxstacksize;
				numparams = numparams;
				nups = nups;
				isvararg = isvararg;
				linedefined = linedefined;
				debugname = debugname;

				sizecode = sizecode;
				code = codelist;

				sizek = sizek;
				k = klist;

				sizep = sizep;
				protos = protolist;

				lineinfoenabled = lineinfoenabled;
				instructionlineinfo = instructionlineinfo;

				bytecodeid = bytecodeid;
			}
		end

		-- userdataRemapping (not used in VM, left unused)
		if typesVersion == 3 then
			local index = readByte()

			while index ~= 0 do
				readVarInt()

				index = readByte()
			end
		end

		local protoCount = readVarInt()
		local protoList = table_create(protoCount)

		for i = 1, protoCount do
			protoList[i] = readProto(i - 1)
		end

		local mainProto = protoList[readVarInt() + 1]

		-- assert(cursor == buffer_len(stream), "deserializer cursor position mismatch")

		mainProto.debugname = "(main)"

		return {
			stringList = stringList;
			protoList = protoList;

			mainProto = mainProto;

			typesVersion = typesVersion;
		}
	end

	local function luau_load(module, env, luau_settings)
		if luau_settings == nil then
			luau_settings = luau_newsettings()
		else 
			luau_validatesettings(luau_settings)
		end

		if type(module) ~= "table" then
			module = luau_deserialize(module, luau_settings)
		end

		local protolist = module.protoList
		local mainProto = module.mainProto

		local breakHook = luau_settings.callHooks.breakHook
		local stepHook = luau_settings.callHooks.stepHook
		local interruptHook = luau_settings.callHooks.interruptHook
		local panicHook = luau_settings.callHooks.panicHook

		local alive = true 

		local function luau_close()
			alive = false
		end

		local function luau_wrapclosure(module, proto, upvals)
			local function luau_execute(...)
				local debugging, stack, protos, code, varargs

				if luau_settings.errorHandling then
					debugging, stack, protos, code, varargs = ... 
				else 
					--// Copied from error handling wrapper
					local passed = table_pack(...)
					stack = table_create(proto.maxstacksize)
					varargs = {
						len = 0,
						list = {},
					}

					table_move(passed, 1, proto.numparams, 0, stack)

					if proto.numparams < passed.n then
						local start = proto.numparams + 1
						local len = passed.n - proto.numparams
						varargs.len = len
						table_move(passed, start, start + len - 1, 1, varargs.list)
					end

					passed = nil

					debugging = {pc = 0, name = "NONE"}

					protos = proto.protos 
					code = proto.code
				end 

				local top, pc, open_upvalues, generalized_iterators = -1, 1, setmetatable({}, {__mode = "vs"}), setmetatable({}, {__mode = "ks"})
				local constants = proto.k
				local extensions = luau_settings.extensions

				while alive do
					local inst = code[pc]
					local op = inst.opcode

					debugging.pc = pc
					debugging.top = top
					debugging.name = inst.opname

					pc += 1

					if stepHook then
						stepHook(stack, debugging, proto, module, upvals)
					end

					if op == 0 then --[[ NOP ]]
						--// Do nothing
					elseif op == 1 then --[[ BREAK ]]
						if breakHook then
							breakHook(stack, debugging, proto, module, upvals)
						else
							warn("Breakpoint encountered without a break hook")
						end
					elseif op == 2 then --[[ LOADNIL ]]
						stack[inst.A] = nil
					elseif op == 3 then --[[ LOADB ]]
						stack[inst.A] = inst.B == 1
						pc += inst.C
					elseif op == 4 then --[[ LOADN ]]
						stack[inst.A] = inst.D
					elseif op == 5 then --[[ LOADK ]]
						stack[inst.A] = inst.K
					elseif op == 6 then --[[ MOVE ]]
						stack[inst.A] = stack[inst.B]
					elseif op == 7 then --[[ GETGLOBAL ]]
						local kv = inst.K

						stack[inst.A] = extensions[kv] or env[kv]

						pc += 1 --// adjust for aux
					elseif op == 8 then --[[ SETGLOBAL ]]
						local kv = inst.K
						env[kv] = stack[inst.A]

						pc += 1 --// adjust for aux
					elseif op == 9 then --[[ GETUPVAL ]]
						local uv = upvals[inst.B + 1]
						stack[inst.A] = uv.store[uv.index]
					elseif op == 10 then --[[ SETUPVAL ]]
						local uv = upvals[inst.B + 1]
						uv.store[uv.index] = stack[inst.A]
					elseif op == 11 then --[[ CLOSEUPVALS ]]
						for i, uv in open_upvalues do
							if uv.index >= inst.A then
								uv.value = uv.store[uv.index]
								uv.store = uv
								uv.index = "value" --// self reference
								open_upvalues[i] = nil
							end
						end
					elseif op == 12 then --[[ GETIMPORT ]]
						if luau_settings.useImportConstants then
							stack[inst.A] = inst.K
						else
							local count = inst.KC
							local k0 = inst.K0
							local import = extensions[k0] or env[k0]
							if count == 1 then
								stack[inst.A] = import
							elseif count == 2 then
								stack[inst.A] = import[inst.K1]
							elseif count == 3 then
								stack[inst.A] = import[inst.K1][inst.K2]
							end
						end

						pc += 1 --// adjust for aux 
					elseif op == 13 then --[[ GETTABLE ]]
						stack[inst.A] = stack[inst.B][stack[inst.C]]
					elseif op == 14 then --[[ SETTABLE ]]
						stack[inst.B][stack[inst.C]] = stack[inst.A]
					elseif op == 15 then --[[ GETTABLEKS ]]
						local index = inst.K
						stack[inst.A] = stack[inst.B][index]

						pc += 1 --// adjust for aux 
					elseif op == 16 then --[[ SETTABLEKS ]]
						local index = inst.K
						stack[inst.B][index] = stack[inst.A]

						pc += 1 --// adjust for aux
					elseif op == 17 then --[[ GETTABLEN ]]
						stack[inst.A] = stack[inst.B][inst.C + 1]
					elseif op == 18 then --[[ SETTABLEN ]]
						stack[inst.B][inst.C + 1] = stack[inst.A]
					elseif op == 19 then --[[ NEWCLOSURE ]]
						local newPrototype = protolist[protos[inst.D + 1]]

						local nups = newPrototype.nups
						local upvalues = table_create(nups)
						stack[inst.A] = luau_wrapclosure(module, newPrototype, upvalues)

						for i = 1, nups do
							local pseudo = code[pc]

							pc += 1

							local type = pseudo.A

							if type == 0 then --// value
								local upvalue = {
									value = stack[pseudo.B],
									index = "value",--// self reference
								}
								upvalue.store = upvalue

								upvalues[i] = upvalue
							elseif type == 1 then --// reference
								local index = pseudo.B
								local prev = open_upvalues[index]

								if prev == nil then
									prev = {
										index = index,
										store = stack,
									}
									open_upvalues[index] = prev
								end

								upvalues[i] = prev
							elseif type == 2 then --// upvalue
								upvalues[i] = upvals[pseudo.B + 1]
							end
						end
					elseif op == 20 then --[[ NAMECALL ]]
						local A = inst.A
						local B = inst.B

						local kv = inst.K

						local sb = stack[B]

						stack[A + 1] = sb

						pc += 1 --// adjust for aux 

						local useFallback = true

						--// Special handling for native namecall behaviour
						local useNativeHandler = luau_settings.useNativeNamecall

						if useNativeHandler then
							local nativeNamecall = luau_settings.namecallHandler

							local callInst = code[pc]
							local callOp = callInst.opcode

							--// Copied from the CALL handler under
							local callA, callB, callC = callInst.A, callInst.B, callInst.C

							if stepHook then
								stepHook(stack, debugging, proto, module, upvals)
							end

							if interruptHook then
								interruptHook(stack, debugging, proto, module, upvals)	
							end

							local params = if callB == 0 then top - callA else callB - 1
							local ret_list = table_pack(
								nativeNamecall(kv, table_unpack(stack, callA + 1, callA + params))
							)

							if ret_list[1] == true then
								useFallback = false

								pc += 1 --// Skip next CALL instruction

								inst = callInst
								op = callOp
								debugging.pc = pc
								debugging.name = inst.opname

								table_remove(ret_list, 1)

								local ret_num = ret_list.n - 1

								if callC == 0 then
									top = callA + ret_num - 1
								else
									ret_num = callC - 1
								end

								table_move(ret_list, 1, ret_num, callA, stack)
							end
						end

						if useFallback then
							stack[A] = sb[kv]
						end
					elseif op == 21 then --[[ CALL ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						local A, B, C = inst.A, inst.B, inst.C

						local params = if B == 0 then top - A else B - 1
						local func = stack[A]
						local ret_list = table_pack(
							func(table_unpack(stack, A + 1, A + params))
						)

						local ret_num = ret_list.n

						if C == 0 then
							top = A + ret_num - 1
						else
							ret_num = C - 1
						end

						table_move(ret_list, 1, ret_num, A, stack)
					elseif op == 22 then --[[ RETURN ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						local A = inst.A
						local B = inst.B 
						local b = B - 1
						local nresults

						if b == LUA_MULTRET then
							nresults = top - A + 1
						else
							nresults = B - 1
						end

						return table_unpack(stack, A, A + nresults - 1)
					elseif op == 23 then --[[ JUMP ]]
						pc += inst.D
					elseif op == 24 then --[[ JUMPBACK ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						pc += inst.D
					elseif op == 25 then --[[ JUMPIF ]]
						if stack[inst.A] then
							pc += inst.D
						end
					elseif op == 26 then --[[ JUMPIFNOT ]]
						if not stack[inst.A] then
							pc += inst.D
						end
					elseif op == 27 then --[[ JUMPIFEQ ]]
						if stack[inst.A] == stack[inst.aux] then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 28 then --[[ JUMPIFLE ]]
						if stack[inst.A] <= stack[inst.aux] then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 29 then --[[ JUMPIFLT ]]
						if stack[inst.A] < stack[inst.aux] then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 30 then --[[ JUMPIFNOTEQ ]]
						if stack[inst.A] == stack[inst.aux] then
							pc += 1
						else
							pc += inst.D
						end
					elseif op == 31 then --[[ JUMPIFNOTLE ]]
						if stack[inst.A] <= stack[inst.aux] then
							pc += 1
						else
							pc += inst.D
						end
					elseif op == 32 then --[[ JUMPIFNOTLT ]]
						if stack[inst.A] < stack[inst.aux] then
							pc += 1
						else
							pc += inst.D
						end
					elseif op == 33 then --[[ ADD ]]
						stack[inst.A] = stack[inst.B] + stack[inst.C]
					elseif op == 34 then --[[ SUB ]]
						stack[inst.A] = stack[inst.B] - stack[inst.C]
					elseif op == 35 then --[[ MUL ]]
						stack[inst.A] = stack[inst.B] * stack[inst.C]
					elseif op == 36 then --[[ DIV ]]
						stack[inst.A] = stack[inst.B] / stack[inst.C]
					elseif op == 37 then --[[ MOD ]]
						stack[inst.A] = stack[inst.B] % stack[inst.C]
					elseif op == 38 then --[[ POW ]]
						stack[inst.A] = stack[inst.B] ^ stack[inst.C]
					elseif op == 39 then --[[ ADDK ]]
						stack[inst.A] = stack[inst.B] + inst.K
					elseif op == 40 then --[[ SUBK ]]
						stack[inst.A] = stack[inst.B] - inst.K
					elseif op == 41 then --[[ MULK ]]
						stack[inst.A] = stack[inst.B] * inst.K
					elseif op == 42 then --[[ DIVK ]]
						stack[inst.A] = stack[inst.B] / inst.K
					elseif op == 43 then --[[ MODK ]]
						stack[inst.A] = stack[inst.B] % inst.K
					elseif op == 44 then --[[ POWK ]]
						stack[inst.A] = stack[inst.B] ^ inst.K
					elseif op == 45 then --[[ AND ]]
						local value = stack[inst.B]
						stack[inst.A] = if value then stack[inst.C] or false else value
					elseif op == 46 then --[[ OR ]]
						local value = stack[inst.B]
						stack[inst.A] = if value then value else stack[inst.C] or false
					elseif op == 47 then --[[ ANDK ]]
						local value = stack[inst.B]
						stack[inst.A] = if value then inst.K or false else value
					elseif op == 48 then --[[ ORK ]]
						local value = stack[inst.B]
						stack[inst.A] = if value then value else inst.K or false
					elseif op == 49 then --[[ CONCAT ]]
						local s = ""
						for i = inst.B, inst.C do
							s ..= stack[i]
						end
						stack[inst.A] = s
					elseif op == 50 then --[[ NOT ]]
						stack[inst.A] = not stack[inst.B]
					elseif op == 51 then --[[ MINUS ]]
						stack[inst.A] = -stack[inst.B]
					elseif op == 52 then --[[ LENGTH ]]
						stack[inst.A] = #stack[inst.B]
					elseif op == 53 then --[[ NEWTABLE ]]
						stack[inst.A] = table_create(inst.aux)

						pc += 1 --// adjust for aux 
					elseif op == 54 then --[[ DUPTABLE ]]
						local template = inst.K
						local serialized = {}
						for _, id in template do
							serialized[constants[id + 1]] = nil
						end
						stack[inst.A] = serialized
					elseif op == 55 then --[[ SETLIST ]]
						local A = inst.A
						local B = inst.B
						local c = inst.C - 1

						if c == LUA_MULTRET then
							c = top - B + 1
						end

						table_move(stack, B, B + c - 1, inst.aux, stack[A])

						pc += 1 --// adjust for aux 
					elseif op == 56 then --[[ FORNPREP ]]
						local A = inst.A

						local limit = stack[A]
						if not ttisnumber(limit) then
							local number = tonumber(limit)

							if number == nil then
								warn("invalid 'for' limit (number expected)")
							end

							stack[A] = number
							limit = number
						end

						local step = stack[A + 1]
						if not ttisnumber(step) then
							local number = tonumber(step)

							if number == nil then
								warn("invalid 'for' step (number expected)")
							end

							stack[A + 1] = number
							step = number
						end

						local index = stack[A + 2]
						if not ttisnumber(index) then
							local number = tonumber(index)

							if number == nil then
								warn("invalid 'for' index (number expected)")
							end

							stack[A + 2] = number
							index = number
						end

						if step > 0 then
							if not (index <= limit) then
								pc += inst.D
							end
						else
							if not (limit <= index) then
								pc += inst.D
							end
						end
					elseif op == 57 then --[[ FORNLOOP ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						local A = inst.A
						local limit = stack[A]
						local step = stack[A + 1]
						local index = stack[A + 2] + step

						stack[A + 2] = index

						if step > 0 then
							if index <= limit then
								pc += inst.D
							end
						else
							if limit <= index then
								pc += inst.D
							end
						end
					elseif op == 58 then --[[ FORGLOOP ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						local A = inst.A
						local res = inst.K

						top = A + 6

						local it = stack[A]

						if (luau_settings.generalizedIteration == false) or ttisfunction(it) then 
							local vals = { it(stack[A + 1], stack[A + 2]) }
							table_move(vals, 1, res, A + 3, stack)

							if stack[A + 3] ~= nil then
								stack[A + 2] = stack[A + 3]
								pc += inst.D
							else
								pc += 1
							end
						else
							local ok, vals = coroutine_resume(generalized_iterators[inst], it, stack[A + 1], stack[A + 2])
							if not ok then
								warn(vals)
							end
							if vals == LUA_GENERALIZED_TERMINATOR then 
								generalized_iterators[inst] = nil
								pc += 1
							else
								table_move(vals, 1, res, A + 3, stack)

								stack[A + 2] = stack[A + 3]
								pc += inst.D
							end
						end
					elseif op == 59 then --[[ FORGPREP_INEXT ]]
						if not ttisfunction(stack[inst.A]) then
							warn(string_format("attempt to iterate over a %s value", type(stack[inst.A]))) -- FORGPREP_INEXT encountered non-function value
						end

						pc += inst.D
					elseif op == 60 then --[[ FASTCALL3 ]]
						--[[ Skipped ]]
						pc += 1 --// adjust for aux
					elseif op == 61 then --[[ FORGPREP_NEXT ]]
						if not ttisfunction(stack[inst.A]) then
							warn(string_format("attempt to iterate over a %s value", type(stack[inst.A]))) -- FORGPREP_NEXT encountered non-function value
						end

						pc += inst.D
					elseif op == 63 then --[[ GETVARARGS ]]
						local A = inst.A
						local b = inst.B - 1

						if b == LUA_MULTRET then
							b = varargs.len
							top = A + b - 1
						end

						table_move(varargs.list, 1, b, A, stack)
					elseif op == 64 then --[[ DUPCLOSURE ]]
						local newPrototype = protolist[inst.K + 1] --// correct behavior would be to reuse the prototype if possible but it would not be useful here

						local nups = newPrototype.nups
						local upvalues = table_create(nups)
						stack[inst.A] = luau_wrapclosure(module, newPrototype, upvalues)

						for i = 1, nups do
							local pseudo = code[pc]
							pc += 1

							local type = pseudo.A
							if type == 0 then --// value
								local upvalue = {
									value = stack[pseudo.B],
									index = "value",--// self reference
								}
								upvalue.store = upvalue

								upvalues[i] = upvalue

								--// references dont get handled by DUPCLOSURE
							elseif type == 2 then --// upvalue
								upvalues[i] = upvals[pseudo.B + 1]
							end
						end
					elseif op == 65 then --[[ PREPVARARGS ]]
						--[[ Handled by wrapper ]]
					elseif op == 66 then --[[ LOADKX ]]
						local kv = inst.K
						stack[inst.A] = kv

						pc += 1 --// adjust for aux 
					elseif op == 67 then --[[ JUMPX ]]
						if interruptHook then
							interruptHook(stack, debugging, proto, module, upvals)	
						end

						pc += inst.E
					elseif op == 68 then --[[ FASTCALL ]]
						--[[ Skipped ]]
					elseif op == 69 then --[[ COVERAGE ]]
						inst.E += 1
					elseif op == 70 then --[[ CAPTURE ]]
						--[[ Handled by CLOSURE ]]
						warn("encountered unhandled CAPTURE")
					elseif op == 71 then --[[ SUBRK ]]
						stack[inst.A] = inst.K - stack[inst.C]
					elseif op == 72 then --[[ DIVRK ]]
						stack[inst.A] = inst.K / stack[inst.C]
					elseif op == 73 then --[[ FASTCALL1 ]]
						--[[ Skipped ]]
					elseif op == 74 then --[[ FASTCALL2 ]]
						--[[ Skipped ]]
						pc += 1 --// adjust for aux
					elseif op == 75 then --[[ FASTCALL2K ]]
						--[[ Skipped ]]
						pc += 1 --// adjust for aux
					elseif op == 76 then --[[ FORGPREP ]]
						local iterator = stack[inst.A]

						if luau_settings.generalizedIteration and not ttisfunction(iterator) then
							local loopInstruction = code[pc + inst.D]
							if generalized_iterators[loopInstruction] == nil then 
								local function gen_iterator(...)
									for r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31, r32, r33, r34, r35, r36, r37, r38, r39, r40, r41, r42, r43, r44, r45, r46, r47, r48, r49, r50, r51, r52, r53, r54, r55, r56, r57, r58, r59, r60, r61, r62, r63, r64, r65, r66, r67, r68, r69, r70, r71, r72, r73, r74, r75, r76, r77, r78, r79, r80, r81, r82, r83, r84, r85, r86, r87, r88, r89, r90, r91, r92, r93, r94, r95, r96, r97, r98, r99, r100, r101, r102, r103, r104, r105, r106, r107, r108, r109, r110, r111, r112, r113, r114, r115, r116, r117, r118, r119, r120, r121, r122, r123, r124, r125, r126, r127, r128, r129, r130, r131, r132, r133, r134, r135, r136, r137, r138, r139, r140, r141, r142, r143, r144, r145, r146, r147, r148, r149, r150, r151, r152, r153, r154, r155, r156, r157, r158, r159, r160, r161, r162, r163, r164, r165, r166, r167, r168, r169, r170, r171, r172, r173, r174, r175, r176, r177, r178, r179, r180, r181, r182, r183, r184, r185, r186, r187, r188, r189, r190, r191, r192, r193, r194, r195, r196, r197, r198, r199, r200 in ... do 
										coroutine_yield({r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31, r32, r33, r34, r35, r36, r37, r38, r39, r40, r41, r42, r43, r44, r45, r46, r47, r48, r49, r50, r51, r52, r53, r54, r55, r56, r57, r58, r59, r60, r61, r62, r63, r64, r65, r66, r67, r68, r69, r70, r71, r72, r73, r74, r75, r76, r77, r78, r79, r80, r81, r82, r83, r84, r85, r86, r87, r88, r89, r90, r91, r92, r93, r94, r95, r96, r97, r98, r99, r100, r101, r102, r103, r104, r105, r106, r107, r108, r109, r110, r111, r112, r113, r114, r115, r116, r117, r118, r119, r120, r121, r122, r123, r124, r125, r126, r127, r128, r129, r130, r131, r132, r133, r134, r135, r136, r137, r138, r139, r140, r141, r142, r143, r144, r145, r146, r147, r148, r149, r150, r151, r152, r153, r154, r155, r156, r157, r158, r159, r160, r161, r162, r163, r164, r165, r166, r167, r168, r169, r170, r171, r172, r173, r174, r175, r176, r177, r178, r179, r180, r181, r182, r183, r184, r185, r186, r187, r188, r189, r190, r191, r192, r193, r194, r195, r196, r197, r198, r199, r200})
									end

									coroutine_yield(LUA_GENERALIZED_TERMINATOR)
								end

								generalized_iterators[loopInstruction] = coroutine_create(gen_iterator)
							end
						end

						pc += inst.D
					elseif op == 77 then --[[ JUMPXEQKNIL ]]
						local kn = inst.KN

						if (stack[inst.A] == nil) ~= kn then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 78 then --[[ JUMPXEQKB ]]
						local kv = inst.K
						local kn = inst.KN
						local ra = stack[inst.A]

						if (ttisboolean(ra) and (ra == kv)) ~= kn then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 79 then --[[ JUMPXEQKN ]]
						local kv = inst.K
						local kn = inst.KN
						local ra = stack[inst.A]

						if (ra == kv) ~= kn then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 80 then --[[ JUMPXEQKS ]]
						local kv = inst.K
						local kn = inst.KN
						local ra = stack[inst.A]

						if (ra == kv) ~= kn then
							pc += inst.D
						else
							pc += 1
						end
					elseif op == 81 then --[[ IDIV ]]
						stack[inst.A] = stack[inst.B] // stack[inst.C]
					elseif op == 82 then --[[ IDIVK ]]
						stack[inst.A] = stack[inst.B] // inst.K
					else
						warn("Unsupported Opcode: " .. inst.opname .. " op: " .. op)
					end
				end

				for i, uv in open_upvalues do
					uv.value = uv.store[uv.index]
					uv.store = uv
					uv.index = "value" --// self reference
					open_upvalues[i] = nil
				end

				for i, iter in generalized_iterators do 
					coroutine_close(iter)
					generalized_iterators[i] = nil
				end
			end

			local function wrapped(...)
				local passed = table_pack(...)
				local stack = table_create(proto.maxstacksize)
				local varargs = {
					len = 0,
					list = {},
				}

				table_move(passed, 1, proto.numparams, 0, stack)

				if proto.numparams < passed.n then
					local start = proto.numparams + 1
					local len = passed.n - proto.numparams
					varargs.len = len
					table_move(passed, start, start + len - 1, 1, varargs.list)
				end

				passed = nil

				local debugging = {pc = 0, name = "NONE"}
				local result
				if luau_settings.errorHandling then 
					result = table_pack(pcall(luau_execute, debugging, stack, proto.protos, proto.code, varargs))
				else
					result = table_pack(true, luau_execute(debugging, stack, proto.protos, proto.code, varargs))
				end

				if result[1] then
					return table_unpack(result, 2, result.n)
				else
					local message = result[2]

					if panicHook then
						panicHook(message, stack, debugging, proto, module, upvals)
					end

					if ttisstring(message) == false then
						if luau_settings.allowProxyErrors then
							warn(message)
						else 
							message = type(message)
						end
					end

					if proto.lineinfoenabled then
					else 
						return warn(string_format("intellect>lvm error [name>%s>opcode %s]>%s", proto.debugname, debugging.pc, debugging.name, message), 0)
					end
				end
			end

			if luau_settings.errorHandling then 
				return wrapped
			else 
				return luau_execute
			end 
		end

		return luau_wrapclosure(module, mainProto),  luau_close
	end

	return function(bytecode, env)
		local executable = luau_load(bytecode, env)
		return setfenv(executable, env)
	end
end)()

local function convertToBytes(str)
    local cleaned_str = str:gsub('^|', ''):gsub('|$', '')
    local byte_strings = {}
    for byte in cleaned_str:gmatch('[^|]+') do
        table.insert(byte_strings, byte)
    end
    local byte_array = {}
    for _, byte_str in ipairs(byte_strings) do
        local byte = tonumber(byte_str)
        if byte then
            table.insert(byte_array, byte)
        end
    end
    return byte_array
end

local function NewEnvironment()
	local env = getfenv(2)
	-- local oldGetService = env.game.GetService
	-- env.game.GetService = function(service: string)
	-- 	return oldGetService(service)
	-- end
	return env
end

local function LoadUNC(env: { [string]: any }): ()
end 

local function Thread()
    local function execute(bytecode)
		local env = NewEnvironment()
		LoadUNC(env)
		local toret = RunBytecode(bytecode, env)
		local cl = toret
		if type(toret) ~= "function" then
			toret = function(...)
				warn(cl,2)
			end
		end
		return function()
			local success, errorMessage = pcall(toret)
			if not success then
				-- would be mad sick to make this red, but it doesn't really matter
				print(errorMessage)
			end
		end
	end

    while true do
        task.wait()
		
		local response = request({
			Method = "GET",
			Url = "http://localhost:443/get-request",
		})

		if not response.Success then
			continue
		end
		
		local data = HttpService:JSONDecode(response.Body)

		if data.Event == "None" then
			continue
		end
	
		-- Handle Events --
		if data.Event == "ExecuteBytecode" then
			local byteArray = convertToBytes(data.Bytecode)
			local buff = buffer.create(#byteArray+1)
			for i, byte in ipairs(byteArray) do
				buffer.writeu8(buff, i-1, byte)
			end
			if buffer.readu8(buff, 1) == 0 then
				table.remove(byteArray, 1)
				print("Catched Error:", string.char(table.unpack(byteArray)))
				continue
			end
			execute(buff)()
		end
		
		-- Send Fulfilled Confirmation --
		request({
			Method = "POST",
			Url = "http://localhost:443/request-fulfilled",
			Body = ""
		})
    end
end

task.spawn(Thread)

if script.Name == "PolicyService" then
    local PlayersService = game:GetService('Players')
    local isSubjectToChinaPolicies = true
    local policyTable
    local initialized = false
    local initAsyncCalledOnce = false
    local initializedEvent = Instance.new("BindableEvent")
    local PolicyService = {}

    function PolicyService:InitAsync()
        if _G.__TESTEZ_RUNNING_TEST__ then
            isSubjectToChinaPolicies = false
            return
        end

        if initialized then return end
        if initAsyncCalledOnce then
            initializedEvent.Event:Wait()
            return
        end
        initAsyncCalledOnce = true

        local localPlayer = PlayersService.LocalPlayer
        while not localPlayer do
            PlayersService.PlayerAdded:Wait()
            localPlayer = PlayersService.LocalPlayer
        end
        assert(localPlayer, "")

        pcall(function() policyTable = game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(localPlayer) end)
        if policyTable then
            isSubjectToChinaPolicies = policyTable["IsSubjectToChinaPolicies"]
        end

        initialized = true
        initializedEvent:Fire()
    end

    function PolicyService:IsSubjectToChinaPolicies()
        self:InitAsync()

        return isSubjectToChinaPolicies
    end

    return PolicyService
elseif script.Name == "JestGlobals" then
    local input_manager = Instance.new("VirtualInputManager")

    input_manager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
    input_manager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
    input_manager:Destroy()

    return {HideTemp = function() end}
end