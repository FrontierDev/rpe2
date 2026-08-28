local _, Addon = ...

Addon.Internal = Addon.Internal or {}

local Tasks = Addon.Internal.Tasks or {}
Addon.Internal.Tasks = Tasks

local Debug = Addon.Debug or {}
local unpackValues = unpack or table.unpack

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function getNowMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end

    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end

    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end

    return nil
end

local function formatError(message)
    if debugstack then
        return ("%s\n%s"):format(tostring(message), debugstack(2))
    end

    return tostring(message)
end

local function logError(message, ...)
    if Debug.Error then
        Debug.Error(message, ...)
    end
end

Tasks.DefaultBudget = Tasks.DefaultBudget or 2
Tasks.DefaultMaxMilliseconds = Tasks.DefaultMaxMilliseconds or 2
Tasks.DefaultSliceMilliseconds = Tasks.DefaultSliceMilliseconds or 2
Tasks.DefaultFlushInterval = Tasks.DefaultFlushInterval or 0.05
Tasks.MaxPerFrame = Tasks.MaxPerFrame or Tasks.DefaultBudget
Tasks.MaxMilliseconds = Tasks.MaxMilliseconds or Tasks.DefaultMaxMilliseconds
Tasks.SliceMilliseconds = Tasks.SliceMilliseconds or Tasks.DefaultSliceMilliseconds
Tasks.FlushInterval = Tasks.FlushInterval or Tasks.DefaultFlushInterval
Tasks.FlushElapsed = Tasks.FlushElapsed or 0
Tasks.Queue = Tasks.Queue or {}
Tasks.DeferredQueue = Tasks.DeferredQueue or {}
Tasks.Head = Tasks.Head or 1
Tasks.Tail = Tasks.Tail or #Tasks.Queue
Tasks.Paused = Tasks.Paused == nil and false or Tasks.Paused
Tasks.IsFlushing = Tasks.IsFlushing or false
Tasks.TotalExecuted = Tasks.TotalExecuted or 0
Tasks.TotalFlushes = Tasks.TotalFlushes or 0
Tasks.TotalSlicesExecuted = Tasks.TotalSlicesExecuted or 0
Tasks.TotalCancelled = Tasks.TotalCancelled or 0
Tasks.TotalStaleCancelled = Tasks.TotalStaleCancelled or 0
Tasks.NextJobId = math.max(0, math.floor(tonumber(Tasks.NextJobId) or 0))
Tasks.JobsById = Tasks.JobsById or {}
Tasks.LastFlushElapsedMs = tonumber(Tasks.LastFlushElapsedMs) or 0
Tasks.MaxFlushElapsedMs = tonumber(Tasks.MaxFlushElapsedMs) or 0
Tasks.JobsExecutedLastFlush = tonumber(Tasks.JobsExecutedLastFlush) or 0
Tasks.NormalJobsExecutedLastFlush = tonumber(Tasks.NormalJobsExecutedLastFlush) or 0
Tasks.SlicesExecutedLastFlush = tonumber(Tasks.SlicesExecutedLastFlush) or 0
Tasks.LastFlushQueuedJobs = tonumber(Tasks.LastFlushQueuedJobs) or 0
Tasks.LastSliceElapsedMs = tonumber(Tasks.LastSliceElapsedMs) or 0
Tasks.MaxSliceElapsedMs = tonumber(Tasks.MaxSliceElapsedMs) or 0
Tasks.LastSliceLabel = Tasks.LastSliceLabel or nil
Tasks.CurrentSliceLabel = Tasks.CurrentSliceLabel or nil
Tasks.CurrentSliceDeadlineMs = Tasks.CurrentSliceDeadlineMs or nil
Tasks.LastCancelledLabel = Tasks.LastCancelledLabel or nil
Tasks.LastCancelReason = Tasks.LastCancelReason or nil

local function captureArgs(...)
    local count = select("#", ...)
    local args = {}

    for index = 1, count do
        args[index] = select(index, ...)
    end

    return args, count
end

local normalizeQueuePointers

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

local function compactQueue()
    if activeQueueLength() <= 0 then
        resetQueue()
    end
end

local function isSliceableJob(job)
    return type(job) == "table" and job.kind == "sliceable"
end

local function countQueuedJobs()
    local normal, sliceable = 0, 0
    local function count(job)
        if type(job) ~= "table" or job.cancelled == true then
            return
        end
        if isSliceableJob(job) then
            sliceable = sliceable + 1
        else
            normal = normal + 1
        end
    end

    for index = Tasks.Head, Tasks.Tail do
        count(Tasks.Queue[index])
    end
    for index = 1, #Tasks.DeferredQueue do
        count(Tasks.DeferredQueue[index])
    end

    return normal, sliceable
