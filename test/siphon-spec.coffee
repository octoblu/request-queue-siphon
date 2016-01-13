_          = require 'lodash'
async      = require 'async'
redis      = require 'fakeredis'
RedisNS    = require '@octoblu/redis-ns'
uuid       = require 'uuid'
JobManager = require 'meshblu-core-job-manager'
Siphon     = require '../src/siphon'

describe 'Siphon', ->
  beforeEach ->
    @redisId = uuid.v1()
    @timeoutSeconds = 1

  beforeEach ->
    client = new RedisNS('in', redis.createClient @redisId)
    client = _.bindAll client, _.functions(client)
    @inJobManager = new JobManager {client, @timeoutSeconds}

    client = new RedisNS('out', redis.createClient @redisId)
    client = _.bindAll client, _.functions(client)
    @outJobManager = new JobManager {client, @timeoutSeconds}

  beforeEach ->
    inClient  = _.bindAll new RedisNS('in', redis.createClient @redisId)
    outClient = _.bindAll new RedisNS('out', redis.createClient @redisId)

    @sut = new Siphon {inClient, outClient, @timeoutSeconds}

  describe '->do', ->
    describe 'when there is a job in the input queue', ->
      beforeEach (done) ->
        request =
          metadata:
            jobType: 'sendMessage'
          data:
            foo: 'bar'

        @sut.do =>
        @inJobManager.createRequest 'request', request, done

      it 'should take things from here and put them over there', (done) ->
        @outJobManager.getRequest ['request'], (error, request) =>
          return done error if error?
          expect(request).to.exist
          done()

      describe 'when the over there worker responds', ->
        beforeEach (done) ->
          @outJobManager.getRequest ['request'], (error, request) =>
            return done error if error?
            @responseId = request.metadata.responseId

            response =
              metadata:
                responseId: @responseId
              data:
                bar: 'foo'

            @outJobManager.createResponse 'response', response, done

        it 'should put it back into the over here queue', (done) ->
          @inJobManager.getResponse 'response', @responseId, (error, response) =>
            return done error if error?
            expect(response).to.exist
            done()

    describe 'when there is no job in the input queue', ->
      beforeEach (done) ->
        @sut.do done

      it 'should not do anything', (done) ->
        @outJobManager.getRequest ['request'], (error, request) =>
          return done error if error?
          expect(request).not.to.exist
          done()
