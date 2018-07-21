
NameResolver = (bundle, packages) ->
  if !bundle.dev
    return (asset) -> String(asset.id)

  packIds = []
  packages.forEach (pack, i) ->
    {name, version} = pack.data
    dupe = packIds[name]
    if dupe isnt undefined
      if dupe isnt true
        packIds[name] = true
        packIds[dupe] = name + '@' + packIds[dupe].data.version
      packIds[i] = name + '@' + version
    else
      packIds[name] = i
      packIds[i] = name
    return

  return (asset) ->
    "'#{packIds[packages.indexOf asset.owner]}/#{asset.name}'"

module.exports = NameResolver
