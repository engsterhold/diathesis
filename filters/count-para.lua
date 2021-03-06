--[[

Make all 'regular' paragraphs into a div and assign a numeric ID
Format this number in the left margin

Copyright © 2021 Michael Cysouw <cysouw@mac.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

count = 0
chapter = 0

------------------------------------
-- User Settings with default values
------------------------------------

resetAtChapter = false

function getUserSettings (meta)
  if meta.resetAtChapter ~= nil then
    resetAtChapter = meta.resetAtChapter
  end
end

------------------------
-- Add global formatting
------------------------

function addGlobalFormatting (meta)

  local tmp = meta['header-includes']
              or pandoc.MetaList{meta['header-includes']}
  
  if FORMAT:match "html" then
    local css = [[ 
    <style>
    .paragraph-number sup { 
      color: grey;
      font-size: x-small;
    }
    </style>
    ]]
    tmp[#tmp+1] = pandoc.MetaBlocks(pandoc.RawBlock("html", css))
  end
  
  function addTexPreamble (tex)
    tmp[#tmp+1] = pandoc.MetaBlocks(pandoc.RawBlock("tex", tex))
  end

  if FORMAT:match "latex" then
    addTexPreamble("\\usepackage{geometry}")
    addTexPreamble("\\usepackage{marginnote}")
    addTexPreamble("\\reversemarginpar")
  end
  
  meta['header-includes'] = tmp
  return(meta)
end

-------------------------
-- count Para and add Div
-------------------------

function countPara (doc)

  for i=1,#doc.blocks do

    -- optionally reset counter
    if  doc.blocks[i].tag == "Header"
        and doc.blocks[i].level == 1
        and doc.blocks[i].classes[1] ~= "unnumbered" 
        and resetAtChapter
    then
        chapter = chapter + 1
        count = 0
    end

    -- count Para, but not if there is an Image inside
    if  doc.blocks[i].tag == "Para"
        and doc.blocks[i].content[1].tag ~= "Image"
    then
      count = count + 1	

      local ID = count
      if resetAtChapter then 
        ID = chapter.."."..count 
      end

      -- add Div with class to Para	
      doc.blocks[i] = pandoc.Div( doc.blocks[i], 
          pandoc.Attr(ID, {"paragraph-number"}))
    end

  end
  return doc
end

------------------------------
-- format for Latex and HTML using attributes
-- for other formats, use HTML
------------------------------

function formatNumber (div)
  
  -- only do this for Divs of the right class
  if div.classes[1] == "paragraph-number" then
    local string = "["..div.identifier.."]"

    if FORMAT:match "latex" then
      -- use marginnote for formatting number in margin
      local texInsert = pandoc.RawInline("tex", 
                          "\\marginnote{ \
                              \\color{lightgray} \
                              \\tiny \
                              \\textsuperscript{"..string.."} \
                          }" )
      table.insert(div.content[1].content, 1, texInsert)

    else
      
      -- format number at start of Para
      local number = pandoc.Superscript(string)
      table.insert(div.content[1].content, 1, pandoc.Space())
      table.insert(div.content[1].content, 1, number)
      
      -- rough approximation for negative text indent
      local points = string.len(div.identifier)*5 + 10
      div.attributes = {style = "text-indent: -"..points.."px;"}
      end
    
  end
  return(div)
  --return(div.content[1])
end

--------------------
-- basic Pandoc loop
--------------------

return {
  { Meta = addGlobalFormatting },
  { Meta = getUserSettings },
  { Pandoc = countPara },
  { Div = formatNumber }
}
