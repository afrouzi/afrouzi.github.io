# Local-dev only: adjust MIME types when running `jekyll serve`.
# Do not require 'webrick' here; GitHub Actions builds do not ship it.
if defined?(WEBrick)
	mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
	mime_types.store('mjs', 'application/javascript')
	mime_types.store('wasm', 'application/wasm')
end
