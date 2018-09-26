local table_operator_unary = {"!", "sin", "cos", "tan"}
-- local table_operator_one = {"+", "-", "*", "/", "(", ")", "!"}
local table_operator = {"+", "-", "*", "/", "(", ")", "!", "sin", "cos", "tan"}
local table_operator_priority = {["+"]=5, ["-"]=5, ["*"]=6, ["/"]=6, ["!"]=80, ["sin"]=70, ["cos"]=70, ["tan"]=70,
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

local function isUnaryOperator(str)
    for _, v in ipairs(table_operator_unary) do
        if v == str then
            return true
        end
    end
    return false
end

local function isNumber(str)
    local result = type(tonumber(str))
    return result == "number" or str == "."
end

local function isOperator(str)
    for _,v in ipairs(table_operator) do
        if str == v then
            return true
        end
    end
    return false
end

local pi = 3.14159265358979323846
-- 修复不规范的写法
local fixTable = {
["(%d.?)pi"] = "%1*" .. tostring(pi), ["(pi)%(pi"] = "%1*(" .. tostring(pi),
["pi"] = tostring(pi),
-- ["%^d%.?%d*"] = "0%1",
["Sin"] = "sin", ["Cos"] = "cos", ["Tan"] = "tan"}
local function preFix(expression)
    for pattern,replace in pairs(fixTable) do
        expression = string.gsub(expression, pattern, replace)
    end
    return expression
end

-- 对区分开了运算符和运算数的table中的 - + 符号做预处理
local function fixPlusMinus(expression_table)
    for index = 1, #expression_table do
        local word = expression_table[index]

        -- 一元操作符的 - +，则在前边补上0
        if word == "-" or word == "+" then
            local last = expression_table[index - 1]
            if (last and (last == "(")) or index == 1 then
                table.insert(expression_table, index, 0)
            end
        -- sin/! 等一元操作符后如果是数字，补全()括号
        elseif isUnaryOperator(word) then
            local nextone = expression_table[index + 1]
            if nextone and isNumber(nextone) then
                table.insert(expression_table, index + 1, "(")
                table.insert(expression_table, index + 3, ")")
            end
        end
    end
    return expression_table
end

-- 添加省略的 * 星号
local fillStarTable = {
["(%d)sin"] = "%1*sin", ["(%d)cos"] = "%1*cos", ["(%d)tan"] = "%1*tan",
["(%))sin"] = "%1*sin", ["(%))cos"] = "%1*cos", ["(%)tan"] = "%1*tan",
-- ["(%d%.?)pi"] = "(%1*pi)", ["%(pi"] = "*(pi", ["%)pi"] = ")*pi",
["(%d%.?)%("] = "%1*(", ["%)(%d%.?)"] = ")*%1",
}
local function fillStar(expression)
    for pattern,replace in pairs(fillStarTable) do
        expression = string.gsub(expression, pattern, replace)
    end
    return expression
end

-- 计算二元运算符
local function caculate(operator, left, right)
    if operator == "+" then
        return left + right
    elseif operator == "-" then
        return left - right
    elseif operator == "*" then
        return left * right
    elseif operator == "/" then
        if right == 0 then
            print("error:divide by zero")
            return 0
        else
            return left / right
        end
    end
end

-- 计算一元运算符
local function caculateUnary(operator, number)
    local function factorial(number)
        if number == 0 then
            return 1
        else
            return number * factorial(number - 1)
        end
    end

    if operator == "!" then
        return factorial(number)
    elseif operator == "sin" then
        return math.sin(number)
    elseif operator == "cos" then
        return math.cos(number)
    elseif operator == "tan" then
        return math.tan(number)
    end
end

-- 将字符串分为运算数和运算符
local function FindAll(str)
    local function splitOperator(str)
        local table_operators = {}
        local operator = ""
        for index = 1, #str do
            operator = operator .. str:sub(index, index)
            if isOperator(operator) then
                table.insert(table_operators, operator)
                operator = ""
            end
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
                operator = ""
            end
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

            break
        -- 操作符
        else
            operator = operator .. character
            if #number > 0 then
                table.insert(expression_table, tonumber(number))
                number = ""
            end
        end
        index = index + 1
    end

    return expression_table
end

-- 根据当前运算符与栈顶运算符的优先级决定是否
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
        -- 是否是一元运算符
        if isUnaryOperator(stack_top) then
            table.insert(stack_number, caculateUnary(table.remove(stack_operator), table.remove(stack_number)))
        else
            local right = table.remove(stack_number)
            local left = table.remove(stack_number)
            table.insert(stack_number, caculate(table.remove(stack_operator), left, right))
        end
        -- index 不变，仍然要处理当前这个运算符
        --
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
            -- 是否是一元运算符
            if isUnaryOperator(stack_top) then
                table.insert(stack_number, caculateUnary(table.remove(stack_operator), table.remove(stack_number)))
            else
                local right = table.remove(stack_number)
                local left = table.remove(stack_number)
                table.insert(stack_number, caculate(table.remove(stack_operator), left, right))
            end
            -- index 不变，仍然要处理当前这个运算符
        end
    end

    return index
end

-- 处理输入的表达式并返回结果
local function Caculate(expression_str)

    -- 预处理
    expression_str = preFix(expression_str)
    expression_str = fillStar(expression_str)

    print("fixed expression = " .. tostring(expression_str))


    stack_operator = {"start"}
    expression_table_temp = FindAll(expression_str)
    expression_table_temp = fixPlusMinus(expression_table_temp)

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

-- 输入
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