json = nil

tasks = {}
renderTasks = {}

COLUMN_X = {
    [1] = 20,
    [2] = 260,
    [3] = 500
}

-- Constants for layout
COLUMN_Y_START = 65
CARD_HEIGHT = 72
CARD_GAP = 10
MAX_CARDS = 30

-- State for picking up and dropping tasks
selectedTask = {
    active = false,
    taskId = nil,
    slotIndex = nil,
    sourceColumn = nil
}

-- Temporary storage for new task being added
newTask = {
    id = nil,
    summary = nil,
    project = nil,
    details = nil,
    column = nil
}


function Initialize()
    json = dofile(SKIN:GetVariable('@') .. 'json.lua')

    tasks.todo = loadTasks('todo.json', 1)
    tasks.inprogress = loadTasks('inprogress.json', 2)
    tasks.done = loadTasks('done.json', 3)

    refreshBoard()
end

function Update()
end

function loadTasks(filename, column)
    -- Open json file
    local path = SKIN:GetVariable("CURRENTPATH").."data\\"..filename
    local file = io.open(path, "r")
    if not file then return {} end

    -- Read json file contents
    local content = file:read("*all")
    file:close()

    -- Decode json content
    local decoded = json.decode(content or "[]")

    -- Initiate result table
    local result = {}

    -- Populate result table with decoded tasks
    for _, task in ipairs(decoded) do
        local id = task["id"] or ""
        local summary = task["summary"] or ""
        local project = task["project"] or ""
        local details = task["details"] or ""

        table.insert(result, {
            id = id;
            summary = summary,
            project = project,
            details = details,
            column = column
        })
    end

    return result
end

function refreshBoard()
    renderTasks = rebuildRenderTasks(tasks)
    updateMeters(renderTasks)
end

function rebuildRenderTasks(renderTasks)
    function appendColumnTasks(result, taskList, column)
        for i, task in ipairs(taskList) do
            table.insert(result, {
                id = task.id;
                summary = task.summary,
                project = task.project,
                details = task.details,
                column = column,
                x = COLUMN_X[column],
                y = COLUMN_Y_START + (i - 1) * (CARD_HEIGHT + CARD_GAP)
            })
        end
    end

    local result = {}

    -- Append tasks from each column to renderTasks with appropriate x and y coordinates
    appendColumnTasks(result, tasks.todo, 1)
    appendColumnTasks(result, tasks.inprogress, 2)
    appendColumnTasks(result, tasks.done, 3)

    return result
end

function updateMeters(renderTasks)
    function showTaskInSlot(i, task)
        local bgMeter = "TaskBg" .. i
        local summaryMeter = "TaskSummary" .. i
        local projectMeter = "TaskProject" .. i
        local projectBgMeter = "TaskProjectBackground" .. i

        SKIN:Bang("!SetOption", bgMeter, "X", task.x + 40)
        SKIN:Bang("!SetOption", bgMeter, "Y", task.y)
        SKIN:Bang("!ShowMeter", bgMeter)

        SKIN:Bang("!SetOption", summaryMeter, "Text", task.summary)
        SKIN:Bang("!SetOption", summaryMeter, "X", task.x + 50)
        SKIN:Bang("!SetOption", summaryMeter, "Y", task.y + 10)
        SKIN:Bang("!SetOption", summaryMeter, "ToolTipText", task.details or "")
        SKIN:Bang("!ShowMeter", summaryMeter)

        SKIN:Bang("!SetOption", projectBgMeter, "X", task.x + 45)
        SKIN:Bang("!SetOption", projectBgMeter, "Y", task.y + 32)
        SKIN:Bang("!ShowMeter", projectBgMeter)

        SKIN:Bang("!SetOption", projectMeter, "Text", task.project)
        SKIN:Bang("!SetOption", projectMeter, "X", task.x + 50)
        SKIN:Bang("!SetOption", projectMeter, "Y", task.y + 34)
        SKIN:Bang("!ShowMeter", projectMeter)
    end

    function hideTaskInSlot(i)
        SKIN:Bang("!HideMeter", "TaskBg" .. i)
        SKIN:Bang("!HideMeter", "TaskSummary" .. i)
        SKIN:Bang("!HideMeter", "TaskProject" .. i)
    end

    -- For each card slot
    for i = 1, MAX_CARDS do
        -- Assign task to slot
        local task = renderTasks[i]
        -- If slot exists
        if task then
            -- Show slot
            showTaskInSlot(i, task)
        -- If not, then hide slot
        else
            hideTaskInSlot(i)
        end
    end

    SKIN:Bang("!UpdateMeter", "*")
    SKIN:Bang("!Redraw")
