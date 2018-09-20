local table_operator_one = {"+", "-", "*", "/", "(", ")", "!"}
local table_operator = {"+", "-", "*", "/", "(", ")"}
local table_operator_priority = {["+"]=5, ["-"]=5, ["*"]=6, ["/"]=6, 
["("]=99, [")"]=-1, ["start"]=-1, ["end"]=-1}

local Caculator = {}
--local expression_str = "(1+2)*3/4-5"
local expression_table_temp = {}

local stack_operator = {"start"}
local stack_number   = {}

local function clean()
    expression_table_temp = {}
    stack_operator = {"start"}
    stack_number = {}
end

local function caculate(operator, left, right)
    if operator == "+" then
        return left + right
    elseif operator == "-" then
        return left - right
    elseif operator == "*" then
        return left * right
    elseif operator == "/" then
        if right == 0 then
            error("divide by zero")
            return 0
        else
        return left / right
        end
    end
end

local function FindAll(str)
    local function isNumber(str)
        local result = type(tonumber(str))
        return result == "number" or str == "."
    end

    local function isOneOperator(str)
        for _,v in ipairs(table_operator_one) do
            if str == v then
                return true
            end
        end
        return false
    end

    local function splitOperator(str)
        -- str = str .. "$"
        local table_operators = {}
        local operator = ""
        local index = 1
        while true do
            local character = str:sub(index, index)
            if index > #str then
                if #operator > 0 then
                    table.insert(table_operators, operator)
                end
            break
            elseif isOneOperator(character) then
                if #operator > 0 then
                    table.insert(table_operators, operator)
                end
                table.insert(table_operators, character)
            -- elseif character == "$" then
            --     if #operator then
            --         table.insert(table_operators, operator)
            --     end
            --     break
            else
                operator = operator .. character
            end

            index = index + 1
        end
        return table_operators
    end

    str = str .. "$"
    local index = 1
    local expression_table = {}
    local number = ""
    local operator = ""
    while true do
        local character = str:sub(index,index)
        -- 操作数
        if isNumber(character) then
            number = number .. character
            if #operator > 0 then
                for _, v in ipairs(splitOperator(operator)) do
                    table.insert(expression_table, v)
                end
                -- table.insert(expression_table, operator)
                operator = ""
            end
            -- print("111expression splited:")
            -- print(table.unpack(expression_table))
        -- -- 左括号
        -- elseif character == "(" then
        --     if #operator > 0 then
        --         table.insert(expression_table, operator)
        --         operator = ""
        --     elseif #number > 0 then
        --         print(" '(' 左边不应该有数字")
        --         return false
        --         -- table.insert(expression_table, tonumber(number))
        --         -- number = ""
        --     end
        --     table.insert(expression_table, character)
        -- 结束符号
        elseif character == "$" then
            if #operator > 0 then
                for _, v in ipairs(splitOperator(operator)) do
                    table.insert(expression_table, v)
                end
                operator = ""
            elseif #number > 0 then
                table.insert(expression_table, tonumber(number))
                number = ""

            else
                -- print("unknown error")
            end
            -- print("333expression splited:")
            -- print(table.unpack(expression_table))
            break
        -- 操作符
        else           
            -- operator = operator .. character
            -- -- 一元操作符
            -- if isOneOperator(character) then
            --     -- print("aaa22222222")
            --     if #number > 0 then
            --         print("一元操作符 " .. character .. "左边不应该有数字")
            --         return false
            --     elseif #operator > 0 then
            --         table.insert(expression_table, operator)
            --         operator = ""
            --         table.insert(expression_table, character)
            --     end
            -- else
            operator = operator .. character
                if #number > 0 then
                    table.insert(expression_table, tonumber(number))
                    number = ""
                end
            -- end

            -- print("222expression splited:")
            -- print(table.unpack(expression_table))
        end
        index = index + 1
    end

    return expression_table
end

local function FindDigit(str, expression_table_temp)
    local index = 1
    while true do
        local b,e = str:find("%d+%.?%d*", index)
        if b then
            expression_table_temp[b] = tonumber(str:sub(b,e))
            -- print(expression_table_temp[b])
            index = e + 1
        else
            break
        end
    end
    return expression_table_temp
end

