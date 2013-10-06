debug =
  log: (msg) -> console.log msg

class Parse

  constructor: (files) ->
    collection = []
    files = files.forEach (file) ->
      debug.log "Parsing #{file.name}"
      # remove useless quotes
      text = file.text.replace new RegExp('"', 'g'), ''
      # split with newline
      logs = text.split '\n'
      # shift table head
      logs.shift()
      debug.log "#{logs.length} logs found."
      collection = collection.concat logs
    len = collection.length
    collection = _.uniq collection
    debug.log "Uniq, remove #{len - collection.length} logs"
    collection = collection.map (elem) ->
      o = {}
      [o.time, o.description, o.category, o.start, o.end, o.remark] = elem.split(',')
      o.time = parseFloat o.time
      o
    @logs = collection
    @analysis()

  analysis: (start = new Date('1970-01-01'), end = new Date()) ->
    # use elem.end to filter
    logs = @logs.filter (elem) ->
      time = new Date elem.end
      if start.getTime() < time.getTime() and end.getTime() > time.getTime()
        true
      else
        false
    tree = {}
    logs.forEach (elem) ->
      {description, category, time} = elem
      tree[category] = {sum: 0, children: {}} unless tree[category]?
      tree[category].sum += time
      unless tree[category].children[description]?
        tree[category].children[description] = {sum: 0}
      tree[category].children[description].sum += time
    json = JSON.stringify tree, null, 2
    document.getElementById('data').innerHTML = json

document.getElementById('files').addEventListener 'change', (e) ->
  files = []
  results = []
  files.push file for file in e.target.files
  pending = files.length
  files.map (file) ->
    reader = new FileReader()
    reader.onload = (e) ->
      results.push {name: file.name, text: e.target.result}
      pending--
      if pending is 0
        window.parse = new Parse results
    reader.readAsText file
