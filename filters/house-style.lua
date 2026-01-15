local function text_to_inlines(text)
  local inlines = {}
  for word in text:gmatch("%S+") do
    if #inlines > 0 then
      table.insert(inlines, pandoc.Space())
    end
    table.insert(inlines, pandoc.Str(word))
  end
  return inlines
end

local function append_text(inlines, text)
  if text == nil or text == "" then
    return
  end
  for word in text:gmatch("%S+") do
    if #inlines > 0 then
      table.insert(inlines, pandoc.Space())
    end
    table.insert(inlines, pandoc.Str(word))
  end
end

local function match_macro(text, name)
  local pat = "^\\\\" .. name .. "%{(.+)%}$"
  return text:match(pat)
end

local function replace_macros_in_text(text)
  local inlines = {}
  local macros = {
    mention = function(content) return pandoc.Emph(text_to_inlines(content)) end,
    term = function(content) return pandoc.SmallCaps(text_to_inlines(content)) end,
    olang = function(content) return pandoc.Emph(text_to_inlines(content)) end,
    mentionh = function(content)
      return pandoc.RawInline("html", "<span class=\"mentionh\">&lang;" .. content .. "&rang;</span>")
    end
  }

  while true do
    local best_start = nil
    local best_end = nil
    local best_name = nil
    local best_content = nil

    for name, _ in pairs(macros) do
      local s, e, content = text:find("\\\\" .. name .. "%{(.-)%}")
      if s and (best_start == nil or s < best_start) then
        best_start = s
        best_end = e
        best_name = name
        best_content = content
      end
    end

    if not best_start then
      break
    end

    append_text(inlines, text:sub(1, best_start - 1))
    table.insert(inlines, macros[best_name](best_content))
    text = text:sub(best_end + 1)
  end

  append_text(inlines, text)
  return inlines
end

function RawInline(el)
  if not FORMAT:match("html") then
    return nil
  end

  if el.format ~= "tex" and el.format ~= "latex" then
    return nil
  end

  local content = match_macro(el.text, "mention")
  if content then
    return pandoc.Emph(text_to_inlines(content))
  end

  content = match_macro(el.text, "term")
  if content then
    return pandoc.SmallCaps(text_to_inlines(content))
  end

  content = match_macro(el.text, "olang")
  if content then
    return pandoc.Emph(text_to_inlines(content))
  end

  content = match_macro(el.text, "mentionh")
  if content then
    return pandoc.RawInline("html", "<span class=\"mentionh\">&lang;" .. content .. "&rang;</span>")
  end

  return nil
end

function Str(el)
  if not FORMAT:match("html") then
    return nil
  end

  if el.text:find("\\\\mention%{") or el.text:find("\\\\term%{") or
     el.text:find("\\\\olang%{") or el.text:find("\\\\mentionh%{") then
    return replace_macros_in_text(el.text)
  end

  return nil
end
