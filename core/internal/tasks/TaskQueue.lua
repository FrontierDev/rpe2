local _, Addon = ...

Addon.Internal = Addon.Internal or {}

local Tasks = Addon.Internal.Tasks or {}
Addon.Internal.Tasks = Tasks

local Debug = Addon.Debug or {}

Tasks.DefaultBudget = Tasks.DefaultBudget or 2
Tasks.DefaultMaxMilliseconds = Tasks.DefaultMaxMilliseconds or 2
Tasks.DefaultFlushInterval = Tasks.DefaultFlushInterval or 0.05
Tasks.MaxPerFrame = Tasks.MaxPerFrame or Tasks.DefaultBudget
Tasks.MaxMilliseconds = Tasks.MaxMilliseconds or Tasks.DefaultMaxMilliseconds
Tasks.FlushInterval = Tasks.FlushInterval or Tasks.DefaultFlushInterval
Tasks.FlushElapsed = Tasks.FlushElapsed or 0
Tasks.Queue = Tasks.Queue or {}
Tasks.DeferredQueue = Tasks.DeferredQueue or {}
Tasks.Head = Tasks.Head or 1
Tasks.Tail = Tasks.Tail or #Tasks.Queue
Tasks.Paused = Tasks.Paused == nil and false or Tasks.Paused
Tasks.IsFlushing = Tasks.IsFlushing or false
Tasks.TotalExecuted = Tasks.TotalExecuted or 0

local function captureArgs(...)
    local count = select("#", ...)
    local args = {}

    for index = 1, count do
        args[index] = select(index, ...)
    end

    return args, count
end

local normalizeQueuePointers

local function appendDeferredQueue()
    if #Tasks.DeferredQueue == 0 then
        return
    end

    normalizeQueuePointers()

    for index = 1, #Tasks.DeferredQueue do
        Tasks.Tail = Tasks.Tail + 1
        Tasks.Queue[Tasks.Tail] = Tasks.DeferredQueue[index]
    end

    Tasks.DeferredQueue = {}
end

