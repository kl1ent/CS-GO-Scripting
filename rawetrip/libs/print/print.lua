local print = function(...)
    local data = {...}
    local current_table_with_strings = {}

    if #data == 0 then
        current_table_with_strings[#current_table_with_strings + 1] = "No values selected to debug."
    else
        for index = 1, #data do
            local current_element = data[index]
            if type(current_element) == "function" then
                current_table_with_strings[index] = ("function %s: %s"):format(
                    (tostring(current_element)):gsub("function: ", ""), current_element() or "nil"
                )
            elseif type(current_element) == "table" then
                for additional_elements = 1, #current_element do
                    if type(current_element[additional_elements]) == "function" then
                        current_element[additional_elements] = ("function %s: %s"):format(
                            (tostring(current_element[additional_elements])):gsub("function: ", ""), current_element[additional_elements]() or "nil"
                        )
                    elseif type(current_element[additional_elements]) == "string" then
                        current_element[additional_elements] = ("\"%s\""):format(current_element[additional_elements])
                    else
                        current_element[additional_elements] = tostring(current_element[additional_elements])
                    end
                end

                current_table_with_strings[index] = ("{%s}"):format(table.concat(current_element, ", "))
            else
                current_table_with_strings[index] = tostring(current_element)
            end
        end
    end

    console.print_color("[rawetrip] ", color.new(247, 132, 58, 255))
    console.print(table.concat(current_table_with_strings, " ") .. "\n")
end
