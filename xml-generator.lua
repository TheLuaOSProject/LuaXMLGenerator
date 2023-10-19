---@diagnostic disable: invisible
-- https://leafo.net/guides/setfenv-in-lua52-and-above.html
local setfenv = setfenv or function(fn, env)
    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.upvaluejoin(fn, i, (function() return env end), 1)
            break
        elseif not name then
            break
        end

        i = i + 1
    end

    return fn
end


---@class xml-generator
local export = {
    sanitize_style = false,
}

---@class XML.Children
---@field [integer] XML.Node | string

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.AttributeTable): XML.Node
---@field private tag string
---@field private children XML.Children
---@field private attributes XML.AttributeTable

---quotes are allowed in text, not in attributes
---@param str string
---@return string
function export.sanitize_text(str)
    return (str:gsub("[<>&]", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;"
    }))
end

---@param str string
---@return string
function export.sanitize_attributes(str)
    return (export.sanitize_text(str):gsub("\"", "&quot;"):gsub("'", "&#39;"))
end

---@generic T
---@param x T
---@return type | `T`
function export.typename(x)
    local mt = getmetatable(x)
    if mt and mt.__name then
        return mt.__name
    else
        return type(x)
    end
end
local typename = export.typename

---@param node XML.Node
---@return string
function export.node_to_string(node)
    local sanitize = (not export.sanitize_style) and node.tag ~= "style"
    local sanitize_text = sanitize and export.sanitize_text or function (...) return ... end

    local html = "<"..node.tag

    for k, v in pairs(node.attributes) do
        if type(v) == "boolean" then
            if v then html = html.." "..k end
        else
            html = html.." "..k.."=\""..export.sanitize_attributes(tostring(v)).."\""
        end
    end

    html = html..">"

    for i, v in ipairs(node.children) do
        if type(v) ~= "table" then
            html = html..sanitize_text(tostring(v))
        else
            html = html..export.node_to_string(v)
        end
    end

    html = html.."</"..node.tag..">"

    return html
end

