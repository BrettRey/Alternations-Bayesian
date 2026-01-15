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

local function match_macro(text, name)
  local pat = "^\\\\" .. name .. "%{(.+)%}$"
  return text:match(pat)
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