end

local function releaseSliceableJob(job, outcome, reason)
    if not isSliceableJob(job) or job.finalized == true then
        return
    end

    job.finalized = true
    Tasks.JobsById[job.id] = nil
    local state = job.state
    if (outcome == "cancelled" or outcome == "failed") and type(job.onCancel) == "function" then
        local ok, err = xpcall(function()
            job.onCancel(state, reason, job)
        end, formatError)
        if not ok then
            logError("Task queue sliceable terminal handler failed for '%s': %s", tostring(job.label or job.id), err)
        end
    elseif outcome == "completed" and type(job.onComplete) == "function" then
        local ok, err = xpcall(function()
            job.onComplete(state, job)
        end, formatError)
        if not ok then
            logError("Task queue sliceable completion handler failed for '%s': %s", tostring(job.label or job.id), err)
        end
    end
    job.state = nil
end

local function cancelSliceableJob(job, reason, stale)
    if not isSliceableJob(job) or job.cancelled == true or job.completed == true then
        return false
    end

    job.cancelled = true
    job.cancelReason = tostring(reason or "cancelled")
    Tasks.TotalCancelled = (tonumber(Tasks.TotalCancelled) or 0) + 1
    if stale == true then
        Tasks.TotalStaleCancelled = (tonumber(Tasks.TotalStaleCancelled) or 0) + 1
    end
    Tasks.LastCancelledLabel = tostring(job.label or job.id or "sliceable")
    Tasks.LastCancelReason = job.cancelReason
    releaseSliceableJob(job, "cancelled", job.cancelReason)
    return true
end

local function runNormalJob(job)
    local ok, err = xpcall(function()
        job.fn(unpackValues(job.args, 1, job.argCount))
    end, formatError)

    if not ok then
        logError("Task queue job failed: %s", err)
    end
end

local function runSliceableJob(self, job, flushDeadlineMs)
    if job.cancelled == true then
        return "cancelled", 0
    end

    if type(job.isStale) == "function" then
        local staleOk, staleOrError = xpcall(function()
            return job.isStale(job.state, job)
        end, formatError)
        if not staleOk then
            logError("Task queue sliceable stale check failed for '%s': %s", tostring(job.label or job.id), staleOrError)
            cancelSliceableJob(job, "stale-check-error", true)
            return "cancelled", 0
        end
        if staleOrError == true then
            cancelSliceableJob(job, "stale", true)
            return "cancelled", 0
        end
    end

    local sliceStartedAt = getNowMilliseconds()
    local sliceDeadlineMs = nil
    if sliceStartedAt then
        local sliceBudget = math.max(0, tonumber(self.SliceMilliseconds) or tonumber(self.DefaultSliceMilliseconds) or 0)
        sliceDeadlineMs = sliceStartedAt + sliceBudget
        if flushDeadlineMs and sliceDeadlineMs > flushDeadlineMs then
            sliceDeadlineMs = flushDeadlineMs
        end
    end

    self.CurrentSliceLabel = tostring(job.label or job.id or "sliceable")
    self.CurrentSliceDeadlineMs = sliceDeadlineMs
    local timings = getTimings()
    local sliceTimer = nil
    if timings and type(timings.Start) == "function"
        and (type(timings.IsEnabled) ~= "function" or timings:IsEnabled())
    then
        sliceTimer = timings:Start("TaskQueue.Slice", {
            context = self.CurrentSliceLabel,
            thresholdMs = self.SliceMilliseconds,
        })
    end

    local results = { xpcall(function()
        return job.step(job.state, sliceDeadlineMs, job)
    end, formatError) }
    local ok = results[1]
    local completed = results[2] == true
    local outcome = results[3]
    local elapsedMs = sliceStartedAt and math.max(0, getNowMilliseconds() - sliceStartedAt) or 0
    self.LastSliceElapsedMs = elapsedMs
    self.MaxSliceElapsedMs = math.max(tonumber(self.MaxSliceElapsedMs) or 0, elapsedMs)
    self.LastSliceLabel = self.CurrentSliceLabel
    self.CurrentSliceLabel = nil
    self.CurrentSliceDeadlineMs = nil

    if sliceTimer and timings and type(timings.Stop) == "function" then
        timings:Stop(sliceTimer, {
            cardinality = {
                jobId = job.id,
                completed = completed and 1 or 0,
                scope = job.scope or "",
            },
        })
    end

    -- Sliceable continuations may distinguish a terminal stale/error result
    -- from ordinary incomplete work.  Preserve that result here instead of
    -- putting stale state back into the deferred queue as if it were pending.
    if ok and outcome == "stale" then
        cancelSliceableJob(job, "stale", true)
        return "cancelled", elapsedMs
    end
    if ok and outcome == "error" then
        logError("Task queue sliceable job '%s' returned an error outcome.", tostring(job.label or job.id))
        job.failed = true
        releaseSliceableJob(job, "failed", "error")
        return "failed", elapsedMs
    end

    if not ok then
        logError("Task queue sliceable job '%s' failed: %s", tostring(job.label or job.id), results[2])
        job.failed = true
        releaseSliceableJob(job, "failed", "error")
        return "failed", elapsedMs
    end

    self.TotalSlicesExecuted = (tonumber(self.TotalSlicesExecuted) or 0) + 1
    if completed then
        job.completed = true
        releaseSliceableJob(job, "completed")
        return "completed", elapsedMs
    end

    return "incomplete", elapsedMs
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
    if type(config) == "table" and type(config.sliceMilliseconds) == "number" then
        self.SliceMilliseconds = math.max(0.1, config.sliceMilliseconds)
    elseif type(self.SliceMilliseconds) ~= "number" or self.SliceMilliseconds <= 0 then
        self.SliceMilliseconds = self.DefaultSliceMilliseconds
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
        kind = "normal",
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

