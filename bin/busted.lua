if ngx ~= nil then
  ngx.exit = function() end
end

-- Busted command-line runner
require 'busted.runner' ({ standalone = false })
