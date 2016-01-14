_         = require 'lodash'
async     = require 'async'
commander = require 'commander'
redis     = require 'redis'
RedisNS   = require '@octoblu/redis-ns'
Siphon    = require './src/siphon'

class Command
  constructor: ->

  parseOptions: =>
    commander
      .option '-i, --input-ns <namespace>',  'Namespace from which to siphon (env: SIPHON_INPUT_NS)'
      .option '-o, --output-ns <namespace>', 'Namespace to siphon in to (env: SIPHON_OUTPUT_NS)'
      .option '-t, --timeout <seconds>', 'Timeout in seconds when waiting for jobs, default 30s (env: SIPHON_TIMEOUT)'
      .parse process.argv

    @redisUri = process.env.SIPHON_REDIS_URI
    @inputNS = commander.inputNs ? process.env.SIPHON_INPUT_NS
    @outputNS = commander.outputNs ? process.env.SIPHON_OUTPUT_NS
    @timeoutSeconds = parseInt(commander.timeout ? process.env.SIPHON_OUTPUT_NS || 30)

    unless @inputNS && @outputNS
      commander.outputHelp()
      process.exit 1

  run: =>
    @parseOptions()

    inClient  = new RedisNS(@inputNS, redis.createClient @redisUri)
    inClient  = _.bindAll inClient, _.functions(inClient)
    outClient = new RedisNS(@outputNS, redis.createClient @redisUri)
    outClient = _.bindAll outClient, _.functions(outClient)

    siphon = new Siphon {inClient, outClient, @timeoutSeconds}
    async.forever siphon.do, (error) =>
      console.error error.stack
      console.error 'No longer accepting new work'

command = new Command
command.run()
