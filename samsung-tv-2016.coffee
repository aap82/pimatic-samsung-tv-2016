module.exports = (env) ->
  plugin_name = "SamsungTV_2016"
  _ = require './utils'
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  WebSocket = require('ws')
  wol = require('wake_on_lan')
  wakeTV = Promise.promisify(wol.wake)
  rq = require('request-promise')

  getTVState = (url) =>
    return rq(url, {json: yes, timeout: 500})
      .then((res) => return Promise.resolve(res))
      .catch(=> return Promise.resolve(null))

  sendKeyToTV = (ws_url, key, timeout=1000) =>
    return new Promise (resolve, reject) =>
      ws = new WebSocket ws_url, (error) ->
        throw new Error(error)
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

  class SamsungTV_2016_Plugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @app_name = new Buffer("#{@config.app_name}").toString('base64')

      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass plugin_name, {
        configDef: deviceConfigDef[plugin_name]
        createCallback: ((config) => new SamsungTV_2016_Switch(config, @))
      }

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
      @_state = lastState?.state.value
      {@ip_address, @update_interval, @api_timeout} = @config
      @isBusy = no
      @isTurningOff = no
      @updateTimeout = null
      @tv_url = "http://#{@ip_address}:8001/api/v2/"
      @ws_url = "http://#{@ip_address}:8001/api/v2/channels/samsung.remote.control?name=#{@plugin.app_name}"

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
          if @isTurningOff and @_state is no
            return no
          else
            @isTurningOff = no
            return yes
      .then((state) => @_setState(state))
      .catch (err) =>
        env.logger.error err
        return Promise.resolve()

    changeStateTo: (state) ->
      return Promise.reject("NOT READY") unless (@_state isnt null and @mac_address isnt null)
      return Promise.resolve("BUSY") if @isBusy
      return Promise.resolve() if @_state is state
      @isBusy = yes
      getTVState(@tv_url).then (isAvail) =>
        return sendKeyToTV(@ws_url, 'KEY_POWER') if isAvail?
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

    destroy: ->
      clearTimeout(@updateTimeout)
      super()

  samsungTV = new SamsungTV_2016_Plugin
  return samsungTV