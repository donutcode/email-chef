exports.VERSION = '0.0.1'

exports.compile = (code, options={}) ->
  try
    # options example: {filename:'sample.html', wrap:false}
    # for now, this just returns the input code
    code
  catch err
    err.message = "In #{options.filename}, #{err.message}" if options.filename
    throw err
    