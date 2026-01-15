-- House style Lua filter for Quarto
-- Converts LaTeX semantic macros to HTML equivalents

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

-- Macro definitions matching house-style preamble.tex
local macros = {
  -- Semantic typography
  mention = function(content) return pandoc.Emph(text_to_inlines(content)) end,
  term = function(content) return pandoc.SmallCaps(text_to_inlines(content)) end,
  olang = function(content) return pandoc.Emph(text_to_inlines(content)) end,
  mentionh = function(content)
    return pandoc.RawInline("html", "<span class=\"mentionh\">&lang;" .. content .. "&rang;</span>")
  end,
  enquote = function(content)
    return pandoc.RawInline("html", "&ldquo;" .. content .. "&rdquo;")
  end,
  abbr = function(content)
    return pandoc.RawInline("html", "<span class=\"abbr\">" .. content .. "</span>")
  end,
  ipa = function(content)
    return pandoc.RawInline("html", "<span class=\"ipa\">" .. content .. "</span>")
  end,
  -- Judgement markers
  ungram = function(content)
    return pandoc.RawInline("html", "<span class=\"ungram\">*" .. content .. "</span>")
  end,
  marg = function(content)
    return pandoc.RawInline("html", "<span class=\"marg\">?" .. content .. "</span>")
  end,
  odd = function(content)
    return pandoc.RawInline("html", "<span class=\"odd\">#" .. content .. "</span>")
  end,
  -- Cross-linguistic notation
  crossmark = function(content)
    return pandoc.RawInline("html", "<sub>&#x2717;</sub>")
  end
}

-- Zero-argument macros (abbreviations)
local zero_arg_macros = {
  eg = "e.g.,",
  ie = "i.e.,",
  etc = "etc."
}

local function replace_macros_in_text(text)
  local inlines = {}

  -- Handle zero-argument macros first
  for name, replacement in pairs(zero_arg_macros) do
    text = text:gsub("\\\\" .. name .. "([^%a])", replacement .. "%1")
    text = text:gsub("\\\\" .. name .. "$", replacement)
  end

  -- Handle \crossmark (no braces)
  text = text:gsub("\\\\crossmark", "<sub>&#x2717;</sub>")

  while true do
    local best_start = nil
    local best_end = nil
    local best_name = nil
    local best_content = nil

    for name, _ in pairs(macros) do
      if name ~= "crossmark" then  -- crossmark handled above
        local s, e, content = text:find("\\\\" .. name .. "%{(.-)%}")
        if s and (best_start == nil or s < best_start) then
          best_start = s
          best_end = e
          best_name = name
          best_content = content
        end
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

-- List of all macro names for pattern matching
local macro_names = {
  "mention", "term", "olang", "mentionh", "enquote",
  "abbr", "ipa", "ungram", "marg", "odd"
}

local function has_any_macro(text)
  for _, name in ipairs(macro_names) do
    if text:find("\\" .. name .. "%{") then
      return true
    end
  end
  -- Also check zero-arg macros
  if text:find("\\eg[^%a]") or text:find("\\ie[^%a]") or
     text:find("\\etc[^%a]") or text:find("\\crossmark") then
    return true
  end
  return false
end

function RawInline(el)
  if not FORMAT:match("html") then
    return nil
  end

  if el.format ~= "tex" and el.format ~= "latex" then
    return nil
  end

  -- Single-macro exact matches
  local content = el.text:match("^\\mention%{(.+)%}$")
  if content then
    return pandoc.Emph(text_to_inlines(content))
  end

  content = el.text:match("^\\term%{(.+)%}$")
  if content then
    return pandoc.SmallCaps(text_to_inlines(content))
  end

  content = el.text:match("^\\olang%{(.+)%}$")
  if content then
    return pandoc.Emph(text_to_inlines(content))
  end

  content = el.text:match("^\\mentionh%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"mentionh\">&lang;" .. content .. "&rang;</span>")
  end

  content = el.text:match("^\\enquote%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "&ldquo;" .. content .. "&rdquo;")
  end

  content = el.text:match("^\\abbr%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"abbr\">" .. content .. "</span>")
  end

  content = el.text:match("^\\ipa%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"ipa\">" .. content .. "</span>")
  end

  content = el.text:match("^\\ungram%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"ungram\">*" .. content .. "</span>")
  end

  content = el.text:match("^\\marg%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"marg\">?" .. content .. "</span>")
  end

  content = el.text:match("^\\odd%{(.+)%}$")
  if content then
    return pandoc.RawInline("html", "<span class=\"odd\">#" .. content .. "</span>")
  end

  -- Zero-arg macros
  if el.text == "\\crossmark" then
    return pandoc.RawInline("html", "<sub>&#x2717;</sub>")
  end

  if el.text == "\\eg" then
    return pandoc.Str("e.g.,")
  end

  if el.text == "\\ie" then
    return pandoc.Str("i.e.,")
  end

  if el.text == "\\etc" then
    return pandoc.Str("etc.")
  end

  -- Mixed content with macros
  if has_any_macro(el.text) then
    return replace_macros_in_text(el.text)
  end

  return nil
end

function Str(el)
  if not FORMAT:match("html") then
    return nil
  end

  if has_any_macro(el.text) then
    return replace_macros_in_text(el.text)
  end

  return nil
end