local function FindOperator(str, expression_table_temp)
    for _, v in pairs(table_operator) do
        -- print("search operator " .. tostring(v))
        while true do
            local b, e = str:find(v,1,true)
            -- print(b,e)
            if b then
                expression_table_temp[b] = v
                -- print(expression_table_temp[b])
                str = str:sub(1,b-1) .. string.rep(" ", e-b+1) .. str:sub(e+1)
                -- print(str)
            else
                break
            end
        end

    end
    return expression_table_temp
end

local function comparePriority(stack_top, index)
    local operator_current = expression_table_target[index]
    local stack_top_priority = table_operator_priority[stack_top]
    local current_priority   = table_operator_priority[operator_current]

    if operator_current == ")" then
        if stack_top == "(" then
            stack_top_priority = current_priority
        --else
            --error("right bracket can not find a left bracket matched")
        end
    else
        if stack_top == "(" then
            current_priority = stack_top_priority + 1
        end
    end
    
    -- 栈顶运算符优先级更高，则可以立即进行计算
    if stack_top_priority > current_priority then
        -- 是否是二元运算符
        local right = table.remove(stack_number)
        local left = table.remove(stack_number)
        table.insert(stack_number, caculate(table.remove(stack_operator), left, right))
        -- index 不变，仍然要处理当前这个运算符
    -- 当前运算符优先级更高，先存入栈中
    elseif stack_top_priority < current_priority then
        table.insert(stack_operator, operator_current)
        index = index + 1
    -- 优先级相同
    else
        -- 结束符号
        if operator_current == "end" and stack_top == "start" then
            table.remove(stack_operator)
        -- 右括号情况
        elseif stack_top == "(" and operator_current == ")" then
            table.remove(stack_operator)
            index = index + 1
        -- 一般情况，那么可以立即计算
        else
            -- TODO: 是否是二元运算符
            local right = table.remove(stack_number)
            local left = table.remove(stack_number)
            table.insert(stack_number, caculate(table.remove(stack_operator), left, right))
            -- index 不变，仍然要处理当前这个运算符
        end
    end

    return index
end

local function Caculate(expression_str)
    stack_operator = {"start"}

    expression_table_temp = FindAll(expression_str)
    -- expression_table_temp = FindOperator(expression_str, expression_table_temp)
    -- expression_table_temp = FindDigit(expression_str, expression_table_temp)

    -- -- 处理变为装有操作符和操作数和table
    -- expression_table_target = {}
    -- for i = 1,#expression_str do
    --     --print(expression_table_temp[i])
    --     if expression_table_temp[i] then
    --         table.insert(expression_table_target, expression_table_temp[i])
    --     end
    -- end

    expression_table_target = expression_table_temp
    table.insert(expression_table_target,"end")

    print("expression splited = ")
    print(table.unpack(expression_table_target))

    local index = 1
    while #stack_operator > 0 do
        --print("index = " .. tostring(index))
        -- 是数字
        if type(expression_table_target[index]) == "number" then
            --print("number " .. tostring(expression_table_target[index]) .. " push")
            table.insert(stack_number, expression_table_target[index])
            index = index + 1
        -- 是运算符
        else
            --print("operator " .. expression_table_target[index] .. " comparePriority:")
            --print(stack_operator[#stack_operator],expression_table_target[index])
            index = comparePriority(stack_operator[#stack_operator], index)
        end
        --print("stack_number:")
        --print(table.unpack(stack_number))
        --print("stack_operator:")
        --print(table.unpack(stack_operator))
        --print("-------------------------------------------")
    end

    return table.remove(stack_number)
end

Caculator.Input = function()
    local expression = ""
    while(true) do
        print("----------------------------------------- \n enter your expression (q/quit to exit)")
        expression = io.read("l")
        
        if expression == "q" or expression == "quit" then
            print("user quit.")
            break
        end
        
        if expression == "" then
            print("empty expression")
        else
            print("origin expression = " .. tostring(expression))
            local noError, result = pcall(Caculate, expression)
            if not noError then
                print("expression has mistake")
            else
                local result_int = math.tointeger(result)
                if result_int then
                    print("result = " .. result_int)
                else
                    print("result = " .. result)
                end
            end
        end
        -- 清理重置
        clean()
    end
end

return Caculator