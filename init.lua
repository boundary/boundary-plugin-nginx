-- Copyright 2015 Boundary, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework')
local json = require('json')
local url = require('url')
local Plugin  = framework.Plugin
local WebRequestDataSource = framework.WebRequestDataSource
local Accumulator = framework.Accumulator
local auth = framework.util.auth
local gsplit = framework.string.gsplit
local isHttpSuccess = framework.util.isHttpSuccess

local params = framework.params

local options = url.parse(params.url)
options.auth = auth(params.username, params.password) 
options.wait_for_end = true
local ds = WebRequestDataSource:new(options)
local acc = Accumulator:new()
local plugin = Plugin:new(params, ds)

local function parseText(body)
    local stats = {}
    for v in gsplit(body, "\n") do
      if v:find("Active connections:", 1, true) then
        local metric, connections = v:match('(%w+):%s*(%d+)')
        stats[metric:lower()] = tonumber(connections)

      elseif v:match("%s*(%d+)%s+(%d+)%s+(%d+)%s*$") then
        local accepts, handled, requests = v:match("%s*(%d+)%s+(%d+)%s+(%d+)%s*$")
        stats.accepts    = tonumber(accepts)
        stats.handled    = tonumber(handled)
        stats.requests   = tonumber(requests)
        stats.not_handled = stats.accepts - stats.handled

      elseif v:match("(%w+):%s*(%d+)") then
        for metric, value in v:gmatch("(%w+):%s*(%d+)") do
          stats[metric:lower()] = tonumber(value)
        end
      end
    end
    return stats
end

local function parseJson(body)
    local parsed
    pcall(function () parsed = json.parse(body) end)
    return parsed 
end

function plugin:onParseValues(data, extra)
  local metrics = {}

  if not isHttpSuccess(extra.status_code) then
    self:emitEvent('error', ('HTTP Request returned %d instead of OK. Please check NGINX Free stats endpoint.'):format(extra.status_code))
    return
  end
  local stats = parseJson(data)
  if stats then
    self:emitEvent('info', 'You should install NGINX+ Plugin for non-free version of NGINX.')
  else 
    stats = parseText(data)
    local handled = acc:accumulate('handled', stats.handled)
    local requests = acc:accumulate('requests', stats.requests)
    local reqs_per_connection = (handled > 0) and requests / handled or 0

    metrics['NGINX_ACTIVE_CONNECTIONS'] = stats.connections
    metrics['NGINX_READING'] = stats.reading
    metrics['NGINX_WRITING'] = stats.writing
    metrics['NGINX_WAITING'] = stats.waiting
    metrics['NGINX_HANDLED'] = handled
    metrics['NGINX_NOT_HANDLED'] = stats.not_handled
    metrics['NGINX_REQUESTS'] = requests
    metrics['NGINX_REQUESTS_PER_CONNECTION'] = reqs_per_connection
  end

  return metrics 
end

plugin:run()

