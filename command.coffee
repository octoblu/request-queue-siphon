commander = require 'commander'
redis     = require 'redis'
RedisNS   = require '@octoblu/redis-ns'

class Command
  constructor: ->

  parseOptions: =>
    commander
      .option '-i, --input-ns <namespace>', 'Namespace from which to siphon (env: SIPHON_INPUT_NS)'
      .option '-o, --output-ns <namespace>', 'Namespace to siphon in to (env: SIPHON_OUTPUT_NS)'
      .option '-r, --rate <rate>', 'Rate at which to siphon work, defaults to x'
      .parse process.argv

    @inputNS = commander.inputQueue ? process.env.SIPHON_INPUT_NS
    @outputNS = commander.outputQueue ? process.env.SIPHON_OUTPUT_NS

    unless @inputNS && @outputNS
      commander.outputHelp()
      process.exit 1

  run: =>
    @parseOptions()

    inClient     = new RedisNS @inputNS, redis.createClient(@redisUri)
    inJobManager = new JobManager client: inClient

    outClient     = new RedisNS @outputNS, redis.createClient(@redisUri)
    outJobManager = new JobManager client: outClient

    siphon = new Siphon {inJobManager, outJobManager}
    siphon.do()

command = new Command
command.run()