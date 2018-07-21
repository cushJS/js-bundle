NameResolver = require './NameResolver'
MagicString = require '@cush/magic-string'
sorcery = require '@cush/sorcery'
Bundle = require 'cush/lib/Bundle'
uhoh = require 'cush/utils/uhoh'
cush = require 'cush'
log = require 'lodge'
fs = require 'saxon/sync'

polyfills =
  require: fs.read __dirname + '/../polyfills/require.js'

class JSBundle extends Bundle
  @id: 'js'
  @exts: ['.js']
  @plugins: ['sucrase', 'buble', 'uglify-js']

  _wrapSourceMapURL: (url) ->
    '//# sourceMappingURL=' + url

  _concat: (assets, packages) ->
    result = new MagicString.Bundle

    # polyfills
    result.prepend polyfills.require + '\n'

    # asset lookup by filename
    files = {}

    resolveName = NameResolver this, packages
    assets.forEach (asset) =>
      if asset.ext isnt '.js'
        uhoh 'Unsupported asset type: ' + asset.path(), 'BAD_ASSET'

      code = new MagicString asset.content
      filename = @relative asset.path()
      files[filename] = asset

      # swap out any `require` calls
      asset.deps?.forEach (dep) ->
        if !dep.asset then log.warn 'Missing asset:', dep
        else code.overwrite dep.start, dep.end, resolveName(dep.asset)

      # wrap assets with a `__d` call
      code.trim()
      code.indent '  '
      code.prepend "/* #{filename} */\n" if @dev
      code.prependRight 0, """
        __d(#{resolveName asset}, function(module, exports) {\n
      """
      code.append '\n});\n'

      # add to the bundle
      result.addSource {filename, content: code}

    # require the main module
    result.append "\nrequire(#{resolveName @main});"

    # create the bundle string
    result =
      content: result.toString()
      map: result.generateMap
        includeContent: false

    # trace the mappings to their original sources
    result.map = sorcery result,
      getMap: (filename) -> files[filename].map or false
      includeContent: false

    return result

module.exports = JSBundle
