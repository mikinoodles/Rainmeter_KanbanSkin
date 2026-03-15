json = nil

tasks = {}
taskMeterPool = {
    count = 0
}
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
MAX_SLOTS = 30

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
    RenderAllTasks(renderTasks)
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

function RenderAllTasks(renderTasks)

    function HideUnusedMeters(fromIndex)
        for i = fromIndex, MAX_SLOTS do
            SKIN:Bang('!HideMeter', 'TaskBg' .. i)
            SKIN:Bang('!HideMeter', 'TaskSummary' .. i)
            SKIN:Bang('!HideMeter', 'TaskProjectBg' .. i)
            SKIN:Bang('!HideMeter', 'TaskProject' .. i)
        end
    end

    function RenderMeters(renderTasks)
        for i, task in ipairs(renderTasks) do
            local bg = "TaskBg" .. i
            local summary = "TaskSummary" .. i
            local projectBg = "TaskProjectBg" .. i
            local project = "TaskProject" .. i

            local leftMouseUpAction = string.format('[!CommandMeasure MeasureScript "OnTaskClick(%d)"]', i)

            SKIN:Bang('!SetOption', bg, 'MeterStyle', "StyleCardBackground")
            SKIN:Bang('!SetOption', bg, 'X', task.x + 40)
            SKIN:Bang('!SetOption', bg, 'Y', task.y)
            SKIN:Bang('!SetOption', bg, "LeftMouseUpAction", leftMouseUpAction)
            SKIN:Bang('!ShowMeter', bg)

            SKIN:Bang('!SetOption', summary, 'MeterStyle', "StyleCardSummary")
            SKIN:Bang('!SetOption', summary, 'Text', task.summary)
            SKIN:Bang('!SetOption', summary, 'X', task.x + 50)
            SKIN:Bang('!SetOption', summary, 'Y', task.y + 10)
            SKIN:Bang('!SetOption', summary, "LeftMouseUpAction", leftMouseUpAction)
            SKIN:Bang('!ShowMeter', summary)

            SKIN:Bang('!SetOption', projectBg, 'MeterStyle', "StyleCardProjectBackground")
            SKIN:Bang('!SetOption', projectBg, 'Shape', string.format(
                "Rectangle 0,0,([TaskProject%d:W] + 10),22,6 | Extend ProjectBgModifiers", i
            ))
            SKIN:Bang('!SetOption', projectBg, 'X', task.x + 45)
            SKIN:Bang('!SetOption', projectBg, 'Y', task.y + 32)
            SKIN:Bang('!SetOption', projectBg, "LeftMouseUpAction", leftMouseUpAction)
            SKIN:Bang('!ShowMeter', projectBg)

            SKIN:Bang("!SetOption", project, "MeterStyle", "StyleCardProject")
            SKIN:Bang("!SetOption", project, "Text", task.project)
            SKIN:Bang("!SetOption", project, "X", task.x + 50)
            SKIN:Bang("!SetOption", project, "Y", task.y + 34)
            SKIN:Bang('!SetOption', project, "LeftMouseUpAction", leftMouseUpAction)
            SKIN:Bang("!ShowMeter", project)
        end
    end

    local count = #renderTasks

    RenderMeters(renderTasks)

    HideUnusedMeters(count + 1)

    SKIN:Bang("!UpdateMeterGroup", "Tasks")
    SKIN:Bang("!Redraw")
end

function OnTaskClick(slotIndex)
    print("Clicked " .. slotIndex)

    function removeHighlightFromAll()
        for i,_ in ipairs(renderTasks) do
            local unselectedBgMeter = "TaskBg" .. i
            SKIN:Bang("!SetOption", unselectedBgMeter, "Shape", "Rectangle 0,0,220,72,8 | Fill Color 40,40,40,220 | StrokeWidth 1 | Stroke Color 90,90,90,255")
            SKIN:Bang("!ShowMeter", unselectedBgMeter)
        end
    end

    function highlightSelectedSlot(slotIndex)
        local selectedBgMeter = "TaskBg" .. slotIndex
        SKIN:Bang("!SetOption", selectedBgMeter, "Shape", "Rectangle 0,0,220,72,8 | Fill Color 55,55,55,235 | StrokeWidth 2 | Stroke Color 120,180,255,255")
        SKIN:Bang("!ShowMeter", selectedBgMeter)
    end

    removeHighlightFromAll()
    highlightSelectedSlot(slotIndex)

    local task = renderTasks[slotIndex]
    if not task then return end

    selectedTask.active = true
    selectedTask.taskId = task.id
    selectedTask.slotIndex = slotIndex
    selectedTask.sourceColumn = task.column
    
    SKIN:Bang("!UpdateMeterGroup", "Tasks")
    SKIN:Bang("!Redraw")
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