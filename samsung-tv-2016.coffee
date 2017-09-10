module.exports = (env) ->
  _ = require './utils'
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  plugin_name = "SamsungTV_2016"
  WebSocket = require('ws')
  wol = require('wake_on_lan')
  wakeTV = Promise.promisify(wol.wake)
  rq = require('request-promise')

  class SamsungTV_2016_Plugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @app_name = new Buffer("#{@config.app_name}").toString('base64')
      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass plugin_name, {
        configDef: deviceConfigDef["#{plugin_name}"]
        createCallback: (config) => new SamsungTV_2016_Switch(config, @)
      }

    logInfo: (str) -> env.logger.info "#{plugin_name}: #{str}"
    logWarn: (str) -> env.logger.warn "#{plugin_name}: #{str}"
    logError: (str) -> env.logger.error "#{plugin_name}: #{str}"

  class SamsungTV_2016_Switch extends env.devices.SwitchActuator
    _state: null
    @property 'mac_address',
      get: -> if @config.mac_address is '' then null else @config.mac_address
      set: (addr) -> @config.mac_address = addr
    @property 'isReady',
      get: -> (@_state isnt null and @mac_address isnt null)

    _getApiState: -> return rq(@tv_url, {json: yes, timeout: 600}).then((res) => return Promise.resolve(res)).catch(=> Promise.resolve(null))

    _updateApiState:  ->
      if @isBusy
        @ping_IntervalTimeout = setTimeout((=> @_updateApiState()), @updateApiState_interval)
        return
      @_getApiState(@tv_url).then (res) =>
        if res?
          @mac_address = res.device.wifiMac unless @mac_address?
          if @isTurningOff and @_state is no
            return no
          else
            @isTurningOff = no
            return yes
        else
          @_setState(no)
          @isTurningOff = no
          return no
      .then (state) =>
        @_setState(state)
        @ping_IntervalTimeout = setTimeout((=> @_updateApiState()), @updateApiState_interval)
        return
      .catch (err) =>
        console .log err
        return @logError err
    _sendKeyToTV: (url, key, timeout =1000) ->
      return new Promise (resolve, reject) =>
        ws = new WebSocket url, (error) ->
          console.log error
          throw new Error(error)
          return reject(error)
        ws.on 'error', (e) -> return reject(e)
        ws.on 'message', (data) ->
          cmd =
            method: 'ms.remote.control'
            params:
              Cmd: 'Click'
              DataOfCmd: key
              Option: 'false'
              TypeOfRemote: 'SendRemoteKey'
          data = JSON.parse(data)
          if data.event == 'ms.channel.connect'
            ws.send JSON.stringify(cmd)
            setTimeout (-> ws.close(); return resolve()), timeout

    afterRegister: ->   setTimeout((=> @_updateApiState()), 2000)

    constructor: (@config, @plugin, lastState) ->
      assert(@config.ip_address isnt '')
      @id = @config.id
      @name = @config.name
      super()
      {@ip_address, @ping_interval, @api_timeout} = @config
      @isBusy = no
      @isTurningOff = no
      @updateApiState_interval = @ping_interval * 1000
      @ping_IntervalTimeout = null
      @tv_url = "http://#{@ip_address}:8001/api/v2/"
      @ws_url = "http://#{@ip_address}:8001/api/v2/channels/samsung.remote.control?name=#{@plugin.app_name}"




    changeStateTo: (state) ->
      return Promise.reject("NOT READY") unless @isReady
      return Promise.resolve("BUSY") if @isBusy
      return Promise.resolve() if @_state is state
      @isBusy = yes
      @_getApiState(@tv_url).then (isAvail) =>
        if isAvail is null
          @isTurningOff = no
          if state is no
            return no
          else
            return wakeTV(@mac_address).then(=> return state)
        else if isAvail?
          return @_sendKeyToTV(@ws_url, 'KEY_POWER')
      .then =>
        @isTurningOff = !state
        @isBusy = no
        @_setState(state)
      .catch (err) =>
        @isBusy = no
        Promise.reject(err)


    destroy: ->
      clearTimeout(@ping_IntervalTimeout)
      super()


  samsungTV = new SamsungTV_2016_Plugin
  return samsungTV