require 'webrick'

# Ensure WEBrick serves modern types correctly in local `jekyll serve`.
mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
mime_types.store('mjs', 'application/javascript')
mime_types.store('wasm', 'application/wasm')
