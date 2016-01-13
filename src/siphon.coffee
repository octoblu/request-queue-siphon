JobManager = require 'meshblu-core-job-manager'

class Siphon
  constructor: ({inClient, outClient, timeoutSeconds}) ->
    @inJobManager  = new JobManager client: inClient, timeoutSeconds: timeoutSeconds
    @outJobManager = new JobManager client: outClient, timeoutSeconds: timeoutSeconds

  do: (callback) =>
    @inJobManager.getRequest ['request'], (error, request) =>
      return callback error if error?
      return callback() unless request?

      @outJobManager.do 'request', 'response', request, (error ,response) =>
        return callback error if error?
        @inJobManager.createResponse 'response', response, callback

module.exports = Siphon
