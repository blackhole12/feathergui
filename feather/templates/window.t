local core = require 'feather.core'
local F = require 'feather.shared'
local override = require 'feather.util'.override
local messages = require 'feather.messages'
local Msg = require 'feather.message'
local Virtual = require 'feather.virtual'
local C = terralib.includecstring [[#include <stdio.h>]]

return core.raw_template {
  core.body
} (
  function(self, context, type_environment)
    if context.window then
      error "NYI: instantiating a window inside another window"
    end
    local rtree_type = context.rtree
    local context_ = override(context, {window = &opaque, transform = &core.transform})
    local body_fns, body_type = type_environment[core.body](context_, type_environment)
    
    local function make_context(self, ui)
      return {
        rtree = `self.rtree,
        rtree_node = `self.rtree.root,
        allocator = `self.rtree.allocator,
        backend = `ui.backend,
        window = `self.window,
        transform = `core.transform.identity(),
      }
    end

    local function override_context(self, context)
      return override(context, {
        rtree = `self.rtree,
        rtree_node = `self.rtree.root,
        allocator = `self.rtree.allocator,
        window = `self.window,
        transform = `core.transform.identity(),
      })
    end

    local fn_table = {
      enter = function(self, context, environment)
        return quote
          self.super.vftable = [self:gettype()].virtual_initializer
            var pos = F.Vec{array(0f, 0f)}
          var size = F.Vec{array(800f, 600f)}
          var transform = core.transform.identity()
          var zero = [F.Vec3D] {array(0.0f, 0.0f, 0.0f)}
          var zindex = [F.Veci] {array(0, 0)}
          self.rtree:init()
          self.rtree:create(nil, &zero, &zero, &zero, &zindex)
          self.window = [context.backend]:CreateWindow(&self.super, nil, &pos, &size, "feather window", messages.Window.RESIZABLE, nil)
          ;[body_fns.enter(`self.body, override_context(self, context), environment)]
        end
      end,
      update = function(self, context, environment)
        return quote
            var transform = core.transform.identity()
            [body_fns.enter(`self.body, override_context(self, context), environment)]
          end
      end,
      exit = function(self, context)
        return quote
          if self.window ~= nil then
            var transform = core.transform.identity()
            [body_fns.exit(`self.body, override_context(self, context))]
            [context.backend]:DestroyWindow(self.window)
            self.window = nil
            self.rtree:destruct()
            end
          end
      end,
      render = function(self, context)
        return quote
            var transform = core.transform.identity()
            [body_fns.render(`self.body, override_context(self, context))]
          end
      end
    }

    local struct window_node(Virtual.extends(Msg.Receiver)) {
      window: &opaque
      body: body_type
      rtree: rtree_type
    }

    terra window_node:Draw(ui : &opaque) : F.Err
      [body_fns.render(`self.body, make_context(self, `[&context.ui](ui)))]
      return 0
    end
    
    terra window_node:Action(ui : &opaque, subkind : int) : F.Err
      switch subkind do
        case 1 then
          [fn_table.exit(`self, make_context(self, `[&context.ui](ui)))]
        end
      end
    end

    return fn_table, window_node
  end
  )
