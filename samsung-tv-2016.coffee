module.exports = (env) ->
  Function::property = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

  plugin_name = "SamsungTV_2016"
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  WebSocket = require('ws')
  wol = require('wake_on_lan')
  wakeTV = Promise.promisify(wol.wake)
  rq = require('request-promise')
  key_commands = require './samsung-tv-key-commands'
  M = env.matcher
  getTVState = (url) =>
    return rq(url, {json: yes, timeout: 500})
      .then((res) => return Promise.resolve(res))
      .catch(=> return Promise.resolve(null))


  class SamsungTV_2016_Plugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @app_name = new Buffer("#{@config.app_name}").toString('base64')

      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass plugin_name, {
        configDef: deviceConfigDef[plugin_name]
        createCallback: ((config) => new SamsungTV_2016_Switch(config, @))
      }
      @framework.ruleManager.addActionProvider(new SamsungTV_2016_ActionProvider(@framework, @config))

  class SamsungTV_2016_Switch extends env.devices.SwitchActuator
    _state: null



    @property 'mac_address',
      get: -> if @config.mac_address is '' then null else @config.mac_address
      set: (addr) -> @config.mac_address = addr

    constructor: (@config, @plugin, lastState) ->
      assert(@config.ip_address isnt '')
      @id = @config.id
      @name = @config.name
      super()
      {@ip_address, @update_interval, @api_timeout} = @config
      @tv_url = "http://#{@ip_address}:8001/api/v2/"
      @ws_url = "#{@tv_url}channels/samsung.remote.control?name=#{@plugin.app_name}"
      @_state = lastState?.state.value
      @isBusy = no
      @isTurningOff = no
      @updateTimeout = null
      @actions.sendKey =
        description: 'send a key'
        params:
          key:
            type: "string"
            enum: key_commands


    afterRegister: -> setTimeout (=> @updateState()), 2000
    updateState: =>
      @_requestUpdate().then =>
        @updateTimeout = setTimeout((=> @updateState()), @update_interval * 1000)
      return

    _requestUpdate: =>
      return Promise.resolve() if @isBusy
      getTVState(@tv_url).then (res) =>
        if res is null
          @isTurningOff = no
          return no
        else
          @mac_address = res.device.wifiMac unless @mac_address?
          return no if @isTurningOff and @_state is no
          @isTurningOff = no
          return yes
      .then(@_setState)
      .catch (err) =>
        env.logger.error err
        return Promise.resolve()
    changeStateTo: (state) ->
      return Promise.reject("NOT READY") unless (@_state isnt null and @mac_address isnt null)
      return Promise.resolve("BUSY") if @isBusy
      return Promise.resolve() if @_state is state
      @isBusy = yes
      getTVState(@tv_url).then (isAvail) =>
        return @send('KEY_POWER') if isAvail?
        return wakeTV(@mac_address) if state is yes
        return null
      .then =>
        @isBusy = no
        @isTurningOff = !state
        return state
      .then((newState) =>
        @_setState(newState))
      .catch (err) =>
        @isBusy = no
        Promise.reject(err)

    sendKey: (key) ->
      return Promise.resolve() if @isTurningOff or @_state is no or not key?
      @send(key).catch (err) => Promise.reject(err)

    send: (key, timeout=1000) =>
      ws_url = @ws_url
      return new Promise (resolve, reject) =>
        ws = new WebSocket ws_url, (error) -> throw new Error(error)
        ws.on 'error', (e) -> return reject(e)
        ws.on 'message', (data) ->
          data = JSON.parse(data)
          if data.event is 'ms.channel.connect'
            ws.send JSON.stringify(createCmd(key))
            setTimeout (-> ws.close(); return resolve()), timeout

    createCmd = (key) ->
      method: 'ms.remote.control'
      params:
        Cmd: 'Click'
        DataOfCmd: key
        Option: "false"
        TypeOfRemote: 'SendRemoteKey'


    destroy: ->
      clearTimeout(@updateTimeout)
      super()

  class SamsungTV_2016_ActionProvider extends env.actions.ActionProvider
    constructor: (@framework, @config) ->
    parseAction: (input, context) =>
      tv = null
      tvs = (device for id, device of @framework.deviceManager.devices when device.config.class.includes("SamsungTV_2016"))
      command = null
      fullMatch = no
      m = M(input, context)
        .match("send samsung_tv_command ")
        .match(key_commands, (m, c) => command = c)
        .match(" to ")
        .matchDevice(tvs, (m, t) => tv = t)

      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SamsungTV_2016_ActionHandler(@framework, tv, command)
        }
      else
        return null

  class SamsungTV_2016_ActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @tv, @command) ->
      console.log @tv
    executeAction: (simulate) =>
      if simulate
        # just return a promise fulfilled with a description about what we would do.
        return __("would send Samsung remote command: \"%s\"", @command)
      else
        return @tv.send(@command)



  samsungTV = new SamsungTV_2016_Plugin
  return samsungTV