end

function PickUpTask(slotIndex)
    function highlightSelectedSlot(slotIndex)
        for i = 1, MAX_CARDS do
            local bgMeter = "TaskBg" .. i

            if i == slotIndex then
                SKIN:Bang("!SetOption", bgMeter, "Shape", "Rectangle 0,0,220,72,8 | Fill Color 55,55,55,235 | StrokeWidth 2 | Stroke Color 120,180,255,255")
            else
                SKIN:Bang("!SetOption", bgMeter, "Shape", "Rectangle 0,0,220,72,8 | Fill Color 40,40,40,220 | StrokeWidth 1 | Stroke Color 90,90,90,255")
            end
        end

        SKIN:Bang("!UpdateMeter", "*")
        SKIN:Bang("!Redraw")
    end

    slotIndex = tonumber(slotIndex)

    local task = renderTasks[slotIndex]
    if not task then
        return
    end

    selectedTask.active = true
    selectedTask.taskId = task.id
    selectedTask.slotIndex = slotIndex
    selectedTask.sourceColumn = task.column

    highlightSelectedSlot(slotIndex)
end


function DropTask(targetColumn)
    targetColumn = tonumber(targetColumn)

    if not selectedTask.active then
        return
    end

    moveTaskToColumn(selectedTask.taskId, targetColumn)
    saveAllTasks()
    refreshBoard()
    clearSelectedTask()
end

function moveTaskToColumn(taskId, targetColumn)
    local taskToMove = nil

    local sourceColumnName = getColumnName(selectedTask.sourceColumn)
    local columnTasks = tasks[sourceColumnName]

    for i, task in ipairs(columnTasks) do
        if task.id == taskId then
            taskToMove = task
            table.remove(columnTasks, i)
            break
        end
    end

    if not taskToMove then
        return
    end

    local targetColumnName = getColumnName(targetColumn)

    table.insert(tasks[targetColumnName], taskToMove)
end

function getColumnName(columnNumber)
    if columnNumber == 1 then
        return "todo"
    elseif columnNumber == 2 then
        return "inprogress"
    else
        return "done"
    end
end

function clearSelectedTask()
    selectedTask.active = false
    selectedTask.taskId = nil
    selectedTask.slotIndex = nil
    selectedTask.sourceColumn = nil

    resetAllCardHighlights()
end

function clearNewTask()
    newTask.summary = nil
    newTask.project = nil
    newTask.details = nil
    newTask.column = nil
end

function resetAllCardHighlights()
    for i = 1, MAX_CARDS do
        local bgMeter = "TaskBg" .. i
        SKIN:Bang("!SetOption", bgMeter, "Shape", "Rectangle 0,0,220,72,8 | Fill Color 40,40,40,220 | StrokeWidth 1 | Stroke Color 90,90,90,255")
    end

    SKIN:Bang("!UpdateMeter", "*")
    SKIN:Bang("!Redraw")
end

function saveAllTasks()
    saveTaskFile("todo.json", tasks.todo)
    saveTaskFile("inprogress.json", tasks.inprogress)
    saveTaskFile("done.json", tasks.done)
end

function saveTaskFile(filename, taskList)
    local path = SKIN:GetVariable("CURRENTPATH") .. "data\\" .. filename
    local file = io.open(path, "w")
    if not file then
        return
    end

    local saveList = {}

    for _, task in ipairs(taskList) do
        table.insert(saveList, {
            id = task.id,
            summary = task.summary,
            project = task.project,
            details = task.details
        })
    end

    file:write(json.encode(saveList))
    file:close()
end

function ClearDoneTasks()
    tasks.done = {}
    saveTaskFile("done.json", tasks.done)
    refreshBoard()
end

function SetPendingSummary(summary)
    if not summary or summary == "" then
        return
    end

    newTask.id = tostring(os.time())
    newTask.summary = summary
    newTask.column = 1
end

function SetPendingProject(project)
    if not project or project == "" then
        return
    end

    newTask.project = project
    AddTodoTask()
end

function AddTodoTask()
    if not newTask.summary or not newTask.project then
        return
    end

    table.insert(tasks.todo, {
        id = newTask.id,
        summary = newTask.summary,
        project = newTask.project,
        details = newTask.details,
        column = 1
    })

    saveTaskFile("todo.json", tasks.todo)
    refreshBoard()

    clearNewTask()
end