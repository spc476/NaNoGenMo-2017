-- ***************************************************************
--
-- Copyright 2017 by Sean Conner.  All Rights Reserved.
--
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the
-- Free Software Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
-- Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Comments, questions and criticisms can be sent to: sean@conman.org
--
-- ********************************************************************
-- luacheck: ignore 611

local entity = require "entity"
local lpeg = require "lpeg"

local Cf = lpeg.Cf
local Cg = lpeg.Cg
local Cs = lpeg.Cs
local Ct = lpeg.Ct
local C  = lpeg.C
local P  = lpeg.P
local R  = lpeg.R
local S  = lpeg.S

local dict do
  local char      = (P"&" / "")
                  * (R("AZ","az")^1 / entity)
                  * (P";" / "")
                  + S[["*`]] / ""
                  + P(1)
  local cleanterm = Cs(char^1)

  local dchar     = (P"&" / "")
                  * (R("AZ","az")^1 / entity)
                  * (P";" / "")
                  + (P"<" * (P(1) - P">")^0 * P">") / ""
                  + P(1)
  local cleandef  = Cs(dchar^1)

  local HW   = P"<hw>"
  local MHW  = P"<mhw>"
  local DEF  = P"<def>"
  local SHW  = P"</hw>"
  local SMHW = P"</mhw>"
  local SDEF = P"</def>"

  local noHW     = (P(1) - (HW + MHW))^0
  local noSHW    = (P(1) - SHW)^0
  local noSDEF   = (P(1) - SDEF)^0
  local noHWDEF  = (P(1) - (HW + DEF))^0
  local noHWSMHW = (P(1) - (HW + SMHW))^0

  local hw  = HW            * C(noSHW)  * SHW
  local mhw = (HW * #R"!~") * C(noSHW)  * SHW
  local def = DEF           * C(noSDEF) * SDEF

  local word   = Cg(hw * Ct((noHWDEF * def)^0))
  local mword  = MHW * noHW
               * Cg(
                       Ct((mhw * noHWSMHW)^1) * SMHW
                     * Ct((noHWDEF * def)^0)
                   )
                   
  local doc = Cf(
            Ct"" * (noHW * (mword + word))^1,
            function(acc,term,termdef)
              local function addword(w,defs)
                if not acc[w] then
                  acc[w] = {}
                end
                
                for _,v in ipairs(defs) do
                  table.insert(acc[w],v)
                end
              end
              
              local defs = {}
              for _,v in ipairs(termdef) do
                table.insert(defs,cleandef:match(v))
              end
              
              if type(term) == 'table' then
                for _,w in ipairs(term) do
                  addword(cleanterm:match(w),defs)
                end
              else
                addword(cleanterm:match(term),defs)
              end
              return acc
            end
         )
         
  local raw do
    raw = ""
    for i = 1 , 25 do
      local n = string.format("../refs/gcide_xml-0.51/xml_files/gcide_%s.xml",string.char(i + 97))
      local f,e = io.open(n,"r")
      if not f then
        print(f,e)
        os.exit(1)
      end
      raw = raw .. f:read("*a")
      f:close()
    end
  end

  dict = doc:match(raw)
end

-- ************************************************************************

do
  local word = R("''","--","AZ","az")^1
end


do
  local list = {}
  for name in pairs(dict) do
    table.insert(list,name)
  end
  
  table.sort(list)
  
  for _,term in ipairs(list) do
    print(term)
    for _,definition in ipairs(dict[term]) do
      print("",definition)
    end
  end
end