---@class XML.GeneratorTable
---@field lua _G
---@field [string] XML.Node
export.xml = setmetatable({}, {
    ---@param _ XML.GeneratorTable
    ---@param tag_name string
    __index = function(_, tag_name)
        --When used
        if tag_name == "lua" then return _G end

        ---@type XML.Node
        local node = {
            tag = tag_name,
            children = {},
            attributes = {}
        }
        return setmetatable(node, {

            ---@param self XML.Node
            ---@param attribs XML.AttributeTable | string | XML.Node
            ---@return XML.Node
            __call = function (self, attribs)
                local tname = typename(attribs)
                if tname == "table" then
                    for i, v in ipairs(attribs --[[@as (string | XML.Node | fun(): XML.Node)[] ]]) do
                        local tname = typename(v)
                        if tname == "function" then
                            ---@type fun(): XML.Node | string
                            v = coroutine.wrap(v --[[@as function]])
                            for elem in v do self.children[#self.children+1] = elem end
                        else
                            self.children[#self.children+1] = v --[[@as string | XML.Node]]
                        end

                        attribs[i] = nil
                    end

                    for key, value in pairs(attribs --[[@as { [string] : string | boolean | number }]]) do
                        self.attributes[key] = value
                    end
                else
                    self.children[#self.children+1] = (tname == "XML.Node" and attribs or tostring(attribs)) --[[@as string | XML.Node]]
                end

                return self
            end;

            __tostring = export.node_to_string;

            __name = "XML.Node";
        })
    end
})

--[[# <code>dl</code>
## Description
Association list consisting of zero or more name-value groups


]]
---@class HTMLElement.dl : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.dl=export.xml.dl

--[[# <code>datalist</code>
## Description
Container for options for


]]
---@class HTMLElement.datalist : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.datalist=export.xml.datalist

--[[# <code>blockquote</code>
## Description
A section quoted from another source


]]
---@class HTMLElement.blockquote : XML.Node
export.xml.blockquote=export.xml.blockquote

--[[# <code>dd</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Content for corresponding</lol-ignore-this>
  <lol-ignore-this>element(s)</lol-ignore-this>
    <code id="elements-3:the-dt-element">
        <a href="https://html.spec.whatwg.org/multipage/grouping-content.html#the-dt-element">
        dt
        </a>
    </code>
</lol-ignore-this>



]]
---@class HTMLElement.dd : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.dd=export.xml.dd

--[[# <code>tbody</code>
## Description
Group of rows in a table


]]
---@class HTMLElement.tbody : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.tbody=export.xml.tbody

--[[# <code>style</code>
## Description
Embedded styling information


]]
---@class HTMLElement.style : XML.Node
---@field media any [Documentation](https://html.spec.whatwg.org/multipage/semantics.html#attr-style-media)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.style=export.xml.style

--[[# <code>ol</code>
## Description
Ordered list


## Categories- flow
- palpable
]]
---@class HTMLElement.ol : XML.Node
---@field reversed any [Documentation](https://html.spec.whatwg.org/multipage/grouping-content.html#attr-ol-reversed)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.ol=export.xml.ol

--[[# <code>dt</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Legend for corresponding</lol-ignore-this>
  <lol-ignore-this>element(s)</lol-ignore-this>
    <code id="elements-3:the-dd-element-3">
        <a href="https://html.spec.whatwg.org/multipage/grouping-content.html#the-dd-element">
        dd
        </a>
    </code>
</lol-ignore-this>



]]
---@class HTMLElement.dt : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.dt=export.xml.dt

--[[# <code>div</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Generic flow container, or container for name-value groups in</lol-ignore-this>
  <lol-ignore-this>elements</lol-ignore-this>
    <code id="elements-3:the-dl-element-2">
        <a href="https://html.spec.whatwg.org/multipage/grouping-content.html#the-dl-element">
        dl
        </a>
    </code>
</lol-ignore-this>



]]
---@class HTMLElement.div : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.div=export.xml.div

--[[# <code>hgroup</code>
## Description
Heading container


]]
---@class HTMLElement.hgroup : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.hgroup=export.xml.hgroup

--[[# <code>template</code>
## Description
Template


## Categories- metadata
- flow
- phrasing
- script-supporting
]]
---@class HTMLElement.template : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.template=export.xml.template

--[[# <code>header</code>
## Description
Introductory or navigational aids for a page or section


]]
---@class HTMLElement.header : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.header=export.xml.header

--[[# <code>del</code>
## Description
A removal from the document


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.del : XML.Node
---@field cite any [Documentation](https://html.spec.whatwg.org/multipage/edits.html#attr-mod-cite)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.del=export.xml.del

--[[# <code>img</code>
## Description
Image


## Categories- flow
- phrasing
- embedded
- interactive
- form-associated
- palpable
]]
---@class HTMLElement.img : XML.Node
---@field alt any [Documentation](https://html.spec.whatwg.org/multipage/embedded-content.html#attr-img-alt)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.img=export.xml.img

--[[# <code>td</code>
## Description
Table cell


]]
---@class HTMLElement.td : XML.Node
---@field colspan any [Documentation](https://html.spec.whatwg.org/multipage/tables.html#attr-tdth-colspan)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.td=export.xml.td

--[[# <code>abbr</code>
## Description
Abbreviation


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.abbr : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.abbr=export.xml.abbr

--[[# <code>menu</code>
## Description
Menu of commands


## Categories- flow
- palpable
]]
---@class HTMLElement.menu : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.menu=export.xml.menu

--[[# <code>dfn</code>
## Description
Defining instance


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.dfn : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.dfn=export.xml.dfn

--[[# <code>span</code>
## Description
Generic phrasing container


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.span : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.span=export.xml.span

--[[# <code>iframe</code>
## Description
<lol-ignore-this>
    <a href="https://html.spec.whatwg.org/multipage/document-sequences.html#child-navigable" id="elements-3:child-navigable">
    Child navigable
    </a>
</lol-ignore-this>



## Categories- flow
- phrasing
- embedded
- interactive
- palpable
]]
---@class HTMLElement.iframe : XML.Node
---@field src any [Documentation](https://html.spec.whatwg.org/multipage/iframe-embed-object.html#attr-iframe-src)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.iframe=export.xml.iframe

--[[# <code>meter</code>
## Description
Gauge


## Categories- flow
- phrasing
- labelable
- palpable
]]
---@class HTMLElement.meter : XML.Node
---@field value any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-meter-value)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.meter=export.xml.meter

--[[# <code>wbr</code>
## Description
Line breaking opportunity


]]
---@class HTMLElement.wbr : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.wbr=export.xml.wbr

--[[# <code>area</code>
## Description
Hyperlink or dead area on an image map


]]
---@class HTMLElement.area : XML.Node
---@field alt any [Documentation](https://html.spec.whatwg.org/multipage/image-maps.html#attr-area-alt)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.area=export.xml.area

--[[# <code>video</code>
## Description
Video player


## Categories- flow
- phrasing
- embedded
- interactive
- palpable
]]
---@class HTMLElement.video : XML.Node
---@field src any [Documentation](https://html.spec.whatwg.org/multipage/media.html#attr-media-src)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.video=export.xml.video

--[[# <code>var</code>
## Description
Variable


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.var : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.var=export.xml.var

--[[# <code>ul</code>
## Description
List


## Categories- flow
- palpable
]]
---@class HTMLElement.ul : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.ul=export.xml.ul

--[[# <code>u</code>
## Description
Unarticulated annotation


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.u : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.u=export.xml.u

--[[# <code>noscript</code>
## Description
Fallback content for script


## Categories- metadata
- flow
- phrasing
]]
---@class HTMLElement.noscript : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.noscript=export.xml.noscript

--[[# <code>track</code>
## Description
Timed text track


]]
---@class HTMLElement.track : XML.Node
---@field default any [Documentation](https://html.spec.whatwg.org/multipage/media.html#attr-track-default)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.track=export.xml.track

--[[# <code>source</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Image source for</lol-ignore-this>
  <lol-ignore-this>or
                media source for</lol-ignore-this>
  <lol-ignore-this>or</lol-ignore-this>
    <code>
      <code id="elements-3:the-img-element-3">
          <a href="https://html.spec.whatwg.org/multipage/embedded-content.html#the-img-element">
          img
          </a>
      </code>
      <code id="elements-3:the-video-element">
          <a href="https://html.spec.whatwg.org/multipage/media.html#the-video-element">
          video
          </a>
      </code>
      <code id="elements-3:the-audio-element-2">
          <a href="https://html.spec.whatwg.org/multipage/media.html#the-audio-element">
          audio
          </a>
      </code>
    </code>
</lol-ignore-this>



]]
---@class HTMLElement.source : XML.Node
---@field type any [Documentation](https://html.spec.whatwg.org/multipage/embedded-content.html#attr-source-type)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.source=export.xml.source

--[[# <code>dialog</code>
## Description
Dialog box or window


]]
---@class HTMLElement.dialog : XML.Node
export.xml.dialog=export.xml.dialog

--[[# <code>title</code>
## Description
Document title


]]
---@class HTMLElement.title : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.title=export.xml.title

--[[# <code>time</code>
## Description
Machine-readable equivalent of date- or time-related data


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.time : XML.Node
export.xml.time=export.xml.time

--[[# <code>details</code>
## Description
Disclosure control for hiding details


## Categories- flow
- interactive
- palpable
]]
---@class HTMLElement.details : XML.Node
---@field name any [Documentation](https://html.spec.whatwg.org/multipage/interactive-elements.html#attr-details-name)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.details=export.xml.details

--[[# <code>nav</code>
## Description
Section with navigational links


## Categories- flow
- sectioning
- palpable
]]
---@class HTMLElement.nav : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.nav=export.xml.nav

--[[# <code>i</code>
## Description
Alternate voice


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.i : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.i=export.xml.i

--[[# <code>search</code>
## Description
Container for search controls


]]
---@class HTMLElement.search : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.search=export.xml.search

--[[# <code>fieldset</code>
## Description
Group of form controls


## Categories- flow
- listed
- form-associated
- palpable
]]
---@class HTMLElement.fieldset : XML.Node
---@field disabled any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-fieldset-disabled)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.fieldset=export.xml.fieldset

--[[# <code>tr</code>
## Description
Table row


]]
---@class HTMLElement.tr : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.tr=export.xml.tr

--[[# <code>progress</code>
## Description
Progress bar


## Categories- flow
- phrasing
- labelable
- palpable
]]
---@class HTMLElement.progress : XML.Node
---@field value any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-progress-value)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.progress=export.xml.progress

--[[# <code>sub</code>
## Description
Subscript


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.sub : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.sub=export.xml.sub

--[[# <code>figcaption</code>
## Description
Caption for


]]
---@class HTMLElement.figcaption : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.figcaption=export.xml.figcaption

--[[# <code>col</code>
## Description
Table column


]]
---@class HTMLElement.col : XML.Node
export.xml.col=export.xml.col

--[[# <code>table</code>
## Description
Table


]]
---@class HTMLElement.table : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.table=export.xml.table

--[[# <code>object</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Image,</lol-ignore-this>
  <lol-ignore-this>, or</lol-ignore-this>
    <a>
      <a href="https://html.spec.whatwg.org/multipage/document-sequences.html#child-navigable" id="elements-3:child-navigable-2">
      child
                    navigable
      </a>
      <a href="https://html.spec.whatwg.org/multipage/infrastructure.html#plugin" id="elements-3:plugin-2">
      plugin
      </a>
    </a>
</lol-ignore-this>



## Categories- flow
- phrasing
- embedded
- interactive
- listed
- form-associated
- palpable
]]
---@class HTMLElement.object : XML.Node
---@field data any [Documentation](https://html.spec.whatwg.org/multipage/iframe-embed-object.html#attr-object-data)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.object=export.xml.object

--[[# <code>sup</code>
## Description
Superscript


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.sup : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.sup=export.xml.sup

--[[# <code>summary</code>
## Description
Caption for


]]
---@class HTMLElement.summary : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.summary=export.xml.summary

--[[# <code>head</code>
## Description
Container for document metadata


]]
---@class HTMLElement.head : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.head=export.xml.head

--[[# <code>form</code>
## Description
User-submittable form


]]
---@class HTMLElement.form : XML.Node
---@field accept-charset any [Documentation](https://html.spec.whatwg.org/multipage/forms.html#attr-form-accept-charset)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.form=export.xml.form

--[[# <code>aside</code>
## Description
Sidebar for tangentially related content


## Categories- flow
- sectioning
- palpable
]]
---@class HTMLElement.aside : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.aside=export.xml.aside

--[[# <code>hr</code>
## Description
Thematic break


]]
---@class HTMLElement.hr : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.hr=export.xml.hr

--[[# <code>embed</code>
## Description
<lol-ignore-this>
    <a href="https://html.spec.whatwg.org/multipage/infrastructure.html#plugin" id="elements-3:plugin">
    Plugin
    </a>
</lol-ignore-this>



## Categories- flow
- phrasing
- embedded
- interactive
- palpable
]]
---@class HTMLElement.embed : XML.Node
---@field src any [Documentation](https://html.spec.whatwg.org/multipage/iframe-embed-object.html#attr-embed-src)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.embed=export.xml.embed

--[[# <code>textarea</code>
## Description
Multiline text controls


## Categories- flow
- phrasing
- interactive
- listed
- labelable
- submittable
- resettable
- form-associated
- palpable
]]
---@class HTMLElement.textarea : XML.Node
---@field autocomplete any [Documentation](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-autocomplete)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.textarea=export.xml.textarea

--[[# <code>small</code>
## Description
Side comment


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.small : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.small=export.xml.small

--[[# <code>b</code>
## Description
Keywords


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.b : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.b=export.xml.b

--[[# <code>a</code>
## Description
Hyperlink


## Categories- flow
- phrasing
- interactive
- palpable
]]
---@class HTMLElement.a : XML.Node
---@field href any [Documentation](https://html.spec.whatwg.org/multipage/links.html#attr-hyperlink-href)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.a=export.xml.a

--[[# <code>br</code>
## Description
Line break, e.g. in poem or postal address


]]
---@class HTMLElement.br : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.br=export.xml.br

--[[# <code>option</code>
## Description
Option in a list box or combo box control


]]
---@class HTMLElement.option : XML.Node
---@field disabled any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-option-disabled)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.option=export.xml.option

--[[# <code>pre</code>
## Description
Block of preformatted text


]]
---@class HTMLElement.pre : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.pre=export.xml.pre

--[[# <code>samp</code>
## Description
Computer output


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.samp : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.samp=export.xml.samp

--[[# <code>mark</code>
## Description
Highlight


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.mark : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.mark=export.xml.mark

--[[# <code>section</code>
## Description
Generic document or application section


## Categories- flow
- sectioning
- palpable
]]
---@class HTMLElement.section : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.section=export.xml.section

--[[# <code>tfoot</code>
## Description
Group of footer rows in a table


]]
---@class HTMLElement.tfoot : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.tfoot=export.xml.tfoot

--[[# <code>body</code>
## Description
Document body


]]
---@class HTMLElement.body : XML.Node
---@field onafterprint any [Documentation](https://html.spec.whatwg.org/multipage/webappapis.html#handler-window-onafterprint)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.body=export.xml.body

--[[# <code>output</code>
## Description
Calculated output value


## Categories- flow
- phrasing
- listed
- labelable
- resettable
- form-associated
- palpable
]]
---@class HTMLElement.output : XML.Node
---@field for any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-output-for)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.output=export.xml.output

--[[# <code>script</code>
## Description
Embedded script


## Categories- metadata
- flow
- phrasing
- script-supporting
]]
---@class HTMLElement.script : XML.Node
---@field src any [Documentation](https://html.spec.whatwg.org/multipage/scripting.html#attr-script-src)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.script=export.xml.script

--[[# <code>cite</code>
## Description
Title of a work


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.cite : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.cite=export.xml.cite

--[[# <code>slot</code>
## Description
Shadow tree slot


]]
---@class HTMLElement.slot : XML.Node
export.xml.slot=export.xml.slot

--[[# <code>s</code>
## Description
Inaccurate text


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.s : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.s=export.xml.s

--[[# <code>article</code>
## Description
Self-contained syndicatable or reusable composition


## Categories- flow
- sectioning
- palpable
]]
---@class HTMLElement.article : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.article=export.xml.article

--[[# <code>audio</code>
## Description
Audio player


## Categories- flow
- phrasing
- embedded
- interactive
- palpable
]]
---@class HTMLElement.audio : XML.Node
---@field src any [Documentation](https://html.spec.whatwg.org/multipage/media.html#attr-media-src)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.audio=export.xml.audio

--[[# <code>input</code>
## Description
Form control


## Categories- flow
- phrasing
- interactive
- listed
- labelable
- submittable
- resettable
- form-associated
- palpable
]]
---@class HTMLElement.input : XML.Node
---@field accept any [Documentation](https://html.spec.whatwg.org/multipage/input.html#attr-input-accept)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.input=export.xml.input

--[[# <code>p</code>
## Description
Paragraph


]]
---@class HTMLElement.p : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.p=export.xml.p

--[[# <code>bdi</code>
## Description
Text directionality isolation


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.bdi : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.bdi=export.xml.bdi

--[[# <code>bdo</code>
## Description
Text directionality formatting


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.bdo : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.bdo=export.xml.bdo

--[[# <code>rt</code>
## Description
Ruby annotation text


]]
---@class HTMLElement.rt : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.rt=export.xml.rt

--[[# <code>map</code>
## Description
<lol-ignore-this>
    <a href="https://html.spec.whatwg.org/multipage/image-maps.html#image-map" id="elements-3:image-map">
    Image map
    </a>
</lol-ignore-this>



## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.map : XML.Node
export.xml.map=export.xml.map

--[[# <code>main</code>
## Description
Container for the dominant contents of the document


]]
---@class HTMLElement.main : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.main=export.xml.main

--[[# <code>figure</code>
## Description
Figure with optional caption


]]
---@class HTMLElement.figure : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.figure=export.xml.figure

--[[# <code>colgroup</code>
## Description
Group of columns in a table


]]
---@class HTMLElement.colgroup : XML.Node
export.xml.colgroup=export.xml.colgroup

--[[# <code>q</code>
## Description
Quotation


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.q : XML.Node
export.xml.q=export.xml.q

--[[# <code>button</code>
## Description
Button control


## Categories- flow
- phrasing
- interactive
- listed
- labelable
- submittable
- form-associated
- palpable
]]
---@class HTMLElement.button : XML.Node
---@field disabled any [Documentation](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.button=export.xml.button

--[[# <code>picture</code>
## Description
Image


## Categories- flow
- phrasing
- embedded
- palpable
]]
---@class HTMLElement.picture : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.picture=export.xml.picture

--[[# <code>select</code>
## Description
List box control


## Categories- flow
- phrasing
- interactive
- listed
- labelable
- submittable
- resettable
- form-associated
- palpable
]]
---@class HTMLElement.select : XML.Node
---@field autocomplete any [Documentation](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-autocomplete)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.select=export.xml.select

--[[# <code>code</code>
## Description
Computer code


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.code : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.code=export.xml.code

--[[# <code>caption</code>
## Description
Table caption


]]
---@class HTMLElement.caption : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.caption=export.xml.caption

--[[# <code>html</code>
## Description
Root element


]]
---@class HTMLElement.html : XML.Node
export.xml.html=export.xml.html

--[[# <code>link</code>
## Description
Link metadata


## Categories- metadata
- flow
- phrasing
]]
---@class HTMLElement.link : XML.Node
---@field href any [Documentation](https://html.spec.whatwg.org/multipage/semantics.html#attr-link-href)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.link=export.xml.link

--[[# <code>em</code>
## Description
Stress emphasis


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.em : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.em=export.xml.em

--[[# <code>li</code>
## Description
List item


]]
---@class HTMLElement.li : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.li=export.xml.li

--[[# <code>ruby</code>
## Description
Ruby annotation(s)


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.ruby : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.ruby=export.xml.ruby

--[[# <code>data</code>
## Description
Machine-readable equivalent


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.data : XML.Node
export.xml.data=export.xml.data

--[[# <code>thead</code>
## Description
Group of heading rows in a table


]]
---@class HTMLElement.thead : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.thead=export.xml.thead

--[[# <code>footer</code>
## Description
Footer for a page or section


]]
---@class HTMLElement.footer : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.footer=export.xml.footer

--[[# <code>th</code>
## Description
Table header cell


]]
---@class HTMLElement.th : XML.Node
---@field colspan any [Documentation](https://html.spec.whatwg.org/multipage/tables.html#attr-tdth-colspan)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.th=export.xml.th

--[[# <code>label</code>
## Description
Caption for a form control


## Categories- flow
- phrasing
- interactive
- palpable
]]
---@class HTMLElement.label : XML.Node
export.xml.label=export.xml.label

--[[# <code>base</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Base URL and default target</lol-ignore-this>
  <lol-ignore-this>for</lol-ignore-this>
  <lol-ignore-this>and</lol-ignore-this>
    <a>
      <a href="https://html.spec.whatwg.org/multipage/document-sequences.html#navigable" id="elements-3:navigable">
      navigable
      </a>
      <a href="https://html.spec.whatwg.org/multipage/links.html#attr-hyperlink-target" id="elements-3:attr-hyperlink-target-3">
      hyperlinks
      </a>
      <a href="https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fs-target" id="elements-3:attr-fs-target">
      forms
      </a>
    </a>
</lol-ignore-this>



]]
---@class HTMLElement.base : XML.Node
---@field href any [Documentation](https://html.spec.whatwg.org/multipage/semantics.html#attr-base-href)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.base=export.xml.base

--[[# <code>canvas</code>
## Description
Scriptable bitmap canvas


## Categories- flow
- phrasing
- embedded
- palpable
]]
---@class HTMLElement.canvas : XML.Node
---@field width any [Documentation](https://html.spec.whatwg.org/multipage/canvas.html#attr-canvas-width)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.canvas=export.xml.canvas

--[[# <code>kbd</code>
## Description
User input


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.kbd : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.kbd=export.xml.kbd

--[[# <code>ins</code>
## Description
An addition to the document


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.ins : XML.Node
---@field cite any [Documentation](https://html.spec.whatwg.org/multipage/edits.html#attr-mod-cite)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.ins=export.xml.ins

--[[# <code>meta</code>
## Description
Text metadata


## Categories- metadata
- flow
- phrasing
]]
---@class HTMLElement.meta : XML.Node
---@field name any [Documentation](https://html.spec.whatwg.org/multipage/semantics.html#attr-meta-name)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.meta=export.xml.meta

--[[# <code>address</code>
## Description
<lol-ignore-this>
  <lol-ignore-this>Contact information for a page or</lol-ignore-this>
  <lol-ignore-this>element</lol-ignore-this>
    <code id="elements-3:the-article-element">
        <a href="https://html.spec.whatwg.org/multipage/sections.html#the-article-element">
        article
        </a>
    </code>
</lol-ignore-this>



]]
---@class HTMLElement.address : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.address=export.xml.address

--[[# <code>rp</code>
## Description
Parenthesis for ruby annotation text


]]
---@class HTMLElement.rp : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.rp=export.xml.rp

--[[# <code>legend</code>
## Description
Caption for


]]
---@class HTMLElement.legend : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.legend=export.xml.legend

--[[# <code>strong</code>
## Description
Importance


## Categories- flow
- phrasing
- palpable
]]
---@class HTMLElement.strong : XML.Node
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.strong=export.xml.strong

--[[# <code>optgroup</code>
## Description
Group of options in a list box


]]
---@class HTMLElement.optgroup : XML.Node
---@field disabled any [Documentation](https://html.spec.whatwg.org/multipage/form-elements.html#attr-optgroup-disabled)
---@field globals any [Documentation](https://html.spec.whatwg.org/multipage/dom.html#global-attributes)
export.xml.optgroup=export.xml.optgroup

---@generic T
---@param func fun(...: T): XML.Node
---@return fun(...: T): XML.Node
function export.declare_generator(func) return setfenv(func, export.xml) end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@generic TKey, TValue
---@param tbl { [TKey] : TValue },
---@param order TKey[]?
---@return XML.Node
function export.html_table(tbl, order)
    local xml = export.xml
    return xml.table {
        function ()
            local function getval(v)
                local tname = typename(v)
                if tname == "XML.Node" then return v end

                if typename(v) ~= "table" or (getmetatable(v) or {}).__tostring then
                    return tostring(v)
                end

                return export.html_table(v)
            end

            if order ~= nil then
                for i, v in ipairs(order) do
                    local val = tbl[v]
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(v)),
                            xml.td(getval(val))
                        }
                    )
                end
            else
                for i, v in ipairs(tbl) do
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(i)),
                            xml.td(getval(v)),
                        }
                    )

                    tbl[i] = nil
                end

                for k, v in pairs(tbl) do
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(k)),
                            xml.td(getval(v)),
                        }
                    )
                end
            end
        end
    }
end

---@alias OptionalStringCollection string | string[]
---@param css { [OptionalStringCollection] : { [OptionalStringCollection] : (OptionalStringCollection) } }
---@return XML.Node
function export.style(css)
    local css_str = ""
    for selector, properties in pairs(css) do
        if type(selector) == "table" then selector = table.concat(selector, ", ") end

        css_str = css_str..selector.." {\n"
        for property, value in pairs(properties) do
            if type(value) == "table" then value = table.concat(value, ", ") end

            css_str = css_str.."    "..property..": "..value..";\n"
        end
        css_str = css_str.."}\n"
    end

    return export.xml.style(css_str)
end


return export
