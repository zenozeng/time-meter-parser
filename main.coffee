debug =
  log: (msg) -> console.log msg

class Parse

  constructor: (files) ->
    if files?
      localStorage.setItem('time-meter-cache', JSON.stringify(files))
    else
      files = localStorage.getItem 'time-meter-cache'
      if files?
        files = JSON.parse files
      else
        return
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
    start = document.getElementById('start').value
    end = document.getElementById('end').value
    @analysis new Date(start), new Date(end)

  analysis: (start = new Date('1970-01-01'), end = new Date()) ->
    console.log {start: start, end: end}
    # use elem.end to filter
    logs = @logs.filter (elem) ->
      time = new Date elem.end
      if start.getTime() < time.getTime() and end.getTime() > time.getTime()
        true
      else
        false
    min = null
    max = null
    starts = logs.map (log) -> new Date(log.start).getTime()
    ends = logs.map (log) -> new Date(log.end).getTime()
    min = Math.min.apply this, starts
    max = Math.max.apply this, ends
    min = new Date min
    max = new Date max
    console.log {min: min, max: max}
    tree = {}
    logs.forEach (elem) ->
      {description, category, time} = elem
      path = category.split('，')
      path.push description
      pathArr = []
      for i in [1..path.length]
        item =
          path: path.slice(0, i).join('-')
          level: i
          name: path[i-1]
        pathArr.push item
      for path in pathArr
        if tree[path.path]?
          tree[path.path].time += time
        else
          tree[path.path] =
            name: path.name
            level: path.level
            time: time
    items = []
    for key, value of tree
      item =
        key: key
        name: value.name
        level: value.level
        time: Math.round(value.time*100) / 100
      items.push item
    items = items.sort (a, b) ->
      a.key.localeCompare(b.key)
    html = ''
    for item in items
      {name, level, time} = item
      html += "<div class='item level-#{level}' style='padding-left: #{level*4*12}px'>
        <span class='name'>#{name}:</span> #{time}
      </div>"
    document.getElementById('data').innerHTML = html

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

fn =-> new Parse()
setTimeout fn, 1000