function Tasks:EnqueueSliceable(options)
    if type(options) ~= "table" then
        error("Addon.Internal.Tasks:EnqueueSliceable(options) requires an options table.", 2)
    end
    if type(options.step) ~= "function" then
        error("Addon.Internal.Tasks:EnqueueSliceable(options) requires options.step(state, deadlineMs).", 2)
    end

    self.NextJobId = math.max(0, math.floor(tonumber(self.NextJobId) or 0)) + 1
    local job = {
        kind = "sliceable",
        id = self.NextJobId,
        label = tostring(options.label or ("sliceable-%d"):format(self.NextJobId)),
        state = options.state,
        step = options.step,
        scope = options.scope ~= nil and tostring(options.scope) or nil,
        isStale = options.isStale or options.staleCheck,
        onCancel = options.onCancel,
        onComplete = options.onComplete,
    }
    self.JobsById[job.id] = job

    if self.IsFlushing then
        self.DeferredQueue[#self.DeferredQueue + 1] = job
    else
        normalizeQueuePointers()
        self.Tail = self.Tail + 1
        self.Queue[self.Tail] = job
    end

    return job
end

function Tasks:ShouldYield(deadlineMs)
    local deadline = tonumber(deadlineMs)
    if deadline == nil then
        return false
    end

    local now = getNowMilliseconds()
    return now ~= nil and now >= deadline
end

function Tasks:Cancel(jobOrId, reason)
    local job = type(jobOrId) == "table" and jobOrId or self.JobsById[tonumber(jobOrId)]
    return cancelSliceableJob(job, reason or "cancelled", false)
end

function Tasks:CancelScope(scope, reason)
    local normalizedScope = tostring(scope or "")
    if normalizedScope == "" then
        return 0
    end

    local jobs = {}
    for _, job in pairs(self.JobsById) do
        if type(job) == "table" and tostring(job.scope or "") == normalizedScope then
            jobs[#jobs + 1] = job
        end
    end

    local cancelled = 0
    for index = 1, #jobs do
        if cancelSliceableJob(jobs[index], reason or ("scope:" .. normalizedScope), false) then
            cancelled = cancelled + 1
        end
    end
    return cancelled
end
Tasks.CancelByScope = Tasks.CancelScope

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

function Tasks:SetSliceBudget(maxMilliseconds)
    if type(maxMilliseconds) ~= "number" then
        error("Addon.Internal.Tasks:SetSliceBudget(maxMilliseconds) requires a numeric budget.", 2)
    end

    self.SliceMilliseconds = math.max(0.1, maxMilliseconds)
    return self.SliceMilliseconds
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

    if budget <= 0 or self.IsFlushing then
        return 0
    end

    appendDeferredQueue()
    normalizeQueuePointers()

    local normalQueued, sliceableQueued = countQueuedJobs()
    local queuedJobs = normalQueued + sliceableQueued
    local executed, normalExecuted, slicesExecuted, processed = 0, 0, 0, 0
    self.IsFlushing = true
    local timings = getTimings()
    local flushTimer = nil
    if timings and type(timings.Start) == "function"
        and (type(timings.IsEnabled) ~= "function" or timings:IsEnabled())
    then
        flushTimer = timings:Start("TaskQueue.Flush", {
            thresholdMs = 2,
        })
    end
    local startedAt = getNowMilliseconds()
    local maxMilliseconds = tonumber(self.MaxMilliseconds) or tonumber(self.DefaultMaxMilliseconds) or 0
    local flushDeadlineMs = startedAt and maxMilliseconds > 0 and (startedAt + maxMilliseconds) or nil

    while processed < budget and self.Head <= self.Tail do
        if flushDeadlineMs and processed > 0 and self:ShouldYield(flushDeadlineMs) then
            break
        end

        local job = self.Queue[self.Head]
        self.Queue[self.Head] = nil
        self.Head = self.Head + 1
        if type(job) == "table" then
            processed = processed + 1
            if isSliceableJob(job) then
                local status = runSliceableJob(self, job, flushDeadlineMs)
                if status == "incomplete" then
                    self.DeferredQueue[#self.DeferredQueue + 1] = job
                end
                if status ~= "cancelled" then
                    self.TotalExecuted = self.TotalExecuted + 1
                    executed = executed + 1
                    slicesExecuted = slicesExecuted + 1
                end
            else
                runNormalJob(job)
                self.TotalExecuted = self.TotalExecuted + 1
                executed = executed + 1
                normalExecuted = normalExecuted + 1
            end
        end
    end

    self.IsFlushing = false
    compactQueue()
    appendDeferredQueue()

    local elapsedMs = startedAt and math.max(0, getNowMilliseconds() - startedAt) or 0
    self.LastFlushElapsedMs = elapsedMs
    self.MaxFlushElapsedMs = math.max(tonumber(self.MaxFlushElapsedMs) or 0, elapsedMs)
    self.TotalFlushes = (tonumber(self.TotalFlushes) or 0) + 1
    self.JobsExecutedLastFlush = executed
    self.NormalJobsExecutedLastFlush = normalExecuted
    self.SlicesExecutedLastFlush = slicesExecuted
    self.LastFlushQueuedJobs = queuedJobs

    if flushTimer and timings and type(timings.Stop) == "function" then
        timings:Stop(flushTimer, {
            cardinality = {
                queuedTasks = queuedJobs,
                normalTasks = normalQueued,
                sliceableTasks = sliceableQueued,
                normalExecuted = normalExecuted,
                slicesExecuted = slicesExecuted,
                deferredTasks = #self.DeferredQueue,
            },
        })
    end

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
    local normalQueued, sliceableQueued = countQueuedJobs()
    return {
        queueLength = normalQueued + sliceableQueued,
        budget = self.MaxPerFrame or self.DefaultBudget,
        timeBudget = self.MaxMilliseconds or self.DefaultMaxMilliseconds,
        sliceBudget = self.SliceMilliseconds or self.DefaultSliceMilliseconds,
        flushInterval = self.FlushInterval or self.DefaultFlushInterval,
        paused = self.Paused and true or false,
        totalExecuted = self.TotalExecuted or 0,
        totalFlushes = self.TotalFlushes or 0,
        totalSlicesExecuted = self.TotalSlicesExecuted or 0,
        totalCancelled = self.TotalCancelled or 0,
        totalStaleCancelled = self.TotalStaleCancelled or 0,
        jobsExecutedLastFlush = self.JobsExecutedLastFlush or 0,
        normalJobsExecutedLastFlush = self.NormalJobsExecutedLastFlush or 0,
        slicesExecutedLastFlush = self.SlicesExecutedLastFlush or 0,
        lastFlushQueuedJobs = self.LastFlushQueuedJobs or 0,
        lastFlushElapsedMs = self.LastFlushElapsedMs or 0,
        maxFlushElapsedMs = self.MaxFlushElapsedMs or 0,
        lastSliceElapsedMs = self.LastSliceElapsedMs or 0,
        maxSliceElapsedMs = self.MaxSliceElapsedMs or 0,
        lastSliceLabel = self.LastSliceLabel,
        currentSliceLabel = self.CurrentSliceLabel,
        lastCancelledLabel = self.LastCancelledLabel,
        lastCancelReason = self.LastCancelReason,
        normalQueuedJobs = normalQueued,
        sliceableQueuedJobs = sliceableQueued,
    }
end