local function activeQueueLength()
    local head = math.max(1, math.floor(tonumber(Tasks.Head) or 1))
    local tail = math.max(head - 1, math.floor(tonumber(Tasks.Tail) or #Tasks.Queue or 0))
    return math.max(0, tail - head + 1)
end

local function resetQueue()
    Tasks.Queue = {}
    Tasks.Head = 1
    Tasks.Tail = 0
end

normalizeQueuePointers = function()
    Tasks.Head = math.max(1, math.floor(tonumber(Tasks.Head) or 1))
    Tasks.Tail = math.max(Tasks.Head - 1, math.floor(tonumber(Tasks.Tail) or #Tasks.Queue or 0))
    if Tasks.Head > Tasks.Tail then
        resetQueue()
    end
end

local function compactQueue()
    if activeQueueLength() <= 0 then
        resetQueue()
    end
end

local function getNowMilliseconds()
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end
    return nil
end

local function runJob(job)
    local ok, err = xpcall(function()
        job.fn(unpack(job.args, 1, job.argCount))
    end, function(message)
        if debugstack then
            return ("%s\n%s"):format(tostring(message), debugstack(2))
        end

        return tostring(message)
    end)

    if not ok and Debug.Error then
        Debug.Error("Task queue job failed: %s", err)
    end
end

function Tasks:Initialize(config)
    if type(config) == "table" and type(config.maxPerFrame) == "number" then
        self.MaxPerFrame = math.max(1, math.floor(config.maxPerFrame))
    elseif type(self.MaxPerFrame) ~= "number" or self.MaxPerFrame < 1 then
        self.MaxPerFrame = self.DefaultBudget
    end
    if type(config) == "table" and type(config.maxMilliseconds) == "number" then
        self.MaxMilliseconds = math.max(1, config.maxMilliseconds)
    elseif type(self.MaxMilliseconds) ~= "number" or self.MaxMilliseconds < 1 then
        self.MaxMilliseconds = self.DefaultMaxMilliseconds
    end
    if type(config) == "table" and type(config.flushInterval) == "number" then
        self.FlushInterval = math.max(0, config.flushInterval)
    elseif type(self.FlushInterval) ~= "number" or self.FlushInterval < 0 then
        self.FlushInterval = self.DefaultFlushInterval
    end
    normalizeQueuePointers()

    if self.Frame or not CreateFrame then
        return self
    end

    self.Frame = CreateFrame("Frame")
    self.Frame:SetScript("OnUpdate", function(_, elapsed)
        if self.Paused then
            return
        end

        if activeQueueLength() == 0 and #self.DeferredQueue == 0 then
            self.FlushElapsed = 0
            return
        end

        self.FlushElapsed = (tonumber(self.FlushElapsed) or 0) + (tonumber(elapsed) or 0)
        local flushInterval = tonumber(self.FlushInterval) or tonumber(self.DefaultFlushInterval) or 0
        if flushInterval > 0 and self.FlushElapsed < flushInterval then
            return
        end
        self.FlushElapsed = 0
        self:Flush()
    end)

    return self
end

function Tasks:Enqueue(fn, ...)
    if type(fn) ~= "function" then
        error("Addon.Internal.Tasks:Enqueue(fn, ...) requires a function.", 2)
    end

    local args, argCount = captureArgs(...)
    local job = {
        fn = fn,
        args = args,
        argCount = argCount,
    }

    if self.IsFlushing then
        self.DeferredQueue[#self.DeferredQueue + 1] = job
    else
        normalizeQueuePointers()
        self.Tail = self.Tail + 1
        self.Queue[self.Tail] = job
    end

    return job
end

function Tasks:SetBudget(maxPerFrame)
    if type(maxPerFrame) ~= "number" then
        error("Addon.Internal.Tasks:SetBudget(maxPerFrame) requires a numeric budget.", 2)
    end

    self.MaxPerFrame = math.max(1, math.floor(maxPerFrame))
    return self.MaxPerFrame
end

function Tasks:SetTimeBudget(maxMilliseconds)
    if type(maxMilliseconds) ~= "number" then
        error("Addon.Internal.Tasks:SetTimeBudget(maxMilliseconds) requires a numeric budget.", 2)
    end

    self.MaxMilliseconds = math.max(1, maxMilliseconds)
    return self.MaxMilliseconds
end

function Tasks:SetFlushInterval(seconds)
    if type(seconds) ~= "number" then
        error("Addon.Internal.Tasks:SetFlushInterval(seconds) requires a numeric interval.", 2)
    end

    self.FlushInterval = math.max(0, seconds)
    self.FlushElapsed = 0
    return self.FlushInterval
end

function Tasks:Flush(maxTasks)
    local budget = self.MaxPerFrame or self.DefaultBudget

    if type(maxTasks) == "number" then
        budget = math.max(0, math.floor(maxTasks))
    end

    if budget <= 0 then
        return 0
    end

    if self.IsFlushing then
        return 0
    end

    appendDeferredQueue()
    normalizeQueuePointers()

    local executed = 0
    self.IsFlushing = true
    local startedAt = getNowMilliseconds()
    local maxMilliseconds = tonumber(self.MaxMilliseconds) or tonumber(self.DefaultMaxMilliseconds) or 0

    while executed < budget and self.Head <= self.Tail do
        local job = self.Queue[self.Head]
        self.Queue[self.Head] = nil
        self.Head = self.Head + 1
        if job then
            runJob(job)
            self.TotalExecuted = self.TotalExecuted + 1
            executed = executed + 1
        end

        if startedAt and maxMilliseconds > 0 and executed > 0 and (getNowMilliseconds() - startedAt) >= maxMilliseconds then
            break
        end
    end

    self.IsFlushing = false
    compactQueue()

    appendDeferredQueue()

    return executed
end

function Tasks:Pause()
    self.Paused = true
    return self
end

function Tasks:Resume()
    self.Paused = false
    return self
end

function Tasks:GetStats()
    return {
        queueLength = activeQueueLength() + #self.DeferredQueue,
        budget = self.MaxPerFrame or self.DefaultBudget,
        timeBudget = self.MaxMilliseconds or self.DefaultMaxMilliseconds,
        flushInterval = self.FlushInterval or self.DefaultFlushInterval,
        paused = self.Paused and true or false,
        totalExecuted = self.TotalExecuted or 0,
    }
end
