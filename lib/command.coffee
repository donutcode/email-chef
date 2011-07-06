# The `chef` utility. Handles command-line compilation for email-chef

# External dependencies.
fs              = require 'fs'
path            = require 'path'
helpers         = require './helpers'
optparse        = require './optparse'
EmailChef       = require './email-chef'
{spawn, exec}   = require 'child_process'
{EventEmitter}  = require 'events'

# Allow EmailChef to emit Node.js events
helpers.extend EmailChef, new EventEmitter

printLine = (line) -> process.stdout.write line + '\n'
printWarn = (line) -> process.binding('stdio').writeError line + '\n'

# The help banner that is printed when `chef` is called without arguments
BANNER = '''
  Usage: chef [options] path/to/email.html
  '''

# The list of all the valid option flags that `chef` knows how to handle
SWITCHES = [
  ['-o', '--output [DIR]',    'set the directory for compiled html']
  ['-w', '--watch',           'watch scripts for changes, and recompile']
  ['-r', '--wrap',            'compile with an html element wrapper']
  ['-v', '--version',         'display email-chef version']
  ['-h', '--help',            'display this help message']
]

# Top-level objects shared by all the functions
opts         = {}
sources      = []
optionParser = null

# Run `chef` by parsing passed options and determining what action to take.
# Flags passed after `--` will be passed verbatim to your script as arguments 
# in `process.argv`
exports.run = ->
  parseOptions()
  return usage()                         if opts.help or sources.length < 1
  return version()                       if opts.version
  process.ARGV = process.argv = process.argv.slice(0, 2)
  process.argv[0] = 'chef'
  process.execPath = require.main.filename
  compileScripts()

# Asynchronously read in each EmailChef in a list of source files and
# compile them. If a directory is passed, recursively compile all
# '.html' extension source files in it and all subdirectories.
compileScripts = ->
  for source in sources
    base = path.join(source)
    compile = (source, sourceIndex, topLevel) ->
      path.exists source, (exists) ->
        throw new Error "File not found: #{source}" if topLevel and not exists
        fs.stat source, (err, stats) ->
          throw err if err
          if stats.isDirectory()
            fs.readdir source, (err, files) ->
              for file in files
                compile path.join(source, file), sourceIndex
          else if topLevel or (path.extname(source) is '.html' and !helpers.ends(source, '.baked.html'))
            fs.readFile source, (err, code) ->
              compileScript(source, code.toString(), base)
            watch source, base if opts.watch
    compile source, sources.indexOf(source), true

# Compile a single source script, containing the given code, according to the
# requested options
compileScript = (file, input, base) ->
  o = opts
  options = compileOptions file
  try
    task = {file, input, options}
    EmailChef.emit 'compile', task
    task.output = EmailChef.compile task.input, task.options
    EmailChef.emit 'success', task
    writeHtml task.file, task.output, base
  catch err
    EmailChef.emit 'failure', err, task
    return if EmailChef.listeners('failure').length
    return printLine err.message if o.watch
    printWarn err.stack
    process.exit 1

# Watch a source EmailChef file using `fs.watchFile`, recompiling it every
# time the file is updated
watch = (source, base) ->
  fs.watchFile source, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
    fs.readFile source, (err, code) ->
      throw err if err
      compileScript(source, code.toString(), base)

# Write out a HTML source file with the inlined code. By default, files
# are written out in `cwd` as `.baked.html` files with the same name, but the output
# directory can be customized with `--output`.
writeHtml = (source, html, base) ->
  filename  = path.basename(source, path.extname(source)) + '.baked.html'
  srcDir    = path.dirname source
  baseDir   = if base is '.' then srcDir else srcDir.substring base.length
  dir       = if opts.output then path.join opts.output, baseDir else srcDir
  htmlPath    = path.join dir, filename
  compile   = ->
    html = ' ' if html.length <= 0
    fs.writeFile htmlPath, html, (err) ->
      if err
        printLine err.message
      else if opts.watch
        console.log "#{(new Date).toLocaleTimeString()} - compiled #{source}"
  path.exists dir, (exists) ->
    if exists then compile() else exec "mkdir -p #{dir}", compile

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`
parseOptions = ->
  optionParser  = new optparse.OptionParser SWITCHES, BANNER
  o = opts      = optionParser.parse process.argv.slice 2
  o.wrap        = !!o.wrap
  sources       = opts.arguments

# The compile-time options to pass to the EmailChef compiler
compileOptions = (filename) -> {filename, wrap:opts.wrap}

# Print the `--help` usage message and exit
usage = ->
  printLine (new optparse.OptionParser SWITCHES, BANNER).help()

# Print the `--version` message and exit
version = ->
  printLine "email-chef version #{EmailChef.VERSION}"
