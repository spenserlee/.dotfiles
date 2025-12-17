local M = {}

local is_pattern_keyword = {
  ["--pattern"] = true,
  ["--pcre"] = true,
}

local is_argument_keyword = {
  ["--context"] = true,
  ["--no_case"] = true,
  ["--distance"] = true,
  ["--distance_abs"] = true,
  ["--within"] = true,
  ["--within_abs"] = true,
}

--- Formats the signature on the current line.
function M.format_signature()
  -- 1. Get the current line and its number
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_get_current_line()

  -- 2. Extract the header (e.g., "F-SBID") and the main content within the parentheses
  local header = line_content:match("^(.-)%(")
  local content = line_content:match("%((.*)%)")

  if not content or not header then
    vim.notify("Error: Line does not match the expected 'F-SBID(...)' format.", vim.log.levels.ERROR)
    return
  end

  -- 3. Split the content into a table of individual components based on the semicolon
  local components = {}
  for comp in content:gmatch("[^;]+") do
    local trimmed = vim.trim(comp)
    if #trimmed > 0 then
      table.insert(components, trimmed)
    end
  end

  -- 4. Process components into logically grouped lines
  local formatted_lines = {}
  local current_group = {}

  local function flush_group()
    if #current_group > 0 then
      -- Join the components in the group with "; " and add to our final list
      table.insert(formatted_lines, "  " .. table.concat(current_group, "; "))
      current_group = {} -- Reset the group
    end
  end

  for _, comp in ipairs(components) do
    local keyword = comp:match("(%S+)") -- Get the first word (the keyword itself)
    if is_pattern_keyword[keyword] then
      flush_group() -- A new major keyword means the previous group is finished.
      table.insert(current_group, comp) -- Start a new group with this component.
    else
      -- Not a major keyword
      if #current_group > 0 then
        -- Is it an argument?
        if is_argument_keyword[keyword] then
          -- Yes, append it to group.
          table.insert(current_group, comp)
        else
          -- No, finish the group and add the standalone one.
          flush_group()
          table.insert(current_group, comp)
          flush_group()
        end
      else
        -- This is a standalone component. Treat it as a group of one.
        table.insert(current_group, comp)
        flush_group()
      end
    end
  end
  flush_group() -- Flush any remaining group after the loop finishes.

  -- 5. Assemble the final, multi-line string to replace the original line
  local final_block = { header .. "(" }
  for _, formatted_line in ipairs(formatted_lines) do
    table.insert(final_block, formatted_line .. ";")
  end
  table.insert(final_block, ")")

  -- 6. Replace the original line in the buffer with our new block of formatted lines
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, final_block)

  vim.notify("Signature formatted successfully!", vim.log.levels.INFO)
end

return M
